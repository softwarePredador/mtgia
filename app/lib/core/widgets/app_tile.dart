import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/bt_tokens.dart';
import 'bt_surface.dart';

/// The surface family of a tile (docs/design/ui-kit-spec.md §4.1c).
enum AppTileTone {
  /// Dark glass with an ivory filet: a neutral action without state.
  vidro,

  /// Full stained-glass color: something is in force now.
  vitral,

  /// Full brass: the main play of the screen.
  latao,

  /// Dashed brass outline: empty, without owner.
  livre,

  /// Ember as ink: ends or destroys; asks for two taps.
  brasaTinta,

  /// Full wine vitral: destroying as the hero of the screen, or a bad state
  /// in force.
  brasaCheia,
}

/// Data status of a tile, orthogonal to its tone.
enum AppTileStatus { normal, carregando, erro, vazio }

/// The tile (`.menu .t`), the base object of the kit (§4.1).
///
/// Five slots — [icon], [estado], [numeral], [label], [sublabel]; only
/// [label] is mandatory. State precedence is
/// `carregando > erro > armado > selecionado > tone`:
///
/// * `carregando` ignores tone, selection and arming: dark glass with the
///   brass sweep, and taps are off;
/// * `erro` ignores tone and selection, keeps the label and turns the
///   corner into `DE NOVO`;
/// * armed keeps the tone background and adds the ember ring (it wins over
///   the brass of selection);
/// * selected forces the brass piece gradient (a `livre` tile cannot be
///   selected);
/// * `vazio` paints like `livre`; when both arrive, `livre` wins.
///
/// Two-tap pieces: inside a [BtArmedScope] the tile arms itself on the
/// first tap when [onArmedConfirm] is set, disarms after 6 s or when another
/// piece arms, and fires [onArmedConfirm] on the second tap. Without a scope
/// the caller drives [armed].
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.label,
    this.icon,
    this.sublabel,
    this.estado,
    this.numeral,
    this.tone = AppTileTone.vidro,
    this.vitralColor,
    this.vitralColorDeep,
    this.status = AppTileStatus.normal,
    this.selected = false,
    this.armed = false,
    this.onTap,
    this.onArmedConfirm,
    this.armKey,
    this.semanticsValue,
    this.autofocus = false,
  }) : assert(
         !(selected && tone == AppTileTone.livre),
         'A tile without owner (livre) cannot be selected.',
       ),
       assert(
         !(tone == AppTileTone.brasaCheia && status == AppTileStatus.erro),
         'brasaCheia already means "a bad state in force"; stacking erro on '
         'it is redundant and unreadable.',
       ),
       assert(
         tone != AppTileTone.vitral || vitralColor != null,
         'tone.vitral needs vitralColor (--bt-c).',
       );

  /// Always painted in capitals.
  final String label;

  /// 34×34 slot, top start.
  final Widget? icon;
  final String? sublabel;

  /// Top end corner; usually an [AppTileEstado].
  final Widget? estado;

  /// Usually an [AppNumeral].
  final Widget? numeral;
  final AppTileTone tone;

  /// `--bt-c`, required for [AppTileTone.vitral].
  final Color? vitralColor;

  /// `--bt-c2`; defaults to `mix(c, #000, 34%)`.
  final Color? vitralColorDeep;
  final AppTileStatus status;
  final bool selected;

  /// Ember ring; asks for the second tap.
  final bool armed;

  /// Null (with [onArmedConfirm] also null) disables the tile.
  final VoidCallback? onTap;

  /// Fires only on the second tap, when the tile is armed.
  final VoidCallback? onArmedConfirm;

  /// Identity inside a [BtArmedScope]; defaults to [key] or [label].
  final Object? armKey;

  /// What the screen reader says about the state.
  final String? semanticsValue;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final palette = tokens.palette;
    final metrics = tokens.metrics;
    final scope = BtArmedScope.maybeOf(context);
    final id = armKey ?? key ?? label;
    final loading = status == AppTileStatus.carregando;
    final error = !loading && status == AppTileStatus.erro;
    final isArmed =
        !loading && !error && (armed || (scope?.isArmed(id) ?? false));
    final free = tone == AppTileTone.livre || status == AppTileStatus.vazio;
    final isSelected = !loading && !error && !isArmed && selected && !free;
    final arming = BtArming.resolve(
      scope: scope,
      id: id,
      armed: isArmed,
      onTap: onTap,
      onArmedConfirm: onArmedConfirm,
    );
    final handler = loading ? null : arming;
    final enabled = handler != null;

    // ── surface ──
    Gradient gradient;
    List<BtShadow> shadows;
    var sheen = false;
    var dashed = false;
    if (loading) {
      gradient = tokens.gradients.glassTile;
      shadows = tokens.shadows.tile;
    } else if (error) {
      gradient = tokens.gradients.errorGlass;
      shadows = tokens.shadows.error;
    } else if (isSelected) {
      gradient = tokens.gradients.brassPiece;
      shadows = tokens.shadows.brass;
      sheen = true;
    } else if (free) {
      gradient = tokens.gradients.free;
      shadows = tokens.shadows.free;
      dashed = true;
    } else {
      switch (tone) {
        case AppTileTone.vitral:
          gradient = tokens.vitral(vitralColor!, deep: vitralColorDeep);
          shadows = tokens.shadows.lit;
          sheen = true;
        case AppTileTone.brasaCheia:
          gradient = tokens.vitral(
            vitralColor ?? palette.wine,
            deep: vitralColorDeep,
          );
          shadows = tokens.shadows.lit;
          sheen = true;
        case AppTileTone.latao:
          gradient = tokens.gradients.brass;
          shadows = tokens.shadows.brass;
          sheen = true;
        case AppTileTone.vidro:
        case AppTileTone.brasaTinta:
        case AppTileTone.livre:
          gradient = tokens.gradients.glassTile;
          shadows = tokens.shadows.tile;
      }
    }
    if (isArmed) shadows = tokens.shadows.armedEmber;

    // ── ink ──
    final onBrass =
        isSelected ||
        (!loading && !error && !free && !isArmed && tone == AppTileTone.latao);
    final ink = onBrass ? palette.obsidian : palette.ivory;
    Color labelInk = ink;
    Color iconInk = ink;
    if (error) {
      labelInk = palette.ember;
      iconInk = palette.ember;
    } else if (free && !loading) {
      labelInk = palette.brassLabel;
      iconInk = palette.brass;
    } else if (!loading && tone == AppTileTone.brasaTinta && !onBrass) {
      labelInk = palette.ember;
      iconInk = palette.ember;
    }
    final labelShadow = onBrass
        ? const <Shadow>[]
        : [
            Shadow(
              color: palette.shade35,
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ];

    // ── corner state ──
    final inVeiledBoard = BtBoardScope.veiledOf(context);
    final offInk = free
        ? palette.mist
        : (inVeiledBoard ? palette.mist : palette.mistDim);
    Widget? corner;
    if (loading) {
      corner = const BtThread();
    } else if (error) {
      corner = const AppTileEstado.off('de novo');
    } else if (isArmed) {
      corner = estado ?? const AppTileEstado.off('de novo');
    } else {
      corner = estado;
    }
    final cornerInk = error || isArmed ? palette.ember : ink;

    final textScale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final cornerInline = textScale > 1.6;

    final iconWidget = icon == null
        ? null
        : SizedBox.square(
            dimension: 34,
            child: IconTheme.merge(
              data: IconThemeData(
                color: iconInk,
                size: 34,
                shadows: onBrass
                    ? null
                    : [
                        Shadow(
                          color: palette.shade35,
                          offset: const Offset(0, 2),
                          blurRadius: 3,
                        ),
                      ],
              ),
              child: icon!,
            ),
          );

    final labelBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sublabel != null) ...[
          Text(
            sublabel!.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.typography.sublabel.copyWith(
              color: onBrass ? palette.obsidian : palette.sublabel,
            ),
          ),
          const SizedBox(height: AppTheme.space3),
        ],
        Text(
          label.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: tokens.typography.label.copyWith(
            color: labelInk,
            shadows: labelShadow,
          ),
        ),
        if (cornerInline && corner != null) ...[
          const SizedBox(height: AppTheme.space4),
          _cornerStyle(context, tokens, corner, cornerInk, offInk, onBrass),
        ],
      ],
    );

    final footer = numeral == null
        ? labelBlock
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DefaultTextStyle.merge(
                style: TextStyle(color: error ? palette.ember : ink),
                child: loading ? const BtThread() : numeral!,
              ),
              SizedBox(width: metrics.gapTile),
              Expanded(child: labelBlock),
            ],
          );

    Widget body = BtSurface(
      gradient: gradient,
      radius: metrics.radiusTile,
      shadows: shadows,
      sheen: sheen,
      dashed: dashed,
      sweep: loading,
      padding: metrics.padTile,
      child: ConstrainedBox(
        // `.mrow.r1 { flex: 112 }`: the tile is at least 112 tall, padding
        // included (12 + 11).
        constraints: const BoxConstraints(minHeight: 112 - 23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            iconWidget ?? const SizedBox(height: AppTheme.space34),
            const SizedBox(height: AppTheme.space8),
            footer,
          ],
        ),
      ),
    );

    if (!cornerInline && corner != null) {
      // The corner lives in the tile's own box: top 11 (15 when quiet),
      // end 13, at most 62% of the width, ellipsized (`.menu .state`).
      body = _TileWithCorner(
        surface: body,
        corner: _cornerStyle(
          context,
          tokens,
          corner,
          cornerInk,
          offInk,
          onBrass,
        ),
        top: AppTileEstado.isOff(corner) || loading ? 15 : 11,
      );
    }

    body = Opacity(
      opacity: enabled || loading ? 1 : metrics.disabledOpacity,
      child: body,
    );

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: isSelected,
      label: label,
      value:
          semanticsValue ??
          (error
              ? 'erro, tocar de novo'
              : isArmed
              ? 'armado, toque de novo para confirmar'
              : null),
      onTap: handler,
      child: ExcludeSemantics(
        child: BtPressable(
          radius: metrics.radiusTile,
          onTap: handler,
          autofocus: autofocus,
          focusRing: onBrass ? BtFocusRing.obsidian : BtFocusRing.brass,
          child: body,
        ),
      ),
    );
  }

  Widget _cornerStyle(
    BuildContext context,
    BtTokens tokens,
    Widget corner,
    Color ink,
    Color offInk,
    bool onBrass,
  ) {
    if (corner is AppTileEstado) {
      return AppTileEstadoTheme(
        onInk: ink,
        offInk: ink == tokens.palette.ember ? ink : offInk,
        shadowed: !onBrass,
        child: corner,
      );
    }
    return DefaultTextStyle.merge(
      style: TextStyle(color: ink),
      child: IconTheme.merge(
        data: IconThemeData(color: ink),
        child: corner,
      ),
    );
  }
}

