import 'dart:io';

import 'package:server/deck_rules_service.dart';
import 'package:server/deck_validation_route_support.dart';
import 'package:test/test.dart';

void main() {
  group('deck validation route support', () {
    test('owner scope query requires deck id and user id', () {
      expect(deckValidationOwnerScopeSql, contains('FROM decks'));
      expect(deckValidationOwnerScopeSql, contains('id = @deckId'));
      expect(deckValidationOwnerScopeSql, contains('user_id = @userId'));
      expect(deckValidationOwnerScopeSql, contains('LIMIT 1'));
      expect(deckValidationOwnerScopeSql, contains('FOR UPDATE'));
    });

    test('success body matches validate endpoint contract', () {
      expect(
        buildDeckValidationSuccessBody(
          deckId: 'deck-1',
          format: 'commander',
          validationUpdatedAt: DateTime.utc(2026, 7, 22, 12, 30),
        ),
        {
          'ok': true,
          'format': 'commander',
          'deck_id': 'deck-1',
          'deck_state': 'validated',
          'requires_review': false,
          'review_reasons': const <String>[],
          'validation_updated_at': '2026-07-22T12:30:00.000Z',
        },
      );
    });

    test('not-found body is explicit and distinguishable', () {
      final body = buildDeckValidationNotFoundBody();

      expect(body['ok'], isFalse);
      expect(body['error'], 'Deck not found or permission denied.');
      expect(body['error_code'], 'deck_not_found');
      expect(isDeckValidationNotFoundBody(body), isTrue);
    });

    test('DeckRulesException body preserves optional card name', () {
      final body = buildDeckValidationRuleErrorBody(
        DeckRulesException('Carta ilegal.', cardName: 'Vendetta'),
        persistedReasons: const ['deck_cards_changed_since_validation'],
        validationUpdatedAt: '2026-07-22T12:31:00Z',
      );

      expect(body['ok'], isFalse);
      expect(body['error'], 'Carta ilegal.');
      expect(body['card_name'], 'Vendetta');
      expect(body['deck_state'], 'draft');
      expect(body['requires_review'], isTrue);
      expect(body['review_reasons'], [
        'deck_cards_changed_since_validation',
        'strict_validation_failed',
      ]);
      expect(body['validation_updated_at'], '2026-07-22T12:31:00.000Z');
    });

    test('internal error body never leaks exception or SQL details', () {
      const secret = 'password=prod-secret SELECT * FROM users';
      final body = buildDeckValidationHandlerErrorBody(Exception(secret));

      expect(body['ok'], isFalse);
      expect(body['error'], 'Unable to validate deck right now.');
      expect(body['error_code'], 'deck_validation_internal_error');
      expect(body.toString(), isNot(contains('prod-secret')));
      expect(body.toString(), isNot(contains('SELECT * FROM users')));
    });

    test('route source uses JSON method-not-allowed and helper bodies', () {
      final source =
          File('routes/decks/[id]/validate/index.dart').readAsStringSync();

      expect(source, contains('methodNotAllowed()'));
      expect(source, contains('deckValidationOwnerScopeSql'));
      expect(source, contains('buildDeckValidationSuccessBody'));
      expect(source, contains('buildDeckValidationNotFoundBody'));
      expect(source, contains('buildDeckValidationRuleErrorBody'));
      expect(source, contains('deckValidationMarkSuccessSql'));
      expect(source, contains('deckValidationMarkFailureSql'));
      expect(source, contains('on DeckRulesException catch (error)'));
      expect(source, isNot(contains('await pool.execute(')));
    });
  });
}
