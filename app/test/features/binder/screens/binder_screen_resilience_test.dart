import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/screens/binder_screen.dart';
import 'package:provider/provider.dart';

class _SequenceBinderProvider extends BinderProvider {
  _SequenceBinderProvider(this.haveResponses);

  final List<List<BinderItem>?> haveResponses;
  final requestedPages = <int>[];
  var _haveIndex = 0;

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
  }) async {
    if (listType != 'have') return const [];
    requestedPages.add(page);
    final index = _haveIndex.clamp(0, haveResponses.length - 1);
    _haveIndex++;
    return haveResponses[index];
  }
}

class _ControlledBinderRequest {
  _ControlledBinderRequest({required this.page, required this.search});

  final int page;
  final String? search;
  final completer = Completer<List<BinderItem>?>();
}

class _ControlledBinderProvider extends BinderProvider {
  final requests = <_ControlledBinderRequest>[];

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
  }) {
    if (listType != 'have') {
      return Future<List<BinderItem>?>.value(const <BinderItem>[]);
    }
    final request = _ControlledBinderRequest(page: page, search: search);
    requests.add(request);
    return request.completer.future;
  }
}

Widget _subject(_SequenceBinderProvider provider) {
  return ChangeNotifierProvider<BinderProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(body: BinderTabContent()),
    ),
  );
}

Widget _controlledSubject(_ControlledBinderProvider provider) {
  return ChangeNotifierProvider<BinderProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(body: BinderTabContent()),
    ),
  );
}

BinderItem _item(int index) {
  return BinderItem(
    id: 'binder-$index',
    cardId: 'card-$index',
    cardName: 'Carta $index',
  );
}

void main() {
  testWidgets(
    'binder distinguishes physical entry availability from playable total',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = _SequenceBinderProvider([
        [
          BinderItem(
            id: 'binder-physical',
            cardId: 'printing-pt',
            cardName: 'Sol Ring',
            quantity: 1,
            language: 'pt-br',
            availableQuantity: 1,
            ownedQuantity: 4,
            allocatedQuantity: 2,
            committedTradeQuantity: 1,
            freeQuantity: 2,
            missingQuantity: 0,
          ),
        ],
      ]);

      await tester.pumpWidget(_subject(provider));
      await tester.pumpAndSettle();

      expect(find.text('PT-BR'), findsOneWidget);
      expect(find.text('Disponível 1'), findsOneWidget);
      expect(find.text('Livre total 2'), findsOneWidget);
      expect(find.text('Alocada 2'), findsOneWidget);
      expect(find.text('Em trade 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('direct binder distinguishes failure from an empty collection', (
    tester,
  ) async {
    final provider = _SequenceBinderProvider([null, null]);

    await tester.pumpWidget(_subject(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('binder-list-error-have')), findsOneWidget);
    expect(find.byKey(const Key('binder-list-empty-have')), findsNothing);

    await tester.tap(find.text('Tentar novamente').first);
    await tester.pumpAndSettle();
    expect(provider.requestedPages, [1, 1]);
  });

  testWidgets(
    'pagination failure preserves loaded cards, stops spinner and offers retry',
    (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = _SequenceBinderProvider([
        List.generate(20, _item),
        null,
        [_item(20)],
      ]);

      await tester.pumpWidget(_subject(provider));
      await tester.pumpAndSettle();

      final list = find.byKey(const Key('binder-list-have'));
      await tester.drag(list, const Offset(0, -1800));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('binder-pagination-error-have')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('binder-list-have')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(provider.requestedPages, [1, 2]);

      await tester.tap(find.byKey(const Key('binder-pagination-retry-have')));
      await tester.pumpAndSettle();

      expect(provider.requestedPages, [1, 2, 2]);
      expect(
        find.byKey(const Key('binder-pagination-error-have')),
        findsNothing,
      );
      expect(find.byKey(const Key('binder-list-have')), findsOneWidget);
    },
  );

  testWidgets(
    'new filter supersedes an in-flight page and ignores its stale response',
    (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = _ControlledBinderProvider();
      await tester.pumpWidget(_controlledSubject(provider));
      await tester.pump();

      expect(provider.requests, hasLength(1));
      provider.requests.single.completer.complete(List.generate(20, _item));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('binder-list-have')),
        const Offset(0, -1800),
      );
      await tester.pump();
      expect(provider.requests, hasLength(2));
      expect(provider.requests[1].page, 2);

      await tester.enterText(
        find.byKey(const Key('binder-search-field')),
        'filtrada',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(provider.requests, hasLength(3));
      expect(provider.requests[2].page, 1);
      expect(provider.requests[2].search, 'filtrada');

      final filtered = BinderItem(
        id: 'filtered',
        cardId: 'filtered-card',
        cardName: 'Carta filtrada',
      );
      provider.requests[2].completer.complete([filtered]);
      await tester.pumpAndSettle();
      expect(find.text('Carta filtrada'), findsOneWidget);
      expect(find.text('Carta 0'), findsNothing);

      provider.requests[1].completer.complete([_item(99)]);
      await tester.pumpAndSettle();

      expect(find.text('Carta filtrada'), findsOneWidget);
      expect(find.text('Carta 99'), findsNothing);
    },
  );
}
