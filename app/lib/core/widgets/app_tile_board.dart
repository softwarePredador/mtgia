import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/bt_tokens.dart';
import 'app_tile.dart';

/// One row of an [AppTileBoard] (`.mrow`).
@immutable
class AppTileRowSpec {
  const AppTileRowSpec({
    required this.children,
    this.weights = const <int>[],
    this.flexWeight = 112,
    this.maxHeight = 128,
  });

  /// The hero row of the ruler: `flex 120`, at most 136 tall.
  const AppTileRowSpec.hero({
    required this.children,
    this.weights = const <int>[],
  }) : flexWeight = 120,
       maxHeight = 136;

  final List<Widget> children;

  /// 1 or 2 per child (`.f1` / `.f2`); empty means all 1.
  final List<int> weights;

  /// 112 (tall row) · 120 (hero row).
  final int flexWeight;

  /// 128 (tall row) · 136 (hero row).
  final double maxHeight;

  int weightOf(int index) => index < weights.length ? weights[index] : 1;
}

/// The board of rows (`.menu` + `.mrow`, docs/design/ui-kit-spec.md §4.3).
///
/// Everything is visible at once, nothing scrolls: rows of flex tiles at
/// most 780 wide, centered, over a thin radial veil that blurs the live
/// surface below. [heroRow] lays its row as `1fr 80px 1fr`, with [center]
/// (the ✕ or the hub) in the 80px hole and the first child as the hero.
/// Above ~160% text scale `maxHeight` becomes `minHeight` and the board may
/// scroll — the emergency exit, not the layout.
class AppTileBoard extends StatelessWidget {
  const AppTileBoard({
    super.key,
    required this.rows,
    this.heroRow,
    this.center,
    this.maxWidth = 780,
    this.veil = true,
    this.onDismiss,
  }) : assert(
         heroRow == null || (heroRow >= 0 && heroRow < rows.length),
         'heroRow must index one of the rows.',
       );

  final List<AppTileRowSpec> rows;
  final int? heroRow;
  final Widget? center;
  final double maxWidth;

  /// Veil + blur over the live surface.
  final bool veil;

  /// Tap on the veil and Escape.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final metrics = tokens.metrics;
    final still = MediaQuery.disableAnimationsOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final grown = textScale > 1.6;

    Widget rowWidget(int index, {required bool bounded}) {
      final spec = rows[index];
      final isHero = index == heroRow;
      final children = <Widget>[];
      if (isHero && spec.children.isNotEmpty) {
        children.add(Expanded(child: _ordered(index, 0, spec.children.first)));
        children.add(
          SizedBox(
            width: 80,
            child: Center(
              child: center == null
                  ? null
                  : FocusTraversalOrder(
                      order: NumericFocusOrder(index * 100 + 1.5),
                      child: center!,
                    ),
            ),
          ),
        );
        children.add(
          Expanded(
            child: Row(
              crossAxisAlignment: grown
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.stretch,
              children: _weighted(index, spec, 1, metrics.gapTile),
            ),
          ),
        );
      } else {
        children.addAll(_weighted(index, spec, 0, metrics.gapTile));
      }
      final row = Row(
        crossAxisAlignment: grown
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
        children: children,
      );
      if (grown) {
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: spec.maxHeight),
          child: row,
        );
      }
      if (!bounded) return SizedBox(height: spec.maxHeight, child: row);
      return Flexible(
        flex: spec.flexWeight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: spec.maxHeight),
          child: row,
        ),
      );
    }

    final board = LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight && !grown;
        final column = Column(
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: metrics.gapTile),
              rowWidget(i, bounded: bounded),
            ],
          ],
        );
        final framed = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppTheme.space8),
              child: column,
            ),
          ),
        );
        if (grown && constraints.hasBoundedHeight) {
          return SingleChildScrollView(child: framed);
        }
        return framed;
      },
    );

    Widget content = BtBoardScope(
      veiled: veil,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: board,
        ),
      ),
    );

    if (veil) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: onDismiss,
              child: MouseRegion(
                cursor: SystemMouseCursors.basic,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: BtBackdrop.filter(
                      metrics.blurMenu,
                      metrics.backdropSaturation,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: tokens.gradients.veilMenu,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          content,
        ],
      );
    }

    if (onDismiss != null) {
      content = CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): onDismiss!,
        },
        child: Focus(skipTraversal: true, child: content),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: still ? 1 : 0, end: 1),
      duration: still ? Duration.zero : metrics.fadeDuration,
      curve: Curves.ease,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: content,
    );
  }

  List<Widget> _weighted(int row, AppTileRowSpec spec, int from, double gap) {
    final out = <Widget>[];
    for (var i = from; i < spec.children.length; i++) {
      if (out.isNotEmpty) out.add(SizedBox(width: gap));
      out.add(
        Expanded(
          flex: spec.weightOf(i),
          child: _ordered(row, i, spec.children[i]),
        ),
      );
    }
    return out;
  }

  Widget _ordered(int row, int index, Widget child) => FocusTraversalOrder(
    order: NumericFocusOrder(row * 100.0 + (index == 0 ? 1 : index + 1)),
    child: child,
  );
}

/// The backdrop of the kit: `blur(<sigma>) saturate(<s>)`.
///
/// [ui.ImageFilter.blur] has no saturation, so it is composed with a
/// luminance-preserving saturation matrix (§4.4f item 3). The tile mode is
/// declared (`decal`) so the blurred edge does not smear the corners.
abstract final class BtBackdrop {
  static ui.ImageFilter filter(double blur, double saturation) {
    final s = saturation;
    const r = 0.2126;
    const g = 0.7152;
    const b = 0.0722;
    final matrix = <double>[
      r * (1 - s) + s, g * (1 - s), b * (1 - s), 0, 0, //
      r * (1 - s), g * (1 - s) + s, b * (1 - s), 0, 0, //
      r * (1 - s), g * (1 - s), b * (1 - s) + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
    return ui.ImageFilter.compose(
      outer: ui.ColorFilter.matrix(matrix),
      inner: ui.ImageFilter.blur(
        sigmaX: blur,
        sigmaY: blur,
        tileMode: TileMode.decal,
      ),
    );
  }
}
