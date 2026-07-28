import 'basic_land_utils.dart' as basic_lands;

/// Strategic safety floor used by optimization flows for 100-card Commander.
///
/// This is intentionally separate from format legality: a Commander deck can
/// be rules-legal with fewer lands, but an optimization preview must not be
/// allowed to persist a structurally unusable mana base. The app's 33-38 band
/// remains advisory; automated mutation uses the more conservative 34-card
/// floor.
const commanderStrategicMinimumLandCount = 34;

class CommanderManaFloorAssessment {
  const CommanderManaFloorAssessment({
    required this.applies,
    required this.landCount,
    required this.minimumLandCount,
    required this.totalCardCount,
  });

  final bool applies;
  final int landCount;
  final int minimumLandCount;
  final int totalCardCount;

  bool get satisfied => !applies || landCount >= minimumLandCount;

  Map<String, dynamic> toQualityError({
    required String code,
    required String message,
  }) {
    return {
      'code': code,
      'message': message,
      'land_count': landCount,
      'minimum_land_count': minimumLandCount,
      'total_card_count': totalCardCount,
      'reasons': [
        'A base de mana tem $landCount terrenos e precisa de pelo menos '
            '$minimumLandCount para aplicação automática.',
      ],
    };
  }
}

bool commanderManaFloorApplies(String format) {
  final normalized = format.trim().toLowerCase();
  return normalized == 'commander' || normalized == 'edh';
}

CommanderManaFloorAssessment assessCommanderManaFloor({
  required String format,
  required Iterable<Map<String, dynamic>> cards,
  int minimumLandCount = commanderStrategicMinimumLandCount,
}) {
  final safeMinimum =
      minimumLandCount < commanderStrategicMinimumLandCount
          ? commanderStrategicMinimumLandCount
          : minimumLandCount;
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
    applies: commanderManaFloorApplies(format),
    landCount: landCount,
    minimumLandCount: safeMinimum,
    totalCardCount: totalCardCount,
  );
}
