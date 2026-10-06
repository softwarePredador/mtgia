import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/security/auth_token_store.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/home/life_counter/life_counter_account_scope.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

// LC-P0-02: login, logout, forced logout (token expiry), account deletion and
// restart close and reopen the right life counter namespace.

class _MemoryTokenBackend implements SecureTokenBackend {
  String? value;

  @override
  Future<void> delete(String key) async => value = null;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _AccountsApi extends ApiClient {
  String nextUserId = 'user-a';

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    expect(endpoint, '/auth/login');
    return ApiResponse(200, {
      'token': 'token-$nextUserId',
      'user': {
        'id': nextUserId,
        'username': nextUserId.replaceAll('-', '_'),
        'email': '$nextUserId@example.com',
      },
    });
  }

  @override
  Future<ApiResponse> get(String endpoint) async {
    expect(endpoint, '/auth/me');
    return ApiResponse(200, const <String, dynamic>{});
  }
}

LifeCounterSession _session(String deckId) => LifeCounterSession.initial(
  playerCount: 2,
  playSessionId: 'play-$deckId',
  deckId: deckId,
  startedAtEpochMs: 1784714400000,
);

void main() {
  late _AccountsApi api;
  late _MemoryTokenBackend tokens;

  AuthProvider buildProvider() => AuthProvider(
    apiClient: api,
    tokenStore: AuthTokenStore(secureBackend: tokens),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ApiClient.resetForTesting();
    LifeCounterAccountScope.resetForTesting();
    api = _AccountsApi();
    tokens = _MemoryTokenBackend();
  });
  tearDown(ApiClient.resetForTesting);

  test('logout closes A, B gets a clean table, A gets hers back', () async {
    final auth = buildProvider();
    expect(await auth.login('user-a@example.com', 'password'), isTrue);
    expect(LifeCounterAccountScope.instance.accountId, 'user-a');
    final storeOfA = LifeCounterSessionStore();
    await storeOfA.save(_session('deck-a'));

    await auth.logout();
    expect(LifeCounterAccountScope.instance.accountId, isNull);
    await expectLater(
      storeOfA.load(),
      throwsA(isA<LifeCounterStorageScopeClosedException>()),
    );

    api.nextUserId = 'user-b';
    expect(await auth.login('user-b@example.com', 'password'), isTrue);
    expect(LifeCounterAccountScope.instance.accountId, 'user-b');
    expect(await LifeCounterSessionStore().load(), isNull);

    await auth.logout();
    api.nextUserId = 'user-a';
    expect(await auth.login('user-a@example.com', 'password'), isTrue);
    expect((await LifeCounterSessionStore().load())?.deckId, 'deck-a');
  });

  test('token expiry closes the namespace but keeps the table', () async {
    final auth = buildProvider();
    expect(await auth.login('user-a@example.com', 'password'), isTrue);
    final storeOfA = LifeCounterSessionStore();
    await storeOfA.save(_session('deck-a'));

    auth.expireSession();

    expect(LifeCounterAccountScope.instance.accountId, isNull);
    await expectLater(
      storeOfA.save(_session('deck-late-write')),
      throwsA(isA<LifeCounterStorageScopeClosedException>()),
    );
    expect(await auth.login('user-a@example.com', 'password'), isTrue);
    expect((await LifeCounterSessionStore().load())?.deckId, 'deck-a');
  });

  test('account deletion removes the account data from the device', () async {
    final auth = buildProvider();
    expect(await auth.login('user-a@example.com', 'password'), isTrue);
    await LifeCounterSessionStore().save(_session('deck-a'));

    await auth.logout(purgeLocalAccountData: true);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where(
        (key) => key.startsWith(lifeCounterAccountKeyPrefix('user-a')),
      ),
      isEmpty,
    );
    expect(await auth.login('user-a@example.com', 'password'), isTrue);
    expect(await LifeCounterSessionStore().load(), isNull);
  });

  test('restart reopens the saved account namespace', () async {
    final first = buildProvider();
    expect(await first.login('user-a@example.com', 'password'), isTrue);
    await LifeCounterSessionStore().save(_session('deck-a'));

    // A fresh process: a new scope and a new provider over the same storage.
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('user_data')!)['id'], 'user-a');
    LifeCounterAccountScope.resetForTesting();
    ApiClient.resetForTesting();
    final restarted = buildProvider();
    await restarted.initialize();

    expect(restarted.status, AuthStatus.authenticated);
    expect(LifeCounterAccountScope.instance.accountId, 'user-a');
    expect((await LifeCounterSessionStore().load())?.deckId, 'deck-a');
  });
}
