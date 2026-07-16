import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import '../routes/index.dart' as root_route;

void main() {
  test('root endpoint exposes the ManaLoom API identity', () async {
    final response = root_route.onRequest(_context(HttpMethod.get));
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.ok);
    expect(body, containsPair('service', 'manaloom-api'));
    expect(body, containsPair('status', 'ok'));
    expect(body, containsPair('health', '/health'));
    expect(body, containsPair('readiness', '/ready'));
    expect(body.toString(), isNot(contains('MTG Deck Builder')));
  });

  test('root endpoint rejects mutating methods', () async {
    final response = root_route.onRequest(_context(HttpMethod.post));
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.methodNotAllowed);
    expect(body, containsPair('error', 'Method not allowed'));
  });
}

RequestContext _context(HttpMethod method) => _RootRequestContext(
  Request(method.name.toUpperCase(), Uri.parse('http://localhost/')),
);

class _RootRequestContext implements RequestContext {
  _RootRequestContext(this.request);

  @override
  final Request request;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() => throw StateError('Root endpoint has no providers.');
}
