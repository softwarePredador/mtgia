import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import '../routes/auth/register.dart' as register_route;

void main() {
  test('register returns a stable error code for a short password', () async {
    final response = await register_route.onRequest(
      _context(password: 'Ab3!short'),
    );
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.badRequest);
    expect(body['error'], 'password_too_short');
    expect(body['message'], 'Senha deve ter no mínimo 12 caracteres.');
  });

  test(
    'register rejects common and account-derived passwords before DB',
    () async {
      for (final password in const [r'P@ssw0rd!2026', 'player-one!2026-safe']) {
        final response = await register_route.onRequest(
          _context(password: password),
        );
        final body = jsonDecode(await response.body()) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.badRequest);
        expect(body['error'], 'weak_password');
        expect(body['message'], contains('menos previsível'));
      }
    },
  );
}

RequestContext _context({required String password}) => _RegisterRequestContext(
  Request.post(
    Uri.parse('http://localhost/auth/register'),
    headers: const {'content-type': 'application/json'},
    body: jsonEncode({
      'username': 'player-one',
      'email': 'player.one@example.com',
      'password': password,
    }),
  ),
);

class _RegisterRequestContext implements RequestContext {
  const _RegisterRequestContext(this.request);

  @override
  final Request request;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() =>
      throw StateError(
        'Password validation must run before database/provider access.',
      );
}
