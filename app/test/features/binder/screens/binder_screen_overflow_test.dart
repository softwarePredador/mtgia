import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/screens/binder_screen.dart';
import 'package:provider/provider.dart';

class _TestBinderProvider extends BinderProvider {
  _TestBinderProvider({this.mockIsLoading = false, this.mockErrorMessage});
  final bool mockIsLoading;
  final String? mockErrorMessage;

  @override
  bool get isLoading => mockIsLoading;
  String? get statsError => mockErrorMessage;
  @override
  Future<void> fetchStats() async {}
  Future<void> fetchItems({bool reset = false}) async {}
}

Widget _buildScreen({bool isLoading = false, String? errorMessage}) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider<BinderProvider>(
        create:
            (_) => _TestBinderProvider(
              mockIsLoading: isLoading,
              mockErrorMessage: errorMessage,
            ),
        child: const BinderTabContent(),
      ),
    ),
  );
}

Future<void> _pumpWithSize(
  WidgetTester tester,
  Size size,
  Widget widget,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  testWidgets('BinderTabContent no overflow at 320px', (tester) async {
    await _pumpWithSize(tester, const Size(320, 568), _buildScreen());
    expect(tester.takeException(), isNull);
  });

  testWidgets('BinderTabContent no overflow at 375px', (tester) async {
    await _pumpWithSize(tester, const Size(375, 812), _buildScreen());
    expect(tester.takeException(), isNull);
  });
}
