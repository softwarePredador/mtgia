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
    expect(
      preview.metaReferenceContext['priority_source'],
      'competitive_meta_exact_shell_match',
    );
    expect(preview.intensity, OptimizeIntensity.focused);
  });

  test('AggressiveCandidateQualityDiagnostics parses optional payload', () {
    final diagnostics = AggressiveCandidateQualityDiagnostics.fromPayload({
      'optimize_diagnostics': {
        'aggressive_candidate_quality': {
          'requested_target_swaps': {'min': 10, 'max': 20},
          'removal_candidates': '12',
          'replacement_candidates': 30,
          'pairs_generated': 18,
          'returned_swaps': 0,
          'rejected_reason_buckets': {
            'quality_gate_rejected': 7,
            'role_mismatch': 2,
          },
          'low_candidate_coverage': true,
          'safety_reduced_scope': true,
          'ranked_before_quality_gate': true,
          'candidate_sources': const ['aggressive_meta_signal_v1'],
        },
      },
    });

    expect(diagnostics, isNotNull);
    expect(diagnostics!.requestedTargetSwaps, 20);
    expect(diagnostics.candidatesAnalyzed, 42);
    expect(diagnostics.pairsGenerated, 18);
    expect(diagnostics.returnedSwaps, 0);
    expect(diagnostics.primaryRejectedBucket, 'quality_gate_rejected');
    expect(
      diagnostics.userFacingReasons,
      contains('Principal bloqueio: qualidade final insuficiente.'),
    );
    expect(
      diagnostics.userFacingReasons,
      contains(
        'Faltaram candidatos seguros suficientes para este comandante e bracket.',
      ),
    );
  });

  test('AggressiveCandidateQualityDiagnostics falls back when absent', () {
    expect(
      AggressiveCandidateQualityDiagnostics.fromPayload(const {
        'mode': 'optimize',
        'intensity': 'aggressive',
      }),
      isNull,
    );
  });

  test('describeOptimizeNoChanges explains aggressive diagnostics', () {
    final result = {
      'mode': 'optimize',
      'intensity': 'aggressive',
      'removals': const <String>[],
      'additions': const <String>[],
      'optimize_diagnostics': {
        'aggressive_candidate_quality': {
          'removal_candidates': 8,
          'replacement_candidates': 22,
          'pairs_generated': 14,
          'returned_swaps': 0,
          'rejected_reason_buckets': {'mana_or_land_safety': 5},
        },
      },
    };
    final preview = OptimizePreviewData.fromResult(result);
    final outcome = OptimizeRequestOutcome(
      result: result,
      preview: preview,
      applyPlan: buildOptimizeApplyPlan(preview),
    );

    final presentation = describeOptimizeNoChanges(outcome);

    expect(presentation, isNotNull);
    expect(presentation!.title, 'Nenhuma melhoria segura encontrada');
    expect(
      presentation.message,
      'A IA encontrou ideias, mas o gate bloqueou as inseguras para preservar seu deck.',
    );
    expect(presentation.reasons, contains('Candidatos analisados: 30.'));
    expect(presentation.reasons, contains('Pares avaliados: 14.'));
    expect(presentation.reasons, contains('Swaps seguros retornados: 0.'));
    expect(
      presentation.reasons,
      contains('Principal bloqueio: risco na base de mana ou terrenos.'),
    );
  });

  test('buildOptimizeDebugJson keeps request and response payloads', () {
    final text = buildOptimizeDebugJson(
      deckId: 'deck-1',
      archetype: 'control',
      bracket: 2,
      keepTheme: true,
      intensity: OptimizeIntensity.aggressive,
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
    expect(text, contains('"intensity": "aggressive"'));
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

  test('describeDeckAiFailure treats quality rejection as safe no-op', () {
    final error = DeckAiFlowException(
      message: 'A otimização sugerida não passou no gate final de qualidade.',
      code: 'OPTIMIZE_QUALITY_REJECTED',
      payload: const {
        'quality_error': {
          'code': 'OPTIMIZE_QUALITY_REJECTED',
          'message': 'A otimização sugerida não passou no gate final.',
        },
      },
    );

    final presentation = describeDeckAiFailure(error, const ['Gate final']);

    expect(presentation.kind, DeckAiFailureKind.noSafeUpgradeFound);
    expect(presentation.title, 'Nenhuma melhoria segura encontrada');
    expect(presentation.reasons, contains('Gate final'));
  });

  test('describeDeckAiFailure maps quality rejection diagnostics', () {
    final error = DeckAiFlowException(
      message: 'A otimização sugerida não passou no gate final de qualidade.',
      code: 'OPTIMIZE_QUALITY_REJECTED',
      payload: const {
        'quality_error': {
          'code': 'OPTIMIZE_QUALITY_REJECTED',
          'message': 'A otimização sugerida não passou no gate final.',
          'optimize_diagnostics': {
            'aggressive_candidate_quality': {
              'removal_candidates': 4,
              'replacement_candidates': 11,
              'pairs_generated': 9,
              'returned_swaps': 0,
              'rejected_reason_buckets': {'role_mismatch': 6},
            },
          },
        },
      },
    );

    final presentation = describeDeckAiFailure(error, const ['Gate final']);

    expect(
      presentation.message,
      'A IA encontrou ideias, mas o gate bloqueou as inseguras para preservar seu deck.',
    );
    expect(presentation.reasons, contains('Candidatos analisados: 15.'));
    expect(
      presentation.reasons,
      contains('Principal bloqueio: mudança de função arriscada.'),
    );
    expect(presentation.reasons, isNot(contains('Gate final')));
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

  test('buildOptimizeApplyPlan applies only selected preview swaps', () {
    final preview = OptimizePreviewData.fromResult({
      'mode': 'optimize',
      'intensity': 'aggressive',
      'removals': const ['Mind Stone', 'Cancel'],
      'additions': const ['Arcane Signet', 'Counterspell'],
      'removals_detailed': const [
        {'card_id': 'remove-1', 'name': 'Mind Stone'},
        {'card_id': 'remove-2', 'name': 'Cancel'},
      ],
      'additions_detailed': const [
        {'card_id': 'add-1', 'name': 'Arcane Signet'},
        {'card_id': 'add-2', 'name': 'Counterspell'},
      ],
    });

    final plan = buildOptimizeApplyPlan(
      preview,
      selection: const OptimizePreviewSelection(
        selectedRemovalIndexes: {0},
        selectedAdditionIndexes: {1},
      ),
    );

    expect(plan.mode, OptimizeApplyMode.applyWithIds);
    expect(plan.removalsDetailed.single['card_id'], 'remove-1');
    expect(plan.additionsDetailed.single['card_id'], 'add-2');
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
        intensity: OptimizeIntensity.focused,
        executeRequest: (
          _,
          __, {
          required bracket,
          required keepTheme,
          required intensity,
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
      intensity: OptimizeIntensity.focused,
      executeRequest: (
        _,
        __, {
        required bracket,
        required keepTheme,
        required intensity,
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
        return outcome.applyPlan;
      },
      onApplyStart: () => calls.add('apply-start'),
      onNoChanges: (_) async => calls.add('no-changes'),
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
