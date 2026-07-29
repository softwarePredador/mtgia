import 'basic_land_utils.dart' as basic_lands;

/// Strategic safety floor used by optimization flows for 100-card Commander.
///
/// This is intentionally separate from format legality: a Commander deck can
/// be rules-legal with fewer lands, but an optimization preview must not be
/// allowed to persist a structurally unusable mana base. The app's 33-38 band
/// remains advisory; automated mutation uses the more conservative 34-card
/// floor.
const commanderStrategicMinimumLandCount = 34;
const commanderStrategicMaximumAutomaticLandFloor = 42;
const brawlStrategicMinimumLandCount = 24;
const brawlStrategicMaximumAutomaticLandFloor = 30;
const optimizationManaFoundationContractVersion =
    'optimization_mana_foundation_v1_2026-07-28';

class CommanderManaFloorAssessment {
  const CommanderManaFloorAssessment({
    required this.applies,
    required this.landCount,
    required this.minimumLandCount,
    required this.severeExcessLandCount,
    required this.totalCardCount,
  });

  final bool applies;
  final int landCount;
  final int minimumLandCount;
  final int severeExcessLandCount;
  final int totalCardCount;

  bool get meetsMinimum => !applies || landCount >= minimumLandCount;
  bool get hasSevereExcess => applies && landCount >= severeExcessLandCount;
  bool get satisfied => meetsMinimum && !hasSevereExcess;

  Map<String, dynamic> toQualityError({
    required String code,
    required String message,
  }) {
    return {
      'code': code,
      'message': message,
      'land_count': landCount,
      'minimum_land_count': minimumLandCount,
      'severe_excess_land_count': severeExcessLandCount,
      'total_card_count': totalCardCount,
      'reasons': [
        if (!meetsMinimum)
          'A base de mana tem $landCount terrenos e precisa de pelo menos '
              '$minimumLandCount para aplicação automática.',
        if (hasSevereExcess)
          'A base de mana tem $landCount terrenos, atingindo o limite '
              'estrutural de $severeExcessLandCount que exige rebuild.',
      ],
    };
  }
}

class OptimizationProfileLandPolicy {
  const OptimizationProfileLandPolicy({
    required this.targetLandCount,
    required this.minimumLandCount,
  });

  final int targetLandCount;
  final int minimumLandCount;
}

bool commanderManaFloorApplies(String format) {
  return strategicMinimumLandCountForFormat(format) != null;
}

int? strategicMinimumLandCountForFormat(String format) {
  return switch (format.trim().toLowerCase()) {
    'commander' || 'edh' => commanderStrategicMinimumLandCount,
    'brawl' => brawlStrategicMinimumLandCount,
    _ => null,
  };
}

int strategicMaximumAutomaticLandFloorForFormat(String format) {
  return switch (format.trim().toLowerCase()) {
    'brawl' => brawlStrategicMaximumAutomaticLandFloor,
    _ => commanderStrategicMaximumAutomaticLandFloor,
  };
}

int strategicTargetLandCountForFormat(String format) {
  return switch (format.trim().toLowerCase()) {
    'brawl' => 25,
    _ => 36,
  };
}

int strategicSevereExcessLandCountForFormat(String format) {
  return switch (format.trim().toLowerCase()) {
    'brawl' => 36,
    _ => 55,
  };
}

int strategicMinimumNonLandCountForFormat(String format) {
  return switch (format.trim().toLowerCase()) {
    'brawl' => 20,
    _ => 25,
  };
}

int dominantColorSourceFloorForFormat(String format) {
  return switch (format.trim().toLowerCase()) {
    'brawl' => 9,
    _ => 15,
  };
}

int secondaryColorSourceFloorForFormat(String format) {
  return switch (format.trim().toLowerCase()) {
    'brawl' => 6,
    _ => 10,
  };
}

String manaFoundationFormatLabel(String format) {
  return switch (format.trim().toLowerCase()) {
    'brawl' => 'Brawl',
    _ => 'Commander',
  };
}

OptimizationProfileLandPolicy? resolveOptimizationProfileLandPolicy({
  required String format,
  Map<String, dynamic>? recommendedStructure,
  Map<String, dynamic>? roleTargets,
}) {
  final roleLandValue = roleTargets?['lands'] ?? roleTargets?['land'];
  final structureLandValue = recommendedStructure?['lands'];
  final rawTarget =
      _readLandPolicyTarget(structureLandValue) ??
      _readLandPolicyTarget(roleLandValue);
  final rawMinimum = _readLandPolicyMinimum(roleLandValue);
  if (rawTarget == null && rawMinimum == null) return null;

  final formatMinimum =
      strategicMinimumLandCountForFormat(format) ??
      commanderStrategicMinimumLandCount;
  final formatMaximum = strategicMaximumAutomaticLandFloorForFormat(format);
  final minimum = (rawMinimum ?? formatMinimum).clamp(
    formatMinimum,
    formatMaximum,
  );
  final target = (rawTarget ?? rawMinimum ?? minimum).clamp(
    minimum,
    formatMaximum,
  );
  return OptimizationProfileLandPolicy(
    targetLandCount: target,
    minimumLandCount: minimum,
  );
}

