Set<String> normalizeColorIdentity(Iterable<String> identity) {
  final normalized = <String>{};
  final allowed = {'W', 'U', 'B', 'R', 'G'};

  for (final raw in identity) {
    final value = raw.toUpperCase().trim();
    if (value.isEmpty) continue;

    final matches = RegExp(r'[WUBRG]').allMatches(value);
    for (final match in matches) {
      final symbol = match.group(0);
      if (symbol != null && allowed.contains(symbol)) {
        normalized.add(symbol);
      }
    }
  }

  return normalized;
}

Set<String> extractColorIdentityFromText(String? text) {
  if (text == null || text.trim().isEmpty) return <String>{};
  final sanitized = _removeParentheticalText(text);
  final symbols =
      RegExp(
        r'\{([^}]+)\}',
      ).allMatches(sanitized).map((match) => match.group(1) ?? '').toList();
  return normalizeColorIdentity(symbols);
}

Set<String> resolveCardColorIdentity({
  Iterable<String>? colorIdentity,
  Iterable<String> colors = const <String>[],
  String? oracleText,
  String? manaCost,
}) {
  if (colorIdentity != null) {
    return normalizeColorIdentity(colorIdentity);
  }

  final fallbackIdentity = <String>{};
  fallbackIdentity.addAll(normalizeColorIdentity(colors));
  fallbackIdentity.addAll(extractColorIdentityFromText(manaCost));
  fallbackIdentity.addAll(extractColorIdentityFromText(oracleText));
  return fallbackIdentity;
}

/// Remove reminder text, inclusive blocos que ocupam a linha inteira e
/// parênteses aninhados. Símbolos de mana em reminder text não compõem a
/// identidade de cor de uma carta.
String _removeParentheticalText(String text) {
  final sanitized = StringBuffer();
  var depth = 0;

  for (final rune in text.runes) {
    if (rune == 0x28) {
      depth++;
      continue;
    }
    if (rune == 0x29 && depth > 0) {
      depth--;
      continue;
    }
    if (depth == 0) sanitized.writeCharCode(rune);
  }

  return sanitized.toString();
}

/// Retorna `true` quando a identidade de cor da carta é um subconjunto da
/// identidade do comandante. Cartas incolores (identidade vazia) sempre passam.
bool isWithinCommanderIdentity({
  required Iterable<String> cardIdentity,
  required Set<String> commanderIdentity,
}) {
  final normalizedCard = normalizeColorIdentity(cardIdentity);
  if (normalizedCard.isEmpty) return true;
  return normalizedCard.every(commanderIdentity.contains);
}
