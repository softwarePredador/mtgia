import '../logger.dart';
import '../ml_knowledge_service.dart';

class OptimizeMlFeedback {
  const OptimizeMlFeedback({
    required this.deckId,
    required this.userId,
    required this.archetype,
    required this.commanderName,
    required this.cardsAccepted,
    required this.cardsRejected,
    required this.effectivenessScore,
    required this.userComment,
  });

  final String? deckId;
  final String? userId;
  final String archetype;
  final String? commanderName;
  final List<String> cardsAccepted;
  final List<String> cardsRejected;
  final int effectivenessScore;
  final String userComment;

  bool get shouldRecord =>
      deckId != null &&
      deckId!.trim().isNotEmpty &&
      userId != null &&
      userId!.trim().isNotEmpty &&
      archetype.trim().isNotEmpty;
}

OptimizeMlFeedback buildOptimizeMlFeedback({
  required String? deckId,
  required String? userId,
  required String archetype,
  required String? commanderName,
  required String operationMode,
  required String outcomeCode,
  required int statusCode,
  required List<String> removals,
  required List<String> additions,
  Map<String, dynamic>? qualityError,
  List<String> validationWarnings = const [],
  List<String> blockedByColorIdentity = const [],
  List<Map<String, dynamic>> blockedByBracket = const [],
}) {
  final acceptedCards = statusCode >= 200 && statusCode < 300
      ? _dedupeCardNames(additions)
      : const <String>[];
  final rejectedCards = _buildRejectedCards(
    statusCode: statusCode,
    removals: removals,
    additions: additions,
    blockedByColorIdentity: blockedByColorIdentity,
    blockedByBracket: blockedByBracket,
  );
  final score = _scoreOptimizeOutcome(
    statusCode: statusCode,
    operationMode: operationMode,
    outcomeCode: outcomeCode,
    removals: removals,
    additions: additions,
    validationWarnings: validationWarnings,
    blockedByColorIdentity: blockedByColorIdentity,
    blockedByBracket: blockedByBracket,
  );
  final qualityCode = qualityError?['code']?.toString();

  return OptimizeMlFeedback(
    deckId: deckId,
    userId: userId,
    archetype: archetype,
    commanderName: commanderName,
    cardsAccepted: acceptedCards,
    cardsRejected: rejectedCards,
    effectivenessScore: score,
    userComment: [
      'auto_feedback',
      'status=$statusCode',
      'outcome=$outcomeCode',
      'mode=$operationMode',
      'score=$score',
      'quality=${qualityCode?.isNotEmpty == true ? qualityCode : 'none'}',
      'removals=${removals.length}',
      'additions=${additions.length}',
      'warnings=${validationWarnings.length}',
      'blocked_color=${blockedByColorIdentity.length}',
      'blocked_bracket=${blockedByBracket.length}',
    ].join(' '),
  );
}

Future<void> recordOptimizeMlFeedback({
  required dynamic connection,
  required OptimizeMlFeedback feedback,
}) async {
  if (!feedback.shouldRecord) return;

  try {
    await MLKnowledgeService(connection).recordFeedback(
      deckId: feedback.deckId,
      userId: feedback.userId,
      archetype: feedback.archetype,
      commanderName: feedback.commanderName,
      cardsAccepted: feedback.cardsAccepted,
      cardsRejected: feedback.cardsRejected,
      effectivenessScore: feedback.effectivenessScore,
      userComment: feedback.userComment,
    );
  } catch (e) {
    Log.w('Falha ao registrar feedback ML do optimize: $e');
  }
}

List<String> _buildRejectedCards({
  required int statusCode,
  required List<String> removals,
  required List<String> additions,
  required List<String> blockedByColorIdentity,
  required List<Map<String, dynamic>> blockedByBracket,
}) {
  final rejected = <String>[
    if (statusCode >= 400) ...removals,
    if (statusCode >= 400) ...additions,
    ...blockedByColorIdentity,
    ...blockedByBracket
        .map((entry) => entry['name']?.toString() ?? '')
        .where((name) => name.trim().isNotEmpty),
  ];
  return _dedupeCardNames(rejected).take(40).toList(growable: false);
}

int _scoreOptimizeOutcome({
  required int statusCode,
  required String operationMode,
  required String outcomeCode,
  required List<String> removals,
  required List<String> additions,
  required List<String> validationWarnings,
  required List<String> blockedByColorIdentity,
  required List<Map<String, dynamic>> blockedByBracket,
}) {
  if (statusCode >= 500) return 1;
  if (statusCode >= 400) return 2;
  if (operationMode == 'rebuild_guided' || outcomeCode == 'rebuild_guided') {
    return 3;
  }
  if (removals.isEmpty && additions.isEmpty) return 3;
  if (validationWarnings.isNotEmpty ||
      blockedByColorIdentity.isNotEmpty ||
      blockedByBracket.isNotEmpty) {
    return 4;
  }
  return 5;
}

List<String> _dedupeCardNames(Iterable<String> names) {
  final seen = <String>{};
  final result = <String>[];
  for (final raw in names) {
    final name = raw.trim();
    if (name.isEmpty) continue;
    if (!seen.add(name.toLowerCase())) continue;
    result.add(name);
  }
  return result;
}
