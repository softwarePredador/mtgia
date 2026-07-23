import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Canonical renderer for Magic mana and rules symbols.
///
/// Symbols are stored using Scryfall-style filenames in `assets/symbols/`.
/// Call sites may pass either raw values (`W/U`) or braced values (`{W/U}`).
class ManaSymbol extends StatelessWidget {
  const ManaSymbol({
    super.key,
    required this.symbol,
    this.size = 18,
    this.margin = EdgeInsets.zero,
  });

  final String symbol;
  final double size;
  final EdgeInsetsGeometry margin;

  static String normalize(String rawSymbol) {
    var normalized = rawSymbol.trim().toUpperCase();
    if (normalized.startsWith('{') && normalized.endsWith('}')) {
      normalized = normalized.substring(1, normalized.length - 1);
    }
    return normalized;
  }

  static String assetFilename(String rawSymbol) =>
      normalize(rawSymbol).replaceAll('/', '-');

  static String semanticLabel(String rawSymbol) {
    final symbol = normalize(rawSymbol);
    const names = <String, String>{
      'W': 'mana branca',
      'U': 'mana azul',
      'B': 'mana preta',
      'R': 'mana vermelha',
      'G': 'mana verde',
      'C': 'mana incolor',
      'S': 'mana de neve',
      'X': 'mana X',
      'Y': 'mana Y',
      'Z': 'mana Z',
      'T': 'virar',
      'Q': 'desvirar',
      'E': 'energia',
      'CHAOS': 'caos',
    };
    return names[symbol] ?? 'símbolo de mana $symbol';
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalize(symbol);
    if (normalized.isEmpty) return const SizedBox.shrink();

    return Semantics(
      image: true,
      label: semanticLabel(normalized),
      excludeSemantics: true,
      child: Padding(
        padding: margin,
        child: SizedBox.square(
          dimension: size,
          child: SvgPicture.asset(
            'assets/symbols/${assetFilename(normalized)}.svg',
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            placeholderBuilder: (_) =>
                FallbackManaSymbol(symbol: normalized, size: size),
            errorBuilder: (_, __, ___) =>
                FallbackManaSymbol(symbol: normalized, size: size),
          ),
        ),
      ),
    );
  }
}

class FallbackManaSymbol extends StatelessWidget {
  const FallbackManaSymbol({super.key, required this.symbol, this.size = 18});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = ManaSymbol.normalize(symbol);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.manaPipBackground(normalized),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.outlineMuted,
          width: AppTheme.strokeHairline,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        normalized,
        maxLines: 1,
        style: TextStyle(
          fontSize: size * 0.48,
          height: 1,
          fontWeight: FontWeight.w900,
          color: AppTheme.manaPipForeground(normalized),
        ),
      ),
    );
  }
}

class ManaCostRow extends StatelessWidget {
  const ManaCostRow({
    super.key,
    this.cost,
    this.symbolSize = 18,
    this.spacing = 2,
  });

  final String? cost;
  final double symbolSize;
  final double spacing;

  static List<String> parse(String? cost) {
    if (cost == null || cost.trim().isEmpty) return const [];
    return RegExp(
      r'\{([^\}]+)\}',
    ).allMatches(cost).map((match) => match.group(1)!).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final symbols = parse(cost);
    if (symbols.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final symbol in symbols)
          ManaSymbol(symbol: symbol, size: symbolSize),
      ],
    );
  }
}

class ColorIdentityPips extends StatelessWidget {
  const ColorIdentityPips({
    super.key,
    required this.colors,
    this.symbolSize = 18,
    this.spacing = 4,
    this.decorated = true,
    this.colorlessWhenEmpty = false,
  });

  final List<String> colors;
  final double symbolSize;
  final double spacing;
  final bool decorated;

  /// Only set this when an empty identity is known to mean colorless. A deck
  /// with incomplete metadata should render an explicit pending state instead.
  final bool colorlessWhenEmpty;

  static const _wubrgOrder = ['W', 'U', 'B', 'R', 'G'];

  static List<String> normalizeColors(
    Iterable<String> colors, {
    bool colorlessWhenEmpty = false,
  }) {
    final sorted =
        colors
            .map(ManaSymbol.normalize)
            .where(_wubrgOrder.contains)
            .toSet()
            .toList()
          ..sort(
            (a, b) => _wubrgOrder.indexOf(a).compareTo(_wubrgOrder.indexOf(b)),
          );
    if (sorted.isEmpty && colorlessWhenEmpty) return const ['C'];
    return sorted;
  }

  List<String> get _symbols =>
      normalizeColors(colors, colorlessWhenEmpty: colorlessWhenEmpty);

  @override
  Widget build(BuildContext context) {
    final symbols = _symbols;
    if (symbols.isEmpty) return const SizedBox.shrink();

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < symbols.length; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          ManaSymbol(symbol: symbols[index], size: symbolSize),
        ],
      ],
    );

    if (!decorated) return row;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: symbolSize <= AppTheme.space14
            ? AppTheme.space6
            : AppTheme.space7,
        vertical: symbolSize <= AppTheme.space14
            ? AppTheme.space4
            : AppTheme.space5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.82),
          width: AppTheme.strokeThin,
        ),
      ),
      child: row,
    );
  }
}

class OracleTextWidget extends StatelessWidget {
  const OracleTextWidget(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\{([^\}]+)\}');

    text.splitMapJoin(
      regex,
      onMatch: (match) {
        final symbol = match.group(1)!;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space1),
              child: ManaSymbol(symbol: symbol, size: 16),
            ),
          ),
        );
        return '';
      },
      onNonMatch: (text) {
        spans.add(TextSpan(text: text));
        return '';
      },
    );

    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        children: spans,
      ),
    );
  }
}
