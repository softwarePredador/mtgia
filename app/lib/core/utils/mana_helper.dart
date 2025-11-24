class ManaHelper {
  /// Calcula o Custo de Mana Convertido (CMC) a partir de uma string de custo.
  /// Ex: "{2}{U}{U}" -> 4
  /// Ex: "{X}{R}" -> 1 (X é 0)
  /// Ex: "{2/W}" -> 2
  static int calculateCMC(String? manaCost) {
    if (manaCost == null || manaCost.isEmpty) return 0;

    int cmc = 0;
    // Regex para capturar símbolos entre chaves: {2}, {U}, {2/W}, {X}
    final regex = RegExp(r'\{([^\}]+)\}');
    final matches = regex.allMatches(manaCost);

    for (final match in matches) {
      final symbol = match.group(1) ?? '';
      cmc += _parseSymbolValue(symbol);
    }

    return cmc;
  }

  static int _parseSymbolValue(String symbol) {
    // X, Y, Z contam como 0
    if (['X', 'Y', 'Z'].contains(symbol)) return 0;

    // Números simples: {1}, {10}
    final number = int.tryParse(symbol);
    if (number != null) return number;

    // Híbridos: {2/W}, {U/B}, {G/P} (Phyrexian)
    if (symbol.contains('/')) {
      final parts = symbol.split('/');
      // Se uma das partes for número, é o valor (ex: {2/W} -> 2)
      final part1Num = int.tryParse(parts[0]);
      if (part1Num != null) return part1Num;
      
      // Se for cor/cor (ex: {U/B}), conta como 1
      return 1;
    }

    // Símbolos de cor simples ou Phyrexian ({U}, {P}) contam como 1
    // Snow {S} conta como 1
    return 1;
  }

  /// Conta a devoção (número de símbolos de cada cor)
  static Map<String, int> countColorPips(String? manaCost) {
    final counts = <String, int>{
      'W': 0, 'U': 0, 'B': 0, 'R': 0, 'G': 0, 'C': 0
    };

    if (manaCost == null || manaCost.isEmpty) return counts;

    final regex = RegExp(r'\{([^\}]+)\}');
    final matches = regex.allMatches(manaCost);

    for (final match in matches) {
      final symbol = match.group(1) ?? '';
      
      // Híbridos contam para ambas as cores? 
      // Para devoção, {U/B} conta como 1 U e 1 B.
      // {2/W} conta como 1 W.
      
      if (symbol.contains('/')) {
        final parts = symbol.split('/');
        for (var part in parts) {
          if (_isColorSymbol(part)) {
            counts[part] = (counts[part] ?? 0) + 1;
          }
        }
      } else {
        if (_isColorSymbol(symbol)) {
          counts[symbol] = (counts[symbol] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  static bool _isColorSymbol(String s) {
    return ['W', 'U', 'B', 'R', 'G', 'C'].contains(s);
  }
}
