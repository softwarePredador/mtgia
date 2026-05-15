import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthSuccessApiClient extends ApiClient {
  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    expect(endpoint, '/auth/login');
    return ApiResponse(200, {
      'token': 'super-secret-token-value',
      'user': {
        'id': 'user-1',
        'username': 'qa_user',
        'email': 'qa_user@example.com',
      },
    });
  }
}

class _AuthTimeoutApiClient extends ApiClient {
  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    throw TimeoutException('SocketException RequestOptions stackTrace');
  }
}

class _DelayedProfileApiClient extends ApiClient {
  final profileCompleter = Completer<ApiResponse>();

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    expect(endpoint, '/auth/login');
    return ApiResponse(200, {
      'token': 'session-token',
      'user': {
        'id': 'user-1',
        'username': 'qa_user',
        'email': 'qa_user@example.com',
      },
    });
  }

  @override
  Future<ApiResponse> get(String endpoint) {
    expect(endpoint, '/users/me');
    return profileCompleter.future;
  }
}

void main() {
  test('login debug logs do not expose email, password or token', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AuthProvider(apiClient: _AuthSuccessApiClient());
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        logs.add(message);
      }
    };

    try {
      final ok = await provider.login('qa_user@example.com', 'Password123!');

      expect(ok, isTrue);
    } finally {
      debugPrint = previousDebugPrint;
    }

    final joined = logs.join('\n');
    expect(joined, isNot(contains('qa_user@example.com')));
    expect(joined, isNot(contains('Password123!')));
    expect(joined, isNot(contains('super-secret-token-value')));
    expect(joined, contains('email_domain=example.com'));
    expect(joined, contains('token recebido: sim'));
  });

  test('login network failure exposes friendly user message only', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AuthProvider(apiClient: _AuthTimeoutApiClient());

    final ok = await provider.login('qa_user@example.com', 'Password123!');

    expect(ok, isFalse);
    expect(
      provider.errorMessage,
      'A conexão demorou mais que o esperado. Tente novamente em instantes.',
    );
    expect(provider.errorMessage, isNot(contains('SocketException')));
    expect(provider.errorMessage, isNot(contains('RequestOptions')));
  });

  test('late profile refresh cannot repopulate user after logout', () async {
    SharedPreferences.setMockInitialValues({});
    final api = _DelayedProfileApiClient();
    final provider = AuthProvider(apiClient: api);

    final loggedIn = await provider.login(
      'qa_user@example.com',
      'Password123!',
    );
    expect(loggedIn, isTrue);

    final refresh = provider.refreshProfile();
    await Future<void>.delayed(Duration.zero);
    await provider.logout();

    api.profileCompleter.complete(
      ApiResponse(200, {
        'user': {
          'id': 'user-stale',
          'username': 'stale_user',
          'email': 'stale@example.com',
        },
      }),
    );
    final refreshed = await refresh;

    expect(refreshed, isFalse);
    expect(provider.user, isNull);
    expect(provider.status, AuthStatus.unauthenticated);
  });
}
