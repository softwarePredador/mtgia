import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/scryfall_image_helper.dart';
import '../../../core/widgets/card_artwork.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../models/deck_details.dart';
import '../models/deck_optimization_event.dart';

class DeckWorkshopTab extends StatefulWidget {
  const DeckWorkshopTab({
    super.key,
    required this.deck,
    required this.events,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onOptimize,
    required this.onValidate,
    required this.onRollback,
    required this.onOpenSampleHand,
    required this.onOpenBattle,
  });

  final DeckDetails deck;
  final List<DeckOptimizationEvent> events;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onOptimize;
  final VoidCallback onValidate;
  final Future<void> Function(DeckOptimizationEvent event) onRollback;
  final VoidCallback onOpenSampleHand;
  final VoidCallback onOpenBattle;

  @override
  State<DeckWorkshopTab> createState() => _DeckWorkshopTabState();
}

class _DeckWorkshopTabState extends State<DeckWorkshopTab> {
  String? _rollingBackEventId;
  String? _actionError;

  Future<void> _rollback(DeckOptimizationEvent event) async {
    if (_rollingBackEventId != null) return;
    setState(() {
      _rollingBackEventId = event.id;
      _actionError = null;
    });
    try {
      await widget.onRollback(event);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _actionError = error.toString().replaceFirst(
          RegExp(r'^Exception:\s*'),
          '',
        );
      });
    } finally {
      if (mounted) setState(() => _rollingBackEventId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: CustomScrollView(
            key: const Key('deck-workshop-tab'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  AppTheme.space16,
                  AppTheme.space16,
                  AppTheme.space0,
                ),
                sliver: SliverList.list(
                  children: [
                    _WorkshopHero(
                      deck: widget.deck,
                      onOptimize: widget.onOptimize,
                      onValidate: widget.onValidate,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    const _WorkshopDecisionRail(),
                    const SizedBox(height: AppTheme.space24),
                    _HistoryHeader(onRefresh: widget.onRefresh),
                    if (_actionError != null) ...[
                      const SizedBox(height: AppTheme.space10),
                      _WorkshopInlineError(message: _actionError!),
                    ],
                    if (widget.errorMessage != null) ...[
                      const SizedBox(height: AppTheme.space10),
                      _WorkshopInlineError(
                        message: widget.errorMessage!,
                        onRetry: widget.onRefresh,
                      ),
                    ],
                    const SizedBox(height: AppTheme.space12),
                    if (widget.isLoading && widget.events.isEmpty)
                      const _WorkshopHistoryLoading()
                    else if (widget.events.isEmpty)
                      _WorkshopEmptyHistory(onOptimize: widget.onOptimize)
                    else
                      for (var index = 0; index < widget.events.length; index++)
                        _WorkshopHistoryEvent(
                          event: widget.events[index],
                          isLast: index == widget.events.length - 1,
                          isRollingBack:
                              _rollingBackEventId == widget.events[index].id,
                          onRollback: () => _rollback(widget.events[index]),
                        ),
                    const SizedBox(height: AppTheme.space20),
                    _WorkshopNextStep(
                      onOpenSampleHand: widget.onOpenSampleHand,
                      onOpenBattle: widget.onOpenBattle,
                    ),
                    const SizedBox(height: AppTheme.space112),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkshopHero extends StatelessWidget {
  const _WorkshopHero({
    required this.deck,
    required this.onOptimize,
    required this.onValidate,
  });

  final DeckDetails deck;
  final VoidCallback onOptimize;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commander = deck.commander.isEmpty ? null : deck.commander.first;
    final commanderName = commander?.name ?? deck.commanderName?.trim() ?? '';
    final artwork = commander?.printingImageUrl ?? deck.commanderImageUrl;
    final fallback =
        commander?.fallbackImageUrl ??
        ScryfallImageHelper.namedImageUrl(commanderName);
    final totalCards = deck.stats['total_cards'] ?? deck.cardCount ?? 0;
    final validationOk = deck.validationState == 'validated';

    Widget copy() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OFICINA · ${deck.format.toUpperCase()}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.brass400,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppTheme.space7),
        Text(
          commanderName.isEmpty ? deck.name : commanderName,
          key: const Key('deck-workshop-commander-name'),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: AppTheme.space7),
        Text(
          (deck.archetype?.trim().isNotEmpty ?? false)
              ? deck.archetype!.trim()
              : 'Defina o plano, revise cada troca e valide em jogo.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Wrap(
          spacing: AppTheme.space7,
          runSpacing: AppTheme.space7,
          children: [
            _WorkshopChip(
              label: '$totalCards cartas',
              icon: Icons.style_outlined,
              color: AppTheme.frost400,
            ),
            if (deck.bracket != null)
              _WorkshopChip(
                label: 'Bracket ${deck.bracket}',
                icon: Icons.shield_outlined,
                color: AppTheme.brass400,
              ),
            _WorkshopChip(
              label: validationOk ? 'Legalidade validada' : 'Revisão pendente',
              icon: validationOk
                  ? Icons.verified_outlined
                  : Icons.fact_check_outlined,
              color: validationOk ? AppTheme.success : AppTheme.warning,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space16),
        Wrap(
          spacing: AppTheme.space8,
          runSpacing: AppTheme.space8,
          children: [
            ElevatedButton.icon(
              key: const Key('deck-workshop-optimize-button'),
              onPressed: onOptimize,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Montar proposta'),
            ),
            OutlinedButton.icon(
              key: const Key('deck-workshop-validate-button'),
              onPressed: onValidate,
              icon: const Icon(Icons.rule_rounded),
              label: const Text('Validar agora'),
            ),
          ],
        ),
      ],
    );

    return Container(
      key: const Key('deck-workshop-hero'),
      padding: const EdgeInsets.all(AppTheme.space18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.34)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceElevated,
            AppTheme.brass400.withValues(alpha: 0.045),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final artworkWidget = SizedBox(
            key: const Key('deck-workshop-commander-art-frame'),
            width: constraints.maxWidth >= 720 ? 130 : 92,
            height: constraints.maxWidth >= 720 ? 181 : 128,
            child: CardArtwork(
              variant: CardArtworkVariant.fullCard,
              imageUrl: artwork,
              fallbackImageUrl: fallback,
              semanticLabel: commanderName.isEmpty
                  ? 'Espaço visual do comandante'
                  : 'Comandante da oficina $commanderName',
              imageIsReference:
                  artwork == null || artwork.toString().trim().isEmpty,
              constrainAspectRatio: false,
            ),
          );
          if (constraints.maxWidth >= 720) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                artworkWidget,
                const SizedBox(width: AppTheme.space20),
                Expanded(child: copy()),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: copy()),
              const SizedBox(width: AppTheme.space12),
              artworkWidget,
            ],
          );
        },
      ),
    );
  }
}

