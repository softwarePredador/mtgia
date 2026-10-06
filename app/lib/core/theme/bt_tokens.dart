import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// BrewTact kit tokens (BT-UX-KIT-001, docs/design/ui-kit-spec.md §3–§4).
///
/// The ruler is the life-counter prototype
/// (docs/design/life-counter-prototype/mesa-brewtact.html). This file never
/// declares a color literal (decision F1, D-44): every color is an [AppTheme]
/// value, at most with an alpha applied. What lives here is the composition
/// that a `ColorScheme` cannot hold — gradients, layered shadows, radii,
/// numeral scales and the type styles with explicit variable-font axes.
///
/// Read it with [BtTokens.of]; when the theme does not register the
/// extension the defaults built from [AppTheme] are returned instead of
/// throwing.
@immutable
class BtTokens extends ThemeExtension<BtTokens> {
  const BtTokens({
    required this.palette,
    required this.gradients,
    required this.shadows,
    required this.metrics,
    required this.typography,
  });

  /// The kit as the prototype draws it, composed from [AppTheme].
  factory BtTokens.fromAppTheme() {
    final palette = BtPalette.fromAppTheme();
    return BtTokens(
      palette: palette,
      gradients: BtGradients.fromAppTheme(),
      shadows: BtShadows.fromAppTheme(),
      metrics: const BtMetrics(),
      typography: BtType.fromAppTheme(),
    );
  }

  /// The instance registered in [AppTheme.darkTheme] and used as fallback.
  static final BtTokens standard = BtTokens.fromAppTheme();

  /// The kit tokens of the ambient theme, or [standard] when the theme has
  /// no [BtTokens] extension (never throws).
  static BtTokens of(BuildContext context) =>
      Theme.of(context).extension<BtTokens>() ?? standard;

  final BtPalette palette;
  final BtGradients gradients;
  final BtShadows shadows;
  final BtMetrics metrics;
  final BtType typography;

  /// The lit vitral of a tile or piece: `linear-gradient(158deg,
  /// mix(c, #fff, 10%) 0%, c 42%, c2 100%)` (`.menu .t.lit`). [deep]
  /// defaults to `mix(c, #000, 34%)`.
  Gradient vitral(Color c, {Color? deep, double middle = 0.42}) =>
      BtAngleGradient(
        angle: 158,
        colors: [
          Color.lerp(c, AppTheme.btLight, 0.10)!,
          c,
          deep ?? Color.lerp(c, AppTheme.btShade, 0.34)!,
        ],
        stops: [0, middle, 1],
      );

  /// Fraunces numeral style for [scale] (§4.2b), with `wght`, clamped
  /// `opsz`, WONK 1 / SOFT 0 and lining + tabular figures.
  TextStyle numeral(
    AppNumeralScale scale, {
    bool selected = false,
    double? fontSize,
  }) {
    final spec = BtNumeralSpec.of(scale);
    final size = fontSize ?? (selected ? spec.selectedSize : spec.size);
    return BtType.display(
      size,
      spec.weight,
      height: spec.height,
      tracking: spec.tracking,
      figures: true,
    ).copyWith(shadows: spec.shadows(palette));
  }

  @override
  BtTokens copyWith({
    BtPalette? palette,
    BtGradients? gradients,
    BtShadows? shadows,
    BtMetrics? metrics,
    BtType? typography,
  }) => BtTokens(
    palette: palette ?? this.palette,
    gradients: gradients ?? this.gradients,
    shadows: shadows ?? this.shadows,
    metrics: metrics ?? this.metrics,
    typography: typography ?? this.typography,
  );

  @override
  BtTokens lerp(covariant ThemeExtension<BtTokens>? other, double t) {
    if (other is! BtTokens) return this;
    return BtTokens(
      palette: BtPalette.lerp(palette, other.palette, t),
      gradients: BtGradients.lerp(gradients, other.gradients, t),
      shadows: BtShadows.lerp(shadows, other.shadows, t),
      metrics: BtMetrics.lerp(metrics, other.metrics, t),
      typography: BtType.lerp(typography, other.typography, t),
    );
  }
}

/// The numeral scales of §4.2b.
enum AppNumeralScale {
  azulejo,
  heroi,
  canto,
  peca,
  pecaNumeral,
  resultado,
  vivo,
  mesa,
  vazio,
}

/// Size, weight, leading and floor of one numeral scale (§4.2b, §4.2f).
@immutable
class BtNumeralSpec {
  const BtNumeralSpec({
    required this.size,
    required this.height,
    required this.minSize,
    double? selectedSize,
    this.weight = 700,
    this.tracking = -0.02,
    this.shadow = BtNumeralShadow.deep,
  }) : selectedSize = selectedSize ?? size;

  final double size;
  final double selectedSize;
  final double height;
  final double minSize;
  final double weight;
  final double tracking;
  final BtNumeralShadow shadow;