Map<String, dynamic> buildOptimizationManaFoundationContract({
  required String format,
  int? minimumLandCount,
  int? landCount,
  bool? satisfied,
}) {
  final formatMinimum =
      strategicMinimumLandCountForFormat(format) ??
      commanderStrategicMinimumLandCount;
  final safeMinimum = (minimumLandCount ?? formatMinimum).clamp(
    formatMinimum,
    strategicMaximumAutomaticLandFloorForFormat(format),
  );
  return {
    'schema_version': optimizationManaFoundationContractVersion,
    'policy': 'automatic_apply_floor',
    'minimum_land_count': safeMinimum,
    'severe_excess_land_count': strategicSevereExcessLandCountForFormat(format),
    if (landCount != null) 'land_count': landCount,
    if (satisfied != null) 'satisfied': satisfied,
  };
}

int resolveOptimizationMinimumLandCountFromMutationContext(
  Map<String, dynamic> mutationContext, {
  required String format,
}) {
  final optimizationContract = _asStringMap(
    mutationContext['optimization_contract'],
  );
  final manaFoundation = _asStringMap(optimizationContract['mana_foundation']);
  final consistencySlo = _asStringMap(mutationContext['consistency_slo']);
  final candidates = [
    manaFoundation['minimum_land_count'],
    consistencySlo['minimum_land_count'],
    mutationContext['minimum_land_count'],
  ];
  final formatMinimum =
      strategicMinimumLandCountForFormat(format) ??
      commanderStrategicMinimumLandCount;
  final formatMaximum = strategicMaximumAutomaticLandFloorForFormat(format);

  for (final candidate in candidates) {
    final parsed = switch (candidate) {
      num() => candidate.toInt(),
      String() => int.tryParse(candidate.trim()),
      _ => null,
    };
    if (parsed == null) continue;
    return parsed.clamp(formatMinimum, formatMaximum);
  }
  return formatMinimum;
}

CommanderManaFloorAssessment assessCommanderManaFloor({
  required String format,
  required Iterable<Map<String, dynamic>> cards,
  int? minimumLandCount,
}) {
  final formatMinimum = strategicMinimumLandCountForFormat(format);
  final applies = formatMinimum != null;
  final safeMinimum =
      applies
          ? (minimumLandCount ?? formatMinimum).clamp(
            formatMinimum,
            strategicMaximumAutomaticLandFloorForFormat(format),
          )
          : minimumLandCount ?? 0;
  var landCount = 0;
  var totalCardCount = 0;

  for (final card in cards) {
    final rawQuantity = card['quantity'];
    final parsedQuantity =
        rawQuantity is num
            ? rawQuantity.toInt()
            : int.tryParse(rawQuantity?.toString() ?? '');
    final quantity =
        parsedQuantity != null && parsedQuantity > 0 ? parsedQuantity : 1;
    totalCardCount += quantity;
    if (basic_lands.isLandTypeLine(card['type_line']?.toString() ?? '')) {
      landCount += quantity;
    }
  }

  return CommanderManaFloorAssessment(
    applies: applies,
    landCount: landCount,
    minimumLandCount: safeMinimum,
    severeExcessLandCount: strategicSevereExcessLandCountForFormat(format),
    totalCardCount: totalCardCount,
  );
}

Map<String, dynamic> _asStringMap(Object? value) {
  if (value is! Map) return const <String, dynamic>{};
  return value.map((key, entry) => MapEntry(key.toString(), entry));
}

int? _readLandPolicyTarget(Object? value) {
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  if (value is! Map) return null;

  for (final key in const ['target', 'recommended', 'ideal', 'min', 'max']) {
    final parsed = _readLandPolicyInteger(value[key]);
    if (parsed != null) return parsed;
  }
  return null;
}

int? _readLandPolicyMinimum(Object? value) {
  if (value is num || value is String) return _readLandPolicyInteger(value);
  if (value is! Map) return null;
  return _readLandPolicyInteger(value['min']);
}

int? _readLandPolicyInteger(Object? value) {
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
