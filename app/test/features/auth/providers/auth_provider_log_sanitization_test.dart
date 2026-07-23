import 'dart:async';
import 'dart:convert';

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

class _MissingTokenApiClient extends ApiClient {
  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    return ApiResponse(200, {
      'user': {
        'id': 'user-without-token',
        'username': 'invalid_contract',
        'email': 'invalid@example.com',
      },
    });
  }
}

class _RegisterSuccessApiClient extends ApiClient {
  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    expect(endpoint, '/auth/register');
    return ApiResponse(201, {
      'token': 'register-secret-token-value',
      'user': {
        'id': 'user-2',
        'username': 'qa_register_user',
        'email': 'qa_register_user@example.com',
      },
    });
  }
}

class _TokenValidationApiClient extends ApiClient {
  int getCalls = 0;

  @override
  Future<ApiResponse> get(String endpoint) async {
    getCalls++;
    expect(endpoint, '/auth/me');
    return ApiResponse(200, {
      'user': {
        'id': 'user-saved',
        'username': 'saved_user',
        'email': 'saved_user@example.com',
      },
    });
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
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('user_data'), isNotNull);
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

  test('register debug logs do not expose email, password or token', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AuthProvider(apiClient: _RegisterSuccessApiClient());
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        logs.add(message);
      }
    };

    try {
      final ok = await provider.register(
        username: 'qa_register_user',
        email: 'qa_register_user@example.com',
        password: 'Password123!',
        legalAccepted: true,
        termsVersion: '2026-07-21',
        privacyVersion: '2026-07-21',
      );

      expect(ok, isTrue);
    } finally {
      debugPrint = previousDebugPrint;
    }

    final joined = logs.join('\n');
    expect(joined, isNot(contains('qa_register_user@example.com')));
    expect(joined, isNot(contains('Password123!')));
    expect(joined, isNot(contains('register-secret-token-value')));
    expect(joined, contains('email_domain=example.com'));
    expect(joined, contains('POST /auth/register'));
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

  test('invalid login contract never leaves auth stuck in loading', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AuthProvider(apiClient: _MissingTokenApiClient());

    final ok = await provider.login('qa_user@example.com', 'Password123!');

    expect(ok, isFalse);
    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.errorMessage, 'Resposta inválida do servidor');
    expect(provider.token, isNull);
  });

  test('initialize reuses in-flight token validation', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'saved-token',
      'user_data': jsonEncode({
        'id': 'user-saved',
        'username': 'saved_user',
        'email': 'saved_user@example.com',
      }),
    });
    final api = _TokenValidationApiClient();
    final provider = AuthProvider(apiClient: api);

    final firstInitialization = provider.initialize();
    final secondInitialization = provider.initialize();

    await Future.wait([firstInitialization, secondInitialization]);

    expect(api.getCalls, 1);
    expect(provider.status, AuthStatus.authenticated);
    expect(provider.user?.id, 'user-saved');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull);

    await provider.initialize();

    expect(api.getCalls, 1);
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
