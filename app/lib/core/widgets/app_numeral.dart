import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/bt_tokens.dart';

export '../theme/bt_tokens.dart' show AppNumeralScale;

/// The serif numeral of the kit (docs/design/ui-kit-spec.md §4.2).
///
/// Fraunces with `wght`, `opsz` that follows the size (the ruler leaves the
/// optical axis on `auto`), WONK 1 / SOFT 0 and lining + tabular figures.
/// The numeral is an object, not text: it ignores the system text scale.
/// When its container is too narrow it shrinks, re-measured with a
/// [TextPainter] so `opsz` keeps matching the real size, and stops at its
/// floor ([minFontSize], or the scale's floor of §4.2f). A [FittedBox] is
/// only the last-resort safety net below that floor.
class AppNumeral extends StatelessWidget {
  const AppNumeral(
    this.value, {
    super.key,
    this.scale = AppNumeralScale.azulejo,
    this.color,
    this.minFontSize,
    this.semanticsLabel,
    this.live = false,
    this.selected = false,
    this.size,
  });

  /// Already formatted; the widget never formats.
  final String value;
  final AppNumeralScale scale;

  /// Defaults to the ink of the ancestor (mist on `canto`, `peca` and
  /// `pecaNumeral`, brass at .55 on `vazio`).
  final Color? color;

  /// Real floor, measured with [TextPainter].
  final double? minFontSize;

  /// "27 de vida", not "27". Mandatory in practice for scales ≥ `heroi`.
  final String? semanticsLabel;

  /// `liveRegion`: reserve it for the single live numeral of a screen.
  final bool live;

  /// Selected pieces step the numeral up one size (38→44, 36→40).
  final bool selected;

  /// Overrides the scale's size (the "outro" numeral piece is 30px);
  /// `opsz` follows it.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final spec = BtNumeralSpec.of(scale);
    final ink =
        color ??
        switch (scale) {
          AppNumeralScale.canto ||
          AppNumeralScale.peca ||
          AppNumeralScale.pecaNumeral => tokens.palette.mist,
          AppNumeralScale.vazio => tokens.palette.emptyNumeral,
          _ => DefaultTextStyle.of(context).style.color ?? tokens.palette.ivory,
        };
    final base = tokens
        .numeral(scale, selected: selected, fontSize: size)
        .copyWith(color: ink);
    final floor = minFontSize ?? spec.minSize;
    return Semantics(
      label: semanticsLabel ?? value,
      liveRegion: live,
      child: ExcludeSemantics(
        child: MediaQuery.withNoTextScaling(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final style = _fit(base, floor, constraints.maxWidth);
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(value, maxLines: 1, softWrap: false, style: style),
              );
            },
          ),
        ),
      ),
    );
  }

  TextStyle _fit(TextStyle style, double floor, double maxWidth) {
    if (!maxWidth.isFinite) return style;
    var size = style.fontSize!;
    var current = style;
    while (size > floor && _width(current) > maxWidth) {
      size = math.max(floor, size - 1);
      current = BtType.resize(style, size);
    }
    return current;
  }

  double _width(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

/// The table numeral that fills a player card, like `.life` in the
/// prototype: `min((height − 2 × reserve) × 1.38, width × 0.38)`, and
/// `0.26` of the width for three digits.
///
/// It is measured by its container (a [LayoutBuilder]), never by the screen,
/// and it is a class of its own because its contract differs from
/// [AppNumeral]: it receives no scale, it measures its parent.
class AppNumeralMesa extends StatelessWidget {
  const AppNumeralMesa(
    this.value, {
    super.key,
    this.reservaVertical = 38,
    this.fatorAltura = 1.38,
    this.fatorLargura = 0.38,
    this.fatorLarguraLongo = 0.26,
    this.minFontSize = 28,
    this.color,
    this.semanticsLabel,
  });

  final String value;

  /// What stays above and below inside the card (`.core { inset: 38px 0 }`).
  final double reservaVertical;
  final double fatorAltura;
  final double fatorLargura;

  /// Width factor once [value] has three or more characters.
  final double fatorLarguraLongo;
  final double minFontSize;
  final Color? color;
  final String? semanticsLabel;

  /// The font size the ruler computes for a card of [size].
  double fontSizeFor(Size size) {
    final byHeight = (size.height - 2 * reservaVertical) * fatorAltura;
    final factor = value.length >= 3 ? fatorLarguraLongo : fatorLargura;
    final byWidth = size.width * factor;
    return math.max(minFontSize, math.min(byHeight, byWidth));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    return Semantics(
      label: semanticsLabel ?? value,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            assert(
              constraints.hasBoundedHeight && constraints.hasBoundedWidth,
              'AppNumeralMesa needs a bounded box: inside a Flex the height '
              'can be infinite and the ruler formula breaks.',
            );
            final size = fontSizeFor(constraints.biggest);
            final style = tokens
                .numeral(AppNumeralScale.mesa, fontSize: size)
                .copyWith(
                  color:
                      color ??
                      DefaultTextStyle.of(context).style.color ??
                      tokens.palette.ivory,
                );
            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  textScaler: TextScaler.noScaling,
                  style: style,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
