typedef SetIconSvgLoader = Future<String?> Function(String url);

/// Small in-memory cache for remote set icons.
///
/// Failed fetches expire quickly so a transient CDN/network error never turns
/// into a permanent generic placeholder for the rest of the app session.
class SetIconSvgCache {
  SetIconSvgCache({
    this.successTtl = const Duration(days: 7),
    this.failureTtl = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration successTtl;
  final Duration failureTtl;
  final DateTime Function() _clock;
  final Map<String, _SetIconSvgCacheEntry> _entries = {};

  Future<String?> resolve(String url, SetIconSvgLoader loader) {
    final now = _clock();
    final cached = _entries[url];
    if (cached != null && now.isBefore(cached.expiresAt)) {
      return cached.future;
    }

    final future = loader(url);
    final entry = _SetIconSvgCacheEntry(
      future: future,
      expiresAt: now.add(failureTtl),
    );
    _entries[url] = entry;
    future.then((svg) {
      if (!identical(_entries[url], entry)) return;
      entry.expiresAt = _clock().add(svg == null ? failureTtl : successTtl);
    });
    return future;
  }

  void invalidate(String url) => _entries.remove(url);

  void clear() => _entries.clear();
}

class _SetIconSvgCacheEntry {
  _SetIconSvgCacheEntry({required this.future, required this.expiresAt});

  final Future<String?> future;
  DateTime expiresAt;
}
