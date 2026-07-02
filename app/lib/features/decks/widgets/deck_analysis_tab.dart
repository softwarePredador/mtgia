import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/utils/mana_helper.dart';
import 'package:provider/provider.dart';

import '../providers/deck_provider.dart';
import '../models/deck_analysis.dart';
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
  final Set<String> _autoFetchedFunctionalDeckIds = <String>{};

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

  void _scheduleFunctionalAnalysisFetch(String deckId) {
    if (_autoFetchedFunctionalDeckIds.contains(deckId)) return;
    _autoFetchedFunctionalDeckIds.add(deckId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeckProvider>().fetchDeckAnalysis(deckId);
    });
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
    final allCards = [
      ...effectiveDeck.commander,
      ...effectiveDeck.mainBoard.values.expand((l) => l),
    ];
    final landCount = allCards
        .where((card) => card.typeLine.toLowerCase().contains('land'))
        .fold<int>(0, (sum, card) => sum + card.quantity);
    final spellCards =
        allCards
            .where((card) => !card.typeLine.toLowerCase().contains('land'))
            .toList();
    final spellQuantity = spellCards.fold<int>(
      0,
      (sum, card) => sum + card.quantity,
    );
    final averageCmc =
        spellQuantity == 0
            ? 0.0
            : spellCards.fold<double>(
                  0,
                  (sum, card) =>
                      sum +
                      (ManaHelper.calculateCMC(card.manaCost) * card.quantity),
                ) /
                spellQuantity;
    final hasAiSummary =
        (effectiveDeck.synergyScore ?? 0) > 0 ||
        ((effectiveDeck.strengths ?? '').trim().isNotEmpty) ||
        ((effectiveDeck.weaknesses ?? '').trim().isNotEmpty);
    _scheduleFunctionalAnalysisFetch(effectiveDeck.id);
    final functionalAnalysis = context.select<DeckProvider, DeckAnalysisData?>(
      (p) => p.deckAnalysisFor(effectiveDeck.id),
    );
    final functionalAnalysisLoading = context.select<DeckProvider, bool>(
      (p) => p.isDeckAnalysisLoading(effectiveDeck.id),
    );
    final functionalAnalysisError = context.select<DeckProvider, String?>(
      (p) => p.deckAnalysisErrorFor(effectiveDeck.id),
    );

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
          _AnalysisSummaryStrip(
            legalityScore: _legalityScore(effectiveDeck),
            priceLabel:
                effectiveDeck.pricingTotal == null
                    ? 'N/D'
                    : 'R\$ ${effectiveDeck.pricingTotal!.toStringAsFixed(0)}',
            averageCmc: averageCmc,
            landCount: landCount,
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
                  height: AppTheme.lineHeightCompact,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _SectionCard(
            key: Key('deck-analysis-functional-section-${effectiveDeck.id}'),
            title: 'Funções do deck',
            subtitle:
                'Entenda quais cartas entraram nas contagens de ramp, compra, remoção, wipes e proteção.',
            child: _FunctionalTagsOverview(
              deckId: effectiveDeck.id,
              analysis: functionalAnalysis,
              isLoading: functionalAnalysisLoading,
              errorMessage: functionalAnalysisError,
              onRefresh:
                  () => context.read<DeckProvider>().fetchDeckAnalysis(
                    effectiveDeck.id,
                    forceRefresh: true,
                  ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Base de mana',
            subtitle:
                'Curva e pressão de cor agrupadas em uma leitura única do deck.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AnalysisSubsectionHeader(
                  title: 'Curva de mana',
                  subtitle:
                      'Distribuição de custo das mágicas, sem considerar terrenos.',
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 18),
                Divider(color: AppTheme.outlineMuted.withValues(alpha: 0.35)),
                const SizedBox(height: 18),
                const _AnalysisSubsectionHeader(
                  title: 'Distribuição de cores',
                  subtitle:
                      'Leitura baseada nos símbolos de mana das mágicas do deck.',
                ),
                const SizedBox(height: 10),
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
                            children: _buildLegend(context, colorCounts),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _legalityScore(DeckDetails deck) {
    final format = deck.format.toLowerCase();
    final target = format == 'commander' ? 100 : (format == 'brawl' ? 60 : 60);
    final hasCommander =
        (format == 'commander' || format == 'brawl')
            ? deck.commander.isNotEmpty
            : true;
    final countScore = ((deck.cardCount / target).clamp(0.0, 1.0) * 85).round();
    return (countScore + (hasCommander ? 15 : 0)).clamp(0, 100);
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

  List<Widget> _buildLegend(BuildContext context, Map<String, int> counts) {
    const namesMap = {
      'W': 'Branco',
      'U': 'Azul',
      'B': 'Preto',
      'R': 'Vermelho',
      'G': 'Verde',
      'C': 'Incolor',
    };
    final textTheme = Theme.of(context).textTheme;

    final colorsMap = AppTheme.wubrg;

    return counts.entries.where((e) => e.value > 0).map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colorsMap[entry.key],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              namesMap[entry.key]!,
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary.withValues(alpha: 0.94),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${entry.value}',
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _AnalysisSummaryStrip extends StatelessWidget {
  const _AnalysisSummaryStrip({
    required this.legalityScore,
    required this.priceLabel,
    required this.averageCmc,
    required this.landCount,
  });

  final int legalityScore;
  final String priceLabel;
  final double averageCmc;
  final int landCount;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.74,
      children: [
        _SummaryMetricRing(
          label: 'Legalidade',
          value: '$legalityScore/100',
          accent: AppTheme.success,
        ),
        _SummaryMetricRing(
          label: 'Preço total',
          value: priceLabel,
          accent: AppTheme.brass400,
        ),
        _SummaryMetricRing(
          label: 'Curva média',
          value: averageCmc.toStringAsFixed(1),
          accent: AppTheme.frost400,
        ),
        _SummaryMetricRing(
          label: 'Terrenos',
          value: '$landCount',
          accent: AppTheme.frost600,
        ),
      ],
    );
  }
}

class _SummaryMetricRing extends StatelessWidget {
  const _SummaryMetricRing({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: accent.withValues(alpha: 0.42),
          width: AppTheme.strokeRegular,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 2),
              color: accent.withValues(alpha: 0.08),
            ),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
    final theme = Theme.of(context);
    final accent = hasAnalysis ? AppTheme.success : theme.colorScheme.primary;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasAnalysis
                    ? Icons.check_circle_outline
                    : Icons.pending_outlined,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 8),
              Text(
                hasAnalysis ? 'Leitura pronta' : 'Leitura pendente',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        FilledButton.tonalIcon(
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
    super.key,
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
        color: AppTheme.surfaceElevated.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.45),
          width: AppTheme.strokeThin,
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

class _FunctionalBucketSpec {
  const _FunctionalBucketSpec({
    required this.key,
    required this.tagKey,
    required this.compositionKey,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String key;
  final String tagKey;
  final String compositionKey;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
}

const _functionalBuckets = <_FunctionalBucketSpec>[
  _FunctionalBucketSpec(
    key: 'ramp',
    tagKey: 'ramp',
    compositionKey: 'ramp',
    label: 'Ramp',
    description: 'Aceleração de mana e busca/geração de recursos.',
    icon: Icons.bolt_rounded,
    color: AppTheme.success,
  ),
  _FunctionalBucketSpec(
    key: 'draw',
    tagKey: 'draw',
    compositionKey: 'draw',
    label: 'Compra',
    description: 'Cartas que repõem mão ou geram seleção de cartas.',
    icon: Icons.style_rounded,
    color: AppTheme.loomCyan,
  ),
  _FunctionalBucketSpec(
    key: 'removal',
    tagKey: 'removal',
    compositionKey: 'removal',
    label: 'Remoção',
    description: 'Interações pontuais contra ameaças da mesa.',
    icon: Icons.gps_fixed_rounded,
    color: AppTheme.warning,
  ),
  _FunctionalBucketSpec(
    key: 'wipes',
    tagKey: 'board_wipe',
    compositionKey: 'board_wipes',
    label: 'Wipes',
    description: 'Efeitos globais para resetar criaturas ou permanentes.',
    icon: Icons.cleaning_services_rounded,
    color: AppTheme.error,
  ),
  _FunctionalBucketSpec(
    key: 'protection',
    tagKey: 'protection',
    compositionKey: 'protection',
    label: 'Proteção',
    description: 'Respostas que protegem comandante, plano ou permanentes.',
    icon: Icons.shield_outlined,
    color: AppTheme.manaViolet,
  ),
  _FunctionalBucketSpec(
    key: 'tutor',
    tagKey: 'tutor',
    compositionKey: 'tutor',
    label: 'Tutors',
    description: 'Busca cartas específicas sem contar buscas de terrenos.',
    icon: Icons.manage_search_rounded,
    color: AppTheme.mythicGold,
  ),
  _FunctionalBucketSpec(
    key: 'recursion',
    tagKey: 'recursion',
    compositionKey: 'recursion',
    label: 'Recursão',
    description:
        'Recupera recursos do cemitério para mão, campo ou conjuração.',
    icon: Icons.restore_rounded,
    color: AppTheme.loomCyan,
  ),
  _FunctionalBucketSpec(
    key: 'wincon',
    tagKey: 'wincon',
    compositionKey: 'wincon',
    label: 'Wincons',
    description: 'Cartas que ajudam a fechar ou vencer a partida.',
    icon: Icons.emoji_events_outlined,
    color: AppTheme.success,
  ),
];

class _FunctionalTagsOverview extends StatelessWidget {
  const _FunctionalTagsOverview({
    required this.deckId,
    required this.analysis,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
  });

  final String deckId;
  final DeckAnalysisData? analysis;
  final bool isLoading;
  final String? errorMessage;
  final Future<DeckAnalysisData?> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading && analysis == null) {
      return const _FunctionalAnalysisStatus(
        key: Key('deck-analysis-functional-loading'),
        icon: Icons.hourglass_top_rounded,
        message: 'Carregando contagens funcionais do backend...',
        child: Padding(
          padding: EdgeInsets.only(top: 12),
          child: LinearProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null && analysis == null) {
      return _FunctionalAnalysisStatus(
        key: const Key('deck-analysis-functional-error'),
        icon: Icons.info_outline_rounded,
        message: errorMessage!,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: OutlinedButton.icon(
            key: const Key('deck-analysis-functional-retry-button'),
            onPressed: () => onRefresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ),
      );
    }

    final data = analysis;
    if (data == null || !data.hasAnyCounts) {
      return _FunctionalAnalysisStatus(
        key: const Key('deck-analysis-functional-empty'),
        icon: Icons.category_outlined,
        message:
            'As funções ainda não estão disponíveis para este deck. Atualize para buscar a leitura do backend.',
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton.tonalIcon(
            key: const Key('deck-analysis-functional-refresh-button'),
            onPressed: isLoading ? null : () => onRefresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Atualizar funções'),
          ),
        ),
      );
    }

    final coverage = data.functionalTags?.coverage;
    final coverageRatio = coverage?.taggedCopyRatio;
    final coverageText = coverage?.summary ?? 'Amostras não informadas';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: Key('deck-analysis-functional-origin-$deckId'),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.outlineMuted.withValues(alpha: 0.35),
              width: AppTheme.strokeThin,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _FunctionalInfoChip(
                    icon: Icons.source_outlined,
                    label: data.sourceLabel,
                  ),
                  _FunctionalInfoChip(
                    icon: Icons.analytics_outlined,
                    label: coverageText,
                  ),
                  if (data.functionalTags?.source?.hasAnySignal == true)
                    _FunctionalInfoChip(
                      icon: Icons.account_tree_outlined,
                      label: data.functionalTags!.source!.summary,
                    ),
                ],
              ),
              if (coverageRatio != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  child: LinearProgressIndicator(
                    value: coverageRatio.clamp(0, 1).toDouble(),
                    minHeight: 5,
                    color: AppTheme.loomCyan,
                    backgroundColor: AppTheme.outlineMuted.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
              ],
              if (!data.hasFunctionalTags) ...[
                const SizedBox(height: 8),
                Text(
                  'Resposta legada: contagens visíveis, mas sem amostras de cartas.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._functionalBuckets.map(
          (bucket) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FunctionalBucketTile(
              deckId: deckId,
              bucket: bucket,
              analysis: data,
            ),
          ),
        ),
        if (isLoading) ...[
          const SizedBox(height: 2),
          Text(
            'Atualizando funções...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _FunctionalAnalysisStatus extends StatelessWidget {
  const _FunctionalAnalysisStatus({
    super.key,
    required this.icon,
    required this.message,
    this.child,
  });

  final IconData icon;
  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.35),
          width: AppTheme.strokeThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary.withValues(alpha: 0.88),
                    height: AppTheme.lineHeightCompact,
                  ),
                ),
              ),
            ],
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _FunctionalInfoChip extends StatelessWidget {
  const _FunctionalInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.loomCyan),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FunctionalBucketTile extends StatelessWidget {
  const _FunctionalBucketTile({
    required this.deckId,
    required this.bucket,
    required this.analysis,
  });

  final String deckId;
  final _FunctionalBucketSpec bucket;
  final DeckAnalysisData analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = analysis.countFor(
      tagKey: bucket.tagKey,
      compositionKey: bucket.compositionKey,
    );
    final samples = analysis.samplesFor(bucket.tagKey);
    final samplePreview =
        samples.isEmpty
            ? 'Sem amostras nesta resposta.'
            : samples.take(2).map((sample) => sample.name).join(', ');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate2.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: bucket.color.withValues(alpha: 0.2),
          width: AppTheme.strokeThin,
        ),
      ),
      child: ExpansionTile(
        key: Key('deck-analysis-functional-bucket-$deckId-${bucket.key}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        iconColor: bucket.color,
        collapsedIconColor: AppTheme.textSecondary,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bucket.color.withValues(alpha: 0.13),
            shape: BoxShape.circle,
          ),
          child: Icon(bucket.icon, color: bucket.color, size: 19),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                bucket.label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              key: Key('deck-analysis-functional-count-$deckId-${bucket.key}'),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: bucket.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: bucket.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          samplePreview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              bucket.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                height: AppTheme.lineHeightCompact,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FunctionalBucketSamples(
            deckId: deckId,
            bucket: bucket,
            samples: samples,
            totalCount: count,
            sourceLabel: analysis.sourceLabel,
            coverageSummary:
                analysis.functionalTags?.coverage.summary ??
                'Cobertura não informada',
          ),
        ],
      ),
    );
  }
}

