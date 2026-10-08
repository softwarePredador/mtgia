import 'dart:io';

import 'package:server/battle/interactive_battle_contract.dart';
import 'package:test/test.dart';

void main() {
  // Duas listas mantidas a mao, em linguagens diferentes, que precisam
  // concordar: `PromptKind` no sidecar Java e a allowlist fail-closed do
  // servidor. Elas divergiram e o custo foi total -- `PromptKind.MULLIGAN` era
  // o unico GAME_ASK classificado, e a primeira pergunta de sim/nao do motor
  // derrubava a mesa com `engine_error` no turno 4. Nenhum teste via, porque
  // cada lado estava internamente coerente.
  //
  // Este teste le o enum Java direto da fonte. Se alguem adicionar um kind la
  // e esquecer daqui, o servidor recusaria o prompt em runtime; a falha passa a
  // aparecer aqui, de graca.
  test('todo PromptKind do sidecar e aceito pela allowlist do servidor', () {
    final javaSource = File(
      '../services/xmage-sidecar/src/main/java/com/manaloom/xmage/'
      'HumanVsAiSpikeHarness.java',
    );
    expect(
      javaSource.existsSync(),
      isTrue,
      reason: 'fonte do sidecar nao encontrada: ${javaSource.path}',
    );
    final body = RegExp(
      r'enum PromptKind \{([^}]*)\}',
    ).firstMatch(javaSource.readAsStringSync());
    expect(body, isNotNull, reason: 'enum PromptKind nao encontrado');

    final kinds =
        body!
            .group(1)!
            .split(',')
            .map((raw) => raw.trim())
            .where((raw) => RegExp(r'^[A-Z][A-Z_]*$').hasMatch(raw))
            .map((raw) => raw.toLowerCase())
            .toList();

    // Sanidade: se a extracao falhar e devolver pouca coisa, o teste passaria
    // vazio e nao provaria nada.
    expect(kinds.length, greaterThanOrEqualTo(11));
    expect(kinds, contains('mulligan'));
    expect(kinds, contains('question'));

    for (final kind in kinds) {
      expect(
        interactiveBattlePromptKinds,
        contains(kind),
        reason:
            'PromptKind.${kind.toUpperCase()} existe no sidecar mas o servidor '
            'recusaria o prompt: adicione "$kind" a allowlist.',
      );
    }
  });

  group('interactive battle request contract', () {
    test('parses bounded create input and requires a distinct opponent', () {
      final input = InteractiveBattleCreateInput.parse({
        'schema_version': interactiveBattleRequestSchema,
        'deck_id': _deckA,
        'opponent_deck_id': _deckB,
        'ttl_seconds': 600,
        'prompt_timeout_seconds': 45,
      }, headerIdempotencyKey: 'interactive-create-1');

      expect(input.deckId, _deckA);
      expect(input.opponentDeckId, _deckB);
      expect(input.ttlSeconds, 600);
      expect(input.promptTimeoutSeconds, 45);
      expect(input.idempotencyKey, 'interactive-create-1');

      expect(
        () => InteractiveBattleCreateInput.parse({
          'deck_id': _deckA,
          'opponent_deck_id': _deckA,
          'idempotency_key': 'same-deck',
        }),
        throwsA(
          isA<InteractiveBattleValidationException>().having(
            (error) => error.code,
            'code',
            'interactive_battle_opponent_invalid',
          ),
        ),
      );
    });

    test('rejects unknown fields and mismatched idempotency keys', () {
      expect(
        () => InteractiveBattleCreateInput.parse({
          'deck_id': _deckA,
          'opponent_deck_id': _deckB,
          'idempotency_key': 'body-key',
          'unexpected': true,
        }),
        throwsA(
          isA<InteractiveBattleValidationException>().having(
            (error) => error.code,
            'code',
            'interactive_battle_unknown_field',
          ),
        ),
      );
      expect(
        () => InteractiveBattleCreateInput.parse({
          'deck_id': _deckA,
          'opponent_deck_id': _deckB,
          'idempotency_key': 'body-key',
        }, headerIdempotencyKey: 'header-key'),
        throwsA(
          isA<InteractiveBattleValidationException>().having(
            (error) => error.code,
            'code',
            'interactive_battle_idempotency_mismatch',
          ),
        ),
      );
    });

    test('create fingerprint binds the stable request body and deck ids', () {
      const input = InteractiveBattleCreateInput(
        deckId: _deckA,
        opponentDeckId: _deckB,
        ttlSeconds: 600,
        promptTimeoutSeconds: 45,
        idempotencyKey: 'fingerprint-one',
      );
      final fingerprint = interactiveBattleCreateFingerprint(input: input);

      expect(
        interactiveBattleCreateFingerprint(
          input: const InteractiveBattleCreateInput(
            deckId: _deckA,
            opponentDeckId: _deckB,
            ttlSeconds: 600,
            promptTimeoutSeconds: 45,
            idempotencyKey: 'fingerprint-retry-key-is-not-hash-material',
          ),
        ),
        fingerprint,
      );
      expect(
        interactiveBattleCreateFingerprint(
          input: const InteractiveBattleCreateInput(
            deckId: _deckC,
            opponentDeckId: _deckB,
            ttlSeconds: 600,
            promptTimeoutSeconds: 45,
            idempotencyKey: 'fingerprint-one',
          ),
        ),
        isNot(fingerprint),
      );
      expect(
        interactiveBattleCreateFingerprint(
          input: const InteractiveBattleCreateInput(
            deckId: _deckA,
            opponentDeckId: _deckB,
            ttlSeconds: 601,
            promptTimeoutSeconds: 45,
            idempotencyKey: 'fingerprint-one',
          ),
        ),
        isNot(fingerprint),
      );
    });
  });

  group('interactive prompt actions', () {
    test(
      'builds opaque option, integer, multi-amount, and delegate actions',
      () {
        final fixtures = <Map<String, dynamic>>[
          {'option_id': _optionId},
          {'integer_value': 3},
          {
            'multi_amount_values': [1, 2],
          },
          {'delegate': true},
        ];
        final expected = InteractiveBattleResponseKind.values;
        for (var index = 0; index < fixtures.length; index++) {
          final action = InteractiveBattleActionInput.parse({
            'schema_version': interactiveBattleActionSchema,
            'state_version': 7,
            'prompt_id': _promptId,
            ...fixtures[index],
          }, headerIdempotencyKey: 'action-$index');
          expect(action.responseKind, expected[index]);
          expect(action.responsePayload['action_id'], 'action-$index');
        }
      },
    );

    test('requires exactly one response and rejects raw option labels', () {
      expect(
        () => InteractiveBattleActionInput.parse({
          'state_version': 7,
          'prompt_id': _promptId,
          'option_id': _optionId,
          'delegate': true,
        }, headerIdempotencyKey: 'ambiguous'),
        throwsA(
          isA<InteractiveBattleValidationException>().having(
            (error) => error.code,
            'code',
            'interactive_battle_action_shape_invalid',
          ),
        ),
      );
      expect(
        () => InteractiveBattleActionInput.parse({
          'state_version': 7,
          'prompt_id': _promptId,
          'option_id': 'Keep this hand',
        }, headerIdempotencyKey: 'raw-label'),
        throwsA(
          isA<InteractiveBattleValidationException>().having(
            (error) => error.code,
            'code',
            'interactive_battle_option_id_invalid',
          ),
        ),
      );
    });

    test('prompt validates state, allowlisted option, and delegation', () {
      final prompt = InteractiveBattlePrompt.parse({
        'schema_version': interactiveBattlePromptSchema,
        'id': _promptId,
        'state_version': 7,
        'kind': 'main_action',
        'input_mode': 'options',
        'title': 'Sua prioridade',
        'message': 'Escolha uma ação.',
        'deadline_at': '2026-07-27T15:00:00Z',
        'options': [
          {'id': _optionId, 'label': 'Passar prioridade', 'role': 'delegate'},
        ],
      });
      final accepted = InteractiveBattleActionInput.parse({
        'state_version': 7,
        'prompt_id': _promptId,
        'option_id': _optionId,
      }, headerIdempotencyKey: 'accepted');
      final delegated = InteractiveBattleActionInput.parse({
        'state_version': 7,
        'prompt_id': _promptId,
        'delegate': true,
      }, headerIdempotencyKey: 'delegated');

      expect(() => prompt.validateAction(accepted), returnsNormally);
      expect(() => prompt.validateAction(delegated), returnsNormally);
      expect(
        () => prompt.validateAction(
          InteractiveBattleActionInput(
            stateVersion: 6,
            promptId: _promptId,
            responseKind: InteractiveBattleResponseKind.option,
            optionId: _optionId,
            idempotencyKey: 'stale',
          ),
        ),
        throwsA(
          isA<InteractiveBattleStaleActionException>().having(
            (error) => error.code,
            'code',
            'interactive_battle_action_stale',
          ),
        ),
      );
    });

    test('prompt parser accepts the engine question kind, rejects unknown', () {
      // O teste de paridade acima prova a constante; este prova o parser.
      // Se `parse` voltar a uma lista propria sem 'question', o prompt da
      // pergunta generica do motor e recusado com
      // `interactive_battle_prompt_invalid` e a mesa morre do mesmo jeito.
      Map<String, Object?> promptWithKind(String kind) => {
        'schema_version': interactiveBattlePromptSchema,
        'id': _promptId,
        'state_version': 9,
        'kind': kind,
        'input_mode': 'options',
        'title': 'Sua decisão',
        'message': 'Escolha uma ação legal para continuar.',
        'deadline_at': '2026-07-27T15:00:00Z',
        'options': [
          {'id': _optionId, 'label': 'Sim', 'role': 'choice'},
          {'id': 'o_qrstuvwxyzabcdef', 'label': 'Não', 'role': 'choice'},
        ],
      };

      final question = InteractiveBattlePrompt.parse(
        promptWithKind('question'),
      );
      expect(question.kind, 'question');
      expect(question.options.map((option) => option.label), ['Sim', 'Não']);

      expect(
        () => InteractiveBattlePrompt.parse(promptWithKind('engine_surprise')),
        throwsA(
          isA<InteractiveBattlePersistenceException>().having(
            (error) => error.code,
            'code',
            'interactive_battle_prompt_invalid',
          ),
        ),
      );
    });

    test('prompt card object id is optional but UUID-strict when present', () {
      final withObjectId = InteractiveBattlePrompt.parse({
        'schema_version': interactiveBattlePromptSchema,
        'id': _promptId,
        'state_version': 7,
        'kind': 'main_action',
        'input_mode': 'options',
        'title': 'Sua prioridade',
        'message': 'Escolha uma ação.',
        'deadline_at': '2026-07-27T15:00:00Z',
        'options': [
          {
            'id': _optionId,
            'label': 'Conjurar Swords to Plowshares',
            'role': 'card',
            'card': {
              'id': '11111111-1111-4111-8111-111111111111',
              'name': 'Swords to Plowshares',
              'set_code': '2XM',
              'collector_number': '35',
            },
          },
        ],
      });
      final withoutObjectId = InteractiveBattlePrompt.parse({
        'schema_version': interactiveBattlePromptSchema,
        'id': _promptId,
        'state_version': 7,
        'kind': 'main_action',
        'input_mode': 'options',
        'title': 'Sua prioridade',
        'message': 'Escolha uma ação.',
        'deadline_at': '2026-07-27T15:00:00Z',
        'options': [
          {
            'id': _optionId,
            'label': 'Conjurar Swords to Plowshares',
            'role': 'card',
            'card': {'name': 'Swords to Plowshares'},
          },
        ],
      });

      expect(
        withObjectId.options.single.card?['id'],
        '11111111-1111-4111-8111-111111111111',
      );
      expect(withoutObjectId.options.single.card?['id'], isNull);

      for (final invalidCard in <Map<String, Object?>>[
        {'id': 'not-a-uuid', 'name': 'Swords to Plowshares'},
        {'id': 42, 'name': 'Swords to Plowshares'},
        {
          'id': '11111111-1111-4111-8111-111111111111',
          'name': 'Swords to Plowshares',
          'hidden_owner_id': 'opponent-private-id',
        },
      ]) {
        expect(
          () => InteractiveBattlePrompt.parse({
            'schema_version': interactiveBattlePromptSchema,
            'id': _promptId,
            'state_version': 7,
            'kind': 'main_action',
            'input_mode': 'options',
            'title': 'Sua prioridade',
            'message': 'Escolha uma ação.',
            'deadline_at': '2026-07-27T15:00:00Z',
            'options': [
              {
                'id': _optionId,
                'label': 'Conjurar Swords to Plowshares',
                'role': 'card',
                'card': invalidCard,
              },
            ],
          }),
          throwsA(
            isA<InteractiveBattlePersistenceException>().having(
              (error) => error.code,
              'code',
              'interactive_battle_prompt_invalid',
            ),
          ),
        );
      }
    });
  });

  test('completed, censored, and conceded sessions require a replay', () {
    expect(InteractiveBattleStatus.completed.requiresPersistedReplay, isTrue);
    expect(InteractiveBattleStatus.censored.requiresPersistedReplay, isTrue);
    expect(InteractiveBattleStatus.conceded.requiresPersistedReplay, isTrue);
    expect(InteractiveBattleStatus.timeout.requiresPersistedReplay, isFalse);
    expect(
      InteractiveBattleStatus.engineError.requiresPersistedReplay,
      isFalse,
    );
  });
}

const _deckA = '11111111-1111-4111-8111-111111111111';
const _deckB = '22222222-2222-4222-8222-222222222222';
const _deckC = '33333333-3333-4333-8333-333333333333';
const _promptId = 'p_abcdefghijklmnop';
const _optionId = 'o_abcdefghijklmnop';
