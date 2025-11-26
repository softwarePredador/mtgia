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
    // Remove chaves se houver
    symbol = symbol.replaceAll('{', '').replaceAll('}', '');
    
    // Números genéricos: "1", "2", "10"
    final number = int.tryParse(symbol);
    if (number != null) return number;
    
    // X é 0 no CMC
    if (symbol == 'X') return 0;
    
    // Híbridos: "2/W", "U/R", "G/P"
    if (symbol.contains('/')) {
      final parts = symbol.split('/');
      // Se for "2/W", o CMC é 2
      if (parts[0] == '2') return 2;
      // Outros híbridos (W/U, G/P) são 1
      return 1;
    }
    
    // Símbolos coloridos (W, U, B, R, G, C, S) contam como 1
    return 1;
  }

  static Map<String, int> countColorPips(String? manaCost) {
    final counts = <String, int>{'W': 0, 'U': 0, 'B': 0, 'R': 0, 'G': 0, 'C': 0};
    if (manaCost == null || manaCost.isEmpty) return counts;

    final regex = RegExp(r'\{([^\}]+)\}');
    final matches = regex.allMatches(manaCost);

    for (final match in matches) {
      final symbol = match.group(1) ?? '';
      final clean = symbol.replaceAll('{', '').replaceAll('}', '');
      
      if (clean.contains('/')) {
        // Híbridos (ex: W/U) contam para ambas as cores
        final parts = clean.split('/');
        for (final part in parts) {
           // Ignora números em híbridos (ex: 2/W -> conta só W)
           if (int.tryParse(part) == null && counts.containsKey(part)) {
             counts[part] = counts[part]! + 1;
           }
        }
      } else {
        if (counts.containsKey(clean)) {
          counts[clean] = counts[clean]! + 1;
        }
      }
    }
    return counts;
  }
}
