import '../logger.dart';
import 'optimization_validator.dart';

typedef OptimizeValidationRunner = Future<ValidationReport> Function({
  required List<Map<String, dynamic>> originalDeck,
  required List<Map<String, dynamic>> optimizedDeck,
  required List<String> removals,
  required List<String> additions,
  required List<String> commanders,
  required String archetype,
});

class OptimizeRouteValidationResult {
  final ValidationReport validationReport;
  final Map<String, dynamic> postAnalysis;
  final List<String> validationWarnings;

  const OptimizeRouteValidationResult({
    required this.validationReport,
    required this.postAnalysis,
    required this.validationWarnings,
  });
}

Future<OptimizeRouteValidationResult> runOptimizeRouteValidation({
  required OptimizeValidationRunner validate,
  required List<Map<String, dynamic>> originalDeck,
  required List<Map<String, dynamic>> optimizedDeck,
  required List<String> removals,
  required List<String> additions,
  required List<String> commanders,
  required String archetype,
  required Map<String, dynamic> postAnalysis,
  required List<String> existingValidationWarnings,
}) async {
  final validationReport = await validate(
    originalDeck: originalDeck,
    optimizedDeck: optimizedDeck,
    removals: removals,
    additions: additions,
    commanders: commanders,
    archetype: archetype,
  );

  final updatedPostAnalysis = Map<String, dynamic>.from(postAnalysis);
  updatedPostAnalysis['validation'] = validationReport.toJson();

  final validationWarnings = [...existingValidationWarnings];
  validationWarnings.addAll(validationReport.warnings);

  final rejectedWarning = buildOptimizeValidationRejectedWarning(
    validationReport,
  );
  if (rejectedWarning != null) {
    validationWarnings.insert(0, rejectedWarning);
  }

  Log.d(
    'Validation score: ${validationReport.score}/100 verdict: ${validationReport.verdict}',
  );

  return OptimizeRouteValidationResult(
    validationReport: validationReport,
    postAnalysis: updatedPostAnalysis,
    validationWarnings: validationWarnings,
  );
}

String? buildOptimizeValidationRejectedWarning(
  ValidationReport validationReport,
) {
  if (validationReport.verdict != 'reprovado') return null;
  return '🚫 VALIDAÇÃO: As trocas sugeridas NÃO passaram na validação automática (score: ${validationReport.score}/100).';
}
