import 'package:server/battle/interactive_battle_contract.dart';
import 'package:test/test.dart';

void main() {
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
const _promptId = 'p_abcdefghijklmnop';
const _optionId = 'o_abcdefghijklmnop';
