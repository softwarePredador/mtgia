import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/bt_tokens.dart';
import 'bt_surface.dart';

/// One turn-order pip of an [AppHeroTile] (`.menu .ordem i`).
@immutable
class AppHeroPip {
  const AppHeroPip({
    required this.color,
    this.current = false,
    this.out = false,
  });

  /// The seat color of the player.
  final Color color;

  /// The player in turn: the pip grows from 13 to 28px.
  final bool current;

  /// Out of the game: opacity .3.
  final bool out;
}

/// A secondary round action carved into the brass (vt-08), at most two.
@immutable
class AppHeroAction {
  const AppHeroAction({required this.icon, required this.label, this.onTap});

  final Widget icon;
  final String label;
  final VoidCallback? onTap;
}

/// The brass hero (`.menu .hero`, docs/design/ui-kit-spec.md §4.5): the
/// main play of the screen, exactly one per screen.
///
/// Turn block (caption + numeral) · 2px divider · label, name and pips ·
/// the obsidian round button. [idle] removes the turn block and divider
/// (`.hero.is-idle`); above ~170% text scale it happens on its own.
/// [loading] turns the brass off (glass + sweep): brass means "in force
/// now", and loading is not. The hero never arms: destroying is an ember
/// tile with two taps.
class AppHeroTile extends StatelessWidget {
  const AppHeroTile({
    super.key,
    required this.label,
    required this.title,
    this.leadingNumeral,
    this.leadingCaption,
    this.subtitle,
    this.pips = const <AppHeroPip>[],
    this.onGo,
    this.onTap,
    this.goIcon,
    this.goLabel,
    this.secondaryActions = const <AppHeroAction>[],
    this.idle = false,
    this.loading = false,
    this.semanticsHint,
  }) : assert(
         secondaryActions.length <= 2,
         'The hero takes at most two secondary actions.',
       );

  /// Inter 800 capitals.
  final String label;

  /// Fraunces 30px: the name.
  final String title;

  /// Usually `AppNumeral(scale: AppNumeralScale.heroi)`.
  final Widget? leadingNumeral;

  /// "TURNO".
  final String? leadingCaption;

  /// "RODADA 1" (vt-08).
  final String? subtitle;
  final List<AppHeroPip> pips;

  /// The obsidian round button.
  final VoidCallback? onGo;

  /// The hero body; defaults to [onGo].
  final VoidCallback? onTap;

  /// Defaults to the brass arrow (27px, stroke 2.4).
  final Widget? goIcon;

  /// Accessible name of the round button; defaults to [label].
  final String? goLabel;
  final List<AppHeroAction> secondaryActions;
  final bool idle;
  final bool loading;

