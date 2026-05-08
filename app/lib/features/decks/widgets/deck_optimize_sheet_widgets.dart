import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../../../core/theme/app_theme.dart';
import '../providers/deck_provider_support.dart';
import 'deck_optimize_flow_support.dart';
import 'deck_ui_components.dart';

class SheetHeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const SheetHeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.18), AppTheme.surfaceElevated],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.24), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StrategyOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final String? difficulty;
  final Color accent;
  final VoidCallback onTap;

  const StrategyOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: accent.withValues(alpha: 0.22), width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  if (difficulty != null && difficulty!.trim().isNotEmpty)
                    DeckMetaChip(
                      label: difficulty!,
                      color: AppTheme.textSecondary,
                    ),
                ],
              ),
              if (description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ver sugestões',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OptimizationPreviewDialog extends StatefulWidget {
  final String mode;
  final String archetype;
  final bool keepTheme;
  final String? preservedTheme;
  final String reasoning;
  final OptimizeIntensity intensity;
  final Map<String, dynamic> optimizeIntensity;
  final Map<String, dynamic>? qualityWarning;
  final Map<String, dynamic> deckAnalysis;
  final Map<String, dynamic> postAnalysis;
  final Map<String, dynamic> warnings;
  final Map<String, dynamic> metaReferenceContext;
  final List<Map<String, dynamic>> displayRemovals;
  final List<Map<String, dynamic>> displayAdditions;
  final VoidCallback onCancel;
  final ValueChanged<OptimizePreviewSelection> onConfirm;
  final Future<void> Function()? onCopyDebug;

  const OptimizationPreviewDialog({
    super.key,
    required this.mode,
    required this.archetype,
    required this.keepTheme,
    required this.preservedTheme,
    required this.reasoning,
    required this.intensity,
    required this.optimizeIntensity,
    required this.qualityWarning,
    required this.deckAnalysis,
    required this.postAnalysis,
    required this.warnings,
    required this.metaReferenceContext,
    required this.displayRemovals,
    required this.displayAdditions,
    required this.onCancel,
    required this.onConfirm,
    this.onCopyDebug,
  });

  @override
  State<OptimizationPreviewDialog> createState() =>
      _OptimizationPreviewDialogState();
}

class _OptimizationPreviewDialogState extends State<OptimizationPreviewDialog> {
  late final Set<int> _selectedRemovalIndexes;
  late final Set<int> _selectedAdditionIndexes;

  @override
  void initState() {
    super.initState();
    _selectedRemovalIndexes = {
      for (var index = 0; index < widget.displayRemovals.length; index++) index,
    };
    _selectedAdditionIndexes = {
      for (var index = 0; index < widget.displayAdditions.length; index++)
        index,
    };
  }

  List<String> _warningLines() {
    final lines = <String>[];
    if (widget.warnings['filtered_by_color_identity'] is Map) {
      lines.add(
        'Algumas adições foram removidas por estarem fora da identidade do comandante.',
      );
    }
    if (widget.warnings['blocked_by_bracket'] is Map) {
      lines.add(
        'Algumas adições foram bloqueadas por exceder limites do bracket.',
      );
    }
    if (widget.warnings['invalid_cards'] != null) {
      lines.add(
        'Algumas cartas sugeridas não foram encontradas e foram removidas.',
      );
    }
    return lines;
  }

  String _metric(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '-';
  }

  String get _planLabel {
    if (widget.mode == 'complete') return 'Completar lista';
    if (widget.metaReferenceContext.isNotEmpty) {
      return 'Ajuste competitivo guiado';
    }
    return switch (widget.intensity) {
      OptimizeIntensity.light => 'Ajuste leve',
      OptimizeIntensity.focused => 'Ajuste focado',
      OptimizeIntensity.aggressive => 'Ajuste agressivo',
      OptimizeIntensity.rebuild => 'Reconstrução guiada',
    };
  }

