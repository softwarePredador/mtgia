import '../deck_validation_state_support.dart';

enum BattleDeckAdmissionFailure {
  format,
  validation,
  quantity,
  size,
  commander,
}

BattleDeckAdmissionFailure? battleDeckAdmissionFailure({
  required String format,
  required String validationState,
  required Iterable<Map<String, dynamic>> cards,
}) {
  final failures = battleDeckAdmissionFailures(
    format: format,
    validationState: validationState,
    cards: cards,
  );
  return failures.isEmpty ? null : failures.first;
}

List<BattleDeckAdmissionFailure> battleDeckAdmissionFailures({
  required String format,
  required String validationState,
  required Iterable<Map<String, dynamic>> cards,
}) {
  final failures = <BattleDeckAdmissionFailure>[];
  if (format.trim().toLowerCase() != 'commander') {
    failures.add(BattleDeckAdmissionFailure.format);
  }
  if (normalizeDeckValidationState(validationState) !=
      deckValidationStateValidated) {
    failures.add(BattleDeckAdmissionFailure.validation);
  }

  var cardCount = 0;
  var commanderCount = 0;
  for (final card in cards) {
    final quantity = card['quantity'];
    if (quantity is! int || quantity < 1) {
      failures.add(BattleDeckAdmissionFailure.quantity);
      continue;
    }
    cardCount += quantity;
    if (card['is_commander'] == true) commanderCount += quantity;
  }
  if (cardCount != 100) failures.add(BattleDeckAdmissionFailure.size);
  if (commanderCount != 1) {
    failures.add(BattleDeckAdmissionFailure.commander);
  }
  return List.unmodifiable(failures.toSet());
}
