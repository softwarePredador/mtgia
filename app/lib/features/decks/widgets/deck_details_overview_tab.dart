import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/scryfall_image_helper.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../models/deck_card_item.dart';
import '../models/deck_analysis.dart';
import '../models/deck_details.dart';
import 'deck_details_aux_widgets.dart';
import 'deck_diagnostic_panel.dart';
import 'deck_ui_components.dart';
import 'sample_hand_widget.dart';

class DeckDetailsOverviewTab extends StatelessWidget {
  final String deckId;
  final DeckDetails deck;
  final int totalCards;
  final int? maxCards;
  final bool isCommanderFormat;
  final bool isValidating;
  final bool isPricingLoading;
  final Map<String, dynamic>? validationResult;
  final Map<String, dynamic>? pricing;
  final DeckAnalysisData? diagnosticAnalysis;
  final bool Function(DeckCardItem card) isCardInvalid;
  final String Function(int bracket) bracketLabel;
  final VoidCallback onValidateNow;
  final VoidCallback onValidationTap;
  final VoidCallback onOpenCards;
  final VoidCallback onForcePricingRefresh;
  final VoidCallback onShowPricingDetails;
  final VoidCallback onTogglePublic;
  final VoidCallback onPlay;
  final VoidCallback onShowOptimizationOptions;
  final VoidCallback? onOpenBattleReplays;
  final VoidCallback onSelectCommander;
  final VoidCallback onImportList;
  final ValueChanged<String?> onEditDescription;
  final ValueChanged<DeckCardItem> onShowCardDetails;

  const DeckDetailsOverviewTab({
    super.key,
    required this.deckId,
    required this.deck,
    required this.totalCards,
    required this.maxCards,
    required this.isCommanderFormat,
    required this.isValidating,
    required this.isPricingLoading,
    required this.validationResult,
    required this.pricing,
    this.diagnosticAnalysis,
    required this.isCardInvalid,
    required this.bracketLabel,
    required this.onValidateNow,
    required this.onValidationTap,
    required this.onOpenCards,
    required this.onForcePricingRefresh,
    required this.onShowPricingDetails,
    required this.onTogglePublic,
    required this.onPlay,
    required this.onShowOptimizationOptions,
    this.onOpenBattleReplays,
    required this.onSelectCommander,
    required this.onImportList,
    required this.onEditDescription,
    required this.onShowCardDetails,
  });

  bool get _hasArchetype =>
      deck.archetype != null && deck.archetype!.trim().isNotEmpty;

  bool get _isEmptyDeck => totalCards == 0;

  String get _effectiveValidationState {
    final liveState = validationResult?['deck_state']?.toString();
    if (liveState == 'validated' || liveState == 'draft') return liveState!;
    return deck.validationState;
  }

  String get _validationStateLabel {
    if (_effectiveValidationState == 'validated') return 'Validado';
    if (_effectiveValidationState == 'draft') return 'Rascunho';
    return 'A validar';
  }

  Color get _validationStateColor {
    if (_effectiveValidationState == 'validated') return AppTheme.success;
    if (_effectiveValidationState == 'draft') return AppTheme.warning;
    return AppTheme.brass400;
  }

  IconData get _validationStateIcon => _effectiveValidationState == 'validated'
      ? Icons.verified_outlined
      : Icons.rule_outlined;

  DeckCardItem? get _heroCommander =>
      deck.commander.isNotEmpty ? deck.commander.first : null;

  String? get _heroCommanderImageUrl {
    final imageUrl = _heroCommander?.imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    return imageUrl;
  }

  String? get _heroCommanderArtUrl {
    return ScryfallImageHelper.preferredImageUrl(
      explicitUrl: _heroCommanderImageUrl,
      cardName: _heroCommander?.name,
      version: 'art_crop',
    );
  }

  String get _heroSummary {
    final parts = <String>['$totalCards cartas'];
    if (deck.bracket != null) {
      parts.add('Bracket ${deck.bracket}');
    }
    if (_hasArchetype) {
      parts.add(deck.archetype!);
    }
    return parts.join(' • ');
  }

