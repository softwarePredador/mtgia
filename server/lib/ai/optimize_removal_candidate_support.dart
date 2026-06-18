import '../basic_land_utils.dart' as basic_lands;
import 'optimize_filler_loader_support.dart';
import 'optimize_functional_role_support.dart';

List<Map<String, dynamic>> buildDeterministicOptimizeRemovalCandidates({
  required List<Map<String, dynamic>> allCardData,
  required List<String> commanders,
  required Set<String> commanderColorIdentity,
  required String targetArchetype,
  required bool keepTheme,
  required List<String>? coreCards,
  required List<String> commanderPriorityNames,
  int swapLimit = 6,
}) {
  final effectiveSwapLimit = swapLimit.clamp(1, 60).toInt();

  List<Map<String, dynamic>> buildCandidates({
    required bool allowCoreTradeoffs,
  }) {
    if (allCardData.isEmpty) return const [];

    final commanderLower =
        commanders.map((name) => name.trim().toLowerCase()).toSet();
    final coreLower = (coreCards ?? const <String>[])
        .map((name) => name.trim().toLowerCase())
        .toSet();
    final preferredNames =
        commanderPriorityNames.map((name) => name.toLowerCase()).toSet();
    final currentRoleCounts = <String, int>{};
    final roleTargets = buildRoleTargetProfile(targetArchetype);
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
      if (typeLine.contains('land')) {
        landCount += qty;
        continue;
      }

      final role = inferFunctionalRoleForCard(card);
      currentRoleCounts[role] = (currentRoleCounts[role] ?? 0) + qty;
    }

    final removalCandidates = <Map<String, dynamic>>[];
    for (final card in allCardData) {
      final name = ((card['name'] as String?) ?? '').trim();
      if (name.isEmpty) continue;
      final lower = name.toLowerCase();
      if (commanderLower.contains(lower)) continue;

      final isCore = keepTheme && coreLower.contains(lower);
      if (isCore && !allowCoreTradeoffs) continue;

      final typeLine = (card['type_line'] as String?) ?? '';
      final isLand = typeLine.toLowerCase().contains('land');
      if (isLand) continue;

      final role = inferFunctionalRoleForCard(card);
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
      });
    }

    final recommendedLandCount =
        recommendedLandCountForOptimizeArchetype(targetArchetype);
    final excessLands = landCount - recommendedLandCount;

    // Avoid cutting lands just because a healthy list is slightly above target.
    if (excessLands >= 4) {
      for (final card in allCardData) {
        final name = ((card['name'] as String?) ?? '').trim();
        if (name.isEmpty) continue;

        final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
        if (!typeLine.contains('land')) continue;

        final lower = name.toLowerCase();
        final isBasic = basic_lands.isBasicLandName(lower);
        final supportsColors = landProducesCommanderColors(
          card: card,
          commanderColorIdentity: commanderColorIdentity,
        );
        final tappedPenalty = (((card['oracle_text'] as String?) ?? '')
                .toLowerCase()
                .contains('enters the battlefield tapped'))
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

      final existing = removalCandidates
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
        if (typeLine.toLowerCase().contains('land')) continue;

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

    final takeLimit = structuralRecoveryScenario
        ? (structuralRecoverySwapTarget < effectiveSwapLimit
            ? structuralRecoverySwapTarget
            : effectiveSwapLimit)
        : effectiveSwapLimit;
    return removalCandidates
        .where((candidate) => (candidate['score'] as int) > 0)
        .take(takeLimit)
        .toList();
  }

  if (allCardData.isEmpty) return const [];
  final strictCandidates = buildCandidates(allowCoreTradeoffs: false);
  if (!keepTheme || strictCandidates.length >= 3) {
    return strictCandidates;
  }

  final merged = <Map<String, dynamic>>[...strictCandidates];
  final relaxedCandidates = buildCandidates(allowCoreTradeoffs: true);
  final seenNonLandNames = strictCandidates
      .where((candidate) => candidate['role'] != 'land')
      .map((candidate) => ((candidate['name'] as String?) ?? '').toLowerCase())
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
  final structuralTakeCount = structuralRecoveryScenario
      ? computeOptimizeStructuralRecoverySwapTarget(
          allCardData: allCardData,
          commanderColorIdentity: commanderColorIdentity,
          targetArchetype: targetArchetype,
        )
      : effectiveSwapLimit;
  final takeCount = structuralTakeCount < effectiveSwapLimit
      ? structuralTakeCount
      : effectiveSwapLimit;
  return merged.take(takeCount).toList();
}
