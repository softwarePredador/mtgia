import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/social/providers/social_provider.dart';
import 'package:manaloom/features/social/screens/user_profile_screen.dart';
import 'package:provider/provider.dart';

class _ProfileApiClient extends ApiClient {
  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint == '/community/users/user-2') {
      return ApiResponse(200, {
        'user': {
          'id': 'user-2',
          'username': 'planeswalker',
          'display_name': 'Planeswalker',
          'follower_count': 2,
          'following_count': 3,
          'public_deck_count': 0,
          'is_following': false,
          'is_own_profile': false,
        },
        'public_decks': <Map<String, dynamic>>[],
      });
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }
}

class _FailingPublicBinderProvider extends BinderProvider {
  int directCalls = 0;

  @override
  Future<void> fetchPublicBinder(String userId, {bool reset = false}) async {}

  @override
  Future<List<BinderItem>?> fetchPublicBinderDirect({
    required String userId,
    required String listType,
    int page = 1,
    int limit = 20,
  }) async {
    directCalls++;
    return null;
  }
}

void main() {
  testWidgets('UserProfileScreen preserva tabs mobile e limita desktop', (
    tester,
  ) async {
    final social = SocialProvider(apiClient: _ProfileApiClient());
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in const [Size(390, 844), Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SocialProvider>.value(value: social),
            ChangeNotifierProvider<BinderProvider>(
              create: (_) => BinderProvider(),
            ),
            ChangeNotifierProvider<MessageProvider>(
              create: (_) => MessageProvider(),
            ),
          ],
          child: const MaterialApp(home: UserProfileScreen(userId: 'user-2')),
        ),
      );
      await tester.pumpAndSettle();

      final contentWidth =
          tester.getSize(find.byKey(const Key('user-profile-content'))).width;
      expect(contentWidth, lessThanOrEqualTo(1120));
      expect(contentWidth, lessThanOrEqualTo(size.width));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'fichario publico diferencia falha de lista vazia e permite retry',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final binder = _FailingPublicBinderProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SocialProvider>(
              create: (_) => SocialProvider(apiClient: _ProfileApiClient()),
            ),
            ChangeNotifierProvider<BinderProvider>.value(value: binder),
            ChangeNotifierProvider<MessageProvider>(
              create: (_) => MessageProvider(),
            ),
          ],
          child: const MaterialApp(home: UserProfileScreen(userId: 'user-2')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fichário'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('public-binder-error-have')), findsOneWidget);
      expect(
        find.text('Nenhuma carta disponível para troca/venda'),
        findsNothing,
      );
      final callsBeforeRetry = binder.directCalls;

      await tester.tap(find.text('Tentar novamente').first);
      await tester.pumpAndSettle();
      expect(binder.directCalls, greaterThan(callsBeforeRetry));
    },
  );
}
