import 'dart:async' show unawaited;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/observability/app_observability.dart';
import '../../../core/security/auth_token_store.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../../home/services/onboarding_state_store.dart';
import '../models/user.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

enum _TokenValidationResult { valid, unauthorized, temporarilyUnavailable }

class AuthProvider extends ChangeNotifier {
  static const invalidSavedSessionMessage =
      'A sessão salva neste dispositivo estava inválida e foi removida. '
      'Entre novamente para continuar.';
  static const expiredSessionMessage =
      'Sua sessão expirou. Entre novamente para continuar de onde parou.';

  final ApiClient _apiClient;
  final AuthTokenStore _tokenStore;
  final OnboardingStateRepository _onboardingStateRepository;

  User? _user;
  String? _token;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  bool _needsOnboarding = true;
  bool _onboardingStorageUnavailable = false;
  int _authGeneration = 0;
  Future<void>? _initializeFuture;

  User? get user => _user;
  String? get token => _token;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get needsOnboarding => _needsOnboarding;
  bool get onboardingStorageUnavailable => _onboardingStorageUnavailable;
  String get defaultAuthenticatedLocation => _onboardingStorageUnavailable
      ? '/onboarding/core-flow?storage=unavailable'
      : (_needsOnboarding ? '/onboarding/core-flow' : '/home');

  AuthProvider({
    ApiClient? apiClient,
    AuthTokenStore? tokenStore,
    OnboardingStateRepository? onboardingStateRepository,
  }) : _apiClient = apiClient ?? ApiClient(),
       _tokenStore = tokenStore ?? AuthTokenStore(),
       _onboardingStateRepository =
           onboardingStateRepository ?? OnboardingStateStore();

  /// Inicializa o provider verificando se há token salvo
  Future<void> initialize() async {
    if (_status != AuthStatus.initial) {
      return;
    }

    final existingInitialization = _initializeFuture;
    if (existingInitialization != null) {
      debugPrint('[🔑 Auth] initialize() reutilizando chamada em andamento');
      return existingInitialization;
    }

    final initialization = _initializeFromDisk();
    _initializeFuture = initialization;
    try {
      await initialization;
    } finally {
      if (identical(_initializeFuture, initialization)) {
        _initializeFuture = null;
      }
    }
  }

  Future<void> _initializeFromDisk() async {
    final generation = ++_authGeneration;
    debugPrint('[🔑 Auth] initialize() → loading');
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = await _tokenStore.read();
      final savedUserJson = prefs.getString('user_data');
      debugPrint(
        '[🔑 Auth] savedToken exists: ${savedToken != null}, savedUser exists: ${savedUserJson != null}',
      );

      if (savedToken != null && savedUserJson != null) {
        _token = savedToken;
        ApiClient.setToken(savedToken);
        _user = User.fromJson(jsonDecode(savedUserJson));
        await _loadOnboardingDecision(generation, _user!.id);
        if (generation != _authGeneration) return;
        debugPrint('[🔑 Auth] validando token com backend...');
        final validationResult = await _validateTokenWithBackend(generation);
        if (generation != _authGeneration) return;
        debugPrint('[🔑 Auth] validação do token: $validationResult');
        if (validationResult == _TokenValidationResult.unauthorized) {
          await _clearStoredCredentialsIfMatch(
            prefs,
            savedToken,
            savedUserJson,
          );
          if (generation != _authGeneration) return;
          _token = null;
          _user = null;
          _resetOnboardingDecision();
          ApiClient.setToken(null);
          _status = AuthStatus.unauthenticated;
        } else {
          // A sessão local continua utilizável quando o backend não consegue
          // confirmar o token temporariamente (rate limit, 5xx, timeout ou rede).
          _status = AuthStatus.authenticated;
        }
      } else {
        if (savedToken != null || savedUserJson != null) {
          await _clearStoredCredentials(prefs);
          _errorMessage = invalidSavedSessionMessage;
        }
        _status = AuthStatus.unauthenticated;
      }
    } catch (e, stackTrace) {
      if (generation != _authGeneration) return;
      debugPrint('[❌ Auth] initialize() erro: $e');
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'AuthProvider',
          operation: 'initialize',
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      await _clearStoredCredentials(prefs);
      _token = null;
      _user = null;
      _resetOnboardingDecision();
      ApiClient.setToken(null);
      _errorMessage = invalidSavedSessionMessage;
      _status = AuthStatus.unauthenticated;
    }

