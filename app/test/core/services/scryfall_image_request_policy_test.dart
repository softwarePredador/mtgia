import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/services/scryfall_image_request_policy.dart';

void main() {
  test('recognizes HTTPS Scryfall API image lookups', () {
    expect(
      isScryfallApiImageUrl(
        'https://api.scryfall.com/cards/named?exact=Island&format=image',
      ),
      isTrue,
    );
    expect(
      isScryfallApiImageUrl(
        'https://api.scryfall.com/cards/'
        '0000579f-7b35-4ed3-b44c-db2a538066fe?format=image&version=normal',
      ),
      isTrue,
    );
    expect(
      isScryfallApiImageUrl(
        'https://cards.scryfall.io/normal/front/a/b/card.jpg',
      ),
      isFalse,
    );
    expect(
      isScryfallApiImageUrl('https://api.scryfall.com/cards/search?q=Island'),
      isFalse,
    );
    expect(
      isScryfallApiImageUrl(
        'http://api.scryfall.com/cards/named?exact=Island&format=image',
      ),
      isFalse,
    );
  });

  test('serializes concurrent permits with a minimum start interval', () async {
    var now = DateTime.utc(2026, 7, 24);
    final waits = <Duration>[];
    final gate = ScryfallImageRequestGate(
      minimumInterval: const Duration(milliseconds: 125),
      clock: () => now,
      delay: (duration) async {
        waits.add(duration);
        now = now.add(duration);
      },
    );

    await Future.wait(<Future<void>>[
      gate.acquire(),
      gate.acquire(),
      gate.acquire(),
    ]);

    expect(waits, const <Duration>[
      Duration(milliseconds: 125),
      Duration(milliseconds: 125),
    ]);
  });

  test('a failed permit does not poison the request queue', () async {
    var calls = 0;
    final gate = ScryfallImageRequestGate(
      minimumInterval: const Duration(milliseconds: 125),
      clock: () => DateTime.utc(2026, 7, 24),
      delay: (_) async {
        calls += 1;
        if (calls == 1) {
          throw StateError('synthetic delay failure');
        }
      },
    );

    await gate.acquire();
    await expectLater(gate.acquire(), throwsStateError);
    await expectLater(gate.acquire(), completes);
  });

  test('uses bounded exponential retry delays', () {
    const policy = ScryfallImageRetryPolicy();

    expect(policy.delayForRetry(0), const Duration(milliseconds: 500));
    expect(policy.delayForRetry(1), const Duration(milliseconds: 1500));
    expect(policy.delayForRetry(2), isNull);
    expect(policy.delayForRetry(-1), isNull);
  });
}
