const deckImportValidationSchemaVersion = 'deck_import_validation_v1';

Map<String, dynamic> buildDeckImportReviewContract({
  required String format,
  required int cardCount,
  required bool hasCommander,
  required bool strictValidationPassed,
  required List<String> notFoundLines,
  required List<String> warnings,
  String? strictValidationError,
}) {
  final normalizedFormat = format.trim().toLowerCase();
  final requiresCommander =
      normalizedFormat == 'commander' || normalizedFormat == 'brawl';
  final importComplete = notFoundLines.isEmpty && warnings.isEmpty;
  final isValidated = strictValidationPassed && importComplete;
  final reviewReasons = <String>[];

  if (notFoundLines.isNotEmpty) {
    reviewReasons.add('unresolved_import_lines');
  }
  if (warnings.isNotEmpty) {
    reviewReasons.add('import_warnings');
  }
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

  return {
    'schema_version': deckImportValidationSchemaVersion,
    'state': isValidated ? 'validated' : 'draft',
    'strict_validation_passed': strictValidationPassed,
    'import_complete': importComplete,
    'requires_review': !isValidated,
    'review_reasons': reviewReasons,
    if (strictValidationError != null &&
        strictValidationError.trim().isNotEmpty)
      'strict_validation_error': strictValidationError.trim(),
  };
}
