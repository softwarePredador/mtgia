import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Original ManaLoom glyphs for product-level concepts.
///
/// The artwork is intentionally brand-inspired rather than derived from Magic
/// set symbols, mana symbols, or other third-party marks.
enum ManaLoomGlyphKind {
  brand,
  deck,
  collection,
  lifeCounter,
  commander,
  battleReplay,
  trade,
  shuffle,
}

extension ManaLoomGlyphKindAsset on ManaLoomGlyphKind {
  String get assetPath => switch (this) {
    ManaLoomGlyphKind.brand => 'assets/icons/brand.svg',
    ManaLoomGlyphKind.deck => 'assets/icons/deck.svg',
    ManaLoomGlyphKind.collection => 'assets/icons/collection.svg',
    ManaLoomGlyphKind.lifeCounter => 'assets/icons/life_counter.svg',
    ManaLoomGlyphKind.commander => 'assets/icons/commander.svg',
    ManaLoomGlyphKind.battleReplay => 'assets/icons/battle_replay.svg',
    ManaLoomGlyphKind.trade => 'assets/icons/trade.svg',
    ManaLoomGlyphKind.shuffle => 'assets/icons/shuffle.svg',
  };
}

/// Renders an original ManaLoom product glyph using the surrounding [IconTheme].
///
/// Pass [semanticLabel] when the glyph communicates meaning on its own. Leave
/// it null when adjacent text already names the action, so assistive technology
/// does not announce the same label twice.
class ManaLoomGlyph extends StatelessWidget {
  const ManaLoomGlyph(
    this.kind, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final ManaLoomGlyphKind kind;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final resolvedColor = color ?? iconTheme.color;
    final opacity = iconTheme.opacity;
    final effectiveColor = resolvedColor != null && opacity != null
        ? resolvedColor.withValues(alpha: resolvedColor.a * opacity)
        : resolvedColor;

    final glyph = SvgPicture.asset(
      kind.assetPath,
      width: resolvedSize,
      height: resolvedSize,
      fit: BoxFit.contain,
      colorFilter: effectiveColor == null
          ? null
          : ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      excludeFromSemantics: true,
    );

    final label = semanticLabel?.trim();
    if (label == null || label.isEmpty) {
      return ExcludeSemantics(child: glyph);
    }

    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: glyph,
    );
  }
}
