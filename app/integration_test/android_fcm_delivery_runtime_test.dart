import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/services/push_notification_service.dart';
import 'package:manaloom/core/services/realtime_notification_coordinator.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/messages/screens/chat_screen.dart';
import 'package:manaloom/features/messages/screens/message_inbox_screen.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/notifications/screens/notification_screen.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_test_helpers.dart';

enum _PushPhase { idle, foreground, backgroundTap }

class _RuntimeUser {
  const _RuntimeUser({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.token,
  });

  final String id;
  final String username;
  final String email;
  final String password;
  final String token;
}

class _RuntimeApi {
  _RuntimeApi(this.baseUrl);

  final String baseUrl;
  final http.Client _client = http.Client();

  Future<_RuntimeUser> registerUser(String prefix) async {
    final unique = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final username = '${prefix}_$unique';
    const password = 'Qa123456!';
    final data = await postJson(
      '/auth/register',
      {
        'username': username,
        'email': '$username@example.com',
        'password': password,
      },
      expected: {201},
    );
    final user = data['user'] as Map<String, dynamic>;
    return _RuntimeUser(
      id: user['id'] as String,
      username: username,
      email: '$username@example.com',
      password: password,
      token: data['token'] as String,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
    Set<int> expected = const {200, 201},
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    return _decode(response, expected: expected);
  }

  Future<Map<String, dynamic>> putJson(
    String endpoint,
    Map<String, dynamic> body, {
    required String token,
    Set<int> expected = const {200},
  }) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    return _decode(response, expected: expected);
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'x-request-id': 'qa-fcm-${DateTime.now().microsecondsSinceEpoch}',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(
    http.Response response, {
    required Set<int> expected,
  }) {
    if (!expected.contains(response.statusCode)) {
      fail(
        '${response.request?.method} ${response.request?.url.path} '
        '-> ${response.statusCode}: ${response.body}',
      );
    }
    if (response.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    fail('Expected JSON object, got ${response.body}');
  }

  void close() => _client.close();
}

class _RuntimeApp {
  _RuntimeApp({
    required this.widget,
    required this.router,
    required this.coordinator,
  });

  final Widget widget;
  final GoRouter router;
  final RealtimeNotificationCoordinator coordinator;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Android physical runtime proves real FCM foreground and tap', (
    tester,
  ) async {
    await binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => binding.setSurfaceSize(null));

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ApiClient.setToken(null);
    _resetMarkerFile();
    expect(ApiClient.baseUrl, isNotEmpty);

    final api = _RuntimeApi(ApiClient.baseUrl);
    addTearDown(api.close);

    final marker =
        'qa_fcm_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
    _log('FCM_RUNTIME_BASE_URL ${ApiClient.baseUrl}');
    _log('FCM_RUNTIME_MARKER $marker');

    final seller = await api.registerUser('${marker}_seller');
    final buyer = await api.registerUser('${marker}_buyer');
    _log(
      'FCM_RUNTIME_USERS_CREATED buyer_username=${buyer.username} '
      'buyer_suffix=${_suffix(buyer.id)} seller_username=${seller.username} '
      'seller_suffix=${_suffix(seller.id)}',
    );

    final auth = AuthProvider();
    final loggedIn = await auth.login(buyer.email, buyer.password);
    expect(loggedIn, isTrue);

    final notifications = NotificationProvider();
    final messages = MessageProvider();
    final trades = TradeProvider();
    final app = _runtimeApp(
      auth: auth,
      notifications: notifications,
      messages: messages,
      trades: trades,
      initialLocation: '/notifications',
    );

    var phase = _PushPhase.idle;
    final foregroundDelivery = Completer<RemoteMessage>();
    final tapDelivery = Completer<RemoteMessage>();
    final pushService = PushNotificationService();
    pushService.onForegroundMessage = (message) {
      _log(
        'FCM_FOREGROUND_CALLBACK type=${message.data['type'] ?? 'unknown'} '
        'has_reference=${message.data.containsKey('reference_id')}',
      );
      unawaited(app.coordinator.handleForegroundData(message.data));
      if (phase == _PushPhase.foreground && !foregroundDelivery.isCompleted) {
        foregroundDelivery.complete(message);
      }
    };
    pushService.onMessageTap = (message) {
      _log(
        'FCM_TAP_CALLBACK type=${message.data['type'] ?? 'unknown'} '
        'has_reference=${message.data.containsKey('reference_id')}',
      );
      app.coordinator.handleMessageTapData(message.data);
      if (phase == _PushPhase.backgroundTap && !tapDelivery.isCompleted) {
        tapDelivery.complete(message);
      }
    };

    await tester.pumpWidget(app.widget);
    await tester.pump();
    await pumpUntilFound(tester, find.text('Notificações'));
    await notifications.fetchNotifications();

    await pushService.init();
    await pushService.requestPermissionAndRegister();
    await pumpUntil(
      tester,
      () async => pushService.currentToken?.isNotEmpty == true,
      description: 'non-empty FCM token',
      attempts: 60,
      step: const Duration(milliseconds: 500),
    );
    final tokenRegistered = await api.putJson('/users/me/fcm-token', {
      'token': pushService.currentToken,
    }, token: buyer.token);
    expect(tokenRegistered['ok'], isTrue);
    _log('FCM_TOKEN_REGISTERED token_present=true');

    final conversation = await api.postJson('/conversations', {
      'user_id': buyer.id,
    }, token: seller.token);
    final conversationId = conversation['id'] as String;
    _log('FCM_CONVERSATION_READY suffix=${_suffix(conversationId)}');

    phase = _PushPhase.foreground;
    final foregroundMessage = '$marker foreground direct';
    _log('FCM_FOREGROUND_EVENT_POSTING');
    await api.postJson(
      '/conversations/$conversationId/messages',
      {'message': foregroundMessage},
      token: seller.token,
      expected: {201},
    );
    await foregroundDelivery.future.timeout(const Duration(seconds: 45));
    await tester.pump(const Duration(seconds: 2));
    await pumpUntilFound(tester, find.text(foregroundMessage));
    expect(notifications.unreadCount, greaterThan(0));
    _assertDirectMessagePayload(
      foregroundDelivery.future,
      conversationId: conversationId,
    );
    _log('FCM_FOREGROUND_DELIVERY_PASS');

    phase = _PushPhase.backgroundTap;
    final backgroundMessage = '$marker background tap';
    _log(
      'FCM_BACKGROUND_EXTERNAL_TRIGGER_READY '
      'seller_username=${seller.username} buyer_username=${buyer.username} '
      'message_marker=$backgroundMessage',
    );

    final tapMessage = await tapDelivery.future.timeout(
      const Duration(seconds: 150),
      onTimeout: () {
        fail('Timeout waiting for FCM notification tap callback');
      },
    );
    expect(tapMessage.data['type'], 'direct_message');
    expect(tapMessage.data['reference_id'], conversationId);
    await tester.pump(const Duration(seconds: 2));
    await pumpUntilFound(tester, find.byKey(const Key('chat-message-field')));
    await pumpUntilFound(tester, find.text(backgroundMessage));
    expectNoRawTechnicalErrorText(tester);
    expect(tester.takeException(), isNull);
    _log('FCM_BACKGROUND_TAP_DELIVERY_PASS');
  });
}

