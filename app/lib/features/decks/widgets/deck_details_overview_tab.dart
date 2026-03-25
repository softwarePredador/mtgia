import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../models/deck_card_item.dart';
import '../models/deck_details.dart';
import 'deck_details_aux_widgets.dart';
import 'deck_diagnostic_panel.dart';
import 'deck_progress_indicator.dart';
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
  final bool Function(DeckCardItem card) isCardInvalid;
  final String Function(int bracket) bracketLabel;
  final VoidCallback onValidationTap;
  final VoidCallback onOpenCards;
  final VoidCallback onForcePricingRefresh;
  final VoidCallback onShowPricingDetails;
  final VoidCallback onTogglePublic;
  final VoidCallback onShowOptimizationOptions;
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
    required this.isCardInvalid,
    required this.bracketLabel,
    required this.onValidationTap,
    required this.onOpenCards,
    required this.onForcePricingRefresh,
    required this.onShowPricingDetails,
    required this.onTogglePublic,
    required this.onShowOptimizationOptions,
    required this.onSelectCommander,
    required this.onImportList,
    required this.onEditDescription,
    required this.onShowCardDetails,
  });

  bool get _hasArchetype =>
      deck.archetype != null && deck.archetype!.trim().isNotEmpty;

  bool get _isEmptyDeck => totalCards == 0;

  DeckCardItem? get _heroCommander =>
      deck.commander.isNotEmpty ? deck.commander.first : null;

  String? get _heroCommanderImageUrl {
    final imageUrl = _heroCommander?.imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    return imageUrl;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHeroArtwork = _heroCommanderImageUrl != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: AppTheme.outlineMuted.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Stack(
                children: [
                  if (_heroCommanderImageUrl != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CachedCardImage(
                          imageUrl: _heroCommanderImageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.backgroundAbyss.withValues(
                              alpha:
                                  _heroCommanderImageUrl != null ? 0.22 : 0.0,
                            ),
                            AppTheme.surfaceElevated.withValues(
                              alpha: _heroCommanderImageUrl != null ? 0.74 : 1,
                            ),
                            AppTheme.backgroundAbyss.withValues(
                              alpha:
                                  _heroCommanderImageUrl != null ? 0.88 : 0.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    hasHeroArtwork
                                        ? const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        )
                                        : EdgeInsets.zero,
                                decoration:
                                    hasHeroArtwork
                                        ? BoxDecoration(
                                          color: AppTheme.backgroundAbyss
                                              .withValues(alpha: 0.48),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMd,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.outlineMuted
                                                .withValues(alpha: 0.35),
                                            width: 0.5,
                                          ),
                                        )
                                        : null,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      deck.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            height: 1.05,
                                          ),
                                    ),
                                    if (_heroCommander != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Comandante: ${_heroCommander!.name}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.textPrimary
                                                  .withValues(alpha: 0.92),
                                              fontWeight: FontWeight.w500,
                                              height: 1.25,
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      _heroSummary,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textPrimary
                                                .withValues(alpha: 0.82),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_heroCommanderImageUrl != null) ...[
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                child: Container(
                                  width: 48,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd,
                                    ),
                                    border: Border.all(
                                      color: AppTheme.outlineMuted.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                                  child: CachedCardImage(
                                    imageUrl: _heroCommanderImageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            DeckMetaChip(
                              label: deck.format.toUpperCase(),
                              color: AppTheme.identityColor(
                                deck.colorIdentity.toSet(),
                              ),
                              icon: Icons.style_outlined,
                            ),
                            if (deck.colorIdentity.isNotEmpty)
                              ColorIdentityPips(colors: deck.colorIdentity),
                            if (isValidating)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            DeckMetaChip(
                              onTap: onTogglePublic,
                              label: deck.isPublic ? 'Público' : 'Privado',
                              color:
                                  deck.isPublic
                                      ? AppTheme.primarySoft
                                      : AppTheme.textSecondary,
                              icon:
                                  deck.isPublic
                                      ? Icons.public
                                      : Icons.lock_outline,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isEmptyDeck)
            _DeckEmptyState(
              isCommanderFormat: isCommanderFormat,
              onSelectCommander: onSelectCommander,
              onOpenCards: onOpenCards,
              onImportList: onImportList,
            )
          else ...[
            _OverviewQuickActions(onOptimize: onShowOptimizationOptions),
            const SizedBox(height: 16),
            DeckProgressIndicator(
              deck: deck,
              totalCards: totalCards,
              maxCards: maxCards,
              hasCommander: deck.commander.isNotEmpty,
              onTap: onOpenCards,
              semanticBadgeLabel:
                  !_isEmptyDeck && !isValidating && validationResult != null
                      ? (validationResult!['ok'] == true
                          ? 'Válido'
                          : 'Inválido')
                      : null,
              semanticBadgeColor:
                  !_isEmptyDeck && !isValidating && validationResult != null
                      ? (validationResult!['ok'] == true
                          ? AppTheme.success
                          : theme.colorScheme.error)
                      : null,
              semanticBadgeIcon:
                  !_isEmptyDeck && !isValidating && validationResult != null
                      ? (validationResult!['ok'] == true
                          ? Icons.verified
                          : Icons.warning_amber_rounded)
                      : null,
              onSemanticBadgeTap:
                  !_isEmptyDeck && !isValidating && validationResult != null
                      ? onValidationTap
                      : null,
            ),
            const SizedBox(height: 16),
            if (isCommanderFormat && deck.commander.isEmpty) ...[
              _CommanderPrompt(onSelectCommander: onSelectCommander),
              const SizedBox(height: 16),
            ],
            _StrategySummaryCard(
              hasArchetype: _hasArchetype,
              archetype: deck.archetype,
              bracket: deck.bracket,
              bracketLabel: bracketLabel,
              onTap: onShowOptimizationOptions,
            ),
            const SizedBox(height: 16),
            if (deck.commander.isNotEmpty) ...[
              _CommanderSection(
                commander: deck.commander,
                isCardInvalid: isCardInvalid,
                onShowCardDetails: onShowCardDetails,
                onChangeCommander:
                    () => context.go('/decks/$deckId/search?mode=commander'),
              ),
              const SizedBox(height: 16),
            ],
            _DescriptionSection(
              description: deck.description,
              onEditDescription: onEditDescription,
            ),
            const SizedBox(height: 16),
            DeckDiagnosticPanel(deck: deck),
            const SizedBox(height: 16),
            SampleHandWidget(deck: deck, compact: true),
          ],
          const SizedBox(height: 16),
          if (_isEmptyDeck) ...[
            Text(
              'Depois que o deck ganhar base, os diagnósticos e recomendações aparecem aqui.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary.withValues(alpha: 0.76),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (!_isEmptyDeck) ...[
            const SizedBox(height: 24),
            DeckPricingRow(
              pricing: pricing,
              isLoading: isPricingLoading,
              onForceRefresh: onForcePricingRefresh,
              onShowDetails: onShowPricingDetails,
            ),
          ],
        ],
      ),
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
        const SizedBox(height: 8),
        ...commander.map(
          (card) => InkWell(
            onTap: () => onShowCardDetails(card),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color:
                      isCardInvalid(card)
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
                      imageUrl: card.imageUrl,
                      width: 52,
                      height: 72,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 4),
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
                          const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.6),
          width: 0.9,
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
                    const SizedBox(height: 2),
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
          const SizedBox(height: 12),
          if (_hasDescription)
            InkWell(
              onTap: () => onEditDescription(description),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: AppTheme.outlineMuted.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary.withValues(alpha: 0.9),
                    height: 1.35,
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
                padding: const EdgeInsets.all(12),
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
  final VoidCallback onOptimize;

  const _OverviewQuickActions({required this.onOptimize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onOptimize,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.28),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        icon: Icon(Icons.auto_fix_high, color: theme.colorScheme.primary),
        label: Text(
          'Otimizar deck',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CommanderPrompt extends StatelessWidget {
  final VoidCallback onSelectCommander;

  const _CommanderPrompt({required this.onSelectCommander});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.warning),
          const SizedBox(width: 10),
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
    final toneColor =
        hasArchetype ? theme.colorScheme.primary : AppTheme.primarySoft;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.6),
          width: 0.9,
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
                    const SizedBox(height: 2),
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
          const SizedBox(height: 12),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: toneColor.withValues(alpha: hasArchetype ? 0.3 : 0.22),
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
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 4),
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
                          const SizedBox(height: 8),
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
      padding: const EdgeInsets.all(18),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppTheme.primarySoft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deck pronto para começar',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adicione as primeiras cartas para liberar análise, validação e recomendações.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (isCommanderFormat)
                FilledButton.icon(
                  onPressed: onSelectCommander,
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: const Text('Selecionar comandante'),
                ),
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
