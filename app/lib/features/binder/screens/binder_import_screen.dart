import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/launch_features.dart';
import '../../../core/config/release_capabilities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/card_artwork.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../../cards/screens/card_search_screen.dart';
import '../../cards/widgets/card_edition_metadata.dart';
import '../../cards/widgets/card_printing_picker.dart';
import '../../decks/models/deck_card_item.dart';
import '../../scanner/screens/card_scanner_screen.dart';
import '../models/binder_import_models.dart';
import '../providers/binder_import_provider.dart';
import '../services/binder_import_draft_store.dart';

class BinderImportScreen extends StatefulWidget {
  const BinderImportScreen({
    super.key,
    required this.ownerId,
    this.initialListType = 'have',
    this.apiClient,
    this.draftStore,
    this.onOnboardingTaskCompleted,
    this.scannerBuildSupported = LaunchFeatures.scannerEnabled,
  });

  final String ownerId;
  final String initialListType;
  final ApiClient? apiClient;
  final BinderImportDraftStore? draftStore;
  final Future<bool> Function()? onOnboardingTaskCompleted;
  final bool scannerBuildSupported;

  @override
  State<BinderImportScreen> createState() => _BinderImportScreenState();
}

class _BinderImportScreenState extends State<BinderImportScreen> {
  late final BinderImportProvider _provider;
  final _sourceController = TextEditingController();
  Timer? _draftTimer;

  String get _listType => widget.initialListType == 'want' ? 'want' : 'have';

