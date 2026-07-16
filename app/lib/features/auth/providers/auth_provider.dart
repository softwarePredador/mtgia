import 'dart:async' show unawaited;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/observability/app_observability.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../models/user.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  User? _user;
  String? _token;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  int _authGeneration = 0;
  Future<void>? _initializeFuture;

  User? get user => _user;
  String? get token => _token;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

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
      final savedToken = prefs.getString('auth_token');
      final savedUserJson = prefs.getString('user_data');
      debugPrint(
        '[🔑 Auth] savedToken exists: ${savedToken != null}, savedUser exists: ${savedUserJson != null}',
      );

      if (savedToken != null && savedUserJson != null) {
        _token = savedToken;
        ApiClient.setToken(savedToken);
        _user = User.fromJson(jsonDecode(savedUserJson));
        debugPrint('[🔑 Auth] validando token com backend...');
        final isValid = await _validateTokenWithBackend(generation);
        if (generation != _authGeneration) return;
        debugPrint('[🔑 Auth] token válido: $isValid');
        _status =
            isValid ? AuthStatus.authenticated : AuthStatus.unauthenticated;
        if (!isValid) {
          await prefs.remove('auth_token');
          await prefs.remove('user_data');
          _token = null;
          _user = null;
          ApiClient.setToken(null);
        }
      } else {
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
        final nextToken = data['token'] as String?;
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
          return false;
        }
        _token = nextToken;
        _user = nextUser;
        ApiClient.setToken(_token);
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
      });
      debugPrint(
        '[🔑 Auth] resposta recebida: statusCode=${response.statusCode}',
      );

      if (response.statusCode == 201) {
        if (generation != _authGeneration) return false;
        final data = response.data as Map<String, dynamic>;
        final nextToken = data['token'] as String?;
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
          return false;
        }
        _token = nextToken;
        _user = nextUser;
        ApiClient.setToken(_token);
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

  /// Logout
  Future<void> logout() async {
    _authGeneration++;
    final prefs = await SharedPreferences.getInstance();
    await _clearStoredCredentials(prefs);

    _token = null;
    _user = null;
    ApiClient.setToken(null);
    _status = AuthStatus.unauthenticated;
    notifyListeners();
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

    final prefs = await SharedPreferences.getInstance();
    if (generation != _authGeneration) return false;

    await prefs.setString('auth_token', resolvedToken);
    if (generation != _authGeneration) {
      if (prefs.getString('auth_token') == resolvedToken) {
        await prefs.remove('auth_token');
      }
      return false;
    }

    final userJson = jsonEncode(resolvedUser.toJson());
    await prefs.setString('user_data', userJson);
    if (generation != _authGeneration) {
      await _clearStoredCredentialsIfMatch(prefs, resolvedToken, userJson);
      return false;
    }

    return true;
  }

  Future<void> _clearStoredCredentials(SharedPreferences prefs) async {
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<void> _clearStoredCredentialsIfMatch(
    SharedPreferences prefs,
    String token,
    String userJson,
  ) async {
    if (prefs.getString('auth_token') == token) {
      await prefs.remove('auth_token');
    }
    if (prefs.getString('user_data') == userJson) {
      await prefs.remove('user_data');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _validateTokenWithBackend(int generation) async {
    try {
      final response = await _apiClient.get('/auth/me');
      if (generation != _authGeneration) return false;
      if (response.statusCode != 200) return false;
      if (response.data is Map && (response.data as Map).containsKey('user')) {
        final userJson = (response.data as Map)['user'];
        if (userJson is Map<String, dynamic>) {
          final nextUser = User.fromJson(userJson);
          if (!await _saveCredentials(generation, user: nextUser)) {
            return false;
          }
          _user = nextUser;
        }
      }
      return true;
    } catch (_) {
      return false;
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
