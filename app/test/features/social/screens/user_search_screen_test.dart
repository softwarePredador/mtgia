import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/social/providers/social_provider.dart';
import 'package:manaloom/features/social/screens/user_search_screen.dart';
import 'package:provider/provider.dart';

class _FakeSocialProvider extends SocialProvider {
  _FakeSocialProvider({this.forcedSearchError});

  final String? forcedSearchError;
  int clearCalls = 0;
  final List<String> searchQueries = <String>[];

  @override
  String? get searchError => forcedSearchError;

  @override
  Future<void> searchUsers(String query) async {
    searchQueries.add(query);
  }

  @override
  void clearSearch() {
    clearCalls += 1;
  }
}

void main() {
  testWidgets('user search only exposes clear action when query is present', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final provider = _FakeSocialProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<SocialProvider>.value(
        value: provider,
        child: const MaterialApp(home: UserSearchScreen()),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('user-search-content'))).width,
      lessThanOrEqualTo(390),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('user-search-clear-button')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('user-search-field')),
      'Rafael',
    );
    await tester.pump();
    expect(find.byKey(const Key('user-search-clear-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('user-search-clear-button')));
    await tester.pump();

    expect(find.byKey(const Key('user-search-clear-button')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('user-search-field')))
          .controller
          ?.text,
      isEmpty,
    );
    expect(provider.clearCalls, 1);

    tester.view.physicalSize = const Size(1280, 900);
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const Key('user-search-content'))).width,
      lessThanOrEqualTo(840),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('user search error offers retry with the current query', (
    tester,
  ) async {
    final provider = _FakeSocialProvider(
      forcedSearchError: 'Não foi possível buscar agora.',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SocialProvider>.value(
        value: provider,
        child: const MaterialApp(home: UserSearchScreen()),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('user-search-field')),
      '  Atraxa  ',
    );
    await tester.pump();

    expect(find.byKey(const Key('user-search-error')), findsOneWidget);
    expect(find.text('Falha ao buscar jogadores'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Tentar novamente'));
    await tester.pump();

    expect(provider.searchQueries, ['Atraxa']);
  });
}