  @override
  void initState() {
    super.initState();
    _provider = BinderImportProvider(
      apiClient: widget.apiClient,
      draftStore: widget.draftStore,
    );
    _sourceController.addListener(_scheduleDraftSave);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _provider.initialize(ownerId: widget.ownerId, listType: _listType);
    if (!mounted) return;
    if (_sourceController.text.isEmpty && _provider.sourceText.isNotEmpty) {
      _sourceController.text = _provider.sourceText;
      _sourceController.selection = TextSelection.collapsed(
        offset: _sourceController.text.length,
      );
    }
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 450), () {
      unawaited(_provider.saveSourceDraft(_sourceController.text));
    });
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _sourceController.removeListener(_scheduleDraftSave);
    _sourceController.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _discardDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceSlate,
        title: const Text('Descartar rascunho?'),
        content: const Text(
          'A fonte e as correções locais deste lote serão removidas. Cartas já aplicadas no Fichário não mudam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Manter'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _provider.discardDraft();
    if (!mounted) return;
    _sourceController.clear();
  }

  Future<void> _confirmAndApply() async {
    final creates = _provider.plans
        .where((plan) => plan.action == 'create')
        .length;
    final updates = _provider.plans
        .where((plan) => plan.action == 'update')
        .length;
    final pending =
        _provider.pendingDecisionCount + _provider.invalidLines.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('binder-import-apply-confirmation'),
        backgroundColor: AppTheme.surfaceSlate,
        title: const Text('Aplicar lote revisado?'),
        content: Text(
          '$creates ${creates == 1 ? 'item será criado' : 'itens serão criados'} e '
          '$updates ${updates == 1 ? 'será atualizado' : 'serão atualizados'}. '
          '${pending > 0 ? '$pending pendência(s) ficarão no rascunho. ' : ''}'
          'Um retry do mesmo plano não soma cópias novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar à revisão'),
          ),
          FilledButton(
            key: const Key('binder-import-confirm-apply-button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Aplicar lote'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _provider.applyBatch();
  }

  Future<void> _choosePrinting(BinderImportCandidate candidate) async {
    final options = candidate.printings;
    if (options.isEmpty) {
      await _provider.chooseSuggestedName(
        candidate.id,
        candidate.matchedName ?? candidate.requestedName,
      );
      if (!mounted || candidate.printings.isEmpty) return;
    }
    final fallback = DeckCardItem.fromJson(candidate.printings.first);
    final selected = await showCardPrintingPicker(
      context: context,
      card: fallback,
      loadPrintings: (_) async => candidate.printings,
      title: 'Impressão para ${candidate.displayName}',
      confirmLabel: 'Confirmar no lote',
    );
    if (!mounted || selected == null) return;
    final exact = candidate.printings.cast<Map<String, dynamic>?>().firstWhere(
      (printing) => printing?['id']?.toString() == selected.id,
      orElse: () => null,
    );
    await _provider.selectPrinting(
      candidate.id,
      exact ?? _printingFromCard(selected),
    );
  }

  Future<void> _openManualSearch(BinderImportCandidate candidate) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CardSearchScreen(
          deckId: '',
          mode: 'binder',
          onCardSelectedForBinder: (card) {
            unawaited(_provider.useManualCard(candidate.id, card));
          },
        ),
      ),
    );
  }

  Future<void> _openScannerSession() async {
    final scannerAllowed = context
        .read<ReleaseCapabilitiesProvider?>()
        ?.isAllowed(
          ReleaseCapability.scanner,
          buildSupported: widget.scannerBuildSupported,
        );
    if (scannerAllowed != true) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CardScannerScreen(
          deckId: '',
          mode: 'binder',
          continuousBinderSession: true,
          onCardScannedForBinder: (card) {
            unawaited(_provider.addScannedCard(card, listType: _listType));
          },
        ),
      ),
    );
  }

  Future<void> _finishImport() async {
    final completion = widget.onOnboardingTaskCompleted;
    if (completion == null) {
      context.pop(true);
      return;
    }
    var completed = false;
    try {
      completed = await completion();
    } catch (_) {
      completed = false;
    }
    if (!mounted) return;
    context.go(
      completed ? '/home' : '/onboarding/core-flow?storage=unavailable',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannerAllowed = context
        .watch<ReleaseCapabilitiesProvider?>()
        ?.isAllowed(
          ReleaseCapability.scanner,
          buildSupported: widget.scannerBuildSupported,
        );
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<BinderImportProvider>(
        builder: (context, provider, _) {
          final applied = provider.candidates.where((candidate) {
            return candidate.status == BinderImportCandidateStatus.applied;
          }).length;
          return Scaffold(
            key: const Key('binder-import-screen'),
            backgroundColor: AppTheme.backgroundAbyss,
            appBar: AppBar(
              title: Text(
                _listType == 'want'
                    ? 'Importar para Quero'
                    : 'Importar coleção',
              ),
              backgroundColor: AppTheme.backgroundAbyss,
              surfaceTintColor: AppTheme.transparent,
              actions: [
                if (provider.sourceText.isNotEmpty ||
                    provider.candidates.isNotEmpty)
                  IconButton(
                    key: const Key('binder-import-discard-action'),
                    tooltip: 'Descartar rascunho',
                    onPressed: provider.isBusy ? null : _discardDraft,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppTheme.scaffoldGradient,
              ),
              child: provider.isLoadingDraft
                  ? AppStatePanel.loading(
                      key: const Key('binder-import-draft-loading'),
                      title: 'Retomando rascunho',
                      message: 'Carregando a fila salva neste dispositivo.',
                      accent: AppTheme.frost400,
                    )
                  : ResponsivePageFrame(
                      maxWidth: AppTheme.contentMaxWidth,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 980;
                          if (wide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 390,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppTheme.space12,
                                      AppTheme.space16,
                                      AppTheme.space16,
                                      AppTheme.space112,
                                    ),
                                    child: _SourcePane(
                                      controller: _sourceController,
                                      provider: provider,
                                      listType: _listType,
                                      onDiscard: _discardDraft,
                                      onScan: scannerAllowed == true
                                          ? _openScannerSession
                                          : null,
                                    ),
                                  ),
                                ),
                                VerticalDivider(
                                  width: 1,
                                  color: AppTheme.outlineMuted.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                Expanded(
                                  child: _ReviewPane(
                                    provider: provider,
                                    onChoosePrinting: _choosePrinting,
                                    onManualSearch: _openManualSearch,
                                  ),
                                ),
                              ],
                            );
                          }
                          return ListView(
                            key: const Key('binder-import-mobile-scroll'),
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.space12,
                              AppTheme.space12,
                              AppTheme.space12,
                              AppTheme.space150,
                            ),
                            children: [
                              _SourcePane(
                                controller: _sourceController,
                                provider: provider,
                                listType: _listType,
                                onDiscard: _discardDraft,
                                onScan: scannerAllowed == true
                                    ? _openScannerSession
                                    : null,
                              ),
                              const SizedBox(height: AppTheme.space16),
                              _ReviewPane(
                                provider: provider,
                                shrinkWrap: true,
                                onChoosePrinting: _choosePrinting,
                                onManualSearch: _openManualSearch,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
            bottomNavigationBar: _ImportActionBar(
              provider: provider,
              appliedCount: applied,
              onPreview: provider.canPreview ? provider.previewBatch : null,
              onApply: provider.canApply ? _confirmAndApply : null,
              onRetry:
                  provider.candidates.any(
                    (candidate) =>
                        candidate.status == BinderImportCandidateStatus.failed,
                  )
                  ? provider.retryFailed
                  : null,
              onFinish: applied > 0 ? _finishImport : null,
            ),
          );
        },
      ),
    );
  }
}

