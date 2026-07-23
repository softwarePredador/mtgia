import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Serviço para monitoramento de performance usando Firebase Performance.
///
/// Funcionalidades:
/// - Rastreia tempo de carregamento de telas automaticamente
/// - Mede tempo de requisições HTTP (integrado no ApiClient)
/// - Envia métricas customizadas para o Firebase Console
///
/// ## Uso no Firebase Console:
/// 1. Acesse console.firebase.google.com
/// 2. Vá em Performance > Traces
/// 3. Verá traces como:
///    - `screen_home` - tempo na tela home
///    - `screen_decks_123` - tempo na tela de deck específico
///    - `fetch_decks` - tempo para carregar lista de decks
///    - HTTP traces automáticos com tempo de cada requisição
class PerformanceService {
  static const int maxSamplesPerSeries = 100;
  static const int maxLocalSeries = 128;
  static const String overflowSeriesName = 'other';

  static PerformanceService? _instance;
  static PerformanceService get instance =>
      _instance ??= PerformanceService._();

  PerformanceService._();

  @visibleForTesting
  static void reset() {
    _instance = null;
  }

  FirebasePerformance? _performance;
  bool _isEnabled = false;

  @visibleForTesting
  bool get isInitializedForTesting => _performance != null;

  @visibleForTesting
  bool get isEnabledForTesting => _isEnabled;

  /// Traces ativos por tela
  final Map<String, Trace> _screenTraces = {};

  /// Traces ativos por operação customizada
  final Map<String, Trace> _customTraces = {};

  /// Estatísticas locais para debug
  final Map<String, List<int>> _localStats = {};
  final Map<String, int> _localFailureCounts = {};
  final Map<String, Stopwatch> _screenStopwatches = {};
  final Map<String, Stopwatch> _customStopwatches = {};

  /// Inicializa o Firebase Performance
  Future<void> init() async {
    if (kIsWeb) {
      _isEnabled = false;
      _performance = null;
      debugPrint(
        '[PerformanceService] Web detectado: Firebase Performance desabilitado.',
      );
      return;
    }

    try {
      _performance = FirebasePerformance.instance;
      _isEnabled =
          await _performance?.isPerformanceCollectionEnabled() ?? false;

      // Habilita coleta se não estiver habilitada
      if (!_isEnabled) {
        await _performance?.setPerformanceCollectionEnabled(true);
        _isEnabled = true;
      }

      debugPrint('[PerformanceService] ✅ Inicializado (enabled=$_isEnabled)');
    } catch (e) {
      debugPrint('[PerformanceService] ⚠️ Não foi possível inicializar: $e');
      _isEnabled = false;
    }
  }

  /// Inicia trace para uma tela
  void startScreenTrace(String screenName) {
    if (_screenStopwatches.containsKey(screenName)) {
      debugPrint('[PerformanceService] ⚠️ Trace já existe: $screenName');
      return;
    }
    _screenStopwatches[screenName] = Stopwatch()..start();
    if (!_isEnabled || _performance == null) return;

    try {
      final trace = _performance!.newTrace('screen_$screenName');
      trace.start();
      _screenTraces[screenName] = trace;
      debugPrint('[PerformanceService] 📊 Trace iniciado: $screenName');
    } catch (e) {
      debugPrint('[PerformanceService] ❌ Erro ao iniciar trace: $e');
    }
  }

  /// Finaliza trace de uma tela
  void stopScreenTrace(String screenName) {
    final stopwatch = _screenStopwatches.remove(screenName);
    if (stopwatch != null) {
      stopwatch.stop();
      recordLocalDuration('screen_$screenName', stopwatch.elapsedMilliseconds);
    }
    if (!_isEnabled) return;

    try {
      final trace = _screenTraces.remove(screenName);
      if (trace != null) {
        trace.stop();
        debugPrint('[PerformanceService] ✅ Trace finalizado: $screenName');
      }
    } catch (e) {
      debugPrint('[PerformanceService] ❌ Erro ao parar trace: $e');
    }
  }

