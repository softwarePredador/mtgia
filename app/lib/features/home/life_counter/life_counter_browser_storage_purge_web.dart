import 'package:web/web.dart' as web;

/// Removes the raw `window.localStorage` keys the Web Lotus host writes
/// outside SharedPreferences. Returns how many keys were removed.
int purgeBrowserLocalStorage(bool Function(String key) shouldRemove) {
  try {
    final storage = web.window.localStorage;
    final keys = <String>[
      for (var index = 0; index < storage.length; index += 1)
        ?storage.key(index),
    ];
    var removed = 0;
    for (final key in keys) {
      if (!shouldRemove(key)) continue;
      storage.removeItem(key);
      removed += 1;
    }
    return removed;
  } catch (_) {
    return 0;
  }
}