class _SourcePane extends StatelessWidget {
  const _SourcePane({
    required this.controller,
    required this.provider,
    required this.listType,
    required this.onDiscard,
    this.onScan,
  });

  final TextEditingController controller;
  final BinderImportProvider provider;
  final String listType;
  final VoidCallback onDiscard;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.brass400.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.brass400.withValues(alpha: 0.25),
                ),
              ),
              child: const ManaLoomGlyph(
                ManaLoomGlyphKind.collection,
                size: 22,
                color: AppTheme.brass400,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listType == 'want'
                        ? 'Monte sua lista Quero em lote'
                        : 'Traga sua caixa para o Fichário',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'Uma linha por carta. Set e número são opcionais, mas aceleram a confirmação da impressão.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.outlineMuted),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FORMATOS ACEITOS',
                style: TextStyle(
                  color: AppTheme.frost400,
                  fontSize: AppTheme.fontXs,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: AppTheme.space8),
              SelectableText(
                '4 Lightning Bolt\n1 Sol Ring (CMM) 396\n2 Rhystic Study [WOT] 25',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: AppTheme.fontSm,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        TextField(
          key: const Key('binder-import-source-field'),
          controller: controller,
          minLines: 9,
          maxLines: 16,
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            labelText: 'Lista da coleção',
            hintText: 'Cole aqui a lista exportada ou digitada…',
            alignLabelWithHint: true,
            helperText: 'O rascunho fica salvo por usuário neste dispositivo.',
            helperMaxLines: 2,
            errorMaxLines: 3,
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpar texto',
                    onPressed: controller.clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('binder-import-review-source-button'),
            onPressed: provider.isBusy
                ? null
                : () => provider.reviewSource(
                    controller.text,
                    listType: listType,
                  ),
            icon: provider.isResolving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fact_check_outlined),
            label: Text(
              provider.isResolving
                  ? 'Lendo catálogo…'
                  : 'Criar fila de revisão',
            ),
          ),
        ),
        if (onScan != null) ...[
          const SizedBox(height: AppTheme.space8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('binder-import-scanner-session-button'),
              onPressed: provider.isBusy ? null : onScan,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Abrir sessão de scanner'),
            ),
          ),
        ],
        if (provider.invalidLines.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space12),
          _InvalidLinesPanel(lines: provider.invalidLines),
        ],
        if (provider.history.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space16),
          _HistoryPanel(history: provider.history),
        ],
      ],
    );
  }
}

class _ReviewPane extends StatelessWidget {
  const _ReviewPane({
    required this.provider,
    required this.onChoosePrinting,
    required this.onManualSearch,
    this.shrinkWrap = false,
  });

