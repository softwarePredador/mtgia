import 'dart:io';

import 'package:test/test.dart';

import '../lib/card_resolution_support.dart';

void main() {
  group('resolveCardCandidateNames', () {
    test('resolves exact match before broader candidates', () {
      final decision = resolveCardCandidateNames(
        'Sol Ring',
        ['Sol Ring', 'Sol Ring Deluxe'],
      );

      expect(decision.isResolved, isTrue);
      expect(decision.matchedName, equals('Sol Ring'));
      expect(decision.strategy, equals('exact'));
    });

    test('resolves unique prefix match', () {
      final decision = resolveCardCandidateNames(
        'Atraxa',
        ['Atraxa, Praetors\' Voice'],
      );

      expect(decision.isResolved, isTrue);
      expect(decision.matchedName, equals('Atraxa, Praetors\' Voice'));
      expect(decision.strategy, equals('prefix'));
    });

    test('marks multiple prefix matches as ambiguous', () {
      final decision = resolveCardCandidateNames(
        'Lightning',
        ['Lightning Bolt', 'Lightning Helix', 'Lightning Greaves'],
      );

      expect(decision.isResolved, isFalse);
      expect(decision.isAmbiguous, isTrue);
      expect(decision.candidateNames, hasLength(3));
    });

    test('resolves unique contains match when prefix is absent', () {
      final decision = resolveCardCandidateNames(
        'Lotus',
        ['Black Lotus'],
      );

      expect(decision.isResolved, isTrue);
      expect(decision.matchedName, equals('Black Lotus'));
      expect(decision.strategy, equals('contains'));
    });

    test('returns unresolved when there are no candidates', () {
      final decision = resolveCardCandidateNames('Unknown Card', const []);

      expect(decision.isResolved, isFalse);
      expect(decision.isAmbiguous, isFalse);
      expect(decision.candidateNames, isEmpty);
    });

    test('does not resolve token names to nearby normal Phyrexian cards', () {
      final decision = resolveCardCandidateNames(
        'Phyrexian Horror',
        ['Phyrexian Censor'],
      );

      expect(decision.isResolved, isFalse);
      expect(decision.isAmbiguous, isFalse);
    });
  });

  group('deck card name resolution source guards', () {
    test(
        'shared deck resolver prefers card identity bridge with cards fallback',
        () {
      final source =
          File('lib/deck_card_name_resolution_support.dart').readAsStringSync();

      expect(source, contains('JOIN card_identity_bridge cib'));
      expect(source, contains('cib.normalized_lookup_name'));
      expect(source, contains('cib.normalized_canonical_name'));
      expect(source, contains('card_identity_bridge'));
      expect(source, contains('cards_fallback'));
      expect(source, contains('isUndefinedCardIdentityBridgeError'));
      expect(source, contains('LOWER(SPLIT_PART(c.name'));
      expect(
        source,
        contains('ORDER BY match_rank, match_priority, legality_rank, card_id'),
      );
      expect(
        source,
        contains(
          'ORDER BY match_rank, match_priority, legality_rank, candidate_name, card_id',
        ),
      );
    });

    test('deck write and batch routes use shared bridge-backed resolver', () {
      final batchRoute =
          File('routes/cards/resolve/batch/index.dart').readAsStringSync();
      final createRoute = File('routes/decks/index.dart').readAsStringSync();
      final updateRoute =
          File('routes/decks/[id]/index.dart').readAsStringSync();

      expect(batchRoute, contains('resolveDeckCardNameCandidates'));
      expect(createRoute, contains('resolveDeckCardIdByName'));
      expect(updateRoute, contains('resolveDeckCardIdByName'));
      expect(
        createRoute,
        isNot(contains('WHERE LOWER(c.name) = LOWER(@name)')),
      );
      expect(
        updateRoute,
        isNot(contains('WHERE LOWER(name) = LOWER(@name)')),
      );
    });
  });
}
