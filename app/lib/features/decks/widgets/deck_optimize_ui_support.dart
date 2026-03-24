import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/deck_provider_support.dart';

List<String> extractDeckAiReasons(DeckAiFlowException error) {
  final reasons = <String>{};

  final qualityReasons = error.qualityError['reasons'];
  if (qualityReasons is List) {
    for (final reason in qualityReasons) {
      final normalized = reason.toString().trim();
      if (normalized.isNotEmpty) reasons.add(normalized);
    }
  }

  final deckStateReasons = error.deckState['reasons'];
  if (deckStateReasons is List) {
    for (final reason in deckStateReasons) {
      final normalized = reason.toString().trim();
      if (normalized.isNotEmpty) reasons.add(normalized);
    }
  }

  return reasons.toList(growable: false);
}

class FlowProgressState {
  final String stage;
  final int stageNumber;
  final int totalStages;

  const FlowProgressState({
    required this.stage,
    required this.stageNumber,
    required this.totalStages,
  });
}

class FlowLoadingPresentation {
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final double? progress;
  final int? stepNumber;
  final int? totalSteps;
  final List<String> tips;

  const FlowLoadingPresentation({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    this.progress,
    this.stepNumber,
    this.totalSteps,
    this.tips = const [],
  });
}

FlowLoadingPresentation describeOptimizeProgress(FlowProgressState state) {
  final normalized = state.stage.trim().toLowerCase();

  if (normalized.contains('preparando análise do deck') ||
      normalized.contains('iniciando otimização')) {
    return const FlowLoadingPresentation(
      title: 'Preparando análise do deck',
      subtitle: 'Lendo comandante, identidade de cor e estado atual da lista.',
      accent: AppTheme.manaViolet,
      icon: Icons.auto_awesome_rounded,
      stepNumber: 1,
      totalSteps: 5,
      progress: 0.12,
      tips: [
        'O app prioriza sinergia com o comandante, não só cartas fortes isoladas.',
        'Se não houver upgrade seguro, é melhor preservar o deck do que piorá-lo.',
        'Em decks mais pesados essa etapa inicial pode levar um pouco mais.',
      ],
    );
  }

  if (normalized.contains('preparando referências do commander')) {
    return const FlowLoadingPresentation(
      title: 'Lendo referências do comandante',
      subtitle:
          'Cruza perfil do comandante, seeds do deck e prioridades conhecidas.',
      accent: AppTheme.primarySoft,
      icon: Icons.menu_book_rounded,
      stepNumber: 1,
      totalSteps: 5,
      progress: 0.18,
      tips: [
        'Aqui o sistema entende o plano natural do comandante antes de sugerir trocas.',
        'Commander bom não é só power: o plano da lista precisa continuar coerente.',
        'Essa base evita sugestões aleatórias que não conversam com o seu deck.',
      ],
    );
  }

  if (normalized.contains('consultando ia para sugestões')) {
    return const FlowLoadingPresentation(
      title: 'Consultando a IA para sugestões',
      subtitle:
          'Gerando shortlist de mudanças coerentes com o plano do deck.',
      accent: AppTheme.manaViolet,
      icon: Icons.psychology_alt_rounded,
      stepNumber: 2,
      totalSteps: 5,
      progress: 0.38,
      tips: [
        'Essa costuma ser uma das etapas mais demoradas.',
        'Nem toda staple entra: a IA tenta respeitar curva, tema e identidade.',
        'Quando o deck já está perto do pico, o sistema tende a ser mais conservador.',
      ],
    );
  }

  if (normalized.contains('preenchendo com cartas sinérgicas')) {
    return const FlowLoadingPresentation(
      title: 'Selecionando cartas mais sinérgicas',
      subtitle:
          'Montando trocas que reforçam o plano sem quebrar a estrutura da lista.',
      accent: AppTheme.success,
      icon: Icons.library_add_check_rounded,
      stepNumber: 3,
      totalSteps: 5,
      progress: 0.58,
      tips: [
        'Boas trocas melhoram o plano do deck sem desmontar peças importantes.',
        'Aqui o sistema evita duplicatas ruins e cartas fora da identidade de cor.',
        'Se o deck estiver muito quebrado, ele pode migrar para rebuild em vez de micro-ajuste.',
      ],
    );
  }

  if (normalized.contains('ajustando base de mana')) {
    return const FlowLoadingPresentation(
      title: 'Ajustando a base de mana',
      subtitle: 'Revisando consistência, curva e fontes de cor do deck.',
      accent: AppTheme.mythicGold,
      icon: Icons.water_drop_outlined,
      stepNumber: 4,
      totalSteps: 5,
      progress: 0.78,
      tips: [
        'Base de mana ruim derruba até lista com cartas fortes.',
        'Essa etapa reduz flood, screw e inconsistência de cores.',
        'Commander melhora muito quando mana e curva conversam com o plano.',
      ],
    );
  }

  if (normalized.contains('processando resultado final')) {
    return const FlowLoadingPresentation(
      title: 'Validando o resultado final',
      subtitle:
          'Organizando o preview e preparando só as mudanças que passaram no gate.',
      accent: AppTheme.success,
      icon: Icons.fact_check_outlined,
      stepNumber: 5,
      totalSteps: 5,
      progress: 0.94,
      tips: [
        'O preview só aparece depois da validação final das trocas.',
        'Se a melhora não for segura, o sistema prefere bloquear a sugestão.',
        'Falta pouco: estamos preparando a versão que você vai revisar.',
      ],
    );
  }

  final fallbackProgress =
      state.stageNumber > 0 && state.totalStages > 0
          ? (state.stageNumber / state.totalStages).clamp(0.1, 0.95)
          : null;

  return FlowLoadingPresentation(
    title: 'Processando otimização...',
    subtitle: state.stage,
    accent: AppTheme.manaViolet,
    icon: Icons.auto_awesome_rounded,
    progress: fallbackProgress,
    tips: const [
      'Estamos processando o deck no servidor.',
      'O objetivo é encontrar melhorias reais sem desmontar o plano da lista.',
      'Se não houver ganho seguro, o app prefere manter o deck intacto.',
    ],
  );
}
