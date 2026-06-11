class OptimizePostValidationSummary {
  final List<String> warnings;
  final List<String> improvements;

  const OptimizePostValidationSummary({
    required this.warnings,
    required this.improvements,
  });
}

String? buildColorIdentityValidationWarning(
    List<String> filteredByColorIdentity) {
  if (filteredByColorIdentity.isEmpty) return null;
  final sample = filteredByColorIdentity.take(3).join(', ');
  final suffix = filteredByColorIdentity.length > 3 ? '...' : '';
  return '⚠️ ${filteredByColorIdentity.length} carta(s) sugerida(s) pela IA foram removidas por violar a identidade de cor do commander: $sample$suffix';
}

List<String> buildEdhrecValidationWarnings({
  required String commanderName,
  required List<String> validAdditions,
  required List<String> additionsNotInEdhrec,
}) {
  if (validAdditions.isEmpty || additionsNotInEdhrec.isEmpty) {
    return const [];
  }

  final percent = (additionsNotInEdhrec.length / validAdditions.length * 100)
      .toStringAsFixed(0);
  final sample = additionsNotInEdhrec.take(3).join(', ');
  final suffix = additionsNotInEdhrec.length > 3 ? '...' : '';

  if (additionsNotInEdhrec.length > validAdditions.length * 0.5) {
    return [
      '⚠️ ${additionsNotInEdhrec.length} ($percent%) das cartas sugeridas NÃO aparecem nos dados EDHREC de $commanderName. Isso pode indicar baixa sinergia: $sample$suffix',
    ];
  }

  if (additionsNotInEdhrec.length >= 3) {
    return [
      '💡 ${additionsNotInEdhrec.length} carta(s) sugerida(s) não estão nos dados EDHREC - podem ser inovadoras ou de baixa sinergia.',
    ];
  }

  return const [];
}

String? buildThemeMismatchWarning({
  required String targetArchetype,
  required List<String> edhrecThemes,
}) {
  if (edhrecThemes.isEmpty) return null;

  final detectedThemeLower = targetArchetype.toLowerCase();
  final hasThemeMatch = edhrecThemes.any((theme) {
    final edhrecTheme = theme.toLowerCase();
    return detectedThemeLower.contains(edhrecTheme) ||
        edhrecTheme.contains(detectedThemeLower);
  });

  if (hasThemeMatch) return null;

  return '💡 Tema detectado "$targetArchetype" não corresponde aos temas populares do EDHREC (${edhrecThemes.take(3).join(", ")}). O sistema está usando abordagem HÍBRIDA: 70% cartas EDHREC + 30% cartas do seu tema para respeitar sua ideia.';
}

OptimizePostValidationSummary buildPostAnalysisValidationSummary({
  required Map<String, dynamic> deckAnalysis,
  required Map<String, dynamic> postAnalysis,
  required String effectiveOptimizeArchetype,
}) {
  final warnings = <String>[];
  final improvements = <String>[];

  final preManaAssessment =
      deckAnalysis['mana_base_assessment'] as String? ?? '';
  final postManaAssessment =
      postAnalysis['mana_base_assessment'] as String? ?? '';
  final preManaIssues = preManaAssessment.contains('Falta mana');
  final postManaIssues = postManaAssessment.contains('Falta mana');

  if (!preManaIssues && postManaIssues) {
    warnings.add(
      '⚠️ ATENÇÃO: As sugestões da IA podem piorar sua base de mana.',
    );
  }

  final preAvgCmc = deckAnalysis['average_cmc'] as String? ?? '0';
  final postAvgCmc = postAnalysis['average_cmc'] as String? ?? '0';
  final preCurve = double.tryParse(preAvgCmc) ?? 0.0;
  final postCurve = double.tryParse(postAvgCmc) ?? 0.0;
  final archetype = effectiveOptimizeArchetype.toLowerCase();

  if (archetype == 'aggro' && postCurve > preCurve) {
    warnings.add(
      '⚠️ ATENÇÃO: O deck está ficando mais lento (CMC aumentou), o que é ruim para Aggro.',
    );
  }

  final preTypes =
      deckAnalysis['type_distribution'] as Map<String, dynamic>? ?? {};
  final postTypes =
      postAnalysis['type_distribution'] as Map<String, dynamic>? ?? {};

  final preLands = (preTypes['lands'] as int?) ?? 0;
  final postLands = (postTypes['lands'] as int?) ?? 0;
  if (postLands < preLands - 3) {
    warnings.add(
      '⚠️ A otimização removeu muitos terrenos ($preLands → $postLands). Isso pode causar problemas de mana.',
    );
  }

  if (archetype == 'control' && postCurve < preCurve - 0.5) {
    warnings.add(
      '💡 O CMC médio diminuiu significativamente ($preAvgCmc → $postAvgCmc). Para Control, isso pode remover respostas de custo alto que são importantes.',
    );
  }

  if (postCurve < preCurve && archetype != 'control') {
    improvements.add('CMC médio otimizado: $preAvgCmc → $postAvgCmc');
  }
  if (preManaIssues && !postManaIssues) {
    improvements.add('Base de mana corrigida');
  }
  if ((postTypes['instants'] as int? ?? 0) >
      (preTypes['instants'] as int? ?? 0)) {
    improvements.add('Mais interação instant-speed adicionada');
  }

  return OptimizePostValidationSummary(
    warnings: warnings,
    improvements: improvements,
  );
}
