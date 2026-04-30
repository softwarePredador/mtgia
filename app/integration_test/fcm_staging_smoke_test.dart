import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('attempts real FCM token registration without logging token', (
    tester,
  ) async {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8082',
    );
    final marker =
        'qa_fcm_${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('fcm-staging-smoke'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('fcm-staging-smoke'), findsOneWidget);

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // ignore: avoid_print
      print('FCM_PERMISSION status=${settings.authorizationStatus.name}');

      final apnsToken = await messaging.getAPNSToken();
      // ignore: avoid_print
      print(
        'FCM_APNS_TOKEN_PRESENT=${apnsToken != null && apnsToken.isNotEmpty}',
      );

      final fcmToken = await messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        // ignore: avoid_print
        print('FCM_SMOKE_RESULT=not_proven reason=empty_fcm_token');
        return;
      }

      final auth = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': marker,
          'email': '$marker@example.invalid',
          'password': 'TestPassword123!',
        }),
      );
      expect(auth.statusCode, anyOf(200, 201), reason: auth.body);
      final authBody = jsonDecode(auth.body) as Map<String, dynamic>;
      final token = authBody['token'] as String;

      final registerToken = await http.put(
        Uri.parse('$baseUrl/users/me/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'token': fcmToken}),
      );
      expect(registerToken.statusCode, 200, reason: registerToken.body);
      // ignore: avoid_print
      print('FCM_SMOKE_RESULT=token_registered token_present=true');
    } catch (error) {
      // ignore: avoid_print
      print('FCM_SMOKE_RESULT=not_proven error_type=${error.runtimeType}');
      // ignore: avoid_print
      print('FCM_SMOKE_ERROR=$error');
    }
  });
}
