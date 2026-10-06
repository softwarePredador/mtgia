import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/bt_tokens.dart';

/// The painted body shared by every kit piece (BT-UX-KIT-001).
///
/// Paints, in the browser's order: the [gradient], the outer [shadows]
/// (below), the inset [shadows] (above the background), the diagonal
/// [sheen], the [dashed] brass outline and, on top of the child, the
/// loading [sweep]. CSS `box-shadow: inset` has no Flutter equivalent, so
/// inset layers are painted here with their exact geometry.
class BtSurface extends StatelessWidget {
  const BtSurface({
    super.key,
    required this.gradient,
    required this.radius,
    this.shadows = const <BtShadow>[],
    this.sheen = false,
    this.dashed = false,
    this.sweep = false,
    this.padding,
    this.child,
  });

  final Gradient? gradient;
  final double radius;
  final List<BtShadow> shadows;
  final bool sheen;
  final bool dashed;
  final bool sweep;
  final EdgeInsetsGeometry? padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final borderRadius = BorderRadius.circular(radius);
    final outer = [
      for (final shadow in shadows.reversed)
        if (!shadow.inset) shadow.toBoxShadow(),
    ];
    final inset = [
      for (final shadow in shadows)
        if (shadow.inset) shadow,
    ];
    Widget content = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    if (sweep) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: borderRadius,
                child: const BtSweep(),
              ),
            ),
          ),
        ],
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
        boxShadow: outer,
      ),
      child: CustomPaint(
        painter: _BtSurfacePainter(
          radius: radius,
          inset: inset,
          sheen: sheen ? tokens.gradients.sheen : const <Gradient>[],
          dash: dashed ? tokens.palette.dash : null,
          dashWidth: tokens.metrics.dashWidth,
          dashLength: tokens.metrics.dashLength,
          dashGap: tokens.metrics.dashGap,
          textDirection: Directionality.maybeOf(context),
        ),
        child: content,
      ),
    );
  }
}

class _BtSurfacePainter extends CustomPainter {
  _BtSurfacePainter({
    required this.radius,
    required this.inset,
    required this.sheen,
    required this.dash,
    required this.dashWidth,
    required this.dashLength,
    required this.dashGap,
    required this.textDirection,
  });

  final double radius;
  final List<BtShadow> inset;
  final List<Gradient> sheen;
  final Color? dash;
  final double dashWidth;
  final double dashLength;
  final double dashGap;
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    if (inset.isNotEmpty || sheen.isNotEmpty) {
      canvas.save();
      canvas.clipRRect(rrect);
      // CSS paints the first inset layer on top: walk the list backwards.
      for (final shadow in inset.reversed) {
        final hole = rrect
            .shift(shadow.offset)
            .deflate(shadow.spread)
            .scaleRadii();
        final path = Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(rect.inflate(shadow.blur * 2 + 40))
          ..addRRect(hole);
        final paint = Paint()..color = shadow.color;
        if (shadow.blur > 0) {
          paint.maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blur / 2);
        }
        canvas.drawPath(path, paint);
      }
      for (final layer in sheen) {
        canvas.drawRect(
          rect,
          Paint()
            ..shader = layer.createShader(rect, textDirection: textDirection),
        );
      }
      canvas.restore();
    }
    final dashColor = dash;
    if (dashColor != null) {
      final stroke = rrect.deflate(dashWidth / 2);
      final paint = Paint()
        ..color = dashColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = dashWidth;
      final source = Path()..addRRect(stroke);
      for (final metric in source.computeMetrics()) {
        var distance = 0.0;
        while (distance < metric.length) {
          final end = math.min(distance + dashLength, metric.length);
          canvas.drawPath(metric.extractPath(distance, end), paint);
          distance = end + dashGap;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BtSurfacePainter old) =>
      old.radius != radius ||
      old.dash != dash ||
      old.textDirection != textDirection ||
      !_same(old.inset, inset) ||
      !_same(old.sheen, sheen);

  static bool _same(List<Object> a, List<Object> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The loading sweep: a narrow 115° brass band (≈24% of 210px) crossing the
/// glass in 1.35 s. It stays still when the platform disables animations.
class BtSweep extends StatefulWidget {
  const BtSweep({super.key});

  @override
  State<BtSweep> createState() => _BtSweepState();
}

class _BtSweepState extends State<BtSweep> with TickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    _controller ??= AnimationController(
      vsync: this,
      duration: BtTokens.of(context).metrics.sweepDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = BtTokens.of(context).palette;
    final controller = _controller;
    if (controller == null) {
      return CustomPaint(painter: _BtSweepPainter(palette: palette, t: 0.3));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CustomPaint(
        painter: _BtSweepPainter(palette: palette, t: controller.value),
      ),
    );
  }
}

class _BtSweepPainter extends CustomPainter {
  _BtSweepPainter({required this.palette, required this.t});

  final BtPalette palette;
  final double t;

  static const double _band = 210;

  @override
  void paint(Canvas canvas, Size size) {
    final x = -_band + (size.width + 2 * _band) * t;
    final rect = Rect.fromLTWH(x, 0, _band, size.height);
    final clear = palette.brass.withValues(alpha: 0);
    final gradient = BtAngleGradient(
      angle: 115,
      colors: [
        clear,
        clear,
        palette.sweepSoft,
        palette.sweepPeak,
        palette.sweepSoft,
        clear,
        clear,
      ],
      stops: const [0, 0.38, 0.44, 0.50, 0.56, 0.62, 1],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(_BtSweepPainter old) => old.t != t;
}

/// The brass thread that stands in for a value that does not exist yet
/// (`bt-carga`): 3px tall, pill radius.
class BtThread extends StatelessWidget {
  const BtThread({super.key, this.width = 64, this.height = 3, this.color});

  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color ?? tokens.palette.thread,
          borderRadius: BorderRadius.circular(tokens.metrics.radiusPill),
        ),
      ),
    );
  }
}