class _WorkshopDecisionRail extends StatelessWidget {
  const _WorkshopDecisionRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('deck-workshop-decision-rail'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space14,
        vertical: AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.45),
        ),
      ),
      child: const Wrap(
        spacing: AppTheme.space8,
        runSpacing: AppTheme.space8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _WorkshopStep(number: '1', label: 'Objetivo'),
          _WorkshopRailArrow(),
          _WorkshopStep(number: '2', label: 'Trocas pareadas'),
          _WorkshopRailArrow(),
          _WorkshopStep(number: '3', label: 'Validação'),
          _WorkshopRailArrow(),
          _WorkshopStep(number: '4', label: 'Teste em jogo'),
        ],
      ),
    );
  }
}

class _WorkshopStep extends StatelessWidget {
  const _WorkshopStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.brass400.withValues(alpha: 0.12),
            border: Border.all(
              color: AppTheme.brass400.withValues(alpha: 0.42),
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppTheme.brass400,
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space5),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: AppTheme.fontSm,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WorkshopRailArrow extends StatelessWidget {
  const _WorkshopRailArrow();

  @override
  Widget build(BuildContext context) => const Icon(
    Icons.arrow_forward_rounded,
    size: 16,
    color: AppTheme.textSecondary,
  );
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Histórico da oficina',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppTheme.space3),
              const Text(
                'Aplicações e restaurações registradas pelo servidor.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('deck-workshop-refresh-history'),
          tooltip: 'Atualizar histórico',
          onPressed: () => onRefresh(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _WorkshopHistoryEvent extends StatelessWidget {
  const _WorkshopHistoryEvent({
    required this.event,
    required this.isLast,
    required this.isRollingBack,
    required this.onRollback,
  });

  final DeckOptimizationEvent event;
  final bool isLast;
  final bool isRollingBack;
  final VoidCallback onRollback;

  String get _title => event.isRollback ? 'Deck restaurado' : 'Plano aplicado';

  String get _rollbackCopy => switch (event.rollbackReason) {
    'already_rolled_back' => 'Esta aplicação já foi desfeita.',
    'snapshot_unavailable' => 'Este registro antigo não possui snapshot.',
    'deck_changed_after_apply' =>
      'O deck mudou depois desta aplicação; o servidor protege as edições mais novas.',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final accent = event.isRollback ? AppTheme.frost400 : AppTheme.brass400;
    return IntrinsicHeight(
      child: Row(
        key: Key('deck-workshop-event-${event.id}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: AppTheme.space16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: AppTheme.outlineMuted.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppTheme.space12),
              padding: const EdgeInsets.all(AppTheme.space14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.outlineMuted.withValues(alpha: 0.55),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        event.isRollback
                            ? Icons.history_rounded
                            : Icons.auto_awesome_rounded,
                        color: accent,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.space2),
                            Text(
                              _eventSubtitle(event),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontSm,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _eventDate(event.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontSm,
                        ),
                      ),
                    ],
                  ),
                  if (event.isApply && event.pairCount > 0) ...[
                    const SizedBox(height: AppTheme.space12),
                    for (
                      var index = 0;
                      index < (event.pairCount > 3 ? 3 : event.pairCount);
                      index++
                    )
                      _HistorySwapPair(
                        index: index,
                        removal: event.removals[index],
                        addition: event.additions[index],
                      ),
                  ],
                  const SizedBox(height: AppTheme.space10),
                  Wrap(
                    spacing: AppTheme.space7,
                    runSpacing: AppTheme.space7,
                    children: [
                      if (event.validationStatus.isNotEmpty)
                        _WorkshopChip(
                          label: _validationLabel(event.validationStatus),
                          icon: Icons.rule_rounded,
                          color: _validationColor(event.validationStatus),
                        ),
                      _WorkshopChip(
                        label: _sourceLabel(event),
                        icon: Icons.source_outlined,
                        color: AppTheme.frost400,
                      ),
                      if (event.battleStatus.isNotEmpty)
                        _WorkshopChip(
                          label: _battleLabel(event.battleStatus),
                          icon: Icons.sports_esports_outlined,
                          color: AppTheme.textSecondary,
                        ),
                    ],
                  ),
                  if (event.canRollback) ...[
                    const SizedBox(height: AppTheme.space12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        key: Key('deck-workshop-undo-${event.id}'),
                        onPressed: isRollingBack ? null : onRollback,
                        icon: isRollingBack
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.undo_rounded),
                        label: Text(
                          isRollingBack
                              ? 'Restaurando...'
                              : 'Desfazer aplicação',
                        ),
                      ),
                    ),
                  ] else if (_rollbackCopy.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.space10),
                    Text(
                      _rollbackCopy,
                      key: Key('deck-workshop-rollback-reason-${event.id}'),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSm,
                        height: AppTheme.lineHeightCompact,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySwapPair extends StatelessWidget {
  const _HistorySwapPair({
    required this.index,
    required this.removal,
    required this.addition,
  });

  final int index;
  final Map<String, dynamic> removal;
  final Map<String, dynamic> addition;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('deck-workshop-history-pair-$index'),
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      padding: const EdgeInsets.all(AppTheme.space8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HistoryCardRef(
              item: removal,
              label: 'SAI',
              color: AppTheme.error,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.space7),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: AppTheme.brass400,
              size: 20,
            ),
          ),
          Expanded(
            child: _HistoryCardRef(
              item: addition,
              label: 'ENTRA',
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCardRef extends StatelessWidget {
  const _HistoryCardRef({
    required this.item,
    required this.label,
    required this.color,
  });

  final Map<String, dynamic> item;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString().trim() ?? '';
    return Row(
      children: [
        SizedBox(
          width: 34,
          height: 48,
          child: CardArtwork(
            variant: CardArtworkVariant.recentDeck,
            imageUrl: item['image_url']?.toString(),
            fallbackImageUrl: ScryfallImageHelper.namedImageUrl(name),
            semanticLabel: '$label $name',
            constrainAspectRatio: false,
            showStatusBadge: false,
          ),
        ),
        const SizedBox(width: AppTheme.space7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: AppTheme.space2),
              Text(
                name.isEmpty ? 'Carta não registrada' : name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkshopNextStep extends StatelessWidget {
  const _WorkshopNextStep({
    required this.onOpenSampleHand,
    required this.onOpenBattle,
  });

  final VoidCallback onOpenSampleHand;
  final VoidCallback onOpenBattle;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('deck-workshop-test-next-step'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.frost400.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ManaLoomGlyph(
            ManaLoomGlyphKind.battleReplay,
            color: AppTheme.frost400,
            size: 26,
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A proposta só termina na mesa',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                const Text(
                  'Mão inicial ajuda a enxergar a curva. Battle e replays produzem evidência de desempenho; a IA não declara um deck “ideal”.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    height: AppTheme.lineHeightCompact,
                  ),
                ),
                const SizedBox(height: AppTheme.space10),
                Wrap(
                  spacing: AppTheme.space8,
                  runSpacing: AppTheme.space8,
                  children: [
                    TextButton.icon(
                      onPressed: onOpenSampleHand,
                      icon: const Icon(Icons.back_hand_outlined),
                      label: const Text('Testar mão inicial'),
                    ),
                    TextButton.icon(
                      onPressed: onOpenBattle,
                      icon: const Icon(Icons.sports_esports_outlined),
                      label: const Text('Abrir Battle / replays'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkshopEmptyHistory extends StatelessWidget {
  const _WorkshopEmptyHistory({required this.onOptimize});

  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('deck-workshop-empty-history'),
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_motion_outlined,
            size: 34,
            color: AppTheme.brass400,
          ),
          const SizedBox(height: AppTheme.space10),
          Text(
            'Nenhuma mudança aplicada ainda',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.space5),
          const Text(
            'Monte uma proposta, escolha as trocas e o primeiro registro aparecerá aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.space12),
          OutlinedButton.icon(
            onPressed: onOptimize,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Começar proposta'),
          ),
        ],
      ),
    );
  }
}

class _WorkshopHistoryLoading extends StatelessWidget {
  const _WorkshopHistoryLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppTheme.space24),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _WorkshopInlineError extends StatelessWidget {
  const _WorkshopInlineError({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('deck-workshop-inline-error'),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () => onRetry!(),
              child: const Text('Tentar'),
            ),
        ],
      ),
    );
  }
}

class _WorkshopChip extends StatelessWidget {
  const _WorkshopChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppTheme.space4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontSm,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _eventSubtitle(DeckOptimizationEvent event) {
  final parts = <String>[
    if (event.archetype.trim().isNotEmpty) event.archetype.trim(),
    if (event.bracket != null) 'Bracket ${event.bracket}',
    if (event.selectedChangeCount > 0)
      '${event.selectedChangeCount} mudanças registradas',
  ];
  return parts.isEmpty ? 'Registro seguro do servidor' : parts.join(' · ');
}

String _eventDate(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)} · ${two(local.hour)}:${two(local.minute)}';
}

String _validationLabel(String status) => switch (status.toLowerCase()) {
  'validated' || 'valid' || 'passed' => 'Legalidade validada',
  'draft' || 'failed' || 'invalid' => 'Revisão necessária',
  _ => 'Validação registrada',
};

Color _validationColor(String status) => switch (status.toLowerCase()) {
  'validated' || 'valid' || 'passed' => AppTheme.success,
  'draft' || 'failed' || 'invalid' => AppTheme.warning,
  _ => AppTheme.textSecondary,
};

String _battleLabel(String status) => switch (status.toLowerCase()) {
  'validated' || 'passed' => 'Battle validado',
  'invalidated_by_rollback' => 'Battle invalidado pelo rollback',
  _ => 'Teste em jogo pendente',
};

String _sourceLabel(DeckOptimizationEvent event) {
  final summary = event.sourceSummary;
  final count = summary['reference_count'];
  if (summary['has_meta_reference'] == true) {
    return count is int && count > 0
        ? '$count referências externas'
        : 'Referência externa registrada';
  }
  final source = summary['post_analysis_source']?.toString().trim() ?? '';
  if (source == 'server_recomputed_from_persisted_selection') {
    return 'Análise recalculada pelo servidor';
  }
  return 'Sem referência externa registrada';
}
