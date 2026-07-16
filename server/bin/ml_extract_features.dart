// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../lib/basic_land_utils.dart' as land_utils;
import '../lib/runtime_environment.dart';

/// Pipeline de extração de features para Machine Learning.
///
/// Extrai dados de battle_simulations + decks e gera um CSV
/// com features numéricas prontas para treinar modelos preditivos.
///
/// Uso:
///   dart run bin/ml_extract_features.dart
///   dart run bin/ml_extract_features.dart --output=training_data.csv
///   dart run bin/ml_extract_features.dart --min-simulations=10
///
/// Output: CSV com uma linha por deck contendo:
///   - Composição: total_cards, land_count, creature_count, instant_count,
///     sorcery_count, enchantment_count, artifact_count, planeswalker_count
///   - Cores: color_W, color_U, color_B, color_R, color_G, num_colors
///   - Curva: avg_cmc, cmc_0_2_pct, cmc_3_4_pct, cmc_5plus_pct
///   - Simulação: consistency_score, screw_rate, flood_rate, keepable_rate,
///     turn1_play, turn2_play, turn3_play, turn4_play
///   - Funcional: removal_count, card_draw_count, ramp_count, board_wipe_count
///   - Meta: format, num_simulations
void main(List<String> args) async {
  final env = loadRuntimeEnvironment();

  final outputFile = _getArg(args, 'output') ?? 'ml_training_data.csv';
  final minSims = int.tryParse(_getArg(args, 'min-simulations') ?? '') ?? 0;

  print('╔══════════════════════════════════════════════╗');
  print('║   ML Feature Extraction Pipeline v1.0        ║');
  print('╚══════════════════════════════════════════════╝');

  // ── Conectar ao banco ──
  final pool = Pool.withEndpoints([
    Endpoint(
      host: env['DB_HOST'] ?? 'localhost',
      port: int.tryParse(env['DB_PORT'] ?? '') ?? 5432,
      database: env['DB_NAME'] ?? 'mtg_db',
      username: env['DB_USER'] ?? 'postgres',
      password: env['DB_PASS'] ?? 'postgres',
    ),
  ], settings: PoolSettings(maxConnectionCount: 3, sslMode: SslMode.disable));

  try {
    print('\n📡 Conectando ao banco...');

    // ── 1. Buscar todos os decks com cartas ──
    print('📊 Buscando decks...');
    final decksResult = await pool.execute('''
      SELECT d.id, d.name, d.format, d.synergy_score,
             COUNT(dc.id) as card_count
      FROM decks d
      LEFT JOIN deck_cards dc ON dc.deck_id = d.id
      GROUP BY d.id
      HAVING COUNT(dc.id) > 0
      ORDER BY card_count DESC
    ''');

    print('   → ${decksResult.length} decks com cartas encontrados');

    // ── 2. Buscar simulações ──
    print('📊 Buscando simulações...');
    final simsResult = await pool.execute('''
      SELECT deck_a_id, game_log::text, simulation_type
      FROM battle_simulations
      WHERE game_log IS NOT NULL
      ORDER BY created_at DESC
    ''');

    print('   → ${simsResult.length} simulações encontradas');

    // Indexar simulações por deck_id
    final simsByDeck = <String, List<Map<String, dynamic>>>{};
    for (final row in simsResult) {
      final deckId = row[0]?.toString();
      if (deckId == null) continue;
      try {
        final log = jsonDecode(row[1].toString()) as Map<String, dynamic>;
        simsByDeck.putIfAbsent(deckId, () => []).add(log);
      } catch (_) {
        continue;
      }
    }

    // ── 3. Extrair features de cada deck ──
    final features = <Map<String, dynamic>>[];
    var processed = 0;
    var skipped = 0;

    for (final deckRow in decksResult) {
      final deckId = deckRow[0].toString();
      final deckName = deckRow[1]?.toString() ?? '';
      final format = deckRow[2]?.toString() ?? 'unknown';
      final synergyScore = deckRow[3] as int? ?? 0;

      // Verifica mínimo de simulações
      final deckSims = simsByDeck[deckId] ?? [];
      if (deckSims.length < minSims) {
        skipped++;
        continue;
      }

      // Busca cartas do deck
      final cardsResult = await pool.execute(
        Sql.named('''
          SELECT c.name, c.mana_cost, c.cmc, c.type_line, c.oracle_text,
                 c.colors, c.color_identity, dc.quantity, dc.is_commander
          FROM deck_cards dc
          JOIN cards c ON c.id = dc.card_id
          WHERE dc.deck_id = @deckId
        '''),
        parameters: {'deckId': deckId},
      );

      if (cardsResult.isEmpty) {
        skipped++;
        continue;
      }

      final deckFeatures = _extractDeckFeatures(cardsResult, format);
      deckFeatures['deck_id'] = deckId;
      deckFeatures['deck_name'] = deckName;
      deckFeatures['synergy_score'] = synergyScore;
      deckFeatures['num_simulations'] = deckSims.length;

      // Extrai métricas de simulação (média das simulações goldfish)
      final goldfishSims =
          deckSims.where((s) => s['type'] == 'goldfish').toList();
      if (goldfishSims.isNotEmpty) {
        _extractSimFeatures(deckFeatures, goldfishSims);
      }

      features.add(deckFeatures);
      processed++;
    }

    print('   → $processed decks processados, $skipped ignorados');

    // ── 4. Gerar CSV ──
    if (features.isEmpty) {
      print('\n⚠️ Nenhum dado para exportar.');
      print('   Execute simulações primeiro: POST /ai/simulate');
      await pool.close();
      return;
    }

    final csv = _generateCsv(features);
    final file = File(outputFile);
    await file.writeAsString(csv);

    print('\n✅ CSV gerado: ${file.absolute.path}');
    print('   → $processed registros, ${features.first.keys.length} features');
    print('\n📋 Colunas:');
    for (final col in features.first.keys) {
      print('   • $col');
    }

    // ── 5. Estatísticas resumidas ──
    _printSummaryStats(features);

    await pool.close();
    print('\n🏁 Pipeline concluído!');
  } catch (e, st) {
    print('\n❌ Erro: $e');
    print(st);
    await pool.close();
    exit(1);
  }
}

