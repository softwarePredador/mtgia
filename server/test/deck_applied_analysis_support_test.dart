import 'package:server/decks/deck_applied_analysis_support.dart';
import 'package:test/test.dart';

void main() {
  group('applied deck post analysis', () {
    test('recomputes metrics from the exact persisted card selection', () {
      final analysis = buildAppliedDeckPostAnalysis(
        persistedCards: const [
          {'card_id': 'commander-1', 'quantity': 1, 'is_commander': true},
          {'card_id': 'spell-1', 'quantity': 2, 'is_commander': false},
          {'card_id': 'land-1', 'quantity': 3, 'is_commander': false},
        ],
        catalogCards: const [
          {
            'id': 'commander-1',
            'name': 'Commander',
            'type_line': 'Legendary Creature',
            'mana_cost': '{2}{R}',
            'cmc': 3.0,
            'colors': ['R'],
            'color_identity': ['R'],
          },
          {
            'id': 'spell-1',
            'name': 'Spell',
            'type_line': 'Sorcery',
            'mana_cost': '{1}{R}',
            'cmc': 2.0,
            'colors': ['R'],
            'color_identity': ['R'],
          },
          {
            'id': 'land-1',
            'name': 'Mountain',
            'type_line': 'Basic Land - Mountain',
            'oracle_text': '{T}: Add {R}.',
            'cmc': 0.0,
            'colors': <String>[],
            'color_identity': ['R'],
          },
        ],
      );

      expect(analysis['schema_version'], appliedDeckPostAnalysisVersion);
      expect(analysis['source'], 'postgres_persisted_card_catalog');
      expect(analysis['analysis_scope'], 'accepted_changes_only');
      expect(analysis['server_recomputed'], isTrue);
      expect(analysis['total_cards'], 6);
      expect(analysis['average_cmc'], '2.33');
      expect((analysis['type_distribution'] as Map)['lands'], 3);
    });

    test('fails closed when a persisted card cannot be resolved', () {
      expect(
        () => buildAppliedDeckPostAnalysis(
          persistedCards: const [
            {'card_id': 'missing', 'quantity': 1},
          ],
          catalogCards: const <Map<String, dynamic>>[],
        ),
        throwsStateError,
      );
    });
  });
}
