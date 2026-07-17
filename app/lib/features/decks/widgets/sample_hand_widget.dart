import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/mana_helper.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../models/deck_card_item.dart';
import '../models/deck_details.dart';

/// Simulador de mão inicial — permite ao jogador "testar" mãos de 7 cartas
/// aleatórias do deck, com opção de London mulligan. Cada mulligan compra uma
/// nova mão de sete e informa quantas cartas devem ir para o fundo do grimório.
///
/// Fundamental para qualquer jogador de MTG avaliar a consistência do deck.
class SampleHandWidget extends StatefulWidget {
  final DeckDetails deck;
  final bool compact;
  final int? randomSeed;
  final ValueChanged<DeckCardItem>? onShowCardDetails;

  const SampleHandWidget({
    super.key,
    required this.deck,
    this.compact = false,
    this.randomSeed,
    this.onShowCardDetails,
  });

  @override
  State<SampleHandWidget> createState() => _SampleHandWidgetState();
}

class _SampleHandWidgetState extends State<SampleHandWidget>
    with SingleTickerProviderStateMixin {
  List<DeckCardItem> _hand = [];
  int _mulligansTaken = 0;
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

  void _drawHand() {
    final pool = _buildPool();
    if (pool.isEmpty) return;

    pool.shuffle(_random);
    final drawSize = min(7, pool.length);
    setState(() {
      _hand = pool.take(drawSize).toList();
      _isDrawn = true;
    });
    _animController.forward(from: 0);
  }

  void _mulligan() {
    if (_mulligansTaken >= 7) return;
    _mulligansTaken += 1;
    _drawHand();
  }

  void _newHand() {
    _mulligansTaken = 0;
    _drawHand();
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
    final previewHeight = widget.compact ? 128.0 : 164.0;
    final imageWidth = widget.compact ? 74.0 : 90.0;
    final imageHeight = widget.compact ? 104.0 : 126.0;
    final horizontalPadding = widget.compact ? 14.0 : 16.0;
    final verticalPadding = widget.compact ? 14.0 : 16.0;

    return Container(
      margin:
          widget.compact
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    _mulligansTaken == 0
                        ? '${_hand.length} cartas'
                        : widget.compact
                        ? '${_hand.length} · fundo $_mulligansTaken'
                        : '${_hand.length} cartas · $_mulligansTaken ao fundo',
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
                onPressed: _newHand,
                icon: const Icon(Icons.casino, size: 20),
                label: const Text('Comprar 7 cartas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brass500,
                  foregroundColor: AppTheme.backgroundAbyss,
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
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'Terrenos',
                      value: '$_landCount',
                      color: AppTheme.mythicGold,
                    ),
                  ),
                  Expanded(
                    child: _StatChip(
                      label: 'Magias',
                      value: '$_nonLandCount',
                      color: AppTheme.primarySoft,
                    ),
                  ),
                  Expanded(
                    child: _StatChip(
                      label: 'Total',
                      value: '${_hand.length}',
                      color: AppTheme.manaViolet,
                    ),
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
            if (_mulligansTaken > 0) ...[
              Container(
                key: const Key('sample-hand-bottom-guidance'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.frost400.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: AppTheme.frost400.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  'Mulligan de Londres: escolha e coloque '
                  '$_mulligansTaken ${_mulligansTaken == 1 ? 'carta' : 'cartas'} '
                  'no fundo do grimório antes de manter.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Hand display
            FadeTransition(
              opacity: _fadeAnim,
              child: _SampleHandCarousel(
                cards: _hand,
                compact: widget.compact,
                height: previewHeight,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                onShowCardDetails: widget.onShowCardDetails,
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons stay compact on desktop and become full-width
            // only when the available pane is genuinely narrow.
            LayoutBuilder(
              builder: (context, constraints) {
                final stackActions = constraints.maxWidth < 520;
                final mulligan = OutlinedButton.icon(
                  key: const Key('sample-hand-mulligan'),
                  onPressed: _mulligansTaken < 7 ? _mulligan : null,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Mulligan'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppTheme.touchTargetMin),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    foregroundColor: AppTheme.mythicGold,
                    side: BorderSide(
                      color:
                          _mulligansTaken < 7
                              ? AppTheme.mythicGold.withValues(alpha: 0.5)
                              : AppTheme.outlineMuted,
                    ),
                  ),
                );
                final newHand = ElevatedButton.icon(
                  key: const Key('sample-hand-new-hand'),
                  onPressed: _newHand,
                  icon: const Icon(Icons.casino, size: 18),
                  label: const Text('Nova Mão'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brass500,
                    foregroundColor: AppTheme.backgroundAbyss,
                  ),
                );

                if (stackActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [mulligan, const SizedBox(height: 8), newHand],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [mulligan, const SizedBox(width: 8), newHand],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SampleHandCarousel extends StatelessWidget {
  final List<DeckCardItem> cards;
  final bool compact;
  final double height;
  final double imageWidth;
  final double imageHeight;
  final ValueChanged<DeckCardItem>? onShowCardDetails;

  const _SampleHandCarousel({
    required this.cards,
    required this.compact,
    required this.height,
    required this.imageWidth,
    required this.imageHeight,
    this.onShowCardDetails,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemExtent = imageWidth + 12;
          final maxFraction = compact ? 0.42 : 0.34;
          final viewportFraction =
              (itemExtent / max(1, constraints.maxWidth))
                  .clamp(0.08, maxFraction)
                  .toDouble();

          return _SampleHandPageView(
            key: ValueKey(
              'sample-hand-carousel-${cards.length}-${viewportFraction.toStringAsFixed(2)}',
            ),
            cards: cards,
            viewportFraction: viewportFraction,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            onShowCardDetails: onShowCardDetails,
          );
        },
      ),
    );
  }
}

class _SampleHandPageView extends StatefulWidget {
  final List<DeckCardItem> cards;
  final double viewportFraction;
  final double imageWidth;
  final double imageHeight;
  final ValueChanged<DeckCardItem>? onShowCardDetails;

  const _SampleHandPageView({
    super.key,
    required this.cards,
    required this.viewportFraction,
    required this.imageWidth,
    required this.imageHeight,
    this.onShowCardDetails,
  });

  @override
  State<_SampleHandPageView> createState() => _SampleHandPageViewState();
}

class _SampleHandPageViewState extends State<_SampleHandPageView> {
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: widget.viewportFraction);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.cards.length) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          key: const Key('sample-hand-carousel'),
          controller: _controller,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.cards.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            final card = widget.cards[index];
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                var page = _currentIndex.toDouble();
                if (_controller.hasClients && _controller.page != null) {
                  page = _controller.page!;
                }
                final distance = (page - index).abs().clamp(0.0, 1.0);
                final scale = 1.0 - (distance * 0.08);
                final opacity = 1.0 - (distance * 0.22);

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: child,
                  ),
                );
              },
              child: Center(
                child: _SampleHandCard(
                  key: Key('sample-hand-card-$index'),
                  card: card,
                  imageWidth: widget.imageWidth,
                  imageHeight: widget.imageHeight,
                  onShowCardDetails: widget.onShowCardDetails,
                ),
              ),
            );
          },
        ),
        if (widget.cards.length > 1) ...[
          Positioned(
            left: 0,
            top: 0,
            bottom: 18,
            child: _CarouselNavButton(
              icon: Icons.chevron_left_rounded,
              enabled: _currentIndex > 0,
              onTap: () => _goTo(_currentIndex - 1),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 18,
            child: _CarouselNavButton(
              icon: Icons.chevron_right_rounded,
              enabled: _currentIndex < widget.cards.length - 1,
              onTap: () => _goTo(_currentIndex + 1),
            ),
          ),
        ],
      ],
    );
  }
}

class _SampleHandCard extends StatelessWidget {
  final DeckCardItem card;
  final double imageWidth;
  final double imageHeight;
  final ValueChanged<DeckCardItem>? onShowCardDetails;

  const _SampleHandCard({
    super.key,
    required this.card,
    required this.imageWidth,
    required this.imageHeight,
    this.onShowCardDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isLand = card.typeLine.toLowerCase().contains('land');

    return Semantics(
      button: onShowCardDetails != null,
      label: 'Ver detalhes de ${card.name}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap:
              onShowCardDetails == null ? null : () => onShowCardDetails!(card),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: CachedCardImage(
                  imageUrl: card.effectiveImageUrl,
                  fallbackImageUrl: card.fallbackImageUrl,
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
                    color: isLand ? AppTheme.mythicGold : AppTheme.textPrimary,
                    fontSize: AppTheme.fontXs,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarouselNavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CarouselNavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: Center(
          child: Material(
            color: AppTheme.backgroundAbyss.withValues(alpha: 0.56),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 30,
                height: 30,
                child: Icon(icon, color: AppTheme.textPrimary, size: 22),
              ),
            ),
          ),
        ),
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
