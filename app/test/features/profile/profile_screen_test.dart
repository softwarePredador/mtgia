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
import 'package:manaloom/features/social/providers/social_provider.dart';
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
    'display_name': 'Marina — Arquivista de Comandantes do Litoral',
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
    if (endpoint == '/users/me/blocks') {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'blocked-1',
            'username': 'ofertas_inseguras',
            'display_name': 'Conta bloqueada',
            'blocked_at': '2026-08-01T10:00:00Z',
          },
        ],
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
            ChangeNotifierProvider<SocialProvider>(
              create: (_) => SocialProvider(apiClient: api),
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
      expect(find.text('@runtime_profile'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byKey(const Key('profile-identity-name')))
            .label,
        contains('Marina — Arquivista de Comandantes do Litoral'),
      );
      expect(find.text('Initial notes'), findsOneWidget);
      expect(find.byKey(const Key('profile-identity-rail')), findsOneWidget);
      expect(
        find.byKey(const Key('profile-settings-workspace')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-display-name-field')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('profile-city-field')), findsOneWidget);
      expect(
        find.byKey(const Key('profile-trade-notes-field')),
        findsOneWidget,
      );
      final saveButton = find.byKey(const Key('profile-save-button'));
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
      expect(find.text('Tudo salvo'), findsOneWidget);

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
      await tester.pump();
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
      expect(find.text('Alterações não salvas'), findsOneWidget);
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
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
      expect(find.text('Alterações salvas'), findsOneWidget);

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

      final avatarButton = find.byKey(const Key('profile-avatar-edit-button'));
      await tester.scrollUntilVisible(
        avatarButton,
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(avatarButton);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-avatar-dialog')), findsOneWidget);
      expect(
        find.byKey(const Key('profile-avatar-privacy-notice')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('profile-avatar-url-field')),
        'https://127.0.0.1/avatar.png',
      );
      await tester.tap(find.byKey(const Key('profile-avatar-apply-button')));
      await tester.pump();
      expect(
        find.text(
          'Use um endereço público; links locais ou de rede privada não são aceitos.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('profile-avatar-cancel-button')));
      await tester.pumpAndSettle();

      final changePassword = find.byKey(
        const Key('profile-change-password-button'),
      );
      await tester.scrollUntilVisible(
        changePassword,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(changePassword);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('profile-change-password-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-password-requirements')),
        findsOneWidget,
      );
      final newPasswordField = find.byKey(
        const Key('profile-new-password-field'),
      );
      EditableText passwordEditor() => tester.widget<EditableText>(
        find.descendant(
          of: newPasswordField,
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordEditor().obscureText, isTrue);
      await tester.tap(
        find.byKey(const Key('profile-new-password-visibility')),
      );
      await tester.pump();
      expect(passwordEditor().obscureText, isFalse);
      await tester.tap(
        find.byKey(const Key('profile-change-password-confirm-button')),
      );
      await tester.pump();
      expect(find.text('Informe sua senha atual.'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('profile-change-password-cancel-button')),
      );
      await tester.pumpAndSettle();

      final revokeSessions = find.byKey(
        const Key('profile-revoke-sessions-button'),
      );
      await tester.ensureVisible(revokeSessions);
      await tester.tap(revokeSessions);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('profile-revoke-sessions-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-revoke-password-visibility')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('profile-revoke-sessions-confirm-button')),
      );
      await tester.pump();
      expect(find.text('Informe sua senha atual.'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('profile-revoke-sessions-cancel-button')),
      );
      await tester.pumpAndSettle();

      final blockedUsers = find.byKey(
        const Key('profile-blocked-users-button'),
      );
      await tester.scrollUntilVisible(
        blockedUsers,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(blockedUsers);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('profile-blocked-users-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-blocked-users-list')),
        findsOneWidget,
      );
      final blockedUsername = find.byKey(
        const Key('profile-blocked-username-blocked-1'),
      );
      expect(find.text('@ofertas_inseguras'), findsOneWidget);
      expect(tester.widget<Text>(blockedUsername).maxLines, 1);
      expect(
        tester.getRect(blockedUsername).right,
        lessThanOrEqualTo(
          tester
              .getRect(find.byKey(const Key('profile-blocked-users-dialog')))
              .right,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('profile-blocked-users-close')));
      await tester.pumpAndSettle();

      final deleteAccount = find.byKey(
        const Key('profile-delete-account-button'),
      );
      await tester.scrollUntilVisible(
        deleteAccount,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(deleteAccount);
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
      expect(
        find.byKey(const Key('profile-delete-privacy-link')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile-delete-password-visibility')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('profile-delete-confirm-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('Digite a frase exatamente como exibida.'),
        findsOneWidget,
      );
      expect(find.text('Informe sua senha.'), findsOneWidget);
      expect(
        tester
            .widget<InputDecorator>(
              find.descendant(
                of: find.byKey(const Key('profile-delete-confirmation-field')),
                matching: find.byType(InputDecorator),
              ),
            )
            .decoration
            .errorMaxLines,
        2,
      );

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

      tester.view.physicalSize = const Size(1920, 1080);
      await tester.pumpAndSettle();
      final content = tester.getRect(find.byKey(const Key('profile-content')));
      final identity = tester.getRect(
        find.byKey(const Key('profile-identity-rail')),
      );
      final workspace = tester.getRect(
        find.byKey(const Key('profile-settings-workspace')),
      );
      expect(content.width, greaterThan(1100));
      expect(content.width, lessThanOrEqualTo(1280));
      expect(find.byKey(const Key('profile-wide-workbench')), findsOneWidget);
      expect(identity.right, lessThan(workspace.left));
      expect(tester.takeException(), isNull);
    },
  );
}
