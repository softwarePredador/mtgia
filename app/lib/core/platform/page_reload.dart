import 'page_reload_stub.dart'
    if (dart.library.js_interop) 'page_reload_web.dart'
    as impl;

/// True where the running code can be replaced by reloading the page (Web).
bool get canReloadPage => impl.canReloadPage;

/// Reloads the page, so the browser fetches the current release.
void reloadPage() => impl.reloadPage();
