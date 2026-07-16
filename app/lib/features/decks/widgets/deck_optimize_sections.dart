import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/deck_provider_support.dart';
import 'deck_optimize_sheet_widgets.dart';
import 'deck_ui_components.dart';

class OptimizationConfigSection extends StatelessWidget {
  final int selectedBracket;
  final bool keepTheme;
  final OptimizeIntensity selectedIntensity;
  final ValueChanged<int> onBracketChanged;
  final ValueChanged<bool> onKeepThemeChanged;
  final ValueChanged<OptimizeIntensity> onIntensityChanged;
  final Color accent;

  const OptimizationConfigSection({
    super.key,
    required this.selectedBracket,
    required this.keepTheme,
    required this.selectedIntensity,
    required this.onBracketChanged,
    required this.onKeepThemeChanged,
    required this.onIntensityChanged,
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
          _OptimizationIntensitySelector(
            selected: selectedIntensity,
            onChanged: onIntensityChanged,
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
              key: const Key('optimize-keep-theme-switch'),
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
          const SizedBox(height: 12),
          _OptimizationModeGuide(selectedBracket: selectedBracket),
        ],
      ),
    );
  }
}

class RecommendationContextSection extends StatelessWidget {
  const RecommendationContextSection({
    super.key,
    required this.preferCollection,
    required this.budgetLimit,
    required this.rebuildIntent,
    required this.onPreferCollectionChanged,
    required this.onBudgetLimitChanged,
    required this.onRebuildIntentChanged,
  });

  final bool preferCollection;
  final double budgetLimit;
  final String rebuildIntent;
  final ValueChanged<bool> onPreferCollectionChanged;
  final ValueChanged<double> onBudgetLimitChanged;
  final ValueChanged<String> onRebuildIntentChanged;

  @override
  Widget build(BuildContext context) {
    return DialogSectionCard(
      title: 'Diferencial da recomendação',
      accent: AppTheme.brass400,
      icon: Icons.psychology_alt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            key: const Key('optimize-prefer-collection-switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Priorizar minha coleção'),
            subtitle: const Text(
              'A IA tenta melhorar usando cartas do fichário antes de sugerir compra.',
            ),
            value: preferCollection,
            onChanged: onPreferCollectionChanged,
          ),
          const SizedBox(height: 6),
          Text(
            'Orçamento: R\$ ${budgetLimit.round()}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Slider(
            key: const Key('optimize-budget-slider'),
            value: budgetLimit,
            min: 0,
            max: 500,
            divisions: 20,
            label: 'R\$ ${budgetLimit.round()}',
            semanticFormatterCallback:
                (value) => 'Orçamento de R\$ ${value.round()}',
            onChanged: onBudgetLimitChanged,
          ),
          const SizedBox(height: 6),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Intenção do rebuild'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('optimize-rebuild-intent-field'),
                value: rebuildIntent,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'casual', child: Text('Casual')),
                  DropdownMenuItem(value: 'upgraded', child: Text('Upgraded')),
                  DropdownMenuItem(
                    value: 'optimized',
                    child: Text('Optimized'),
                  ),
                  DropdownMenuItem(value: 'cedh', child: Text('cEDH')),
                ],
                onChanged: (value) {
                  if (value != null) onRebuildIntentChanged(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          _RecommendationContextSummary(
            preferCollection: preferCollection,
            budgetLimit: budgetLimit,
            rebuildIntent: rebuildIntent,
          ),
          const SizedBox(height: 12),
          const _RecommendationTrustNote(),
        ],
      ),
    );
  }
}

class _RecommendationContextSummary extends StatelessWidget {
  const _RecommendationContextSummary({
    required this.preferCollection,
    required this.budgetLimit,
    required this.rebuildIntent,
  });

  final bool preferCollection;
  final double budgetLimit;
  final String rebuildIntent;

