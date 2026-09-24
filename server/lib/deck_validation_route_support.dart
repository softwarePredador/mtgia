import 'deck_rules_service.dart';
import 'deck_validation_state_support.dart';

const deckValidationOwnerScopeSql = '''
  SELECT id::text, format, validation_reasons
  FROM decks
  WHERE id = @deckId AND user_id = @userId
  LIMIT 1
  FOR UPDATE
''';

const deckValidationCardsSql = '''
  SELECT card_id::text, quantity::int, is_commander
  FROM deck_cards
  WHERE deck_id = @deckId
''';

const deckValidationMarkSuccessSql = '''
  UPDATE decks
  SET validation_state = 'validated',
      validation_reasons = '[]'::jsonb,
      validation_updated_at = CURRENT_TIMESTAMP
  WHERE id = @deckId AND user_id = @userId
  RETURNING validation_state, validation_reasons, validation_updated_at
''';

/// Recusa estrita: os motivos que o deck já tinha, mais
/// `strict_validation_failed` e o motivo específico da recusa (ex.:
/// `legality_unknown`, D-28), calculados por
/// [deckValidationFailureReasons].
const deckValidationMarkFailureSql = '''
  UPDATE decks
  SET validation_state = 'draft',
      validation_reasons = CAST(@reasons AS jsonb),
      validation_updated_at = CURRENT_TIMESTAMP
  WHERE id = @deckId AND user_id = @userId
  RETURNING validation_state, validation_reasons, validation_updated_at
''';

/// Os motivos persistidos numa recusa estrita.
List<String> deckValidationFailureReasons(
  Object? persistedReasons,
  DeckRulesException error,
) {
  final reasons = normalizeDeckValidationReasons(
    persistedReasons,
  ).toList(growable: true);
  for (final reason in [deckValidationReasonStrictFailed, error.reason]) {
    if (reason != null && reason.isNotEmpty && !reasons.contains(reason)) {
      reasons.add(reason);
    }
  }
  return List<String>.unmodifiable(reasons);
}

Map<String, dynamic> buildDeckValidationSuccessBody({
  required String deckId,
  required String format,
  required Object? validationUpdatedAt,
}) {
  return {
    'ok': true,
    'format': format,
    'deck_id': deckId,
    'deck_state': 'validated',
    'requires_review': false,
    'review_reasons': const <String>[],
    'validation_updated_at': deckValidationTimestampToJson(validationUpdatedAt),
  };
}

Map<String, dynamic> buildDeckValidationNotFoundBody() {
  return {
    'ok': false,
    'error': 'Deck not found or permission denied.',
    'error_code': 'deck_not_found',
  };
}

bool isDeckValidationNotFoundBody(Map<String, dynamic> body) {
  return body['ok'] == false && body['error_code'] == 'deck_not_found';
}

Map<String, dynamic> buildDeckValidationRuleErrorBody(
  DeckRulesException e, {
  required Object? persistedReasons,
  required Object? validationUpdatedAt,
}) {
  final reasons = normalizeDeckValidationReasons(
    persistedReasons,
  ).toList(growable: true);
  if (!reasons.contains(deckValidationReasonStrictFailed)) {
    reasons.add(deckValidationReasonStrictFailed);
  }
  return {
    'ok': false,
    'error': e.message,
    'deck_state': 'draft',
    'requires_review': true,
    'review_reasons': List<String>.unmodifiable(reasons),
    'validation_updated_at': deckValidationTimestampToJson(validationUpdatedAt),
    if (e.cardName != null) 'card_name': e.cardName,
  };
}

Map<String, dynamic> buildDeckValidationHandlerErrorBody(Object _) {
  return const {
    'ok': false,
    'error': 'Unable to validate deck right now.',
    'error_code': 'deck_validation_internal_error',
  };
}
