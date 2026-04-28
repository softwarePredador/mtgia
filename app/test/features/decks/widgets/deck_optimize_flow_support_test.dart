import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/providers/deck_provider_support.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_flow_support.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_ui_support.dart';

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
      'meta_reference_context': const {
        'priority_source': 'competitive_meta_exact_shell_match',
        'references': [
          {
            'shell_label': 'Kraum + Tymna',
            'source': 'EDHTop16',
            'selection_rank': 1,
          },
        ],
      },
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
      result: const {
        'mode': 'optimize',
        'meta_reference_context': {
          'priority_source': 'competitive_meta_exact_shell_match',
        },
      },
    );

    expect(text, contains('"deck_id": "deck-1"'));
    expect(text, contains('"archetype": "control"'));
    expect(text, contains('"keep_theme": true'));
    expect(text, contains('"mode": "optimize"'));
    expect(text, contains('"meta_reference_context"'));
    expect(text, contains('"priority_source"'));
  });

  test('describeDeckAiFailure classifies needs_repair correctly', () {
    final error = DeckAiFlowException(
      message: 'Deck fora da faixa de optimize.',
      code: 'OPTIMIZE_NEEDS_REPAIR',
      outcomeCode: 'needs_repair',
      payload: const {
        'quality_error': {'message': 'Deck fora da faixa de optimize.'},
      },
    );

    final presentation = describeDeckAiFailure(error, const ['Pouca base']);

    expect(presentation.kind, DeckAiFailureKind.needsRepair);
    expect(presentation.title, 'Deck precisa de reconstrução');
    expect(presentation.reasons, contains('Pouca base'));
  });

  test('buildGuidedRebuildRequest resolves payload and fallbacks', () {
    final error = DeckAiFlowException(
      message: 'Needs repair',
      code: 'OPTIMIZE_NEEDS_REPAIR',
      outcomeCode: 'needs_repair',
      payload: const {
        'theme': {'theme': 'spellslinger'},
        'next_action': {
          'payload': {
            'archetype': 'control',
            'bracket': 3,
            'rebuild_scope': 'auto',
            'save_mode': 'draft_clone',
          },
        },
      },
    );

    final request = buildGuidedRebuildRequest(
      error: error,
      fallbackArchetype: 'midrange',
      selectedBracket: 2,
    );

    expect(request.archetype, 'control');
    expect(request.theme, 'spellslinger');
    expect(request.bracket, 3);
    expect(request.rebuildScope, 'auto');
    expect(request.saveMode, 'draft_clone');
  });

  test('buildOptimizeApplyPlan prefers bulk add for complete mode', () {
    final preview = OptimizePreviewData.fromResult({
      'mode': 'complete',
      'removals': const <String>[],
      'additions': const ['Arcane Signet'],
      'additions_detailed': const [
        {'card_id': 'add-1', 'name': 'Arcane Signet', 'quantity': 2},
      ],
    });

    final plan = buildOptimizeApplyPlan(preview);

    expect(plan.mode, OptimizeApplyMode.addBulk);
    expect(plan.bulkCards.single['card_id'], 'add-1');
    expect(plan.bulkCards.single['quantity'], 2);
  });

  test('buildOptimizeApplyPlan falls back to ids or names as needed', () {
    final idsPreview = OptimizePreviewData.fromResult({
      'mode': 'optimize',
      'removals': const ['Mind Stone'],
      'additions': const ['Arcane Signet'],
      'removals_detailed': const [
        {'card_id': 'remove-1', 'name': 'Mind Stone'},
      ],
      'additions_detailed': const [
        {'card_id': 'add-1', 'name': 'Arcane Signet'},
      ],
    });
    final idsPlan = buildOptimizeApplyPlan(idsPreview);
    expect(idsPlan.mode, OptimizeApplyMode.applyWithIds);

    final namesPreview = OptimizePreviewData.fromResult({
      'mode': 'optimize',
      'removals': const ['Mind Stone'],
      'additions': const ['Arcane Signet'],
    });
    final namesPlan = buildOptimizeApplyPlan(namesPreview);
    expect(namesPlan.mode, OptimizeApplyMode.applyByNames);
    expect(namesPlan.removals, ['Mind Stone']);
    expect(namesPlan.additions, ['Arcane Signet']);
  });

  test('executeOptimizeApplyPlan dispatches to correct executor', () async {
    final calls = <String>[];

    await executeOptimizeApplyPlan(
      deckId: 'deck-1',
      plan: const OptimizeApplyPlan(
        mode: OptimizeApplyMode.applyWithIds,
        removalsDetailed: [
          {'card_id': 'remove-1'},
        ],
        additionsDetailed: [
          {'card_id': 'add-1'},
        ],
      ),
      addBulk: (_, __) async => calls.add('bulk'),
      applyWithIds: (_, __, ___) async => calls.add('ids'),
      applyByNames: (_, __, ___) async => calls.add('names'),
    );

    expect(calls, ['ids']);
  });

  test(
    'executeConfirmedOptimization applies plan and persists strategy',
    () async {
      final calls = <String>[];

      await executeConfirmedOptimization(
        deckId: 'deck-1',
        archetype: 'control',
        bracket: 2,
        plan: const OptimizeApplyPlan(
          mode: OptimizeApplyMode.applyByNames,
          removals: ['Mind Stone'],
          additions: ['Arcane Signet'],
        ),
        addBulk: (_, __) async => calls.add('bulk'),
        applyWithIds: (_, __, ___) async => calls.add('ids'),
        applyByNames: (_, removals, additions) async {
          calls.add('names:${removals.join(",")}:${additions.join(",")}');
        },
        updateDeckStrategy: ({
          required deckId,
          required archetype,
          required bracket,
        }) async {
          calls.add('strategy:$deckId:$archetype:$bracket');
        },
      );

      expect(calls, [
        'names:Mind Stone:Arcane Signet',
        'strategy:deck-1:control:2',
      ]);
    },
  );

  test(
    'executeGuidedRebuildRequest refreshes saved draft when returned',
    () async {
      final calls = <String>[];

      final outcome = await executeGuidedRebuildRequest(
        deckId: 'deck-1',
        request: const GuidedRebuildRequest(
          archetype: 'control',
          theme: 'spellslinger',
          bracket: 3,
          rebuildScope: 'auto',
          saveMode: 'draft_clone',
        ),
        rebuildDeck: (
          _, {
          required archetype,
          required theme,
          required bracket,
          required rebuildScope,
          required saveMode,
        }) async {
          calls.add(
            'rebuild:$archetype:$theme:$bracket:$rebuildScope:$saveMode',
          );
          return {'draft_deck_id': 'draft-1'};
        },
        refreshDeckDetails: (deckId, {forceRefresh = false}) async {
          calls.add('refresh:$deckId:$forceRefresh');
        },
      );

      expect(outcome.hasSavedDraft, isTrue);
      expect(outcome.draftDeckId, 'draft-1');
      expect(
        calls,
        containsAll([
          'rebuild:control:spellslinger:3:auto:draft_clone',
          'refresh:draft-1:true',
        ]),
      );
    },
  );

  test(
    'executeGuidedRebuildFlow dispatches preview and draft callbacks',
    () async {
      final calls = <String>[];

      await executeGuidedRebuildFlow(
        deckId: 'deck-1',
        request: const GuidedRebuildRequest(
          archetype: 'control',
          theme: 'spellslinger',
          bracket: 3,
          rebuildScope: 'auto',
          saveMode: 'draft_clone',
        ),
        rebuildDeck:
            (
              _, {
              required archetype,
              required theme,
              required bracket,
              required rebuildScope,
              required saveMode,
            }) async => {'draft_deck_id': 'draft-1'},
        refreshDeckDetails: (_, {forceRefresh = false}) async {
          calls.add('refresh:$forceRefresh');
        },
        onLoadingStart: () => calls.add('loading-start'),
        onLoadingClose: () => calls.add('loading-close'),
        onPreviewOnly: () async => calls.add('preview'),
        onDraftReady: (draftDeckId) async => calls.add('draft:$draftDeckId'),
        onAiError: (_) async => calls.add('ai-error'),
        onGenericError: (_) => calls.add('generic-error'),
      );

      expect(calls, [
        'loading-start',
        'refresh:true',
        'loading-close',
        'draft:draft-1',
      ]);
    },
  );

  test('executeDeckAiFailureAction dispatches by presentation kind', () async {
    final calls = <String>[];

    await executeDeckAiFailureAction(
      presentation: const DeckAiFailurePresentation(
        kind: DeckAiFailureKind.noSafeUpgradeFound,
        title: 'Nada seguro',
        message: 'Sem upgrade',
        reasons: ['Gate'],
      ),
      onNeedsRepair: () async => calls.add('repair'),
      showInfo:
          ({required title, required message, required reasons}) async =>
              calls.add('info:$title:$message:${reasons.join(",")}'),
      showError: (message) => calls.add('error:$message'),
    );

    expect(calls, ['info:Nada seguro:Sem upgrade:Gate']);
  });

  test(
    'requestOptimizePreview maps progress and returns preview/apply plan',
    () async {
      final progress = <FlowProgressState>[];

      final outcome = await requestOptimizePreview(
        deckId: 'deck-1',
        archetype: 'control',
        bracket: 2,
        keepTheme: true,
        executeRequest: (
          _,
          __, {
          required bracket,
          required keepTheme,
          required onProgress,
        }) async {
          onProgress('Gerando sugestões...', 2, 5);
          return {
            'mode': 'optimize',
            'removals': const ['Mind Stone'],
            'additions': const ['Arcane Signet'],
            'removals_detailed': const [
              {'card_id': 'remove-1', 'name': 'Mind Stone'},
            ],
            'additions_detailed': const [
              {'card_id': 'add-1', 'name': 'Arcane Signet'},
            ],
          };
        },
        onProgressUpdate: progress.add,
      );

      expect(progress.single.stage, 'Gerando sugestões...');
      expect(progress.single.stageNumber, 2);
      expect(outcome.preview.mode, 'optimize');
      expect(outcome.applyPlan.mode, OptimizeApplyMode.applyWithIds);
    },
  );

  test('executeOptimizeFlow orchestrates preview, apply and success', () async {
    final calls = <String>[];
    final progress = <FlowProgressState>[];

    await executeOptimizeFlow(
      deckId: 'deck-1',
      archetype: 'control',
      bracket: 2,
      keepTheme: true,
      executeRequest: (
        _,
        __, {
        required bracket,
        required keepTheme,
        required onProgress,
      }) async {
        onProgress('Gerando sugestões...', 3, 5);
        return {
          'mode': 'optimize',
          'removals': const ['Mind Stone'],
          'additions': const ['Arcane Signet'],
        };
      },
      onProgressUpdate: progress.add,
      confirmPreview: (outcome) async {
        calls.add('preview:${outcome.preview.mode}');
        return true;
      },
      onApplyStart: () => calls.add('apply-start'),
      onNoChanges: () => calls.add('no-changes'),
      onSuccess: () => calls.add('success'),
      onAiError: (_) async => calls.add('ai-error'),
      onGenericError: (_) => calls.add('generic-error'),
      addBulk: (_, __) async => calls.add('bulk'),
      applyWithIds: (_, __, ___) async => calls.add('ids'),
      applyByNames: (_, removals, additions) async {
        calls.add('names:${removals.join(",")}:${additions.join(",")}');
      },
      updateDeckStrategy: ({
        required deckId,
        required archetype,
        required bracket,
      }) async {
        calls.add('strategy:$deckId:$archetype:$bracket');
      },
    );

    expect(progress.single.stageNumber, 3);
    expect(calls, [
      'preview:optimize',
      'apply-start',
      'names:Mind Stone:Arcane Signet',
      'strategy:deck-1:control:2',
      'success',
    ]);
  });

  test(
    'executeOptimizeNeedsRepairFlow orchestrates rebuild callbacks',
    () async {
      final calls = <String>[];
      final error = DeckAiFlowException(
        message: 'Needs repair',
        code: 'OPTIMIZE_NEEDS_REPAIR',
        outcomeCode: 'needs_repair',
        payload: const {
          'theme': {'theme': 'spellslinger'},
          'next_action': {
            'payload': {
              'archetype': 'control',
              'bracket': 3,
              'rebuild_scope': 'auto',
              'save_mode': 'draft_clone',
            },
          },
        },
      );

      await executeOptimizeNeedsRepairFlow(
        deckId: 'deck-1',
        error: error,
        fallbackArchetype: 'midrange',
        selectedBracket: 2,
        rebuildDeck: (
          _, {
          required archetype,
          required theme,
          required bracket,
          required rebuildScope,
          required saveMode,
        }) async {
          calls.add(
            'rebuild:$archetype:$theme:$bracket:$rebuildScope:$saveMode',
          );
          return {'draft_deck_id': 'draft-1'};
        },
        refreshDeckDetails: (deckId, {forceRefresh = false}) async {
          calls.add('refresh:$deckId:$forceRefresh');
        },
        onLoadingStart: () => calls.add('loading-start'),
        onLoadingClose: () => calls.add('loading-close'),
        onPreviewOnly: () async => calls.add('preview'),
        onDraftReady: (draftDeckId) async => calls.add('draft:$draftDeckId'),
        onAiError: (_) async => calls.add('ai-error'),
        onGenericError: (_) => calls.add('generic-error'),
      );

      expect(calls, [
        'loading-start',
        'rebuild:control:spellslinger:3:auto:draft_clone',
        'refresh:draft-1:true',
        'loading-close',
        'draft:draft-1',
      ]);
    },
  );

  test(
    'executeOptimizeFailureFlow routes needs_repair into rebuild flow',
    () async {
      final calls = <String>[];
      final error = DeckAiFlowException(
        message: 'Needs repair',
        code: 'OPTIMIZE_NEEDS_REPAIR',
        outcomeCode: 'needs_repair',
        payload: const {
          'theme': {'theme': 'spellslinger'},
          'next_action': {
            'payload': {
              'archetype': 'control',
              'bracket': 3,
              'rebuild_scope': 'auto',
              'save_mode': 'draft_clone',
            },
          },
        },
      );

      await executeOptimizeFailureFlow(
        deckId: 'deck-1',
        error: error,
        fallbackArchetype: 'midrange',
        selectedBracket: 2,
        rebuildDeck:
            (
              _, {
              required archetype,
              required theme,
              required bracket,
              required rebuildScope,
              required saveMode,
            }) async => {'draft_deck_id': 'draft-1'},
        refreshDeckDetails: (_, {forceRefresh = false}) async {
          calls.add('refresh:$forceRefresh');
        },
        onLoadingStart: () => calls.add('loading-start'),
        onLoadingClose: () => calls.add('loading-close'),
        onPreviewOnly: () async => calls.add('preview'),
        onDraftReady: (draftDeckId) async => calls.add('draft:$draftDeckId'),
        onRebuildAiError: (_) async => calls.add('rebuild-ai-error'),
        onRebuildGenericError: (_) => calls.add('rebuild-generic-error'),
        showInfo:
            ({required title, required message, required reasons}) async =>
                calls.add('info:$title'),
        showError: (message) => calls.add('error:$message'),
      );

      expect(calls, [
        'loading-start',
        'refresh:true',
        'loading-close',
        'draft:draft-1',
      ]);
    },
  );
}
