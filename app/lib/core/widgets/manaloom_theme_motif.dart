import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Original ManaLoom atmosphere for surfaces that have no card art to carry
/// the game identity.
///
/// The motif uses card proportions, tabletop zones, and five-color data cues.
/// It deliberately avoids official card backs, mana symbols, set marks, and
/// other third-party brand assets.
enum ManaLoomMotifVariant { cardWeave, battlefield }

class ManaLoomThemeMotif extends StatelessWidget {
  const ManaLoomThemeMotif({
    super.key,
    required this.child,
    this.variant = ManaLoomMotifVariant.cardWeave,
    this.intensity = 1,
    this.borderRadius,
  });

  final Widget child;
  final ManaLoomMotifVariant variant;
  final double intensity;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final layered = Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: CustomPaint(
                key: const Key('manaloom-theme-motif-paint'),
                painter: _ManaLoomThemeMotifPainter(
                  variant: variant,
                  intensity: intensity.clamp(0, 1),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );

    return RepaintBoundary(
      child: borderRadius == null
          ? layered
          : ClipRRect(borderRadius: borderRadius!, child: layered),
    );
  }
}

class _ManaLoomThemeMotifPainter extends CustomPainter {
  const _ManaLoomThemeMotifPainter({
    required this.variant,
    required this.intensity,
  });

  final ManaLoomMotifVariant variant;
  final double intensity;

  static const _identityColors = <Color>[
    AppTheme.manaW,
    AppTheme.manaU,
    AppTheme.manaB,
    AppTheme.manaR,
    AppTheme.manaG,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || intensity <= 0) return;

    switch (variant) {
      case ManaLoomMotifVariant.cardWeave:
        _paintCardWeave(canvas, size);
      case ManaLoomMotifVariant.battlefield:
        _paintBattlefield(canvas, size);
    }
  }

  void _paintCardWeave(Canvas canvas, Size size) {
    final shortSide = math.min(size.width, size.height);
    final ringCenter = Offset(size.width * 0.78, size.height * 0.30);
    final ringRadius = math.max(64.0, shortSide * 0.34);
    final brassLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppTheme.brass400.withValues(alpha: 0.095 * intensity);
    final frostLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppTheme.frost400.withValues(alpha: 0.065 * intensity);

    for (var index = 0; index < 4; index++) {
      final radius = ringRadius * (0.56 + index * 0.18);
      canvas.drawArc(
        Rect.fromCircle(center: ringCenter, radius: radius),
        math.pi * 0.72,
        math.pi * 1.18,
        false,
        index.isEven ? brassLine : frostLine,
      );
    }

    final cardHeight = math.min(116.0, math.max(68.0, shortSide * 0.23));
    final cardWidth = cardHeight * 0.7159;
    _drawCard(
      canvas,
      center: Offset(size.width * 0.10, size.height * 0.18),
      width: cardWidth,
      height: cardHeight,
      angle: -0.16,
      paint: frostLine,
    );
    _drawCard(
      canvas,
      center: Offset(size.width * 0.91, size.height * 0.78),
      width: cardWidth,
      height: cardHeight,
      angle: 0.14,
      paint: brassLine,
    );

    final nodeRadius = math.max(2.2, math.min(4.0, shortSide * 0.009));
    for (var index = 0; index < _identityColors.length; index++) {
      final angle = math.pi * (0.86 + index * 0.10);
      final point = ringCenter + Offset.fromDirection(angle, ringRadius * 0.9);
      final nodePaint = Paint()
        ..color = _identityColors[index].withValues(alpha: 0.42 * intensity);
      canvas.drawCircle(point, nodeRadius, nodePaint);
    }
  }

  void _paintBattlefield(Canvas canvas, Size size) {
    final shortSide = math.min(size.width, size.height);
    final brassLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppTheme.brass400.withValues(alpha: 0.12 * intensity);
    final frostLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppTheme.frost400.withValues(alpha: 0.075 * intensity);

    final table = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.055,
        size.height * 0.08,
        size.width * 0.89,
        size.height * 0.84,
      ),
      const Radius.circular(AppTheme.radiusLg),
    );
    canvas.drawRRect(table, brassLine);
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.5),
      Offset(size.width * 0.92, size.height * 0.5),
      frostLine,
    );

    final zoneWidth = math.max(36.0, math.min(92.0, size.width * 0.14));
    final zoneHeight = zoneWidth * 0.7159;
    for (final y in [size.height * 0.20, size.height * 0.67]) {
      for (final x in [size.width * 0.18, size.width * 0.82]) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y),
            width: zoneWidth,
            height: zoneHeight,
          ),
          const Radius.circular(AppTheme.radiusXs),
        );
        canvas.drawRRect(rect, frostLine);
      }
    }

    final stackSize = math.max(24.0, math.min(46.0, shortSide * 0.12));
    for (var index = 0; index < 3; index++) {
      _drawCard(
        canvas,
        center: Offset(
          size.width * 0.5 + (index - 1) * stackSize * 0.22,
          size.height * 0.5 + (index - 1) * stackSize * 0.09,
        ),
        width: stackSize * 0.7159,
        height: stackSize,
        angle: (index - 1) * 0.06,
        paint: index == 1 ? brassLine : frostLine,
      );
    }

    final orbitCenter = Offset(size.width * 0.5, size.height * 0.5);
    final orbitRadius = math.max(34.0, math.min(72.0, shortSide * 0.19));
    for (var index = 0; index < _identityColors.length; index++) {
      final angle = -math.pi / 2 + index * (math.pi * 2 / 5);
      final point = orbitCenter + Offset.fromDirection(angle, orbitRadius);
      canvas.drawCircle(
        point,
        math.max(2.2, math.min(4.0, shortSide * 0.01)),
        Paint()
          ..color = _identityColors[index].withValues(alpha: 0.46 * intensity),
      );
    }
  }

  void _drawCard(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required double angle,
    required Paint paint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final outer = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: width, height: height),
      Radius.circular(math.max(3, width * 0.08)),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -height * 0.06),
        width: width * 0.72,
        height: height * 0.54,
      ),
      Radius.circular(math.max(2, width * 0.05)),
    );
    canvas.drawRRect(outer, paint);
    canvas.drawRRect(inner, paint);
    canvas.drawLine(
      Offset(-width * 0.28, height * 0.34),
      Offset(width * 0.28, height * 0.34),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ManaLoomThemeMotifPainter oldDelegate) =>
      oldDelegate.variant != variant || oldDelegate.intensity != intensity;
}
