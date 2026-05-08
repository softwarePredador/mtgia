import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'visual_capture_helpers.dart';

class RuntimeAuthSession {
  final String token;
  final Map<String, dynamic> user;
  final String email;
  final String username;
  final String password;

  const RuntimeAuthSession({
    required this.token,
    required this.user,
    required this.email,
    required this.username,
    required this.password,
  });

  String get userId => user['id']?.toString() ?? '';
}

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
  int attempts = 60,
  Duration step = const Duration(milliseconds: 500),
}) async {
  for (var i = 0; i < attempts; i += 1) {
    await tester.pump(step);
    if (condition()) return;
  }
  fail('Timeout waiting for $description');
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 60,
  Duration step = const Duration(milliseconds: 500),
}) {
  return pumpUntil(
    tester,
    () => finder.evaluate().isNotEmpty,
    description: finder.toString(),
    attempts: attempts,
    step: step,
  );
}

Future<void> pumpUntilAbsent(
  WidgetTester tester,
  Finder finder, {
  int attempts = 60,
  Duration step = const Duration(milliseconds: 500),
}) {
  return pumpUntil(
    tester,
    () => finder.evaluate().isEmpty,
    description: '${finder.toString()} to disappear',
    attempts: attempts,
    step: step,
  );
}

Future<void> clearRuntimeAuth() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  ApiClient.setToken(null);
}

Future<RuntimeAuthSession> seedAuthenticatedSession(
  ApiClient api, {
  String usernamePrefix = 'runtime_qa',
  String password = 'Qa123456!',
}) async {
  final unique = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
  final username = '${usernamePrefix}_$unique';
  final email = '$username@example.com';

  final response = await api.post('/auth/register', {
    'username': username,
    'email': email,
    'password': password,
  });
  expect(response.statusCode, anyOf(200, 201));

  final data = response.data as Map<String, dynamic>;
  final token = data['token']?.toString();
  final user = (data['user'] as Map?)?.cast<String, dynamic>();
  expect(token, isNotNull);
  expect(user, isNotNull);

  ApiClient.setToken(token);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token!);
  await prefs.setString('user_data', jsonEncode(user));

  return RuntimeAuthSession(
    token: token,
    user: user!,
    email: email,
    username: username,
    password: password,
  );
}

Future<void> captureRuntimeCheckpoint(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) {
  return captureVisualProof(binding, tester, name);
}

void expectNoRawTechnicalErrorText(WidgetTester tester) {
  final rawErrorPatterns = [
    'DioException',
    'SocketException',
    'RequestOptions',
    'Exception:',
    'StackTrace',
    'status code',
    'developer.mozilla',
  ];

  for (final pattern in rawErrorPatterns) {
    expect(find.textContaining(pattern), findsNothing);
  }
}
