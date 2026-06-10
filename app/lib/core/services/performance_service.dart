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
    if (!_isEnabled || _performance == null) return;

    try {
      // Evita traces duplicados
      if (_screenTraces.containsKey(screenName)) {
        debugPrint('[PerformanceService] ⚠️ Trace já existe: $screenName');
        return;
      }

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
    if (!_isEnabled || _performance == null) return;

    try {
      if (_customTraces.containsKey(name)) {
        debugPrint(
          '[PerformanceService] ⚠️ Trace customizado já existe: $name',
        );
        return;
      }

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
    if (!_isEnabled || _performance == null) {
      return operation();
    }

    final trace = _performance!.newTrace(name);
    final stopwatch = Stopwatch()..start();

    await trace.start();

    try {
      final result = await operation();
      stopwatch.stop();

      // Registra estatísticas locais
      _recordLocalStat(name, stopwatch.elapsedMilliseconds);

      await trace.stop();
      return result;
    } catch (e) {
      stopwatch.stop();
      trace.putAttribute(
        'error',
        e.toString().substring(0, 100.clamp(0, e.toString().length)),
      );
      await trace.stop();
      rethrow;
    }
  }

  /// Registra estatística local para debug
  void _recordLocalStat(String name, int durationMs) {
    _localStats.putIfAbsent(name, () => []);
    _localStats[name]!.add(durationMs);

    // Mantém apenas últimas 100 amostras
    if (_localStats[name]!.length > 100) {
      _localStats[name]!.removeAt(0);
    }
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
      final samples = entry.value;
      if (samples.isEmpty) continue;

      samples.sort();
      final avg = samples.reduce((a, b) => a + b) / samples.length;
      final min = samples.first;
      final max = samples.last;
      final p50 = samples[samples.length ~/ 2];
      final p90 = samples[(samples.length * 0.9).floor()];

      result[entry.key] = {
        'count': samples.length,
        'avg_ms': avg.round(),
        'min_ms': min,
        'max_ms': max,
        'p50_ms': p50,
        'p90_ms': p90,
      };
    }

    return result;
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
        '    count=${s['count']} | avg=${s['avg_ms']}ms | p50=${s['p50_ms']}ms | p90=${s['p90_ms']}ms | max=${s['max_ms']}ms',
      );
    }
    debugPrint('[📊 Performance] ═══════════════════════════════════════');
  }
}

/// NavigatorObserver para rastrear tempo de telas automaticamente
class PerformanceNavigatorObserver extends NavigatorObserver {
  final PerformanceService _service = PerformanceService.instance;

  /// Mapa para rastrear tempo local (para debug logs)
  final Map<String, DateTime> _screenStartTimes = {};

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
      _screenStartTimes[screenName] = DateTime.now();
      _service.startScreenTrace(screenName);
      debugPrint('[📱 Screen] → PUSH: $screenName');
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    final screenName = _getScreenName(route);

    if (screenName != 'unknown') {
      final startTime = _screenStartTimes.remove(screenName);
      _service.stopScreenTrace(screenName);

      if (startTime != null) {
        final duration = DateTime.now().difference(startTime);
        debugPrint(
          '[📱 Screen] ← POP: $screenName (${duration.inMilliseconds}ms)',
        );

        // Alerta se a tela foi muito lenta
        if (duration.inMilliseconds > 3000) {
          debugPrint(
            '[⚠️ SLOW SCREEN] $screenName demorou ${duration.inSeconds}s',
          );
        }
      }
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    final oldName = _getScreenName(oldRoute);
    final newName = _getScreenName(newRoute);

    if (oldName != 'unknown') {
      _screenStartTimes.remove(oldName);
      _service.stopScreenTrace(oldName);
    }

    if (newName != 'unknown') {
      _screenStartTimes[newName] = DateTime.now();
      _service.startScreenTrace(newName);
    }

    debugPrint('[📱 Screen] ↔ REPLACE: $oldName → $newName');
  }
}
