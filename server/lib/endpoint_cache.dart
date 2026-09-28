class _CacheItem {
  const _CacheItem({required this.payload, required this.expiresAt});

  final Map<String, dynamic> payload;
  final DateTime expiresAt;
}

/// Cache em memória, por réplica, de respostas de rota.
///
/// D-23 (BT-PRIV-002): nenhuma entrada vale mais de 24 h ([maxTtl]), e as
/// vencidas saem da memória na primeira leitura ou gravação depois de
/// [sweepInterval], mesmo que a mesma chave nunca volte a ser lida. Assim a
/// análise de deck de uma conta excluída não fica na memória até o restart.
///
/// BT-CAT-03: no máximo [maxEntries] entradas. No teto, saem primeiro as
/// vencidas e depois as gravadas há mais tempo; [evictions] conta estas.
class EndpointCache {
  EndpointCache._({DateTime Function()? clock, int? entryLimit})
    : _clock = clock ?? DateTime.now,
      _entryLimit = entryLimit ?? maxEntries;

  /// Instância isolada, com relógio (e teto) controlados, para testes.
  factory EndpointCache.forTesting({
    required DateTime Function() clock,
    int? entryLimit,
  }) => EndpointCache._(clock: clock, entryLimit: entryLimit);

  static final EndpointCache instance = EndpointCache._();

  /// Teto de validade de qualquer entrada (D-23).
  static const maxTtl = Duration(hours: 24);

  /// Intervalo mínimo entre duas varreduras das entradas vencidas.
  static const sweepInterval = Duration(minutes: 1);

  /// Teto de entradas por réplica (BT-CAT-03).
  static const maxEntries = 10000;

  final DateTime Function() _clock;
  final int _entryLimit;
  // Mapa com a ordem de gravação: a primeira chave é a gravada há mais tempo.
  final Map<String, _CacheItem> _store = <String, _CacheItem>{};
  DateTime? _lastSweep;
  int _evictions = 0;

  /// Entradas na memória, vencidas ou não.
  int get length => _store.length;

  /// Teto desta instância.
  int get entryLimit => _entryLimit;

  /// Entradas vivas que saíram por causa do teto, desde o início do processo.
  int get evictions => _evictions;

  Map<String, dynamic>? get(String key) {
    final now = _clock();
    _sweepIfDue(now);
    final item = _store[key];
    if (item == null) return null;
    if (now.isAfter(item.expiresAt)) {
      _store.remove(key);
      return null;
    }
    return item.payload;
  }

  void set(
    String key,
    Map<String, dynamic> payload, {
    Duration ttl = const Duration(seconds: 60),
  }) {
    final now = _clock();
    _sweepIfDue(now);
    final bounded = ttl > maxTtl ? maxTtl : ttl;
    // Regravar a chave a leva para o fim da ordem.
    _store.remove(key);
    if (_store.length >= _entryLimit) {
      _clearExpired(now);
      while (_store.length >= _entryLimit) {
        _store.remove(_store.keys.first);
        _evictions++;
      }
    }
    _store[key] = _CacheItem(payload: payload, expiresAt: now.add(bounded));
  }

  void clearExpired() => _clearExpired(_clock());

  void _sweepIfDue(DateTime now) {
    final last = _lastSweep;
    if (last != null && now.difference(last) < sweepInterval) return;
    _lastSweep = now;
    _clearExpired(now);
  }

  void _clearExpired(DateTime now) {
    _store.removeWhere((_, item) => now.isAfter(item.expiresAt));
  }
}
