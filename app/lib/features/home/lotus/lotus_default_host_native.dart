import 'lotus_host.dart';
import 'lotus_host_controller.dart';
import 'lotus_js_bridges.dart';

LotusHost createDefaultLotusHost({
  required LotusAppReviewCallback onAppReviewRequested,
  required LotusShellMessageCallback onShellMessageRequested,
}) {
  return LotusHostController(
    onAppReviewRequested: onAppReviewRequested,
    onShellMessageRequested: onShellMessageRequested,
  );
}
