import '../basic_land_utils.dart';
import '../logger.dart';

void rebuildOptimizeRecommendations(Map<String, dynamic> responseBody) {
  responseBody['recommendations'] = [
    ...((responseBody['removals_detailed'] as List?) ?? const []),
    ...((responseBody['additions_detailed'] as List?) ?? const []),
  ];
}

void balanceOptimizeDetailedPayload({
  required Map<String, dynamic> responseBody,
  required List<String> validAdditions,
  required List<String> validRemovals,
  required Map<String, Map<String, dynamic>> validByNameLower,
  required bool isComplete,
}) {
  rebuildOptimizeRecommendations(responseBody);

  final addDet = (responseBody['additions_detailed'] as List?) ?? [];
  final remDet = (responseBody['removals_detailed'] as List?) ?? [];

  Log.d('Balanceamento final:');
  Log.d('  validAdditions.length = ${validAdditions.length}');
  Log.d('  validRemovals.length = ${validRemovals.length}');
  Log.d('  additions_detailed.length = ${addDet.length}');
  Log.d('  removals_detailed.length = ${remDet.length}');
  Log.d('  mode = ${responseBody['mode']}');

  if (addDet.length != validAdditions.length) {
    Log.w('Algumas adições não foram mapeadas para card_id!');
    for (final name in validAdditions) {
      final v = validByNameLower[name.toLowerCase()];
      if (v == null || v['id'] == null) {
        Log.w('  Carta sem card_id: "$name" (key: "${name.toLowerCase()}")');
      }
    }
  }

  if (isComplete) {
    rebuildOptimizeRecommendations(responseBody);
    return;
  }

  if (addDet.length < remDet.length) {
    final missingDetailed = remDet.length - addDet.length;
    Log.d(
      '  Gap em detailed: faltam $missingDetailed - construindo de validAdditions',
    );

    final existingNames = addDet
        .whereType<Map>()
        .map((e) => e['name']?.toString().toLowerCase() ?? '')
        .toSet();
    final newDetailed = <Map<String, dynamic>>[];
    for (final name in validAdditions) {
      if (existingNames.contains(name.toLowerCase())) continue;
      final v = validByNameLower[name.toLowerCase()];
      if (v != null && v['id'] != null) {
        newDetailed.add({
          'name': v['name'] ?? name,
          'card_id': v['id'],
          'quantity': 1,
        });
        existingNames.add(name.toLowerCase());
      }
    }
    if (newDetailed.isNotEmpty) {
      responseBody['additions_detailed'] = [...addDet, ...newDetailed];
    }

    final finalAddDet = (responseBody['additions_detailed'] as List?) ?? [];
    if (finalAddDet.length < remDet.length) {
      responseBody['removals_detailed'] =
          remDet.take(finalAddDet.length).toList();
      responseBody['removals'] =
          validRemovals.take(finalAddDet.length).toList();
    }
  } else if (addDet.length > remDet.length) {
    Log.d('  Truncando adições extras');
    responseBody['additions_detailed'] = addDet.take(remDet.length).toList();
    responseBody['additions'] = validAdditions.take(remDet.length).toList();
  }

  rebuildOptimizeRecommendations(responseBody);
  final finalAddDet = (responseBody['additions_detailed'] as List?) ?? [];
  final finalRemDet = (responseBody['removals_detailed'] as List?) ?? [];
  Log.d(
    '  Final: additions_detailed=${finalAddDet.length}, removals_detailed=${finalRemDet.length}',
  );
}

void enforceOptimizeFinalPayloadIntegrity({
  required Map<String, dynamic> responseBody,
  required Set<String> deckNamesLower,
  required String deckFormat,
  required bool isComplete,
}) {
  if (isComplete) {
    rebuildOptimizeRecommendations(responseBody);
    return;
  }

  final additionsDetailedFinal =
      (responseBody['additions_detailed'] as List?) ?? [];
  final removalsDetailedFinal =
      (responseBody['removals_detailed'] as List?) ?? [];
  final removalNamesFinal = removalsDetailedFinal
      .whereType<Map>()
      .map((e) => (e['name']?.toString() ?? '').toLowerCase())
      .where((n) => n.isNotEmpty)
      .toSet();

  final filteredAdditions = <dynamic>[];
  final filteredAdditionNames = <String>[];
  final filteredRemovalsToKeep = <dynamic>[];
  final filteredRemovalNames = <String>[];

  for (final add in additionsDetailedFinal) {
    if (add is! Map) continue;
    final name = (add['name']?.toString() ?? '').toLowerCase();
    if (name.isEmpty) continue;

    final isBasic = isBasicLandName(name);
    final alreadyInDeck = deckNamesLower.contains(name);
    final beingRemoved = removalNamesFinal.contains(name);

    if (alreadyInDeck &&
        !beingRemoved &&
        !isBasic &&
        (deckFormat == 'commander' || deckFormat == 'brawl')) {
      Log.w(
        '  Validação final: removendo adição duplicada "$name" (já existe no deck)',
      );
      continue;
    }

    filteredAdditions.add(add);
    filteredAdditionNames.add(add['name']?.toString() ?? name);
  }

  if (filteredAdditions.length < additionsDetailedFinal.length) {
    Log.d(
      '  Validação final: ${additionsDetailedFinal.length - filteredAdditions.length} adições removidas por duplicidade',
    );

    for (var i = 0;
        i < removalsDetailedFinal.length &&
            filteredRemovalsToKeep.length < filteredAdditions.length;
        i++) {
      filteredRemovalsToKeep.add(removalsDetailedFinal[i]);
      final rem = removalsDetailedFinal[i];
      if (rem is Map) {
        filteredRemovalNames.add(rem['name']?.toString() ?? '');
      }
    }

    responseBody['additions_detailed'] = filteredAdditions;
    responseBody['additions'] = filteredAdditionNames;
    responseBody['removals_detailed'] = filteredRemovalsToKeep;
    responseBody['removals'] = filteredRemovalNames;

    Log.d(
      '  Validação final pós-rebalanceamento: ${filteredAdditions.length} adições, ${filteredRemovalsToKeep.length} remoções',
    );
  }

  final finalAdditions = (responseBody['additions_detailed'] as List?) ?? [];
  final finalRemovals = (responseBody['removals_detailed'] as List?) ?? [];
  if (finalAdditions.length != finalRemovals.length) {
    Log.w(
      '  Safety net: additions(${finalAdditions.length}) != removals(${finalRemovals.length}), rebalancing',
    );
    final minLen = finalAdditions.length < finalRemovals.length
        ? finalAdditions.length
        : finalRemovals.length;
    responseBody['additions_detailed'] = finalAdditions.take(minLen).toList();
    responseBody['additions'] =
        ((responseBody['additions'] as List?) ?? []).take(minLen).toList();
    responseBody['removals_detailed'] = finalRemovals.take(minLen).toList();
    responseBody['removals'] =
        ((responseBody['removals'] as List?) ?? []).take(minLen).toList();
  }

  rebuildOptimizeRecommendations(responseBody);
}
