import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/security/auth_token_store.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/home/services/onboarding_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryTokenBackend implements SecureTokenBackend {
  String? value;

  @override
  Future<void> delete(String key) async => value = null;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _LoginApi extends ApiClient {
  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    expect(endpoint, '/auth/login');
    return ApiResponse(200, {
      'token': 'onboarding-token',
      'user': {
        'id': 'user-onboarding',
        'username': 'first_login',
        'email': 'first_login@example.com',
      },
    });
  }
}

class _OnboardingRepository implements OnboardingStateRepository {
  _OnboardingRepository({this.state = const OnboardingState(), this.error});

  final OnboardingState state;
  final Object? error;
  int loadCalls = 0;

  @override
  Future<OnboardingState> load(String userId) async {
    loadCalls += 1;
    expect(userId, 'user-onboarding');
    if (error != null) throw error!;
    return state;
  }

  @override
  Future<void> saveProgress(
    String userId, {
    required String selectedFormat,
  }) async {}

  @override
  Future<void> settle(
    String userId, {
    required String selectedFormat,
    required OnboardingDisposition disposition,
  }) async {}
}

AuthProvider _buildProvider(_OnboardingRepository repository) {
  return AuthProvider(
    apiClient: _LoginApi(),
    tokenStore: AuthTokenStore(secureBackend: _MemoryTokenBackend()),
    onboardingStateRepository: repository,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ApiClient.resetForTesting();
  });
  tearDown(ApiClient.resetForTesting);

  test(
    'first login resolves to onboarding from persisted product state',
    () async {
      final repository = _OnboardingRepository();
      final provider = _buildProvider(repository);

      expect(
        await provider.login('first_login@example.com', 'password'),
        isTrue,
      );

      expect(repository.loadCalls, 1);
      expect(provider.needsOnboarding, isTrue);
      expect(provider.onboardingStorageUnavailable, isFalse);
      expect(provider.defaultAuthenticatedLocation, '/onboarding/core-flow');
    },
  );

  test(
    'completed onboarding resolves to home after logout and login',
    () async {
      final repository = _OnboardingRepository(
        state: const OnboardingState(
          disposition: OnboardingDisposition.completed,
        ),
      );
      final provider = _buildProvider(repository);

      expect(
        await provider.login('first_login@example.com', 'password'),
        isTrue,
      );
      expect(provider.defaultAuthenticatedLocation, '/home');
      await provider.logout();
      expect(provider.needsOnboarding, isTrue);
      expect(
        await provider.login('first_login@example.com', 'password'),
        isTrue,
      );

      expect(repository.loadCalls, 2);
      expect(provider.defaultAuthenticatedLocation, '/home');
    },
  );

  test(
    'storage failure stays pending and routes to recoverable warning',
    () async {
      final repository = _OnboardingRepository(
        error: const OnboardingPersistenceException('storage offline'),
      );
      final provider = _buildProvider(repository);

      expect(
        await provider.login('first_login@example.com', 'password'),
        isTrue,
      );

      expect(provider.needsOnboarding, isTrue);
      expect(provider.onboardingStorageUnavailable, isTrue);
      expect(
        provider.defaultAuthenticatedLocation,
        '/onboarding/core-flow?storage=unavailable',
      );
    },
  );

  test('settled callback updates the in-memory router decision', () async {
    final provider = _buildProvider(_OnboardingRepository());
    expect(await provider.login('first_login@example.com', 'password'), isTrue);

    provider.markOnboardingSettled();

    expect(provider.needsOnboarding, isFalse);
    expect(provider.defaultAuthenticatedLocation, '/home');
  });
}