  static BtNumeralSpec of(AppNumeralScale scale) => switch (scale) {
    AppNumeralScale.azulejo => const BtNumeralSpec(
      size: 56,
      height: 0.8,
      minSize: 20,
    ),
    AppNumeralScale.heroi => const BtNumeralSpec(
      size: 70,
      height: 0.8,
      minSize: 24,
      shadow: BtNumeralShadow.light,
    ),
    AppNumeralScale.canto => const BtNumeralSpec(
      size: 32,
      height: 1,
      minSize: 16,
      shadow: BtNumeralShadow.none,
    ),
    AppNumeralScale.peca => const BtNumeralSpec(
      size: 38,
      selectedSize: 44,
      height: 0.85,
      minSize: 16,
      shadow: BtNumeralShadow.none,
    ),
    AppNumeralScale.pecaNumeral => const BtNumeralSpec(
      size: 36,
      selectedSize: 40,
      height: 1,
      minSize: 16,
      shadow: BtNumeralShadow.none,
    ),
    AppNumeralScale.resultado => const BtNumeralSpec(
      size: 92,
      height: 0.85,
      minSize: 24,
      tracking: -0.03,
      shadow: BtNumeralShadow.none,
    ),
    AppNumeralScale.vivo => const BtNumeralSpec(
      size: 64,
      height: 0.9,
      minSize: 24,
      tracking: -0.03,
      shadow: BtNumeralShadow.live,
    ),
    AppNumeralScale.mesa => const BtNumeralSpec(
      size: 120,
      height: 0.72,
      minSize: 28,
      weight: 600,
      tracking: -0.03,
      shadow: BtNumeralShadow.table,
    ),
    AppNumeralScale.vazio => const BtNumeralSpec(
      size: 44,
      height: 0.8,
      minSize: 16,
      shadow: BtNumeralShadow.none,
    ),
  };

  List<Shadow> shadows(BtPalette palette) => switch (shadow) {
    BtNumeralShadow.none => const <Shadow>[],
    BtNumeralShadow.deep => [
      Shadow(color: palette.shade35, offset: const Offset(0, 3), blurRadius: 8),
    ],
    BtNumeralShadow.light => [
      Shadow(color: palette.light35, offset: const Offset(0, 1)),
    ],
    BtNumeralShadow.live => [
      Shadow(color: palette.shade30, offset: const Offset(0, 3), blurRadius: 8),
    ],
    BtNumeralShadow.table => [
      Shadow(color: palette.shade18, offset: const Offset(0, 2)),
    ],
  };
}

enum BtNumeralShadow { none, deep, light, live, table }

/// Composed (translucent) colors of the kit. Every value is an [AppTheme]
/// color with an alpha; none is a new hue.
@immutable
class BtPalette {
  const BtPalette({
    required this.ivory,
    required this.mist,
    required this.mistDim,
    required this.obsidian,
    required this.slate850,
    required this.slate750,
    required this.brass,
    required this.brassLabel,
    required this.ember,
    required this.wine,
    required this.heart,
    required this.sublabel,
    required this.captionOnBrass,
    required this.heroDivider,
    required this.pipRing,
    required this.dash,
    required this.filete,
    required this.plaqueRest,
    required this.thread,
    required this.labelBar,
    required this.emptyNumeral,
    required this.thumbnail,
    required this.hintSurface,
    required this.numeralPieceSurface,
    required this.shade35,
    required this.shade30,
    required this.shade18,
    required this.light35,
    required this.stateShadow,
    required this.sweepSoft,
    required this.sweepPeak,
  });

  factory BtPalette.fromAppTheme() => BtPalette(
    ivory: AppTheme.textPrimary,
    mist: AppTheme.textSecondary,
    mistDim: AppTheme.textHint,
    obsidian: AppTheme.backgroundAbyss,
    slate850: AppTheme.surfaceElevated,
    slate750: AppTheme.outlineMuted,
    brass: AppTheme.brass400,
    brassLabel: AppTheme.btBrassLabel,
    ember: AppTheme.error,
    wine: AppTheme.btWine,
    heart: AppTheme.btHeart,
    sublabel: AppTheme.textPrimary.withValues(alpha: 0.72),
    captionOnBrass: AppTheme.backgroundAbyss.withValues(alpha: 0.7),
    heroDivider: AppTheme.backgroundAbyss.withValues(alpha: 0.18),
    pipRing: AppTheme.backgroundAbyss.withValues(alpha: 0.85),
    dash: AppTheme.brass400.withValues(alpha: 0.5),
    filete: AppTheme.textPrimary.withValues(alpha: 0.10),
    // D1 resolved in the prototype: the plaque wire at rest is .45 (4.09:1).
    plaqueRest: AppTheme.textPrimary.withValues(alpha: 0.45),
    thread: AppTheme.brass400.withValues(alpha: 0.30),
    labelBar: AppTheme.textPrimary.withValues(alpha: 0.10),
    emptyNumeral: AppTheme.brass400.withValues(alpha: 0.55),
    thumbnail: AppTheme.backgroundAbyss.withValues(alpha: 0.8),
    hintSurface: AppTheme.surfaceElevated.withValues(alpha: 0.6),
    numeralPieceSurface: AppTheme.surfaceElevated.withValues(alpha: 0.8),
    shade35: AppTheme.btShade.withValues(alpha: 0.35),
    shade30: AppTheme.btShade.withValues(alpha: 0.30),
    shade18: AppTheme.btShade.withValues(alpha: 0.18),
    light35: AppTheme.btLight.withValues(alpha: 0.35),
    stateShadow: AppTheme.backgroundAbyss.withValues(alpha: 0.5),
    sweepSoft: AppTheme.brass400.withValues(alpha: 0.20),
    sweepPeak: AppTheme.btBrassLight.withValues(alpha: 0.34),
  );