    if (generation != _authGeneration) return;
    debugPrint('[🔑 Auth] initialize() concluído → $_status');
    notifyListeners();
  }

  /// Login
  Future<bool> login(String email, String password) async {
    final generation = ++_authGeneration;
    debugPrint(
      '[🔑 Auth] login() chamado email_domain=${_safeEmailDomain(email)}',
    );
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[🔑 Auth] enviando POST /auth/login...');
      final response = await _apiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });
      debugPrint(
        '[🔑 Auth] resposta recebida: statusCode=${response.statusCode}',
      );

      if (response.statusCode == 200) {
        if (generation != _authGeneration) return false;
        final data = response.data as Map<String, dynamic>;
        final nextToken = _readAuthToken(data['token']);
        final nextUser = User.fromJson(data['user'] as Map<String, dynamic>);
        debugPrint(
          '[🔑 Auth] token recebido: ${nextToken != null ? "sim" : "NÃO"}',
        );
        debugPrint('[🔑 Auth] user parsed: ${nextUser.username}');

        // Salvar credenciais
        if (!await _saveCredentials(
          generation,
          token: nextToken,
          user: nextUser,
        )) {
          _markCredentialContractFailure(generation);
          return false;
        }
        _token = nextToken;
        _user = nextUser;
        ApiClient.setToken(_token);
        await _loadOnboardingDecision(generation, nextUser.id);
        if (generation != _authGeneration) return false;
        debugPrint('[🔑 Auth] credenciais salvas');

        _status = AuthStatus.authenticated;
        debugPrint('[🔑 Auth] status → authenticated ✅');
        notifyListeners();
        return true;
      } else {
        if (generation != _authGeneration) return false;
        _errorMessage = FriendlyErrorMapper.fromApiResponse(
          response,
          context: FriendlyErrorContext.authLogin,
        );
        debugPrint('[🔑 Auth] login falhou: $_errorMessage');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      if (generation != _authGeneration) return false;
      _errorMessage = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.authLogin,
      );
      debugPrint('[❌ Auth] login() EXCEPTION: $e');
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'AuthProvider',
          operation: 'login',
          extras: {'email_domain': _safeEmailDomain(email)},
        ),
      );
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Registro
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required bool legalAccepted,
    required String termsVersion,
    required String privacyVersion,
  }) async {
    final generation = ++_authGeneration;
    debugPrint(
      '[🔑 Auth] register() chamado email_domain=${_safeEmailDomain(email)}',
    );
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[🔑 Auth] enviando POST /auth/register...');
      final response = await _apiClient.post('/auth/register', {
        'username': username,
        'email': email,
        'password': password,
        'legal_accepted': legalAccepted,
        'terms_version': termsVersion,
        'privacy_version': privacyVersion,
      });
      debugPrint(
        '[🔑 Auth] resposta recebida: statusCode=${response.statusCode}',
      );

      if (response.statusCode == 201) {
        if (generation != _authGeneration) return false;
        final data = response.data as Map<String, dynamic>;
        final nextToken = _readAuthToken(data['token']);
        final nextUser = User.fromJson(data['user'] as Map<String, dynamic>);
        debugPrint(
          '[🔑 Auth] token recebido: ${nextToken != null ? "sim" : "NÃO"}',
        );
        debugPrint('[🔑 Auth] user parsed: ${nextUser.username}');
        if (!await _saveCredentials(
          generation,
          token: nextToken,
          user: nextUser,
        )) {
          _markCredentialContractFailure(generation);
          return false;
        }
        _token = nextToken;
        _user = nextUser;
        ApiClient.setToken(_token);
        await _loadOnboardingDecision(generation, nextUser.id);
        if (generation != _authGeneration) return false;
        debugPrint('[🔑 Auth] credenciais salvas');

        _status = AuthStatus.authenticated;
        debugPrint('[🔑 Auth] status → authenticated ✅');
        notifyListeners();
        return true;
      } else {
        if (generation != _authGeneration) return false;
        _errorMessage = FriendlyErrorMapper.fromApiResponse(
          response,
          context: FriendlyErrorContext.authRegister,
        );
        debugPrint('[🔑 Auth] register falhou: $_errorMessage');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      if (generation != _authGeneration) return false;
      _errorMessage = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.authRegister,
      );
      debugPrint('[❌ Auth] register() EXCEPTION: $e');
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'AuthProvider',
          operation: 'register',
          extras: {'email_domain': _safeEmailDomain(email)},
        ),
      );
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _rotateAuthenticatedSession(
    endpoint: '/auth/change-password',
    body: {'current_password': currentPassword, 'new_password': newPassword},
    operation: 'changePassword',
  );

  Future<bool> revokeOtherSessions({required String currentPassword}) =>
      _rotateAuthenticatedSession(
        endpoint: '/auth/revoke-sessions',
        body: {'current_password': currentPassword},
        operation: 'revokeOtherSessions',
      );

  Future<bool> _rotateAuthenticatedSession({
    required String endpoint,
    required Map<String, dynamic> body,
    required String operation,
  }) async {
    final generation = _authGeneration;
    final currentUser = _user;
    if (currentUser == null || _status != AuthStatus.authenticated) {
      _errorMessage = 'Entre novamente para alterar a segurança da conta.';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiClient.post(endpoint, body);
      if (generation != _authGeneration) return false;
      if (response.statusCode != 200 || response.data is! Map) {
        final data = response.data;
        _errorMessage = data is Map && data['message'] is String
            ? data['message'] as String
            : 'Não foi possível atualizar a segurança da conta.';
        notifyListeners();
        return false;
      }
      final data = response.data as Map;
      final nextToken = _readAuthToken(data['token']);
      final rawUser = data['user'];
      final nextUser = rawUser is Map<String, dynamic>
          ? User.fromJson(rawUser)
          : currentUser;
      if (!await _saveCredentials(
        generation,
        token: nextToken,
        user: nextUser,
      )) {
        _errorMessage = 'Resposta inválida do servidor';
        notifyListeners();
        return false;
      }
      _token = nextToken;
      _user = nextUser;
      ApiClient.setToken(nextToken);
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      if (generation != _authGeneration) return false;
      _errorMessage = 'Não foi possível atualizar a segurança da conta.';
      unawaited(
        AppObservability.instance.captureProviderException(
          error,
          stackTrace: stackTrace,
          provider: 'AuthProvider',
          operation: operation,
        ),
      );
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _authGeneration++;
    final prefs = await SharedPreferences.getInstance();
    try {
      await _clearStoredCredentials(prefs);
    } finally {
      _token = null;
      _user = null;
      _resetOnboardingDecision();
      ApiClient.setToken(null);
      _errorMessage = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Ends an already-authenticated session after the backend explicitly
  /// reports that its token is missing, invalid or expired.
  ///
  /// The visible state changes synchronously so GoRouter can capture the
  /// current protected URI in the login redirect. Credential cleanup is
  /// guarded by the expired values, preventing a late delete from removing a
  /// newer login.
  void expireSession() {
    if (_status != AuthStatus.authenticated || _token == null) return;

    final expiredToken = _token!;
    final expiredUserJson = _user == null ? null : jsonEncode(_user!.toJson());
    _authGeneration++;
    _token = null;
    _user = null;
    _resetOnboardingDecision();
    ApiClient.setToken(null);
    _errorMessage = expiredSessionMessage;
    _status = AuthStatus.unauthenticated;
    notifyListeners();

    unawaited(_clearExpiredCredentials(expiredToken, expiredUserJson));
  }

  Future<void> _clearExpiredCredentials(
    String expiredToken,
    String? expiredUserJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _tokenStore.deleteIfMatches(expiredToken);
      if (expiredUserJson != null &&
          prefs.getString('user_data') == expiredUserJson) {
        await prefs.remove('user_data');
      }
    } catch (error, stackTrace) {
      unawaited(
        AppObservability.instance.captureProviderException(
          error,
          stackTrace: stackTrace,
          provider: 'AuthProvider',
          operation: 'expireSessionCleanup',
        ),
      );
    }
  }

  /// Salva credenciais localmente
  Future<bool> _saveCredentials(
    int generation, {
    String? token,
    User? user,
  }) async {
    final resolvedToken = token ?? _token;
    final resolvedUser = user ?? _user;
    if (resolvedToken == null ||
        resolvedUser == null ||
        generation != _authGeneration) {
      return false;
    }

    final userJson = jsonEncode(resolvedUser.toJson());
    await _tokenStore.write(resolvedToken);
    if (generation != _authGeneration) {
      await _tokenStore.deleteIfMatches(resolvedToken);
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', userJson);
      if (generation != _authGeneration) {
        await _clearStoredCredentialsIfMatch(prefs, resolvedToken, userJson);
        return false;
      }
    } catch (_) {
      await _tokenStore.deleteIfMatches(resolvedToken);
      rethrow;
    }

    return true;
  }

  Future<void> _clearStoredCredentials(SharedPreferences prefs) async {
    try {
      await _tokenStore.delete();
    } catch (error, stackTrace) {
      debugPrint('[AuthProvider] falha ao limpar o cofre seguro: $error');
      unawaited(
        AppObservability.instance.captureProviderException(
          error,
          stackTrace: stackTrace,
          provider: 'AuthProvider',
          operation: 'clearSecureCredentials',
        ),
      );
    }
    await prefs.remove('user_data');
  }

  Future<void> _clearStoredCredentialsIfMatch(
    SharedPreferences prefs,
    String token,
    String userJson,
  ) async {
    await _tokenStore.deleteIfMatches(token);
    if (prefs.getString('user_data') == userJson) {
      await prefs.remove('user_data');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void markOnboardingSettled() {
    if (!_needsOnboarding && !_onboardingStorageUnavailable) return;
    _needsOnboarding = false;
    _onboardingStorageUnavailable = false;
    notifyListeners();
  }

  Future<void> _loadOnboardingDecision(int generation, String userId) async {
    try {
      final state = await _onboardingStateRepository.load(userId);
      if (generation != _authGeneration) return;
      _needsOnboarding = !state.isSettled;
      _onboardingStorageUnavailable = false;
    } catch (error, stackTrace) {
      if (generation != _authGeneration) return;
      _needsOnboarding = true;
      _onboardingStorageUnavailable = true;
      unawaited(
        AppObservability.instance.captureProviderException(
          error,
          stackTrace: stackTrace,
          provider: 'AuthProvider',
          operation: 'loadOnboardingDecision',
        ),
      );
    }
  }

  void _resetOnboardingDecision() {
    _needsOnboarding = true;
    _onboardingStorageUnavailable = false;
  }

  String? _readAuthToken(dynamic value) {
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void _markCredentialContractFailure(int generation) {
    if (generation != _authGeneration) return;
    _errorMessage = 'Resposta inválida do servidor';
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<_TokenValidationResult> _validateTokenWithBackend(
    int generation,
  ) async {
    try {
      final response = await _apiClient.get('/auth/me');
      if (generation != _authGeneration) {
        return _TokenValidationResult.temporarilyUnavailable;
      }
      if (response.statusCode == 401) {
        return _TokenValidationResult.unauthorized;
      }
      if (response.statusCode != 200) {
        return _TokenValidationResult.temporarilyUnavailable;
      }
      if (response.data is Map && (response.data as Map).containsKey('user')) {
        final userJson = (response.data as Map)['user'];
        if (userJson is Map<String, dynamic>) {
          final nextUser = User.fromJson(userJson);
          if (!await _saveCredentials(generation, user: nextUser)) {
            return _TokenValidationResult.temporarilyUnavailable;
          }
          _user = nextUser;
        }
      }
      return _TokenValidationResult.valid;
    } catch (_) {
      return _TokenValidationResult.temporarilyUnavailable;
    }
  }

  Future<bool> refreshProfile() async {
    final generation = _authGeneration;
    try {
      final response = await _apiClient.get('/users/me');
      if (generation != _authGeneration) return false;
      if (response.statusCode != 200) {
        _recordProfileProviderEvent(
          'profile_refresh_http_error',
          operation: 'refreshProfile',
          statusCode: response.statusCode,
          requestId: response.requestId,
        );
        return false;
      }
      final data = response.data;
      if (data is Map && data['user'] is Map<String, dynamic>) {
        final nextUser = User.fromJson((data['user'] as Map<String, dynamic>));
        if (!await _saveCredentials(generation, user: nextUser)) return false;
        _user = nextUser;
        notifyListeners();
        return true;
      }
      _recordProfileProviderEvent(
        'profile_refresh_contract_error',
        operation: 'refreshProfile',
        statusCode: response.statusCode,
        requestId: response.requestId,
      );
      return false;
    } catch (e, stackTrace) {
      if (generation != _authGeneration) return false;
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'AuthProvider',
          operation: 'refreshProfile',
        ),
      );
      return false;
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? locationState,
    String? locationCity,
    String? tradeNotes,
  }) async {
    final generation = _authGeneration;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.patch('/users/me', {
        if (displayName != null) 'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (locationState != null) 'location_state': locationState,
        if (locationCity != null) 'location_city': locationCity,
        if (tradeNotes != null) 'trade_notes': tradeNotes,
      });
      if (generation != _authGeneration) return false;
      if (response.statusCode != 200) {
        _recordProfileProviderEvent(
          'profile_update_http_error',
          operation: 'updateProfile',
          statusCode: response.statusCode,
          requestId: response.requestId,
        );
        _errorMessage = FriendlyErrorMapper.fromApiResponse(
          response,
          context: FriendlyErrorContext.authProfile,
        );
        notifyListeners();
        return false;
      }
      final data = response.data;
      if (data is Map && data['user'] is Map<String, dynamic>) {
        final nextUser = User.fromJson((data['user'] as Map<String, dynamic>));
        if (!await _saveCredentials(generation, user: nextUser)) return false;
        _user = nextUser;
        notifyListeners();
      } else {
        _recordProfileProviderEvent(
          'profile_update_contract_error',
          operation: 'updateProfile',
          statusCode: response.statusCode,
          requestId: response.requestId,
        );
        _errorMessage = 'Resposta inválida do servidor';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e, stackTrace) {
      if (generation != _authGeneration) return false;
      _errorMessage = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.authProfile,
      );
      unawaited(
        AppObservability.instance.captureProviderException(
          e,
          stackTrace: stackTrace,
          provider: 'AuthProvider',
          operation: 'updateProfile',
        ),
      );
      notifyListeners();
      return false;
    }
  }

  String _safeEmailDomain(String email) {
    final parts = email.trim().split('@');
    if (parts.length != 2 || parts.last.trim().isEmpty) {
      return 'unknown';
    }
    return parts.last.trim().toLowerCase();
  }

  void _recordProfileProviderEvent(
    String message, {
    required String operation,
    int? statusCode,
    String? requestId,
  }) {
    debugPrint(
      '[AuthProvider] $message operation=$operation '
      'status=${statusCode ?? 'n/a'} request_id=${requestId ?? 'n/a'}',
    );
    unawaited(
      AppObservability.instance.recordEvent(
        message,
        category: 'profile',
        data: {
          'provider': 'AuthProvider',
          'operation': operation,
          if (statusCode != null) 'status_code': statusCode,
          if (requestId != null) 'request_id': requestId,
        },
      ),
    );
  }
}