  /// Inicia um trace customizado (ex: "fetch_decks", "analyze_deck")
  void startTrace(String name) {
    if (_customStopwatches.containsKey(name)) {
      debugPrint('[PerformanceService] ⚠️ Trace customizado já existe: $name');
      return;
    }
    _customStopwatches[name] = Stopwatch()..start();
    if (!_isEnabled || _performance == null) return;

    try {
      final trace = _performance!.newTrace(name);
      trace.start();
      _customTraces[name] = trace;
    } catch (e) {
      debugPrint('[PerformanceService] ❌ Erro ao iniciar trace $name: $e');
    }
  }

  /// Finaliza um trace customizado
  void stopTrace(
    String name, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) {
    final stopwatch = _customStopwatches.remove(name);
    if (stopwatch != null) {
      stopwatch.stop();
      recordLocalDuration(name, stopwatch.elapsedMilliseconds);
    }
    if (!_isEnabled) return;

    try {
      final trace = _customTraces.remove(name);
      if (trace != null) {
        // Adiciona atributos
        attributes?.forEach((key, value) {
          trace.putAttribute(key, value);
        });

        // Adiciona métricas
        metrics?.forEach((key, value) {
          trace.setMetric(key, value);
        });

        trace.stop();
      }
    } catch (e) {
      debugPrint('[PerformanceService] ❌ Erro ao parar trace $name: $e');
    }
  }

  /// Cria um trace customizado para operações específicas (wrapper async)
  Future<T> traceAsync<T>(String name, Future<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    Trace? trace;
    Object? operationError;

    if (_isEnabled && _performance != null) {
      try {
        trace = _performance!.newTrace(name);
        await trace.start();
      } catch (error) {
        trace = null;
        debugPrint(
          '[PerformanceService] ❌ Erro ao iniciar trace $name: $error',
        );
      }
    }

    try {
      return await operation();
    } catch (error) {
      operationError = error;
      rethrow;
    } finally {
      stopwatch.stop();
      recordLocalDuration(
        name,
        stopwatch.elapsedMilliseconds,
        failed: operationError != null,
      );
      if (trace != null) {
        try {
          if (operationError != null) {
            trace.putAttribute(
              'error_type',
              operationError.runtimeType.toString(),
            );
          }
          await trace.stop();
        } catch (error) {
          debugPrint(
            '[PerformanceService] ❌ Erro ao parar trace $name: $error',
          );
        }
      }
    }
  }