  final Color ivory;
  final Color mist;
  final Color mistDim;
  final Color obsidian;
  final Color slate850;
  final Color slate750;
  final Color brass;
  final Color brassLabel;
  final Color ember;
  final Color wine;
  final Color heart;
  final Color sublabel;
  final Color captionOnBrass;
  final Color heroDivider;
  final Color pipRing;
  final Color dash;
  final Color filete;
  final Color plaqueRest;
  final Color thread;
  final Color labelBar;
  final Color emptyNumeral;
  final Color thumbnail;
  final Color hintSurface;
  final Color numeralPieceSurface;
  final Color shade35;
  final Color shade30;
  final Color shade18;
  final Color light35;
  final Color stateShadow;
  final Color sweepSoft;
  final Color sweepPeak;

  List<Color> get _all => [
    ivory,
    mist,
    mistDim,
    obsidian,
    slate850,
    slate750,
    brass,
    brassLabel,
    ember,
    wine,
    heart,
    sublabel,
    captionOnBrass,
    heroDivider,
    pipRing,
    dash,
    filete,
    plaqueRest,
    thread,
    labelBar,
    emptyNumeral,
    thumbnail,
    hintSurface,
    numeralPieceSurface,
    shade35,
    shade30,
    shade18,
    light35,
    stateShadow,
    sweepSoft,
    sweepPeak,
  ];

