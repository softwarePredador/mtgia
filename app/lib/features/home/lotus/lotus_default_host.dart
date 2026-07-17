import 'lotus_host.dart';
import 'lotus_js_bridges.dart';
import 'lotus_default_host_native.dart'
    if (dart.library.js_interop) 'lotus_default_host_web.dart'
    as platform;

LotusHost createDefaultLotusHost({
  required LotusAppReviewCallback onAppReviewRequested,
  required LotusShellMessageCallback onShellMessageRequested,
}) {
  return platform.createDefaultLotusHost(
    onAppReviewRequested: onAppReviewRequested,
    onShellMessageRequested: onShellMessageRequested,
  );
}
