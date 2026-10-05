import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/bt_tokens.dart';
import 'app_tile.dart';
import 'bt_surface.dart';

/// The kind of a footer action (§5, `AppActionBar`).
enum AppActionKind {
  /// Glass, like a neutral tile.
  neutra,

  /// Brass with the sheen: the single main play of the footer.
  principal,

  /// Ember ink: ends or destroys, two taps.
  brasa,
}

/// One footer action. DERIVED: the ruler's `.btn` is still in the old
/// language; only its 46px height and `0 16` padding came from it, and the
/// radius is the ruler's 12 (F6, D-44). The visual is 46 tall and the
/// touch target grows to 48 with transparent room.
@immutable
class AppAction {
  const AppAction(
    this.label, {
    this.onTap,
    this.onArmedConfirm,
    this.kind = AppActionKind.neutra,
    this.icon,
    this.armKey,
  });

  const AppAction.principal(this.label, {this.onTap, this.icon})
    : kind = AppActionKind.principal,
      onArmedConfirm = null,
      armKey = null;

  final String label;
  final VoidCallback? onTap;

  /// For [AppActionKind.brasa]: fires on the second tap inside a
  /// [BtArmedScope]; the label turns into `TOCAR DE NOVO` while armed.
  final VoidCallback? onArmedConfirm;
  final AppActionKind kind;
  final Widget? icon;
  final Object? armKey;
}

/// The action footer of an [AppTileOverlay] (`.sheet > .btns`): outside
/// the scroll, `auto-fit minmax(140px, 1fr)` with gap 8, at most one main
/// action (one hero per screen).
class AppActionBar extends StatelessWidget {
  const AppActionBar({
    super.key,
    this.actions = const <AppAction>[],
    this.primary,
  });

  /// Neutral or ember actions, in reading order.
  final List<AppAction> actions;

  /// The main action, placed last.
  final AppAction? primary;

  @override
  Widget build(BuildContext context) {
    final all = [...actions, if (primary != null) primary!];
    assert(
      all.where((a) => a.kind == AppActionKind.principal).length <= 1,
      'At most one main action per footer: one hero per screen.',
    );
    final gap = BtTokens.of(context).metrics.gapTile;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 560.0;
        final fit = ((width + gap) / (140 + gap)).floor().clamp(1, 99);
        final columns = all.isEmpty ? 1 : fit.clamp(1, all.length);
        final cell = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in all)
              SizedBox(
                width: cell,
                child: AppActionButton(action: action),
              ),
          ],
        );
      },
    );
  }
}

/// One rendered [AppAction].
class AppActionButton extends StatelessWidget {
  const AppActionButton({super.key, required this.action});

  final AppAction action;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final palette = tokens.palette;
    final metrics = tokens.metrics;
    final scope = BtArmedScope.maybeOf(context);
    final id = action.armKey ?? action.label;
    final isArmed = scope?.isArmed(id) ?? false;
    final handler = BtArming.resolve(
      scope: scope,
      id: id,
      armed: isArmed,
      onTap: action.onTap,
      onArmedConfirm: action.onArmedConfirm,
    );
    final enabled = handler != null;
    final principal = action.kind == AppActionKind.principal;
    final ember = action.kind == AppActionKind.brasa;
    final ink = principal
        ? palette.obsidian
        : ember
        ? palette.ember
        : palette.ivory;
    final text = isArmed ? 'tocar de novo' : action.label;

    final surface = BtSurface(
      gradient: principal
          ? tokens.gradients.brass
          : tokens.gradients.glassPiece,
      radius: metrics.radiusAction,
      shadows: principal
          ? tokens.shadows.brass
          : isArmed
          ? tokens.shadows.armedEmber
          : tokens.shadows.action,
      sheen: principal,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppTheme.space16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 46),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (action.icon != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: ink, size: 18),
                child: action.icon!,
              ),
              const SizedBox(width: AppTheme.space8),
            ],
            Flexible(
              child: Text(
                text.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tokens.typography.action.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: action.label,
      value: isArmed ? 'toque de novo para confirmar' : null,
      onTap: handler,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled ? 1 : metrics.disabledOpacity,
          child: BtPressable(
            radius: metrics.radiusAction,
            onTap: handler,
            focusRing: principal ? BtFocusRing.obsidian : BtFocusRing.brass,
            child: Padding(
              // 46 → 48: one transparent dp above and below.
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppTheme.space1,
              ),
              child: surface,
            ),
          ),
        ),
      ),
    );
  }
}
