import 'package:flutter/material.dart';

import '../theme/bt_tokens.dart';
import 'app_numeral.dart';
import 'app_tile.dart';
import 'bt_surface.dart';

/// The numeral piece (`.v`, vt-04-regras.png) — `AppNumberTile` in
/// docs/design/ui-kit-spec.md §5.
///
/// A 70×58 piece that paints neither icon nor label, only an
/// `AppNumeral(pecaNumeral)`: 36px in mist, 40px obsidian on brass when
/// selected, 30px in the "outro" variant. [label] stays mandatory and is
/// the accessible name (`'<label>: <value>'`), because the number alone
/// says nothing. It replaces segmented numbers and short sliders, so its
/// semantics are the exclusive-group ones.
class AppNumeralPiece extends StatelessWidget {
  const AppNumeralPiece({
    super.key,
    required this.label,
    required this.value,
    this.selected = false,
    this.armed = false,
    this.other = false,
    this.status = AppTileStatus.normal,
    this.onTap,
    this.onArmedConfirm,
    this.armKey,
  });

  /// The caption that gives the number its meaning ("Segurar muda de").
  final String label;

  /// Already formatted.
  final String value;
  final bool selected;
  final bool armed;

  /// The "outro" variant: numeral 30px.
  final bool other;
  final AppTileStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onArmedConfirm;
  final Object? armKey;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final palette = tokens.palette;
    final metrics = tokens.metrics;
    final scope = BtArmedScope.maybeOf(context);
    final id = armKey ?? key ?? '$label:$value';
    final loading = status == AppTileStatus.carregando;
    final error = !loading && status == AppTileStatus.erro;
    final empty = !loading && !error && status == AppTileStatus.vazio;
    final isArmed =
        !loading && !error && (armed || (scope?.isArmed(id) ?? false));
    final isSelected = !loading && !error && !empty && !isArmed && selected;
    final handler = loading
        ? null
        : BtArming.resolve(
            scope: scope,
            id: id,
            armed: isArmed,
            onTap: onTap,
            onArmedConfirm: onArmedConfirm,
          );
    final enabled = handler != null;

    Gradient gradient = LinearGradient(
      colors: [palette.numeralPieceSurface, palette.numeralPieceSurface],
    );
    var shadows = tokens.shadows.numeralPiece;
    if (error) {
      gradient = tokens.gradients.errorGlass;
      shadows = tokens.shadows.error;
    } else if (empty) {
      gradient = tokens.gradients.free;
      shadows = const <BtShadow>[];
    } else if (isSelected) {
      gradient = tokens.gradients.brassPiece;
      shadows = tokens.shadows.numeralPieceOn;
    } else if (isArmed) {
      shadows = tokens.shadows.armed;
    }

    final Widget content;
    if (loading) {
      content = const BtThread(width: 28);
    } else if (error) {
      content = BtThread(width: 28, color: palette.ember);
    } else if (empty) {
      content = const AppNumeral('0', scale: AppNumeralScale.vazio);
    } else {
      content = AppNumeral(
        value,
        scale: AppNumeralScale.pecaNumeral,
        selected: isSelected,
        size: other ? 30 : null,
        color: isSelected
            ? palette.obsidian
            : isArmed
            ? palette.brass
            : null,
      );
    }

    final body = SizedBox(
      width: 70,
      height: 58,
      child: BtSurface(
        gradient: gradient,
        radius: metrics.radiusRule,
        shadows: shadows,
        dashed: empty,
        sweep: loading,
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -2),
            child: content,
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      selected: isSelected,
      enabled: enabled,
      label: '$label: $value',
      value: error
          ? 'erro, tentar de novo'
          : isArmed
          ? 'toque de novo para confirmar'
          : null,
      onTap: handler,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled || loading ? 1 : metrics.disabledOpacity,
          child: BtPressable(
            radius: metrics.radiusRule,
            onTap: handler,
            focusRing: isSelected ? BtFocusRing.obsidian : BtFocusRing.brass,
            child: body,
          ),
        ),
      ),
    );
  }
}