/// Places the corner state over the tile, limited to 62% of its width.
class _TileWithCorner extends StatelessWidget {
  const _TileWithCorner({
    required this.surface,
    required this.corner,
    required this.top,
  });

  final Widget surface;
  final Widget corner;
  final double top;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth * 0.62
            : double.infinity;
        // passthrough: the tile keeps the size its slot gives it; the
        // corner never shrinks it to the label's width.
        return Stack(
          fit: StackFit.passthrough,
          children: [
            surface,
            PositionedDirectional(
              top: top,
              end: 13,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: corner,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Ink handed by a tile to its [AppTileEstado].
class AppTileEstadoTheme extends InheritedWidget {
  const AppTileEstadoTheme({
    super.key,
    required this.onInk,
    required this.offInk,
    required this.shadowed,
    required super.child,
  });

  final Color onInk;
  final Color offInk;
  final bool shadowed;

  static AppTileEstadoTheme? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTileEstadoTheme>();

  @override
  bool updateShouldNotify(AppTileEstadoTheme old) =>
      old.onInk != onInk || old.offInk != offInk || old.shadowed != shadowed;
}

/// The word in the tile corner (`.menu .state`).
///
/// The default form is the lit word (Fraunces 700 19px, D-44 A1–A3); the
/// [AppTileEstado.off] form is the quiet capitals (Inter 700 10.5px).
class AppTileEstado extends StatelessWidget {
  const AppTileEstado(this.text, {super.key, this.dotColor}) : off = false;

  const AppTileEstado.off(this.text, {super.key}) : off = true, dotColor = null;

  final String text;
  final bool off;

  /// Optional player dot before the word (`.state .dotp`).
  final Color? dotColor;

  static bool isOff(Widget widget) => widget is AppTileEstado && widget.off;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final theme = AppTileEstadoTheme.maybeOf(context);
    final style = off
        ? tokens.typography.stateOff.copyWith(
            color: theme?.offInk ?? tokens.palette.mistDim,
          )
        : tokens.typography.stateOn.copyWith(
            color: theme?.onInk ?? tokens.palette.ivory,
            shadows: (theme?.shadowed ?? true)
                ? [
                    Shadow(
                      color: tokens.palette.stateShadow,
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ]
                : null,
          );
    final word = Text(
      off ? text.toUpperCase() : text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: style,
    );
    if (dotColor == null) return word;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: tokens.palette.ivory.withValues(alpha: 0.85),
                spreadRadius: 1.5,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.space5),
        Flexible(child: word),
      ],
    );
  }
}

/// Context handed by an [AppTileBoard] to its tiles (A8: inside a veiled
/// board the quiet state uses `--bt-nevoa`, not `--bt-nevoa-fraca`).
class BtBoardScope extends InheritedWidget {
  const BtBoardScope({super.key, required this.veiled, required super.child});

