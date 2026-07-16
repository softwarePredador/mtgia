import 'package:test/test.dart';

import '../lib/ai/optimize_filler_candidate_support.dart';

void main() {
  group('dedupeCandidatesByName', () {
    test('keeps first non-empty candidate for each normalized name', () {
      final result = dedupeCandidatesByName([
        {'name': ' Sol Ring ', 'id': 'first'},
        {'name': 'sol ring', 'id': 'duplicate'},
        {'name': '', 'id': 'empty'},
        {'name': 'Arcane Signet', 'id': 'second'},
      ]);

      expect(
        result.map((candidate) => candidate['id']).toList(),
        equals(['first', 'second']),
      );
    });
  });

  group('shouldKeepCommanderFillerCandidate', () {
    test('rejects excluded names and off-identity cards', () {
      expect(
        shouldKeepCommanderFillerCandidate(
          candidate: {
            'name': 'Arcane Signet',
            'color_identity': const <String>[],
            'colors': const <String>[],
          },
          excludeNames: {'arcane signet'},
        ),
        isFalse,
      );

      expect(
        shouldKeepCommanderFillerCandidate(
          candidate: {
            'name': 'Swords to Plowshares',
            'mana_cost': '{W}',
            'color_identity': const ['W'],
            'colors': const ['W'],
          },
          excludeNames: const <String>{},
          commanderColorIdentity: const {'U'},
          enforceCommanderIdentity: true,
        ),
        isFalse,
      );
    });

    test('allows colorless cards and cards inside commander identity', () {
      expect(
        shouldKeepCommanderFillerCandidate(
          candidate: {
            'name': 'Sol Ring',
            'mana_cost': '{1}',
            'color_identity': const <String>[],
            'colors': const <String>[],
          },
          excludeNames: const <String>{},
          commanderColorIdentity: const {'R', 'W'},
          enforceCommanderIdentity: true,
        ),
        isTrue,
      );

      expect(
        shouldKeepCommanderFillerCandidate(
          candidate: {
            'name': 'Boros Charm',
            'mana_cost': '{R}{W}',
            'color_identity': const ['R', 'W'],
            'colors': const ['R', 'W'],
          },
          excludeNames: const <String>{},
          commanderColorIdentity: const {'R', 'W'},
          enforceCommanderIdentity: true,
        ),
        isTrue,
      );
    });
  });

  group('resolvedCardIdentity', () {
    test('preserves explicit canonical colorless identity', () {
      expect(
        resolvedCardIdentity({
          'color_identity': const <String>[],
          'colors': const <String>['W'],
          'mana_cost': '{U}',
          'oracle_text': '{T}: Add {B}.',
        }),
        isEmpty,
      );
    });

    test('uses fallback only when canonical identity is absent', () {
      expect(
        resolvedCardIdentity({
          'colors': const <String>['W'],
          'mana_cost': '{U}',
          'oracle_text': '{T}: Add {B}.',
        }),
        equals({'W', 'U', 'B'}),
      );
    });

    test('uses non-empty canonical identity without merging fallback', () {
      expect(
        resolvedCardIdentity({
          'color_identity': const <String>['G'],
          'colors': const <String>['W'],
          'mana_cost': '{U}',
          'oracle_text': '{T}: Add {B}.',
        }),
        equals({'G'}),
      );
    });
  });

  group('commanderFillerQualityScore', () {
    test('rewards premium fillers and penalizes group draw traps', () {
      final solRingScore = commanderFillerQualityScore({
        'name': 'Sol Ring',
        'type_line': 'Artifact',
        'oracle_text': '{T}: Add {C}{C}.',
        'cmc': 1,
        'meta_deck_count': 1,
        'usage_count': 8,
      });

      final templeBellScore = commanderFillerQualityScore({
        'name': 'Temple Bell',
        'type_line': 'Artifact',
        'oracle_text': '{T}: Each player draws a card.',
        'cmc': 3,
        'meta_deck_count': 1,
        'usage_count': 8,
      });

      expect(solRingScore, greaterThan(templeBellScore));
    });

    test('penalizes high-cmc utility filler', () {
      final cheapUtilityScore = commanderFillerQualityScore({
        'name': 'Relic of Progenitus',
        'type_line': 'Artifact',
        'oracle_text': 'Exile target card from a graveyard.',
        'cmc': 1,
      });
      final expensiveUtilityScore = commanderFillerQualityScore({
        'name': 'Planar Bridge',
        'type_line': 'Artifact',
        'oracle_text': 'Search your library for a permanent card.',
        'cmc': 6,
      });

      expect(cheapUtilityScore, greaterThan(expensiveUtilityScore));
    });
  });

  group('land color fixing helpers', () {
    test('detects explicit mana symbols and any-color lands', () {
      expect(
        landProducesCommanderColors(
          card: {
            'name': 'Clifftop Retreat',
            'oracle_text': '{T}: Add {R} or {W}.',
            'colors': const <String>[],
            'color_identity': const <String>[],
          },
          commanderColorIdentity: const {'R', 'W'},
        ),
        isTrue,
      );

      expect(
        landProducesCommanderColors(
          card: {
            'name': 'Command Tower',
            'oracle_text':
                '{T}: Add one mana of any color in your commander identity.',
            'colors': const <String>[],
            'color_identity': const <String>[],
          },
          commanderColorIdentity: const {'B', 'G'},
        ),
        isTrue,
      );
    });

    test('treats fetchlands as fixing without adding color identity', () {
      final fetch = {
        'name': 'Flooded Strand',
        'oracle_text':
            '{T}, Pay 1 life, Sacrifice this land: Search your library for a Plains or Island card.',
        'colors': const <String>[],
        'color_identity': const <String>[],
      };

      expect(resolvedCardIdentity(fetch), isEmpty);
      expect(
        landFixesCommanderColors(
          card: fetch,
          commanderColorIdentity: const {'W', 'U'},
        ),
        isTrue,
      );
    });
  });
}
