import 'package:server/deck_snapshot_contract.dart';
import 'package:test/test.dart';

void main() {
  group('deck snapshot contract', () {
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
