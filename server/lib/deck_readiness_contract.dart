import 'deck_validation_state_support.dart';

const deckReadinessSchemaVersion = 'deck_readiness_v1';

Map<String, dynamic> buildDeckReadinessContract({
  required String format,
  required int cardCount,
  required bool hasCommander,
  required bool strictValidationPassed,
  Iterable<String> prerequisiteReviewReasons = const <String>[],
  String? strictValidationError,
}) {
  final normalizedFormat = format.trim().toLowerCase();
  final requiresCommander =
      normalizedFormat == 'commander' || normalizedFormat == 'brawl';
  final reviewReasons =
      normalizeDeckValidationReasons(
        prerequisiteReviewReasons.toList(growable: false),
      ).toList();

  if (requiresCommander && !hasCommander) {
    reviewReasons.add('missing_commander');
  }
  if (!strictValidationPassed) {
    final expectedCount = switch (normalizedFormat) {
      'commander' => 100,
      'brawl' => 60,
      _ => 60,
    };
    final countIsIncomplete =
        requiresCommander
            ? cardCount != expectedCount
            : cardCount < expectedCount;
    if (countIsIncomplete) {
      reviewReasons.add('incomplete_deck_size');
    }
    if (reviewReasons.isEmpty) {
      reviewReasons.add('strict_validation_pending');
    }
  }

  final normalizedReasons = normalizeDeckValidationReasons(reviewReasons);
  final isValidated = strictValidationPassed && normalizedReasons.isEmpty;

  return {
    'schema_version': deckReadinessSchemaVersion,
    'state':
        isValidated ? deckValidationStateValidated : deckValidationStateDraft,
    'strict_validation_passed': strictValidationPassed,
    'requires_review': !isValidated,
    'review_reasons': normalizedReasons,
    if (strictValidationError != null &&
        strictValidationError.trim().isNotEmpty)
      'strict_validation_error': strictValidationError.trim(),
  };
}
