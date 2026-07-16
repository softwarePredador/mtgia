import 'package:postgres/postgres.dart';

import '../logger.dart';

/// Persisted only when the source variant has neither structured template
/// requirements nor textual prerequisites. Legacy rows without this
/// provenance are intentionally untrusted until an audited sync rewrites them.
const commanderSpellbookVerifiedNoPrerequisitesMarker =
    '[manaloom_requirements_v1:verified_none]';

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
  final List<String> requiredCommanderOracleIds;
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
    this.requiredCommanderOracleIds = const [],
  });

  /// Prerequisites in Spellbook are game-state requirements. Only rows that a
  /// current sync explicitly marked as having none can be proven from deck
  /// composition alone. Legacy blank values remain unknown and fail closed.
  bool get hasUnverifiedPrerequisites =>
      prerequisites?.trim() != commanderSpellbookVerifiedNoPrerequisitesMarker;
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

  /// True only when every non-card requirement was explicitly verified.
  final bool requirementsSatisfied;

  const DeckComboMatch({
    required this.combo,
    required this.presentCount,
    required this.missingOracleIds,
    required this.missingCardNames,
    this.requirementsSatisfied = true,
  });

  bool get isComplete => requirementsSatisfied && missingOracleIds.isEmpty;

  /// Combo a exatamente uma carta de distância de ficar completo.
  bool get isOneAway => requirementsSatisfied && missingOracleIds.length == 1;
}

/// Resultado agregado de [CommanderSpellbookService.findDeckCombos].
class DeckCombosResult {
  /// Combos cujas cartas estão todas presentes no deck.
  final List<DeckComboMatch> complete;

  /// Combos a 1 carta de distância (oportunidades de inclusão).
  final List<DeckComboMatch> nearMisses;

  const DeckCombosResult({required this.complete, required this.nearMisses});

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
  /// [commanderOracleIds] são os oracle ids das cartas marcadas como
  /// comandante no deck. O conjunto é obrigatório para que variantes com
  /// `must_be_commander` nunca sejam promovidas só porque a carta está nas 99.
  /// [commanderColorIdentity] (ex.: {'R','W'}) é usado para descartar combos
  /// fora da identidade de cor do comandante — apenas combos jogáveis.
  Future<DeckCombosResult> findDeckCombos({
    required Pool pool,
    required Set<String> deckOracleIds,
    required Set<String> commanderOracleIds,
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
            ARRAY(
              SELECT cc.oracle_id
              FROM combo_cards cc
              WHERE cc.combo_id = c.id
                AND cc.must_be_commander = true
              ORDER BY cc.oracle_id
            ) AS required_commander_oracle_ids,
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

    return matchCommanderSpellbookRows(
      rows: rows.map((row) => row.toColumnMap()),
      deckOracleIds: ids.toSet(),
      commanderOracleIds: commanderOracleIds,
      commanderColorIdentity: commanderColorIdentity,
      maxNearMisses: maxNearMisses,
    );
  }

  /// True se [comboIdentity] (ex.: "BR") couber em [deckIdentity] (ex.: {B,R,G}).
  static bool identityFits(String comboIdentity, Set<String> deckIdentity) {
    for (final c in comboIdentity.split('')) {
      if (c == 'C' || c.trim().isEmpty) continue;
      if (!deckIdentity.contains(c)) return false;
    }
    return true;
  }

  static List<String> toStringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}

/// Converte linhas de `card_combos` em matches de forma determinística.
///
/// Separado da consulta para permitir testes de contrato sem banco e para
/// manter a classificação fail-closed no único ponto que decide `complete`.
DeckCombosResult matchCommanderSpellbookRows({
  required Iterable<Map<String, dynamic>> rows,
  required Set<String> deckOracleIds,
  required Set<String> commanderOracleIds,
  Set<String> commanderColorIdentity = const {},
  int maxNearMisses = 40,
}) {
  final deckSet =
      deckOracleIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
  final commanderSet =
      commanderOracleIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
  final identity =
      commanderColorIdentity
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toSet();

  final complete = <DeckComboMatch>[];
  final nearMisses = <DeckComboMatch>[];

  for (final m in rows) {
    final comboIdentity = (m['color_identity'] as String? ?? '').toUpperCase();

    // Filtro de identidade de cor: o combo só é jogável se sua identidade for
    // subconjunto da identidade do comandante.
    if (identity.isNotEmpty &&
        !CommanderSpellbookService.identityFits(comboIdentity, identity)) {
      continue;
    }

    final oracleIds = CommanderSpellbookService.toStringList(
      m['card_oracle_ids'],
    );
    final names = CommanderSpellbookService.toStringList(m['card_names']);
    final cardCount = (m['card_count'] as int?) ?? oracleIds.length;
    final requiredCommanderOracleIds = CommanderSpellbookService.toStringList(
      m['required_commander_oracle_ids'],
    );

    // Corrupt/incomplete persisted rows must never become complete by virtue
    // of an empty or shorter array.
    if (oracleIds.length < 2 ||
        cardCount != oracleIds.length ||
        oracleIds.toSet().length != oracleIds.length ||
        requiredCommanderOracleIds.any(
          (oracleId) => !oracleIds.contains(oracleId),
        )) {
      continue;
    }

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
      produces: CommanderSpellbookService.toStringList(m['produces']),
      cardOracleIds: oracleIds,
      cardNames: names,
      cardCount: cardCount,
      requiredCommanderOracleIds: requiredCommanderOracleIds,
    );

    final commanderRequirementsSatisfied = requiredCommanderOracleIds.every(
      commanderSet.contains,
    );
    final requirementsSatisfied =
        !combo.hasUnverifiedPrerequisites && commanderRequirementsSatisfied;
    final match = DeckComboMatch(
      combo: combo,
      presentCount: cardCount - missingIds.length,
      missingOracleIds: missingIds,
      missingCardNames: missingNames,
      requirementsSatisfied: requirementsSatisfied,
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
