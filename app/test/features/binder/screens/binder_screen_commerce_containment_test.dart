// A8 / D-04: o fichário só apresenta troca e venda quando a release permite.
// Provider ausente ou capability desligada fecham a superfície (fail-closed);
// cada controle responde à SUA capability.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/config/release_capabilities.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/screens/binder_screen.dart';
import 'package:provider/provider.dart';

class _OfferBinderProvider extends BinderProvider {
  @override
  Future<void> fetchStats() async {}

  @override
  BinderStats get stats => BinderStats(
    totalItems: 24,
    uniqueCards: 16,
    duplicateCopies: 8,
    forTradeCount: 4,
    forSaleCount: 2,
    wishlistCount: 3,
    priceMissingCount: 5,
    cardsUsedInDecks: 9,
    ownedQuantity: 24,
    allocatedQuantity: 8,
    freeQuantity: 16,
  );

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
  }) async => listType != 'have'
      ? const []
      : [
          BinderItem(
            id: 'binder-oferta',
            cardId: 'card-oferta',
            cardName: 'Sol Ring',
            forTrade: true,
            forSale: true,
            price: 12.5,
          ),
        ];
}

Future<void> _pump(
  WidgetTester tester, {
  Set<ReleaseCapability>? capabilities,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Widget app = ChangeNotifierProvider<BinderProvider>.value(
    value: _OfferBinderProvider(),
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(body: BinderTabContent()),
    ),
  );
  if (capabilities != null) {
    app = ChangeNotifierProvider<ReleaseCapabilitiesProvider>.value(
      value: ReleaseCapabilitiesProvider.seeded(capabilities),
      child: app,
    );
  }
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Finder _chip(String label) =>
    find.widgetWithText(FilterChip, label, skipOffstage: false);

void main() {
  testWidgets('sem provider de capabilities, nada de troca nem venda', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(const Key('binder-item-card-binder-oferta')), findsOneWidget);
    expect(_chip('Troca'), findsNothing);
    expect(_chip('Venda'), findsNothing);
    expect(find.text('Troca', skipOffstage: false), findsNothing);
    expect(find.text('Venda', skipOffstage: false), findsNothing);
    expect(find.textContaining('R\$ 12.50'), findsNothing);
  });

  testWidgets('capabilities fechadas escondem filtros, tags, preço e stats', (
    tester,
  ) async {
    await _pump(tester, capabilities: const {});

    expect(find.byKey(const Key('binder-item-card-binder-oferta')), findsOneWidget);
    expect(_chip('Troca'), findsNothing);
    expect(_chip('Venda'), findsNothing);
    expect(find.text('Troca', skipOffstage: false), findsNothing);
    expect(find.text('Venda', skipOffstage: false), findsNothing);
    expect(find.textContaining('R\$ 12.50'), findsNothing);
  });

  testWidgets('trades abre só Troca; marketplace abre só Venda e preço', (
    tester,
  ) async {
    await _pump(tester, capabilities: const {ReleaseCapability.trades});
    expect(_chip('Troca'), findsOneWidget);
    expect(_chip('Venda'), findsNothing);
    expect(find.textContaining('R\$ 12.50'), findsNothing);

    await _pump(tester, capabilities: const {ReleaseCapability.marketplace});
    expect(_chip('Troca'), findsNothing);
    expect(_chip('Venda'), findsOneWidget);
    expect(find.textContaining('R\$ 12.50'), findsOneWidget);
  });

  testWidgets('ambas as capabilities abertas mostram tudo', (tester) async {
    await _pump(
      tester,
      capabilities: const {
        ReleaseCapability.trades,
        ReleaseCapability.marketplace,
      },
    );
    expect(_chip('Troca'), findsOneWidget);
    expect(_chip('Venda'), findsOneWidget);
    expect(find.textContaining('R\$ 12.50'), findsOneWidget);
  });
}
