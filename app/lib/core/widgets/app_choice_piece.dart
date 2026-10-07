import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/bt_tokens.dart';
import 'app_numeral.dart';
import 'app_tile.dart';
import 'bt_surface.dart';

/// The choice piece with a thumbnail (`.p` + `.seats`, jogadores.png) —
/// `AppChoiceTile` in docs/design/ui-kit-spec.md §5.
///
/// An [AppTile] whose icon slot is a real thumbnail and whose foot carries
/// an `AppNumeral(peca)`. The choice is worth on touch; the current one is
/// the brass piece with the selection halo, and its numeral steps from 38
/// to 44. It replaces `Radio` and `DropdownButton` rows, so its semantics
/// are the exclusive-group ones: `inMutuallyExclusiveGroup` + `checked`.
class AppChoicePiece extends StatelessWidget {
  const AppChoicePiece({
    super.key,
    required this.label,
    this.thumbnail,
    this.numeral,
    this.caption,
    this.selected = false,
    this.armed = false,
    this.status = AppTileStatus.normal,
    this.onTap,
    this.onArmedConfirm,
    this.armKey,
    this.semanticsValue,
  });

  /// The accessible name of the option (not painted).
  final String label;

  /// The real miniature (e.g. the table seats); drawn over obsidian .8,
  /// radius 12, 30–66 tall.
  final Widget? thumbnail;

  /// The value of the option, already formatted.
  final String? numeral;

  /// Small capitals at the foot end ("ATUAL", "CONFIRMAR").
  final String? caption;
  final bool selected;
  final bool armed;
  final AppTileStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onArmedConfirm;
  final Object? armKey;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final palette = tokens.palette;
    final metrics = tokens.metrics;
    final scope = BtArmedScope.maybeOf(context);
    final id = armKey ?? key ?? label;
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

    Gradient gradient = tokens.gradients.glassPiece;
    var shadows = tokens.shadows.piece;
    if (error) {
      gradient = tokens.gradients.errorGlass;
      shadows = tokens.shadows.error;
    } else if (empty) {
      gradient = tokens.gradients.free;
      shadows = tokens.shadows.free;
    } else if (isSelected) {
      gradient = tokens.gradients.brassPiece;
      shadows = tokens.shadows.selected;
    } else if (isArmed) {
      shadows = tokens.shadows.armed;
    }

    final numeralColor = error
        ? palette.ember
        : isSelected
        ? palette.obsidian
        : isArmed
        ? palette.brass
        : null;
    final captionColor = error
        ? palette.ember
        : isSelected
        ? palette.obsidian.withValues(alpha: 0.75)
        : empty
        ? palette.brassLabel
        : palette.mistDim;
    final captionText = error ? 'tentar de novo' : caption;

    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(metrics.radiusMini),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 30, maxHeight: 66),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? palette.obsidian : palette.thumbnail,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppTheme.space4),
            child: loading || thumbnail == null
                ? const SizedBox(width: double.infinity)
                : thumbnail,
          ),
        ),
      ),
    );

    final foot = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (loading)
          const BtThread(width: 40)
        else if (empty)
          const AppNumeral('0', scale: AppNumeralScale.vazio)
        else if (numeral != null)
          AppNumeral(
            numeral!,
            scale: AppNumeralScale.peca,
            selected: isSelected,
            color: numeralColor,
          ),
        const SizedBox(width: AppTheme.space6),
        Expanded(
          child: captionText == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppTheme.space3,
                  ),
                  child: Text(
                    captionText.toUpperCase(),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.typography.pieceCaption.copyWith(
                      color: captionColor,
                    ),
                  ),
                ),
        ),
      ],
    );

    final body = BtSurface(
      gradient: gradient,
      radius: metrics.radiusTile,
      shadows: shadows,
      dashed: empty,
      sweep: loading,
      padding: metrics.padPiece,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 112 - 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // `.p .seats { flex: 1 1 0; max-height: 66px; min-height: 30px }`
            final sized = SizedBox(
              height: 66,
              width: double.infinity,
              child: thumb,
            );
            return Column(
              mainAxisSize: constraints.hasBoundedHeight
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!empty)
                  constraints.hasBoundedHeight ? Flexible(child: sized) : sized,
                const SizedBox(height: AppTheme.space6),
                foot,
              ],
            );
          },
        ),
      ),
    );

    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      selected: isSelected,
      enabled: enabled,
      label: numeral == null ? label : '$label: $numeral',
      value:
          semanticsValue ??
          (error
              ? 'erro, tentar de novo'
              : isArmed
              ? 'toque de novo para confirmar'
              : null),
      onTap: handler,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled || loading ? 1 : metrics.disabledOpacity,
          child: BtPressable(
            radius: metrics.radiusTile,
            onTap: handler,
            focusRing: isSelected ? BtFocusRing.obsidian : BtFocusRing.brass,
            child: body,
          ),
        ),
      ),
    );
  }
}
