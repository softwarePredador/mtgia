import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/mana_helper.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../models/deck_card_item.dart';
import '../models/deck_details.dart';

/// Simulador de mão inicial — permite ao jogador "testar" mãos de 7 cartas
/// aleatórias do deck, com opção de mulligan (nova mão com -1 carta).
///
/// Fundamental para qualquer jogador de MTG avaliar a consistência do deck.
class SampleHandWidget extends StatefulWidget {
  final DeckDetails deck;
  final bool compact;
  final int? randomSeed;

  const SampleHandWidget({
    super.key,
    required this.deck,
    this.compact = false,
    this.randomSeed,
  });

  @override
  State<SampleHandWidget> createState() => _SampleHandWidgetState();
}

class _SampleHandWidgetState extends State<SampleHandWidget>
    with SingleTickerProviderStateMixin {
  List<DeckCardItem> _hand = [];
  int _handSize = 7;
  bool _isDrawn = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late final Random _random;

  @override
  void initState() {
    super.initState();
    _random = Random(widget.randomSeed);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Constroi a lista expandida de cartas (respeitando quantity).
  List<DeckCardItem> _buildPool() {
    final pool = <DeckCardItem>[];
    for (final cards in widget.deck.mainBoard.values) {
      for (final card in cards) {
        for (var i = 0; i < card.quantity; i++) {
          pool.add(card);
        }
      }
    }
    return pool;
  }

  void _drawHand(int size) {
    final pool = _buildPool();
    if (pool.isEmpty) return;

    pool.shuffle(_random);
    final drawSize = min(size, pool.length);
    setState(() {
      _hand = pool.take(drawSize).toList();
      _handSize = size;
      _isDrawn = true;
    });
    _animController.forward(from: 0);
  }

  void _mulligan() {
    final newSize = max(1, _handSize - 1);
    _drawHand(newSize);
  }

  void _newHand() {
    _drawHand(7);
  }

  int get _landCount =>
      _hand.where((c) => c.typeLine.toLowerCase().contains('land')).length;

  int get _nonLandCount => _hand.length - _landCount;

  int get _earlyPlayCount =>
      _hand.where((card) {
        if (card.typeLine.toLowerCase().contains('land')) return false;
        return ManaHelper.calculateCMC(card.manaCost) <= 3;
      }).length;

  int get _coloredSpellCount => _hand
      .where((card) => !card.typeLine.toLowerCase().contains('land'))
      .fold(
        0,
        (sum, card) =>
            sum +
            ManaHelper.countColorPips(
              card.manaCost,
            ).values.fold(0, (a, b) => a + b),
      );

  _OpeningHandAssessment get _assessment {
    if (_hand.isEmpty) {
      return const _OpeningHandAssessment(
        verdict: 'Sem leitura',
        summary: 'Compre uma mão para avaliar consistência e ritmo inicial.',
        tone: _AssessmentTone.neutral,
      );
    }

    if (_landCount <= 1) {
      return const _OpeningHandAssessment(
        verdict: 'Mulligan',
        summary: 'Poucos terrenos para desenvolver a curva com segurança.',
        tone: _AssessmentTone.bad,
      );
    }

    if (_landCount >= 6) {
      return const _OpeningHandAssessment(
        verdict: 'Mulligan',
        summary: 'Terrenos demais para uma mão inicial agressiva ou estável.',
        tone: _AssessmentTone.bad,
      );
    }

    if (_earlyPlayCount == 0) {
      return const _OpeningHandAssessment(
        verdict: 'Arriscada',
        summary:
            'A mão não mostra jogadas cedo o bastante para estabilizar a partida.',
        tone: _AssessmentTone.warn,
      );
    }

    if (_landCount >= 2 && _landCount <= 4 && _earlyPlayCount >= 2) {
      return const _OpeningHandAssessment(
        verdict: 'Keep provável',
        summary: 'Mana e curva inicial parecem saudáveis para seguir.',
        tone: _AssessmentTone.good,
      );
    }

    if (_coloredSpellCount <= 1) {
      return const _OpeningHandAssessment(
        verdict: 'Arriscada',
        summary:
            'A mão depende de poucas mágicas relevantes e pode ficar travada.',
        tone: _AssessmentTone.warn,
      );
    }

    return const _OpeningHandAssessment(
      verdict: 'Borderline',
      summary: 'A mão é jogável, mas vale pensar no plano do deck e na mesa.',
      tone: _AssessmentTone.neutral,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assessment = _assessment;
    final previewHeight = widget.compact ? 122.0 : 160.0;
    final imageWidth = widget.compact ? 74.0 : 90.0;
    final imageHeight = widget.compact ? 104.0 : 126.0;
    final horizontalPadding = widget.compact ? 14.0 : 16.0;
    final verticalPadding = widget.compact ? 14.0 : 16.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.back_hand, color: AppTheme.mythicGold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.compact ? 'Playtest rápido' : 'Testar Mão Inicial',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_isDrawn)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '$_handSize cartas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (!_isDrawn) ...[
            // Draw button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('sample-hand-draw'),
                onPressed: () => _drawHand(7),
                icon: const Icon(Icons.casino, size: 20),
                label: const Text('Comprar 7 cartas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.manaViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.compact
                  ? 'Compre uma mão e veja rápido se ela parece keepável.'
                  : 'Simula uma mão inicial aleatória do seu deck.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          if (_isDrawn) ...[
            // Stats bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(
                    label: 'Terrenos',
                    value: '$_landCount',
                    color: AppTheme.mythicGold,
                  ),
                  _StatChip(
                    label: 'Magias',
                    value: '$_nonLandCount',
                    color: AppTheme.primarySoft,
                  ),
                  _StatChip(
                    label: 'Total',
                    value: '${_hand.length}',
                    color: AppTheme.manaViolet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              key: const Key('sample-hand-assessment'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: assessment.tone.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: assessment.tone.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    assessment.tone.icon,
                    size: 18,
                    color: assessment.tone.foreground,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assessment.verdict,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: assessment.tone.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          assessment.summary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Hand display
            FadeTransition(
              opacity: _fadeAnim,
              child: SizedBox(
                height: previewHeight,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _hand.length,
                  itemBuilder: (context, index) {
                    final card = _hand[index];
                    final isLand = card.typeLine.toLowerCase().contains('land');
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < _hand.length - 1 ? 8 : 0,
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                            child: CachedCardImage(
                              imageUrl: card.imageUrl,
                              width: imageWidth,
                              height: imageHeight,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: imageWidth,
                            child: Text(
                              card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    isLand
                                        ? AppTheme.mythicGold
                                        : AppTheme.textPrimary,
                                fontSize: AppTheme.fontXs,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: widget.compact ? double.infinity : null,
                  child: OutlinedButton.icon(
                    key: const Key('sample-hand-mulligan'),
                    onPressed: _handSize > 1 ? _mulligan : null,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text('Mulligan (${max(1, _handSize - 1)})'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.mythicGold,
                      side: BorderSide(
                        color:
                            _handSize > 1
                                ? AppTheme.mythicGold.withValues(alpha: 0.5)
                                : AppTheme.outlineMuted,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: widget.compact ? double.infinity : null,
                  child: ElevatedButton.icon(
                    key: const Key('sample-hand-new-hand'),
                    onPressed: _newHand,
                    icon: const Icon(Icons.casino, size: 18),
                    label: const Text('Nova Mão'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.manaViolet,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OpeningHandAssessment {
  final String verdict;
  final String summary;
  final _AssessmentTone tone;

  const _OpeningHandAssessment({
    required this.verdict,
    required this.summary,
    required this.tone,
  });
}

enum _AssessmentTone { good, warn, bad, neutral }

extension on _AssessmentTone {
  Color get foreground {
    switch (this) {
      case _AssessmentTone.good:
        return AppTheme.success;
      case _AssessmentTone.warn:
        return AppTheme.mythicGold;
      case _AssessmentTone.bad:
        return AppTheme.error;
      case _AssessmentTone.neutral:
        return AppTheme.primarySoft;
    }
  }

  Color get background => foreground.withValues(alpha: 0.12);

  Color get border => foreground.withValues(alpha: 0.32);

  IconData get icon {
    switch (this) {
      case _AssessmentTone.good:
        return Icons.check_circle_outline_rounded;
      case _AssessmentTone.warn:
        return Icons.warning_amber_rounded;
      case _AssessmentTone.bad:
        return Icons.close_rounded;
      case _AssessmentTone.neutral:
        return Icons.info_outline_rounded;
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: AppTheme.fontLg,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: AppTheme.fontXs,
          ),
        ),
      ],
    );
  }
}