/// Extrai features de composição do deck.
Map<String, dynamic> _extractDeckFeatures(
  List<ResultRow> cards,
  String format,
) {
  var totalCards = 0;
  var landCount = 0;
  var creatureCount = 0;
  var instantCount = 0;
  var sorceryCount = 0;
  var enchantmentCount = 0;
  var artifactCount = 0;
  var planeswalkerCount = 0;
  var totalCmc = 0;
  var nonLandCards = 0;

  // CMC buckets
  var cmc02 = 0;
  var cmc34 = 0;
  var cmc5plus = 0;

  // Funcional
  var removalCount = 0;
  var drawCount = 0;
  var rampCount = 0;
  var wipeCount = 0;
  var counterCount = 0;
  var tutorCount = 0;

  // Cores
  final colorSet = <String>{};
  var hasCommander = false;

  const removalKeywords = [
    'destroy target',
    'exile target',
    'deals damage to target',
    'return target.*to.*hand',
    '-x/-x',
    'sacrifice',
  ];
  const wipeKeywords = [
    'destroy all',
    'exile all',
    'all creatures get',
    'damage to each creature',
  ];
  const drawKeywords = [
    'draw a card',
    'draw two',
    'draw three',
    'draws a card',
  ];
  const rampKeywords = [
    'add {',
    'search your library for a.*land',
    'land card and put',
    'mana of any',
  ];
  const counterKeywords = ['counter target'];
  const tutorKeywords = [
    'search your library for a card',
    'search your library for a creature',
    'search your library for an',
  ];

  for (final row in cards) {
    final map = row.toColumnMap();
    final qty = (map['quantity'] as int?) ?? 1;
    final typeLine = (map['type_line'] ?? '').toString();
    final oracleText = (map['oracle_text'] ?? '').toString().toLowerCase();
    final cmc = _parseCmc(map['cmc']);
    final colors = (map['colors'] as List?)?.cast<String>() ?? [];

    totalCards += qty;
    colorSet.addAll(colors.map((c) => c.toUpperCase()));

    if (map['is_commander'] == true) hasCommander = true;

    if (land_utils.isLandTypeLine(typeLine)) {
      landCount += qty;
      continue;
    }

    nonLandCards += qty;
    totalCmc += cmc * qty;

    // Tipo
    final typeLineLower = typeLine.toLowerCase();
    if (typeLineLower.contains('creature')) creatureCount += qty;
    if (typeLineLower.contains('instant')) instantCount += qty;
    if (typeLineLower.contains('sorcery')) sorceryCount += qty;
    if (typeLineLower.contains('enchantment')) enchantmentCount += qty;
    if (typeLineLower.contains('artifact')) artifactCount += qty;
    if (typeLineLower.contains('planeswalker')) planeswalkerCount += qty;

    // CMC bucket
    if (cmc <= 2) {
      cmc02 += qty;
    } else if (cmc <= 4) {
      cmc34 += qty;
    } else {
      cmc5plus += qty;
    }

    // Funcional
    if (removalKeywords.any((k) => oracleText.contains(k))) {
      removalCount += qty;
    }
    if (wipeKeywords.any((k) => oracleText.contains(k))) wipeCount += qty;
    if (drawKeywords.any((k) => oracleText.contains(k))) drawCount += qty;
    if (rampKeywords.any((k) => oracleText.contains(k))) rampCount += qty;
    if (counterKeywords.any((k) => oracleText.contains(k))) {
      counterCount += qty;
    }
    if (tutorKeywords.any((k) => oracleText.contains(k))) tutorCount += qty;
  }

  final avgCmc = nonLandCards > 0 ? totalCmc / nonLandCards : 0.0;
  final landPct = totalCards > 0 ? landCount / totalCards : 0.0;

  return {
    'format': format,
    'total_cards': totalCards,
    'has_commander': hasCommander ? 1 : 0,

    // Composição
    'land_count': landCount,
    'land_pct': _r(landPct),
    'creature_count': creatureCount,
    'instant_count': instantCount,
    'sorcery_count': sorceryCount,
    'enchantment_count': enchantmentCount,
    'artifact_count': artifactCount,
    'planeswalker_count': planeswalkerCount,

    // Cores
    'color_W': colorSet.contains('W') ? 1 : 0,
    'color_U': colorSet.contains('U') ? 1 : 0,
    'color_B': colorSet.contains('B') ? 1 : 0,
    'color_R': colorSet.contains('R') ? 1 : 0,
    'color_G': colorSet.contains('G') ? 1 : 0,
    'num_colors': colorSet.length,

    // Curva de mana
    'avg_cmc': _r(avgCmc),
    'cmc_0_2_count': cmc02,
    'cmc_3_4_count': cmc34,
    'cmc_5plus_count': cmc5plus,
    'cmc_0_2_pct': nonLandCards > 0 ? _r(cmc02 / nonLandCards) : 0.0,
    'cmc_3_4_pct': nonLandCards > 0 ? _r(cmc34 / nonLandCards) : 0.0,
    'cmc_5plus_pct': nonLandCards > 0 ? _r(cmc5plus / nonLandCards) : 0.0,

    // Funcional
    'removal_count': removalCount,
    'card_draw_count': drawCount,
    'ramp_count': rampCount,
    'board_wipe_count': wipeCount,
    'counterspell_count': counterCount,
    'tutor_count': tutorCount,
  };
}

