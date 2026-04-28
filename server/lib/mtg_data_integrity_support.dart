import 'color_identity.dart';

const Map<String, String> basicLandSubtypeColorIdentity = {
  'plains': 'W',
  'island': 'U',
  'swamp': 'B',
  'mountain': 'R',
  'forest': 'G',
};

class ColorIdentityBackfillDecision {
  const ColorIdentityBackfillDecision({
    required this.deterministic,
    required this.identity,
    required this.sources,
    required this.reason,
  });

  final bool deterministic;
  final List<String> identity;
  final List<String> sources;
  final String reason;

  Map<String, dynamic> toJson() => {
        'deterministic': deterministic,
        'identity': identity,
        'sources': sources,
        'reason': reason,
      };
}

ColorIdentityBackfillDecision decideColorIdentityBackfill({
  required bool colorsKnown,
  Iterable<String> colors = const <String>[],
  String? manaCost,
  String? oracleText,
  String? typeLine,
}) {
  final resolved = <String>{};
  final sources = <String>[];

  final colorSymbols = normalizeColorIdentity(colors);
  if (colorSymbols.isNotEmpty) {
    resolved.addAll(colorSymbols);
    sources.add('colors');
  }

  final manaSymbols = extractColorIdentityFromText(manaCost);
  if (manaSymbols.isNotEmpty) {
    resolved.addAll(manaSymbols);
    sources.add('mana_cost');
  }

  final oracleSymbols = extractColorIdentityFromText(oracleText);
  if (oracleSymbols.isNotEmpty) {
    resolved.addAll(oracleSymbols);
    sources.add('oracle_text');
  }

  final landTypeSymbols = extractColorIdentityFromTypeLine(typeLine);
  if (landTypeSymbols.isNotEmpty) {
    resolved.addAll(landTypeSymbols);
    sources.add('type_line_land_subtype');
  }

  final identity = _orderedColorIdentity(resolved);
  if (identity.isNotEmpty) {
    return ColorIdentityBackfillDecision(
      deterministic: true,
      identity: identity,
      sources: sources,
      reason: 'identity_symbols_found',
    );
  }

  if (colorsKnown) {
    return const ColorIdentityBackfillDecision(
      deterministic: true,
      identity: <String>[],
      sources: <String>['colors'],
      reason: 'explicit_empty_colors_without_identity_symbols',
    );
  }

  return const ColorIdentityBackfillDecision(
    deterministic: false,
    identity: <String>[],
    sources: <String>[],
    reason: 'colors_missing_and_no_identity_symbols',
  );
}

Set<String> extractColorIdentityFromTypeLine(String? typeLine) {
  if (typeLine == null || typeLine.trim().isEmpty) return <String>{};
  final normalized = typeLine.toLowerCase();
  final identity = <String>{};

  for (final entry in basicLandSubtypeColorIdentity.entries) {
    if (RegExp('\\b${entry.key}\\b').hasMatch(normalized)) {
      identity.add(entry.value);
    }
  }

  return identity;
}

String? normalizeMtgSetCode(String? value) {
  final code = value?.trim();
  if (code == null || code.isEmpty) return null;
  return code.toUpperCase();
}

List<String> _orderedColorIdentity(Set<String> identity) {
  const order = ['W', 'U', 'B', 'R', 'G'];
  return order.where(identity.contains).toList(growable: false);
}
