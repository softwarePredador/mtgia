import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../../core/utils/mana_helper.dart';
import '../providers/deck_provider.dart';
import '../models/deck_details.dart';

class DeckAnalysisTab extends StatefulWidget {
  final DeckDetails deck;

  const DeckAnalysisTab({super.key, required this.deck});

  @override
  State<DeckAnalysisTab> createState() => _DeckAnalysisTabState();
}

class _DeckAnalysisTabState extends State<DeckAnalysisTab> {
  bool _isRefreshingAi = false;
  bool _autoAnalysisTriggered = false;

  // Cached analysis data — recalculated only when deck changes
  String? _cachedDeckId;
  int _cachedCardCount = -1;
  List<int> _cachedManaCurve = List<int>.filled(8, 0);
  Map<String, int> _cachedColorCounts = {};

  void _recalculateIfNeeded(DeckDetails deck) {
    final allCards = [
      ...deck.commander,
      ...deck.mainBoard.values.expand((l) => l),
    ];
    final cardCount = allCards.fold<int>(0, (s, c) => s + c.quantity);
    if (deck.id == _cachedDeckId && cardCount == _cachedCardCount) return;

    _cachedDeckId = deck.id;
    _cachedCardCount = cardCount;

    // Mana curve
    final manaCurve = List<int>.filled(8, 0);
    for (var card in allCards) {
      if (card.typeLine.toLowerCase().contains('land')) continue;
      final cmc = ManaHelper.calculateCMC(card.manaCost);
      final index = cmc >= 7 ? 7 : cmc;
      manaCurve[index] += card.quantity;
    }
    _cachedManaCurve = manaCurve;

    // Color distribution
    final colorCounts = <String, int>{
      'W': 0,
      'U': 0,
      'B': 0,
      'R': 0,
      'G': 0,
      'C': 0,
    };
    for (var card in allCards) {
      if (card.typeLine.toLowerCase().contains('land')) continue;
      final pips = ManaHelper.countColorPips(card.manaCost);
      pips.forEach((color, count) {
        if (colorCounts.containsKey(color)) {
          colorCounts[color] =
              (colorCounts[color] ?? 0) + (count * card.quantity);
        }
      });
    }
    _cachedColorCounts = colorCounts;
  }