/// Which focus ring a pressable draws (§4.1f, §4.5f).
enum BtFocusRing {
  /// `outline: 2px solid #E0A93B; outline-offset: 2px`.
  brass,

  /// Over brass the ring inverts: obsidian 2px plus 1px of ivory outside.
  obsidian,
}

/// Touch, keyboard, hover and press feedback shared by the kit pieces.
///
/// No ripple (the ruler has none): a [GestureDetector] plus [AnimatedScale]
/// (`scale .97` on press, `1.012` on hover). Enter/Space activate through
/// [FocusableActionDetector], which also paints the focus ring. Semantics
/// belong to the caller, so the gesture is excluded from the tree here.
class BtPressable extends StatefulWidget {
  const BtPressable({
    super.key,
    required this.child,
    required this.radius,
    this.onTap,
    this.focusRing = BtFocusRing.brass,
    this.autofocus = false,
    this.focusNode,
    this.scaleOnPress = true,
    this.shape = BoxShape.rectangle,
  });

  final Widget child;
  final double radius;
  final VoidCallback? onTap;
  final BtFocusRing focusRing;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool scaleOnPress;
  final BoxShape shape;

  @override
  State<BtPressable> createState() => _BtPressableState();
}

class _BtPressableState extends State<BtPressable> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final enabled = widget.onTap != null;
    final still = MediaQuery.disableAnimationsOf(context);
    var scale = 1.0;
    if (enabled && widget.scaleOnPress && !still) {
      if (_pressed) {
        scale = tokens.metrics.pressScale;
      } else if (_hovered) {
        scale = tokens.metrics.hoverScale;
      }
    }
    return FocusableActionDetector(
      enabled: enabled,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: CustomPaint(
          foregroundPainter: _focused
              ? _BtFocusRingPainter(
                  radius: widget.radius,
                  shape: widget.shape,
                  ring: widget.focusRing,
                  palette: tokens.palette,
                  width: tokens.metrics.focusRingWidth,
                  gap: tokens.metrics.focusRingGap,
                )
              : null,
          child: AnimatedScale(
            scale: scale,
            duration: still ? Duration.zero : tokens.metrics.pressDuration,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _BtFocusRingPainter extends CustomPainter {
  _BtFocusRingPainter({
    required this.radius,
    required this.shape,
    required this.ring,
    required this.palette,
    required this.width,
    required this.gap,
  });

  final double radius;
  final BoxShape shape;
  final BtFocusRing ring;
  final BtPalette palette;
  final double width;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    void stroke(double inflate, double w, Color color) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = color;
      final r = rect.inflate(inflate);
      if (shape == BoxShape.circle) {
        canvas.drawOval(r, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(radius + inflate)),
          paint,
        );
      }
    }

    switch (ring) {
      case BtFocusRing.brass:
        stroke(gap + width / 2, width, palette.brass);
      case BtFocusRing.obsidian:
        stroke(gap + width / 2, width, palette.obsidian);
        stroke(gap + width + 0.5, 1, palette.ivory);
    }
  }

  @override
  bool shouldRepaint(_BtFocusRingPainter old) =>
      old.ring != ring || old.radius != radius || old.palette != palette;
}

/// Grows a small visual to the 48 dp touch target (§4.1f, D-44) with
/// transparent room, without changing the drawing.
class BtTouchTarget extends StatelessWidget {
  const BtTouchTarget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final target = BtTokens.of(context).metrics.touchTarget;
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: target, minHeight: target),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    );
  }
}

/// The few stroked glyphs the ruler draws itself (24-unit viewBox), so their
/// stroke width matches `mesa-brewtact.html` (F5: the back chevron is 2).
enum BtGlyphShape { chevronBack, close, arrowForward, pause }

class BtStrokeGlyph extends StatelessWidget {
  const BtStrokeGlyph(
    this.shape, {
    super.key,
    required this.size,
    required this.strokeWidth,
    this.color,
  });

  final BtGlyphShape shape;
  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? IconTheme.of(context).color;
    final mirror =
        shape != BtGlyphShape.close &&
        Directionality.maybeOf(context) == TextDirection.rtl;
    Widget glyph = CustomPaint(
      size: Size.square(size),
      painter: _BtGlyphPainter(
        shape,
        strokeWidth,
        color ?? BtTokens.of(context).palette.ivory,
      ),
    );
    if (mirror) {
      glyph = Transform.flip(flipX: true, child: glyph);
    }
    return ExcludeSemantics(child: glyph);
  }
}

class _BtGlyphPainter extends CustomPainter {
  _BtGlyphPainter(this.shape, this.strokeWidth, this.color);

  final BtGlyphShape shape;
  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    switch (shape) {
      case BtGlyphShape.chevronBack:
        path
          ..moveTo(15, 5)
          ..lineTo(8, 12)
          ..lineTo(15, 19);
      case BtGlyphShape.close:
        path
          ..moveTo(6, 6)
          ..lineTo(18, 18)
          ..moveTo(18, 6)
          ..lineTo(6, 18);
      case BtGlyphShape.arrowForward:
        path
          ..moveTo(5, 12)
          ..lineTo(19, 12)
          ..moveTo(13, 6)
          ..lineTo(19, 12)
          ..lineTo(13, 18);
      case BtGlyphShape.pause:
        path
          ..moveTo(9, 6)
          ..lineTo(9, 18)
          ..moveTo(15, 6)
          ..lineTo(15, 18);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BtGlyphPainter old) =>
      old.shape != shape ||
      old.strokeWidth != strokeWidth ||
      old.color != color;
}
