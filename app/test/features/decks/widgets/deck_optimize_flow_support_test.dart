import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/providers/deck_provider_support.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_flow_support.dart';

void main() {
  test('OptimizePreviewData normalizes detailed and fallback fields', () {
    final preview = OptimizePreviewData.fromResult({
      'mode': 'optimize',
      'removals': const ['Mind Stone'],
      'additions': const ['Arcane Signet'],
      'reasoning': 'Troca simples',
      'warnings': const {'note': 'safe'},
      'theme': const {'theme': 'spellslinger'},
      'constraints': const {'keep_theme': true},
      'additions_detailed': const [
        {'card_id': 'add-1', 'name': 'Arcane Signet'},
      ],
      'removals_detailed': const [
        {'card_id': 'remove-1', 'name': 'Mind Stone'},
      ],
      'deck_analysis': const {'average_cmc': 3.2},
      'post_analysis': const {'average_cmc': 3.0},
      'quality_warning': const {'message': 'partial'},
    });

    expect(preview.hasChanges, isTrue);
    expect(preview.mode, 'optimize');
    expect(preview.themeInfo['theme'], 'spellslinger');
    expect(preview.displayAdditions.first['card_id'], 'add-1');
    expect(preview.displayRemovals.first['card_id'], 'remove-1');
    expect(preview.qualityWarning?['message'], 'partial');
  });

  test('buildOptimizeDebugJson keeps request and response payloads', () {
    final text = buildOptimizeDebugJson(
      deckId: 'deck-1',
      archetype: 'control',
      bracket: 2,
      keepTheme: true,
      result: const {'mode': 'optimize'},
    );

    expect(text, contains('"deck_id": "deck-1"'));
    expect(text, contains('"archetype": "control"'));
    expect(text, contains('"keep_theme": true'));
    expect(text, contains('"mode": "optimize"'));
  });

  test('describeDeckAiFailure classifies needs_repair correctly', () {
    final error = DeckAiFlowException(
      message: 'Deck fora da faixa de optimize.',
      code: 'OPTIMIZE_NEEDS_REPAIR',
      outcomeCode: 'needs_repair',
      payload: const {
        'quality_error': {
          'message': 'Deck fora da faixa de optimize.',
        },
      },
    );

    final presentation = describeDeckAiFailure(error, const ['Pouca base']);

    expect(presentation.kind, DeckAiFailureKind.needsRepair);
    expect(presentation.title, 'Deck precisa de reconstrução');
    expect(presentation.reasons, contains('Pouca base'));
  });
}
