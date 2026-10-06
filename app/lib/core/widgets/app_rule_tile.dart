import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/bt_tokens.dart';
import 'app_tile.dart';
import 'bt_surface.dart';

/// Size variants of [AppRuleTile].
enum AppRuleTileSize {
  /// `.rt`: min-height 96, three bands (icon · title · state word).
  regular,

  /// `.rt.sm`: 84×58, icon over a short centered title (Sem / Dia / Noite).
  small,

  /// `.pf-states .rt`: min-height 74, three per row, title 13px.
  estado,
}

/// Which old control the rule replaces; it decides the semantic role
/// (§4.1f): a `Switch` is announced as toggled, a `Checkbox` as checked.
enum AppRuleTileRole { toggle, checkbox }

/// The rule piece that lights up and says VALE (`.rt`,
/// docs/design/ui-kit-spec.md §5) — the replacement of `Switch`,
/// `SwitchListTile` and `Checkbox`.
///
/// Off it is glass with `NÃO VALE`; on it is the brass piece with obsidian
/// ink and `VALE` at full opacity (B1, D-44). [bad] paints a bad state in
/// force in the wine vitral with ivory ink. The state is said in words, not
/// in a switch position.
///
/// F4 (D-44): the title can be rich text with its own targets — legal
/// consent with links inside the sentence. Build the links with
/// [AppRuleTile.link]; each one is its own 48 dp target and its own
/// semantic node, and tapping it does not toggle the rule.
class AppRuleTile extends StatelessWidget {
  const AppRuleTile({
    super.key,
    required this.title,
    required this.on,
    this.onTap,
    this.icon,
    this.titleSpans,
    this.bad = false,
    this.size = AppRuleTileSize.regular,
    this.role = AppRuleTileRole.toggle,
    this.status = AppTileStatus.normal,
    this.onWord = 'vale',
    this.offWord = 'não vale',
  });

  /// Plain title; also the accessible name.
  final String title;
  final bool on;

  /// Toggles the rule; null disables it.
  final VoidCallback? onTap;
  final Widget? icon;

  /// Rich title with its own targets (F4); replaces the painted [title].
  final List<InlineSpan>? titleSpans;

  /// A bad state in force (`.rt.bad.on`): wine vitral when [on].
  final bool bad;
  final AppRuleTileSize size;
  final AppRuleTileRole role;
  final AppTileStatus status;
  final String onWord;
  final String offWord;