/// Extrai features das simulações goldfish (média).
void _extractSimFeatures(
  Map<String, dynamic> features,
  List<Map<String, dynamic>> sims,
) {
  double avgConsistency = 0;
  double avgScrew = 0;
  double avgFlood = 0;
  double avgKeepable = 0;
  double avgT1 = 0;
  double avgT2 = 0;
  double avgT3 = 0;
  double avgT4 = 0;

  var count = 0;

  for (final sim in sims) {
    final mana = sim['mana_analysis'] as Map<String, dynamic>?;
    final curve = sim['curve_analysis'] as Map<String, dynamic>?;
    final consistency = sim['consistency_score'];

    if (mana != null) {
      avgScrew += (mana['screw_rate'] as num?)?.toDouble() ?? 0;
      avgFlood += (mana['flood_rate'] as num?)?.toDouble() ?? 0;
      avgKeepable += (mana['keepable_rate'] as num?)?.toDouble() ?? 0;
    }
    if (curve != null) {
      avgT1 += (curve['turn_1_play'] as num?)?.toDouble() ?? 0;
      avgT2 += (curve['turn_2_play'] as num?)?.toDouble() ?? 0;
      avgT3 += (curve['turn_3_play'] as num?)?.toDouble() ?? 0;
      avgT4 += (curve['turn_4_play'] as num?)?.toDouble() ?? 0;
    }
    if (consistency != null) {
      avgConsistency += (consistency as num).toDouble();
    }
    count++;
  }

  if (count > 0) {
    features['sim_consistency_score'] = _r(avgConsistency / count);
    features['sim_screw_rate'] = _r(avgScrew / count);
    features['sim_flood_rate'] = _r(avgFlood / count);
    features['sim_keepable_rate'] = _r(avgKeepable / count);
    features['sim_turn1_play'] = _r(avgT1 / count);
    features['sim_turn2_play'] = _r(avgT2 / count);
    features['sim_turn3_play'] = _r(avgT3 / count);
    features['sim_turn4_play'] = _r(avgT4 / count);
  } else {
    features['sim_consistency_score'] = 0.0;
    features['sim_screw_rate'] = 0.0;
    features['sim_flood_rate'] = 0.0;
    features['sim_keepable_rate'] = 0.0;
    features['sim_turn1_play'] = 0.0;
    features['sim_turn2_play'] = 0.0;
    features['sim_turn3_play'] = 0.0;
    features['sim_turn4_play'] = 0.0;
  }
}