  final BinderImportProvider provider;
  final Future<void> Function(BinderImportCandidate) onChoosePrinting;
  final Future<void> Function(BinderImportCandidate) onManualSearch;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    if (provider.candidates.isEmpty) {
      return AppStatePanel(
        key: const Key('binder-import-empty-review'),
        icon: Icons.playlist_add_check_circle_outlined,
        title: 'A fila aparecerá aqui',
        message:
            'Cole a lista, revise nomes e escolha cada impressão ambígua antes de alterar o Fichário.',
        accent: AppTheme.frost400,
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewHeader(provider: provider),
        if (provider.isResolving || provider.isPreviewing) ...[
          const SizedBox(height: AppTheme.space8),
          const LinearProgressIndicator(
            key: Key('binder-import-review-progress'),
            color: AppTheme.frost400,
          ),
        ],
        if (provider.error != null) ...[
          const SizedBox(height: AppTheme.space10),
          _InlineNotice(
            key: const Key('binder-import-error'),
            icon: Icons.error_outline_rounded,
            color: AppTheme.error,
            message: provider.error!,
          ),
        ],
        if (provider.summary != null) ...[
          const SizedBox(height: AppTheme.space10),
          _AvailabilityStrip(summary: provider.summary!),
        ],
        const SizedBox(height: AppTheme.space10),
        ...provider.candidates.map(
          (candidate) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space10),
            child: _CandidateCard(
              candidate: candidate,
              provider: provider,
              onChoosePrinting: () => onChoosePrinting(candidate),
              onManualSearch: () => onManualSearch(candidate),
            ),
          ),
        ),
        if (provider.plans.isNotEmpty) _PlanSummary(plans: provider.plans),
      ],
    );
    if (shrinkWrap) return content;
    return SingleChildScrollView(
      key: const Key('binder-import-review-scroll'),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space16,
        AppTheme.space12,
        AppTheme.space112,
      ),
      child: content,
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.provider});

  final BinderImportProvider provider;

  @override
  Widget build(BuildContext context) {
    final copies = provider.candidates.fold<int>(
      0,
      (total, candidate) => total + candidate.quantity,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fila de candidatos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppTheme.space3),
              Text(
                '${provider.candidates.length} linhas agrupadas • $copies cópias',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontSm,
                ),
              ),
            ],
          ),
        ),
        _CountPill(
          label: 'Prontas',
          value: provider.readyCount,
          color: AppTheme.success,
        ),
        const SizedBox(width: AppTheme.space6),
        _CountPill(
          label: 'Pendentes',
          value: provider.pendingDecisionCount,
          color: AppTheme.brass400,
        ),
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.provider,
    required this.onChoosePrinting,
    required this.onManualSearch,
  });

  final BinderImportCandidate candidate;
  final BinderImportProvider provider;
  final VoidCallback onChoosePrinting;
  final VoidCallback onManualSearch;

  @override
  Widget build(BuildContext context) {
    final selected = candidate.selectedPrinting;
    final status = _candidateStatus(candidate);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      key: Key('binder-import-candidate-${candidate.id}'),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: status.color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: compact ? 58 : 68,
                height: compact ? 82 : 96,
                child: CardArtwork(
                  variant: CardArtworkVariant.gallery,
                  imageUrl: selected?['image_url']?.toString(),
                  semanticLabel: selected == null
                      ? 'Impressão ainda não escolhida para ${candidate.displayName}'
                      : 'Arte da impressão escolhida de ${candidate.displayName}',
                  constrainAspectRatio: false,
                  showStatusBadge: selected != null,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppTheme.space6,
                      runSpacing: AppTheme.space6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          candidate.displayName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.fontMd,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        _StatusChip(label: status.label, color: status.color),
                        if (candidate.hasDuplicateSources)
                          _StatusChip(
                            label: '${candidate.sourceLines.length} linhas',
                            color: AppTheme.frost400,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space5),
                    Text(
                      selected == null
                          ? _sourceHint(candidate)
                          : cardEditionFullLabel(selected),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSm,
                        height: 1.3,
                      ),
                    ),
                    if (candidate.error != null) ...[
                      const SizedBox(height: AppTheme.space5),
                      Text(
                        candidate.error!,
                        style: TextStyle(
                          color: status.color,
                          fontSize: AppTheme.fontXs,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remover da fila',
                onPressed: provider.isBusy
                    ? null
                    : () => provider.removeCandidate(candidate.id),
                icon: const Icon(Icons.close_rounded, size: 19),
              ),
            ],
          ),
          if (candidate.suggestedNames.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space10),
            Wrap(
              spacing: AppTheme.space6,
              runSpacing: AppTheme.space6,
              children: candidate.suggestedNames
                  .map((name) {
                    return ActionChip(
                      label: Text(name),
                      onPressed: provider.isBusy
                          ? null
                          : () => provider.chooseSuggestedName(
                              candidate.id,
                              name,
                            ),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: AppTheme.space10),
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (candidate.status == BinderImportCandidateStatus.unresolved ||
                  candidate.status == BinderImportCandidateStatus.failed ||
                  candidate.status == BinderImportCandidateStatus.ambiguous)
                OutlinedButton.icon(
                  key: Key('binder-import-manual-search-${candidate.id}'),
                  onPressed: provider.isBusy ? null : onManualSearch,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Buscar carta'),
                ),
              if (candidate.printings.isNotEmpty)
                OutlinedButton.icon(
                  key: Key('binder-import-printing-${candidate.id}'),
                  onPressed: provider.isBusy ? null : onChoosePrinting,
                  icon: const Icon(Icons.style_outlined, size: 18),
                  label: Text(
                    selected == null
                        ? 'Escolher impressão'
                        : 'Trocar impressão',
                  ),
                ),
              _QuantityControl(candidate: candidate, provider: provider),
            ],
          ),
          if (selected != null) ...[
            const SizedBox(height: AppTheme.space10),
            Divider(color: AppTheme.outlineMuted.withValues(alpha: 0.65)),
            const SizedBox(height: AppTheme.space4),
            _PhysicalControls(candidate: candidate, provider: provider),
          ],
        ],
      ),
    );
  }
}

