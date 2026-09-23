import 'dart:io';

import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/privacy/deleted_deck_anonymizer.dart';
import '../lib/user_data_privacy_service.dart';
import 'support/scripted_pool.dart';

/// BT-PRIV-002 (D-23), sem banco: anonimização do deck de quem saiu dentro do
/// replay de outra pessoa, falha fechada quando uma relação obrigatória
/// falta e as lacunas do inventário tratadas no serviço.
void main() {
  group('replay de outra pessoa contra o deck de quem saiu', () {
    const deletedDeck = '3f1c2b7a-9d4e-4f6a-8b2c-1d2e3f4a5b6c';
    const keptDeck = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';

    test('troca o UUID e o nome do deck apagado e preserva o resto', () {
      final anonymized = anonymizeDeletedDeckReferences(
        {
          'deck_a': {'id': keptDeck, 'name': 'Deck de quem rodou'},
          'deck_b': {
            'id': deletedDeck,
            'name': 'Deck do Fulano',
            'cards': [
              {'name': 'Sol Ring', 'quantity': 1},
            ],
          },
          'events': [
            {'actor': 'deck_b', 'message': 'vence $deletedDeck'},
            {'deck_id': deletedDeck, 'deck_name': 'Deck do Fulano'},
          ],
          'winner_deck_id': deletedDeck,
          'turns': 7,
        },
        [deletedDeck.toUpperCase()],
      );

      expect(anonymized, {
        'deck_a': {'id': keptDeck, 'name': 'Deck de quem rodou'},
        'deck_b': {
          'id': deletedDeckPlaceholderId,
          'name': deletedDeckPlaceholderName,
          'cards': [
            {'name': 'Sol Ring', 'quantity': 1},
          ],
        },
        'events': [
          {'actor': 'deck_b', 'message': 'vence $deletedDeckPlaceholderId'},
          {
            'deck_id': deletedDeckPlaceholderId,
            'deck_name': deletedDeckPlaceholderName,
          },
        ],
        'winner_deck_id': deletedDeckPlaceholderId,
        'turns': 7,
      });
    });

    test('sem deck apagado, o replay volta igual', () {
      final replay = {
        'deck_b': {'id': keptDeck, 'name': 'Deck'},
      };
      expect(anonymizeDeletedDeckReferences(replay, const []), same(replay));
    });
  });

  group('exclusão falha fechada', () {
    const password = 'Senha!Atual-2026';
    late String storedHash;

    setUpAll(() {
      AuthService.resetForTesting();
      storedHash = AuthService().hashPassword(password);
    });

    test(
      'relação obrigatória ausente derruba a exclusão antes de apagar',
      () async {
        final pool = ScriptedPool([
          scriptedResult(
            columns: const ['username', 'email', 'password_hash'],
            rows: [
              ['jogadora', 'jogadora@example.invalid', storedHash],
            ],
          ),
          scriptedResult(
            columns: const ['relation'],
            rows: const [
              ['ai_logs'],
            ],
          ),
        ]);

        await expectLater(
          UserDataPrivacyService(pool).deleteAndAnonymizeAccount(
            userId: '3f1c2b7a-9d4e-4f6a-8b2c-1d2e3f4a5b6c',
            password: password,
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('ai_logs'),
            ),
          ),
        );
        final writes = pool.queries.where((query) {
          final statement = query.trimLeft().toUpperCase();
          return statement.startsWith('DELETE') ||
              statement.startsWith('UPDATE') ||
              statement.startsWith('INSERT');
        });
        expect(writes, isEmpty);
        expect(pool.exhausted, isTrue);
      },
    );
  });

  group('lacunas do inventário tratadas na exclusão', () {
    final service =
        File('lib/user_data_privacy_service.dart').readAsStringSync();

    test('bloqueios, tokens e recursos entram na exclusão', () {
      expect(service, contains('DELETE FROM user_blocks'));
      expect(service, contains('DELETE FROM password_reset_tokens'));
      expect(service, contains('DELETE FROM email_verification_tokens'));
      expect(service, contains('UPDATE user_block_events'));
      expect(service, contains('UPDATE content_report_appeals'));
      expect(service, contains('UPDATE moderation_actions'));
      expect(service, contains("evidence = '{}'::jsonb"));
    });

    test('simulação de outra pessoa não é apagada por citar o deck do '
        'titular', () {
      expect(service, contains('anonymizeDeletedDeckReferences'));
      expect(
        service,
        isNot(contains('deck.id IN (attempt.deck_a_id, attempt.deck_b_id)')),
      );
      expect(service, isNot(contains('OR simulation.deck_b_id = deck.id')));
    });

    test('relação ausente não vira sucesso silencioso', () {
      expect(service, isNot(contains('_deleteIfPresent')));
      expect(service, isNot(contains('_executeIfPresent')));
      expect(service, isNot(contains('_executeIfAllPresent')));
    });
  });

  test('o recibo diz o que a exclusão faz', () {
    expect(accountDeletionPolicyVersion, 'brewtact-beta-privacy-v2');
    expect(accountDeletionRetentionSummary, {
      'trades_and_disputes': 'anonymized',
      'moderation_records': 'anonymized',
      'operational_aggregates': 'deidentified',
      'deck_learning_and_battle_rows': 'deleted',
      'third_party_simulations_against_public_decks': 'anonymized',
      'blocks_and_account_tokens': 'deleted',
      'deleted_deck_anti_resurrection_keys': 'opaque_identifier_only',
    });
  });
}