  /// "passa a vez para o próximo jogador".
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final bodyTap = loading ? null : (onTap ?? onGo);
    final goTap = loading ? null : onGo;
    final enabled = bodyTap != null || goTap != null;
    return LayoutBuilder(
      builder: (context, constraints) =>
          _build(context, tokens, bodyTap, goTap, enabled, constraints),
    );
  }

  Widget _build(
    BuildContext context,
    BtTokens tokens,
    VoidCallback? bodyTap,
    VoidCallback? goTap,
    bool enabled,
    BoxConstraints constraints,
  ) {
    final palette = tokens.palette;
    final metrics = tokens.metrics;
    final textScale = MediaQuery.textScalerOf(context).scale(10) / 10;
    // DERIVED: above ~170% text scale, or when the hero is too narrow for
    // the turn block (a portrait phone board), it collapses to `idle`.
    final narrow = constraints.maxWidth.isFinite && constraints.maxWidth < 250;
    final showTurn =
        !idle &&
        !narrow &&
        textScale <= 1.7 &&
        (leadingNumeral != null || leadingCaption != null);
    final ink = loading ? palette.ivory : palette.obsidian;

    final turn = showTurn
        ? ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56, minHeight: 64),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingCaption != null)
                  Text(
                    leadingCaption!.toUpperCase(),
                    style: tokens.typography.heroCaption.copyWith(
                      color: loading
                          ? palette.sublabel
                          : palette.captionOnBrass,
                    ),
                  ),
                if (leadingCaption != null && leadingNumeral != null)
                  const SizedBox(height: AppTheme.space6),
                if (leadingNumeral != null)
                  DefaultTextStyle.merge(
                    style: TextStyle(color: ink),
                    child: loading
                        ? const BtThread(width: 40)
                        : leadingNumeral!,
                  ),
              ],
            ),
          )
        : null;

    final mid = Container(
      padding: EdgeInsetsDirectional.only(
        start: showTurn ? AppTheme.space12 : AppTheme.space2,
      ),
      decoration: showTurn
          ? BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(
                  color: palette.heroDivider,
                  width: AppTheme.strokeStrong,
                ),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tokens.typography.label.copyWith(color: ink),
          ),
          const SizedBox(height: AppTheme.space5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.typography.heroName.copyWith(color: ink),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.space5),
            Text(
              subtitle!.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tokens.typography.heroCaption.copyWith(
                color: loading ? palette.sublabel : palette.obsidian,
              ),
            ),
          ],
          if (pips.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space7),
            ExcludeSemantics(
              child: Wrap(
                spacing: AppTheme.space5,
                runSpacing: AppTheme.space5,
                children: [for (final pip in pips) _Pip(pip: pip)],
              ),
            ),
          ],
        ],
      ),
    );

    final row = Row(
      children: [
        if (turn != null) ...[
          ExcludeSemantics(child: turn),
          const SizedBox(width: AppTheme.space12),
        ],
        Expanded(child: ExcludeSemantics(child: mid)),
        for (final action in secondaryActions) ...[
          const SizedBox(width: AppTheme.space8),
          _CarvedAction(action: action, enabled: !loading),
        ],
        const SizedBox(width: AppTheme.space12),
        _GoButton(
          onTap: goTap,
          label: goLabel ?? label,
          icon: goIcon,
          loading: loading,
        ),
      ],
    );

    final surface = BtSurface(
      gradient: loading ? tokens.gradients.glassPiece : tokens.gradients.brass,
      radius: metrics.radiusTile,
      shadows: loading ? tokens.shadows.piece : tokens.shadows.brass,
      sheen: !loading,
      sweep: loading,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppTheme.space16,
        AppTheme.space10,
        AppTheme.space14,
        AppTheme.space10,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 120 - 20),
        child: Center(child: row),
      ),
    );

    // Two targets, not one (§4.5f): the hero body and the round button.
    // The hero node keeps explicit children so the button stays reachable.
    return Opacity(
      opacity: enabled || loading ? 1 : metrics.disabledOpacity,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        button: true,
        enabled: bodyTap != null,
        label: '$label, $title',
        hint: semanticsHint,
        onTap: bodyTap,
        child: BtPressable(
          radius: metrics.radiusTile,
          onTap: bodyTap,
          focusRing: BtFocusRing.obsidian,
          child: surface,
        ),
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.pip});

  final AppHeroPip pip;

  @override
  Widget build(BuildContext context) {
    final palette = BtTokens.of(context).palette;
    final still = MediaQuery.disableAnimationsOf(context);
    return Opacity(
      opacity: pip.out ? 0.3 : 1,
      child: AnimatedContainer(
        duration: still ? Duration.zero : const Duration(milliseconds: 160),
        width: pip.current ? 28 : 13,
        height: 13,
        decoration: BoxDecoration(
          color: pip.color,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [BoxShadow(color: palette.pipRing, spreadRadius: 2)],
        ),
      ),
    );
  }
}

class _GoButton extends StatelessWidget {
  const _GoButton({
    required this.onTap,
    required this.label,
    required this.icon,
    required this.loading,
  });

  final VoidCallback? onTap;
  final String label;
  final Widget? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final palette = tokens.palette;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: BtPressable(
          radius: 28,
          shape: BoxShape.circle,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 56,
            child: BtSurface(
              gradient: LinearGradient(
                colors: [palette.obsidian, palette.obsidian],
              ),
              radius: 28,
              shadows: tokens.shadows.heroGo,
              child: Center(
                child: loading
                    ? const BtThread(width: 24)
                    : IconTheme.merge(
                        data: IconThemeData(color: palette.brass, size: 27),
                        child:
                            icon ??
                            BtStrokeGlyph(
                              BtGlyphShape.arrowForward,
                              size: 27,
                              strokeWidth: 2.4,
                              color: palette.brass,
                            ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A secondary action carved into the brass: no obsidian, a darker well.
class _CarvedAction extends StatelessWidget {
  const _CarvedAction({required this.action, required this.enabled});

  final AppHeroAction action;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final palette = tokens.palette;
    final onTap = enabled ? action.onTap : null;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: action.label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: BtPressable(
          radius: 24,
          shape: BoxShape.circle,
          onTap: onTap,
          child: SizedBox.square(
            dimension: tokens.metrics.touchTarget,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.heroDivider,
              ),
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(color: palette.obsidian, size: 22),
                  child: action.icon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
