import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../models/deck_card_item.dart';
import '../models/deck_analysis.dart';
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
  final DeckAnalysisData? diagnosticAnalysis;
  final bool Function(DeckCardItem card) isCardInvalid;
  final String Function(int bracket) bracketLabel;
  final VoidCallback onValidateNow;
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
    this.diagnosticAnalysis,
    required this.isCardInvalid,
    required this.bracketLabel,
    required this.onValidateNow,
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
                                      ? AppTheme.frost400
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
            _CommanderDeckSummaryGrid(
              deck: deck,
              totalCards: totalCards,
              maxCards: maxCards,
              hasCommander: deck.commander.isNotEmpty,
              pricing: pricing,
            ),
            const SizedBox(height: 16),
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
            DeckDiagnosticPanel(deck: deck, analysis: diagnosticAnalysis),
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
    if (deck.colorIdentity.isEmpty) return 'Incolor/pendente';
    return deck.colorIdentity.join('');
  }

  String get _countLabel =>
      maxCards == null ? '$totalCards cartas' : '$totalCards/$maxCards cartas';

  String get _priceLabel {
    final rawTotal = pricing?['estimated_total_usd'] ?? deck.pricingTotal;
    final total = rawTotal is num ? rawTotal.toDouble() : null;
    if (total == null) return 'Pendente';
    final currency =
        pricing?['currency']?.toString() ?? deck.pricingCurrency ?? 'USD';
    return '$currency ${total.toStringAsFixed(2)}';
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
        final columns =
            constraints.maxWidth < 360
                ? 2
                : (constraints.maxWidth < 720 ? 4 : 4);
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
                icon: Icons.workspace_premium_outlined,
                accent: commanderOk ? AppTheme.success : AppTheme.warning,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _SummaryTile(
                label: 'Identidade',
                value: _identityLabel,
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
                icon:
                    _priceLabel == 'Pendente'
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
  final IconData icon;
  final Color accent;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
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
    final accent =
        isValidating
            ? AppTheme.frost400
            : hasResult
            ? (ok ? AppTheme.success : AppTheme.error)
            : AppTheme.frost400;
    final title =
        isValidating
            ? 'Validando legalidade'
            : hasResult
            ? (ok ? 'Deck legal para o formato' : 'Atenção na legalidade')
            : 'Legalidade ainda não verificada';
    final target =
        maxCards == null
            ? '$totalCards cartas'
            : '$totalCards/$maxCards cartas';
    final issues = _issues();
    final message =
        isValidating
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 0.9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child:
                isValidating
                    ? const Padding(
                      padding: EdgeInsets.all(9),
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
          const SizedBox(width: 12),
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
                const SizedBox(height: 6),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DeckMetaChip(
                      label:
                          hasCommander
                              ? 'Comandante definido'
                              : 'Sem comandante',
                      color: hasCommander ? AppTheme.success : AppTheme.warning,
                      icon:
                          hasCommander
                              ? Icons.workspace_premium
                              : Icons.person_search_outlined,
                    ),
                    if (hasResult)
                      OutlinedButton.icon(
                        onPressed: onValidationTap,
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Ver status'),
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
                  const SizedBox(height: 12),
                  ...issues
                      .take(3)
                      .map(
                        (issue) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: issue.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: issue.accent.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textBlock = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(issue.icon, color: issue.accent, size: 18),
              const SizedBox(width: 10),
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
                    const SizedBox(height: 3),
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
          final action =
              isPrimaryCommanderAction
                  ? FilledButton.icon(
                    onPressed: issue.onAction,
                    icon: const Icon(
                      Icons.workspace_premium_outlined,
                      size: 16,
                    ),
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
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: textBlock),
              const SizedBox(width: 8),
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
          backgroundColor: AppTheme.brass400.withValues(alpha: 0.10),
          foregroundColor: AppTheme.brass400,
          side: BorderSide(color: AppTheme.brass400.withValues(alpha: 0.30)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        icon: const Icon(Icons.auto_fix_high, color: AppTheme.brass400),
        label: Text(
          'Otimizar com IA',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.brass400,
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
    final toneColor = hasArchetype ? AppTheme.brass500 : AppTheme.frost400;

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
                  color: AppTheme.frost400.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppTheme.frost400,
                ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
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
          const SizedBox(height: 16),
          if (isCommanderFormat) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSelectCommander,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Selecionar comandante'),
              ),
            ),
            const SizedBox(height: 10),
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
