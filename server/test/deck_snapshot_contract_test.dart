import 'dart:io';

import 'package:server/deck_snapshot_contract.dart';
import 'package:test/test.dart';

void main() {
  group('deck snapshot contract', () {
    test('deck_version_at is the revision time, never the request time '
        '(LC-P0-05)', () {
      final sql = deckVersionAtSql('d');
      expect(
        sql,
        'COALESCE((SELECT version_event.created_at '
        'FROM deck_change_events version_event '
        'WHERE version_event.deck_id = d.id '
        'AND version_event.revision_after = d.revision), d.created_at, '
        "TIMESTAMPTZ '1970-01-01 00:00:00+00')",
      );
      expect(sql.toLowerCase(), isNot(contains('now()')));
      expect(sql.toLowerCase(), isNot(contains('current_timestamp')));
      final route = File('routes/decks/[id]/index.dart').readAsStringSync();
      expect(route, contains("deckVersionAtSql('decks')"));
      expect(route, isNot(contains("'deck_version_at': DateTime.now()")));
      final service =
          File('lib/retention/post_game_note_service.dart').readAsStringSync();
      expect(service, contains("deckVersionAtSql('d')"));
      expect(service, isNot(contains('capturedAt: DateTime.now()')));
    });

    test('is deterministic across database and API row ordering', () {
      final first = buildDeckSnapshotHash(
        name: 'Lorehold',
        format: 'commander',
        cards: const [
          {'card_id': 'card-b', 'quantity': 2, 'is_commander': false},
          {'card_id': 'card-a', 'quantity': 1, 'is_commander': true},
        ],
      );
      final second = buildDeckSnapshotHash(
        name: 'Lorehold',
        format: 'commander',
        cards: const [
          {'id': 'card-a', 'quantity': 1, 'is_commander': true},
          {'id': 'card-b', 'quantity': 2, 'is_commander': false},
        ],
      );

      expect(first, second);
      expect(first, hasLength(64));
    });

    test('changes for gameplay-relevant deck revisions', () {
      String snapshot({int quantity = 1, bool commander = false}) =>
          buildDeckSnapshotHash(
            name: 'Lorehold',
            format: 'commander',
            cards: [
              {
                'card_id': 'card-a',
                'quantity': quantity,
                'is_commander': commander,
              },
            ],
          );

      expect(snapshot(quantity: 1), isNot(snapshot(quantity: 2)));
      expect(snapshot(), isNot(snapshot(commander: true)));
      expect(
        snapshot(),
        isNot(
          buildDeckSnapshotHash(
            name: 'Renamed',
            format: 'commander',
            cards: const [
              {'card_id': 'card-a', 'quantity': 1, 'is_commander': false},
            ],
          ),
        ),
      );
    });

    test('keeps a stable identity for an empty draft', () {
      final hash = buildDeckSnapshotHash(
        name: 'Draft',
        format: 'commander',
        cards: const [],
      );

      expect(hash, hasLength(64));
    });
  });
}
