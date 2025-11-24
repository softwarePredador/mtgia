import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/mana_helper.dart';
import '../models/deck_details.dart';

class DeckAnalysisTab extends StatelessWidget {
  final DeckDetails deck;

  const DeckAnalysisTab({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Prepara dados
    final allCards = [
      ...deck.commander,
      ...deck.mainBoard.values.expand((l) => l),
    ];

    // 1. Curva de Mana
    final manaCurve = List<int>.filled(8, 0); // 0 a 7+
    for (var card in allCards) {
      // Terrenos geralmente não contam na curva de mana para "jogar", mas têm CMC 0.
      // Vamos excluir terrenos da curva visual para focar em spells?
      // Padrão MTG Arena: Exclui terrenos.
      if (card.typeLine.toLowerCase().contains('land')) continue;

      final cmc = ManaHelper.calculateCMC(card.manaCost);
      final index = cmc >= 7 ? 7 : cmc;
      manaCurve[index] += card.quantity;
    }

    // 2. Distribuição de Cores (Pips)
    final colorCounts = <String, int>{
      'W': 0, 'U': 0, 'B': 0, 'R': 0, 'G': 0, 'C': 0
    };
    for (var card in allCards) {
      if (card.typeLine.toLowerCase().contains('land')) continue;
      final pips = ManaHelper.countColorPips(card.manaCost);
      pips.forEach((color, count) {
        if (colorCounts.containsKey(color)) {
          colorCounts[color] = (colorCounts[color] ?? 0) + (count * card.quantity);
        }
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção de IA (Existente)
          if (deck.synergyScore != null) ...[
            _AnalysisCard(
              title: 'Sinergia (IA)',
              score: deck.synergyScore!,
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
          ],
          if (deck.strengths != null) ...[
            Text('Pontos Fortes', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(deck.strengths!),
            const SizedBox(height: 24),
          ],
          if (deck.weaknesses != null) ...[
            Text('Pontos Fracos', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(deck.weaknesses!),
            const SizedBox(height: 24),
          ],

          const Divider(),
          const SizedBox(height: 16),

          // Seção Matemática (Nova)
          Text('Curva de Mana', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Distribuição de custo das mágicas (sem terrenos)',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (manaCurve.reduce((a, b) => a > b ? a : b) + 1).toDouble(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.grey[800]!,
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
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 32),

          Text('Distribuição de Cores', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Baseado nos símbolos de mana das cartas',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          SizedBox(
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
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, int> counts) {
    final total = counts.values.fold(0, (sum, item) => sum + item);
    if (total == 0) return [];

    final colorsMap = {
      'W': const Color(0xFFF0F2C0), // White (Yellowish)
      'U': const Color(0xFFB3CEEA), // Blue
      'B': const Color(0xFFA69F9D), // Black (Greyish)
      'R': const Color(0xFFEB9F82), // Red
      'G': const Color(0xFFC4D3CA), // Green
      'C': const Color(0xFFC7D7E0), // Colorless
    };

    return counts.entries.where((e) => e.value > 0).map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: colorsMap[entry.key] ?? Colors.grey,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
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
    
    final colorsMap = {
      'W': const Color(0xFFF0F2C0),
      'U': const Color(0xFFB3CEEA),
      'B': const Color(0xFFA69F9D),
      'R': const Color(0xFFEB9F82),
      'G': const Color(0xFFC4D3CA),
      'C': const Color(0xFFC7D7E0),
    };

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
