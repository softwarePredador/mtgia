import 'package:web/web.dart' as web;

bool get canReloadPage => true;

void reloadPage() => web.window.location.reload();
