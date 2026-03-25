import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/mana_helper.dart';
import '../models/deck_card_item.dart';
import '../models/deck_details.dart';

class DeckDiagnosticPanel extends StatelessWidget {
  final DeckDetails deck;
  final VoidCallback? onOpenAnalysis;

  const DeckDiagnosticPanel({
    super.key,
    required this.deck,
    this.onOpenAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = _DeckDiagnosticSnapshot.fromDeck(deck);
    final hasWarnings = snapshot.metrics.any(
      (metric) =>
          identical(metric.tone, _DiagnosticTone.danger) ||
          identical(metric.tone, _DiagnosticTone.warn),
    );
    final summaryTone =
        hasWarnings ? _DiagnosticTone.warn : _DiagnosticTone.good;
    final summaryLabel = hasWarnings ? 'Pontos de atenção' : 'Base saudável';

    return Container(
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
                              'Leitura rápida do deck',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Resumo local de mana, curva e interação para orientar os próximos ajustes.',
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
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Indicadores principais',
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
                            child: _DiagnosticMetricCard(metric: metric),
                          ),
                        )
                        .toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Diagnóstico textual',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...snapshot.insights.map((insight) => _DiagnosticInsightRow(insight)),
        ],
      ),
    );
  }
}

class _DiagnosticMetricCard extends StatelessWidget {
  final _DiagnosticMetric metric;

  const _DiagnosticMetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 170;

        return Container(
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
        );
      },
    );
  }
}

class _DiagnosticInsightRow extends StatelessWidget {
  final _DiagnosticInsight insight;

  const _DiagnosticInsightRow(this.insight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
  final List<_DiagnosticInsight> insights;

  const _DeckDiagnosticSnapshot({
    required this.metrics,
    required this.insights,
  });

  factory _DeckDiagnosticSnapshot.fromDeck(DeckDetails deck) {
    final cards = deck.mainBoard.values.expand((list) => list).toList();
    final targets = _DeckDiagnosticTargets.fromDeck(deck);

    final landCount = _sumWhere(cards, (card) => _isLand(card));
    final rampCount = _sumWhere(
      cards,
      (card) => !_isLand(card) && _isRamp(card),
    );
    final drawCount = _sumWhere(
      cards,
      (card) => !_isLand(card) && _isDraw(card),
    );
    final interactionCount = _sumWhere(
      cards,
      (card) => !_isLand(card) && _isInteraction(card),
    );
    final wipeCount = _sumWhere(
      cards,
      (card) => !_isLand(card) && _isWipe(card),
    );

    var weightedCmc = 0;
    var nonLandCount = 0;
    for (final card in cards) {
      if (_isLand(card)) continue;
      final quantity = card.quantity <= 0 ? 1 : card.quantity;
      weightedCmc += ManaHelper.calculateCMC(card.manaCost) * quantity;
      nonLandCount += quantity;
    }
    final averageCmc = nonLandCount == 0 ? 0.0 : weightedCmc / nonLandCount;

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
      ),
      _DiagnosticMetric(
        label: 'Ramp',
        value: rampCount.toString(),
        status: rampEval.label,
        target: 'Meta ${targets.minRamp}+',
        tone: rampEval.tone,
        icon: rampEval.icon,
      ),
      _DiagnosticMetric(
        label: 'Compra',
        value: drawCount.toString(),
        status: drawEval.label,
        target: 'Meta ${targets.minDraw}+',
        tone: drawEval.tone,
        icon: drawEval.icon,
      ),
      _DiagnosticMetric(
        label: 'Interação',
        value: interactionCount.toString(),
        status: interactionEval.label,
        target: 'Meta ${targets.minInteraction}+',
        tone: interactionEval.tone,
        icon: interactionEval.icon,
      ),
      _DiagnosticMetric(
        label: 'Wipes',
        value: wipeCount.toString(),
        status: wipeEval.label,
        target: 'Meta ${targets.minWipes}+',
        tone: wipeEval.tone,
        icon: wipeEval.icon,
      ),
      _DiagnosticMetric(
        label: 'CMC médio',
        value: averageCmc == 0 ? '-' : averageCmc.toStringAsFixed(1),
        status: curveEval.label,
        target: 'Ideal até ${targets.curveTarget.toStringAsFixed(1)}',
        tone: curveEval.tone,
        icon: curveEval.icon,
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

    return _DeckDiagnosticSnapshot(metrics: metrics, insights: insights);
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

  static int _sumWhere(
    List<DeckCardItem> cards,
    bool Function(DeckCardItem card) predicate,
  ) {
    return cards.fold<int>(
      0,
      (sum, card) => predicate(card) ? sum + card.quantity : sum,
    );
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
        minLands: 34,
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

  const _DiagnosticMetric({
    required this.label,
    required this.value,
    required this.status,
    required this.target,
    required this.tone,
    required this.icon,
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
