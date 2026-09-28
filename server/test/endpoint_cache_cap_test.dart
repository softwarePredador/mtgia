import 'package:test/test.dart';

import '../lib/endpoint_cache.dart';

/// BT-CAT-03: o cache de rotas tem teto de entradas por réplica. No teto,
/// saem primeiro as vencidas e depois as gravadas há mais tempo.
void main() {
  test('o teto de produção é 10.000 entradas', () {
    expect(EndpointCache.maxEntries, 10000);
    expect(EndpointCache.instance.entryLimit, EndpointCache.maxEntries);
  });

  test('no teto, a gravada há mais tempo sai e conta', () {
    final now = DateTime.utc(2026, 9, 28, 12);
    final cache = EndpointCache.forTesting(clock: () => now, entryLimit: 3);
    for (final key in ['a', 'b', 'c', 'd', 'e']) {
      cache.set(key, {'k': key}, ttl: const Duration(minutes: 5));
    }
    expect(cache.length, 3);
    expect(cache.evictions, 2);
    expect(cache.get('a'), isNull);
    expect(cache.get('b'), isNull);
    expect(cache.get('e'), {'k': 'e'});
  });

  test('regravar uma chave a leva para o fim da fila', () {
    final now = DateTime.utc(2026, 9, 28, 12);
    final cache = EndpointCache.forTesting(clock: () => now, entryLimit: 2);
    cache.set('a', {'v': 1});
    cache.set('b', {'v': 2});
    cache.set('a', {'v': 3});
    cache.set('c', {'v': 4});
    expect(cache.get('b'), isNull);
    expect(cache.get('a'), {'v': 3});
    expect(cache.get('c'), {'v': 4});
    expect(cache.evictions, 1);
  });

  test('no teto, as vencidas saem antes das vivas e não contam', () {
    var now = DateTime.utc(2026, 9, 28, 12);
    final cache = EndpointCache.forTesting(clock: () => now, entryLimit: 2);
    cache.set('curta', {'v': 1}, ttl: const Duration(seconds: 10));
    cache.set('longa', {'v': 2}, ttl: const Duration(hours: 1));
    now = now.add(const Duration(seconds: 30));
    cache.set('nova', {'v': 3});
    expect(cache.evictions, 0);
    expect(cache.get('longa'), {'v': 2});
    expect(cache.get('nova'), {'v': 3});
    expect(cache.length, 2);
  });
}
