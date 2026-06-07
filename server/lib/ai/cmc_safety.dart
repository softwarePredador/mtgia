bool isLikelyLandCard(Map<String, dynamic> card) {
  final typeLine = card['type_line']?.toString().toLowerCase() ?? '';
  return typeLine.contains('land');
}

int? parseManaCostCmc(String? manaCost) {
  final value = manaCost?.trim();
  if (value == null || value.isEmpty) return null;

  var total = 0;
  var sawSymbol = false;
  final matches = RegExp(r'\{([^}]+)\}').allMatches(value);
  for (final match in matches) {
    final symbol = match.group(1)?.trim().toUpperCase();
    if (symbol == null || symbol.isEmpty) continue;
    sawSymbol = true;

    final generic = int.tryParse(symbol);
    if (generic != null) {
      total += generic;
      continue;
    }

    if (symbol == 'X' || symbol == 'Y' || symbol == 'Z') {
      continue;
    }

    if (symbol.startsWith('2/')) {
      total += 2;
      continue;
    }

    if (symbol.contains('/')) {
      total += 1;
      continue;
    }

    total += 1;
  }

  return sawSymbol ? total : null;
}

int safeCmcForOptimization(
  Map<String, dynamic> card, {
  int unknownNonLandFallback = 99,
}) {
  if (isLikelyLandCard(card)) return 0;

  final parsedCmc = _parseRawCmc(card['cmc']);
  final manaCostCmc = parseManaCostCmc(card['mana_cost']?.toString());

  if (parsedCmc == null) {
    return manaCostCmc ?? unknownNonLandFallback;
  }

  if (parsedCmc == 0 && manaCostCmc != null && manaCostCmc > 0) {
    return manaCostCmc;
  }

  return parsedCmc;
}

bool hasSuspiciousNonLandCmc(Map<String, dynamic> card) {
  if (isLikelyLandCard(card)) return false;
  final parsedCmc = _parseRawCmc(card['cmc']);
  final manaCostCmc = parseManaCostCmc(card['mana_cost']?.toString());
  return parsedCmc == null ||
      (parsedCmc == 0 && manaCostCmc != null && manaCostCmc > 0);
}

int? _parseRawCmc(Object? rawCmc) {
  if (rawCmc == null) return null;
  if (rawCmc is int) return rawCmc.clamp(0, 999);
  if (rawCmc is double) return rawCmc.floor().clamp(0, 999);
  if (rawCmc is num) return rawCmc.floor().clamp(0, 999);
  final parsed = num.tryParse(rawCmc.toString().trim());
  if (parsed == null) return null;
  return parsed.floor().clamp(0, 999);
}