  Color _formatAccentColor(String format) {
    switch (format.toLowerCase()) {
      case 'commander':
      case 'brawl':
        return AppTheme.formatCommander;
      case 'standard':
        return AppTheme.formatStandard;
      case 'modern':
        return AppTheme.formatModern;
      case 'pioneer':
        return AppTheme.formatPioneer;
      case 'legacy':
        return AppTheme.formatLegacy;
      case 'vintage':
        return AppTheme.formatVintage;
      case 'pauper':
        return AppTheme.formatPauper;
      default:
        return AppTheme.brass500;
    }
  }

  Widget _buildHero(BuildContext context, {required Color formatAccent}) {
    final theme = Theme.of(context);
    final artUrl = _heroCommanderArtUrl;
    final hasArtwork = artUrl != null || _heroCommanderImageUrl != null;

    return Container(
      key: const Key('deck-overview-hero'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 176),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: hasArtwork
              ? formatAccent.withValues(alpha: 0.46)
              : AppTheme.outlineMuted.withValues(alpha: 0.78),
          width: AppTheme.strokeRegular,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Stack(
          children: [
            if (hasArtwork)
              Positioned.fill(
                child: Row(
                  children: [
                    const Spacer(flex: 5),
                    Expanded(
                      flex: 4,
                      child: CachedCardImage(
                        imageUrl: artUrl ?? _heroCommanderImageUrl,
                        fallbackImageUrl: _heroCommander?.fallbackImageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.backgroundAbyss,
                      AppTheme.backgroundAbyss.withValues(alpha: 0.96),
                      AppTheme.surfaceElevated.withValues(
                        alpha: hasArtwork ? 0.38 : 1,
                      ),
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    if (_heroCommander != null) ...[
                      const SizedBox(height: AppTheme.space7),
                      Text(
                        'Comandante: ${_heroCommander!.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.space6),
                    Text(
                      _heroSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DeckMetaChip(
                          label: deck.format.toUpperCase(),
                          color: formatAccent,
                          icon: Icons.style_outlined,
                          prominent: true,
                        ),
                        if (deck.colorIdentityKnown)
                          ColorIdentityPips(
                            colors: deck.colorIdentity,
                            colorlessWhenEmpty: true,
                          ),
                        if (isValidating)
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        DeckMetaChip(
                          key: const Key('deck-review-state-chip'),
                          label: _validationStateLabel,
                          color: _validationStateColor,
                          icon: _validationStateIcon,
                          prominent: true,
                        ),
                        DeckMetaChip(
                          onTap: onTogglePublic,
                          label: deck.isPublic ? 'Público' : 'Privado',
                          color: deck.isPublic
                              ? AppTheme.frost400
                              : AppTheme.textPrimary.withValues(alpha: 0.86),
                          icon: deck.isPublic
                              ? Icons.public
                              : Icons.lock_outline,
                          prominent: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatAccent = _formatAccentColor(deck.format);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopPanes =
            constraints.maxWidth >= AppTheme.breakpointExpanded;
        final gutter = constraints.maxWidth < AppTheme.breakpointCompact
            ? AppTheme.pageGutterCompact
            : AppTheme.pageGutter;

        final strategy = _StrategySummaryCard(
          hasArchetype: _hasArchetype,
          archetype: deck.archetype,
          bracket: deck.bracket,
          bracketLabel: bracketLabel,
          onTap: onShowOptimizationOptions,
        );
        final commander = deck.commander.isEmpty
            ? null
            : _CommanderSection(
                commander: deck.commander,
                isCardInvalid: isCardInvalid,
                onShowCardDetails: onShowCardDetails,
                onChangeCommander: () =>
                    context.go('/decks/$deckId/search?mode=commander'),
              );
        final description = _DescriptionSection(
          description: deck.description,
          onEditDescription: onEditDescription,
        );
        final diagnostics = DeckDiagnosticPanel(
          deck: deck,
          analysis: diagnosticAnalysis,
          onOpenBattleReplays: onOpenBattleReplays,
          onShowCardDetails: onShowCardDetails,
        );
        final playtest = SampleHandWidget(
          deck: deck,
          compact: true,
          onShowCardDetails: onShowCardDetails,
        );
        final pricingPanel = DeckPricingRow(
          pricing: pricing,
          isLoading: isPricingLoading,
          onForceRefresh: onForcePricingRefresh,
          onShowDetails: onShowPricingDetails,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            gutter,
            gutter,
            gutter,
            AppTheme.space32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(context, formatAccent: formatAccent),
                  const SizedBox(height: AppTheme.space14),
                  if (_isEmptyDeck) ...[
                    _DeckEmptyState(
                      isCommanderFormat: isCommanderFormat,
                      onSelectCommander: onSelectCommander,
                      onOpenCards: onOpenCards,
                      onImportList: onImportList,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      'Depois que o deck ganhar base, os diagnósticos e recomendações aparecem aqui.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimary.withValues(alpha: 0.76),
                      ),
                    ),
                  ] else ...[
                    _OverviewQuickActions(
                      onPlay: onPlay,
                      onOptimize: onShowOptimizationOptions,
                    ),
                    const SizedBox(height: AppTheme.space14),
                    _CommanderDeckSummaryGrid(
                      deck: deck,
                      totalCards: totalCards,
                      maxCards: maxCards,
                      hasCommander: deck.commander.isNotEmpty,
                      pricing: pricing,
                    ),
                    const SizedBox(height: AppTheme.space14),
                    _LegalityConfidenceCard(
                      isCommanderFormat: isCommanderFormat,
                      isValidating: isValidating,
                      validationResult: validationResult,
                      totalCards: totalCards,
                      maxCards: maxCards,
                      hasCommander: deck.commander.isNotEmpty,
                      onValidateNow: onValidateNow,
                      onValidationTap: onValidationTap,
                      onOpenCards: onOpenCards,
                      onSelectCommander: onSelectCommander,
                    ),
                    if (isCommanderFormat && deck.commander.isEmpty) ...[
                      const SizedBox(height: AppTheme.space14),
                      _CommanderPrompt(onSelectCommander: onSelectCommander),
                    ],
                    const SizedBox(height: AppTheme.paneGap),
                    if (useDesktopPanes)
                      Row(
                        key: const Key('deck-overview-desktop-panes'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: KeyedSubtree(
                              key: const Key('deck-overview-primary-pane'),
                              child: Column(
                                children: [
                                  diagnostics,
                                  const SizedBox(height: AppTheme.paneGap),
                                  playtest,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.paneGap),
                          SizedBox(
                            key: const Key('deck-overview-inspector-pane'),
                            width: AppTheme.inspectorWidth,
                            child: Column(
                              children: [
                                strategy,
                                if (commander != null) ...[
                                  const SizedBox(height: AppTheme.space14),
                                  commander,
                                ],
                                const SizedBox(height: AppTheme.space14),
                                description,
                                const SizedBox(height: AppTheme.space14),
                                pricingPanel,
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      strategy,
                      if (commander != null) ...[
                        const SizedBox(height: AppTheme.space16),
                        commander,
                      ],
                      const SizedBox(height: AppTheme.space16),
                      description,
                      const SizedBox(height: AppTheme.space16),
                      diagnostics,
                      const SizedBox(height: AppTheme.space16),
                      playtest,
                      const SizedBox(height: AppTheme.space24),
                      pricingPanel,
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CommanderSection extends StatelessWidget {
  final List<DeckCardItem> commander;
  final bool Function(DeckCardItem card) isCardInvalid;
  final ValueChanged<DeckCardItem> onShowCardDetails;
  final VoidCallback onChangeCommander;

  const _CommanderSection({
    required this.commander,
    required this.isCardInvalid,
    required this.onShowCardDetails,
    required this.onChangeCommander,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Comandante', style: theme.textTheme.titleMedium),
            ),
            TextButton.icon(
              onPressed: onChangeCommander,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Trocar'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        ...commander.map(
          (card) => InkWell(
            onTap: () => onShowCardDetails(card),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isCardInvalid(card)
                      ? theme.colorScheme.error.withValues(alpha: 0.32)
                      : AppTheme.outlineMuted.withValues(alpha: 0.65),
                  width: isCardInvalid(card) ? 1.2 : 0.9,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: CachedCardImage(
                      imageUrl: card.effectiveImageUrl,
                      fallbackImageUrl: card.fallbackImageUrl,
                      width: 52,
                      height: 72,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          card.typeLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.92,
                            ),
                            height: 1.25,
                          ),
                        ),
                        if (isCardInvalid(card)) ...[
                          const SizedBox(height: AppTheme.space8),
                          _InlineCommanderBadge(
                            label: 'Inválida',
                            color: theme.colorScheme.error,
                            icon: Icons.warning_amber_rounded,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommanderDeckSummaryGrid extends StatelessWidget {
  final DeckDetails deck;
  final int totalCards;
  final int? maxCards;
  final bool hasCommander;
  final Map<String, dynamic>? pricing;

  const _CommanderDeckSummaryGrid({
    required this.deck,
    required this.totalCards,
    required this.maxCards,
    required this.hasCommander,
    required this.pricing,
  });

  String get _identityLabel {
    if (deck.colorIdentity.isNotEmpty) return '';
    return deck.colorIdentityKnown ? 'Incolor' : 'Pendente';
  }

  String get _countLabel =>
      maxCards == null ? '$totalCards cartas' : '$totalCards/$maxCards cartas';

  String get _priceLabel {
    final rawTotal = pricing?['estimated_total_usd'] ?? deck.pricingTotal;
    final total = rawTotal is num ? rawTotal.toDouble() : null;
    if (total == null) return 'Pendente';
    final currency =
        pricing?['currency']?.toString() ?? deck.pricingCurrency ?? 'USD';
    return CurrencyFormatter.format(
      total,
      currencyCode: currency,
      compact: true,
    );
  }

  String get _curveLabel {
    final raw =
        deck.stats['average_cmc'] ??
        deck.stats['avg_cmc'] ??
        deck.stats['average_mana_value'];
    final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
    if (value == null) return 'Aba Análise';
    return 'CMC ${value.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final cardsOk = maxCards == null || totalCards == maxCards;
    final commanderOk = !isCommanderFormat(deck.format) || hasCommander;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 680 ? 2 : 4;
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _SummaryTile(
                label: 'Commander',
                value: hasCommander ? 'Definido' : 'Ausente',
                iconWidget: const ManaLoomGlyph(ManaLoomGlyphKind.commander),
                accent: commanderOk ? AppTheme.success : AppTheme.warning,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _SummaryTile(
                label: 'Identidade',
                value: _identityLabel,
                valueWidget: deck.colorIdentityKnown
                    ? ColorIdentityPips(
                        colors: deck.colorIdentity,
                        symbolSize: 17,
                        spacing: 3,
                        decorated: false,
                        colorlessWhenEmpty: true,
                      )
                    : null,
                icon: Icons.palette_outlined,
                accent: AppTheme.identityColor(deck.colorIdentity.toSet()),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _SummaryTile(
                label: 'Contagem',
                value: _countLabel,
                icon: Icons.format_list_numbered,
                accent: cardsOk ? AppTheme.success : AppTheme.frost400,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _SummaryTile(
                label: _priceLabel == 'Pendente' ? 'Curva' : 'Preço',
                value: _priceLabel == 'Pendente' ? _curveLabel : _priceLabel,
                icon: _priceLabel == 'Pendente'
                    ? Icons.show_chart_rounded
                    : Icons.attach_money_rounded,
                accent: AppTheme.mythicGold,
              ),
            ),
          ],
        );
      },
    );
  }
}

bool isCommanderFormat(String format) {
  final normalized = format.toLowerCase();
  return normalized == 'commander' || normalized == 'brawl';
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Widget? valueWidget;
  final IconData? icon;
  final Widget? iconWidget;
  final Color accent;

  const _SummaryTile({
    required this.label,
    required this.value,
    this.valueWidget,
    this.icon,
    this.iconWidget,
    required this.accent,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space6,
      ),
      child: Row(
        children: [
          IconTheme(
            data: IconThemeData(color: accent, size: 18),
            child: iconWidget ?? Icon(icon),
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                if (valueWidget != null)
                  valueWidget!
                else
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalityConfidenceCard extends StatelessWidget {
  final bool isCommanderFormat;
  final bool isValidating;
  final Map<String, dynamic>? validationResult;
  final int totalCards;
  final int? maxCards;
  final bool hasCommander;
  final VoidCallback onValidateNow;
  final VoidCallback onValidationTap;
  final VoidCallback onOpenCards;
  final VoidCallback onSelectCommander;

  const _LegalityConfidenceCard({
    required this.isCommanderFormat,
    required this.isValidating,
    required this.validationResult,
    required this.totalCards,
    required this.maxCards,
    required this.hasCommander,
    required this.onValidateNow,
    required this.onValidationTap,
    required this.onOpenCards,
    required this.onSelectCommander,
  });

  String? get _validationUpdatedLabel {
    final raw = validationResult?['validation_updated_at'];
    final parsed = raw is DateTime
        ? raw
        : raw == null
        ? null
        : DateTime.tryParse(raw.toString());
    if (parsed == null) return null;
    final local = parsed.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final date =
        '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}';
    final time = '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
    return 'Atualizado em $date às $time';
  }

  List<_ValidationIssue> _issues() {
    final issues = <_ValidationIssue>[];
    void add(_ValidationIssue issue) {
      if (issues.any((existing) => existing.title == issue.title)) return;
      issues.add(issue);
    }

    if (isCommanderFormat && !hasCommander) {
      add(
        _ValidationIssue(
          title: 'Comandante ausente',
          message:
              'Escolha o comandante antes de validar identidade de cor e singleton.',
          actionLabel: 'Selecionar comandante',
          onAction: onSelectCommander,
          icon: Icons.person_search_outlined,
          accent: AppTheme.warning,
        ),
      );
    }

    if (maxCards != null && totalCards < maxCards!) {
      final missing = maxCards! - totalCards;
      add(
        _ValidationIssue(
          title: 'Deck abaixo de $maxCards cartas',
          message:
              'Faltam $missing carta${missing == 1 ? '' : 's'} para fechar a lista do formato.',
          actionLabel: 'Abrir cartas',
          onAction: onOpenCards,
          icon: Icons.playlist_add_outlined,
          accent: AppTheme.frost400,
        ),
      );
    } else if (maxCards != null && totalCards > maxCards!) {
      final excess = totalCards - maxCards!;
      add(
        _ValidationIssue(
          title: 'Quantidade acima do limite',
          message:
              'Remova $excess carta${excess == 1 ? '' : 's'} para voltar ao tamanho correto.',
          actionLabel: 'Ver cartas',
          onAction: onOpenCards,
          icon: Icons.remove_circle_outline,
          accent: AppTheme.error,
        ),
      );
    }

    final rawError = validationResult?['error']?.toString().trim() ?? '';
    if (validationResult != null &&
        validationResult?['ok'] != true &&
        rawError.isNotEmpty) {
      final lower = rawError.toLowerCase();
      if (lower.contains('identidade') || lower.contains('color identity')) {
        add(
          _ValidationIssue(
            title: 'Carta fora da identidade de cor',
            message:
                'Uma carta usa cor que o comandante não permite. Troque ou remova a carta sinalizada.',
            actionLabel: 'Ver cartas',
            onAction: onOpenCards,
            icon: Icons.palette_outlined,
            accent: AppTheme.error,
          ),
        );
      } else if (lower.contains('ban') ||
          lower.contains('not legal') ||
          lower.contains('não legal') ||
          lower.contains('nao legal')) {
        add(
          _ValidationIssue(
            title: 'Carta banida ou não legal',
            message:
                'Substitua a carta por uma opção permitida no formato selecionado.',
            actionLabel: 'Ver cartas',
            onAction: onOpenCards,
            icon: Icons.gavel_outlined,
            accent: AppTheme.error,
          ),
        );
      } else if (lower.contains('quantidade') ||
          lower.contains('copy') ||
          lower.contains('cópia') ||
          lower.contains('copia') ||
          lower.contains('singleton')) {
        add(
          _ValidationIssue(
            title: 'Quantidade inválida',
            message:
                'Commander permite 1 cópia de carta não-básica. Ajuste a quantidade da carta sinalizada.',
            actionLabel: 'Ver cartas',
            onAction: onOpenCards,
            icon: Icons.exposure_outlined,
            accent: AppTheme.error,
          ),
        );
      } else if (lower.contains('commander') || lower.contains('comandante')) {
        add(
          _ValidationIssue(
            title: 'Problema com comandante',
            message:
                'Revise se o comandante foi marcado corretamente e se é elegível.',
            actionLabel: 'Selecionar comandante',
            onAction: onSelectCommander,
            icon: Icons.workspace_premium_outlined,
            accent: AppTheme.warning,
          ),
        );
      } else {
        add(
          _ValidationIssue(
            title: 'Regra do formato não atendida',
            message:
                'A validação encontrou um ponto de regra. Abra as cartas sinalizadas e ajuste a lista.',
            actionLabel: 'Ver status',
            onAction: onValidationTap,
            icon: Icons.rule_folder_outlined,
            accent: AppTheme.warning,
          ),
        );
      }
    }

    return issues;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ok = validationResult?['ok'] == true;
    final hasResult = validationResult != null && !isValidating;
    final accent = isValidating
        ? AppTheme.frost400
        : hasResult
        ? (ok ? AppTheme.success : AppTheme.error)
        : AppTheme.frost400;
    final title = isValidating
        ? 'Validando legalidade'
        : hasResult
        ? (ok ? 'Deck legal para o formato' : 'Atenção na legalidade')
        : 'Legalidade ainda não verificada';
    final target = maxCards == null
        ? '$totalCards cartas'
        : '$totalCards/$maxCards cartas';
    final issues = _issues();
    final baseMessage = isValidating
        ? 'Checando formato, comandante, contagem e identidade de cor.'
        : hasResult
        ? (ok
              ? 'A lista passou nas regras conhecidas do app. Revise preço e estratégia antes da mesa.'
              : issues.isNotEmpty
              ? 'Encontramos ${issues.length} ponto${issues.length == 1 ? '' : 's'} para corrigir antes da mesa.'
              : 'Revise as cartas sinalizadas antes de jogar.')
        : isCommanderFormat
        ? 'Commander precisa de 100 cartas, 1 comandante e identidade de cor consistente. Valide antes de otimizar ou jogar.'
        : 'Valide a lista antes de exportar, compartilhar ou jogar.';
    final updatedLabel = _validationUpdatedLabel;
    final message = updatedLabel == null
        ? baseMessage
        : '$baseMessage $updatedLabel.';

    if (hasResult && ok) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space10,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: accent.withValues(alpha: 0.32)),
            bottom: BorderSide(color: accent.withValues(alpha: 0.32)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: accent, size: 22),
            const SizedBox(width: AppTheme.space10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space2),
                  Text(
                    '$target • Lista aprovada nas regras conhecidas.'
                    '${updatedLabel == null ? '' : ' • $updatedLabel'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onValidationTap,
              icon: const Icon(Icons.verified_outlined, size: 16),
              label: const Text('Válido'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
          width: AppTheme.strokeRegular,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppTheme.touchTargetMin,
            height: AppTheme.touchTargetMin,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: isValidating
                ? const Padding(
                    padding: EdgeInsets.all(AppTheme.space9),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    ok
                        ? Icons.verified_rounded
                        : hasResult
                        ? Icons.warning_amber_rounded
                        : Icons.rule_folder_outlined,
                    color: accent,
                    size: 20,
                  ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    DeckMetaChip(label: target, color: accent),
                  ],
                ),
                const SizedBox(height: AppTheme.space6),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: AppTheme.lineHeightCompact,
                  ),
                ),
                const SizedBox(height: AppTheme.space10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DeckMetaChip(
                      label: hasCommander
                          ? 'Comandante definido'
                          : 'Sem comandante',
                      color: hasCommander ? AppTheme.success : AppTheme.warning,
                      icon: hasCommander
                          ? Icons.workspace_premium
                          : Icons.person_search_outlined,
                    ),
                    if (hasResult)
                      OutlinedButton.icon(
                        onPressed: onValidationTap,
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Inválido'),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: isValidating ? null : onValidateNow,
                        icon: const Icon(Icons.verified_outlined, size: 16),
                        label: const Text('Validar agora'),
                      ),
                  ],
                ),
                if (issues.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space12),
                  ...issues
                      .take(3)
                      .map(
                        (issue) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.space8,
                          ),
                          child: _ValidationIssueRow(issue: issue),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationIssue {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;
  final Color accent;

  const _ValidationIssue({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.icon,
    required this.accent,
  });
}

class _ValidationIssueRow extends StatelessWidget {
  final _ValidationIssue issue;

  const _ValidationIssueRow({required this.issue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.space10),
      decoration: BoxDecoration(
        color: issue.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: issue.accent.withValues(alpha: 0.22),
          width: AppTheme.strokeThin,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textBlock = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(issue.icon, color: issue.accent, size: 18),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space3),
                    Text(
                      issue.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final isPrimaryCommanderAction =
              issue.actionLabel == 'Selecionar comandante';
          final action = isPrimaryCommanderAction
              ? FilledButton.icon(
                  onPressed: issue.onAction,
                  icon: const Icon(Icons.workspace_premium_outlined, size: 16),
                  label: Text(issue.actionLabel),
                )
              : TextButton(
                  onPressed: issue.onAction,
                  child: Text(issue.actionLabel),
                );

          if (constraints.maxWidth < 280) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textBlock,
                const SizedBox(height: AppTheme.space8),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: textBlock),
              const SizedBox(width: AppTheme.space8),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _InlineCommanderBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _InlineCommanderBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
          width: AppTheme.strokeThin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: AppTheme.space4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String? description;
  final ValueChanged<String?> onEditDescription;

  const _DescriptionSection({
    required this.description,
    required this.onEditDescription,
  });

  bool get _hasDescription =>
      description != null && description!.trim().isNotEmpty;

  String get _displayDescription {
    final raw = description?.trim() ?? '';
    if (raw.isEmpty) return raw;

    final lower = raw.toLowerCase();
    final isInternalImportNote =
        lower.startsWith('imported from hermes') ||
        lower.contains('source: docs/') ||
        lower.contains('docs/hermes-analysis/');

    if (!isInternalImportNote) return raw;

    return 'Deck importado de uma análise validada. Adicione o plano de jogo, '
        'nível da mesa e condições de vitória para orientar as recomendações.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.6),
          width: AppTheme.strokeRegular,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Descrição', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppTheme.space2),
                    Text(
                      'Resumo curto do plano e da intenção do deck.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => onEditDescription(description),
                icon: Icon(_hasDescription ? Icons.edit : Icons.add, size: 16),
                label: Text(_hasDescription ? 'Editar' : 'Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          if (_hasDescription)
            InkWell(
              onTap: () => onEditDescription(description),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: AppTheme.outlineMuted.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _displayDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary.withValues(alpha: 0.9),
                    height: AppTheme.lineHeightCompact,
                  ),
                ),
              ),
            )
          else
            InkWell(
              onTap: () => onEditDescription(null),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: AppTheme.outlineMuted.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  'Toque para adicionar uma descrição ao deck...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary.withValues(alpha: 0.82),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverviewQuickActions extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onOptimize;

  const _OverviewQuickActions({required this.onPlay, required this.onOptimize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playButton = FilledButton.icon(
      onPressed: onPlay,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, AppTheme.touchTargetMin),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space18,
          vertical: AppTheme.space12,
        ),
        backgroundColor: AppTheme.brass400,
        foregroundColor: AppTheme.backgroundAbyss,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
      icon: const Icon(Icons.favorite_rounded, size: 19),
      label: Text(
        'Jogar agora',
        style: theme.textTheme.titleSmall?.copyWith(
          color: AppTheme.backgroundAbyss,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final optimizeButton = OutlinedButton.icon(
      key: const Key('deck-optimize-button'),
      onPressed: onOptimize,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppTheme.touchTargetMin),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space18,
          vertical: AppTheme.space12,
        ),
        foregroundColor: AppTheme.textPrimary,
        side: BorderSide(color: AppTheme.frost400.withValues(alpha: 0.55)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
      icon: const Icon(Icons.auto_fix_high, size: 19),
      label: const Text('Otimizar'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppTheme.breakpointCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              playButton,
              const SizedBox(height: AppTheme.space8),
              optimizeButton,
            ],
          );
        }
        return Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [optimizeButton, playButton],
          ),
        );
      },
    );
  }
}

class _CommanderPrompt extends StatelessWidget {
  final VoidCallback onSelectCommander;

  const _CommanderPrompt({required this.onSelectCommander});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.warning),
          const SizedBox(width: AppTheme.space10),
          const Expanded(
            child: Text(
              'Selecione um comandante para aplicar regras e filtros de identidade de cor.',
            ),
          ),
          TextButton(
            onPressed: onSelectCommander,
            child: const Text('Selecionar'),
          ),
        ],
      ),
    );
  }
}

class _StrategySummaryCard extends StatelessWidget {
  final bool hasArchetype;
  final String? archetype;
  final int? bracket;
  final String Function(int bracket) bracketLabel;
  final VoidCallback onTap;

  const _StrategySummaryCard({
    required this.hasArchetype,
    required this.archetype,
    required this.bracket,
    required this.bracketLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toneColor = hasArchetype ? AppTheme.brass500 : AppTheme.frost400;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.6),
          width: AppTheme.strokeRegular,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estratégia', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppTheme.space2),
                    Text(
                      hasArchetype
                          ? 'Direção principal que orienta análise e otimização.'
                          : 'Defina o plano do deck para melhorar recomendações.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.tune, size: 18),
                label: Text(hasArchetype ? 'Alterar' : 'Definir'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: toneColor.withValues(alpha: hasArchetype ? 0.3 : 0.22),
                  width: AppTheme.strokeThin,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: toneColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      hasArchetype
                          ? Icons.psychology
                          : Icons.auto_awesome_outlined,
                      color: toneColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasArchetype ? archetype! : 'Não definida',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          bracket != null
                              ? 'Bracket: $bracket • ${bracketLabel(bracket!)}'
                              : 'Bracket não definido',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.92,
                            ),
                          ),
                        ),
                        if (!hasArchetype) ...[
                          const SizedBox(height: AppTheme.space8),
                          Text(
                            'Toque para escolher um plano de jogo antes de otimizar.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: toneColor.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: toneColor.withValues(alpha: 0.85),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckEmptyState extends StatelessWidget {
  final bool isCommanderFormat;
  final VoidCallback onSelectCommander;
  final VoidCallback onOpenCards;
  final VoidCallback onImportList;

  const _DeckEmptyState({
    required this.isCommanderFormat,
    required this.onSelectCommander,
    required this.onOpenCards,
    required this.onImportList,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineMuted.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space10),
                decoration: BoxDecoration(
                  color: AppTheme.frost400.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppTheme.frost400,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCommanderFormat
                          ? 'Escolha o comandante primeiro'
                          : 'Deck pronto para começar',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      isCommanderFormat
                          ? 'Commander precisa de um comandante antes das 99 cartas para validar identidade de cor e recomendações.'
                          : 'Adicione as primeiras cartas para liberar análise, validação e recomendações.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          if (isCommanderFormat) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSelectCommander,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Selecionar comandante'),
              ),
            ),
            const SizedBox(height: AppTheme.space10),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenCards,
                icon: const Icon(Icons.search),
                label: const Text('Buscar cartas'),
              ),
              OutlinedButton.icon(
                onPressed: onImportList,
                icon: const Icon(Icons.paste_outlined),
                label: const Text('Colar lista'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
