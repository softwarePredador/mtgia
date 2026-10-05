import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/config/release_capabilities.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/binder/models/binder_import_models.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/screens/binder_import_screen.dart';
import 'package:manaloom/features/binder/screens/binder_screen.dart';
import 'package:manaloom/features/binder/services/binder_import_draft_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BT-SCN-00 F2: the scanner CTA needs both the server capability and the
/// artifact build support. These tests drive the real screens through the
/// capability provider instead of passing the final boolean in.

class _FixedBinderProvider extends BinderProvider {
  _FixedBinderProvider({required this.items, this.withStats = false});

  final List<BinderItem> items;
  final bool withStats;

  @override
  Future<void> fetchStats() async {}

  @override
  BinderStats? get stats => withStats
      ? BinderStats(
          totalItems: 3,
          uniqueCards: 3,
          duplicateCopies: 0,
          forTradeCount: 0,
          forSaleCount: 0,
          wishlistCount: 0,
          priceMissingCount: 0,
          cardsUsedInDecks: 0,
          ownedQuantity: 3,
          allocatedQuantity: 0,
          freeQuantity: 3,
        )
      : null;

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
  }) async => listType == 'have' && page == 1 ? items : const [];
}

class _EmptyImportApi extends ApiClient {
  @override
  Future<ApiResponse> get(String endpoint) async =>
      ApiResponse(200, const {'data': <Object?>[]});
}

class _EmptyDraftStore extends BinderImportDraftStore {
  @override
  Future<BinderImportDraft?> loadDraft(String ownerId) async => null;

  @override
  Future<List<BinderImportBatchHistory>> loadHistory(String ownerId) async =>
      const [];
}

ReleaseCapabilitiesProvider _capabilities({required bool scanner}) =>
    ReleaseCapabilitiesProvider.seeded({
      ReleaseCapability.collectionPrivate,
      ReleaseCapability.catalogPrivate,
      if (scanner) ReleaseCapability.scanner,
    });

const _gateCases = <({bool capability, bool build, bool visible})>[
  (capability: false, build: false, visible: false),
  (capability: true, build: false, visible: false),
  (capability: false, build: true, visible: false),
  (capability: true, build: true, visible: true),
];

Future<void> _pumpBinder(
  WidgetTester tester, {
  required BinderProvider binder,
  required ReleaseCapabilitiesProvider capabilities,
  required bool build,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BinderProvider>.value(value: binder),
        ChangeNotifierProvider<ReleaseCapabilitiesProvider>.value(
          value: capabilities,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: BinderTabContent(scannerBuildSupported: build)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final gate in _gateCases) {
    final label =
        'capability ${gate.capability ? 'ON' : 'OFF'}, '
        'build ${gate.build ? 'ON' : 'OFF'}';
    final expected = gate.visible ? findsOneWidget : findsNothing;

    testWidgets('binder stats bar scan action: $label', (tester) async {
      final capabilities = _capabilities(scanner: gate.capability);
      addTearDown(capabilities.dispose);
      await _pumpBinder(
        tester,
        binder: _FixedBinderProvider(
          items: [BinderItem(id: 'b-1', cardId: 'c-1', cardName: 'Sol Ring')],
          withStats: true,
        ),
        capabilities: capabilities,
        build: gate.build,
      );

      expect(find.byKey(const Key('binder-scan-card-action')), expected);
    });

    testWidgets('compact binder scan action: $label', (tester) async {
      final capabilities = _capabilities(scanner: gate.capability);
      addTearDown(capabilities.dispose);
      await _pumpBinder(
        tester,
        binder: _FixedBinderProvider(
          items: [BinderItem(id: 'b-1', cardId: 'c-1', cardName: 'Sol Ring')],
        ),
        capabilities: capabilities,
        build: gate.build,
      );

      expect(
        find.byKey(const Key('binder-compact-import-action')),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Escanear'), expected);
    });

    testWidgets('empty binder scan action: $label', (tester) async {
      final capabilities = _capabilities(scanner: gate.capability);
      addTearDown(capabilities.dispose);
      await _pumpBinder(
        tester,
        binder: _FixedBinderProvider(items: const []),
        capabilities: capabilities,
        build: gate.build,
      );

      expect(find.byKey(const Key('binder-empty-scan-have')), expected);
    });

    testWidgets('binder import scanner session: $label', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final capabilities = _capabilities(scanner: gate.capability);
      addTearDown(capabilities.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<ReleaseCapabilitiesProvider>.value(
          value: capabilities,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: BinderImportScreen(
              ownerId: 'user-1',
              apiClient: _EmptyImportApi(),
              draftStore: _EmptyDraftStore(),
              scannerBuildSupported: gate.build,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('binder-import-screen')), findsOneWidget);
      expect(
        find.byKey(const Key('binder-import-scanner-session-button')),
        expected,
      );
    });
  }
}
