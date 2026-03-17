import 'dart:math' as math;

import 'package:postgres/postgres.dart';

import 'deck_state_analysis.dart';
import '../deck_rules_service.dart';
import '../deck_schema_support.dart';
import '../edh_bracket_policy.dart';
import '../logger.dart';
import 'edhrec_service.dart';

class RebuildTargetProfile {
  const RebuildTargetProfile({
    required this.totalCards,
    required this.landCount,
    required this.ramp,
    required this.drawSelection,
    required this.interaction,
    required this.wipes,
    required this.payoffs,
    required this.wincons,
    required this.rawCategoryTargets,
  });

  final int totalCards;
  final int landCount;
  final int ramp;
  final int drawSelection;
  final int interaction;
  final int wipes;
  final int payoffs;
  final int wincons;
  final Map<String, int> rawCategoryTargets;

  Map<String, dynamic> toJson() => {
        'total_cards': totalCards,
        'land_count': landCount,
        'ramp': ramp,
        'draw_selection': drawSelection,
        'interaction': interaction,
        'wipes': wipes,
        'payoffs': payoffs,
        'wincons': wincons,
        'raw_category_targets': rawCategoryTargets,
      };
}

class RebuildScopeDecision {
  const RebuildScopeDecision({
    required this.requestedScope,
    required this.selectedScope,
    required this.keepRate,
    required this.keptCards,
    required this.cutCards,
    required this.reasons,
  });

  final String requestedScope;
  final String selectedScope;
  final double keepRate;
  final List<Map<String, dynamic>> keptCards;
  final List<Map<String, dynamic>> cutCards;
  final List<String> reasons;

  Map<String, dynamic> toJson() => {
        'requested_scope': requestedScope,
        'selected_scope': selectedScope,
        'keep_rate': keepRate,
        'reasons': reasons,
      };
}

class RebuildResult {
  const RebuildResult({
    required this.scopeDecision,
    required this.targetProfile,
    required this.rebuiltCards,
    required this.deckAnalysisBefore,
    required this.deckAnalysisAfter,
    required this.deckStateBefore,
    required this.deckStateAfter,
    required this.resolvedTheme,
    required this.resolvedArchetype,
    required this.keptCards,
    required this.warnings,
    required this.sourceSummary,
  });

  final RebuildScopeDecision scopeDecision;
  final RebuildTargetProfile targetProfile;
  final List<Map<String, dynamic>> rebuiltCards;
  final Map<String, dynamic> deckAnalysisBefore;
  final Map<String, dynamic> deckAnalysisAfter;
  final DeckOptimizationState deckStateBefore;
  final DeckOptimizationState deckStateAfter;
  final String resolvedTheme;
  final String resolvedArchetype;
  final List<Map<String, dynamic>> keptCards;
  final List<String> warnings;
  final Map<String, dynamic> sourceSummary;

  int get totalCards =>
      rebuiltCards.fold<int>(0, (sum, card) => sum + ((card['quantity'] as int?) ?? 0));

  int get replacedSlots {
    final kept = keptCards.fold<int>(
      0,
      (sum, card) => sum + ((card['quantity'] as int?) ?? 0),
    );
    return math.max(0, totalCards - kept);
  }
}

class RebuildGuidedService {
  RebuildGuidedService(this._pool, {EdhrecService? edhrecService})
      : _edhrecService = edhrecService ?? EdhrecService();

  final Pool _pool;
  final EdhrecService _edhrecService;