class _FunctionalBucketSamples extends StatelessWidget {
  const _FunctionalBucketSamples({
    required this.deckId,
    required this.bucket,
    required this.samples,
    required this.totalCount,
    required this.sourceLabel,
    required this.coverageSummary,
  });

  final String deckId;
  final _FunctionalBucketSpec bucket;
  final List<DeckFunctionalTagSample> samples;
  final int totalCount;
  final String sourceLabel;
  final String coverageSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleSamples = samples.take(5).toList(growable: false);

    return Column(
      key: Key('deck-analysis-functional-samples-$deckId-${bucket.key}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FunctionalMetaLine(
          icon: Icons.source_outlined,
          text: 'Origem da contagem: $sourceLabel',
        ),
        const SizedBox(height: 6),
        _FunctionalMetaLine(
          icon: Icons.analytics_outlined,
          text: 'Cobertura geral: $coverageSummary',
        ),
        const SizedBox(height: 6),
        _FunctionalMetaLine(
          icon: Icons.rule_rounded,
          text:
              'Como é contado: ${bucket.description} A contagem inclui cartas marcadas com a função "${bucket.label}" no backend.',
        ),
        const SizedBox(height: 10),
        if (visibleSamples.isEmpty)
          Text(
            'Este backend retornou a contagem, mas não enviou amostras de cartas para este indicador.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: AppTheme.lineHeightCompact,
            ),
          )
        else ...[
          Text(
            'Cartas consideradas: mostrando ${visibleSamples.length} de $totalCount.',
            key: Key(
              'deck-analysis-functional-considered-$deckId-${bucket.key}',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary.withValues(alpha: 0.84),
              fontWeight: FontWeight.w700,
              height: AppTheme.lineHeightCompact,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(visibleSamples.length, (index) {
            final sample = visibleSamples[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _FunctionalSampleRow(
                key: Key(
                  'deck-analysis-functional-sample-$deckId-${bucket.key}-$index',
                ),
                sample: sample,
                accent: bucket.color,
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _FunctionalMetaLine extends StatelessWidget {
  const _FunctionalMetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _FunctionalSampleRow extends StatelessWidget {
  const _FunctionalSampleRow({
    super.key,
    required this.sample,
    required this.accent,
  });

  final DeckFunctionalTagSample sample;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail =
        sample.reason?.trim().isNotEmpty == true ? sample.reason : sample.role;
    final metadata = [
      if (sample.confidence != null)
        'confiança ${(sample.confidence!.clamp(0, 1) * 100).round()}%',
      if (_friendlyFunctionalCode(sample.speed).isNotEmpty)
        _friendlyFunctionalCode(sample.speed),
      if (_friendlyFunctionalCode(sample.manaEfficiency).isNotEmpty)
        _friendlyFunctionalCode(sample.manaEfficiency),
    ];
    final semanticDetails = [
      if (_friendlyFunctionalCode(sample.cardAdvantageType).isNotEmpty)
        _friendlyFunctionalCode(sample.cardAdvantageType),
      if (_friendlyFunctionalCode(sample.interactionScope).isNotEmpty)
        _friendlyFunctionalCode(sample.interactionScope),
      if (_friendlyFunctionalCode(sample.protectionType).isNotEmpty)
        _friendlyFunctionalCode(sample.protectionType),
      if (_friendlyFunctionalCode(sample.recursionType).isNotEmpty)
        _friendlyFunctionalCode(sample.recursionType),
    ];
    final evidence = _friendlyFunctionalEvidence(sample.evidence);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 15, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sample.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    key: Key(
                      'deck-analysis-functional-sample-reason-${sample.name}',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    metadata.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary.withValues(alpha: 0.82),
                      height: 1.2,
                    ),
                  ),
                ],
                if (semanticDetails.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final item in semanticDetails)
                        _FunctionalDetailPill(label: item, accent: accent),
                    ],
                  ),
                ],
                if (evidence.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Evidência: $evidence',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary.withValues(alpha: 0.72),
                      height: 1.2,
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

class _FunctionalDetailPill extends StatelessWidget {
  const _FunctionalDetailPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: accent.withValues(alpha: 0.18), width: 0.6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppTheme.textPrimary.withValues(alpha: 0.82),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _friendlyFunctionalCode(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty || value == 'none' || value == 'unknown') {
    return '';
  }
  return switch (value) {
    'fast' => 'rápida',
    'medium' => 'média',
    'slow' => 'lenta',
    'cheap' => 'baixo custo',
    'fair' => 'custo justo',
    'expensive' => 'custo alto',
    'card_draw' => 'compra carta',
    'selection' => 'seleção',
    'loot' => 'filtra mão',
    'spot' => 'pontual',
    'single_target' => 'alvo único',
    'mass' => 'global',
    'board' => 'mesa',
    'hexproof' => 'hexproof',
    'indestructible' => 'indestrutível',
    'phase_out' => 'phase out',
    'blink' => 'blink/proteção',
    'counterspell' => 'anula mágicas',
    'graveyard_to_hand' => 'cemitério para mão',
    'graveyard_to_battlefield' => 'reanima',
    _ => value.replaceAll('_', ' '),
  };
}

String _friendlyFunctionalEvidence(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return '';
  return switch (value) {
    'persisted_semantic_v2' => 'tag semântica persistida',
    'heuristic_functional_tags_v1' => 'heurística funcional v1',
    'card_draw_text' => 'texto da carta indica compra/vantagem',
    'mana_ramp_text' => 'texto da carta acelera mana',
    'removal_text' => 'texto da carta remove/interage',
    'board_wipe_text' => 'texto da carta afeta várias permanentes',
    'protection_text' => 'texto da carta protege permanente ou plano',
    _ => value.replaceAll('_', ' '),
  };
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
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
          width: AppTheme.strokeThin,
        ),
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
              height: AppTheme.lineHeightCompact,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisSubsectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AnalysisSubsectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary.withValues(alpha: 0.94),
          ),
        ),
      ],
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          width: AppTheme.strokeThin,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 4,
              color: color,
              backgroundColor: color.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary.withValues(alpha: 0.96),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$score/100',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