  String get _intensityLabel {
    return switch (widget.intensity) {
      OptimizeIntensity.light => 'Leve: 3-5 trocas seguras',
      OptimizeIntensity.focused => 'Focado: 6-10 trocas seguras',
      OptimizeIntensity.aggressive => 'Agressivo: 10-20 trocas seguras',
      OptimizeIntensity.rebuild => 'Rebuild guiado',
    };
  }

  int get _selectedChangeCount =>
      _selectedRemovalIndexes.length + _selectedAdditionIndexes.length;

  void _toggleRemoval(int index, bool selected) {
    setState(() {
      if (selected) {
        _selectedRemovalIndexes.add(index);
      } else {
        _selectedRemovalIndexes.remove(index);
      }
    });
  }

  void _toggleAddition(int index, bool selected) {
    setState(() {
      if (selected) {
        _selectedAdditionIndexes.add(index);
      } else {
        _selectedAdditionIndexes.remove(index);
      }
    });
  }

  void _confirmSelected() {
    widget.onConfirm(
      OptimizePreviewSelection(
        selectedRemovalIndexes: Set<int>.from(_selectedRemovalIndexes),
        selectedAdditionIndexes: Set<int>.from(_selectedAdditionIndexes),
      ),
    );
  }

  Widget _selectableSuggestionList({
    required List<Map<String, dynamic>> items,
    required Set<int> selectedIndexes,
    required String keyPrefix,
    required Color accent,
    required ValueChanged<int> onToggleOff,
    required ValueChanged<int> onToggleOn,
    int limit = 30,
  }) {
    return Column(
      children: [
        for (var index = 0; index < items.take(limit).length; index++)
          _SelectableSuggestionLineItem(
            key: Key('optimize-suggestion-$keyPrefix-$index'),
            item: items[index],
            accent: accent,
            selected: selectedIndexes.contains(index),
            onChanged: (value) {
              if (value) {
                onToggleOn(index);
              } else {
                onToggleOff(index);
              }
            },
          ),
      ],
    );
  }

  Map<String, dynamic> get _targetSwaps {
    final value = widget.optimizeIntensity['target_swaps'];
    return value is Map ? value.cast<String, dynamic>() : const {};
  }

