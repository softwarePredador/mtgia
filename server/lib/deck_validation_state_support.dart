import 'dart:convert';

const deckValidationStateUnknown = 'unknown';
const deckValidationStateDraft = 'draft';
const deckValidationStateValidated = 'validated';

const deckValidationReasonNotRecorded = 'validation_not_recorded';
const deckValidationReasonStrictFailed = 'strict_validation_failed';
const deckValidationReasonCardsChanged =
    'deck_cards_changed_since_validation';
const deckValidationReasonFormatChanged =
    'deck_format_changed_since_validation';

String normalizeDeckValidationState(Object? value) {
  final normalized = value?.toString().trim().toLowerCase();
  return switch (normalized) {
    deckValidationStateDraft => deckValidationStateDraft,
    deckValidationStateValidated => deckValidationStateValidated,
    _ => deckValidationStateUnknown,
  };
}

bool deckRequiresReview(Object? state) =>
    normalizeDeckValidationState(state) != deckValidationStateValidated;

List<String> normalizeDeckValidationReasons(Object? value) {
  Object? decoded = value;
  if (value is String) {
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      decoded = const <Object?>[];
    }
  }

  if (decoded is! List) return const <String>[];
  final reasons = <String>[];
  for (final entry in decoded) {
    final reason = entry?.toString().trim() ?? '';
    if (reason.isNotEmpty && !reasons.contains(reason)) {
      reasons.add(reason);
    }
  }
  return List<String>.unmodifiable(reasons);
}

String encodeDeckValidationReasons(Iterable<String> reasons) =>
    jsonEncode(normalizeDeckValidationReasons(reasons.toList(growable: false)));

String? deckValidationTimestampToJson(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  return DateTime.tryParse(value.toString())?.toIso8601String();
}

Map<String, dynamic> exposeDeckValidationState(Map<String, dynamic> deck) {
  final state = normalizeDeckValidationState(
    deck['validation_state'] ?? deck['deck_state'],
  );
  final reasons = normalizeDeckValidationReasons(
    deck['validation_reasons'] ?? deck['review_reasons'],
  ).toList(growable: true);
  if (state == deckValidationStateUnknown && reasons.isEmpty) {
    reasons.add(deckValidationReasonNotRecorded);
  }
  deck
    ..remove('validation_state')
    ..remove('validation_reasons')
    ..['deck_state'] = state
    ..['requires_review'] = deckRequiresReview(state)
    ..['review_reasons'] = List<String>.unmodifiable(reasons)
    ..['validation_updated_at'] = deckValidationTimestampToJson(
      deck['validation_updated_at'],
    );
  return deck;
}
