import 'dart:convert';

const deckValidationStateUnknown = 'unknown';
const deckValidationStateDraft = 'draft';
const deckValidationStateValidated = 'validated';

const deckValidationReasonNotRecorded = 'validation_not_recorded';
const deckValidationReasonStrictFailed = 'strict_validation_failed';

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

Map<String, dynamic> exposeDeckValidationState(Map<String, dynamic> deck) {
  final state = normalizeDeckValidationState(
    deck['validation_state'] ?? deck['deck_state'],
  );
  final reasons = normalizeDeckValidationReasons(
    deck['validation_reasons'] ?? deck['review_reasons'],
  );
  deck
    ..remove('validation_state')
    ..remove('validation_reasons')
    ..['deck_state'] = state
    ..['requires_review'] = deckRequiresReview(state)
    ..['review_reasons'] = reasons;
  return deck;
}
