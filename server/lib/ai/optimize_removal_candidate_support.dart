import '../basic_land_utils.dart' as basic_lands;
import '../edh_bracket_policy.dart';
import 'optimize_filler_loader_support.dart';
import 'optimize_functional_role_support.dart';
import 'optimization_ramp_profile.dart';

Map<String, int> _criticalRoleContributions(Map<String, dynamic> card) => {
  for (final role in commanderCriticalFunctionalRoleNames)
    role: countOptimizationFunctionalRole([
      {...card, 'quantity': 1},
    ], role: role),
};

List<Map<String, dynamic>> _selectRemovalCandidatesWithoutBreakingRoleFloors({
  required List<Map<String, dynamic>> candidates,
  required List<Map<String, dynamic>> allCardData,
  required String targetArchetype,
  required int maxCount,
  int? bracket,
}) {
  if (maxCount <= 0 || candidates.isEmpty) return const [];

  final assessment = assessCommanderFunctionalRoleFloors(
    cards: allCardData,
    targetArchetype: targetArchetype,
    bracket: bracket,
  );
  if (!assessment.applies) {
    return candidates.take(maxCount).toList(growable: false);
  }

  final remainingCounts = Map<String, int>.from(assessment.actualCounts);
  final selected = <Map<String, dynamic>>[];
  for (final candidate in candidates) {
    if (selected.length >= maxCount) break;

    final contributions = _criticalRoleContributions(candidate);
    final forcedBracketRepair = candidate['bracket_violation'] == true;
    final wouldBreakFloor =
        !forcedBracketRepair &&
        contributions.entries.any(
          (entry) =>
              entry.value > 0 &&
              (remainingCounts[entry.key] ?? 0) - entry.value <
                  (assessment.minimumCounts[entry.key] ?? 0),
        );
    if (wouldBreakFloor) continue;

    selected.add({...candidate, 'critical_role_contributions': contributions});
    for (final entry in contributions.entries) {
      remainingCounts[entry.key] =
          (remainingCounts[entry.key] ?? 0) - entry.value;
    }
  }
  return selected;
}

