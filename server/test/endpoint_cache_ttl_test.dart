import 'package:test/test.dart';

import '../lib/endpoint_cache.dart';

/// D-23 (BT-PRIV-002): caches com TTL de até 24 h, e entrada vencida sai da
/// memória mesmo que a mesma chave nunca volte a ser lida.
void main() {
  late DateTime now;
  late EndpointCache cache;

  setUp(() {
    now = DateTime.utc(2026, 9, 23, 12);
    cache = EndpointCache.forTesting(clock: () => now);
  });

  test('entrada dentro do TTL é servida', () {
    cache.set('deck:analise', {'ok': true}, ttl: const Duration(minutes: 10));
    now = now.add(const Duration(minutes: 9));
    expect(cache.get('deck:analise'), {'ok': true});
  });

  test('TTL acima de 24 h é limitado a 24 h', () {
    cache.set('deck:analise', {'ok': true}, ttl: const Duration(days: 30));
    now = now.add(EndpointCache.maxTtl);
    expect(cache.get('deck:analise'), {'ok': true});
    now = now.add(const Duration(seconds: 1));
    expect(cache.get('deck:analise'), isNull);
  });

  test('entrada vencida sai da memória no próximo acesso a outra chave', () {
    cache.set('deck:de-conta-excluida', {
      'lista': 'cartas',
    }, ttl: const Duration(minutes: 10));
    expect(cache.length, 1);
    now = now.add(const Duration(minutes: 11));
    expect(cache.get('outra-chave'), isNull);
    expect(cache.length, 0);
  });

  test('a varredura roda no máximo uma vez por intervalo', () {
    cache.set('a', {'v': 1}, ttl: const Duration(seconds: 10));
    now = now.add(const Duration(seconds: 30));
    cache.set('b', {'v': 2}, ttl: const Duration(seconds: 10));
    expect(cache.length, 2, reason: 'ainda dentro do intervalo de varredura');
    now = now.add(EndpointCache.sweepInterval);
    cache.get('c');
    expect(cache.length, 0);
  });
}
