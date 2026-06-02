import 'package:postgres/postgres.dart';

import 'edhrec_service.dart';

/// Persiste snapshots diários de inclusão/sinergia de cartas por commander
/// (do EDHREC) e calcula tendências (rising/falling/stable) comparando o
/// snapshot mais recente com o anterior.
///
/// Diferente do [EdhrecService] (network-only, cache em memória), este serviço
/// precisa de um [Pool] e escreve/lê de `edhrec_card_snapshots`.
class EdhrecTrendService {
  final Pool pool;

  EdhrecTrendService(this.pool);

  /// Persiste um snapshot das cartas de um commander para [snapshotDate]
  /// (default = hoje, em UTC). Idempotente via
  /// `ON CONFLICT (commander_slug, card_name, snapshot_date)`.
  ///
  /// Retorna a quantidade de cartas persistidas.
  Future<int> persistSnapshot(
    EdhrecCommanderData data, {
    DateTime? snapshotDate,
  }) async {
    final cards = data.topCards;
    if (cards.isEmpty) return 0;

    // Uma mesma carta pode aparecer em várias categorias (cardlists) do EDHREC.
    // O UNIQUE é (commander_slug, card_name, snapshot_date), então deduplicamos
    // por nome (mantendo a maior inclusão) para não quebrar o ON CONFLICT por
    // linhas duplicadas dentro do mesmo INSERT.
    final byName = <String, EdhrecCard>{};
    for (final c in cards) {
      final existing = byName[c.name];
      if (existing == null || c.inclusionRate > existing.inclusionRate) {
        byName[c.name] = c;
      }
    }
    final deduped = byName.values.toList();

    final slug = EdhrecService.slugFor(data.commanderName);
    final date = (snapshotDate ?? DateTime.now().toUtc());
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    const batchSize = 500;
    var done = 0;
    for (var start = 0; start < deduped.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, deduped.length);
      final batch = deduped.sublist(start, end);

      final rows = <String>[];
      final params = <String, dynamic>{
        'slug': slug,
        'cmd': data.commanderName,
        'date': dateStr,
      };
      for (var i = 0; i < batch.length; i++) {
        final c = batch[i];
        rows.add(
          '(@slug, @cmd, @n$i, @inc$i, @syn$i, @nd$i, @cat$i, @date::date, CURRENT_TIMESTAMP)',
        );
        params['n$i'] = c.name;
        params['inc$i'] = c.inclusionRate;
        params['syn$i'] = c.synergy;
        params['nd$i'] = c.numDecks;
        params['cat$i'] = c.category;
      }

      await pool.execute(
        Sql.named('''
          INSERT INTO edhrec_card_snapshots (
            commander_slug, commander_name, card_name,
            inclusion, synergy, num_decks, category, snapshot_date, created_at
          ) VALUES ${rows.join(', ')}
          ON CONFLICT (commander_slug, card_name, snapshot_date) DO UPDATE SET
            inclusion = EXCLUDED.inclusion,
            synergy = EXCLUDED.synergy,
            num_decks = EXCLUDED.num_decks,
            category = EXCLUDED.category,
            commander_name = EXCLUDED.commander_name
        '''),
        parameters: params,
      );
      done += batch.length;
    }
    return done;
  }

  /// Compara os dois snapshots mais recentes (distintos por data) de um
  /// commander e retorna a tendência por carta.
  ///
  /// Quando só existe um snapshot, todas as cartas saem como `stable` com
  /// delta 0 (sem base de comparação).
  Future<List<EdhrecCardTrend>> getCardTrends(
    String commanderName, {
    double risingThreshold = 0.02,
  }) async {
    final slug = EdhrecService.slugFor(commanderName);

    final datesRes = await pool.execute(
      Sql.named('''
        SELECT DISTINCT snapshot_date
        FROM edhrec_card_snapshots
        WHERE commander_slug = @slug
        ORDER BY snapshot_date DESC
        LIMIT 2
      '''),
      parameters: {'slug': slug},
    );
    if (datesRes.isEmpty) return const [];

    final latest = datesRes.first.toColumnMap()['snapshot_date'];
    final previous =
        datesRes.length > 1 ? datesRes[1].toColumnMap()['snapshot_date'] : null;

    final latestRows = await pool.execute(
      Sql.named('''
        SELECT card_name, inclusion, synergy, num_decks, category
        FROM edhrec_card_snapshots
        WHERE commander_slug = @slug AND snapshot_date = @d
      '''),
      parameters: {'slug': slug, 'd': latest},
    );

    final prevByCard = <String, double>{};
    if (previous != null) {
      final prevRows = await pool.execute(
        Sql.named('''
          SELECT card_name, inclusion
          FROM edhrec_card_snapshots
          WHERE commander_slug = @slug AND snapshot_date = @d
        '''),
        parameters: {'slug': slug, 'd': previous},
      );
      for (final r in prevRows) {
        final m = r.toColumnMap();
        prevByCard[(m['card_name'] as String)] =
            (m['inclusion'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final trends = <EdhrecCardTrend>[];
    for (final r in latestRows) {
      final m = r.toColumnMap();
      final name = m['card_name'] as String;
      final inclusion = (m['inclusion'] as num?)?.toDouble() ?? 0.0;
      final prevInclusion = prevByCard[name];
      final delta = prevInclusion == null ? 0.0 : inclusion - prevInclusion;

      final TrendDirection direction;
      if (previous == null || prevInclusion == null) {
        direction = TrendDirection.stable;
      } else if (delta >= risingThreshold) {
        direction = TrendDirection.rising;
      } else if (delta <= -risingThreshold) {
        direction = TrendDirection.falling;
      } else {
        direction = TrendDirection.stable;
      }

      trends.add(EdhrecCardTrend(
        cardName: name,
        inclusion: inclusion,
        synergy: (m['synergy'] as num?)?.toDouble() ?? 0.0,
        numDecks: (m['num_decks'] as int?) ?? 0,
        category: (m['category'] as String?) ?? '',
        deltaInclusion: delta,
        direction: direction,
      ));
    }

    trends.sort((a, b) => b.deltaInclusion.compareTo(a.deltaInclusion));
    return trends;
  }
}

enum TrendDirection { rising, falling, stable }

class EdhrecCardTrend {
  final String cardName;
  final double inclusion;
  final double synergy;
  final int numDecks;
  final String category;
  final double deltaInclusion;
  final TrendDirection direction;

  EdhrecCardTrend({
    required this.cardName,
    required this.inclusion,
    required this.synergy,
    required this.numDecks,
    required this.category,
    required this.deltaInclusion,
    required this.direction,
  });

  Map<String, dynamic> toJson() => {
        'card_name': cardName,
        'inclusion': inclusion,
        'synergy': synergy,
        'num_decks': numDecks,
        'category': category,
        'delta_inclusion': deltaInclusion,
        'direction': direction.name,
      };
}