List<Map<String, dynamic>> buildDeterministicOptimizeRemovalCandidates({
  required List<Map<String, dynamic>> allCardData,
  required List<String> commanders,
  required Set<String> commanderColorIdentity,
  required String targetArchetype,
  required bool keepTheme,
  required List<String>? coreCards,
  required List<String> commanderPriorityNames,
  int? bracket,
  int swapLimit = 6,
}) {
  final effectiveSwapLimit = swapLimit.clamp(1, 60).toInt();

  List<Map<String, dynamic>> buildCandidates({
    required bool allowCoreTradeoffs,
  }) {
    if (allCardData.isEmpty) return const [];

    final commanderLower =
        commanders.map((name) => name.trim().toLowerCase()).toSet();
    final coreLower =
        (coreCards ?? const <String>[])
            .map((name) => name.trim().toLowerCase())
            .toSet();
    final preferredNames =
        commanderPriorityNames.map((name) => name.toLowerCase()).toSet();
    Map<String, dynamic> anchorMetadata(String lowerName, String role) {
      final reasons = <String>[
        if (coreLower.contains(lowerName)) 'declared_core_card',
        if (preferredNames.contains(lowerName)) 'commander_priority_card',
        if (role == 'engine' || role == 'combo_piece') 'engine_role',
      ];
      return {
        'protected_anchor': reasons.isNotEmpty,
        'anchor_reasons': reasons,
        'anchor_cut_policy': 'same_lane_replacement_or_battle_gate',
      };
    }

    final currentRoleCounts = <String, int>{};
    final roleTargets = buildRoleTargetProfile(targetArchetype);
    final bracketViolationRemovalNames = <String>{};
    if (bracket != null) {
      final assessment = assessDeckAgainstBracketPolicy(
        bracket: bracket,
        cards: allCardData,
      );
      final gameChangerCount =
          assessment.counts[BracketCategory.gameChanger] ?? 0;
      final gameChangerCap =
          assessment.policy.maxCounts[BracketCategory.gameChanger] ?? 0;
      final excess = (gameChangerCount - gameChangerCap).clamp(0, 99);
      if (excess > 0) {
        final removableGameChangers =
            allCardData.where((card) {
              final name = card['name']?.toString().trim() ?? '';
              if (name.isEmpty || commanderLower.contains(name.toLowerCase())) {
                return false;
              }
              return tagCardForBracket(
                name: name,
                typeLine: card['type_line']?.toString() ?? '',
                oracleText: card['oracle_text']?.toString() ?? '',
              ).categories.contains(BracketCategory.gameChanger);
            }).toList();
        removableGameChangers.sort((a, b) {
          int preservationPenalty(Map<String, dynamic> card) {
            final lower = card['name']?.toString().trim().toLowerCase() ?? '';
            return (coreLower.contains(lower) ? 2 : 0) +
                (preferredNames.contains(lower) ? 1 : 0);
          }

          final byPreservation = preservationPenalty(
            a,
          ).compareTo(preservationPenalty(b));
          if (byPreservation != 0) return byPreservation;
          final cmcA = (a['cmc'] as num?)?.toDouble() ?? 0;
          final cmcB = (b['cmc'] as num?)?.toDouble() ?? 0;
          final byCmc = cmcB.compareTo(cmcA);
          if (byCmc != 0) return byCmc;
          return (a['name']?.toString() ?? '').compareTo(
            b['name']?.toString() ?? '',
          );
        });
        bracketViolationRemovalNames.addAll(
          removableGameChangers
              .take(excess)
              .map((card) => card['name']?.toString().toLowerCase() ?? '')
              .where((name) => name.isNotEmpty),
        );
      }
    }
    final structuralRecoveryScenario = isOptimizeStructuralRecoveryScenario(
      allCardData: allCardData,
      commanderColorIdentity: commanderColorIdentity,
    );
    final structuralRecoverySwapTarget =
        computeOptimizeStructuralRecoverySwapTarget(
          allCardData: allCardData,
          commanderColorIdentity: commanderColorIdentity,
          targetArchetype: targetArchetype,
        );
    var landCount = 0;

    for (final card in allCardData) {
      final qty = (card['quantity'] as int?) ?? 1;
      final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
      if (basic_lands.isLandTypeLine(typeLine)) {
        landCount += qty;
        continue;
      }

      final role = inferFunctionalRoleForCard(card);
      if (role == 'ramp' &&
          !optimizationRampProfileForCard(card).countsTowardGenericFloor) {
        continue;
      }
      currentRoleCounts[role] = (currentRoleCounts[role] ?? 0) + qty;
    }

    final removalCandidates = <Map<String, dynamic>>[];
    for (final card in allCardData) {
      final name = ((card['name'] as String?) ?? '').trim();
      if (name.isEmpty) continue;
      final lower = name.toLowerCase();
      if (commanderLower.contains(lower)) continue;

      final isCore = keepTheme && coreLower.contains(lower);
      final resolvesBracketViolation = bracketViolationRemovalNames.contains(
        lower,
      );
      if (isCore && !allowCoreTradeoffs && !resolvesBracketViolation) {
        continue;
      }

      final typeLine = (card['type_line'] as String?) ?? '';
      final isLand = basic_lands.isLandTypeLine(typeLine);
      if (isLand) continue;

      final role = inferFunctionalRoleForCard(card);
      if (resolvesBracketViolation) {
        final cmc = (card['cmc'] as num?)?.toDouble() ?? 0.0;
        removalCandidates.add({
          'name': name,
          'role': role,
          'cmc': cmc,
          'score': 1000000 + (cmc * 10).round(),
          'type_line': typeLine,
          'oracle_text': (card['oracle_text'] as String?) ?? '',
          'bracket_violation': true,
          'bracket': bracket,
          ...anchorMetadata(lower, role),
        });
        continue;
      }
      if (role == 'ramp' &&
          !optimizationRampProfileForCard(card).countsTowardGenericFloor) {
        continue;
      }
      final currentRole = currentRoleCounts[role] ?? 0;
      final targetRole = roleTargets[role] ?? 0;
      final surplus = (currentRole - targetRole).clamp(0, 99);
      if (surplus <= 0) continue;
      final cmc = (card['cmc'] as num?)?.toDouble() ?? 0.0;
      final preferredPenalty = preferredNames.contains(lower) ? 220 : 0;
      final corePenalty = isCore ? 240 : 0;
      final score =
          surplus * 100 + (cmc * 12).round() - preferredPenalty - corePenalty;
      if (score <= 0) continue;

      removalCandidates.add({
        'name': name,
        'role': role,
        'cmc': cmc,
        'score': score,
        'type_line': typeLine,
        'oracle_text': (card['oracle_text'] as String?) ?? '',
        ...anchorMetadata(lower, role),
      });
    }

    final recommendedLandCount = recommendedLandCountForOptimizeArchetype(
      targetArchetype,
    );
    final excessLands = landCount - recommendedLandCount;

    // Avoid cutting lands just because a healthy list is slightly above target.
    if (excessLands >= 4) {
      for (final card in allCardData) {
        final name = ((card['name'] as String?) ?? '').trim();
        if (name.isEmpty) continue;

        final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
        if (!basic_lands.isLandTypeLine(typeLine)) continue;

        final lower = name.toLowerCase();
        final isBasic = basic_lands.isBasicLandName(lower);
        final supportsColors = landProducesCommanderColors(
          card: card,
          commanderColorIdentity: commanderColorIdentity,
        );
        final tappedPenalty =
            (((card['oracle_text'] as String?) ?? '').toLowerCase().contains(
                  'enters the battlefield tapped',
                ))
                ? 20
                : 0;
        final colorlessPenalty =
            supportsColors ? 0 : (commanderColorIdentity.isEmpty ? 0 : 70);
        final basicPenalty = isBasic ? 30 : 0;
        final score =
            excessLands * 100 + colorlessPenalty + basicPenalty + tappedPenalty;
        final copies = ((card['quantity'] as int?) ?? 1).clamp(
          1,
          excessLands.clamp(
            1,
            structuralRecoveryScenario
                ? structuralRecoverySwapTarget
                : effectiveSwapLimit,
          ),
        );

        for (var i = 0; i < copies; i++) {
          removalCandidates.add({
            'name': name,
            'role': 'land',
            'cmc': 0.0,
            'score': score - i,
            'type_line': card['type_line'],
            'oracle_text': (card['oracle_text'] as String?) ?? '',
            ...anchorMetadata(lower, 'land'),
          });
        }
      }
    }

    final nonLandRemovalCount =
        removalCandidates.where((c) => (c['role'] as String?) != 'land').length;
    if (!structuralRecoveryScenario &&
        nonLandRemovalCount < effectiveSwapLimit) {
      final criticalRoles = switch (targetArchetype.trim().toLowerCase()) {
        'aggro' => {'creature', 'ramp', 'removal', 'protection'},
        'control' => {'removal', 'draw', 'wipe', 'ramp', 'protection'},
        'midrange' => {'removal', 'ramp', 'draw'},
        _ => {'removal', 'ramp'},
      };

      final existing =
          removalCandidates
              .map((c) => ((c['name'] as String?) ?? '').trim().toLowerCase())
              .where((n) => n.isNotEmpty)
              .toSet();

      final extra = <Map<String, dynamic>>[];
      for (final card in allCardData) {
        final name = ((card['name'] as String?) ?? '').trim();
        if (name.isEmpty) continue;
        final lower = name.toLowerCase();
        if (existing.contains(lower)) continue;
        if (commanderLower.contains(lower)) continue;

        final isCore = keepTheme && coreLower.contains(lower);
        if (isCore && !allowCoreTradeoffs) continue;

        final typeLine = (card['type_line'] as String?) ?? '';
        if (basic_lands.isLandTypeLine(typeLine)) continue;

        final cmc = (card['cmc'] as num?)?.toDouble() ?? 0.0;
        if (cmc < 6) continue;

        final role = inferFunctionalRoleForCard(card);
        if (criticalRoles.contains(role)) continue;

        final preferredPenalty = preferredNames.contains(lower) ? 220 : 0;
        final corePenalty = isCore ? 240 : 0;
        final score = (cmc * 30).round() - preferredPenalty - corePenalty;
        if (score <= 0) continue;

        extra.add({
          'name': name,
          'role': role,
          'cmc': cmc,
          'score': score,
          'type_line': typeLine,
          'oracle_text': (card['oracle_text'] as String?) ?? '',
          ...anchorMetadata(lower, role),
        });
      }

      extra.sort((a, b) {
        final byScore = (b['score'] as int).compareTo(a['score'] as int);
        if (byScore != 0) return byScore;
        return ((a['name'] as String)).compareTo(b['name'] as String);
      });

      for (final candidate in extra) {
        if (removalCandidates
                .where((c) => (c['role'] as String?) != 'land')
                .length >=
            effectiveSwapLimit) {
          break;
        }
        final lower =
            ((candidate['name'] as String?) ?? '').trim().toLowerCase();
        if (lower.isEmpty || existing.contains(lower)) continue;
        removalCandidates.add(candidate);
        existing.add(lower);
      }
    }

    removalCandidates.sort((a, b) {
      final byScore = (b['score'] as int).compareTo(a['score'] as int);
      if (byScore != 0) return byScore;
      return ((a['name'] as String)).compareTo(b['name'] as String);
    });

    final structuralTakeLimit =
        structuralRecoveryScenario
            ? (structuralRecoverySwapTarget < effectiveSwapLimit
                ? structuralRecoverySwapTarget
                : effectiveSwapLimit)
            : effectiveSwapLimit;
    final takeLimit =
        bracketViolationRemovalNames.length > structuralTakeLimit
            ? bracketViolationRemovalNames.length.clamp(1, effectiveSwapLimit)
            : structuralTakeLimit;
    return _selectRemovalCandidatesWithoutBreakingRoleFloors(
      candidates: removalCandidates
          .where((candidate) => (candidate['score'] as int) > 0)
          .toList(growable: false),
      allCardData: allCardData,
      targetArchetype: targetArchetype,
      bracket: bracket,
      maxCount: takeLimit,
    );
  }

  if (allCardData.isEmpty) return const [];
  final strictCandidates = buildCandidates(allowCoreTradeoffs: false);
  if (!keepTheme || strictCandidates.length >= 3) {
    return strictCandidates;
  }

  final merged = <Map<String, dynamic>>[...strictCandidates];
  final relaxedCandidates = buildCandidates(allowCoreTradeoffs: true);
  final seenNonLandNames =
      strictCandidates
          .where((candidate) => candidate['role'] != 'land')
          .map(
            (candidate) => ((candidate['name'] as String?) ?? '').toLowerCase(),
          )
          .where((name) => name.isNotEmpty)
          .toSet();

  for (final candidate in relaxedCandidates) {
    final role = (candidate['role'] as String?) ?? 'utility';
    final lowerName = ((candidate['name'] as String?) ?? '').toLowerCase();
    final isLand = role == 'land';
    if (!isLand && seenNonLandNames.contains(lowerName)) continue;

    merged.add(candidate);
    if (!isLand && lowerName.isNotEmpty) {
      seenNonLandNames.add(lowerName);
    }
    if (merged.length >= effectiveSwapLimit) break;
  }

  final structuralRecoveryScenario = isOptimizeStructuralRecoveryScenario(
    allCardData: allCardData,
    commanderColorIdentity: commanderColorIdentity,
  );
  final structuralTakeCount =
      structuralRecoveryScenario
          ? computeOptimizeStructuralRecoverySwapTarget(
            allCardData: allCardData,
            commanderColorIdentity: commanderColorIdentity,
            targetArchetype: targetArchetype,
          )
          : effectiveSwapLimit;
  final bracketRepairCount =
      merged
          .where((candidate) => candidate['bracket_violation'] == true)
          .length;
  final baseTakeCount =
      structuralTakeCount < effectiveSwapLimit
          ? structuralTakeCount
          : effectiveSwapLimit;
  final takeCount =
      bracketRepairCount > baseTakeCount
          ? bracketRepairCount.clamp(1, effectiveSwapLimit)
          : baseTakeCount;
  return _selectRemovalCandidatesWithoutBreakingRoleFloors(
    candidates: merged,
    allCardData: allCardData,
    targetArchetype: targetArchetype,
    bracket: bracket,
    maxCount: takeCount,
  );
}
