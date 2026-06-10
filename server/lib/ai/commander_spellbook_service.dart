import 'package:postgres/postgres.dart';

import '../logger.dart';

/// Representa um combo (variant) do Commander Spellbook armazenado em `card_combos`.
class ComboVariant {
  final String id;
  final String colorIdentity;
  final String? manaNeeded;
  final String? prerequisites;
  final String? description;
  final List<String> produces;
  final List<String> cardOracleIds;
  final List<String> cardNames;
  final int cardCount;

  const ComboVariant({
    required this.id,
    required this.colorIdentity,
    required this.manaNeeded,
    required this.prerequisites,
    required this.description,
    required this.produces,
    required this.cardOracleIds,
    required this.cardNames,
    required this.cardCount,
  });
}

/// Resultado do match de um combo contra um deck.
class DeckComboMatch {
  final ComboVariant combo;

  /// Quantas cartas do combo já estão no deck.
  final int presentCount;

  /// Oracle ids das cartas do combo que faltam (vazio se o combo está completo).
  final List<String> missingOracleIds;

  /// Nomes das cartas que faltam (alinhados a [missingOracleIds]).
  final List<String> missingCardNames;

  const DeckComboMatch({
    required this.combo,
    required this.presentCount,
    required this.missingOracleIds,
    required this.missingCardNames,
  });

  bool get isComplete => missingOracleIds.isEmpty;

  /// Combo a exatamente uma carta de distância de ficar completo.
  bool get isOneAway => missingOracleIds.length == 1;
}

/// Resultado agregado de [CommanderSpellbookService.findDeckCombos].
class DeckCombosResult {
  /// Combos cujas cartas estão todas presentes no deck.
  final List<DeckComboMatch> complete;

  /// Combos a 1 carta de distância (oportunidades de inclusão).
  final List<DeckComboMatch> nearMisses;

  const DeckCombosResult({
    required this.complete,
    required this.nearMisses,
  });

  bool get isEmpty => complete.isEmpty && nearMisses.isEmpty;
}

/// Serviço de integração com o Commander Spellbook.
///
/// A fonte de verdade é a tabela `card_combos` (populada offline por
/// `bin/sync_combos.dart` a partir do bulk `variants.json`). Em runtime este
/// serviço apenas consulta o banco para casar combos com um deck — sem chamadas
/// de rede no caminho quente do optimize.
class CommanderSpellbookService {
  static const bulkUrl = 'https://json.commanderspellbook.com/variants.json';

  /// Encontra combos completos e a-1-carta presentes/possíveis em um deck.
  ///
  /// [deckOracleIds] são os oracle ids (Scryfall) das cartas do deck.
  /// [commanderColorIdentity] (ex.: {'R','W'}) é usado para descartar combos
  /// fora da identidade de cor do comandante — apenas combos jogáveis.
  Future<DeckCombosResult> findDeckCombos({
    required Pool pool,
    required Set<String> deckOracleIds,
    Set<String> commanderColorIdentity = const {},
    int maxNearMisses = 40,
  }) async {
    final ids = deckOracleIds.where((e) => e.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      return const DeckCombosResult(complete: [], nearMisses: []);
    }

    List<ResultRow> rows;
    try {
      rows = await pool.execute(
        Sql.named('''
          SELECT
            c.id,
            c.color_identity,
            c.mana_needed,
            c.prerequisites,
            c.description,
            c.produces,
            c.card_oracle_ids,
            c.card_names,
            c.card_count,
            cardinality(
              ARRAY(
                SELECT unnest(c.card_oracle_ids)
                INTERSECT
                SELECT unnest(@deck_ids::text[])
              )
            ) AS present
          FROM card_combos c
          WHERE c.card_count >= 2
            AND c.card_oracle_ids && @deck_ids::text[]
            AND cardinality(
              ARRAY(
                SELECT unnest(c.card_oracle_ids)
                INTERSECT
                SELECT unnest(@deck_ids::text[])
              )
            ) >= c.card_count - 1
        '''),
        parameters: {'deck_ids': ids},
      );
    } catch (e) {
      Log.w('CommanderSpellbook findDeckCombos query failed: $e');
      return const DeckCombosResult(complete: [], nearMisses: []);
    }

    final deckSet = ids.toSet();
    final identity = commanderColorIdentity
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    final complete = <DeckComboMatch>[];
    final nearMisses = <DeckComboMatch>[];

    for (final row in rows) {
      final m = row.toColumnMap();
      final comboIdentity = (m['color_identity'] as String? ?? '').toUpperCase();

      // Filtro de identidade de cor: o combo só é jogável se sua identidade for
      // subconjunto da identidade do comandante.
      if (identity.isNotEmpty && !_identityFits(comboIdentity, identity)) {
        continue;
      }

      final oracleIds = _toStringList(m['card_oracle_ids']);
      final names = _toStringList(m['card_names']);
      final cardCount = (m['card_count'] as int?) ?? oracleIds.length;

      final missingIds = <String>[];
      final missingNames = <String>[];
      for (var i = 0; i < oracleIds.length; i++) {
        if (!deckSet.contains(oracleIds[i])) {
          missingIds.add(oracleIds[i]);
          missingNames.add(i < names.length ? names[i] : oracleIds[i]);
        }
      }

      final combo = ComboVariant(
        id: m['id'] as String,
        colorIdentity: comboIdentity,
        manaNeeded: m['mana_needed'] as String?,
        prerequisites: m['prerequisites'] as String?,
        description: m['description'] as String?,
        produces: _toStringList(m['produces']),
        cardOracleIds: oracleIds,
        cardNames: names,
        cardCount: cardCount,
      );

      final match = DeckComboMatch(
        combo: combo,
        presentCount: cardCount - missingIds.length,
        missingOracleIds: missingIds,
        missingCardNames: missingNames,
      );

      if (match.isComplete) {
        complete.add(match);
      } else if (match.isOneAway) {
        nearMisses.add(match);
      }
    }

    // Combos menores (2 cartas) e que produzem mais resultados primeiro.
    nearMisses.sort((a, b) {
      final byCount = a.combo.cardCount.compareTo(b.combo.cardCount);
      if (byCount != 0) return byCount;
      return b.combo.produces.length.compareTo(a.combo.produces.length);
    });

    return DeckCombosResult(
      complete: complete,
      nearMisses: nearMisses.take(maxNearMisses).toList(),
    );
  }

  /// True se [comboIdentity] (ex.: "BR") couber em [deckIdentity] (ex.: {B,R,G}).
  static bool _identityFits(String comboIdentity, Set<String> deckIdentity) {
    for (final c in comboIdentity.split('')) {
      if (c == 'C' || c.trim().isEmpty) continue;
      if (!deckIdentity.contains(c)) return false;
    }
    return true;
  }

  static List<String> _toStringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}