class _PhysicalControls extends StatelessWidget {
  const _PhysicalControls({required this.candidate, required this.provider});

  final BinderImportCandidate candidate;
  final BinderImportProvider provider;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.space10,
      runSpacing: AppTheme.space8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            key: Key('binder-import-condition-${candidate.id}'),
            initialValue: candidate.condition,
            decoration: const InputDecoration(
              labelText: 'Condição',
              isDense: true,
            ),
            items: const ['NM', 'LP', 'MP', 'HP', 'DMG']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(growable: false),
            onChanged: provider.isBusy
                ? null
                : (value) {
                    if (value != null) {
                      provider.updatePhysicalIdentity(
                        candidate.id,
                        condition: value,
                      );
                    }
                  },
          ),
        ),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            key: Key('binder-import-language-${candidate.id}'),
            initialValue: candidate.language,
            decoration: const InputDecoration(
              labelText: 'Idioma',
              isDense: true,
            ),
            items: const ['en', 'pt', 'pt-br', 'es', 'fr', 'de', 'it', 'ja']
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.toUpperCase()),
                  ),
                )
                .toList(growable: false),
            onChanged: provider.isBusy
                ? null
                : (value) {
                    if (value != null) {
                      provider.updatePhysicalIdentity(
                        candidate.id,
                        language: value,
                      );
                    }
                  },
          ),
        ),
        FilterChip(
          key: Key('binder-import-foil-${candidate.id}'),
          selected: candidate.isFoil,
          label: const Text('Foil físico'),
          avatar: const Icon(Icons.auto_awesome, size: 16),
          onSelected: provider.isBusy
              ? null
              : (value) => provider.updatePhysicalIdentity(
                  candidate.id,
                  isFoil: value,
                ),
        ),
      ],
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({required this.candidate, required this.provider});

  final BinderImportCandidate candidate;
  final BinderImportProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.touchTargetMin,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.outlineMuted),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Diminuir quantidade',
            onPressed: provider.isBusy || candidate.quantity <= 1
                ? null
                : () => provider.changeQuantity(candidate.id, -1),
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          Semantics(
            label: '${candidate.quantity} cópias',
            child: Text(
              '${candidate.quantity}',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Aumentar quantidade',
            onPressed: provider.isBusy
                ? null
                : () => provider.changeQuantity(candidate.id, 1),
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ImportActionBar extends StatelessWidget {
  const _ImportActionBar({
    required this.provider,
    required this.appliedCount,
    required this.onPreview,
    required this.onApply,
    required this.onRetry,
    required this.onFinish,
  });

  final BinderImportProvider provider;
  final int appliedCount;
  final VoidCallback? onPreview;
  final VoidCallback? onApply;
  final VoidCallback? onRetry;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final failed = provider.candidates
        .where(
          (candidate) => candidate.status == BinderImportCandidateStatus.failed,
        )
        .length;
    String status;
    if (provider.isApplying) {
      status = 'Aplicando cada identidade com proteção de retry…';
    } else if (provider.isPreviewing) {
      status = 'Comparando o lote com o Fichário atual…';
    } else if (appliedCount > 0 || failed > 0) {
      status = '$appliedCount concluída(s) • $failed para revisar';
    } else if (provider.plans.isNotEmpty) {
      final creates = provider.plans
          .where((plan) => plan.action == 'create')
          .length;
      final updates = provider.plans
          .where((plan) => plan.action == 'update')
          .length;
      status = '$creates criar • $updates atualizar';
    } else {
      status = '${provider.readyCount} pronta(s) para o plano';
    }

    return Material(
      key: const Key('binder-import-action-bar'),
      color: AppTheme.surfaceElevated,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppTheme.space12,
            AppTheme.space10,
            AppTheme.space12,
            AppTheme.space10 + safeBottom * 0,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSm,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space10),
                  if (onRetry != null && provider.plans.isNotEmpty)
                    FilledButton.icon(
                      key: const Key('binder-import-retry-button'),
                      onPressed: provider.isBusy ? null : onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Revisar falhas'),
                    )
                  else if (provider.plans.isNotEmpty && onApply != null)
                    FilledButton.icon(
                      key: const Key('binder-import-apply-button'),
                      onPressed: onApply,
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Aplicar lote'),
                    )
                  else if (onFinish != null)
                    FilledButton.icon(
                      key: const Key('binder-import-finish-button'),
                      onPressed: onFinish,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Voltar ao Fichário'),
                    )
                  else
                    FilledButton.icon(
                      key: const Key('binder-import-preview-button'),
                      onPressed: onPreview,
                      icon: const Icon(Icons.compare_arrows_rounded),
                      label: const Text('Revisar plano'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityStrip extends StatelessWidget {
  const _AvailabilityStrip({required this.summary});

  final BinderImportAvailability summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('binder-import-availability-summary'),
      padding: const EdgeInsets.all(AppTheme.space10),
      decoration: BoxDecoration(
        color: AppTheme.frost400.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.24)),
      ),
      child: Wrap(
        spacing: AppTheme.space16,
        runSpacing: AppTheme.space8,
        children: [
          _SummaryValue(label: 'Tenho', value: summary.ownedQuantity),
          _SummaryValue(label: 'Alocadas', value: summary.allocatedQuantity),
          _SummaryValue(label: 'Livres', value: summary.freeQuantity),
          _SummaryValue(
            label: 'Em troca',
            value: summary.committedTradeQuantity,
          ),
          _SummaryValue(label: 'Faltam', value: summary.missingQuantity),
        ],
      ),
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plans});

  final List<BinderImportPlan> plans;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('binder-import-plan-summary'),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plano antes de persistir',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          ...plans.map((plan) {
            final label = switch (plan.status) {
              'created' => 'Criado',
              'updated' => 'Atualizado',
              'unchanged' => 'Já aplicado',
              'failed' || 'rejected' => 'Revisar',
              _ => plan.action == 'create' ? 'Criar' : 'Atualizar',
            };
            final color = switch (plan.status) {
              'failed' || 'rejected' => AppTheme.error,
              'created' || 'updated' || 'unchanged' => AppTheme.success,
              _ => AppTheme.brass400,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space6),
              child: Row(
                children: [
                  _StatusChip(label: label, color: color),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      '${plan.card['name'] ?? 'Carta'} • ${plan.quantity} '
                      '(${plan.baselineQuantity ?? 0} → ${plan.targetQuantity ?? '?'})',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSm,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InvalidLinesPanel extends StatelessWidget {
  const _InvalidLinesPanel({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return _InlineNotice(
      key: const Key('binder-import-invalid-lines'),
      icon: Icons.rule_folder_outlined,
      color: AppTheme.warning,
      message:
          '${lines.length} linha(s) não foram lidas e ficarão fora do lote:\n${lines.take(3).join('\n')}',
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.history});

  final List<BinderImportBatchHistory> history;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: const Key('binder-import-history'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: const Text(
        'Histórico neste dispositivo',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: AppTheme.fontSm,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        '${history.length} ${history.length == 1 ? 'lote salvo' : 'lotes salvos'}',
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      children: history
          .take(3)
          .map((entry) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                entry.totalFailed > 0
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: entry.totalFailed > 0
                    ? AppTheme.warning
                    : AppTheme.success,
              ),
              title: Text(
                '${entry.totalApplied} aplicada(s) • ${entry.totalFailed} falha(s)',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                _dateTimeLabel(entry.createdAt),
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: AppTheme.fontSm,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space8,
          vertical: AppTheme.space5,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$value',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space7,
        vertical: AppTheme.space3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Text.rich(
        TextSpan(
          text: '$value ',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

({String label, Color color}) _candidateStatus(
  BinderImportCandidate candidate,
) {
  if (candidate.status == BinderImportCandidateStatus.applied) {
    return switch (candidate.applicationStatus) {
      'created' => (label: 'Criada', color: AppTheme.success),
      'updated' => (label: 'Atualizada', color: AppTheme.success),
      _ => (label: 'Já aplicada', color: AppTheme.success),
    };
  }
  return switch (candidate.status) {
    BinderImportCandidateStatus.resolving => (
      label: 'Resolvendo',
      color: AppTheme.frost400,
    ),
    BinderImportCandidateStatus.needsPrinting => (
      label: 'Escolher impressão',
      color: AppTheme.brass400,
    ),
    BinderImportCandidateStatus.ambiguous => (
      label: 'Nome ambíguo',
      color: AppTheme.warning,
    ),
    BinderImportCandidateStatus.unresolved => (
      label: 'Não encontrada',
      color: AppTheme.error,
    ),
    BinderImportCandidateStatus.ready => (
      label: 'Pronta',
      color: AppTheme.success,
    ),
    BinderImportCandidateStatus.failed => (
      label: 'Retry necessário',
      color: AppTheme.error,
    ),
    BinderImportCandidateStatus.applied => (
      label: 'Aplicada',
      color: AppTheme.success,
    ),
  };
}

String _sourceHint(BinderImportCandidate candidate) {
  final parts = <String>[
    candidate.requestedName,
    if (candidate.requestedSetCode != null)
      candidate.requestedSetCode!.toUpperCase(),
    if (candidate.requestedCollectorNumber != null)
      '#${candidate.requestedCollectorNumber}',
  ];
  return 'Entrada: ${parts.join(' • ')}';
}

Map<String, dynamic> _printingFromCard(DeckCardItem card) => {
  'id': card.id,
  'oracle_id': card.oracleId,
  'name': card.name,
  'image_url': card.imageUrl,
  'layout': card.layout,
  'card_faces': card.cardFaces
      .map((face) => {'name': face.name, 'image_url': face.imageUrl})
      .toList(growable: false),
  'set_code': card.setCode,
  'set_name': card.setName,
  'set_release_date': card.setReleaseDate,
  'collector_number': card.collectorNumber,
  'foil': card.foil,
  'mana_cost': card.manaCost,
  'type_line': card.typeLine,
  'rarity': card.rarity,
};

String _dateTimeLabel(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
