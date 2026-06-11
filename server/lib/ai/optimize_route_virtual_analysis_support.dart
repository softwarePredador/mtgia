import 'optimize_deck_support.dart' as optimize_deck;
import 'optimize_route_post_validation_support.dart'
    as optimize_route_post_validation;
import 'optimize_state_support.dart' as optimize_state;

class OptimizeVirtualPostAnalysisResult {
  final List<Map<String, dynamic>> additionsForAnalysis;
  final List<Map<String, dynamic>> virtualDeck;
  final Map<String, dynamic> postAnalysis;
  final List<String> validationWarnings;

  const OptimizeVirtualPostAnalysisResult({
    required this.additionsForAnalysis,
    required this.virtualDeck,
    required this.postAnalysis,
    required this.validationWarnings,
  });
}

OptimizeVirtualPostAnalysisResult buildOptimizeVirtualPostAnalysis({
  required List<Map<String, dynamic>> originalDeck,
  required List<String> validRemovals,
  required List<String> validAdditions,
  required List<Map<String, dynamic>> additionsData,
  required Iterable<String> deckColors,
  required Map<String, dynamic> deckAnalysis,
  required String effectiveOptimizeArchetype,
}) {
  final additionsForAnalysis = optimize_deck.buildOptimizeAdditionEntries(
    requestedAdditions: validAdditions,
    additionsData: additionsData,
  );
  final virtualDeck = optimize_deck.buildVirtualDeckForAnalysis(
    originalDeck: originalDeck,
    removals: validRemovals,
    additions: additionsForAnalysis,
  );

  final postAnalyzer = optimize_state.DeckArchetypeAnalyzerCore(
    virtualDeck,
    deckColors.toList(),
  );
  final postAnalysis = Map<String, dynamic>.from(
    postAnalyzer.generateAnalysis(),
  );
  final postValidationSummary =
      optimize_route_post_validation.buildPostAnalysisValidationSummary(
    deckAnalysis: deckAnalysis,
    postAnalysis: postAnalysis,
    effectiveOptimizeArchetype: effectiveOptimizeArchetype,
  );

  if (postValidationSummary.improvements.isNotEmpty) {
    postAnalysis['improvements'] = postValidationSummary.improvements;
  }

  return OptimizeVirtualPostAnalysisResult(
    additionsForAnalysis: additionsForAnalysis,
    virtualDeck: virtualDeck,
    postAnalysis: postAnalysis,
    validationWarnings: postValidationSummary.warnings,
  );
}