  /// Registra estatística local para debug
  void recordLocalDuration(String name, int durationMs, {bool failed = false}) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final seriesName =
        _localStats.containsKey(trimmedName) ||
            _localStats.length < maxLocalSeries
        ? trimmedName
        : overflowSeriesName;
    _localStats.putIfAbsent(seriesName, () => <int>[]);
    _localStats[seriesName]!.add(durationMs < 0 ? 0 : durationMs);
    if (failed) {
      _localFailureCounts.update(
        seriesName,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    if (_localStats[seriesName]!.length > maxSamplesPerSeries) {
      _localStats[seriesName]!.removeAt(0);
    }
  }

  @visibleForTesting
  void clearLocalStats() {
    _localStats.clear();
    _localFailureCounts.clear();
    _screenStopwatches.clear();
    _customStopwatches.clear();
  }

  /// Adiciona métrica customizada a um trace ativo
  void addMetric(String screenName, String metricName, int value) {
    if (!_isEnabled) return;

    final trace = _screenTraces[screenName] ?? _customTraces[screenName];
    if (trace != null) {
      trace.setMetric(metricName, value);
    }
  }

  /// Adiciona atributo a um trace ativo
  void addAttribute(String screenName, String key, String value) {
    if (!_isEnabled) return;

    final trace = _screenTraces[screenName] ?? _customTraces[screenName];
    if (trace != null) {
      trace.putAttribute(key, value);
    }
  }

  /// Retorna estatísticas locais para debug
  Map<String, Map<String, dynamic>> getLocalStats() {
    final result = <String, Map<String, dynamic>>{};

    for (final entry in _localStats.entries) {
      final samples = List<int>.of(entry.value)..sort();
      if (samples.isEmpty) continue;

      final avg = samples.reduce((a, b) => a + b) / samples.length;
      final min = samples.first;
      final max = samples.last;
      final p50 = _percentile(samples, 0.50);
      final p90 = _percentile(samples, 0.90);
      final p95 = _percentile(samples, 0.95);

      result[entry.key] = {
        'count': samples.length,
        'error_count': _localFailureCounts[entry.key] ?? 0,
        'avg_ms': avg.round(),
        'min_ms': min,
        'max_ms': max,
        'p50_ms': p50,
        'p90_ms': p90,
        'p95_ms': p95,
      };
    }

    return result;
  }

  int _percentile(List<int> sortedSamples, double percentile) {
    final rank = (percentile * sortedSamples.length).ceil();
    final index = (rank - 1).clamp(0, sortedSamples.length - 1);
    return sortedSamples[index];
  }

  /// Imprime estatísticas locais no console (útil para debug)
  void printLocalStats() {
    final stats = getLocalStats();
    if (stats.isEmpty) {
      debugPrint('[📊 Performance] Nenhuma estatística coletada ainda');
      return;
    }

    debugPrint('[📊 Performance] ═══════════════════════════════════════');
    for (final entry in stats.entries) {
      final s = entry.value;
      debugPrint('[📊 Performance] ${entry.key}:');
      debugPrint(
        '    count=${s['count']} | errors=${s['error_count']} | '
        'avg=${s['avg_ms']}ms | p50=${s['p50_ms']}ms | '
        'p95=${s['p95_ms']}ms | max=${s['max_ms']}ms',
      );
    }
    debugPrint('[📊 Performance] ═══════════════════════════════════════');
  }
}

/// NavigatorObserver para rastrear tempo de telas automaticamente
class PerformanceNavigatorObserver extends NavigatorObserver {
  final PerformanceService _service = PerformanceService.instance;
  final Map<Route<dynamic>, DateTime> _visibleRouteStartTimes = {};
  Route<dynamic>? _visibleRoute;

  String _getScreenName(Route? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty || name == '/') {
      // Tenta extrair nome da classe do widget
      final args = route?.settings.arguments;
      if (args is Map && args.containsKey('screenName')) {
        return args['screenName'] as String;
      }
      return 'unknown';
    }
    // Limpa o nome (remove / inicial e substitui / por _)
    return name.replaceAll(RegExp(r'^/'), '').replaceAll('/', '_');
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    final screenName = _getScreenName(route);
    if (screenName != 'unknown') {
      debugPrint('[📱 Screen] → PUSH: $screenName');
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    final screenName = _getScreenName(route);
    if (screenName != 'unknown') {
      debugPrint('[📱 Screen] ← POP: $screenName');
    }
  }

  @override
  void didChangeTop(Route topRoute, Route? previousTopRoute) {
    super.didChangeTop(topRoute, previousTopRoute);
    if (identical(_visibleRoute, topRoute)) return;
    _stopVisibleRoute(previousTopRoute ?? _visibleRoute);
    _startVisibleRoute(topRoute);
  }

  void _startVisibleRoute(Route<dynamic> route) {
    final screenName = _getScreenName(route);
    _visibleRoute = route;
    if (screenName == 'unknown') return;
    _visibleRouteStartTimes[route] = DateTime.now();
    _service.startScreenTrace(screenName);
  }

  void _stopVisibleRoute(Route<dynamic>? route) {
    if (route == null) return;
    final screenName = _getScreenName(route);
    final startTime = _visibleRouteStartTimes.remove(route);
    if (screenName == 'unknown' || startTime == null) return;
    _service.stopScreenTrace(screenName);

    final duration = DateTime.now().difference(startTime);
    debugPrint(
      '[📱 Screen] ◼ VISIBLE: $screenName (${duration.inMilliseconds}ms)',
    );
    if (duration.inMilliseconds > 3000) {
      debugPrint(
        '[⚠️ SLOW SCREEN] $screenName ficou visível por '
        '${duration.inSeconds}s',
      );
    }
  }
}
