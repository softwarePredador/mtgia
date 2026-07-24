import 'dart:async';

typedef ScryfallImageClock = DateTime Function();
typedef ScryfallImageDelay = Future<void> Function(Duration duration);

/// Serializes the start of Scryfall API image requests.
///
/// Card images hosted by the Scryfall CDN do not need this gate. It is only
/// used for image responses from `api.scryfall.com/cards/...`, which share the
/// public API rate limit.
class ScryfallImageRequestGate {
  ScryfallImageRequestGate({
    this.minimumInterval = const Duration(milliseconds: 125),
    ScryfallImageClock? clock,
    ScryfallImageDelay? delay,
  }) : _clock = clock ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed;

  final Duration minimumInterval;
  final ScryfallImageClock _clock;
  final ScryfallImageDelay _delay;

  Future<void> _tail = Future<void>.value();
  DateTime? _lastPermitAt;

  /// Completes when the caller may start its request.
  ///
  /// Concurrent callers are kept in arrival order and receive permits at
  /// least [minimumInterval] apart.
  Future<void> acquire() {
    final scheduled = _tail.then((_) async {
      final lastPermitAt = _lastPermitAt;
      if (lastPermitAt != null) {
        final elapsed = _clock().difference(lastPermitAt);
        final remaining = minimumInterval - elapsed;
        if (remaining > Duration.zero) {
          await _delay(remaining);
        }
      }
      _lastPermitAt = _clock();
    });

    // A failed injected clock/delay must not permanently block later callers.
    _tail = scheduled.catchError((Object _) {});
    return scheduled;
  }
}

/// Retry policy for transient failures from Scryfall API image lookups.
class ScryfallImageRetryPolicy {
  const ScryfallImageRetryPolicy({
    this.delays = const <Duration>[
      Duration(milliseconds: 500),
      Duration(milliseconds: 1500),
    ],
  });

  final List<Duration> delays;

  /// Returns the delay for a zero-based retry, or `null` when retries ended.
  Duration? delayForRetry(int retryIndex) {
    if (retryIndex < 0 || retryIndex >= delays.length) {
      return null;
    }
    return delays[retryIndex];
  }
}

bool isScryfallApiImageUrl(String imageUrl) {
  final uri = Uri.tryParse(imageUrl);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host.toLowerCase() == 'api.scryfall.com' &&
      uri.pathSegments.length >= 2 &&
      uri.pathSegments.first == 'cards' &&
      uri.queryParameters['format']?.toLowerCase() == 'image';
}

final scryfallImageRequestGate = ScryfallImageRequestGate();
const scryfallImageRetryPolicy = ScryfallImageRetryPolicy();
