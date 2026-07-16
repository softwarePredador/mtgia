import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/mana_helper.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../models/deck_analysis.dart';
import '../models/deck_card_item.dart';
import '../models/deck_details.dart';

class DeckDiagnosticPanel extends StatelessWidget {
  final DeckDetails deck;
  final DeckAnalysisData? analysis;
  final VoidCallback? onOpenAnalysis;
  final VoidCallback? onOpenBattleReplays;
  final ValueChanged<DeckCardItem>? onShowCardDetails;

  const DeckDiagnosticPanel({
    super.key,
    required this.deck,
    this.analysis,
    this.onOpenAnalysis,
    this.onOpenBattleReplays,
    this.onShowCardDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = _DeckDiagnosticSnapshot.fromDeck(deck, analysis: analysis);
    final hasWarnings = snapshot.metrics.any(
      (metric) =>
          identical(metric.tone, _DiagnosticTone.danger) ||
          identical(metric.tone, _DiagnosticTone.warn),
    );
    final summaryTone =
        hasWarnings ? _DiagnosticTone.warn : _DiagnosticTone.good;
    final summaryLabel = hasWarnings ? 'Ajustes sugeridos' : 'Base saudável';
    final playerNotice = _PlayerReadinessNotice.fromAnalysis(
      analysis,
      hasMetricWarnings: hasWarnings,
    );

    return Container(
      key: const Key('deck-diagnostic-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.65),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 420;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Próximos ajustes do deck',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Priorize o que melhora a partida: mana, compra, respostas e curva.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 12),
                        _DiagnosticSummaryBadge(
                          label: summaryLabel,
                          tone: summaryTone,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (isCompact)
                        _DiagnosticSummaryBadge(
                          label: summaryLabel,
                          tone: summaryTone,
                        ),
                      if (onOpenAnalysis != null)
                        TextButton.icon(
                          onPressed: onOpenAnalysis,
                          icon: const Icon(Icons.analytics_outlined, size: 18),
                          label: const Text('Análise completa'),
                        ),
                      if (onOpenBattleReplays != null)
                        TextButton.icon(
                          key: const Key('deck-open-battle-replays-button'),
                          onPressed: onOpenBattleReplays,
                          icon: const Icon(
                            Icons.psychology_alt_outlined,
                            size: 18,
                          ),
                          label: const Text('Ver testes'),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          if (playerNotice != null) ...[
            const SizedBox(height: 14),
            _PlayerReadinessCard(notice: playerNotice),
          ],
          const SizedBox(height: 16),
          Text(
            'O que melhorar primeiro',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth < 360
                      ? 1
                      : (constraints.maxWidth < 720 ? 2 : 3);
              final spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children:
                    snapshot.metrics
                        .map(
                          (metric) => SizedBox(
                            width: itemWidth,
                            child: _DiagnosticMetricCard(
                              metric: metric,
                              onOpenEvidence:
                                  () => _showDiagnosticEvidenceSheet(
                                    context,
                                    metric.evidence,
                                    onShowCardDetails: onShowCardDetails,
                                  ),
                            ),
                          ),
                        )
                        .toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Ver cartas por função',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Abra um grupo para ver quais cartas sustentam aquela parte do plano.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          _DiagnosticEvidenceGrid(
            evidence: snapshot.evidence,
            onOpenEvidence:
                (evidence) => _showDiagnosticEvidenceSheet(
                  context,
                  evidence,
                  onShowCardDetails: onShowCardDetails,
                ),
          ),
          const SizedBox(height: 18),
          Text(
            'Resumo em linguagem simples',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...snapshot.insights.asMap().entries.map(
            (entry) => _DiagnosticInsightRow(entry.value, index: entry.key),
          ),
        ],
      ),
    );
  }
}

class _PlayerReadinessNotice {
  const _PlayerReadinessNotice({
    required this.title,
    required this.detail,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String detail;
  final IconData icon;
  final _DiagnosticTone tone;

  static _PlayerReadinessNotice? fromAnalysis(
    DeckAnalysisData? analysis, {
    required bool hasMetricWarnings,
  }) {
    final readiness = analysis?.readiness;

    if (readiness == null) {
      if (!hasMetricWarnings) return null;
      return const _PlayerReadinessNotice(
        title: 'Ajustes recomendados antes da próxima partida',
        detail:
            'Comece pelos indicadores em amarelo ou vermelho para melhorar consistência.',
        icon: Icons.tune_rounded,
        tone: _DiagnosticTone.warn,
      );
    }

    if (readiness.hasBlockers) {
      return _PlayerReadinessNotice(
        title: 'Corrigir lista antes de jogar',
        detail: _friendlyReadinessAction(readiness),
        icon: Icons.report_problem_outlined,
        tone: _DiagnosticTone.danger,
      );
    }

    if (readiness.warningCount > 0 || hasMetricWarnings) {
      return _PlayerReadinessNotice(
        title: 'Deck jogável, mas com ajustes importantes',
        detail: _friendlyReadinessAction(readiness),
        icon: Icons.tune_rounded,
        tone: _DiagnosticTone.warn,
      );
    }

    return const _PlayerReadinessNotice(
      title: 'Base pronta para testar',
      detail:
          'A estrutura principal parece equilibrada. Use os indicadores abaixo para ajustes finos.',
      icon: Icons.check_circle_outline_rounded,
      tone: _DiagnosticTone.good,
    );
  }
}

String _friendlyReadinessAction(DeckReadinessSummary readiness) {
  final action = readiness.primaryAction.trim();
  if (action.isEmpty || action == 'Inteligência avançada liberada.') {
    return 'Use os indicadores abaixo para decidir o próximo ajuste.';
  }
  if (action == 'Revisar avisos antes da simulação.') {
    return 'Revise os pontos sinalizados abaixo antes da próxima partida.';
  }
  if (action == 'Resolver bloqueios antes de avançar.') {
    return 'Corrija os problemas estruturais do deck antes de continuar.';
  }
  return action;
}

class _PlayerReadinessCard extends StatelessWidget {
  final _PlayerReadinessNotice notice;

  const _PlayerReadinessCard({required this.notice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('deck-player-readiness-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: notice.tone.border.withValues(alpha: 0.68)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: notice.tone.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(notice.icon, color: notice.tone.foreground, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notice.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.25,
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

class _DiagnosticMetricCard extends StatelessWidget {
  final _DiagnosticMetric metric;
  final VoidCallback onOpenEvidence;

  const _DiagnosticMetricCard({
    required this.metric,
    required this.onOpenEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 170;

        return Semantics(
          button: true,
          label: 'Ver cartas de ${metric.label}',
          child: Material(
            color: AppTheme.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: InkWell(
              key: Key('deck-diagnostic-metric-${metric.label}'),
              onTap: onOpenEvidence,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSlate.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: metric.tone.border.withValues(alpha: 0.68),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCompact) ...[
                      Text(
                        metric.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MetricToneBadge(label: metric.status, tone: metric.tone),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              metric.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _MetricToneBadge(
                                label: metric.status,
                                tone: metric.tone,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            metric.value,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: metric.tone.background,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                          ),
                          child: Icon(
                            metric.icon,
                            size: 16,
                            color: metric.tone.foreground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metric.target,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DiagnosticEvidenceGrid extends StatelessWidget {
  final List<_DiagnosticEvidence> evidence;
  final ValueChanged<_DiagnosticEvidence> onOpenEvidence;

  const _DiagnosticEvidenceGrid({
    required this.evidence,
    required this.onOpenEvidence,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 1 : 2;
        final spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              evidence
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      child: _DiagnosticEvidenceCard(
                        evidence: item,
                        onTap: () => onOpenEvidence(item),
                      ),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _DiagnosticEvidenceCard extends StatelessWidget {
  final _DiagnosticEvidence evidence;
  final VoidCallback onTap;

  const _DiagnosticEvidenceCard({required this.evidence, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = evidence.previewLabels.take(5).toList();
    final hiddenCount = evidence.previewLabels.length - preview.length;

    return Semantics(
      button: true,
      label: 'Ver cartas de ${evidence.label}',
      child: Material(
        color: AppTheme.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          key: Key('deck-diagnostic-evidence-${evidence.label}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.outlineMuted.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(evidence.icon, size: 15, color: AppTheme.mythicGold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${evidence.label} (${evidence.count})',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (preview.isEmpty)
                  Text(
                    'Nenhuma carta detectada.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Text(
                    [
                      ...preview,
                      if (hiddenCount > 0) '+$hiddenCount outras',
                    ].join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showDiagnosticEvidenceSheet(
  BuildContext context,
  _DiagnosticEvidence evidence, {
  ValueChanged<DeckCardItem>? onShowCardDetails,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceElevated,
    barrierColor: AppTheme.backgroundAbyss.withValues(alpha: 0.72),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusLg),
      ),
    ),
    builder:
        (sheetContext) => _DiagnosticEvidenceSheet(
          evidence: evidence,
          onShowCardDetails: onShowCardDetails,
        ),
  );
}

class _DiagnosticEvidenceSheet extends StatelessWidget {
  final _DiagnosticEvidence evidence;
  final ValueChanged<DeckCardItem>? onShowCardDetails;

  const _DiagnosticEvidenceSheet({
    required this.evidence,
    this.onShowCardDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.78;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        key: Key('deck-diagnostic-evidence-sheet-${evidence.label}'),
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.outlineMuted.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.mythicGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      evidence.icon,
                      size: 18,
                      color: AppTheme.mythicGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${evidence.label} (${evidence.count})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          evidence.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: AppTheme.outlineMuted.withValues(alpha: 0.48),
            ),
            Flexible(
              child:
                  evidence.entries.isEmpty
                      ? _DiagnosticEvidenceEmpty(evidence: evidence)
                      : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: evidence.entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = evidence.entries[index];
                          return _DiagnosticEvidenceListTile(
                            entry: entry,
                            evidenceLabel: evidence.label,
                            onTap:
                                entry.card != null && onShowCardDetails != null
                                    ? () {
                                      Navigator.of(context).pop();
                                      onShowCardDetails!(entry.card!);
                                    }
                                    : null,
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticEvidenceEmpty extends StatelessWidget {
  final _DiagnosticEvidence evidence;

  const _DiagnosticEvidenceEmpty({required this.evidence});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'Nenhuma carta foi detectada para ${evidence.label.toLowerCase()} nesta leitura.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}

class _DiagnosticEvidenceListTile extends StatelessWidget {
  final _DiagnosticEvidenceEntry entry;
  final String evidenceLabel;
  final VoidCallback? onTap;

  const _DiagnosticEvidenceListTile({
    required this.entry,
    required this.evidenceLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = entry.card;
    final quantity = entry.quantity;
    final detail = entry.detail ?? _friendlyEvidenceReason(evidenceLabel);
    final imageUrl = card?.effectiveImageUrl ?? _scryfallImageUrl(entry.name);

    return Material(
      color: AppTheme.surfaceSlate.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        key: Key('deck-diagnostic-evidence-card-${entry.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CachedCardImage(
                imageUrl: imageUrl,
                fallbackImageUrl:
                    card?.fallbackImageUrl ?? _scryfallImageUrl(entry.name),
                width: AppTheme.touchTargetMin,
                height: 64,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (quantity != null && quantity > 1) ...[
                          const SizedBox(width: 8),
                          _EvidenceQuantityBadge(quantity: quantity),
                        ],
                      ],
                    ),
                    if ((card?.typeLine ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        card!.typeLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.open_in_new_rounded,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EvidenceQuantityBadge extends StatelessWidget {
  final int quantity;

  const _EvidenceQuantityBadge({required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.mythicGold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.mythicGold.withValues(alpha: 0.28)),
      ),
      child: Text(
        'x$quantity',
        style: const TextStyle(
          color: AppTheme.mythicGold,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String? _scryfallImageUrl(String cardName) {
  final trimmed = cardName.trim();
  if (trimmed.isEmpty) return null;
  return Uri.https('api.scryfall.com', '/cards/named', {
    'exact': trimmed,
    'format': 'image',
    'version': 'normal',
  }).toString();
}

String _friendlyEvidenceReason(String label) {
  switch (label) {
    case 'Terrenos':
      return 'Conta para a base de mana do deck.';
    case 'Ramp':
      return 'Ajuda a acelerar mana, reduzir custo ou chegar antes nas jogadas principais.';
    case 'Compra':
      return 'Ajuda a comprar, selecionar ou manter cartas disponíveis.';
    case 'Interação':
      return 'Ajuda a responder ameaças e proteger seu plano de jogo.';
    case 'Wipes':
      return 'Ajuda a resetar a mesa quando os oponentes desenvolvem demais.';
    case 'CMC médio':
      return 'Entra no cálculo da curva do deck.';
    default:
      return 'Carta considerada nesta leitura do deck.';
  }
}

class _DiagnosticInsightRow extends StatelessWidget {
  final _DiagnosticInsight insight;

  final int index;

  const _DiagnosticInsightRow(this.insight, {required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: Key('deck-diagnostic-insight-$index'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: insight.tone.border.withValues(alpha: 0.58)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: insight.tone.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(insight.icon, size: 14, color: insight.tone.foreground),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insight.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticSummaryBadge extends StatelessWidget {
  final String label;
  final _DiagnosticTone tone;

  const _DiagnosticSummaryBadge({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('deck-diagnostic-summary-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: tone.border.withValues(alpha: 0.62)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tone.foreground,
          fontSize: AppTheme.fontSm,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricToneBadge extends StatelessWidget {
  final String label;
  final _DiagnosticTone tone;

  const _MetricToneBadge({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: tone.border.withValues(alpha: 0.62)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tone.foreground,
          fontSize: AppTheme.fontSm,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DeckDiagnosticSnapshot {
  final List<_DiagnosticMetric> metrics;
  final List<_DiagnosticEvidence> evidence;
  final List<_DiagnosticInsight> insights;

  const _DeckDiagnosticSnapshot({
    required this.metrics,
    required this.evidence,
    required this.insights,
  });

  factory _DeckDiagnosticSnapshot.fromDeck(
    DeckDetails deck, {
    DeckAnalysisData? analysis,
  }) {
    final cards = deck.mainBoard.values.expand((list) => list).toList();
    final targets = _DeckDiagnosticTargets.fromDeck(deck);

    final landCards = _collectWhere(cards, (card) => _isLand(card));
    final rampCards = _collectWhere(
      cards,
      (card) => !_isLand(card) && _isRamp(card),
    );
    final drawCards = _collectWhere(
      cards,
      (card) => !_isLand(card) && _isDraw(card),
    );
    final interactionCards = _collectWhere(
      cards,
      (card) => !_isLand(card) && _isInteraction(card),
    );
    final wipeCards = _collectWhere(
      cards,
      (card) => !_isLand(card) && _isWipe(card),
    );
    final rampAnalysis = _analysisBucket(
      analysis,
      tagKey: 'ramp',
      compositionKey: 'ramp',
    );
    final drawAnalysis = _analysisBucket(
      analysis,
      tagKey: 'draw',
      compositionKey: 'draw',
    );
    final interactionAnalysis = _analysisBucket(
      analysis,
      tagKey: 'removal',
      compositionKey: 'removal',
    );
    final wipeAnalysis = _analysisBucket(
      analysis,
      tagKey: 'board_wipe',
      compositionKey: 'board_wipes',
    );
    final landCount = _sumQuantities(landCards);
    final rampCount = rampAnalysis?.count ?? _sumQuantities(rampCards);
    final drawCount = drawAnalysis?.count ?? _sumQuantities(drawCards);
    final interactionCount =
        interactionAnalysis?.count ?? _sumQuantities(interactionCards);
    final wipeCount = wipeAnalysis?.count ?? _sumQuantities(wipeCards);

    var weightedCmc = 0;
    var nonLandCount = 0;
    final nonLandCards = <DeckCardItem>[];
    for (final card in cards) {
      if (_isLand(card)) continue;
      nonLandCards.add(card);
      final quantity = card.quantity <= 0 ? 1 : card.quantity;
      weightedCmc += ManaHelper.calculateCMC(card.manaCost) * quantity;
      nonLandCount += quantity;
    }
    final averageCmc = nonLandCount == 0 ? 0.0 : weightedCmc / nonLandCount;

    final landEvidence = _DiagnosticEvidence(
      label: 'Terrenos',
      count: landCount,
      icon: Icons.terrain_rounded,
      entries: _entriesFromCards(landCards),
      description: 'Base de mana usada para desenvolver suas jogadas.',
    );
    final rampEvidence = _DiagnosticEvidence(
      label: 'Ramp',
      count: rampCount,
      icon: Icons.bolt_rounded,
      entries: _entriesFromBucket(
        rampAnalysis,
        rampCards,
        cards,
        tagKey: 'ramp',
      ),
      description: 'Pedras, redução de custo e efeitos que aceleram seu jogo.',
    );
    final drawEvidence = _DiagnosticEvidence(
      label: 'Compra',
      count: drawCount,
      icon: Icons.auto_stories_rounded,
      entries: _entriesFromBucket(
        drawAnalysis,
        drawCards,
        cards,
        tagKey: 'draw',
      ),
      description: 'Cartas que ajudam a manter recursos ao longo da partida.',
    );
    final interactionEvidence = _DiagnosticEvidence(
      label: 'Interação',
      count: interactionCount,
      icon: Icons.shield_outlined,
      entries: _entriesFromBucket(
        interactionAnalysis,
        interactionCards,
        cards,
        tagKey: 'removal',
      ),
      description: 'Respostas para criaturas, permanentes e jogadas da mesa.',
    );
    final wipeEvidence = _DiagnosticEvidence(
      label: 'Wipes',
      count: wipeCount,
      icon: Icons.cleaning_services_outlined,
      entries: _entriesFromBucket(
        wipeAnalysis,
        wipeCards,
        cards,
        tagKey: 'board_wipe',
      ),
      description: 'Efeitos que limpam a mesa quando o jogo sai do controle.',
    );
    final curveEvidence = _DiagnosticEvidence(
      label: 'CMC médio',
      count: nonLandCount,
      icon: Icons.show_chart_rounded,
      entries: _entriesFromCards(nonLandCards, sortByCmcDescending: true),
      description: 'Mágicas não-terreno usadas para entender o peso da curva.',
    );

    final landEval = _rangeEvaluation(
      value: landCount,
      min: targets.minLands,
      max: targets.maxLands,
      goodLabel: 'Na faixa',
      lowLabel: 'Baixo',
      highLabel: 'Alto',
      icon: Icons.terrain_rounded,
    );
    final rampEval = _minimumEvaluation(
      value: rampCount,
      min: targets.minRamp,
      goodLabel: 'Boa aceleração',
      warnLabel: 'Ramp curto',
      icon: Icons.bolt_rounded,
    );
    final drawEval = _minimumEvaluation(
      value: drawCount,
      min: targets.minDraw,
      goodLabel: 'Compra estável',
      warnLabel: 'Compra curta',
      icon: Icons.auto_stories_rounded,
    );
    final interactionEval = _minimumEvaluation(
      value: interactionCount,
      min: targets.minInteraction,
      goodLabel: 'Mesa coberta',
      warnLabel: 'Interação curta',
      icon: Icons.shield_outlined,
    );
    final wipeEval = _minimumEvaluation(
      value: wipeCount,
      min: targets.minWipes,
      goodLabel: 'Sweepers ok',
      warnLabel: 'Poucos wipes',
      icon: Icons.cleaning_services_outlined,
    );
    final curveEval = _curveEvaluation(
      averageCmc,
      targets.curveTarget,
      targets.curveWarning,
    );

    final metrics = <_DiagnosticMetric>[
      _DiagnosticMetric(
        label: 'Terrenos',
        value: landCount.toString(),
        status: landEval.label,
        target: 'Alvo ${targets.minLands}-${targets.maxLands}',
        tone: landEval.tone,
        icon: landEval.icon,
        evidence: landEvidence,
      ),
      _DiagnosticMetric(
        label: 'Ramp',
        value: rampCount.toString(),
        status: rampEval.label,
        target: 'Meta ${targets.minRamp}+',
        tone: rampEval.tone,
        icon: rampEval.icon,
        evidence: rampEvidence,
      ),
      _DiagnosticMetric(
        label: 'Compra',
        value: drawCount.toString(),
        status: drawEval.label,
        target: 'Meta ${targets.minDraw}+',
        tone: drawEval.tone,
        icon: drawEval.icon,
        evidence: drawEvidence,
      ),
      _DiagnosticMetric(
        label: 'Interação',
        value: interactionCount.toString(),
        status: interactionEval.label,
        target: 'Meta ${targets.minInteraction}+',
        tone: interactionEval.tone,
        icon: interactionEval.icon,
        evidence: interactionEvidence,
      ),
      _DiagnosticMetric(
        label: 'Wipes',
        value: wipeCount.toString(),
        status: wipeEval.label,
        target: 'Meta ${targets.minWipes}+',
        tone: wipeEval.tone,
        icon: wipeEval.icon,
        evidence: wipeEvidence,
      ),
      _DiagnosticMetric(
        label: 'CMC médio',
        value: averageCmc == 0 ? '-' : averageCmc.toStringAsFixed(1),
        status: curveEval.label,
        target: 'Ideal até ${targets.curveTarget.toStringAsFixed(1)}',
        tone: curveEval.tone,
        icon: curveEval.icon,
        evidence: curveEvidence,
      ),
    ];

    final insights = _buildInsights(
      cards: cards,
      landCount: landCount,
      rampCount: rampCount,
      drawCount: drawCount,
      interactionCount: interactionCount,
      wipeCount: wipeCount,
      averageCmc: averageCmc,
      targets: targets,
    );

    final evidence = <_DiagnosticEvidence>[
      rampEvidence,
      drawEvidence,
      interactionEvidence,
      wipeEvidence,
    ];

    return _DeckDiagnosticSnapshot(
      metrics: metrics,
      evidence: evidence,
      insights: insights,
    );
  }

  static List<_DiagnosticInsight> _buildInsights({
    required List<DeckCardItem> cards,
    required int landCount,
    required int rampCount,
    required int drawCount,
    required int interactionCount,
    required int wipeCount,
    required double averageCmc,
    required _DeckDiagnosticTargets targets,
  }) {
    final totalCards = cards.fold<int>(0, (sum, card) => sum + card.quantity);
    if (totalCards < 20) {
      return const [
        _DiagnosticInsight(
          text: 'Adicione mais cartas para uma leitura mais confiável do deck.',
          icon: Icons.info_outline_rounded,
          tone: _DiagnosticTone.neutral,
        ),
      ];
    }

    final insights = <_PrioritizedInsight>[];

    if (landCount < targets.minLands) {
      insights.add(
        _PrioritizedInsight(
          priority: 5,
          insight: const _DiagnosticInsight(
            text: 'Base de mana curta para o tamanho atual da lista.',
            icon: Icons.terrain_rounded,
            tone: _DiagnosticTone.danger,
          ),
        ),
      );
    } else if (landCount > targets.maxLands) {
      insights.add(
        _PrioritizedInsight(
          priority: 4,
          insight: const _DiagnosticInsight(
            text: 'Terrenos acima do esperado podem reduzir a pressão do deck.',
            icon: Icons.landscape_outlined,
            tone: _DiagnosticTone.warn,
          ),
        ),
      );
    } else {
      insights.add(
        _PrioritizedInsight(
          priority: 1,
          insight: const _DiagnosticInsight(
            text: 'Base de mana na faixa esperada para o formato.',
            icon: Icons.check_circle_outline_rounded,
            tone: _DiagnosticTone.good,
          ),
        ),
      );
    }

    if (rampCount < targets.minRamp) {
      insights.add(
        _PrioritizedInsight(
          priority: 4,
          insight: const _DiagnosticInsight(
            text: 'Ramp curto; o deck tende a acelerar menos do que o ideal.',
            icon: Icons.bolt_rounded,
            tone: _DiagnosticTone.warn,
          ),
        ),
      );
    }

    if (drawCount < targets.minDraw) {
      insights.add(
        _PrioritizedInsight(
          priority: 5,
          insight: const _DiagnosticInsight(
            text:
                'Compra de cartas abaixo do ideal para manter gás no meio da partida.',
            icon: Icons.auto_stories_rounded,
            tone: _DiagnosticTone.danger,
          ),
        ),
      );
    }

    if (interactionCount < targets.minInteraction) {
      insights.add(
        _PrioritizedInsight(
          priority: 5,
          insight: const _DiagnosticInsight(
            text: 'Interação curta; a lista pode sofrer para responder à mesa.',
            icon: Icons.shield_outlined,
            tone: _DiagnosticTone.danger,
          ),
        ),
      );
    } else if (interactionCount >= targets.minInteraction + 2) {
      insights.add(
        _PrioritizedInsight(
          priority: 1,
          insight: const _DiagnosticInsight(
            text: 'Boa densidade de interação para segurar o ritmo da partida.',
            icon: Icons.verified_outlined,
            tone: _DiagnosticTone.good,
          ),
        ),
      );
    }

    if (wipeCount < targets.minWipes && targets.minWipes > 0) {
      insights.add(
        _PrioritizedInsight(
          priority: 3,
          insight: const _DiagnosticInsight(
            text: 'Poucas respostas globais para mesas mais longas.',
            icon: Icons.cleaning_services_outlined,
            tone: _DiagnosticTone.warn,
          ),
        ),
      );
    }

    if (averageCmc > targets.curveWarning) {
      insights.add(
        _PrioritizedInsight(
          priority: 4,
          insight: const _DiagnosticInsight(
            text: 'Curva média alta; o deck pode sair lento sem ajuda de ramp.',
            icon: Icons.show_chart_rounded,
            tone: _DiagnosticTone.warn,
          ),
        ),
      );
    } else if (averageCmc > 0 && averageCmc <= targets.curveTarget) {
      insights.add(
        _PrioritizedInsight(
          priority: 1,
          insight: const _DiagnosticInsight(
            text:
                'Curva leve o bastante para desenvolver a mesa com consistência.',
            icon: Icons.trending_up_rounded,
            tone: _DiagnosticTone.good,
          ),
        ),
      );
    }

    insights.sort((a, b) => b.priority.compareTo(a.priority));
    return insights.take(3).map((item) => item.insight).toList();
  }

  static List<DeckCardItem> _collectWhere(
    List<DeckCardItem> cards,
    bool Function(DeckCardItem card) predicate,
  ) {
    return cards.where(predicate).toList(growable: false);
  }

  static int _sumQuantities(List<DeckCardItem> cards) {
    return cards.fold<int>(0, (sum, card) => sum + card.quantity);
  }

  static List<_DiagnosticEvidenceEntry> _entriesFromCards(
    List<DeckCardItem> cards, {
    bool sortByCmcDescending = false,
  }) {
    final sorted = [...cards]..sort((a, b) {
      if (sortByCmcDescending) {
        final cmcCompare = ManaHelper.calculateCMC(
          b.manaCost,
        ).compareTo(ManaHelper.calculateCMC(a.manaCost));
        if (cmcCompare != 0) return cmcCompare;
      }
      return a.name.compareTo(b.name);
    });
    return sorted
        .map((card) => _DiagnosticEvidenceEntry.fromCard(card))
        .toList(growable: false);
  }

  static List<_DiagnosticEvidenceEntry> _entriesFromBucket(
    _DiagnosticFunctionalBucket? bucket,
    List<DeckCardItem> fallbackCards,
    List<DeckCardItem> allCards, {
    required String tagKey,
  }) {
    if (bucket == null || bucket.samples.isEmpty) {
      return _entriesFromCards(fallbackCards);
    }

    final cardsByName = <String, DeckCardItem>{};
    for (final card in allCards) {
      cardsByName[_normalizeCardName(card.name)] = card;
    }

    final entries = <_DiagnosticEvidenceEntry>[];
    final seen = <String>{};

    void addEntry(_DiagnosticEvidenceEntry entry) {
      final key = _normalizeCardName(entry.name);
      if (key.isEmpty || !seen.add(key)) return;
      entries.add(entry);
    }

    for (final sample in bucket.samples) {
      final card = cardsByName[_normalizeCardName(sample.name)];
      addEntry(
        _DiagnosticEvidenceEntry(
          name: sample.name,
          quantity: card?.quantity,
          card: card,
          detail: _friendlyEvidenceReasonForKey(tagKey),
        ),
      );
    }

    for (final entry in _entriesFromCards(fallbackCards)) {
      addEntry(
        _DiagnosticEvidenceEntry(
          name: entry.name,
          quantity: entry.quantity,
          card: entry.card,
          detail: entry.detail ?? _friendlyEvidenceReasonForKey(tagKey),
        ),
      );
    }

    return entries;
  }

  static _DiagnosticFunctionalBucket? _analysisBucket(
    DeckAnalysisData? analysis, {
    required String tagKey,
    required String compositionKey,
  }) {
    if (analysis == null) return null;
    final hasFunctionalCount =
        analysis.functionalTags?.counts.containsKey(tagKey) ?? false;
    final hasLegacyCount = analysis.composition.containsKey(compositionKey);
    if (!hasFunctionalCount && !hasLegacyCount) return null;

    return _DiagnosticFunctionalBucket(
      count: analysis.countFor(tagKey: tagKey, compositionKey: compositionKey),
      samples: _formatFunctionalSamples(analysis.samplesFor(tagKey)),
    );
  }

  static List<DeckFunctionalTagSample> _formatFunctionalSamples(
    List<DeckFunctionalTagSample> samples,
  ) {
    final byName = <String, DeckFunctionalTagSample>{};
    for (final sample in samples) {
      final key = _normalizeCardName(sample.name);
      if (key.isEmpty) continue;
      byName.putIfAbsent(key, () => sample);
    }
    final values = byName.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    return values;
  }

  static String _normalizeCardName(String value) {
    return value.trim().toLowerCase();
  }

  static String _friendlyEvidenceReasonForKey(String key) {
    switch (key) {
      case 'ramp':
        return _friendlyEvidenceReason('Ramp');
      case 'draw':
        return _friendlyEvidenceReason('Compra');
      case 'removal':
        return _friendlyEvidenceReason('Interação');
      case 'board_wipe':
        return _friendlyEvidenceReason('Wipes');
      default:
        return 'Carta considerada nesta leitura do deck.';
    }
  }

  static bool _isLand(DeckCardItem card) =>
      card.typeLine.toLowerCase().contains('land');

  static bool _isRamp(DeckCardItem card) {
    final type = card.typeLine.toLowerCase();
    final text = (card.oracleText ?? '').toLowerCase();
    final manaCost = ManaHelper.calculateCMC(card.manaCost);

    final createsMana =
        text.contains('add {') ||
        text.contains('add one mana of any color') ||
        text.contains('create a treasure token') ||
        text.contains('create a tapped treasure token');
    final fetchesLand =
        text.contains('search your library for a basic land') ||
        text.contains('search your library for up to two basic land cards') ||
        (text.contains('search your library') && text.contains('land card'));

    return createsMana &&
            (type.contains('artifact') ||
                type.contains('creature') ||
                manaCost <= 3) ||
        fetchesLand;
  }

  static bool _isDraw(DeckCardItem card) {
    final text = (card.oracleText ?? '').toLowerCase();
    return text.contains('draw a card') ||
        text.contains('draw two cards') ||
        text.contains('draw three cards') ||
        text.contains('draw x cards') ||
        text.contains('draw cards') ||
        text.contains('draw that many') ||
        text.contains('draw equal') ||
        text.contains('draws a card') ||
        text.contains('draw, then') ||
        text.contains('draw and discard') ||
        text.contains('you may draw') ||
        text.contains('put that card into your hand') ||
        text.contains('put one of them into your hand') ||
        text.contains('put a card from among them into your hand') ||
        text.contains('exile the top card') && text.contains('you may play') ||
        text.contains('exile the top two cards') &&
            text.contains('you may play') ||
        text.contains('exile cards from the top') &&
            text.contains('you may play') ||
        text.contains('investigate') ||
        text.contains('connive');
  }

  static bool _isInteraction(DeckCardItem card) {
    final text = (card.oracleText ?? '').toLowerCase();
    return text.contains('counter target') ||
        text.contains('destroy target') ||
        text.contains('exile target') ||
        text.contains('return target') ||
        text.contains('fight target') ||
        text.contains('deals 3 damage to any target') ||
        text.contains('deals 2 damage to any target') ||
        text.contains('deals 4 damage to any target') ||
        text.contains('target player sacrifices') ||
        text.contains('tap target');
  }

  static bool _isWipe(DeckCardItem card) {
    final text = (card.oracleText ?? '').toLowerCase();
    return text.contains('destroy all') ||
        text.contains('exile all') ||
        text.contains('all creatures get -') ||
        text.contains('each creature gets -') ||
        text.contains('each player sacrifices all');
  }

  static _MetricEvaluation _rangeEvaluation({
    required int value,
    required int min,
    required int max,
    required String goodLabel,
    required String lowLabel,
    required String highLabel,
    required IconData icon,
  }) {
    if (value < min) {
      return _MetricEvaluation(
        label: lowLabel,
        tone: _DiagnosticTone.danger,
        icon: icon,
      );
    }
    if (value > max) {
      return _MetricEvaluation(
        label: highLabel,
        tone: _DiagnosticTone.warn,
        icon: icon,
      );
    }
    return _MetricEvaluation(
      label: goodLabel,
      tone: _DiagnosticTone.good,
      icon: icon,
    );
  }

  static _MetricEvaluation _minimumEvaluation({
    required int value,
    required int min,
    required String goodLabel,
    required String warnLabel,
    required IconData icon,
  }) {
    if (value < min) {
      return _MetricEvaluation(
        label: warnLabel,
        tone: value == 0 ? _DiagnosticTone.danger : _DiagnosticTone.warn,
        icon: icon,
      );
    }
    return _MetricEvaluation(
      label: goodLabel,
      tone: _DiagnosticTone.good,
      icon: icon,
    );
  }

  static _MetricEvaluation _curveEvaluation(
    double value,
    double target,
    double warning,
  ) {
    if (value == 0) {
      return const _MetricEvaluation(
        label: 'Sem leitura',
        tone: _DiagnosticTone.neutral,
        icon: Icons.show_chart_rounded,
      );
    }
    if (value > warning) {
      return const _MetricEvaluation(
        label: 'Curva alta',
        tone: _DiagnosticTone.warn,
        icon: Icons.show_chart_rounded,
      );
    }
    if (value > target) {
      return const _MetricEvaluation(
        label: 'Curva média',
        tone: _DiagnosticTone.warn,
        icon: Icons.show_chart_rounded,
      );
    }
    return const _MetricEvaluation(
      label: 'Curva leve',
      tone: _DiagnosticTone.good,
      icon: Icons.show_chart_rounded,
    );
  }
}

class _DeckDiagnosticTargets {
  final int minLands;
  final int maxLands;
  final int minRamp;
  final int minDraw;
  final int minInteraction;
  final int minWipes;
  final double curveTarget;
  final double curveWarning;

  const _DeckDiagnosticTargets({
    required this.minLands,
    required this.maxLands,
    required this.minRamp,
    required this.minDraw,
    required this.minInteraction,
    required this.minWipes,
    required this.curveTarget,
    required this.curveWarning,
  });

  factory _DeckDiagnosticTargets.fromDeck(DeckDetails deck) {
    final format = deck.format.toLowerCase();
    if (format == 'commander') {
      return const _DeckDiagnosticTargets(
        minLands: 33,
        maxLands: 38,
        minRamp: 8,
        minDraw: 8,
        minInteraction: 8,
        minWipes: 2,
        curveTarget: 3.6,
        curveWarning: 4.1,
      );
    }
    if (format == 'brawl') {
      return const _DeckDiagnosticTargets(
        minLands: 24,
        maxLands: 27,
        minRamp: 5,
        minDraw: 6,
        minInteraction: 6,
        minWipes: 1,
        curveTarget: 3.2,
        curveWarning: 3.7,
      );
    }
    return const _DeckDiagnosticTargets(
      minLands: 22,
      maxLands: 26,
      minRamp: 3,
      minDraw: 5,
      minInteraction: 6,
      minWipes: 1,
      curveTarget: 3.1,
      curveWarning: 3.6,
    );
  }
}

enum _DiagnosticTone { good, warn, danger, neutral }

extension on _DiagnosticTone {
  Color get foreground {
    switch (this) {
      case _DiagnosticTone.good:
        return AppTheme.success;
      case _DiagnosticTone.warn:
        return AppTheme.mythicGold;
      case _DiagnosticTone.danger:
        return AppTheme.error;
      case _DiagnosticTone.neutral:
        return AppTheme.primarySoft;
    }
  }

  Color get border => foreground.withValues(alpha: 0.35);

  Color get background => foreground.withValues(alpha: 0.12);
}

class _DiagnosticMetric {
  final String label;
  final String value;
  final String status;
  final String target;
  final _DiagnosticTone tone;
  final IconData icon;
  final _DiagnosticEvidence evidence;

  const _DiagnosticMetric({
    required this.label,
    required this.value,
    required this.status,
    required this.target,
    required this.tone,
    required this.icon,
    required this.evidence,
  });
}

class _DiagnosticEvidence {
  final String label;
  final int count;
  final IconData icon;
  final List<_DiagnosticEvidenceEntry> entries;
  final String description;

  const _DiagnosticEvidence({
    required this.label,
    required this.count,
    required this.icon,
    required this.entries,
    required this.description,
  });

  List<String> get previewLabels {
    return entries.map((entry) => entry.previewLabel).toList(growable: false);
  }
}

class _DiagnosticEvidenceEntry {
  final String name;
  final int? quantity;
  final DeckCardItem? card;
  final String? detail;

  const _DiagnosticEvidenceEntry({
    required this.name,
    this.quantity,
    this.card,
    this.detail,
  });

  factory _DiagnosticEvidenceEntry.fromCard(DeckCardItem card) {
    return _DiagnosticEvidenceEntry(
      name: card.name,
      quantity: card.quantity,
      card: card,
    );
  }

  String get previewLabel {
    final suffix = quantity != null && quantity! > 1 ? ' x$quantity' : '';
    return '$name$suffix';
  }
}

class _DiagnosticFunctionalBucket {
  final int count;
  final List<DeckFunctionalTagSample> samples;

  const _DiagnosticFunctionalBucket({
    required this.count,
    required this.samples,
  });
}

class _MetricEvaluation {
  final String label;
  final _DiagnosticTone tone;
  final IconData icon;

  const _MetricEvaluation({
    required this.label,
    required this.tone,
    required this.icon,
  });
}

class _DiagnosticInsight {
  final String text;
  final IconData icon;
  final _DiagnosticTone tone;

  const _DiagnosticInsight({
    required this.text,
    required this.icon,
    required this.tone,
  });
}

class _PrioritizedInsight {
  final int priority;
  final _DiagnosticInsight insight;

  const _PrioritizedInsight({required this.priority, required this.insight});
}