  String get _budgetLabel {
    final rounded = budgetLimit.round();
    if (rounded <= 0) return 'Sem compras novas';
    return 'Até R\$ $rounded';
  }

  String get _collectionLabel =>
      preferCollection ? 'Coleção primeiro' : 'Coleção + mercado';

  String get _intentLabel {
    return switch (rebuildIntent) {
      'casual' => 'Casual',
      'upgraded' => 'Upgraded',
      'optimized' => 'Optimized',
      'cedh' => 'cEDH',
      _ => rebuildIntent,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('optimize-recommendation-context-summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A IA vai respeitar',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RecommendationConstraintChip(
                icon: Icons.inventory_2_outlined,
                label: _collectionLabel,
              ),
              _RecommendationConstraintChip(
                icon: Icons.payments_outlined,
                label: _budgetLabel,
              ),
              _RecommendationConstraintChip(
                icon: Icons.speed_outlined,
                label: _intentLabel,
              ),
              const _RecommendationConstraintChip(
                icon: Icons.compare_arrows_outlined,
                label: 'Antes/depois',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationConstraintChip extends StatelessWidget {
  const _RecommendationConstraintChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.frost400),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTrustNote extends StatelessWidget {
  const _RecommendationTrustNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted.withValues(alpha: 0.6)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fact_check_outlined, color: AppTheme.frost400, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'O preview explica função, risco, curva, preço e bracket quando esses dados vierem da IA. O relatório antes/depois pode ser compartilhado antes de aplicar.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptimizationIntensitySelector extends StatelessWidget {
  final OptimizeIntensity selected;
  final ValueChanged<OptimizeIntensity> onChanged;

  const _OptimizationIntensitySelector({
    required this.selected,
    required this.onChanged,
  });

  String _title(OptimizeIntensity intensity) {
    return switch (intensity) {
      OptimizeIntensity.light => 'Leve',
      OptimizeIntensity.focused => 'Focado',
      OptimizeIntensity.aggressive => 'Agressivo',
      OptimizeIntensity.rebuild => 'Rebuild',
    };
  }

  String _description(OptimizeIntensity intensity) {
    return switch (intensity) {
      OptimizeIntensity.light => '3-5 trocas seguras, mantendo o plano.',
      OptimizeIntensity.focused => '6-10 trocas seguras; padrão equilibrado.',
      OptimizeIntensity.aggressive =>
        '10-20 trocas seguras. Pode mudar mais cartas do deck.',
      OptimizeIntensity.rebuild =>
        'Reconstrução guiada quando a estrutura precisa ser refeita.',
    };
  }

  Color _accent(OptimizeIntensity intensity) {
    return switch (intensity) {
      OptimizeIntensity.light => AppTheme.success,
      OptimizeIntensity.focused => AppTheme.frost400,
      OptimizeIntensity.aggressive => AppTheme.mythicGold,
      OptimizeIntensity.rebuild => AppTheme.brass400,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intensidade',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              OptimizeIntensity.values.map((intensity) {
                final isSelected = selected == intensity;
                final accent = _accent(intensity);
                return ChoiceChip(
                  key: Key('optimize-intensity-${intensity.name}'),
                  label: Text(_title(intensity)),
                  selected: isSelected,
                  onSelected: (_) => onChanged(intensity),
                  selectedColor: accent.withValues(alpha: 0.22),
                  side: BorderSide(
                    color:
                        isSelected
                            ? accent
                            : AppTheme.outlineMuted.withValues(alpha: 0.7),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _accent(selected).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: _accent(selected).withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected == OptimizeIntensity.rebuild
                    ? Icons.construction_rounded
                    : Icons.tune_rounded,
                color: _accent(selected),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _description(selected),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptimizationModeGuide extends StatelessWidget {
  final int selectedBracket;

  const _OptimizationModeGuide({required this.selectedBracket});

  @override
  Widget build(BuildContext context) {
    final isCompetitive = selectedBracket >= 4;
    final accent = isCompetitive ? AppTheme.mythicGold : AppTheme.frost400;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCompetitive ? Icons.emoji_events_outlined : Icons.tune_outlined,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCompetitive
                  ? 'Competitivo/cEDH: usa referências meta quando existirem, mas ainda filtra por identidade, bracket e segurança.'
                  : 'Ajuste leve: troca poucas cartas. Se a lista estiver muito fora da faixa, o app oferece rebuild guiado em vez de aplicar mudanças arriscadas.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
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
          key: const Key('optimize-apply-current-strategy-button'),
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
      if (!showAllStrategies) {
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

      return StrategyOptionCard(
        title: 'midrange',
        description:
            'Ajuste leve padrão quando o detector não encontra uma estratégia automática. O preview continua obrigatório antes de aplicar.',
        difficulty: 'fallback seguro',
        accent: accent,
        onTap: () => onSelectArchetype('midrange'),
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
  final OptimizeIntensity selectedIntensity;
  final bool preferCollection;
  final double budgetLimit;
  final String rebuildIntent;
  final bool startsFromPostGame;
  final bool showAllStrategies;
  final Future<List<Map<String, dynamic>>> optionsFuture;
  final ScrollController scrollController;
  final Color accent;
  final ValueChanged<int> onBracketChanged;
  final ValueChanged<bool> onKeepThemeChanged;
  final ValueChanged<OptimizeIntensity> onIntensityChanged;
  final ValueChanged<bool> onPreferCollectionChanged;
  final ValueChanged<double> onBudgetLimitChanged;
  final ValueChanged<String> onRebuildIntentChanged;
  final VoidCallback onToggleStrategyVisibility;
  final VoidCallback onRetryOptions;
  final ValueChanged<String> onApplyArchetype;

  const OptimizationSheetBody({
    super.key,
    required this.savedArchetype,
    required this.selectedBracket,
    required this.keepTheme,
    required this.selectedIntensity,
    required this.preferCollection,
    required this.budgetLimit,
    required this.rebuildIntent,
    this.startsFromPostGame = false,
    required this.showAllStrategies,
    required this.optionsFuture,
    required this.scrollController,
    required this.accent,
    required this.onBracketChanged,
    required this.onKeepThemeChanged,
    required this.onIntensityChanged,
    required this.onPreferCollectionChanged,
    required this.onBudgetLimitChanged,
    required this.onRebuildIntentChanged,
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
        SheetHeroCard(
          icon: Icons.tune_rounded,
          title: 'Otimizar Deck',
          subtitle: 'Estratégia, potência, coleção e orçamento.',
          accent: accent,
        ),
        const SizedBox(height: 16),
        if (startsFromPostGame) ...[
          const _PostGameOptimizationNotice(),
          const SizedBox(height: 16),
        ],
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
        const SizedBox(height: 16),
        OptimizationConfigSection(
          selectedBracket: selectedBracket,
          keepTheme: keepTheme,
          selectedIntensity: selectedIntensity,
          accent: accent,
          onBracketChanged: onBracketChanged,
          onKeepThemeChanged: onKeepThemeChanged,
          onIntensityChanged: onIntensityChanged,
        ),
        const SizedBox(height: 16),
        RecommendationContextSection(
          preferCollection: preferCollection,
          budgetLimit: budgetLimit,
          rebuildIntent: rebuildIntent,
          onPreferCollectionChanged: onPreferCollectionChanged,
          onBudgetLimitChanged: onBudgetLimitChanged,
          onRebuildIntentChanged: onRebuildIntentChanged,
        ),
      ],
    );
  }
}

class _PostGameOptimizationNotice extends StatelessWidget {
  const _PostGameOptimizationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('optimize-post-game-notice'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sports_score_outlined, color: AppTheme.brass400),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Fluxo iniciado pelo pós-jogo. Use coleção, orçamento e intensidade para transformar os problemas recorrentes da mesa em um ajuste revisável.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
