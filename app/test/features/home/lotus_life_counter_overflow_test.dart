import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:manaloom/features/home/lotus/lotus_host.dart';
import 'package:manaloom/features/home/lotus/lotus_js_bridges.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLotusHost implements LotusHost {
  @override
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  @override
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  @override
  Widget buildView(BuildContext context) {
    return const ColoredBox(
      key: Key('fake-lotus-host-view'),
      color: Colors.black,
    );
  }

  @override
  void suppressStaleBeforeUnloadSnapshot() {}

  @override
  Future<void> loadBundle() async {}

  @override
  Future<void> runJavaScript(String script) async {}

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async => null;

  @override
  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
  }
}

Widget _buildScreen(_FakeLotusHost host) {
  return MaterialApp(
    home: LotusLifeCounterScreen(
      hostFactory: ({
        required LotusAppReviewCallback onAppReviewRequested,
        required LotusShellMessageCallback onShellMessageRequested,
      }) {
        return host;
      },
    ),
  );
}

Future<void> _pumpWithSize(
  WidgetTester tester,
  _FakeLotusHost host,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(_buildScreen(host));
  await tester.pumpAndSettle();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall methodCall) async => null,
        );
  });

  group('LotusLifeCounterScreen overflow', () {
    testWidgets('no overflow at 280px — loaded state', (tester) async {
      final host = _FakeLotusHost();
      host.isLoading.value = false;
      host.errorMessage.value = null;

      await _pumpWithSize(tester, host, const Size(280, 653));
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 375px — loaded state', (tester) async {
      final host = _FakeLotusHost();
      host.isLoading.value = false;
      host.errorMessage.value = null;

      await _pumpWithSize(tester, host, const Size(375, 812));
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 320px with text scaler 1.3', (tester) async {
      final host = _FakeLotusHost();
      host.isLoading.value = false;
      host.errorMessage.value = null;

      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.pumpWidget(_buildScreen(host));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
