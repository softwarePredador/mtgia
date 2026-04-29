import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../observability/app_observability.dart';

/// Response wrapper para padronizar respostas da API
class ApiResponse {
  final int statusCode;
  final dynamic data;
  final int durationMs; // Tempo da requisição em ms
  final String? requestId;
  final String? responseRequestId;

  ApiResponse(
    this.statusCode,
    this.data, {
    this.durationMs = 0,
    this.requestId,
    this.responseRequestId,
  });
}

class ApiClient {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String _debugAndroidEmulatorUrl = 'http://10.0.2.2:8080';
  static const String _debugLocalhostUrl = 'http://127.0.0.1:8080';
  static const String _releaseFallbackUrl = '';

  // ──────────────────────────────────────────
  // Cache do token em memória (evita SharedPreferences a cada request)
  // ──────────────────────────────────────────
  static String? _cachedToken;

  /// Atualiza o token em memória (chamar no login/register/logout).
  static void setToken(String? token) {
    _cachedToken = token;
  }

  /// Instância singleton do http.Client para reutilizar conexões TCP.
  static final http.Client _httpClient = http.Client();
  static bool _performanceUnavailable = false;
  static final Random _requestIdRandom = Random.secure();

  // Retorna a URL correta dependendo do ambiente
  static String get baseUrl {
    if (_envBaseUrl.trim().isNotEmpty) {
      return _envBaseUrl.trim().replaceAll(RegExp(r'/$'), '');
    }

    if (kDebugMode) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return _debugAndroidEmulatorUrl;
      }
      return _debugLocalhostUrl;
    }

    return _releaseFallbackUrl;
  }

  /// Log da URL base resolvida (chamado uma vez no boot)
  static void debugLogBaseUrl() {
    debugPrint('[🌐 ApiClient] baseUrl = $baseUrl');
    debugPrint('[🌐 ApiClient] platform = $defaultTargetPlatform | kIsWeb=$kIsWeb | kDebugMode=$kDebugMode');
    if (_envBaseUrl.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[🌐 ApiClient] fallback de debug ativo; em device físico ou backend remoto use --dart-define=API_BASE_URL=https://seu-host',
        );
      } else if (baseUrl.isEmpty) {
        debugPrint(
          '[⚠️ ApiClient] API_BASE_URL ausente em release/profile; configure --dart-define=API_BASE_URL=https://seu-host',
        );
      }
    }
  }

  static String generateRequestId({DateTime? now, Random? random}) {
    final resolvedNow = now ?? DateTime.now();
    final resolvedRandom = random ?? _requestIdRandom;
    final timestamp = resolvedNow.microsecondsSinceEpoch.toRadixString(16);
    final entropy = resolvedRandom.nextInt(1 << 32).toRadixString(16);
    return 'mob-$timestamp-$entropy';
  }

  static Map<String, String> appendRequestIdHeaders(
    Map<String, String> headers, {
    String? requestId,
  }) {
    final resolvedRequestId =
        requestId?.trim().isNotEmpty == true ? requestId!.trim() : generateRequestId();
    return {
      ...headers,
      'x-request-id': resolvedRequestId,
    };
  }

  static bool isReportableHttpStatus(int statusCode) => statusCode >= 400;

  Map<String, String> _getHeaders({String? requestId}) {
    final baseHeaders = {
      'Content-Type': 'application/json',
      if (_cachedToken != null) 'Authorization': 'Bearer $_cachedToken',
    };
    return appendRequestIdHeaders(baseHeaders, requestId: requestId);
  }

  /// Carrega token do disco para o cache (chamado 1x no boot).
  static Future<void> loadTokenFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');
  }

  /// Cria um HttpMetric para rastrear a requisição no Firebase Performance
  HttpMetric? _createMetric(String url, HttpMethod method) {
    if (kIsWeb || _performanceUnavailable) {
      return null;
    }

    try {
      return FirebasePerformance.instance.newHttpMetric(url, method);
    } catch (e) {
      _performanceUnavailable = true;
      debugPrint('[⚠️ ApiClient] Firebase Performance indisponível; métricas HTTP desativadas nesta sessão. Detalhe: $e');
      return null;
    }
  }

  Future<ApiResponse> get(String endpoint) async {
    _ensureBaseUrlConfigured();
    final url = '$baseUrl$endpoint';
    final requestId = generateRequestId();
    final headers = _getHeaders(requestId: requestId);
    final metric = _createMetric(url, HttpMethod.Get);
    final stopwatch = Stopwatch()..start();
    
    debugPrint('[🌐 ApiClient] GET $url');
    
    try {
      await metric?.start();
      
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      // Registra métricas
      metric?.responseContentType = response.headers['content-type'];
      metric?.httpResponseCode = response.statusCode;
      metric?.responsePayloadSize = response.contentLength ?? response.bodyBytes.length;
      await metric?.stop();
      
      final durationMs = stopwatch.elapsedMilliseconds;
      debugPrint('[🌐 ApiClient] GET $endpoint → ${response.statusCode} (${durationMs}ms)');
      
      // Alerta requisições lentas
      if (durationMs > 2000) {
        debugPrint('[⚠️ SLOW REQUEST] GET $endpoint demorou ${durationMs}ms');
      }
      
      return _parseResponse(
        response,
        method: 'GET',
        endpoint: endpoint,
        durationMs: durationMs,
        requestId: requestId,
      );
    } catch (e) {
      stopwatch.stop();
      await metric?.stop();
      debugPrint('[❌ ApiClient] GET $endpoint FALHOU após ${stopwatch.elapsedMilliseconds}ms: $e');
      unawaited(
        AppObservability.instance.captureException(
          e is Exception ? e : Exception('GET $endpoint failed: $e'),
          stackTrace: StackTrace.current,
          tags: const {'source': 'api_client', 'method': 'GET'},
          extras: {
            'endpoint': endpoint,
            'request_id': requestId,
            'duration_ms': stopwatch.elapsedMilliseconds,
          },
        ),
      );
      rethrow;
    }
  }

  Future<ApiResponse> post(String endpoint, Map<String, dynamic> body, {Duration? timeout}) async {
    _ensureBaseUrlConfigured();
    final url = '$baseUrl$endpoint';
    final requestId = generateRequestId();
    final headers = _getHeaders(requestId: requestId);
    final metric = _createMetric(url, HttpMethod.Post);
    final stopwatch = Stopwatch()..start();
    final bodyBytes = utf8.encode(jsonEncode(body));
    
    // Endpoints de IA têm timeout maior (2 minutos)
    final isAiEndpoint = endpoint.startsWith('/ai/');
    final effectiveTimeout = timeout ?? (isAiEndpoint ? const Duration(minutes: 2) : const Duration(seconds: 15));
    
    debugPrint('[🌐 ApiClient] POST $url');
    
    try {
      await metric?.start();
      metric?.requestPayloadSize = bodyBytes.length;
      
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(effectiveTimeout);
      
      stopwatch.stop();
      
      metric?.responseContentType = response.headers['content-type'];
      metric?.httpResponseCode = response.statusCode;
      metric?.responsePayloadSize = response.contentLength ?? response.bodyBytes.length;
      await metric?.stop();
      
      final durationMs = stopwatch.elapsedMilliseconds;
      debugPrint('[🌐 ApiClient] POST $endpoint → ${response.statusCode} (${durationMs}ms)');
      
      if (durationMs > 2000) {
        debugPrint('[⚠️ SLOW REQUEST] POST $endpoint demorou ${durationMs}ms');
      }
      
      return _parseResponse(
        response,
        method: 'POST',
        endpoint: endpoint,
        durationMs: durationMs,
        requestId: requestId,
      );
    } catch (e) {
      stopwatch.stop();
      await metric?.stop();
      debugPrint('[❌ ApiClient] POST $endpoint FALHOU após ${stopwatch.elapsedMilliseconds}ms: $e');
      unawaited(
        AppObservability.instance.captureException(
          e is Exception ? e : Exception('POST $endpoint failed: $e'),
          stackTrace: StackTrace.current,
          tags: const {'source': 'api_client', 'method': 'POST'},
          extras: {
            'endpoint': endpoint,
            'request_id': requestId,
            'duration_ms': stopwatch.elapsedMilliseconds,
          },
        ),
      );
      rethrow;
    }
  }

  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    _ensureBaseUrlConfigured();
    final url = '$baseUrl$endpoint';
    final requestId = generateRequestId();
    final headers = _getHeaders(requestId: requestId);
    final metric = _createMetric(url, HttpMethod.Put);
    final stopwatch = Stopwatch()..start();
    
    debugPrint('[🌐 ApiClient] PUT $url');
    
    try {
      await metric?.start();
      
      final response = await _httpClient.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      metric?.httpResponseCode = response.statusCode;
      await metric?.stop();
      
      final durationMs = stopwatch.elapsedMilliseconds;
      debugPrint('[🌐 ApiClient] PUT $endpoint → ${response.statusCode} (${durationMs}ms)');
      
      if (durationMs > 2000) {
        debugPrint('[⚠️ SLOW REQUEST] PUT $endpoint demorou ${durationMs}ms');
      }
      
      return _parseResponse(
        response,
        method: 'PUT',
        endpoint: endpoint,
        durationMs: durationMs,
        requestId: requestId,
      );
    } catch (e) {
      stopwatch.stop();
      await metric?.stop();
      debugPrint('[❌ ApiClient] PUT $endpoint FALHOU: $e');
      unawaited(
        AppObservability.instance.captureException(
          e is Exception ? e : Exception('PUT $endpoint failed: $e'),
          stackTrace: StackTrace.current,
          tags: const {'source': 'api_client', 'method': 'PUT'},
          extras: {
            'endpoint': endpoint,
            'request_id': requestId,
            'duration_ms': stopwatch.elapsedMilliseconds,
          },
        ),
      );
      rethrow;
    }
  }

  Future<ApiResponse> patch(String endpoint, Map<String, dynamic> body) async {
    _ensureBaseUrlConfigured();
    final url = '$baseUrl$endpoint';
    final requestId = generateRequestId();
    final headers = _getHeaders(requestId: requestId);
    final metric = _createMetric(url, HttpMethod.Patch);
    final stopwatch = Stopwatch()..start();
    
    debugPrint('[🌐 ApiClient] PATCH $url');
    
    try {
      await metric?.start();
      
      final response = await _httpClient.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      metric?.httpResponseCode = response.statusCode;
      await metric?.stop();
      
      final durationMs = stopwatch.elapsedMilliseconds;
      debugPrint('[🌐 ApiClient] PATCH $endpoint → ${response.statusCode} (${durationMs}ms)');
      
      return _parseResponse(
        response,
        method: 'PATCH',
        endpoint: endpoint,
        durationMs: durationMs,
        requestId: requestId,
      );
    } catch (e) {
      stopwatch.stop();
      await metric?.stop();
      debugPrint('[❌ ApiClient] PATCH $endpoint FALHOU: $e');
      unawaited(
        AppObservability.instance.captureException(
          e is Exception ? e : Exception('PATCH $endpoint failed: $e'),
          stackTrace: StackTrace.current,
          tags: const {'source': 'api_client', 'method': 'PATCH'},
          extras: {
            'endpoint': endpoint,
            'request_id': requestId,
            'duration_ms': stopwatch.elapsedMilliseconds,
          },
        ),
      );
      rethrow;
    }
  }

  Future<ApiResponse> delete(String endpoint) async {
    _ensureBaseUrlConfigured();
    final url = '$baseUrl$endpoint';
    final requestId = generateRequestId();
    final headers = _getHeaders(requestId: requestId);
    final metric = _createMetric(url, HttpMethod.Delete);
    final stopwatch = Stopwatch()..start();
    
    debugPrint('[🌐 ApiClient] DELETE $url');
    
    try {
      await metric?.start();
      
      final response = await _httpClient.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      
      stopwatch.stop();
      
      metric?.httpResponseCode = response.statusCode;
      await metric?.stop();
      
      final durationMs = stopwatch.elapsedMilliseconds;
      debugPrint('[🌐 ApiClient] DELETE $endpoint → ${response.statusCode} (${durationMs}ms)');
      
      return _parseResponse(
        response,
        method: 'DELETE',
        endpoint: endpoint,
        durationMs: durationMs,
        requestId: requestId,
      );
    } catch (e) {
      stopwatch.stop();
      await metric?.stop();
      debugPrint('[❌ ApiClient] DELETE $endpoint FALHOU: $e');
      unawaited(
        AppObservability.instance.captureException(
          e is Exception ? e : Exception('DELETE $endpoint failed: $e'),
          stackTrace: StackTrace.current,
          tags: const {'source': 'api_client', 'method': 'DELETE'},
          extras: {
            'endpoint': endpoint,
            'request_id': requestId,
            'duration_ms': stopwatch.elapsedMilliseconds,
          },
        ),
      );
      rethrow;
    }
  }

  ApiResponse _parseResponse(
    http.Response response, {
    required String method,
    required String endpoint,
    int durationMs = 0,
    String? requestId,
  }) {
    dynamic data;
    
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        data = response.body;
      }
    }
    
    final parsed = ApiResponse(
      response.statusCode,
      data,
      durationMs: durationMs,
      requestId: requestId,
      responseRequestId: response.headers['x-request-id'],
    );

    _recordHttpResult(
      method: method,
      endpoint: endpoint,
      statusCode: response.statusCode,
      durationMs: durationMs,
      requestId: requestId,
      responseRequestId: response.headers['x-request-id'],
    );
    return parsed;
  }

  void _recordHttpResult({
    required String method,
    required String endpoint,
    required int statusCode,
    required int durationMs,
    String? requestId,
    String? responseRequestId,
  }) {
    final data = <String, Object?>{
      'method': method,
      'endpoint': endpoint,
      'status_code': statusCode,
      'duration_ms': durationMs,
      if (requestId != null) 'request_id': requestId,
      if (responseRequestId != null) 'response_request_id': responseRequestId,
    };

    if (durationMs > 2000) {
      unawaited(
        AppObservability.instance.recordEvent(
          'api_slow_request',
          category: 'api',
          level: SentryLevel.warning,
          data: data,
        ),
      );
    }

    if (!isReportableHttpStatus(statusCode)) {
      return;
    }

    unawaited(
      AppObservability.instance.captureException(
        Exception('HTTP $statusCode $method $endpoint'),
        stackTrace: StackTrace.current,
        level: statusCode >= 500 ? SentryLevel.error : SentryLevel.warning,
        tags: {
          'source': 'api_client',
          'method': method,
          'http_status': statusCode.toString(),
        },
        extras: data,
      ),
    );
  }

  void _ensureBaseUrlConfigured() {
    if (baseUrl.isNotEmpty) return;
    throw StateError(
      'API_BASE_URL não configurado. Em debug use --dart-define=API_BASE_URL=http://seu-host:8080 '
      'para backend remoto/device físico; em release/profile configure a URL pública da API no build.',
    );
  }
}