Future<void> _assertDirectMessagePayload(
  Future<RemoteMessage> messageFuture, {
  required String conversationId,
}) async {
  final message = await messageFuture;
  expect(message.data['type'], 'direct_message');
  expect(message.data['reference_id'], conversationId);
}

_RuntimeApp _runtimeApp({
  required AuthProvider auth,
  required NotificationProvider notifications,
  required MessageProvider messages,
  required TradeProvider trades,
  required String initialLocation,
}) {
  late final GoRouter router;
  router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (_, __) => const MessageInboxScreen(),
      ),
      GoRoute(
        path: '/messages/:conversationId',
        builder:
            (_, state) => ChatScreen(
              conversationId: state.pathParameters['conversationId']!,
            ),
      ),
    ],
  );
  final coordinator = RealtimeNotificationCoordinator(
    router: router,
    notificationProvider: notifications,
    messageProvider: messages,
    tradeProvider: trades,
  );

  final widget = MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<BinderProvider>(create: (_) => BinderProvider()),
      ChangeNotifierProvider<CardProvider>(create: (_) => CardProvider()),
      ChangeNotifierProvider<NotificationProvider>.value(value: notifications),
      ChangeNotifierProvider<MessageProvider>.value(value: messages),
      ChangeNotifierProvider<TradeProvider>.value(value: trades),
    ],
    child: MaterialApp.router(
      title: 'ManaLoom Android FCM Runtime',
      theme: AppTheme.darkTheme,
      routerConfig: router,
    ),
  );

  return _RuntimeApp(widget: widget, router: router, coordinator: coordinator);
}

String _suffix(String value) {
  if (value.length <= 8) return value;
  return value.substring(value.length - 8);
}

void _log(String message) {
  debugPrint(message);
  try {
    _markerFile().writeAsStringSync(
      '${DateTime.now().toIso8601String()} $message\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {
    // The stdout/debugPrint logs remain the primary channel if cache writes fail.
  }
  // ignore: avoid_print
  print(message);
}

void _resetMarkerFile() {
  try {
    final file = _markerFile();
    if (file.existsSync()) {
      file.deleteSync();
    }
  } catch (_) {
    // Best effort only; stale markers are also cleared by the unique run marker.
  }
}

File _markerFile() {
  return File('${Directory.systemTemp.path}/fcm_runtime_markers.log');
}
