import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'deck_optimize_sheet_widgets.dart';
import 'deck_ui_components.dart';

class OptimizationConfigSection extends StatelessWidget {
  final int selectedBracket;
  final bool keepTheme;
  final ValueChanged<int> onBracketChanged;
  final ValueChanged<bool> onKeepThemeChanged;
  final Color accent;

  const OptimizationConfigSection({
    super.key,
    required this.selectedBracket,
    required this.keepTheme,
    required this.onBracketChanged,
    required this.onKeepThemeChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DialogSectionCard(
      title: 'Configuração da otimização',
      accent: accent,
      icon: Icons.settings_suggest_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Bracket / Power level',
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedBracket,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 - Casual')),
                  DropdownMenuItem(value: 2, child: Text('2 - Mid')),
                  DropdownMenuItem(value: 3, child: Text('3 - High')),
                  DropdownMenuItem(value: 4, child: Text('4 - cEDH')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  onBracketChanged(v);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.outlineMuted.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 2,
              ),
              title: const Text('Manter tema do deck'),
              subtitle: const Text(
                'Evita trocar o plano principal e preserva cartas núcleo quando possível.',
              ),
              value: keepTheme,
              onChanged: onKeepThemeChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class CurrentStrategySection extends StatelessWidget {
  final String savedArchetype;
  final bool showAllStrategies;
  final VoidCallback onToggleVisibility;
  final VoidCallback onApply;

  const CurrentStrategySection({
    super.key,
    required this.savedArchetype,
    required this.showAllStrategies,
    required this.onToggleVisibility,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DialogSectionCard(
          title: 'Estratégia atual',
          accent: AppTheme.primarySoft,
          icon: Icons.auto_awesome_motion_rounded,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  savedArchetype,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onToggleVisibility,
                child: Text(
                  showAllStrategies ? 'Ocultar outras' : 'Ver outras',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onApply,
          icon: const Icon(Icons.check),
          label: const Text('Aplicar estratégia atual'),
        ),
      ],
    );
  }
}

class OptimizationOptionsSection extends StatelessWidget {
  final AsyncSnapshot<List<Map<String, dynamic>>> snapshot;
  final bool showAllStrategies;
  final Color accent;
  final VoidCallback onRetry;
  final ValueChanged<String> onSelectArchetype;

  const OptimizationOptionsSection({
    super.key,
    required this.snapshot,
    required this.showAllStrategies,
    required this.accent,
    required this.onRetry,
    required this.onSelectArchetype,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 12),
            Text('Analisando estratégias...'),
          ],
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text('Erro: ${snapshot.error}', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final options = snapshot.data ?? const <Map<String, dynamic>>[];
    final visibleOptions =
        showAllStrategies ? options : const <Map<String, dynamic>>[];

    if (visibleOptions.isEmpty) {
      return DialogSectionCard(
        title: 'Estratégias alternativas ocultas',
        accent: AppTheme.textSecondary,
        icon: Icons.visibility_off_outlined,
        child: const Text(
          'Você pode seguir com a estratégia atual ou exibir novamente as demais opções para comparar.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < visibleOptions.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final option = visibleOptions[index];
              final title = (option['title'] ?? 'Sem Título').toString();
              return StrategyOptionCard(
                title: title,
                description: (option['description'] ?? '').toString(),
                difficulty: option['difficulty']?.toString(),
                accent: accent,
                onTap: () {
                  if (title.isEmpty) return;
                  onSelectArchetype(title);
                },
              );
            },
          ),
        ],
      ],
    );
  }
}

class OptimizationSheetBody extends StatelessWidget {
  final String? savedArchetype;
  final int selectedBracket;
  final bool keepTheme;
  final bool showAllStrategies;
  final Future<List<Map<String, dynamic>>> optionsFuture;
  final ScrollController scrollController;
  final Color accent;
  final ValueChanged<int> onBracketChanged;
  final ValueChanged<bool> onKeepThemeChanged;
  final VoidCallback onToggleStrategyVisibility;
  final VoidCallback onRetryOptions;
  final ValueChanged<String> onApplyArchetype;

  const OptimizationSheetBody({
    super.key,
    required this.savedArchetype,
    required this.selectedBracket,
    required this.keepTheme,
    required this.showAllStrategies,
    required this.optionsFuture,
    required this.scrollController,
    required this.accent,
    required this.onBracketChanged,
    required this.onKeepThemeChanged,
    required this.onToggleStrategyVisibility,
    required this.onRetryOptions,
    required this.onApplyArchetype,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.textHint,
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            ),
          ),
        ),
        SheetHeroCard(
          icon: Icons.tune_rounded,
          title: 'Otimizar Deck',
          subtitle:
              'Escolha a direção da IA e aplique apenas mudanças seguras para este deck.',
          accent: accent,
        ),
        const SizedBox(height: 16),
        OptimizationConfigSection(
          selectedBracket: selectedBracket,
          keepTheme: keepTheme,
          accent: accent,
          onBracketChanged: onBracketChanged,
          onKeepThemeChanged: onKeepThemeChanged,
        ),
        const SizedBox(height: 12),
        if (savedArchetype != null && savedArchetype!.trim().isNotEmpty) ...[
          CurrentStrategySection(
            savedArchetype: savedArchetype!,
            showAllStrategies: showAllStrategies,
            onToggleVisibility: onToggleStrategyVisibility,
            onApply: () => onApplyArchetype(savedArchetype!),
          ),
          const SizedBox(height: 16),
        ],
        FutureBuilder<List<Map<String, dynamic>>>(
          future: optionsFuture,
          builder:
              (context, snapshot) => OptimizationOptionsSection(
                snapshot: snapshot,
                showAllStrategies: showAllStrategies,
                accent: accent,
                onRetry: onRetryOptions,
                onSelectArchetype: onApplyArchetype,
              ),
        ),
      ],
    );
  }
}
