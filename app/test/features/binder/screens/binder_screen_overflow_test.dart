import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/screens/binder_screen.dart';
import 'package:provider/provider.dart';

class _TestBinderProvider extends BinderProvider {
  _TestBinderProvider({
    this.mockIsLoading = false,
    this.mockErrorMessage,
    this.mockItems = const [],
  });
  final bool mockIsLoading;
  final String? mockErrorMessage;
  final List<BinderItem> mockItems;

  @override
  bool get isLoading => mockIsLoading;
  String? get statsError => mockErrorMessage;
  @override
  Future<void> fetchStats() async {}

  @override
  Future<List<BinderItem>?> fetchBinderDirect({
    required String listType,
    int page = 1,
    int limit = 20,
    String? condition,
    String? search,
    bool? forTrade,
    bool? forSale,
    String? setCode,
    String? rarity,
    String? language,
    bool? foil,
    String sortBy = 'name',
    String sortOrder = 'asc',
  }) async => mockItems;
}

Widget _buildScreen({
  bool isLoading = false,
  String? errorMessage,
  List<BinderItem> items = const [],
}) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider<BinderProvider>(
        create:
            (_) => _TestBinderProvider(
              mockIsLoading: isLoading,
              mockErrorMessage: errorMessage,
              mockItems: items,
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
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
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

  testWidgets('BinderTabContent bounds canvas and uses two columns at 1280px', (
    tester,
  ) async {
    final items = [
      BinderItem(id: 'one', cardId: 'card-one', cardName: 'Sol Ring'),
      BinderItem(id: 'two', cardId: 'card-two', cardName: 'Arcane Signet'),
    ];
    await _pumpWithSize(
      tester,
      const Size(1280, 900),
      _buildScreen(items: items),
    );

    expect(find.byKey(const Key('binder-grid-have')), findsOneWidget);
    expect(find.byKey(const Key('binder-list-have')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('binder-responsive-canvas'))).width,
      lessThanOrEqualTo(1280),
    );
    expect(tester.takeException(), isNull);
  });
}
