import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('post-game screen links diagnostics to optimize and rebuild flows', () {
    final postGameSource =
        File(
          'lib/features/retention/screens/post_game_notes_screen.dart',
        ).readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();
    final detailsSource =
        File(
          'lib/features/decks/screens/deck_details_screen.dart',
        ).readAsStringSync();
    final optimizeSectionsSource =
        File(
          'lib/features/decks/widgets/deck_optimize_sections.dart',
        ).readAsStringSync();

    expect(
      postGameSource,
      contains("'/decks/\${widget.deckId}?optimize=post_game'"),
    );
    expect(
      postGameSource,
      contains("'/decks/\${widget.deckId}?optimize=rebuild'"),
    );
    expect(
      postGameSource,
      contains("Key('post-game-optimize-from-summary-button')"),
    );
    expect(
      postGameSource,
      contains("Key('post-game-rebuild-from-summary-button')"),
    );
    expect(mainSource, contains("state.uri.queryParameters['optimize']"));
    expect(detailsSource, contains('initialOptimizationIntent'));
    expect(detailsSource, contains('_openInitialOptimizationIntent'));
    expect(detailsSource, contains('OptimizeIntensity.rebuild'));
    expect(optimizeSectionsSource, contains('optimize-post-game-notice'));
  });
}
