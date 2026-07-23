import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/security/auth_token_store.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemorySecureTokenBackend implements SecureTokenBackend {
  String? value;

  @override
  Future<void> delete(String key) async => value = null;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _ProfileApiClient extends ApiClient {
  Map<String, dynamic> user = {
    'id': 'user-1',
    'username': 'runtime_profile',
    'email': 'runtime_profile@example.com',
    'display_name': 'Initial Runtime',
    'avatar_url': null,
    'location_state': 'RJ',
    'location_city': 'Rio de Janeiro',
    'trade_notes': 'Initial notes',
    'profile_visibility': 'public',
    'binder_visibility': 'public',
    'location_visibility': 'private',
    'message_visibility': 'everyone',
    'trade_visibility': 'everyone',
    'trade_notes_visibility': 'private',
  };

  Map<String, dynamic>? lastPatchBody;
  Map<String, dynamic>? lastDeleteBody;

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint == '/users/me') {
      return ApiResponse(200, {'user': Map<String, dynamic>.from(user)});
    }
    if (endpoint == '/users/me/export') {
      return ApiResponse(200, {
        'schema_version': 1,
        'account': {'id': 'user-1', 'email': user['email']},
        'data': {'decks': <Object>[]},
      });
    }
    fail('GET inesperado: $endpoint');
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    expect(endpoint, '/auth/login');
    return ApiResponse(200, {
      'token': 'profile-test-token',
      'user': Map<String, dynamic>.from(user),
    });
  }

  @override
  Future<ApiResponse> patch(String endpoint, Map<String, dynamic> body) async {
    expect(endpoint, '/users/me');
    lastPatchBody = body;
    user = {...user, ...body};
    return ApiResponse(200, {'user': Map<String, dynamic>.from(user)});
  }

  @override
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    expect(endpoint, '/users/me');
    lastDeleteBody = body;
    return ApiResponse(401, {'error': 'invalid_password'});
  }
}

void main() {
  testWidgets(
    'ProfileScreen edits supported fields and refreshes persisted data',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      SharedPreferences.setMockInitialValues({});
      final api = _ProfileApiClient();
      String? sharedData;
      final auth = AuthProvider(
        apiClient: api,
        tokenStore: AuthTokenStore(secureBackend: _MemorySecureTokenBackend()),
      );
      final loggedIn = await auth.login(
        'runtime_profile@example.com',
        'TestPassword123!',
      );
      expect(loggedIn, isTrue);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<MessageProvider>(
              create: (_) => MessageProvider(),
            ),
            ChangeNotifierProvider<NotificationProvider>(
              create: (_) => NotificationProvider(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: ProfileScreen(
              apiClient: api,
              shareData: (content) async => sharedData = content,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perfil'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('profile-content'))).width,
        lessThanOrEqualTo(390),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('runtime_profile'), findsOneWidget);
      expect(find.text('Initial notes'), findsOneWidget);
      expect(
        find.byKey(const Key('profile-display-name-field')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('profile-city-field')), findsOneWidget);
      expect(
        find.byKey(const Key('profile-trade-notes-field')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('profile-display-name-field')),
        'Runtime Nick Edited',
      );
      await tester.enterText(
        find.byKey(const Key('profile-city-field')),
        'Campinas',
      );
      await tester.enterText(
        find.byKey(const Key('profile-trade-notes-field')),
        'Runtime trade notes edited',
      );
      final saveButton = find.byKey(const Key('profile-save-button'));
      await tester.scrollUntilVisible(
        saveButton,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(api.lastPatchBody?['display_name'], 'Runtime Nick Edited');
      expect(api.lastPatchBody?['location_city'], 'Campinas');
      expect(api.lastPatchBody?['trade_notes'], 'Runtime trade notes edited');
      expect(api.lastPatchBody?['profile_visibility'], 'public');
      expect(api.lastPatchBody?['binder_visibility'], 'public');
      expect(api.lastPatchBody?['location_visibility'], 'private');
      expect(api.lastPatchBody?['message_visibility'], 'everyone');
      expect(api.lastPatchBody?['trade_visibility'], 'everyone');
      expect(api.lastPatchBody?['trade_notes_visibility'], 'private');
      expect(auth.user?.displayName, 'Runtime Nick Edited');

      final refreshed = await auth.refreshProfile();
      expect(refreshed, isTrue);
      expect(auth.user?.locationCity, 'Campinas');
      expect(auth.user?.tradeNotes, 'Runtime trade notes edited');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      final exportButton = find.byKey(const Key('profile-export-data-button'));
      await tester.scrollUntilVisible(
        exportButton,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(exportButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(sharedData, contains('"schema_version": 1'));
      expect(find.textContaining('Exportação preparada'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile-delete-account-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('profile-delete-account-dialog')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('profile-delete-confirmation-field')),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('profile-delete-account-dialog')),
        findsNothing,
      );

      final deleteButton = find.byKey(
        const Key('profile-delete-account-button'),
      );
      await tester.scrollUntilVisible(
        deleteButton,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-delete-confirm-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('Digite a frase exatamente como exibida.'),
        findsOneWidget,
      );
      expect(find.text('Informe sua senha.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('profile-delete-confirmation-field')),
        'EXCLUIR MINHA CONTA',
      );
      await tester.enterText(
        find.byKey(const Key('profile-delete-password-field')),
        'WrongPassword123!',
      );
      await tester.tap(find.byKey(const Key('profile-delete-confirm-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(api.lastDeleteBody, {
        'confirmation': 'EXCLUIR MINHA CONTA',
        'password': 'WrongPassword123!',
      });
      expect(
        find.text('Senha incorreta. Sua conta não foi alterada.'),
        findsOneWidget,
      );

      tester.view.physicalSize = const Size(1280, 900);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('profile-content'))).width,
        lessThanOrEqualTo(840),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
