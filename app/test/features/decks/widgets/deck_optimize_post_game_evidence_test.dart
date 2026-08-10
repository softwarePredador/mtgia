import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/providers/deck_provider_support.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_dialogs.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_flow_support.dart';

void main() {
  test('recommendation context carries only the post-game note receipt', () {
    final context = buildOptimizeRecommendationContext(
      preferCollection: true,
      budgetEnabled: false,
      budgetLimit: 0,
      rebuildIntent: 'post_game',
      postGameNoteId: ' note-42 ',
    );

    expect(context['post_game_note_id'], 'note-42');
    expect(context, isNot(contains('notes')));
    expect(context, isNot(contains('performed_well')));
  });

  test('optimization preview parses authenticated post-game evidence', () {
    final preview = OptimizePreviewData.fromResult({
      'mode': 'optimize',
      'outcome_code': 'optimized',
      'can_apply': true,
      'post_game_evidence': _evidence,
    });

    expect(preview.postGameEvidence['note_id'], 'note-42');
    expect(preview.postGameEvidence['note_revision'], 3);
    expect(preview.postGameEvidence['selected_card_count'], 2);
  });

  testWidgets('optimization preview explains the authenticated evidence used', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showOptimizationPreviewDialog(
                context,
                mode: 'optimize',
                archetype: 'artifacts',
                keepTheme: true,
                preservedTheme: 'artifacts',
                reasoning: 'Ajuste orientado pelo pós-jogo.',
                intensity: OptimizeIntensity.focused,
                optimizeIntensity: const <String, dynamic>{},
                qualityWarning: null,
                deckAnalysis: const <String, dynamic>{},
                postAnalysis: const <String, dynamic>{},
                warnings: const <String, dynamic>{},
                metaReferenceContext: const <String, dynamic>{},
                postGameEvidence: _evidence,
                canApply: false,
                displayRemovals: const <Map<String, dynamic>>[],
                displayAdditions: const <Map<String, dynamic>>[],
              ),
              child: const Text('open-evidence-preview'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-evidence-preview'));
    await tester.pumpAndSettle();

    final section = find.byKey(
      const Key('optimize-preview-post-game-evidence'),
    );
    expect(section, findsOneWidget);
    expect(
      find.descendant(of: section, matching: find.text('Sol Ring')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('Thought Vessel')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('Velocidade')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: section,
        matching: find.textContaining('não autoriza aplicação automática'),
      ),
      findsOneWidget,
    );
  });
}

const Map<String, dynamic> _evidence = {
  'schema_version': 'post_game_optimize_evidence_v1',
  'note_id': 'note-42',
  'note_revision': 3,
  'selected_card_count': 2,
  'issues': ['speed'],
  'performed_well': [
    {
      'card_id': '11111111-1111-4111-8111-111111111111',
      'name': 'Sol Ring',
      'quantity': 1,
    },
  ],
  'underperformed': [
    {
      'card_id': '22222222-2222-4222-8222-222222222222',
      'name': 'Thought Vessel',
      'quantity': 1,
    },
  ],
  'deck_revision': {'matches_current': true},
};