  String get _targetSwapText {
    final min = _targetSwaps['min']?.toString();
    final max = _targetSwaps['max']?.toString();
    if (min != null && max != null) return '$min-$max';
    if (max != null) return 'até $max';
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final warningLines = _warningLines();

    return AlertDialog(
      key: const Key('optimize-preview-dialog'),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: DialogTitleBlock(
        icon:
            widget.mode == 'complete'
                ? Icons.playlist_add_check_circle_outlined
                : Icons.auto_awesome_rounded,
        title:
            widget.mode == 'complete'
                ? 'Completar deck (${widget.archetype})'
                : 'Sugestões para ${widget.archetype}',
        subtitle: 'Revise as mudanças antes de aplicar no deck.',
        accent:
            widget.mode == 'complete' ? AppTheme.brass400 : AppTheme.frost400,
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DeckMetaChip(
                    label:
                        widget.mode == 'complete'
                            ? 'Modo Complete'
                            : 'Modo Optimize',
                    color:
                        widget.mode == 'complete'
                            ? AppTheme.brass400
                            : AppTheme.frost400,
                    icon:
                        widget.mode == 'complete'
                            ? Icons.playlist_add_rounded
                            : Icons.auto_fix_high_rounded,
                  ),
                  DeckMetaChip(
                    label: _intensityLabel,
                    color:
                        widget.intensity == OptimizeIntensity.aggressive
                            ? AppTheme.mythicGold
                            : AppTheme.frost400,
                    icon: Icons.speed_rounded,
                  ),
                  if (widget.keepTheme && widget.preservedTheme != null)
                    DeckMetaChip(
                      label: 'Tema: ${widget.preservedTheme}',
                      color: AppTheme.frost400,
                      icon: Icons.category_outlined,
                    ),
                ],
              ),
              if (widget.intensity == OptimizeIntensity.aggressive) ...[
                const SizedBox(height: 16),
                DialogSectionCard(
                  title: 'Atenção ao ajuste agressivo',
                  accent: AppTheme.mythicGold,
                  icon: Icons.warning_amber_rounded,
                  child: const Text(
                    'Este modo pode trocar mais cartas. Desmarque qualquer sugestão que você queira preservar antes de aplicar.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              if (widget.reasoning.isNotEmpty) ...[
                const SizedBox(height: 16),
                DialogSectionCard(
                  title: 'Leitura da IA',
                  accent: AppTheme.frost400,
                  icon: Icons.psychology_alt_outlined,
                  child: Text(
                    widget.reasoning,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              if (widget.qualityWarning != null) ...[
                const SizedBox(height: 16),
                DialogSectionCard(
                  title: 'Aviso de qualidade',
                  accent: AppTheme.brass400,
                  icon: Icons.info_outline_rounded,
                  child: Text(
                    widget.qualityWarning!['message'] as String? ??
                        'Otimização parcial.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DialogSectionCard(
                title: 'Controle antes de aplicar',
                accent: AppTheme.frost400,
                icon: Icons.fact_check_outlined,
                child: _TrustSignalGrid(
                  signals: [
                    _TrustSignal(
                      label: 'Plano',
                      value: _planLabel,
                      icon: Icons.route_outlined,
                    ),
                    _TrustSignal(
                      label: 'Mudanças',
                      value: '$_selectedChangeCount selecionadas',
                      icon: Icons.swap_horiz_rounded,
                    ),
                    _TrustSignal(
                      label: 'Alvo',
                      value: _targetSwapText,
                      icon: Icons.flag_outlined,
                    ),
                    _TrustSignal(
                      label: 'Cartas depois',
                      value: _metric(widget.postAnalysis, const [
                        'total_cards',
                        'card_count',
                      ]),
                      icon: Icons.format_list_numbered,
                    ),
                    _TrustSignal(
                      label: 'Terrenos',
                      value: _metric(widget.postAnalysis, const [
                        'lands',
                        'land_count',
                      ]),
                      icon: Icons.terrain_outlined,
                    ),
                  ],
                ),
              ),
              if (widget.metaReferenceContext.isNotEmpty) ...[
                const SizedBox(height: 16),
                _MetaReferenceSection(contextData: widget.metaReferenceContext),
              ],
              if (widget.deckAnalysis.isNotEmpty &&
                  widget.postAnalysis.isNotEmpty) ...[
                const SizedBox(height: 16),
                DialogSectionCard(
                  title: 'Antes vs Depois',
                  accent: AppTheme.frost400,
                  icon: Icons.compare_arrows_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MetricDiffRow(
                        label: 'CMC médio',
                        before: '${widget.deckAnalysis['average_cmc'] ?? '-'}',
                        after: '${widget.postAnalysis['average_cmc'] ?? '-'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Curva: ${widget.deckAnalysis['mana_curve_assessment'] ?? '-'}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      if (widget.postAnalysis['improvements'] is List &&
                          (widget.postAnalysis['improvements'] as List)
                              .isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Ganhos: ${(widget.postAnalysis['improvements'] as List).take(2).join(' • ')}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (warningLines.isNotEmpty) ...[
                const SizedBox(height: 16),
                DialogSectionCard(
                  title: 'Avisos',
                  accent: AppTheme.brass400,
                  icon: Icons.warning_amber_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        warningLines
                            .map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '• $line',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
              if (widget.displayRemovals.isNotEmpty) ...[
                const SizedBox(height: 16),
                DialogSectionCard(
                  title:
                      'Remover (${_selectedRemovalIndexes.length}/${widget.displayRemovals.length})',
                  accent: AppTheme.error,
                  icon: Icons.remove_circle_outline_rounded,
                  child: Column(
                    children: [
                      _selectableSuggestionList(
                        items: widget.displayRemovals,
                        selectedIndexes: _selectedRemovalIndexes,
                        keyPrefix: 'remove',
                        accent: AppTheme.error,
                        onToggleOff: (index) => _toggleRemoval(index, false),
                        onToggleOn: (index) => _toggleRemoval(index, true),
                        limit: 20,
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.displayAdditions.isNotEmpty) ...[
                const SizedBox(height: 16),
                DialogSectionCard(
                  title:
                      'Adicionar (${_selectedAdditionIndexes.length}/${widget.displayAdditions.length})',
                  accent: AppTheme.success,
                  icon: Icons.add_circle_outline_rounded,
                  child: Column(
                    children: [
                      _selectableSuggestionList(
                        items: widget.displayAdditions,
                        selectedIndexes: _selectedAdditionIndexes,
                        keyPrefix: 'add',
                        accent: AppTheme.success,
                        onToggleOff: (index) => _toggleAddition(index, false),
                        onToggleOn: (index) => _toggleAddition(index, true),
                      ),
                      if (widget.displayAdditions.length > 30)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '+ ${widget.displayAdditions.length - 30} cartas…',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Cancelar')),
        if (kDebugMode && widget.onCopyDebug != null)
          TextButton(
            onPressed: () {
              widget.onCopyDebug!();
            },
            child: const Text('Copiar relatório técnico'),
          ),
        ElevatedButton(
          key: const Key('optimize-preview-apply-button'),
          onPressed: _selectedChangeCount == 0 ? null : _confirmSelected,
          child: const Text('Aplicar mudanças'),
        ),
      ],
    );
  }
}

class _MetaReferenceSection extends StatelessWidget {
  final Map<String, dynamic> contextData;

  const _MetaReferenceSection({required this.contextData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metaScope =
        (contextData['meta_scope'] is Map)
            ? (contextData['meta_scope'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final references =
        (contextData['references'] as List?)
            ?.whereType<Map>()
            .map((entry) => entry.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];
    final influenced =
        (contextData['suggested_cards_influenced'] as List?)
            ?.whereType<Map>()
            .map((entry) => entry.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];
    final prioritySource = contextData['priority_source']?.toString() ?? '';
    final selectionReason = contextData['selection_reason']?.toString() ?? '';
    final scopeLabel = metaScope['label']?.toString() ?? '';

    return DialogSectionCard(
      title: 'Referências meta usadas',
      accent: AppTheme.mythicGold,
      icon: Icons.travel_explore_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meta entra como referência estratégica, não como cópia cega. A lista final ainda passa por identidade de cor, bracket e preview antes de aplicar.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (scopeLabel.isNotEmpty)
                DeckMetaChip(
                  label: scopeLabel,
                  color: AppTheme.mythicGold,
                  icon: Icons.shield_outlined,
                ),
              if (selectionReason.isNotEmpty)
                DeckMetaChip(
                  label: selectionReason,
                  color: AppTheme.frost400,
                  icon: Icons.filter_alt_outlined,
                ),
              if (prioritySource.isNotEmpty)
                DeckMetaChip(
                  label: prioritySource,
                  color: AppTheme.textSecondary,
                  icon: Icons.source_outlined,
                ),
            ],
          ),
          if (references.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Shells de referência',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...references.take(3).map((reference) {
              final shell =
                  reference['shell_label']?.toString() ?? 'Shell meta';
              final source = reference['source']?.toString() ?? 'fonte meta';
              final scope = reference['meta_scope']?.toString() ?? '';
              final strategy =
                  reference['strategy_archetype']?.toString().trim() ?? '';
              final rank = reference['selection_rank']?.toString();
              final lineParts = [
                source,
                if (scope.isNotEmpty) scope,
                if (strategy.isNotEmpty) strategy,
              ];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MetaReferenceRow(
                  title: rank == null ? shell : '#$rank $shell',
                  subtitle: lineParts.join(' • '),
                ),
              );
            }),
          ],
          if (influenced.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Sugestões com evidência meta',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...influenced.take(5).map((entry) {
              final name = entry['name']?.toString() ?? '';
              final count = entry['reference_count']?.toString();
              return _MetaReferenceRow(
                title: name,
                subtitle:
                    count == null
                        ? 'Aparece nas referências selecionadas.'
                        : 'Aparece em $count referência(s) selecionada(s).',
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _MetaReferenceRow extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MetaReferenceRow({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.outlineMuted.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OutcomeInfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<String> reasons;

  const OutcomeInfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.reasons = const <String>[],
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      title: DialogTitleBlock(
        icon: Icons.info_outline,
        title: title,
        subtitle: 'Resultado da análise do deck',
        accent: AppTheme.frost400,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 16),
              DialogSectionCard(
                title: 'Motivos',
                accent: AppTheme.frost400,
                icon: Icons.rule_folder_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      reasons
                          .take(6)
                          .map(
                            (reason) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '• $reason',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class GuidedRebuildActionDialog extends StatelessWidget {
  final String message;
  final List<String> reasons;

  const GuidedRebuildActionDialog({
    super.key,
    required this.message,
    this.reasons = const <String>[],
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      title: DialogTitleBlock(
        icon: Icons.construction_rounded,
        title: 'Reconstrução guiada recomendada',
        subtitle:
            'A lista precisa de ajuste estrutural antes de upgrades seguros.',
        accent: AppTheme.mythicGold,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'O ManaLoom pode criar um rascunho reconstruído sem alterar o deck original.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
            ),
            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 16),
              DialogSectionCard(
                title: 'Por que rebuild?',
                accent: AppTheme.mythicGold,
                icon: Icons.rule_folder_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      reasons
                          .take(6)
                          .map(
                            (reason) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '• $reason',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Agora não'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.auto_fix_high_rounded),
          label: const Text('Criar reconstrução guiada'),
        ),
      ],
    );
  }
}

class _MetricDiffRow extends StatelessWidget {
  final String label;
  final String before;
  final String after;

  const _MetricDiffRow({
    required this.label,
    required this.before,
    required this.after,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$before → $after',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TrustSignal {
  final String label;
  final String value;
  final IconData icon;

  const _TrustSignal({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _TrustSignalGrid extends StatelessWidget {
  final List<_TrustSignal> signals;

  const _TrustSignalGrid({required this.signals});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          signals
              .map(
                (signal) => Container(
                  width: 118,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: AppTheme.outlineMuted.withValues(alpha: 0.62),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(signal.icon, size: 16, color: AppTheme.frost400),
                      const SizedBox(height: 6),
                      Text(
                        signal.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontXs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        signal.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: AppTheme.fontSm,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _SelectableSuggestionLineItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color accent;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _SelectableSuggestionLineItem({
    super.key,
    required this.item,
    required this.accent,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? '';
    final confidenceMap =
        (item['confidence'] is Map)
            ? (item['confidence'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final confidenceLevel = confidenceMap['level']?.toString() ?? '';
    final score = (confidenceMap['score'] as num?)?.toDouble();
    final reason = item['reason']?.toString() ?? '';
    final role = item['role']?.toString() ?? item['function']?.toString() ?? '';
    final priority = item['priority']?.toString() ?? '';
    final risk = item['risk']?.toString() ?? '';
    final impact =
        item['impact']?.toString() ?? item['impact_estimate']?.toString() ?? '';
    final metadata = [
      if (role.isNotEmpty) role,
      if (priority.isNotEmpty) 'prioridade $priority',
      if (risk.isNotEmpty) 'risco $risk',
      if (impact.isNotEmpty) impact,
    ].join(' • ');

    String suffix = '';
    if (confidenceLevel.isNotEmpty && score != null) {
      suffix = ' • ${confidenceLevel.toUpperCase()} ${(score * 100).round()}%';
    } else if (confidenceLevel.isNotEmpty) {
      suffix = ' • ${confidenceLevel.toUpperCase()}';
    } else if (score != null) {
      suffix = ' • ${(score * 100).round()}%';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: () => onChanged(!selected),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                selected
                    ? accent.withValues(alpha: 0.08)
                    : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color:
                  selected
                      ? accent.withValues(alpha: 0.35)
                      : AppTheme.outlineMuted.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onChanged(value ?? false),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name$suffix',
                      style: TextStyle(
                        color: selected ? accent : AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (metadata.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          metadata,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    if (reason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          reason,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
