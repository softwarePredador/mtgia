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
  final VoidCallback onOpenAnalysis;
  final VoidCallback onForcePricingRefresh;
  final VoidCallback onShowPricingDetails;
  final VoidCallback onTogglePublic;
  final VoidCallback onShowOptimizationOptions;
  final VoidCallback onSelectCommander;
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
    required this.onOpenAnalysis,
    required this.onForcePricingRefresh,
    required this.onShowPricingDetails,
    required this.onTogglePublic,
    required this.onShowOptimizationOptions,
    required this.onSelectCommander,
    required this.onEditDescription,
    required this.onShowCardDetails,
  });

  bool get _hasDescription =>
      deck.description != null && deck.description!.trim().isNotEmpty;

  bool get _hasArchetype =>
      deck.archetype != null && deck.archetype!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: AppTheme.outlineMuted.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deck.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DeckMetaChip(
                      label: deck.format.toUpperCase(),
                      color: AppTheme.identityColor(deck.colorIdentity.toSet()),
                      icon: Icons.style_outlined,
                    ),
                    if (deck.colorIdentity.isNotEmpty)
                      ColorIdentityPips(colors: deck.colorIdentity),
                    if (isValidating)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (validationResult != null)
                      DeckMetaChip(
                        onTap: onValidationTap,
                        label:
                            validationResult!['ok'] == true
                                ? 'Válido'
                                : 'Inválido',
                        color:
                            validationResult!['ok'] == true
                                ? AppTheme.success
                                : theme.colorScheme.error,
                        icon:
                            validationResult!['ok'] == true
                                ? Icons.verified
                                : Icons.warning_amber_rounded,
                      ),
                    DeckMetaChip(
                      onTap: onTogglePublic,
                      label: deck.isPublic ? 'Público' : 'Privado',
                      color:
                          deck.isPublic
                              ? AppTheme.primarySoft
                              : AppTheme.textSecondary,
                      icon:
                          deck.isPublic ? Icons.public : Icons.lock_outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DeckProgressIndicator(
            deck: deck,
            totalCards: totalCards,
            maxCards: maxCards,
            hasCommander: deck.commander.isNotEmpty,
            onTap: onOpenCards,
          ),
          const SizedBox(height: 12),
          DeckPricingRow(
            pricing: pricing,
            isLoading: isPricingLoading,
            onForceRefresh: onForcePricingRefresh,
            onShowDetails: onShowPricingDetails,
          ),
          const SizedBox(height: 12),
          DeckDiagnosticPanel(deck: deck, onOpenAnalysis: onOpenAnalysis),
          SampleHandWidget(deck: deck, compact: true),
          if (isCommanderFormat && deck.commander.isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: theme.colorScheme.errorContainer),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Selecione um comandante para aplicar regras e filtros de identidade de cor.',
                    ),
                  ),
                  TextButton(
                    onPressed:
                        onSelectCommander,
                    child: const Text('Selecionar'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Descrição', style: theme.textTheme.titleMedium),
              ),
              TextButton.icon(
                onPressed: () => onEditDescription(deck.description),
                icon: Icon(
                  _hasDescription ? Icons.edit : Icons.add,
                  size: 16,
                ),
                label: Text(_hasDescription ? 'Editar' : 'Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_hasDescription)
            InkWell(
              onTap: () => onEditDescription(deck.description),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  deck.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
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
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Text(
                  'Toque para adicionar uma descrição ao deck...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (deck.commander.isNotEmpty) ...[
            Text('Comandante', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...deck.commander.map(
              (card) => Card(
                shape:
                    isCardInvalid(card)
                        ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.error,
                            width: 2,
                          ),
                        )
                        : null,
                color:
                    isCardInvalid(card)
                        ? theme.colorScheme.error.withValues(alpha: 0.08)
                        : null,
                child: Stack(
                  children: [
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        child: CachedCardImage(
                          imageUrl: card.imageUrl,
                          width: 44,
                          height: 62,
                        ),
                      ),
                      title: Text(card.name),
                      subtitle: Text(card.typeLine),
                      onTap: () => onShowCardDetails(card),
                    ),
                    if (isCardInvalid(card))
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Inválida',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppTheme.fontXs,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed:
                    () => context.go('/decks/$deckId/search?mode=commander'),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Trocar comandante'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Estratégia', style: theme.textTheme.titleMedium),
              ),
              TextButton.icon(
                onPressed: onShowOptimizationOptions,
                icon: const Icon(Icons.tune, size: 18),
                label: Text(_hasArchetype ? 'Alterar' : 'Definir'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onShowOptimizationOptions,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _hasArchetype
                        ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        )
                        : theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color:
                      _hasArchetype
                          ? theme.colorScheme.primary.withValues(alpha: 0.4)
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasArchetype ? Icons.psychology : Icons.help_outline,
                    color:
                        _hasArchetype
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasArchetype ? deck.archetype! : 'Não definida',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                _hasArchetype
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deck.bracket != null
                              ? 'Bracket: ${deck.bracket} • ${bracketLabel(deck.bracket!)}'
                              : 'Bracket não definido',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          if (!_hasArchetype) ...[
            const SizedBox(height: 8),
            Text(
              'Toque para definir a estratégia do deck',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
