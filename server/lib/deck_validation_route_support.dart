import 'deck_rules_service.dart';

const deckValidationOwnerScopeSql = '''
  SELECT id::text, format
  FROM decks
  WHERE id = @deckId AND user_id = @userId
  LIMIT 1
''';

const deckValidationCardsSql = '''
  SELECT card_id::text, quantity::int, is_commander
  FROM deck_cards
  WHERE deck_id = @deckId
''';

Map<String, dynamic> buildDeckValidationSuccessBody({
  required String deckId,
  required String format,
}) {
  return {
    'ok': true,
    'format': format,
    'deck_id': deckId,
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

Map<String, dynamic> buildDeckValidationRuleErrorBody(DeckRulesException e) {
  return {
    'ok': false,
    'error': e.message,
    if (e.cardName != null) 'card_name': e.cardName,
  };
}

Map<String, dynamic> buildDeckValidationHandlerErrorBody(Object error) {
  return {
    'ok': false,
    'error': error.toString(),
  };
}