  static BtPalette lerp(BtPalette a, BtPalette b, double t) {
    final x = a._all;
    final y = b._all;
    final c = [for (var i = 0; i < x.length; i++) Color.lerp(x[i], y[i], t)!];
    var i = 0;
    Color n() => c[i++];
    return BtPalette(
      ivory: n(),
      mist: n(),
      mistDim: n(),
      obsidian: n(),
      slate850: n(),
      slate750: n(),
      brass: n(),
      brassLabel: n(),
      ember: n(),
      wine: n(),
      heart: n(),
      sublabel: n(),
      captionOnBrass: n(),
      heroDivider: n(),
      pipRing: n(),
      dash: n(),
      filete: n(),
      plaqueRest: n(),
      thread: n(),
      labelBar: n(),
      emptyNumeral: n(),
      thumbnail: n(),
      hintSurface: n(),
      numeralPieceSurface: n(),
      shade35: n(),
      shade30: n(),
      shade18: n(),
      light35: n(),
      stateShadow: n(),
      sweepSoft: n(),
      sweepPeak: n(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BtPalette && _listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);
}

/// The kit gradients (§3.2).
@immutable
class BtGradients {
  const BtGradients({
    required this.glassTile,
    required this.glassPiece,
    required this.brass,
    required this.brassPiece,
    required this.free,
    required this.errorGlass,
    required this.wine,
    required this.sheen,
    required this.veilSheet,
    required this.veilMenu,
  });

  factory BtGradients.fromAppTheme() {
    final clear = AppTheme.btLight.withValues(alpha: 0);
    final clearShade = AppTheme.btShade.withValues(alpha: 0);
    return BtGradients(
      // `linear-gradient(160deg, rgba(41,48,65,.88), rgba(21,24,33,.95))`
      glassTile: BtAngleGradient(
        angle: 160,
        colors: [
          AppTheme.outlineMuted.withValues(alpha: 0.88),
          AppTheme.surfaceSlate.withValues(alpha: 0.95),
        ],
      ),
      glassPiece: BtAngleGradient(
        angle: 160,
        colors: [
          AppTheme.outlineMuted.withValues(alpha: 0.84),
          AppTheme.surfaceSlate.withValues(alpha: 0.94),
        ],
      ),
      brass: const BtAngleGradient(
        angle: 158,
        colors: [AppTheme.btBrassLight, AppTheme.brass400, AppTheme.brass500],
        stops: [0, 0.40, 1],
      ),
      brassPiece: const BtAngleGradient(
        angle: 158,
        colors: [AppTheme.btBrassLight, AppTheme.brass400, AppTheme.brass500],
        stops: [0, 0.42, 1],
      ),
      free: const BtAngleGradient(
        angle: 158,
        colors: [AppTheme.btFreeTop, AppTheme.btFreeBottom],
      ),
      errorGlass: BtAngleGradient(
        angle: 160,
        colors: [
          AppTheme.btErrorGlassTop.withValues(alpha: 0.88),
          AppTheme.btErrorGlassBottom.withValues(alpha: 0.95),
        ],
      ),
      // `.rt.bad.on`: mix(vinho 82%, #fff), vinho 45%, mix(vinho 70%, #000).
      wine: BtAngleGradient(
        angle: 158,
        colors: [
          Color.lerp(AppTheme.btWine, AppTheme.btLight, 0.18)!,
          AppTheme.btWine,
          Color.lerp(AppTheme.btWine, AppTheme.btShade, 0.30)!,
        ],
        stops: const [0, 0.45, 1],
      ),
      sheen: [
        BtAngleGradient(
          angle: 115,
          colors: [
            AppTheme.btLight.withValues(alpha: 0.13),
            AppTheme.btLight.withValues(alpha: 0.13),
            clear,
            clear,
          ],
          stops: const [0, 0.34, 0.342, 1],
        ),
        BtAngleGradient(
          angle: 200,
          colors: [
            clearShade,
            clearShade,
            AppTheme.btShade.withValues(alpha: 0.10),
            AppTheme.btShade.withValues(alpha: 0.10),
          ],
          stops: const [0, 0.72, 0.722, 1],
        ),
      ],
      veilSheet: BtEllipseGradient(
        center: const Alignment(0, -0.2),
        colors: [
          AppTheme.backgroundAbyss.withValues(alpha: 0.80),
          AppTheme.backgroundAbyss.withValues(alpha: 0.93),
        ],
      ),
      veilMenu: BtEllipseGradient(
        colors: [
          AppTheme.backgroundAbyss.withValues(alpha: 0.42),
          AppTheme.backgroundAbyss.withValues(alpha: 0.78),
        ],
      ),
    );
  }

  final Gradient glassTile;
  final Gradient glassPiece;
  final Gradient brass;
  final Gradient brassPiece;
  final Gradient free;
  final Gradient errorGlass;
  final Gradient wine;
  final List<Gradient> sheen;
  final Gradient veilSheet;
  final Gradient veilMenu;

  static BtGradients lerp(BtGradients a, BtGradients b, double t) {
    Gradient g(Gradient x, Gradient y) => Gradient.lerp(x, y, t)!;
    return BtGradients(
      glassTile: g(a.glassTile, b.glassTile),
      glassPiece: g(a.glassPiece, b.glassPiece),
      brass: g(a.brass, b.brass),
      brassPiece: g(a.brassPiece, b.brassPiece),
      free: g(a.free, b.free),
      errorGlass: g(a.errorGlass, b.errorGlass),
      wine: g(a.wine, b.wine),
      sheen: a.sheen.length == b.sheen.length
          ? [for (var i = 0; i < a.sheen.length; i++) g(a.sheen[i], b.sheen[i])]
          : (t < 0.5 ? a.sheen : b.sheen),
      veilSheet: g(a.veilSheet, b.veilSheet),
      veilMenu: g(a.veilMenu, b.veilMenu),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BtGradients &&
      other.glassTile == glassTile &&
      other.glassPiece == glassPiece &&
      other.brass == brass &&
      other.brassPiece == brassPiece &&
      other.free == free &&
      other.errorGlass == errorGlass &&
      other.wine == wine &&
      _listEquals(other.sheen, sheen) &&
      other.veilSheet == veilSheet &&
      other.veilMenu == veilMenu;

  @override
  int get hashCode => Object.hash(
    glassTile,
    glassPiece,
    brass,
    brassPiece,
    free,
    errorGlass,
    wine,
    Object.hashAll(sheen),
    veilSheet,
    veilMenu,
  );
}

/// One layer of a CSS `box-shadow`, outer or [inset].
@immutable
class BtShadow {
  const BtShadow({
    required this.color,
    this.offset = Offset.zero,
    this.blur = 0,
    this.spread = 0,
    this.inset = false,
  });

  final Color color;
  final Offset offset;
  final double blur;
  final double spread;
  final bool inset;

  BoxShadow toBoxShadow() => BoxShadow(
    color: color,
    offset: offset,
    blurRadius: blur,
    spreadRadius: spread,
  );

  static List<BtShadow> lerpList(List<BtShadow> a, List<BtShadow> b, double t) {
    if (a.length != b.length) return t < 0.5 ? a : b;
    return [
      for (var i = 0; i < a.length; i++)
        if (a[i].inset == b[i].inset)
          BtShadow(
            color: Color.lerp(a[i].color, b[i].color, t)!,
            offset: Offset.lerp(a[i].offset, b[i].offset, t)!,
            blur: ui.lerpDouble(a[i].blur, b[i].blur, t)!,
            spread: ui.lerpDouble(a[i].spread, b[i].spread, t)!,
            inset: a[i].inset,
          )
        else
          t < 0.5 ? a[i] : b[i],
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is BtShadow &&
      other.color == color &&
      other.offset == offset &&
      other.blur == blur &&
      other.spread == spread &&
      other.inset == inset;

  @override
  int get hashCode => Object.hash(color, offset, blur, spread, inset);
}

/// The kit shadows, in CSS order (first layer on top).
@immutable
class BtShadows {
  const BtShadows({
    required this.tile,
    required this.piece,
    required this.rule,
    required this.free,
    required this.lit,
    required this.brass,
    required this.selected,
    required this.armed,
    required this.armedEmber,
    required this.error,
    required this.x,
    required this.ruleOn,
    required this.ruleBadOn,
    required this.numeralPiece,
    required this.numeralPieceOn,
    required this.action,
    required this.heroGo,
    required this.headX,
  });

  factory BtShadows.fromAppTheme() {
    final ivory = AppTheme.textPrimary;
    final light = AppTheme.btLight;
    final shade = AppTheme.btShade;
    final obsidian = AppTheme.backgroundAbyss;
    final brass = AppTheme.brass400;
    final drop45 = BtShadow(
      color: shade.withValues(alpha: 0.45),
      offset: const Offset(0, 8),
      blur: 18,
    );
    final brassRingTop = BtShadow(
      color: light.withValues(alpha: 0.45),
      offset: const Offset(0, 1.5),
      inset: true,
    );
    return BtShadows(
      tile: [
        BtShadow(
          color: ivory.withValues(alpha: 0.10),
          spread: 1.5,
          inset: true,
        ),
        BtShadow(
          color: light.withValues(alpha: 0.10),
          offset: const Offset(0, 1.5),
          inset: true,
        ),
        drop45,
      ],
      // §3.2 trap 1: the piece ring is .09, not the tile's .10.
      piece: [
        BtShadow(
          color: ivory.withValues(alpha: 0.09),
          spread: 1.5,
          inset: true,
        ),
        BtShadow(
          color: light.withValues(alpha: 0.10),
          offset: const Offset(0, 1.5),
          inset: true,
        ),
        drop45,
      ],
      rule: [
        BtShadow(
          color: ivory.withValues(alpha: 0.09),
          spread: 1.5,
          inset: true,
        ),
        BtShadow(
          color: shade.withValues(alpha: 0.4),
          offset: const Offset(0, 8),
          blur: 18,
        ),
      ],
      // §3.2 trap 2: the free tile has no ivory ring, only the dash.
      free: [drop45],
      lit: [
        BtShadow(
          color: ivory.withValues(alpha: 0.17),
          spread: 1.5,
          inset: true,
        ),
        BtShadow(
          color: light.withValues(alpha: 0.30),
          offset: const Offset(0, 1.5),
          inset: true,
        ),
        BtShadow(
          color: shade.withValues(alpha: 0.16),
          offset: const Offset(0, -10),
          blur: 22,
          inset: true,
        ),
        BtShadow(
          color: shade.withValues(alpha: 0.5),
          offset: const Offset(0, 10),
          blur: 22,
        ),
        BtShadow(color: obsidian.withValues(alpha: 0.85), spread: 3),
      ],
      brass: [
        brassRingTop,
        BtShadow(
          color: shade.withValues(alpha: 0.5),
          offset: const Offset(0, 10),
          blur: 22,
        ),
        BtShadow(color: obsidian.withValues(alpha: 0.85), spread: 3),
      ],
      selected: [
        brassRingTop,
        BtShadow(color: obsidian, spread: 3),
        BtShadow(color: brass.withValues(alpha: 0.55), spread: 5),
        BtShadow(
          color: brass.withValues(alpha: 0.28),
          offset: const Offset(0, 12),
          blur: 30,
        ),
      ],
      armed: [
        BtShadow(color: brass, spread: 2, inset: true),
        BtShadow(color: obsidian, spread: 3),
        BtShadow(color: brass.withValues(alpha: 0.35), spread: 5),
      ],
      armedEmber: [
        const BtShadow(color: AppTheme.error, spread: 2, inset: true),
        drop45,
      ],
      error: [
        BtShadow(
          color: AppTheme.error.withValues(alpha: 0.34),
          spread: 1.5,
          inset: true,
        ),
        BtShadow(
          color: light.withValues(alpha: 0.08),
          offset: const Offset(0, 1.5),
          inset: true,
        ),
        drop45,
      ],
      x: [
        BtShadow(color: brass, spread: 2, inset: true),
        BtShadow(color: obsidian, spread: 7),
        BtShadow(color: brass.withValues(alpha: 0.28), spread: 8.5),
        BtShadow(
          color: shade.withValues(alpha: 0.7),
          offset: const Offset(0, 10),
          blur: 26,
        ),
      ],
      ruleOn: [
        brassRingTop,
        BtShadow(color: obsidian, spread: 3),
        BtShadow(color: brass.withValues(alpha: 0.45), spread: 5),
      ],
      ruleBadOn: [
        BtShadow(
          color: light.withValues(alpha: 0.26),
          offset: const Offset(0, 1.5),
          inset: true,
        ),
        BtShadow(color: obsidian, spread: 3),
        BtShadow(color: AppTheme.btWineRing.withValues(alpha: 0.5), spread: 5),
      ],
      numeralPiece: [
        BtShadow(
          color: ivory.withValues(alpha: 0.13),
          spread: 1.5,
          inset: true,
        ),
      ],
      numeralPieceOn: [
        brassRingTop,
        BtShadow(color: obsidian, spread: 3),
        BtShadow(color: brass.withValues(alpha: 0.55), spread: 5),
      ],
      action: [
        BtShadow(
          color: ivory.withValues(alpha: 0.10),
          spread: 1.5,
          inset: true,
        ),
        drop45,
      ],
      heroGo: [
        BtShadow(
          color: shade.withValues(alpha: 0.4),
          offset: const Offset(0, 6),
          blur: 14,
        ),
        BtShadow(color: brass.withValues(alpha: 0.55), spread: 2, inset: true),
      ],
      headX: [
        const BtShadow(color: AppTheme.outlineMuted, spread: 1, inset: true),
      ],
    );
  }

  final List<BtShadow> tile;
  final List<BtShadow> piece;
  final List<BtShadow> rule;
  final List<BtShadow> free;
  final List<BtShadow> lit;
  final List<BtShadow> brass;
  final List<BtShadow> selected;
  final List<BtShadow> armed;
  final List<BtShadow> armedEmber;
  final List<BtShadow> error;
  final List<BtShadow> x;
  final List<BtShadow> ruleOn;
  final List<BtShadow> ruleBadOn;
  final List<BtShadow> numeralPiece;
  final List<BtShadow> numeralPieceOn;
  final List<BtShadow> action;
  final List<BtShadow> heroGo;
  final List<BtShadow> headX;

  List<List<BtShadow>> get _all => [
    tile,
    piece,
    rule,
    free,
    lit,
    brass,
    selected,
    armed,
    armedEmber,
    error,
    x,
    ruleOn,
    ruleBadOn,
    numeralPiece,
    numeralPieceOn,
    action,
    heroGo,
    headX,
  ];

  static BtShadows lerp(BtShadows a, BtShadows b, double t) {
    final x = a._all;
    final y = b._all;
    final l = [
      for (var i = 0; i < x.length; i++) BtShadow.lerpList(x[i], y[i], t),
    ];
    var i = 0;
    List<BtShadow> n() => l[i++];
    return BtShadows(
      tile: n(),
      piece: n(),
      rule: n(),
      free: n(),
      lit: n(),
      brass: n(),
      selected: n(),
      armed: n(),
      armedEmber: n(),
      error: n(),
      x: n(),
      ruleOn: n(),
      ruleBadOn: n(),
      numeralPiece: n(),
      numeralPieceOn: n(),
      action: n(),
      heroGo: n(),
      headX: n(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! BtShadows) return false;
    final x = _all;
    final y = other._all;
    for (var i = 0; i < x.length; i++) {
      if (!_listEquals(x[i], y[i])) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_all.map(Object.hashAll));
}

/// Radii, paddings, columns, opacities and timings of the kit.
@immutable
class BtMetrics {
  const BtMetrics({
    this.radiusTile = AppTheme.radiusLifeCounterXl,
    this.radiusRule = AppTheme.radiusXl,
    this.radiusPanel = AppTheme.radiusLifeCounterLg,
    this.radiusHint = AppTheme.radiusLg,
    this.radiusMini = AppTheme.radiusMd,
    this.radiusMiniTile = AppTheme.radiusLifeCounterSm,
    this.radiusPill = AppTheme.radiusPill,
    this.radiusPad = AppTheme.radiusPad,
    // F6 (D-44): the footer action follows the ruler's `.btn`, radius 12.
    this.radiusAction = AppTheme.radiusMd,
    this.gapTable = AppTheme.space6,
    this.gapTile = AppTheme.space8,
    this.gapPiece = AppTheme.space10,
    this.columnContent = 560,
    this.columnTable = 780,
    this.disabledOpacity = 0.38,
    this.pressScale = 0.97,
    this.hoverScale = 1.012,
    this.blurSheet = 8,
    this.blurMenu = 3,
    this.backdropSaturation = 0.8,
    this.touchTarget = AppTheme.touchTargetMin,
    this.focusRingWidth = AppTheme.strokeStrong,
    this.focusRingGap = AppTheme.space2,
    this.dashWidth = AppTheme.strokeStrong,
    this.dashLength = AppTheme.space6,
    this.dashGap = AppTheme.space5,
    this.pressDuration = const Duration(milliseconds: 120),
    this.fadeDuration = const Duration(milliseconds: 160),
    this.sweepDuration = const Duration(milliseconds: 1350),
    this.armTimeout = const Duration(seconds: 6),
  });

  final double radiusTile;
  final double radiusRule;
  final double radiusPanel;
  final double radiusHint;
  final double radiusMini;
  final double radiusMiniTile;
  final double radiusPill;
  final double radiusPad;
  final double radiusAction;
  final double gapTable;
  final double gapTile;
  final double gapPiece;
  final double columnContent;
  final double columnTable;
  final double disabledOpacity;
  final double pressScale;
  final double hoverScale;
  final double blurSheet;
  final double blurMenu;
  final double backdropSaturation;
  final double touchTarget;
  final double focusRingWidth;
  final double focusRingGap;
  final double dashWidth;
  final double dashLength;
  final double dashGap;
  final Duration pressDuration;
  final Duration fadeDuration;
  final Duration sweepDuration;

  /// `ARM_MS = 6000` in mesa-brewtact.html: an armed piece disarms alone.
  final Duration armTimeout;

  /// `.menu .t { padding: 12px 14px 11px }`.
  EdgeInsetsDirectional get padTile => const EdgeInsetsDirectional.fromSTEB(
    AppTheme.space14,
    AppTheme.space12,
    AppTheme.space14,
    AppTheme.space11,
  );

  /// `.p { padding: 11px 12px 9px }`.
  EdgeInsetsDirectional get padPiece => const EdgeInsetsDirectional.fromSTEB(
    AppTheme.space12,
    AppTheme.space11,
    AppTheme.space12,
    AppTheme.space9,
  );

  /// `.rt { padding: 12px 14px }`.
  EdgeInsetsDirectional get padRule => const EdgeInsetsDirectional.fromSTEB(
    AppTheme.space14,
    AppTheme.space12,
    AppTheme.space14,
    AppTheme.space12,
  );

  List<double> get _all => [
    radiusTile,
    radiusRule,
    radiusPanel,
    radiusHint,
    radiusMini,
    radiusMiniTile,
    radiusPill,
    radiusPad,
    radiusAction,
    gapTable,
    gapTile,
    gapPiece,
    columnContent,
    columnTable,
    disabledOpacity,
    pressScale,
    hoverScale,
    blurSheet,
    blurMenu,
    backdropSaturation,
    touchTarget,
    focusRingWidth,
    focusRingGap,
    dashWidth,
    dashLength,
    dashGap,
  ];

  static BtMetrics lerp(BtMetrics a, BtMetrics b, double t) {
    final x = a._all;
    final y = b._all;
    final d = [
      for (var i = 0; i < x.length; i++) ui.lerpDouble(x[i], y[i], t)!,
    ];
    var i = 0;
    double n() => d[i++];
    final late = t < 0.5 ? a : b;
    return BtMetrics(
      radiusTile: n(),
      radiusRule: n(),
      radiusPanel: n(),
      radiusHint: n(),
      radiusMini: n(),
      radiusMiniTile: n(),
      radiusPill: n(),
      radiusPad: n(),
      radiusAction: n(),
      gapTable: n(),
      gapTile: n(),
      gapPiece: n(),
      columnContent: n(),
      columnTable: n(),
      disabledOpacity: n(),
      pressScale: n(),
      hoverScale: n(),
      blurSheet: n(),
      blurMenu: n(),
      backdropSaturation: n(),
      touchTarget: n(),
      focusRingWidth: n(),
      focusRingGap: n(),
      dashWidth: n(),
      dashLength: n(),
      dashGap: n(),
      pressDuration: late.pressDuration,
      fadeDuration: late.fadeDuration,
      sweepDuration: late.sweepDuration,
      armTimeout: late.armTimeout,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BtMetrics &&
      _listEquals(other._all, _all) &&
      other.pressDuration == pressDuration &&
      other.fadeDuration == fadeDuration &&
      other.sweepDuration == sweepDuration &&
      other.armTimeout == armTimeout;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(_all),
    pressDuration,
    fadeDuration,
    sweepDuration,
    armTimeout,
  );
}

/// Type styles of the kit (§4–§6). Colors are left to the piece that paints
/// them, because the ink depends on the surface (§4.1f).
@immutable
class BtType {
  const BtType({
    required this.label,
    required this.sublabel,
    required this.stateOn,
    required this.stateOff,
    required this.heroCaption,
    required this.heroName,
    required this.sheetTitle,
    required this.ruleTitle,
    required this.ruleState,
    required this.pieceCaption,
    required this.bandCaption,
    required this.action,
    required this.plaque,
    required this.plaqueSecret,
    required this.hint,
    required this.errorLine,
  });

  factory BtType.fromAppTheme() => BtType(
    label: ui(11.5, 800, height: 1.18, tracking: 0.085),
    sublabel: ui(11, 700, height: 1, tracking: 0.06),
    // A1–A3 (D-44): the corner state is 19px, so it counts as large text.
    stateOn: display(19, 700, height: 1),
    stateOff: ui(10.5, 700, height: 1, tracking: 0.1),
    heroCaption: ui(11, 700, height: 1, tracking: 0.06),
    heroName: display(30, 700, height: 1, tracking: -0.01),
    sheetTitle: display(22, 600, height: 1.15),
    ruleTitle: ui(14, 700, height: 1.2),
    ruleState: ui(11, 800, height: 1, tracking: 0.1),
    pieceCaption: ui(11, 700, height: 1, tracking: 0.08),
    bandCaption: ui(11, 800, height: 1, tracking: 0.12),
    action: ui(11.5, 800, height: 1.18, tracking: 0.085),
    plaque: display(22, 600, height: 1.2),
    plaqueSecret: ui(22, 600, height: 1.2, figures: true),
    hint: ui(12, 500, height: 1.4),
    errorLine: ui(12, 500, height: 1.4),
  );

  final TextStyle label;
  final TextStyle sublabel;
  final TextStyle stateOn;
  final TextStyle stateOff;
  final TextStyle heroCaption;
  final TextStyle heroName;
  final TextStyle sheetTitle;
  final TextStyle ruleTitle;
  final TextStyle ruleState;
  final TextStyle pieceCaption;
  final TextStyle bandCaption;
  final TextStyle action;
  final TextStyle plaque;
  final TextStyle plaqueSecret;
  final TextStyle hint;
  final TextStyle errorLine;

  /// Inter with explicit `wght` and `opsz` (clamped to the file's 14–32).
  ///
  /// The bundled Inter is a variable font registered without weight
  /// descriptors, so `fontWeight` alone does not move its axis (§4.2b).
  static TextStyle ui(
    double size,
    double weight, {
    double? height,
    double tracking = 0,
    bool figures = false,
  }) => TextStyle(
    fontFamily: AppTheme.uiFontFamily,
    fontSize: size,
    fontWeight: _weight(weight),
    height: height,
    letterSpacing: tracking * size,
    fontVariations: [
      FontVariation('wght', weight),
      FontVariation('opsz', size.clamp(14, 32).toDouble()),
    ],
    fontFeatures: figures
        ? const [FontFeature.liningFigures(), FontFeature.tabularFigures()]
        : null,
  );

  /// Fraunces with explicit `wght`, `opsz` = size (clamped to 9–144),
  /// `WONK` 1 and `SOFT` 0 (§4.2b).
  static TextStyle display(
    double size,
    double weight, {
    double? height,
    double tracking = 0,
    bool figures = false,
  }) => TextStyle(
    fontFamily: AppTheme.displayFontFamily,
    fontSize: size,
    fontWeight: _weight(weight),
    height: height,
    letterSpacing: tracking * size,
    fontVariations: [
      FontVariation('wght', weight),
      FontVariation('opsz', size.clamp(9, 144).toDouble()),
      const FontVariation('WONK', 1),
      const FontVariation('SOFT', 0),
    ],
    fontFeatures: figures
        ? const [FontFeature.liningFigures(), FontFeature.tabularFigures()]
        : null,
  );

  /// Re-applies the variable axes after a size change (opsz follows size).
  static TextStyle resize(TextStyle style, double size) {
    final variations = style.fontVariations;
    if (variations == null) return style.copyWith(fontSize: size);
    final isDisplay = style.fontFamily == AppTheme.displayFontFamily;
    final opsz = isDisplay ? size.clamp(9, 144) : size.clamp(14, 32);
    final scale = style.fontSize == null || style.fontSize == 0
        ? 1.0
        : size / style.fontSize!;
    return style.copyWith(
      fontSize: size,
      letterSpacing: style.letterSpacing == null
          ? null
          : style.letterSpacing! * scale,
      fontVariations: [
        for (final v in variations)
          v.axis == 'opsz' ? FontVariation('opsz', opsz.toDouble()) : v,
      ],
    );
  }

  static FontWeight _weight(double weight) =>
      FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)];

  List<TextStyle> get _all => [
    label,
    sublabel,
    stateOn,
    stateOff,
    heroCaption,
    heroName,
    sheetTitle,
    ruleTitle,
    ruleState,
    pieceCaption,
    bandCaption,
    action,
    plaque,
    plaqueSecret,
    hint,
    errorLine,
  ];

  static BtType lerp(BtType a, BtType b, double t) {
    final x = a._all;
    final y = b._all;
    final s = [
      for (var i = 0; i < x.length; i++) TextStyle.lerp(x[i], y[i], t)!,
    ];
    var i = 0;
    TextStyle n() => s[i++];
    return BtType(
      label: n(),
      sublabel: n(),
      stateOn: n(),
      stateOff: n(),
      heroCaption: n(),
      heroName: n(),
      sheetTitle: n(),
      ruleTitle: n(),
      ruleState: n(),
      pieceCaption: n(),
      bandCaption: n(),
      action: n(),
      plaque: n(),
      plaqueSecret: n(),
      hint: n(),
      errorLine: n(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BtType && _listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);
}

/// A CSS `linear-gradient(<angle>deg, …)`: the gradient line crosses the
/// box center at [angle] (0 = towards the top, clockwise) and its length is
/// `|w·sin a| + |h·cos a|`, so the stops land where the browser puts them on
/// any aspect ratio. In RTL the angle mirrors (158° → 202°).
@immutable
class BtAngleGradient extends Gradient {
  const BtAngleGradient({
    required this.angle,
    required super.colors,
    super.stops,
  });

  final double angle;

  List<double> _resolvedStops() {
    final s = stops;
    if (s != null) return s;
    if (colors.length == 1) return const [0];
    return [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)];
  }

  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final degrees = textDirection == TextDirection.rtl ? 360 - angle : angle;
    final radians = degrees * math.pi / 180;
    final direction = Offset(math.sin(radians), -math.cos(radians));
    final half =
        (rect.width * direction.dx.abs() + rect.height * direction.dy.abs()) /
        2;
    return ui.Gradient.linear(
      rect.center - direction * half,
      rect.center + direction * half,
      colors,
      _resolvedStops(),
    );
  }

  @override
  Gradient withOpacity(double opacity) => BtAngleGradient(
    angle: angle,
    colors: [for (final c in colors) c.withValues(alpha: c.a * opacity)],
    stops: stops,
  );

  @override
  Gradient scale(double factor) => BtAngleGradient(
    angle: angle,
    colors: [for (final c in colors) Color.lerp(null, c, factor)!],
    stops: stops,
  );

  @override
  Gradient? lerpFrom(Gradient? a, double t) {
    if (a is BtAngleGradient) return _lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  Gradient? lerpTo(Gradient? b, double t) {
    if (b is BtAngleGradient) return _lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  static Gradient? _lerp(BtAngleGradient a, BtAngleGradient b, double t) {
    if (a.colors.length != b.colors.length) return null;
    final sa = a._resolvedStops();
    final sb = b._resolvedStops();
    return BtAngleGradient(
      angle: ui.lerpDouble(a.angle, b.angle, t)!,
      colors: [
        for (var i = 0; i < a.colors.length; i++)
          Color.lerp(a.colors[i], b.colors[i], t)!,
      ],
      stops: [
        for (var i = 0; i < sa.length; i++) ui.lerpDouble(sa[i], sb[i], t)!,
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BtAngleGradient &&
      other.angle == angle &&
      _listEquals(other.colors, colors) &&
      _listEquals(other.stops ?? const [], stops ?? const []);

  @override
  int get hashCode =>
      Object.hash(angle, Object.hashAll(colors), Object.hashAll(stops ?? []));
}

/// A CSS `radial-gradient(ellipse at <center>, …)` with the default
/// `farthest-corner` size: an ellipse with the box's farthest-side aspect.
@immutable
class BtEllipseGradient extends Gradient {
  const BtEllipseGradient({
    this.center = Alignment.center,
    required super.colors,
    super.stops,
  });

  final Alignment center;

  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final c = center.withinRect(rect);
    final sideX = math.max(c.dx - rect.left, rect.right - c.dx);
    final sideY = math.max(c.dy - rect.top, rect.bottom - c.dy);
    final rx = math.max(sideX * math.sqrt2, 1.0);
    final ry = math.max(sideY * math.sqrt2, 1.0);
    final matrix = Matrix4.translationValues(c.dx, c.dy, 0)
      ..multiply(Matrix4.diagonal3Values(1, ry / rx, 1))
      ..multiply(Matrix4.translationValues(-c.dx, -c.dy, 0));
    return ui.Gradient.radial(
      c,
      rx,
      colors,
      stops ??
          [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)],
      TileMode.clamp,
      matrix.storage,
    );
  }

  @override
  Gradient withOpacity(double opacity) => BtEllipseGradient(
    center: center,
    colors: [for (final c in colors) c.withValues(alpha: c.a * opacity)],
    stops: stops,
  );

  @override
  Gradient scale(double factor) => BtEllipseGradient(
    center: center,
    colors: [for (final c in colors) Color.lerp(null, c, factor)!],
    stops: stops,
  );

  @override
  bool operator ==(Object other) =>
      other is BtEllipseGradient &&
      other.center == center &&
      _listEquals(other.colors, colors) &&
      _listEquals(other.stops ?? const [], stops ?? const []);

  @override
  int get hashCode =>
      Object.hash(center, Object.hashAll(colors), Object.hashAll(stops ?? []));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
