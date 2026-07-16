import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/social/providers/social_provider.dart';
import 'package:manaloom/features/social/screens/user_search_screen.dart';
import 'package:provider/provider.dart';

class _FakeSocialProvider extends SocialProvider {
  int clearCalls = 0;

  @override
  Future<void> searchUsers(String query) async {}

  @override
  void clearSearch() {
    clearCalls += 1;
  }
}

void main() {
  testWidgets('user search only exposes clear action when query is present', (
    tester,
  ) async {
    final provider = _FakeSocialProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<SocialProvider>.value(
        value: provider,
        child: const MaterialApp(home: UserSearchScreen()),
      ),
    );

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
  });
}