  Future<void> _refreshAi({bool force = false}) async {
    if (_isRefreshingAi) return;
    setState(() => _isRefreshingAi = true);

    try {
      await context.read<DeckProvider>().refreshAiAnalysis(
        widget.deck.id,
        force: force,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshingAi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deck = context.select<DeckProvider, DeckDetails?>(
      (p) => p.selectedDeck,
    );
    final effectiveDeck =
        (deck != null && deck.id == widget.deck.id) ? deck : widget.deck;

    // Auto-trigger AI analysis for decks with enough cards that were never analyzed
    final hasAnalysis =
        (effectiveDeck.synergyScore ?? 0) > 0 ||
        (effectiveDeck.strengths ?? '').trim().isNotEmpty ||
        (effectiveDeck.weaknesses ?? '').trim().isNotEmpty;
    final totalCardCount = effectiveDeck.cardCount;
    if (!_autoAnalysisTriggered &&
        !_isRefreshingAi &&
        !hasAnalysis &&
        totalCardCount >= 60) {
      _autoAnalysisTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshAi();
      });
    }

    // Use cached mana curve & color distribution (recalculated only when deck changes)
    _recalculateIfNeeded(effectiveDeck);
    final manaCurve = _cachedManaCurve;
    final colorCounts = _cachedColorCounts;
    final hasAiSummary =
        (effectiveDeck.synergyScore ?? 0) > 0 ||
        ((effectiveDeck.strengths ?? '').trim().isNotEmpty) ||
        ((effectiveDeck.weaknesses ?? '').trim().isNotEmpty);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análise do deck',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Resumo de sinergia, curva e pressão de cor para apoiar decisões reais no deck.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _AnalysisActionBar(
            hasAnalysis: hasAiSummary,
            isRefreshing: _isRefreshingAi,
            onRefresh: () => _refreshAi(force: hasAiSummary),
          ),
          if (_isRefreshingAi) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Atualizando leitura do deck...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (hasAiSummary) ...[
            _SectionCard(
              title: 'Leitura de sinergia',
              subtitle: 'Resumo qualitativo da IA sobre o plano atual do deck.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (effectiveDeck.synergyScore != null) ...[
                    _AnalysisCard(
                      title: 'Score de sinergia',
                      score: effectiveDeck.synergyScore!,
                      color: AppTheme.manaViolet,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if ((effectiveDeck.strengths ?? '').trim().isNotEmpty)
                    _InsightBlock(
                      title: 'Pontos fortes',
                      icon: Icons.trending_up,
                      accent: AppTheme.success,
                      text: effectiveDeck.strengths!,
                    ),
                  if ((effectiveDeck.strengths ?? '').trim().isNotEmpty &&
                      (effectiveDeck.weaknesses ?? '').trim().isNotEmpty)
                    const SizedBox(height: 12),
                  if ((effectiveDeck.weaknesses ?? '').trim().isNotEmpty)
                    _InsightBlock(
                      title: 'Pontos fracos',
                      icon: Icons.warning_amber_rounded,
                      accent: AppTheme.warning,
                      text: effectiveDeck.weaknesses!,
                    ),
                ],
              ),
            ),
          ] else ...[
            _SectionCard(
              title: 'Sinergia ainda não gerada',
              subtitle:
                  'A IA ainda não resumiu os pontos fortes e fracos desta lista.',
              child: Text(
                'Use "Gerar análise" para produzir uma leitura executiva do plano do deck antes de otimizar.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Curva de mana',
            subtitle:
                'Distribuição de custo das mágicas, sem considerar terrenos.',
            child:
                manaCurve.every((v) => v == 0)
                    ? SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Adicione mágicas ao deck para ver a curva de mana.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              (manaCurve.reduce((a, b) => a > b ? a : b) + 1)
                                  .toDouble(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => AppTheme.surfaceSlate,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index == 7) return const Text('7+');
                                  return Text(index.toString());
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(8, (index) {
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: manaCurve[index].toDouble(),
                                  color: theme.colorScheme.primary,
                                  width: 16,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppTheme.radiusXs),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Distribuição de cores',
            subtitle:
                'Leitura baseada nos símbolos de mana das mágicas do deck.',
            child:
                colorCounts.values.every((v) => v == 0)
                    ? SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Adicione mágicas coloridas para ver a distribuição de cores.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : SizedBox(
                      height: 200,
                      child: Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: _buildPieSections(colorCounts),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildLegend(colorCounts),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, int> counts) {
    final total = counts.values.fold(0, (sum, item) => sum + item);
    if (total == 0) return [];

    final colorsMap = AppTheme.wubrg;

    return counts.entries.where((e) => e.value > 0).map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: colorsMap[entry.key] ?? AppTheme.disabled,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: AppTheme.fontSm,
          fontWeight: FontWeight.bold,
          color: AppTheme.backgroundAbyss,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend(Map<String, int> counts) {
    final namesMap = {
      'W': 'Branco',
      'U': 'Azul',
      'B': 'Preto',
      'R': 'Vermelho',
      'G': 'Verde',
      'C': 'Incolor',
    };

    final colorsMap = AppTheme.wubrg;

    return counts.entries.where((e) => e.value > 0).map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colorsMap[entry.key],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text('${namesMap[entry.key]}: ${entry.value}'),
          ],
        ),
      );
    }).toList();
  }
}

class _AnalysisActionBar extends StatelessWidget {
  final bool hasAnalysis;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _AnalysisActionBar({
    required this.hasAnalysis,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            hasAnalysis ? 'Leitura pronta' : 'Leitura pendente',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: isRefreshing ? null : onRefresh,
          icon: Icon(hasAnalysis ? Icons.refresh : Icons.auto_awesome),
          label: Text(hasAnalysis ? 'Atualizar análise' : 'Gerar análise'),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InsightBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final String text;

  const _InsightBlock({
    required this.title,
    required this.icon,
    required this.accent,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary.withValues(alpha: 0.88),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final int score;
  final Color color;

  const _AnalysisCard({
    required this.title,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircularProgressIndicator(
              value: score / 100,
              color: color,
              backgroundColor: color.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '$score/100',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