  /// An inline link for [titleSpans]: underlined, with a 48 dp target and
  /// its own `link` semantics.
  static InlineSpan link(
    String text, {
    required VoidCallback onTap,
    String? semanticsLabel,
  }) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: _RuleLink(text: text, onTap: onTap, semanticsLabel: semanticsLabel),
  );

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final palette = tokens.palette;
    final metrics = tokens.metrics;
    final loading = status == AppTileStatus.carregando;
    final error = !loading && status == AppTileStatus.erro;
    final lit = on && !loading && !error;
    final handler = loading ? null : onTap;
    final enabled = handler != null;

    Gradient gradient = tokens.gradients.glassPiece;
    var shadows = tokens.shadows.rule;
    var ink = palette.ivory;
    var stateInk = palette.mistDim;
    var iconInk = palette.mist;
    List<Shadow>? stateShadow;
    if (error) {
      gradient = tokens.gradients.errorGlass;
      shadows = tokens.shadows.error;
      ink = palette.ember;
      stateInk = palette.ember;
      iconInk = palette.ember;
    } else if (lit && bad) {
      gradient = tokens.gradients.wine;
      shadows = tokens.shadows.ruleBadOn;
      stateInk = palette.ivory;
      iconInk = palette.ivory;
      stateShadow = [
        Shadow(
          color: palette.obsidian.withValues(alpha: 0.45),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];
    } else if (lit) {
      gradient = tokens.gradients.brassPiece;
      shadows = tokens.shadows.ruleOn;
      ink = palette.obsidian;
      stateInk = palette.obsidian;
      iconInk = palette.obsidian;
    }

    final word = error ? 'tocar de novo' : (on ? onWord : offWord);
    final regular = size == AppRuleTileSize.regular;
    final small = size == AppRuleTileSize.small;
    final estado = size == AppRuleTileSize.estado;
    final iconSize = estado ? 20.0 : 26.0;
    final titleStyle = tokens.typography.ruleTitle.copyWith(
      color: ink,
      fontSize: estado ? 13 : null,
    );

    final iconWidget = icon == null
        ? null
        : SizedBox.square(
            dimension: iconSize,
            child: IconTheme.merge(
              data: IconThemeData(color: iconInk, size: iconSize),
              child: icon!,
            ),
          );

    final Widget titleWidget;
    if (loading) {
      titleWidget = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: small
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [BtThread(width: 84, height: 9, color: palette.labelBar)],
      );
    } else if (titleSpans != null) {
      // The links are WidgetSpans: they read the title style from here.
      titleWidget = DefaultTextStyle.merge(
        style: titleStyle,
        child: Text.rich(
          TextSpan(style: titleStyle, children: titleSpans),
          textAlign: small ? TextAlign.center : TextAlign.start,
        ),
      );
    } else {
      titleWidget = Text(
        title,
        maxLines: small ? 2 : 3,
        overflow: TextOverflow.ellipsis,
        textAlign: small ? TextAlign.center : TextAlign.start,
        style: titleStyle,
      );
    }

    // The state word is the node's value; it is not read twice.
    final stateWidget = loading
        ? const BtThread(width: 40)
        : ExcludeSemantics(
            child: Text(
              word.toUpperCase(),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: tokens.typography.ruleState.copyWith(
                color: stateInk,
                shadows: stateShadow,
              ),
            ),
          );

    final Widget content;
    if (small) {
      content = SizedBox(
        width: 84,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppTheme.space8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconWidget != null) iconWidget,
                const SizedBox(height: AppTheme.space4),
                titleWidget,
              ],
            ),
          ),
        ),
      );
    } else {
      content = ConstrainedBox(
        constraints: BoxConstraints(minHeight: regular ? 96 : 74),
        child: Padding(
          padding: regular
              ? metrics.padRule
              : const EdgeInsetsDirectional.fromSTEB(
                  AppTheme.space10,
                  AppTheme.space9,
                  AppTheme.space10,
                  AppTheme.space9,
                ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconWidget ?? SizedBox(height: iconSize),
              SizedBox(height: regular ? AppTheme.space6 : AppTheme.space3),
              titleWidget,
              SizedBox(height: regular ? AppTheme.space6 : AppTheme.space3),
              stateWidget,
            ],
          ),
        ),
      );
    }

    final body = BtSurface(
      gradient: gradient,
      radius: estado ? metrics.radiusPanel : metrics.radiusRule,
      shadows: shadows,
      sweep: loading,
      child: content,
    );

    final rich = titleSpans != null && !loading;
    final pressable = Opacity(
      opacity: enabled || loading ? 1 : metrics.disabledOpacity,
      child: BtPressable(
        radius: estado ? metrics.radiusPanel : metrics.radiusRule,
        onTap: handler,
        focusRing: lit && !bad ? BtFocusRing.obsidian : BtFocusRing.brass,
        child: body,
      ),
    );

    return Semantics(
      container: true,
      toggled: role == AppRuleTileRole.toggle ? on : null,
      checked: role == AppRuleTileRole.checkbox ? on : null,
      enabled: enabled,
      // A rich title merges its text into this node and keeps each link
      // as a node of its own (the link is a container); a plain one is the
      // name of the rule.
      label: rich ? null : title,
      value: word,
      onTap: handler,
      child: rich ? pressable : ExcludeSemantics(child: pressable),
    );
  }
}

class _RuleLink extends StatelessWidget {
  const _RuleLink({
    required this.text,
    required this.onTap,
    required this.semanticsLabel,
  });

  final String text;
  final VoidCallback onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final color = style.color ?? BtTokens.of(context).palette.ivory;
    return Semantics(
      container: true,
      link: true,
      button: true,
      label: semanticsLabel ?? text,
      onTap: onTap,
      child: ExcludeSemantics(
        child: BtPressable(
          radius: 6,
          onTap: onTap,
          scaleOnPress: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: BtTokens.of(context).metrics.touchTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                text,
                style: style.copyWith(
                  color: color,
                  decoration: TextDecoration.underline,
                  decorationColor: color,
                  decorationThickness: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