  final bool veiled;

  static bool veiledOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BtBoardScope>()?.veiled ??
      false;

  @override
  bool updateShouldNotify(BtBoardScope old) => old.veiled != veiled;
}

/// The owner of two-tap arming for one screen (§4.1c).
///
/// Holds a single armed key, disarms it after [timeout] (`ARM_MS = 6000` in
/// the ruler) and disarms the previous piece when another one arms. Pieces
/// stay stateless and read the scope.
class BtArmedScope extends StatefulWidget {
  const BtArmedScope({super.key, required this.child, this.timeout});

  final Widget child;

  /// Defaults to [BtMetrics.armTimeout] (6 s).
  final Duration? timeout;

  static BtArmedController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_BtArmedInherited>()
      ?.controller;

  @override
  State<BtArmedScope> createState() => _BtArmedScopeState();
}

/// What a piece can ask of its [BtArmedScope].
abstract interface class BtArmedController {
  Object? get armedKey;
  bool isArmed(Object key);
  void arm(Object key);
  void disarm();
}

class _BtArmedScopeState extends State<BtArmedScope>
    implements BtArmedController {
  Object? _armedKey;
  Timer? _timer;

  @override
  Object? get armedKey => _armedKey;

  @override
  bool isArmed(Object key) => _armedKey == key;

  @override
  void arm(Object key) {
    _timer?.cancel();
    setState(() => _armedKey = key);
    _timer = Timer(
      widget.timeout ?? BtTokens.of(context).metrics.armTimeout,
      disarm,
    );
  }

  @override
  void disarm() {
    _timer?.cancel();
    _timer = null;
    if (mounted && _armedKey != null) setState(() => _armedKey = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _BtArmedInherited(
    controller: this,
    armedKey: _armedKey,
    child: widget.child,
  );
}

class _BtArmedInherited extends InheritedWidget {
  const _BtArmedInherited({
    required this.controller,
    required this.armedKey,
    required super.child,
  });

  final BtArmedController controller;
  final Object? armedKey;

  @override
  bool updateShouldNotify(_BtArmedInherited old) => old.armedKey != armedKey;
}

/// Resolves the tap of a piece that may need two taps.
abstract final class BtArming {
  /// Returns the handler for one tap, or null when the piece is disabled.
  static VoidCallback? resolve({
    required BtArmedController? scope,
    required Object id,
    required bool armed,
    required VoidCallback? onTap,
    required VoidCallback? onArmedConfirm,
  }) {
    if (armed) {
      if (onArmedConfirm == null) return onTap;
      return () {
        scope?.disarm();
        onArmedConfirm();
      };
    }
    if (onArmedConfirm != null && scope != null) {
      return () {
        onTap?.call();
        scope.arm(id);
      };
    }
    return onTap;
  }
}
