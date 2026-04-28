import 'package:server/sets_catalog_contract.dart';
import 'package:test/test.dart';

void main() {
  group('sets catalog contract', () {
    final now = DateTime(2026, 4, 28, 12);

    test('classifica sets futuros, novos, atuais e antigos', () {
      expect(resolveSetStatus(DateTime(2026, 6, 26), now: now), 'future');
      expect(resolveSetStatus(DateTime(2026, 4, 24), now: now), 'new');
      expect(resolveSetStatus(DateTime(2026, 1, 23), now: now), 'current');
      expect(resolveSetStatus(DateTime(2025, 1, 1), now: now), 'old');
    });

    test('janela documentada considera 30 dias como new e 180 como current',
        () {
      expect(setCatalogNewReleaseWindowDays, 30);
      expect(setCatalogCurrentReleaseWindowDays, 180);
      expect(resolveSetStatus(DateTime(2026, 3, 29), now: now), 'new');
      expect(resolveSetStatus(DateTime(2025, 10, 30), now: now), 'current');
      expect(resolveSetStatus(DateTime(2025, 10, 29), now: now), 'old');
    });

    test(
        'normaliza busca, codigo e paginacao sem quebrar parametros existentes',
        () {
      expect(normalizeSetSearchQuery('  Marvel  '), 'Marvel');
      expect(normalizeSetSearchQuery('   '), isNull);
      expect(normalizeSetCodeFilter(' soc '), 'SOC');
      expect(safeSetCatalogLimit(null), 50);
      expect(safeSetCatalogLimit('999'), 200);
      expect(safeSetCatalogLimit('0'), 1);
      expect(safeSetCatalogPage('-2'), 1);
      expect(safeSetCatalogPage('3'), 3);
    });

    test('mapeia card_count e status sem remover campos legados', () {
      final payload = mapSetCatalogRow(
        {
          'code': 'ECC',
          'name': 'Lorwyn Eclipsed Commander',
          'release_date': DateTime(2026, 1, 23),
          'type': 'commander',
          'block': null,
          'is_online_only': false,
          'is_foreign_only': null,
          'card_count': 42,
        },
        now: now,
      );

      expect(payload['code'], 'ECC');
      expect(payload['name'], 'Lorwyn Eclipsed Commander');
      expect(payload['release_date'], '2026-01-23');
      expect(payload['type'], 'commander');
      expect(payload['is_online_only'], false);
      expect(payload['card_count'], 42);
      expect(payload['status'], 'current');
    });

    test('set sem release_date continua retornando status e card_count seguros',
        () {
      final payload = mapSetCatalogRow(
        {
          'code': 'UNK',
          'name': 'Unknown Set',
          'release_date': null,
          'type': null,
          'block': null,
          'is_online_only': null,
          'is_foreign_only': null,
          'card_count': null,
        },
        now: now,
      );

      expect(payload['status'], 'old');
      expect(payload['card_count'], 0);
    });
  });
}