  Future<RebuildResult> build({
    required List<Map<String, dynamic>> originalDeck,
    required String deckFormat,
    required List<String> commanders,
    required Set<String> commanderColorIdentity,
    required int? bracket,
    String? requestedArchetype,
    String? requestedTheme,
    String rebuildScope = 'auto',
    List<String> mustKeep = const [],
    List<String> mustAvoid = const [],
  }) async {
    final deckColors = <String>{};
    for (final card in originalDeck) {
      deckColors.addAll((card['colors'] as List?)?.cast<String>() ?? const []);
    }

    final deckAnalysisBefore =
        DeckArchetypeAnalyzer(originalDeck, deckColors.toList())
            .generateAnalysis();
    final deckStateBefore = assessDeckOptimizationState(
      cards: originalDeck,
      deckAnalysis: deckAnalysisBefore,
      deckFormat: deckFormat,
      currentTotalCards: _totalCards(originalDeck),
      commanderColorIdentity: commanderColorIdentity,
    );

    final commanderName = commanders.firstWhere(
      (name) => name.trim().isNotEmpty,
      orElse: () => '',
    );
    if (commanderName.isEmpty) {
      throw RebuildException(
        'Nao foi possivel iniciar o rebuild sem comandante definido.',
      );
    }

    final commanderData = await _edhrecService.fetchCommanderData(commanderName);
    final averageDeckData =
        await _edhrecService.fetchAverageDeckData(commanderName);
    final cachedProfile =
        await _loadCommanderReferenceProfileFromCache(commanderName);

    final resolvedTheme = _resolveTheme(
      requestedTheme: requestedTheme,
      commanderData: commanderData,
      commanderName: commanderName,
      originalDeck: originalDeck,
    );
    var resolvedArchetype = resolveOptimizeArchetype(
      requestedArchetype: requestedArchetype,
      detectedArchetype: deckAnalysisBefore['detected_archetype']?.toString(),
    );
    if (resolvedTheme == 'counters' && resolvedArchetype == 'aggro') {
      resolvedArchetype = 'midrange';
    }

    final targetProfile = _buildTargetProfile(
      deckFormat: deckFormat,
      requestedArchetype: resolvedArchetype,
      resolvedTheme: resolvedTheme,
      commanderData: commanderData,
      cachedProfile: cachedProfile,
    );

    final candidateWeights = _buildCandidateWeights(
      averageDeckData: averageDeckData,
      commanderData: commanderData,
      cachedProfile: cachedProfile,
    );
    final mustKeepLower =
        mustKeep.map((name) => name.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
    final mustAvoidLower =
        mustAvoid.map((name) => name.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();

    final currentCardScores = _scoreCurrentDeckCards(
      originalDeck: originalDeck,
      commanderColorIdentity: commanderColorIdentity,
      candidateWeights: candidateWeights,
      targetProfile: targetProfile,
      resolvedArchetype: resolvedArchetype,
      resolvedTheme: resolvedTheme,
      mustKeep: mustKeepLower,
      mustAvoid: mustAvoidLower,
    );
    final scopeDecision = _decideScope(
      requestedScope: rebuildScope,
      originalDeck: originalDeck,
      deckStateBefore: deckStateBefore,
      currentCardScores: currentCardScores,
    );

    final candidateNames = candidateWeights.keys.toSet().toList();
    final candidateCards = await _loadCardsByNames(candidateNames);
    final basicLandCatalog = await _loadBasicLandCatalog();
    final weightedCandidates = _weightCandidateCards(
      candidateCards: candidateCards,
      candidateWeights: candidateWeights,
      commanderColorIdentity: commanderColorIdentity,
      resolvedArchetype: resolvedArchetype,
      resolvedTheme: resolvedTheme,
      mustAvoid: mustAvoidLower,
    );

    final rebuiltCards = _assembleDeck(
      originalDeck: originalDeck,
      scopeDecision: scopeDecision,
      weightedCandidates: weightedCandidates,
      targetProfile: targetProfile,
      commanderColorIdentity: commanderColorIdentity,
      deckFormat: deckFormat,
      bracket: bracket,
      resolvedArchetype: resolvedArchetype,
      resolvedTheme: resolvedTheme,
      mustKeep: mustKeepLower,
      mustAvoid: mustAvoidLower,
      basicLandCatalog: basicLandCatalog,
    );

    await _pool.runTx(
      (session) => DeckRulesService(session).validateAndThrow(
        format: deckFormat,
        cards: rebuiltCards
            .map((card) => {
                  'card_id': card['card_id'],
                  'quantity': card['quantity'],
                  'is_commander': card['is_commander'] ?? false,
                })
            .toList(),
        strict: true,
      ),
    );

    final rebuiltDeckColors = <String>{};
    for (final card in rebuiltCards) {
      rebuiltDeckColors.addAll((card['colors'] as List?)?.cast<String>() ?? const []);
    }
    final deckAnalysisAfter = DeckArchetypeAnalyzer(
      rebuiltCards,
      rebuiltDeckColors.toList(),
    ).generateAnalysis();
    final deckStateAfter = assessDeckOptimizationState(
      cards: rebuiltCards,
      deckAnalysis: deckAnalysisAfter,
      deckFormat: deckFormat,
      currentTotalCards: _totalCards(rebuiltCards),
      commanderColorIdentity: commanderColorIdentity,
    );

    final warnings = <String>[];
    if (deckStateAfter.status == 'needs_repair') {
      warnings.add(
        'O rebuild gerado ainda exige ajustes estruturais. Revise o draft antes de aplicar.',
      );
    }
    if (commanderData == null) {
      warnings.add(
        'EDHREC nao retornou dados completos para esse comandante; o rebuild usou heuristicas locais.',
      );
    }
    if (averageDeckData == null) {
      warnings.add(
        'Average deck do EDHREC indisponivel; a reconstrução usou top cards e estrutura heurística.',
      );
    }

    final keptCards = scopeDecision.keptCards
        .map((card) => Map<String, dynamic>.from(card))
        .toList(growable: false);

    return RebuildResult(
      scopeDecision: scopeDecision,
      targetProfile: targetProfile,
      rebuiltCards: rebuiltCards,
      deckAnalysisBefore: deckAnalysisBefore,
      deckAnalysisAfter: deckAnalysisAfter,
      deckStateBefore: deckStateBefore,
      deckStateAfter: deckStateAfter,
      resolvedTheme: resolvedTheme,
      resolvedArchetype: resolvedArchetype,
      keptCards: keptCards,
      warnings: warnings,
      sourceSummary: {
        'used_average_deck_seed': averageDeckData != null,
        'used_edhrec_top_cards': commanderData != null,
        'used_cached_commander_profile': cachedProfile != null,
        'candidate_pool_size': weightedCandidates.length,
      },
    );
  }

  Future<Map<String, dynamic>?> createDraftClone({
    required String userId,
    required String sourceDeckId,
    required String sourceDeckName,
    required String deckFormat,
    required String resolvedArchetype,
    required int? bracket,
    required List<Map<String, dynamic>> rebuiltCards,
    required String resolvedTheme,
    required String selectedScope,
  }) async {
    final hasMeta = await hasDeckMetaColumns(_pool);
    final draftName = 'Rebuild Draft - $sourceDeckName';

    return _pool.runTx((session) async {
      final insertDeck = await session.execute(
        Sql.named(
          hasMeta
              ? '''
                INSERT INTO decks (user_id, name, format, description, archetype, bracket, is_public)
                VALUES (@userId, @name, @format, @description, @archetype, @bracket, false)
                RETURNING id::text, name, format, description, archetype, bracket, is_public, created_at
              '''
              : '''
                INSERT INTO decks (user_id, name, format, description, is_public)
                VALUES (@userId, @name, @format, @description, false)
                RETURNING id::text, name, format, description, created_at, is_public
              ''',
        ),
        parameters: {
          'userId': userId,
          'name': draftName,
          'format': deckFormat,
          'description':
              'Draft de rebuild_guided criado a partir de $sourceDeckId | theme=$resolvedTheme | scope=$selectedScope',
          if (hasMeta) 'archetype': resolvedArchetype,
          if (hasMeta) 'bracket': bracket,
        },
      );

      final deckMap = insertDeck.first.toColumnMap();
      final newDeckId = deckMap['id'] as String;

      final values = <String>[];
      final parameters = <String, dynamic>{'deckId': newDeckId};
      for (var i = 0; i < rebuiltCards.length; i++) {
        final card = rebuiltCards[i];
        values.add('(@deckId, @cardId$i, @qty$i, @isCommander$i)');
        parameters['cardId$i'] = card['card_id'];
        parameters['qty$i'] = card['quantity'];
        parameters['isCommander$i'] = card['is_commander'] ?? false;
      }

      final sql =
          'INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander) VALUES ${values.join(', ')}';
      await session.execute(Sql.named(sql), parameters: parameters);

      if (deckMap['created_at'] is DateTime) {
        deckMap['created_at'] =
            (deckMap['created_at'] as DateTime).toIso8601String();
      }
      return deckMap.cast<String, dynamic>();
    });
  }

  RebuildTargetProfile _buildTargetProfile({
    required String deckFormat,
    required String requestedArchetype,
    required String resolvedTheme,
    required EdhrecCommanderData? commanderData,
    required Map<String, dynamic>? cachedProfile,
  }) {
    final recommendedStructure = cachedProfile?['recommended_structure'] is Map
        ? (cachedProfile!['recommended_structure'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final categoryTargetsRaw = recommendedStructure['category_targets'] is Map
        ? (recommendedStructure['category_targets'] as Map)
            .cast<String, dynamic>()
            .map((key, value) => MapEntry(key, _toInt(value) ?? 0))
        : const <String, int>{};

    final totalCards = deckFormat == 'brawl' ? 60 : 100;
    final recommendedLands = _toInt(recommendedStructure['lands']) ??
        _deriveRecommendedLands(
          deckFormat: deckFormat,
          requestedArchetype: requestedArchetype,
          resolvedTheme: resolvedTheme,
          commanderData: commanderData,
        );

    var ramp = 10;
    var drawSelection = 12;
    var interaction = 12;
    var wipes = 2;
    var payoffs = 8;
    var wincons = 4;

    if (requestedArchetype == 'control') {
      drawSelection = 14;
      interaction = 16;
      wipes = 3;
      payoffs = 6;
      wincons = 3;
    } else if (requestedArchetype == 'aggro') {
      ramp = 8;
      drawSelection = 9;
      interaction = 8;
      wipes = 1;
      payoffs = 10;
      wincons = 6;
    } else if (requestedArchetype == 'combo') {
      ramp = 11;
      drawSelection = 13;
      interaction = 10;
      wipes = 1;
      payoffs = 9;
      wincons = 6;
    }

    if (resolvedTheme == 'counters') {
      ramp = 9;
      drawSelection = 10;
      interaction = 10;
      wipes = 2;
      payoffs = 12;
      wincons = 4;
    } else if (_isAggroTribalTheme(resolvedTheme)) {
      ramp = 7;
      drawSelection = 8;
      interaction = 7;
      wipes = 1;
      payoffs = 15;
      wincons = 6;
    } else if (resolvedTheme == 'spellslinger') {
      ramp = 10;
      drawSelection = 16;
      interaction = 15;
      wipes = 2;
      payoffs = 10;
      wincons = 5;
    } else if (resolvedTheme == 'artifacts') {
      ramp = 11;
      drawSelection = 11;
      interaction = 10;
      wipes = 2;
      payoffs = 12;
      wincons = 5;
    } else if (resolvedTheme == 'enchantments') {
      ramp = 9;
      drawSelection = 12;
      interaction = 10;
      wipes = 2;
      payoffs = 12;
      wincons = 4;
    } else if (resolvedTheme == 'voltron') {
      ramp = 9;
      drawSelection = 9;
      interaction = 12;
      wipes = 1;
      payoffs = 11;
      wincons = 6;
    }

    return RebuildTargetProfile(
      totalCards: totalCards,
      landCount: recommendedLands,
      ramp: math.max(ramp, categoryTargetsRaw['ramp'] ?? 0),
      drawSelection:
          math.max(drawSelection, categoryTargetsRaw['card_draw'] ?? 0),
      interaction: interaction,
      wipes: wipes,
      payoffs: payoffs,
      wincons: wincons,
      rawCategoryTargets: categoryTargetsRaw,
    );
  }

  int _deriveRecommendedLands({
    required String deckFormat,
    required String requestedArchetype,
    required String resolvedTheme,
    required EdhrecCommanderData? commanderData,
  }) {
    if (commanderData != null) {
      final dist = commanderData.averageTypeDistribution;
      final basic = dist['basic'] ?? 0;
      final nonbasic = dist['nonbasic'] ?? 0;
      final total = basic + nonbasic;
      if (total > 0) return total;
    }

    if (deckFormat == 'brawl') return 25;
    if (requestedArchetype == 'aggro') return 34;
    if (requestedArchetype == 'control') return 37;
    if (resolvedTheme == 'counters') return 36;
    if (resolvedTheme == 'spellslinger') return 36;
    return 36;
  }

  String _resolveTheme({
    required String? requestedTheme,
    required EdhrecCommanderData? commanderData,
    required String commanderName,
    required List<Map<String, dynamic>> originalDeck,
  }) {
    final normalizedRequested = _normalizeTheme(requestedTheme);
    if (normalizedRequested != null) return normalizedRequested;

    final commanderText = originalDeck
        .where((card) => card['is_commander'] == true)
        .map((card) => (card['oracle_text'] as String?) ?? '')
        .join(' ')
        .toLowerCase();

    if (commanderText.contains('instant or sorcery')) return 'spellslinger';
    if (commanderText.contains('artifact')) return 'artifacts';
    if (commanderText.contains('enchantment')) return 'enchantments';
    if (commanderText.contains('equipped creature') ||
        commanderText.contains('auras attached')) {
      return 'voltron';
    }

    final themes = commanderData?.themes ?? const <String>[];
    for (final theme in themes) {
      final normalized = _normalizeTheme(theme);
      if (normalized != null) return normalized;
    }

    final commanderLower = commanderName.toLowerCase();
    if (commanderLower.contains('talrand')) return 'spellslinger';
    return 'midrange';
  }

  String? _normalizeTheme(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return null;
    if (normalized.contains('spell')) return 'spellslinger';
    if (normalized.contains('-1/-1') ||
        normalized.contains('proliferate') ||
        normalized == 'counters') {
      return 'counters';
    }
    if (normalized.contains('artifact')) return 'artifacts';
    if (normalized.contains('enchant')) return 'enchantments';
    if (normalized.contains('voltron')) return 'voltron';
    if (normalized.contains('control')) return 'control';
    if (normalized.contains('combo')) return 'combo';
    if (normalized.contains('aggro')) return 'aggro';
    return normalized;
  }

  Map<String, int> _buildCandidateWeights({
    required EdhrecAverageDeckData? averageDeckData,
    required EdhrecCommanderData? commanderData,
    required Map<String, dynamic>? cachedProfile,
  }) {
    final weights = <String, int>{};

    void addWeight(String name, int weight) {
      final cleaned = name.trim();
      if (cleaned.isEmpty) return;
      weights[cleaned] = math.max(weights[cleaned] ?? 0, weight);
    }

    if (averageDeckData != null) {
      for (var i = 0; i < averageDeckData.seedCards.length; i++) {
        final card = averageDeckData.seedCards[i];
        addWeight(card.name, 220 - i + card.quantity * 5);
      }
    }

    if (commanderData != null) {
      for (var i = 0; i < commanderData.topCards.length; i++) {
        final card = commanderData.topCards[i];
        final weight =
            170 - i + (card.synergy * 40).round() + (card.inclusion * 20).round();
        addWeight(card.name, weight);
      }
    }

    if (cachedProfile != null) {
      final topCards = cachedProfile['top_cards'] as List?;
      if (topCards != null) {
        for (var i = 0; i < topCards.length; i++) {
          final entry = topCards[i];
          if (entry is! Map) continue;
          final name = entry['name']?.toString() ?? '';
          addWeight(name, 150 - i);
        }
      }

      final avgSeed = cachedProfile['average_deck_seed'] as List?;
      if (avgSeed != null) {
        for (var i = 0; i < avgSeed.length; i++) {
          final entry = avgSeed[i];
          if (entry is! Map) continue;
          final name = entry['name']?.toString() ?? '';
          final quantity = _toInt(entry['quantity']) ?? 1;
          addWeight(name, 210 - i + quantity * 5);
        }
      }
    }

    return weights;
  }

  Map<String, int> _scoreCurrentDeckCards({
    required List<Map<String, dynamic>> originalDeck,
    required Set<String> commanderColorIdentity,
    required Map<String, int> candidateWeights,
    required RebuildTargetProfile targetProfile,
    required String resolvedArchetype,
    required String resolvedTheme,
    required Set<String> mustKeep,
    required Set<String> mustAvoid,
  }) {
    final scores = <String, int>{};
    final totalLandsTarget = targetProfile.landCount;

    for (final card in originalDeck) {
      final name = (card['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) continue;
      final lower = name.toLowerCase();

      if (card['is_commander'] == true) {
        scores[lower] = 1000;
        continue;
      }
      if (mustAvoid.contains(lower)) {
        scores[lower] = 0;
        continue;
      }
      if (mustKeep.contains(lower)) {
        scores[lower] = 900;
        continue;
      }

      var score = candidateWeights[name] ?? candidateWeights[lower] ?? 0;
      final role = _normalizedRoleForCard(
        card,
        resolvedArchetype: resolvedArchetype,
        resolvedTheme: resolvedTheme,
      );
      final typeLine = (card['type_line'] as String?)?.toLowerCase() ?? '';
      final oracle = (card['oracle_text'] as String?)?.toLowerCase() ?? '';
      final colors = _extractIdentity(card);

      if (typeLine.contains('land')) {
        if (_landProducesCommanderColor(oracle, commanderColorIdentity) ||
            _isAnyColorLand(oracle)) {
          score += 55;
        } else if (_basicMatchesCommander(lower, commanderColorIdentity)) {
          score += 40;
        } else if (lower == 'wastes' && commanderColorIdentity.isNotEmpty) {
          score -= 60;
        }

        if (totalLandsTarget < 35 && lower == 'wastes') {
          score -= 10;
        }
      } else {
        if (colors.isNotEmpty &&
            colors.difference(commanderColorIdentity).isNotEmpty) {
          score -= 100;
        }
        if (role == 'ramp') score += 20;
        if (role == 'draw') score += 20;
        if (role == 'interaction') score += 20;
        if (role == 'wipe') score += 12;
        if (role == 'payoff' || role == 'engine') score += 18;
        if (role == 'wincon') score += 15;
      }

      score += _curveAndThemeAdjustment(
        card: card,
        role: role,
        resolvedArchetype: resolvedArchetype,
        resolvedTheme: resolvedTheme,
      );

      scores[lower] = score;
    }

    return scores;
  }

  RebuildScopeDecision _decideScope({
    required String requestedScope,
    required List<Map<String, dynamic>> originalDeck,
    required DeckOptimizationState deckStateBefore,
    required Map<String, int> currentCardScores,
  }) {
    final normalizedRequested = requestedScope.trim().toLowerCase();
    final keepThreshold =
        normalizedRequested == 'full_non_commander_rebuild' ? 120 : 80;

    final keptCards = <Map<String, dynamic>>[];
    final cutCards = <Map<String, dynamic>>[];
    var keepNonCommanderQty = 0;
    var totalNonCommanderQty = 0;

    for (final card in originalDeck) {
      final quantity = (card['quantity'] as int?) ?? 1;
      if (card['is_commander'] == true) {
        keptCards.add(Map<String, dynamic>.from(card));
        continue;
      }
      totalNonCommanderQty += quantity;
      final name = (card['name'] as String?)?.trim().toLowerCase() ?? '';
      final score = currentCardScores[name] ?? 0;
      if (score >= keepThreshold) {
        keptCards.add(Map<String, dynamic>.from(card));
        keepNonCommanderQty += quantity;
      } else {
        cutCards.add(Map<String, dynamic>.from(card));
      }
    }

    final keepRate = totalNonCommanderQty == 0
        ? 1.0
        : keepNonCommanderQty / totalNonCommanderQty;

    var selectedScope = normalizedRequested;
    if (selectedScope.isEmpty || selectedScope == 'auto') {
      selectedScope =
          keepRate < 0.25 || deckStateBefore.severityScore >= 70
              ? 'full_non_commander_rebuild'
              : 'repair_partial';
    }
    if (selectedScope != 'repair_partial' &&
        selectedScope != 'full_non_commander_rebuild') {
      selectedScope = 'repair_partial';
    }

    final reasons = <String>[
      'Keep rate calculado em ${(keepRate * 100).toStringAsFixed(0)}% do shell atual.',
      if (deckStateBefore.status == 'needs_repair')
        'Optimize classificou o deck como needs_repair antes do rebuild.',
    ];
    if (selectedScope == 'full_non_commander_rebuild') {
      reasons.add(
        'A maior parte da lista atual nao sustenta o plano do comandante; rebuild completo dos slots nao-comandante selecionado.',
      );
    } else {
      reasons.add(
        'Parte relevante da shell ainda e aproveitavel; rebuild parcial selecionado.',
      );
    }

    return RebuildScopeDecision(
      requestedScope: normalizedRequested.isEmpty ? 'auto' : normalizedRequested,
      selectedScope: selectedScope,
      keepRate: keepRate,
      keptCards: keptCards,
      cutCards: cutCards,
      reasons: reasons,
    );
  }

  Future<List<Map<String, dynamic>>> _loadCardsByNames(List<String> names) async {
    if (names.isEmpty) return const [];
    final normalized = names.map((name) => name.toLowerCase()).toSet().toList();

    final result = await _pool.execute(
      Sql.named(r'''
        SELECT DISTINCT ON (LOWER(name))
               id::text,
               name,
               type_line,
               COALESCE(mana_cost, '') AS mana_cost,
               COALESCE(colors, ARRAY[]::text[]) AS colors,
               COALESCE(color_identity, ARRAY[]::text[]) AS color_identity,
               COALESCE(
                 (
                   SELECT SUM(
                     CASE
                       WHEN m[1] ~ '^[0-9]+$' THEN m[1]::int
                       WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                       WHEN m[1] = 'X' THEN 0
                       ELSE 1
                     END
                   )
                   FROM regexp_matches(COALESCE(mana_cost, ''), '\{([^}]+)\}', 'g') AS m(m)
                 ),
                 0
               )::double precision AS cmc,
               COALESCE(oracle_text, '') AS oracle_text
        FROM cards
        WHERE LOWER(name) = ANY(@names)
        ORDER BY LOWER(name), id
      '''),
      parameters: {'names': normalized},
    );

    return result
        .map(
          (row) => <String, dynamic>{
            'card_id': row[0] as String,
            'name': row[1] as String? ?? '',
            'type_line': row[2] as String? ?? '',
            'mana_cost': row[3] as String? ?? '',
            'colors': (row[4] as List?)?.cast<String>() ?? const <String>[],
            'color_identity':
                (row[5] as List?)?.cast<String>() ?? const <String>[],
            'cmc': (row[6] as num?)?.toDouble() ?? 0.0,
            'oracle_text': row[7] as String? ?? '',
            'quantity': 1,
            'is_commander': false,
          },
        )
        .toList();
  }

  List<_WeightedCard> _weightCandidateCards({
    required List<Map<String, dynamic>> candidateCards,
    required Map<String, int> candidateWeights,
    required Set<String> commanderColorIdentity,
    required String resolvedArchetype,
    required String resolvedTheme,
    required Set<String> mustAvoid,
  }) {
    final weighted = <_WeightedCard>[];

    for (final card in candidateCards) {
      final name = (card['name'] as String?)?.trim() ?? '';
      final lower = name.toLowerCase();
      if (name.isEmpty || mustAvoid.contains(lower)) continue;

      final identity = _extractIdentity(card);
      if (identity.isNotEmpty &&
          identity.difference(commanderColorIdentity).isNotEmpty) {
        continue;
      }

      var weight = candidateWeights[name] ?? candidateWeights[lower] ?? 0;
      final role = _normalizedRoleForCard(
        card,
        resolvedArchetype: resolvedArchetype,
        resolvedTheme: resolvedTheme,
      );
      if (role == 'ramp' || role == 'draw' || role == 'interaction') {
        weight += 12;
      } else if (role == 'payoff' || role == 'engine') {
        weight += 18;
      } else if (role == 'wipe' || role == 'wincon') {
        weight += 10;
      } else if (role == 'land') {
        weight += 8;
      }
      weight += _curveAndThemeAdjustment(
        card: card,
        role: role,
        resolvedArchetype: resolvedArchetype,
        resolvedTheme: resolvedTheme,
      );
      weighted.add(
        _WeightedCard(
          card: Map<String, dynamic>.from(card),
          weight: weight,
          role: role,
        ),
      );
    }

    weighted.sort((a, b) {
      final byWeight = b.weight.compareTo(a.weight);
      if (byWeight != 0) return byWeight;
      return (a.card['name'] as String).compareTo(b.card['name'] as String);
    });
    return weighted;
  }

  List<Map<String, dynamic>> _assembleDeck({
    required List<Map<String, dynamic>> originalDeck,
    required RebuildScopeDecision scopeDecision,
    required List<_WeightedCard> weightedCandidates,
    required RebuildTargetProfile targetProfile,
    required Set<String> commanderColorIdentity,
    required String deckFormat,
    required int? bracket,
    required String resolvedArchetype,
    required String resolvedTheme,
    required Set<String> mustKeep,
    required Set<String> mustAvoid,
    required Map<String, Map<String, dynamic>> basicLandCatalog,
  }) {
    final selected = <String, Map<String, dynamic>>{};
    final preserveAllKeep = scopeDecision.selectedScope == 'repair_partial';

    for (final card in scopeDecision.keptCards) {
      final name = (card['name'] as String?)?.trim().toLowerCase() ?? '';
      if (name.isEmpty) continue;
      if (!preserveAllKeep && card['is_commander'] != true) {
        final score = _normalizedRoleForCard(
          card,
          resolvedArchetype: resolvedArchetype,
          resolvedTheme: resolvedTheme,
        );
        final mustPreserve = mustKeep.contains(name);
        final highPriorityLand = score == 'land' &&
            (_landProducesCommanderColor(
                  (card['oracle_text'] as String?) ?? '',
                  commanderColorIdentity,
                ) ||
                _isAnyColorLand((card['oracle_text'] as String?) ?? ''));
        if (!mustPreserve && !highPriorityLand) {
          continue;
        }
      }
      selected[name] = Map<String, dynamic>.from(card);
    }

    final currentCardsForBracket =
        selected.values.map((card) => Map<String, dynamic>.from(card)).toList();
    final candidateCardsOrdered = weightedCandidates.map((item) => item.card).toList();
    final bracketAllowedNames = <String>{};
    if (bracket != null) {
      final decision = applyBracketPolicyToAdditions(
        bracket: bracket,
        currentDeckCards: currentCardsForBracket,
        additionsCardsData: candidateCardsOrdered,
      );
      bracketAllowedNames.addAll(
        decision.allowed.map((name) => name.toLowerCase()),
      );
    } else {
      bracketAllowedNames.addAll(
        candidateCardsOrdered
            .map((card) => (card['name'] as String?)?.toLowerCase() ?? ''),
      );
    }

    final coloredLandCandidates = <_WeightedCard>[];
    final utilityLandCandidates = <_WeightedCard>[];
    final nonLandCandidates = <_WeightedCard>[];
    for (final candidate in weightedCandidates) {
      final lower = ((candidate.card['name'] as String?) ?? '').toLowerCase();
      if (!bracketAllowedNames.contains(lower)) continue;
      if (selected.containsKey(lower)) continue;
      if (_isLandCard(candidate.card)) {
        if (_isUtilityColorlessLandCard(
          candidate.card,
          commanderColorIdentity: commanderColorIdentity,
        )) {
          utilityLandCandidates.add(candidate);
        } else {
          coloredLandCandidates.add(candidate);
        }
      } else {
        nonLandCandidates.add(candidate);
      }
    }

    final maxTotal = targetProfile.totalCards;
    final roleCounts = _countRoles(
      selected.values,
      resolvedArchetype: resolvedArchetype,
      resolvedTheme: resolvedTheme,
    );
    final commanderCount = selected.values
        .where((card) => card['is_commander'] == true)
        .fold<int>(0, (sum, card) => sum + ((card['quantity'] as int?) ?? 1));
    final nonCommanderTarget = maxTotal - commanderCount;
    final nonLandTarget = nonCommanderTarget - targetProfile.landCount;

    for (final candidate in nonLandCandidates) {
      if (_totalCards(selected.values.toList()) >= maxTotal) break;
      final role = candidate.role;
      final shouldAdd = _shouldAddByRole(
        role: role,
        roleCounts: roleCounts,
        targetProfile: targetProfile,
        selectedTotal: _totalNonCommanderNonLand(selected.values.toList()),
        nonLandTarget: nonLandTarget,
      );
      if (!shouldAdd) continue;
      _addCardToSelection(selected, candidate.card);
      _incrementRole(roleCounts, role);
    }

    for (final candidate in nonLandCandidates) {
      if (_totalNonCommanderNonLand(selected.values.toList()) >= nonLandTarget) {
        break;
      }
      final lower = ((candidate.card['name'] as String?) ?? '').toLowerCase();
      if (selected.containsKey(lower)) continue;
      _addCardToSelection(selected, candidate.card);
      _incrementRole(roleCounts, candidate.role);
    }

    final monoColorUtilityLimit =
        _maxUtilityColorlessLands(commanderColorIdentity);
    var utilityLandCount = _countUtilityColorlessLands(
      selected.values.toList(),
      commanderColorIdentity: commanderColorIdentity,
    );

    for (final candidate in coloredLandCandidates) {
      final currentLandCount = roleCounts['land'] ?? 0;
      if (currentLandCount >= targetProfile.landCount) break;
      final lower = ((candidate.card['name'] as String?) ?? '').toLowerCase();
      if (selected.containsKey(lower)) continue;
      _addCardToSelection(selected, candidate.card);
      _incrementRole(roleCounts, 'land');
    }

    for (final candidate in utilityLandCandidates) {
      final currentLandCount = roleCounts['land'] ?? 0;
      if (currentLandCount >= targetProfile.landCount) break;
      final lower = ((candidate.card['name'] as String?) ?? '').toLowerCase();
      if (selected.containsKey(lower)) continue;
      if (utilityLandCount >= monoColorUtilityLimit) continue;
      _addCardToSelection(selected, candidate.card);
      _incrementRole(roleCounts, 'land');
      utilityLandCount += 1;
    }

    _addBasicLandsUntilTarget(
      selected: selected,
      targetLandCount: targetProfile.landCount,
      commanderColorIdentity: commanderColorIdentity,
      basicLandCatalog: basicLandCatalog,
    );

    final remainingCandidates = [
      ...nonLandCandidates,
      ...coloredLandCandidates,
      ...utilityLandCandidates,
    ];
    for (final candidate in remainingCandidates) {
      if (_totalCards(selected.values.toList()) >= maxTotal) break;
      final lower = ((candidate.card['name'] as String?) ?? '').toLowerCase();
      if (selected.containsKey(lower)) continue;
      if (_isLandCard(candidate.card)) {
        final currentLandCount = roleCounts['land'] ?? 0;
        if (currentLandCount >= targetProfile.landCount) continue;
        if (_isUtilityColorlessLandCard(
              candidate.card,
              commanderColorIdentity: commanderColorIdentity,
            ) &&
            utilityLandCount >= monoColorUtilityLimit) {
          continue;
        }
      }
      _addCardToSelection(selected, candidate.card);
      if (_isLandCard(candidate.card)) {
        _incrementRole(roleCounts, 'land');
        if (_isUtilityColorlessLandCard(
          candidate.card,
          commanderColorIdentity: commanderColorIdentity,
        )) {
          utilityLandCount += 1;
        }
      }
    }

    _addBasicLandsUntilDeckComplete(
      selected: selected,
      targetTotal: maxTotal,
      commanderColorIdentity: commanderColorIdentity,
      basicLandCatalog: basicLandCatalog,
    );

    var assembled = selected.values
        .map((card) => Map<String, dynamic>.from(card))
        .toList(growable: true);
    assembled = _rebalanceMonoColorManaBase(
      cards: assembled,
      commanderColorIdentity: commanderColorIdentity,
      basicLandCatalog: basicLandCatalog,
      resolvedTheme: resolvedTheme,
    );
    if (_totalCards(assembled) > maxTotal) {
      assembled = _trimDeckToTarget(
        cards: assembled,
        targetTotal: maxTotal,
        resolvedArchetype: resolvedArchetype,
        resolvedTheme: resolvedTheme,
      );
    }

    assembled.sort((a, b) {
      final commanderA = a['is_commander'] == true ? 0 : 1;
      final commanderB = b['is_commander'] == true ? 0 : 1;
      final byCommander = commanderA.compareTo(commanderB);
      if (byCommander != 0) return byCommander;
      return ((a['name'] as String?) ?? '').compareTo((b['name'] as String?) ?? '');
    });
    return assembled;
  }

  List<Map<String, dynamic>> _rebalanceMonoColorManaBase({
    required List<Map<String, dynamic>> cards,
    required Set<String> commanderColorIdentity,
    required Map<String, Map<String, dynamic>> basicLandCatalog,
    required String resolvedTheme,
  }) {
    if (commanderColorIdentity.length != 1) return cards;

    final mutable = cards.map((card) => Map<String, dynamic>.from(card)).toList();
    final utilityIndexes = <int>[];
    for (var i = 0; i < mutable.length; i++) {
      final card = mutable[i];
      if (_isUtilityColorlessLandCard(
        card,
        commanderColorIdentity: commanderColorIdentity,
      )) {
        utilityIndexes.add(i);
      }
    }

    final maxUtility = _maxUtilityColorlessLands(commanderColorIdentity);
    if (utilityIndexes.length <= maxUtility) return mutable;

    utilityIndexes.sort((a, b) {
      final priorityA = _utilityLandKeepPriority(
        mutable[a],
        resolvedTheme: resolvedTheme,
      );
      final priorityB = _utilityLandKeepPriority(
        mutable[b],
        resolvedTheme: resolvedTheme,
      );
      return priorityA.compareTo(priorityB);
    });

    final replacementsNeeded = utilityIndexes.length - maxUtility;
    for (var i = 0; i < replacementsNeeded; i++) {
      final idx = utilityIndexes[i];
      mutable[idx] = _basicLandCardForColor(
        commanderColorIdentity.first,
        basicLandCatalog,
      );
    }

    return mutable;
  }

  bool _shouldAddByRole({
    required String role,
    required Map<String, int> roleCounts,
    required RebuildTargetProfile targetProfile,
    required int selectedTotal,
    required int nonLandTarget,
  }) {
    if (selectedTotal >= nonLandTarget) return false;
    switch (role) {
      case 'ramp':
        return (roleCounts['ramp'] ?? 0) < targetProfile.ramp;
      case 'draw':
        return (roleCounts['draw'] ?? 0) < targetProfile.drawSelection;
      case 'interaction':
        return (roleCounts['interaction'] ?? 0) < targetProfile.interaction;
      case 'wipe':
        return (roleCounts['wipe'] ?? 0) < targetProfile.wipes;
      case 'payoff':
      case 'engine':
        return ((roleCounts['payoff'] ?? 0) + (roleCounts['engine'] ?? 0)) <
            targetProfile.payoffs;
      case 'wincon':
        return (roleCounts['wincon'] ?? 0) < targetProfile.wincons;
      case 'support':
        return selectedTotal < nonLandTarget;
      default:
        return false;
    }
  }

  Map<String, int> _countRoles(
    Iterable<Map<String, dynamic>> cards, {
    required String resolvedArchetype,
    required String resolvedTheme,
  }) {
    final counts = <String, int>{};
    for (final card in cards) {
      final role = _normalizedRoleForCard(
        card,
        resolvedArchetype: resolvedArchetype,
        resolvedTheme: resolvedTheme,
      );
      counts[role] = (counts[role] ?? 0) + ((card['quantity'] as int?) ?? 1);
    }
    return counts;
  }

  String _normalizedRoleForCard(
    Map<String, dynamic> card, {
    required String resolvedArchetype,
    required String resolvedTheme,
  }) {
    final typeLine = (card['type_line'] as String?)?.toLowerCase() ?? '';
    final oracle = (card['oracle_text'] as String?)?.toLowerCase() ?? '';
    final name = (card['name'] as String?)?.toLowerCase() ?? '';
    final cmc = (card['cmc'] as num?)?.toDouble() ?? 0.0;

    if (typeLine.contains('land')) return 'land';
    if (oracle.contains('destroy all') ||
        oracle.contains('each creature') ||
        oracle.contains('all creatures')) {
      return 'wipe';
    }
    if (oracle.contains('counter target') ||
        oracle.contains('destroy target') ||
        oracle.contains('exile target') ||
        oracle.contains('return target') && oracle.contains('hand')) {
      return 'interaction';
    }
    if (oracle.contains('draw a card') ||
        oracle.contains('draw two cards') ||
        oracle.contains('draw three cards') ||
        oracle.contains('scry') && oracle.contains('draw')) {
      return 'draw';
    }
    if (oracle.contains('add {') ||
        oracle.contains('add one mana') ||
        oracle.contains('search your library for a land') ||
        name.contains('signet') ||
        name.contains('sol ring') ||
        name.contains('talisman')) {
      return 'ramp';
    }
    if (oracle.contains('you win the game') ||
        oracle.contains('each opponent loses') ||
        oracle.contains('combat damage to a player')) {
      return 'wincon';
    }
    if (_isAggroTribalTheme(resolvedTheme) &&
        typeLine.contains('creature') &&
        (name.contains('goblin') ||
            oracle.contains('goblin') ||
            oracle.contains('attacking creature') ||
            oracle.contains('creatures you control get'))) {
      return 'payoff';
    }
    if (resolvedTheme == 'counters' &&
        (oracle.contains('-1/-1 counter') ||
            oracle.contains('proliferate') ||
            oracle.contains('put a counter on') ||
            oracle.contains('remove a counter from'))) {
      return 'payoff';
    }
    if (resolvedArchetype == 'aggro' &&
        typeLine.contains('creature') &&
        cmc <= 3.0) {
      return 'payoff';
    }
    if (resolvedTheme == 'spellslinger' &&
        oracle.contains('instant or sorcery')) {
      return 'payoff';
    }
    if (resolvedTheme == 'artifacts' && oracle.contains('artifact')) {
      return 'payoff';
    }
    if (resolvedTheme == 'enchantments' && oracle.contains('enchantment')) {
      return 'payoff';
    }
    if (oracle.contains('whenever') || oracle.contains('at the beginning of')) {
      return 'engine';
    }
    return 'support';
  }

  int _curveAndThemeAdjustment({
    required Map<String, dynamic> card,
    required String role,
    required String resolvedArchetype,
    required String resolvedTheme,
  }) {
    final typeLine = (card['type_line'] as String?)?.toLowerCase() ?? '';
    final oracle = (card['oracle_text'] as String?)?.toLowerCase() ?? '';
    final name = (card['name'] as String?)?.toLowerCase() ?? '';
    final cmc = (card['cmc'] as num?)?.toDouble() ?? 0.0;

    var delta = 0;

    if (resolvedArchetype == 'aggro' || _isAggroTribalTheme(resolvedTheme)) {
      if (cmc <= 2.0) {
        delta += 18;
      } else if (cmc <= 3.0) {
        delta += 8;
      } else if (cmc >= 5.0) {
        delta -= 24;
      } else if (cmc >= 4.0) {
        delta -= 12;
      }

      if (typeLine.contains('creature')) delta += 10;
      if (role == 'wipe') delta -= 6;
    }

    if (_isAggroTribalTheme(resolvedTheme)) {
      if (name.contains('goblin') || oracle.contains('goblin')) {
        delta += 22;
      }
      if (typeLine.contains('creature')) {
        delta += 8;
      }
    }

    if (resolvedTheme == 'spellslinger') {
      if (typeLine.contains('instant') || typeLine.contains('sorcery')) {
        delta += 10;
      }
      if (cmc >= 5.0) {
        delta -= 10;
      }
    }

    if (resolvedTheme == 'counters') {
      if (oracle.contains('-1/-1 counter') || oracle.contains('proliferate')) {
        delta += 18;
      }
      if (oracle.contains('put a counter on') ||
          oracle.contains('remove a counter from')) {
        delta += 10;
      }
    }

    if (name == 'temple of the false god' &&
        (resolvedTheme == 'spellslinger' ||
            resolvedArchetype == 'control' ||
            resolvedArchetype == 'combo')) {
      delta -= 40;
    }
    if (name == 'terrain generator' && resolvedTheme != 'landfall') {
      delta -= 15;
    }

    return delta;
  }

  bool _isAggroTribalTheme(String resolvedTheme) {
    return resolvedTheme.contains('goblin') ||
        resolvedTheme.contains('tribal') ||
        resolvedTheme == 'aggro';
  }

  bool _landProducesCommanderColor(
    String oracleText,
    Set<String> commanderColorIdentity,
  ) {
    final oracle = oracleText.toLowerCase();
    for (final color in commanderColorIdentity) {
      if (oracle.contains('add {${color.toLowerCase()}}')) return true;
    }
    return false;
  }

  bool _isAnyColorLand(String oracleText) {
    final oracle = oracleText.toLowerCase();
    return oracle.contains('one mana of any color') ||
        oracle.contains('one mana of any type');
  }

  bool _isUtilityColorlessLandCard(
    Map<String, dynamic> card, {
    required Set<String> commanderColorIdentity,
  }) {
    if (!_isLandCard(card)) return false;
    if (card['is_commander'] == true) return false;
    final name = (card['name'] as String?)?.toLowerCase() ?? '';
    if (_isBasicLandCardByName(name)) return false;
    final oracle = (card['oracle_text'] as String?) ?? '';
    return !_landProducesCommanderColor(oracle, commanderColorIdentity) &&
        !_isAnyColorLand(oracle);
  }

  int _countUtilityColorlessLands(
    List<Map<String, dynamic>> cards, {
    required Set<String> commanderColorIdentity,
  }) {
    return cards.fold<int>(0, (sum, card) {
      if (_isUtilityColorlessLandCard(
        card,
        commanderColorIdentity: commanderColorIdentity,
      )) {
        return sum + ((card['quantity'] as int?) ?? 1);
      }
      return sum;
    });
  }

  int _maxUtilityColorlessLands(Set<String> commanderColorIdentity) {
    if (commanderColorIdentity.length <= 1) return 2;
    return 4;
  }

  int _utilityLandKeepPriority(
    Map<String, dynamic> card, {
    required String resolvedTheme,
  }) {
    final name = (card['name'] as String?)?.toLowerCase() ?? '';
    if (name == 'temple of the false god') return 0;
    if (name == 'terrain generator') return 1;
    if (name == 'scavenger grounds') return 2;
    if (name == 'myriad landscape') return resolvedTheme == 'landfall' ? 7 : 3;
    if (name == 'reliquary tower') return 4;
    if (name == 'war room') return 5;
    if (name == 'ancient tomb') return 8;
    return 3;
  }

  bool _basicMatchesCommander(String lower, Set<String> commanderColorIdentity) {
    if (commanderColorIdentity.isEmpty) return false;
    if (commanderColorIdentity.length == 1) {
      final color = commanderColorIdentity.first;
      return (color == 'W' && lower == 'plains') ||
          (color == 'U' && lower == 'island') ||
          (color == 'B' && lower == 'swamp') ||
          (color == 'R' && lower == 'mountain') ||
          (color == 'G' && lower == 'forest');
    }
    return lower == 'plains' ||
        lower == 'island' ||
        lower == 'swamp' ||
        lower == 'mountain' ||
        lower == 'forest';
  }

  bool _isLandCard(Map<String, dynamic> card) {
    final typeLine = (card['type_line'] as String?)?.toLowerCase() ?? '';
    return typeLine.contains('land');
  }

  void _incrementRole(Map<String, int> roleCounts, String role) {
    roleCounts[role] = (roleCounts[role] ?? 0) + 1;
  }

  void _addCardToSelection(
    Map<String, Map<String, dynamic>> selected,
    Map<String, dynamic> card,
  ) {
    final name = (card['name'] as String?)?.trim().toLowerCase() ?? '';
    if (name.isEmpty) return;
    final quantity = (card['quantity'] as int?) ?? 1;
    if (_isBasicLandCardByName(name)) {
      final existing = selected[name];
      if (existing == null) {
        selected[name] = {
          ...Map<String, dynamic>.from(card),
          'quantity': quantity,
          'is_commander': false,
        };
      } else {
        selected[name] = {
          ...existing,
          'quantity': (existing['quantity'] as int? ?? 1) + quantity,
        };
      }
      return;
    }

    selected.putIfAbsent(
      name,
      () => {
        ...Map<String, dynamic>.from(card),
        'quantity': 1,
        'is_commander': card['is_commander'] ?? false,
      },
    );
  }

  void _addBasicLandsUntilTarget({
    required Map<String, Map<String, dynamic>> selected,
    required int targetLandCount,
    required Set<String> commanderColorIdentity,
    required Map<String, Map<String, dynamic>> basicLandCatalog,
  }) {
    final currentLandCount = selected.values.fold<int>(
      0,
      (sum, card) =>
          sum +
          (_isLandCard(card) ? ((card['quantity'] as int?) ?? 1) : 0),
    );
    if (currentLandCount >= targetLandCount) return;
    final missing = targetLandCount - currentLandCount;
    final basics = _buildBasicLandDistribution(
      missing: missing,
      commanderColorIdentity: commanderColorIdentity,
      basicLandCatalog: basicLandCatalog,
    );
    for (final basic in basics) {
      _addCardToSelection(selected, basic);
    }
  }

  void _addBasicLandsUntilDeckComplete({
    required Map<String, Map<String, dynamic>> selected,
    required int targetTotal,
    required Set<String> commanderColorIdentity,
    required Map<String, Map<String, dynamic>> basicLandCatalog,
  }) {
    final currentTotal = _totalCards(selected.values.toList());
    if (currentTotal >= targetTotal) return;
    final basics = _buildBasicLandDistribution(
      missing: targetTotal - currentTotal,
      commanderColorIdentity: commanderColorIdentity,
      basicLandCatalog: basicLandCatalog,
    );
    for (final basic in basics) {
      _addCardToSelection(selected, basic);
    }
  }

  List<Map<String, dynamic>> _buildBasicLandDistribution({
    required int missing,
    required Set<String> commanderColorIdentity,
    required Map<String, Map<String, dynamic>> basicLandCatalog,
  }) {
    if (missing <= 0) return const [];
    final colors = commanderColorIdentity.isEmpty
        ? const ['W', 'U', 'B', 'R', 'G']
        : commanderColorIdentity.toList();
    final basics = <Map<String, dynamic>>[];
    for (var i = 0; i < missing; i++) {
      final color = colors[i % colors.length];
      basics.add(_basicLandCardForColor(color, basicLandCatalog));
    }
    return basics;
  }

  Map<String, dynamic> _basicLandCardForColor(
    String color,
    Map<String, Map<String, dynamic>> basicLandCatalog,
  ) {
    switch (color.toUpperCase()) {
      case 'W':
        return _basicLandCard(
          name: 'Plains',
          oracle: '{T}: Add {W}.',
          basicLandCatalog: basicLandCatalog,
        );
      case 'U':
        return _basicLandCard(
          name: 'Island',
          oracle: '{T}: Add {U}.',
          basicLandCatalog: basicLandCatalog,
        );
      case 'B':
        return _basicLandCard(
          name: 'Swamp',
          oracle: '{T}: Add {B}.',
          basicLandCatalog: basicLandCatalog,
        );
      case 'R':
        return _basicLandCard(
          name: 'Mountain',
          oracle: '{T}: Add {R}.',
          basicLandCatalog: basicLandCatalog,
        );
      case 'G':
        return _basicLandCard(
          name: 'Forest',
          oracle: '{T}: Add {G}.',
          basicLandCatalog: basicLandCatalog,
        );
      default:
        return _basicLandCard(
          name: 'Wastes',
          oracle: '{T}: Add {C}.',
          basicLandCatalog: basicLandCatalog,
        );
    }
  }

  Map<String, dynamic> _basicLandCard({
    required String name,
    required String oracle,
    required Map<String, Map<String, dynamic>> basicLandCatalog,
  }) {
    final cached = basicLandCatalog[name.toLowerCase()];
    if (cached != null) {
      return {
        ...cached,
        'quantity': 1,
        'is_commander': false,
      };
    }
    return {
      'card_id': '',
      'name': name,
      'type_line': 'Basic Land',
      'mana_cost': '',
      'colors': const <String>[],
      'color_identity': const <String>[],
      'cmc': 0.0,
      'oracle_text': oracle,
      'quantity': 1,
      'is_commander': false,
    };
  }

  bool _isBasicLandCardByName(String lower) {
    return lower == 'plains' ||
        lower == 'island' ||
        lower == 'swamp' ||
        lower == 'mountain' ||
        lower == 'forest' ||
        lower == 'wastes';
  }

  int _totalCards(List<Map<String, dynamic>> cards) {
    return cards.fold<int>(
      0,
      (sum, card) => sum + ((card['quantity'] as int?) ?? 1),
    );
  }

  int _totalNonCommanderNonLand(List<Map<String, dynamic>> cards) {
    return cards.fold<int>(0, (sum, card) {
      if (card['is_commander'] == true) return sum;
      if (_isLandCard(card)) return sum;
      return sum + ((card['quantity'] as int?) ?? 1);
    });
  }

  List<Map<String, dynamic>> _trimDeckToTarget({
    required List<Map<String, dynamic>> cards,
    required int targetTotal,
    required String resolvedArchetype,
    required String resolvedTheme,
  }) {
    final mutable = cards.map((card) => Map<String, dynamic>.from(card)).toList();
    mutable.sort((a, b) {
      final commanderA = a['is_commander'] == true ? 0 : 1;
      final commanderB = b['is_commander'] == true ? 0 : 1;
      final byCommander = commanderB.compareTo(commanderA);
      if (byCommander != 0) return byCommander;
      final roleA = _normalizedRoleForCard(
        a,
        resolvedArchetype: resolvedArchetype,
        resolvedTheme: resolvedTheme,
      );
      final roleB = _normalizedRoleForCard(
        b,
        resolvedArchetype: resolvedArchetype,
        resolvedTheme: resolvedTheme,
      );
      final removableA = roleA == 'land' ? 0 : 1;
      final removableB = roleB == 'land' ? 0 : 1;
      final byRole = removableA.compareTo(removableB);
      if (byRole != 0) return byRole;
      return ((a['name'] as String?) ?? '').compareTo((b['name'] as String?) ?? '');
    });

    while (_totalCards(mutable) > targetTotal) {
      final idx = mutable.indexWhere(
        (card) =>
            card['is_commander'] != true &&
            ((card['quantity'] as int?) ?? 1) > 0,
      );
      if (idx == -1) break;
      final quantity = (mutable[idx]['quantity'] as int?) ?? 1;
      if (quantity <= 1) {
        mutable.removeAt(idx);
      } else {
        mutable[idx]['quantity'] = quantity - 1;
      }
    }

    return mutable;
  }

  Future<Map<String, dynamic>?> _loadCommanderReferenceProfileFromCache(
    String commanderName,
  ) async {
    try {
      final result = await _pool.execute(
        Sql.named('''
          SELECT profile_json
          FROM commander_reference_profiles
          WHERE LOWER(commander_name) = LOWER(@commander)
          LIMIT 1
        '''),
        parameters: {'commander': commanderName},
      );
      if (result.isEmpty) return null;
      final payload = result.first[0];
      if (payload is Map<String, dynamic>) return payload;
      if (payload is Map) return payload.cast<String, dynamic>();
      return null;
    } catch (e) {
      Log.w('Falha ao carregar commander_reference_profile para rebuild: $e');
      return null;
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Set<String> _extractIdentity(Map<String, dynamic> card) {
    final colorIdentity =
        (card['color_identity'] as List?)?.cast<String>() ?? const <String>[];
    final colors = (card['colors'] as List?)?.cast<String>() ?? const <String>[];
    final source = colorIdentity.isNotEmpty ? colorIdentity : colors;
    return source.map((c) => c.toUpperCase()).toSet();
  }

  Future<Map<String, Map<String, dynamic>>> _loadBasicLandCatalog() async {
    final basics = await _loadCardsByNames(
      const ['Plains', 'Island', 'Swamp', 'Mountain', 'Forest', 'Wastes'],
    );
    final byName = <String, Map<String, dynamic>>{};
    for (final basic in basics) {
      final name = (basic['name'] as String?)?.toLowerCase() ?? '';
      if (name.isEmpty) continue;
      byName[name] = basic;
    }
    return byName;
  }
}

class _WeightedCard {
  const _WeightedCard({
    required this.card,
    required this.weight,
    required this.role,
  });

  final Map<String, dynamic> card;
  final int weight;
  final String role;
}

class RebuildException implements Exception {
  RebuildException(this.message);
  final String message;

  @override
  String toString() => message;
}
