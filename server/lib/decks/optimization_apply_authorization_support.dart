import '../ai/optimize_swap_integrity.dart';

class OptimizationApplyAuthorizationViolation implements Exception {
  const OptimizationApplyAuthorizationViolation(this.code);

  final String code;

  Map<String, dynamic> get responseBody => {
    'error_code': 'optimization_apply_not_authorized',
    'error':
        'A aplicação não corresponde ao preview seguro mais recente. '
        'Atualize a análise e tente novamente.',
    'authorization_error': code,
    'can_apply': false,
  };

  @override
  String toString() => 'OptimizationApplyAuthorizationViolation($code)';
}

OptimizeApplyAuthorizationVerification? validateOptimizationApplyAuthorization({
  required String deckId,
  required String currentDeckSignature,
  required List<Map<String, dynamic>> beforeCards,
  required List<Map<String, dynamic>> afterCards,
  required Map<String, dynamic> mutationContext,
  int? expectedBracket,
  Map<String, String>? environment,
  DateTime? now,
}) {
  final signingSecret = resolveOptimizeApplySigningSecret(
    environment: environment,
  );
  if (signingSecret.isEmpty) {
    throw const OptimizationApplyAuthorizationViolation(
      'signing_secret_unavailable',
    );
  }

  final authorization =
      mutationContext['apply_authorization'] is Map
          ? (mutationContext['apply_authorization'] as Map)
              .cast<String, dynamic>()
          : const <String, dynamic>{};
  final token = authorization['token']?.toString().trim() ?? '';
  if (token.isEmpty) {
    throw const OptimizationApplyAuthorizationViolation(
      'authorization_required',
    );
  }

  final actualRemovals = buildOptimizationCardDelta(
    beforeCards: beforeCards,
    afterCards: afterCards,
    additions: false,
  );
  final actualAdditions = buildOptimizationCardDelta(
    beforeCards: beforeCards,
    afterCards: afterCards,
    additions: true,
  );
  final verification = verifyOptimizeApplyAuthorization(
    signingSecret: signingSecret,
    token: token,
    deckId: deckId,
    deckSignature: currentDeckSignature,
    actualRemovals: actualRemovals,
    actualAdditions: actualAdditions,
    expectedBracket: expectedBracket,
    now: now,
  );
  if (!verification.valid) {
    throw OptimizationApplyAuthorizationViolation(verification.code);
  }
  final metadataViolation = _findUnauthorizedMetadataChange(
    beforeCards: beforeCards,
    afterCards: afterCards,
  );
  if (metadataViolation != null) {
    throw OptimizationApplyAuthorizationViolation(metadataViolation);
  }
  final authorizedBracket = optimizationApplyAuthorizedBracket(verification);
  if (authorizedBracket != null) {
    final contextBracket = _readBracket(mutationContext['bracket']);
    if (contextBracket == null) {
      throw const OptimizationApplyAuthorizationViolation(
        'context_bracket_required',
      );
    }
    if (contextBracket != authorizedBracket) {
      throw const OptimizationApplyAuthorizationViolation(
        'context_bracket_binding_mismatch',
      );
    }
  }
  return verification;
}

int? optimizationApplyAuthorizedBracket(
  OptimizeApplyAuthorizationVerification? verification,
) {
  if (verification == null || !verification.valid) return null;
  return _readBracket(verification.payload['bracket']);
}

String? _findUnauthorizedMetadataChange({
  required Iterable<Map<String, dynamic>> beforeCards,
  required Iterable<Map<String, dynamic>> afterCards,
}) {
  final beforeById = <String, Map<String, dynamic>>{
    for (final card in beforeCards)
      if (_cardId(card).isNotEmpty) _cardId(card): card,
  };

  for (final after in afterCards) {
    final cardId = _cardId(after);
    if (cardId.isEmpty) continue;
    final before = beforeById[cardId];
    final afterIsCommander = after['is_commander'] == true;
    final afterCondition = _condition(after['condition']);

    if (before == null) {
      if (afterIsCommander) return 'commander_addition_not_authorized';
      if (afterCondition != 'NM') return 'addition_condition_not_authorized';
      continue;
    }
    if ((before['is_commander'] == true) != afterIsCommander) {
      return 'commander_role_change_not_authorized';
    }
    if (_condition(before['condition']) != afterCondition) {
      return 'condition_change_not_authorized';
    }
  }
  return null;
}

String _cardId(Map<String, dynamic> card) =>
    card['card_id']?.toString().trim().toLowerCase() ?? '';

String _condition(Object? raw) {
  final value = raw?.toString().trim().toUpperCase() ?? '';
  return value.isEmpty ? 'NM' : value;
}

int? _readBracket(Object? raw) {
  final value = switch (raw) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value.trim()),
    _ => null,
  };
  if (value == null || value < 1 || value > 5) return null;
  return value;
}