/// Gera CSV a partir da lista de features.
String _generateCsv(List<Map<String, dynamic>> features) {
  final buf = StringBuffer();

  // Header
  buf.writeln(features.first.keys.join(','));

  // Rows
  for (final row in features) {
    buf.writeln(
      row.values
          .map((v) {
            if (v is String) {
              // Escapa strings com aspas duplas
              return '"${v.replaceAll('"', '""')}"';
            }
            return v.toString();
          })
          .join(','),
    );
  }

  return buf.toString();
}

/// Imprime estatísticas resumidas das features extraídas.
void _printSummaryStats(List<Map<String, dynamic>> features) {
  print('\n📊 Estatísticas resumidas:');

  // Formato
  final formats = <String, int>{};
  for (final f in features) {
    final fmt = f['format']?.toString() ?? 'unknown';
    formats[fmt] = (formats[fmt] ?? 0) + 1;
  }
  print('   Formatos: $formats');

  // Média de cartas
  final avgCards =
      features
          .map((f) => (f['total_cards'] as num).toDouble())
          .reduce((a, b) => a + b) /
      features.length;
  print('   Média de cartas: ${avgCards.toStringAsFixed(1)}');

  // Média de cores
  final avgColors =
      features
          .map((f) => (f['num_colors'] as num).toDouble())
          .reduce((a, b) => a + b) /
      features.length;
  print('   Média de cores: ${avgColors.toStringAsFixed(1)}');

  // Média CMC
  final avgCmc =
      features
          .map((f) => (f['avg_cmc'] as num).toDouble())
          .reduce((a, b) => a + b) /
      features.length;
  print('   CMC médio: ${avgCmc.toStringAsFixed(2)}');

  // Com simulação
  final withSim =
      features.where((f) => (f['num_simulations'] as int) > 0).length;
  print('   Com simulações: $withSim / ${features.length}');

  if (withSim > 0) {
    final simsFeatures = features.where(
      (f) => (f['num_simulations'] as int) > 0,
    );
    final avgConsistency =
        simsFeatures
            .map((f) => (f['sim_consistency_score'] as num).toDouble())
            .reduce((a, b) => a + b) /
        withSim;
    print('   Consistência média: ${avgConsistency.toStringAsFixed(1)}');
  }
}

int _parseCmc(dynamic cmc) {
  if (cmc == null) return 0;
  if (cmc is int) return cmc;
  if (cmc is double) return cmc.toInt();
  return int.tryParse(cmc.toString()) ?? 0;
}

double _r(double v) => double.parse(v.toStringAsFixed(4));

String? _getArg(List<String> args, String name) {
  for (final arg in args) {
    if (arg.startsWith('--$name=')) {
      return arg.substring('--$name='.length);
    }
  }
  return null;
}
