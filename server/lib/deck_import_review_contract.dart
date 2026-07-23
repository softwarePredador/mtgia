import 'deck_readiness_contract.dart';

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
  final importComplete = notFoundLines.isEmpty && warnings.isEmpty;
  final prerequisiteReasons = <String>[];

  if (notFoundLines.isNotEmpty) {
    prerequisiteReasons.add('unresolved_import_lines');
  }
  if (warnings.isNotEmpty) {
    prerequisiteReasons.add('import_warnings');
  }

  final readiness = buildDeckReadinessContract(
    format: format,
    cardCount: cardCount,
    hasCommander: hasCommander,
    strictValidationPassed: strictValidationPassed,
    prerequisiteReviewReasons: prerequisiteReasons,
    strictValidationError: strictValidationError,
  );

  return {
    ...readiness,
    'schema_version': deckImportValidationSchemaVersion,
    'import_complete': importComplete,
  };
}
