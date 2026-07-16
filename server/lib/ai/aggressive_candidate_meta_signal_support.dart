const aggressiveCandidateMetaSignalSource = 'aggressive_meta_signal_v1';

const aggressiveCandidateTrackedRoles = <String>{
  'ramp',
  'draw',
  'removal',
  'protection',
  'tutor',
  'wincon',
  'combo_piece',
  'wipe',
  'stax',
  'recursion',
  'graveyard',
  'token',
  'engine',
  'payoff',
  'enabler',
};

bool isCommanderCandidateLegalityAllowed(String? status) {
  final normalized = status?.trim().toLowerCase();
  return normalized == null ||
      normalized.isEmpty ||
      normalized == 'legal' ||
      normalized == 'restricted';
}

bool isExternalCommanderCandidateTrusted({
  required String? validationStatus,
  required String? legalStatus,
  required String? subformat,
}) {
  final validation = validationStatus?.trim().toLowerCase();
  final legal = legalStatus?.trim().toLowerCase();
  final scope = subformat?.trim().toLowerCase();
  return scope == 'competitive_commander' &&
      (validation == 'validated' ||
          validation == 'staged' ||
          validation == 'promoted') &&
      (legal == 'legal' || legal == 'valid' || legal == 'warning_reviewed');
}

String confidenceLabel({
  required int evidenceCount,
  required String source,
  int? freshnessDays,
  bool commanderIdentityResolved = true,
}) {
  if (!commanderIdentityResolved || evidenceCount <= 0) return 'not_proven';

  final normalizedSource = source.trim().toLowerCase();
  final sourceBonus =
      normalizedSource.contains('external')
          ? 1
          : normalizedSource.contains('cedh') ||
              normalizedSource.contains('competitive')
          ? 1
          : 0;
  final stalePenalty = freshnessDays != null && freshnessDays > 75 ? 1 : 0;
  final adjustedEvidence = evidenceCount + sourceBonus - stalePenalty;

  if (adjustedEvidence >= 12) return 'high';
  if (adjustedEvidence >= 5) return 'medium_high';
  if (adjustedEvidence >= 3) return 'medium';
  return 'low';
}

int scoreAggressiveMetaSignal({
  required int evidenceCount,
  required int roleScore,
  required double functionConfidence,
  required String subformat,
  required int rejectionPenalty,
  int? freshnessDays,
}) {
  final evidenceBonus = (evidenceCount * 5).clamp(0, 35).toInt();
  final roleComponent = (roleScore * 0.55).round();
  final functionComponent = (functionConfidence * 18).round();
  final subformatBonus =
      subformat.trim().toLowerCase() == 'competitive_commander' ? 8 : 0;
  final freshnessPenalty = freshnessDays != null && freshnessDays > 75 ? 6 : 0;
  final penaltyComponent = (rejectionPenalty / 8).round().clamp(0, 35);

  return (roleComponent +
          functionComponent +
          evidenceBonus +
          subformatBonus -
          freshnessPenalty -
          penaltyComponent)
      .clamp(1, 100)
      .toInt();
}

String bracketScopeForMetaSignal({
  required String subformat,
  required String existingBracketScope,
  required int score,
}) {
  final normalizedSubformat = subformat.trim().toLowerCase();
  final existingMinimum = candidateBracketScopeMinimum(existingBracketScope);
  if (normalizedSubformat == 'competitive_commander' || existingMinimum == 3) {
    return 'bracket_3_plus';
  }
  if (score >= 82 || existingMinimum == 2) {
    return 'bracket_2_plus';
  }
  return 'any';
}

int? candidateBracketScopeMinimum(String bracketScope) {
  return switch (bracketScope.trim().toLowerCase()) {
    'bracket_2_plus' || 'bracket_2_5' || 'bracket_2_4' => 2,
    'bracket_3_plus' || 'bracket_3_5' || 'bracket_3_4' => 3,
    _ => null,
  };
}

bool colorIdentityFits({
  required Set<String> cardIdentity,
  required Set<String> commanderIdentity,
}) {
  if (commanderIdentity.isEmpty) return false;
  return cardIdentity.every(commanderIdentity.contains);
}

String buildMetaSignalEvidence({
  required String source,
  required String subformat,
  required String confidence,
  required int evidenceCount,
  required int deckCount,
  required String freshness,
}) {
  return [
    'source=$source',
    'subformat=$subformat',
    'confidence=$confidence',
    'evidence_count=$evidenceCount',
    'deck_count=$deckCount',
    'freshness=$freshness',
    'forced_swap=false',
  ].join(';');
}

List<Map<String, dynamic>> buildRoleReplacementExamples(
  List<Map<String, dynamic>> rejectedRows,
  List<Map<String, dynamic>> candidateRows, {
  int limit = 12,
}) {
  final candidatesByRole = <String, List<Map<String, dynamic>>>{};
  for (final candidate in candidateRows) {
    final role = candidate['role']?.toString() ?? '';
    if (role.isEmpty) continue;
    candidatesByRole
        .putIfAbsent(role, () => <Map<String, dynamic>>[])
        .add(candidate);
  }

  for (final rows in candidatesByRole.values) {
    rows.sort((a, b) {
      final byScore = ((b['score'] as num?) ?? 0).compareTo(
        (a['score'] as num?) ?? 0,
      );
      if (byScore != 0) return byScore;
      final byEvidence = ((b['evidence_count'] as num?) ?? 0).compareTo(
        (a['evidence_count'] as num?) ?? 0,
      );
      if (byEvidence != 0) return byEvidence;
      return (a['card_name']?.toString() ?? '').compareTo(
        b['card_name']?.toString() ?? '',
      );
    });
  }

  final output = <Map<String, dynamic>>[];
  for (final rejected in rejectedRows) {
    final role = rejected['role']?.toString() ?? '';
    final rejectedKey = _normalizedReplacementKey(
      rejected['card_name']?.toString() ?? '',
    );
    final replacements =
        (candidatesByRole[role] ?? const <Map<String, dynamic>>[]).where(
          (candidate) =>
              _normalizedReplacementKey(
                candidate['card_name']?.toString() ?? '',
              ) !=
              rejectedKey,
        );
    if (replacements.isEmpty) continue;
    final replacement = replacements.first;
    output.add({
      'rejected_card': rejected['card_name'],
      'rejected_reason': rejected['reason'] ?? 'historical_quality_penalty',
      'role': role,
      'replacement_card': replacement['card_name'],
      'replacement_score': replacement['score'],
      'replacement_evidence_count': replacement['evidence_count'],
      'replacement_confidence': replacement['confidence'],
      'logic':
          'same_role_higher_meta_signal_with_legality_and_color_identity_guard',
    });
    if (output.length >= limit) break;
  }
  return output;
}

String _normalizedReplacementKey(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
