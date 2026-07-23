import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter_route.dart';

void main() {
  group('lifeCounterRouteLocation', () {
    test('keeps the canonical route without empty context', () {
      expect(lifeCounterRouteLocation(), lifeCounterRoutePath);
      expect(
        lifeCounterRouteLocation(deckId: '  ', deckName: ''),
        lifeCounterRoutePath,
      );
    });

    test('encodes deck context as URL-safe query parameters', () {
      final location = lifeCounterRouteLocation(
        deckId: 'deck/42',
        deckName: 'Atraxa + marcadores',
        deckSnapshotHash:
            'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        deckVersionAtEpochMs: 1784714400000,
      );
      final uri = Uri.parse(location);

      expect(uri.path, lifeCounterRoutePath);
      expect(uri.queryParameters['deckId'], 'deck/42');
      expect(uri.queryParameters['deckName'], 'Atraxa + marcadores');
      expect(
        uri.queryParameters['deckSnapshotHash'],
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );
      expect(uri.queryParameters['deckVersionAt'], '1784714400000');
    });

    test('omits incomplete or invalid deck version metadata', () {
      final incomplete = Uri.parse(
        lifeCounterRouteLocation(
          deckId: 'deck-42',
          deckSnapshotHash:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
      );
      final invalid = Uri.parse(
        lifeCounterRouteLocation(
          deckId: 'deck-42',
          deckSnapshotHash: 'not-a-sha256',
          deckVersionAtEpochMs: 1784714400000,
        ),
      );

      expect(incomplete.queryParameters['deckId'], 'deck-42');
      expect(incomplete.queryParameters, isNot(contains('deckSnapshotHash')));
      expect(incomplete.queryParameters, isNot(contains('deckVersionAt')));
      expect(invalid.queryParameters, isNot(contains('deckSnapshotHash')));
      expect(invalid.queryParameters, isNot(contains('deckVersionAt')));
    });
  });

  test('exit result only exposes a valid non-negative duration', () {
    const completed = LifeCounterExitResult(
      hadGameActivity: true,
      storageFlushed: true,
      startedAtEpochMs: 1000,
      deckSnapshotHash:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      deckVersionAtEpochMs: 500,
      endedAtEpochMs: 61000,
    );
    const invalid = LifeCounterExitResult(
      hadGameActivity: false,
      storageFlushed: false,
      startedAtEpochMs: 2000,
      endedAtEpochMs: 1000,
    );

    expect(completed.duration, const Duration(minutes: 1));
    expect(completed.deckVersionAtEpochMs, 500);
    expect(invalid.duration, isNull);
  });
}
