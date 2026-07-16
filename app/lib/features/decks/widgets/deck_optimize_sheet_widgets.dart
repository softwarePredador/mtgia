import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:share_plus/share_plus.dart';

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, color: accent, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: AppTheme.lineHeightCompact,
                ),
              ),
            ],
          ),
        ),
      ],
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
        side: BorderSide(
          color: accent.withValues(alpha: 0.22),
          width: AppTheme.strokeMedium,
        ),
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
  final Map<String, dynamic> optimizationContract;
  final Map<String, dynamic> battleValidation;
  final List<Map<String, dynamic>> displayRemovals;
  final List<Map<String, dynamic>> displayAdditions;
  final VoidCallback onCancel;
  final ValueChanged<OptimizePreviewSelection> onConfirm;
  final Future<void> Function()? onCopyDebug;
  final Future<String?> Function(Map<String, dynamic> payload)?
  onCreateShareLink;

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
    required this.optimizationContract,
    required this.battleValidation,
    required this.displayRemovals,
    required this.displayAdditions,
    required this.onCancel,
    required this.onConfirm,
    this.onCopyDebug,
    this.onCreateShareLink,
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
    if (_pairedSelectionRequired) {
      final pairCount =
          widget.displayRemovals.length < widget.displayAdditions.length
              ? widget.displayRemovals.length
              : widget.displayAdditions.length;
      _selectedRemovalIndexes = {
        for (var index = 0; index < pairCount; index++) index,
      };
      _selectedAdditionIndexes = {
        for (var index = 0; index < pairCount; index++) index,
      };
    } else {
      _selectedRemovalIndexes = {
        for (var index = 0; index < widget.displayRemovals.length; index++)
          index,
      };
      _selectedAdditionIndexes = {
        for (var index = 0; index < widget.displayAdditions.length; index++)
          index,
      };
    }
  }

  bool get _pairedSelectionRequired {
    final rawDecision = widget.optimizationContract['user_decision'];
    final decision =
        rawDecision is Map
            ? rawDecision.cast<String, dynamic>()
            : const <String, dynamic>{};
    return decision['paired_selection_required'] == true ||
        widget.mode == 'optimize';
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
      if (_pairedSelectionRequired) {
        _setPairedSelection(index, selected);
        return;
      }
      if (selected) {
        _selectedRemovalIndexes.add(index);
      } else {
        _selectedRemovalIndexes.remove(index);
      }
    });
  }

  void _toggleAddition(int index, bool selected) {
    setState(() {
      if (_pairedSelectionRequired) {
        _setPairedSelection(index, selected);
        return;
      }
      if (selected) {
        _selectedAdditionIndexes.add(index);
      } else {
        _selectedAdditionIndexes.remove(index);
      }
    });
  }

  void _setPairedSelection(int index, bool selected) {
    if (index < 0 ||
        index >= widget.displayRemovals.length ||
        index >= widget.displayAdditions.length) {
      return;
    }
    if (selected) {
      _selectedRemovalIndexes.add(index);
      _selectedAdditionIndexes.add(index);
    } else {
      _selectedRemovalIndexes.remove(index);
      _selectedAdditionIndexes.remove(index);
    }
  }

  void _confirmSelected() {
    widget.onConfirm(
      OptimizePreviewSelection(
        selectedRemovalIndexes: Set<int>.from(_selectedRemovalIndexes),
        selectedAdditionIndexes: Set<int>.from(_selectedAdditionIndexes),
      ),
    );
  }

  Future<void> _shareReport() async {
    var text = _buildShareReport();
    final createShareLink = widget.onCreateShareLink;
    if (createShareLink != null) {
      final link = await createShareLink(_buildSharePayload());
      if (link != null && link.trim().isNotEmpty) {
        text = '$text\n\nLink publico: $link';
      }
    }
    await Share.share(text);
  }

  Map<String, dynamic> _buildSharePayload() {
    List<Map<String, dynamic>> selected(
      List<Map<String, dynamic>> items,
      Set<int> selectedIndexes,
    ) {
      return selectedIndexes
          .where((index) => index >= 0 && index < items.length)
          .map((index) => Map<String, dynamic>.from(items[index]))
          .toList(growable: false);
    }

    return {
      'type': 'optimization_preview',
      'plan_label': _planLabel,
      'archetype': widget.archetype,
      'intensity_label': _intensityLabel,
      'selected_change_count': _selectedChangeCount,
      'reasoning': widget.reasoning,
      'before': widget.deckAnalysis,
      'after': widget.postAnalysis,
      'warnings': widget.warnings,
      'meta_reference_context': widget.metaReferenceContext,
      'optimization_contract': widget.optimizationContract,
      'battle_validation': widget.battleValidation,
      'removals': selected(widget.displayRemovals, _selectedRemovalIndexes),
      'additions': selected(widget.displayAdditions, _selectedAdditionIndexes),
    };
  }

  String _buildShareReport() {
    String names(List<Map<String, dynamic>> items, Set<int> selectedIndexes) {
      final selected =
          selectedIndexes
              .where((index) => index >= 0 && index < items.length)
              .map((index) => items[index]['name']?.toString() ?? '')
              .where((name) => name.trim().isNotEmpty)
              .take(12)
              .toList();
      return selected.isEmpty ? '-' : selected.join(', ');
    }

    return [
      'ManaLoom - Relatório antes/depois',
      'Plano: $_planLabel',
      'Estratégia: ${widget.archetype}',
      'Intensidade: $_intensityLabel',
      'Mudanças selecionadas: $_selectedChangeCount',
      'Remover: ${names(widget.displayRemovals, _selectedRemovalIndexes)}',
      'Adicionar: ${names(widget.displayAdditions, _selectedAdditionIndexes)}',
      if (widget.reasoning.isNotEmpty) 'Motivo: ${widget.reasoning}',
      if (widget.deckAnalysis.isNotEmpty || widget.postAnalysis.isNotEmpty)
        'Antes/depois: CMC ${widget.deckAnalysis['average_cmc'] ?? '-'} -> ${widget.postAnalysis['average_cmc'] ?? '-'}; cartas ${widget.deckAnalysis['total_cards'] ?? '-'} -> ${widget.postAnalysis['total_cards'] ?? widget.postAnalysis['card_count'] ?? '-'}.',
    ].join('\n');
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

  Map<String, dynamic> get _deckbuilderValidation {
    final raw = widget.optimizationContract['deckbuilder_validation'];
    return raw is Map ? raw.cast<String, dynamic>() : const {};
  }

  Map<String, dynamic> get _battleValidation {
    if (widget.battleValidation.isNotEmpty) return widget.battleValidation;
    final raw = widget.optimizationContract['battle_validation'];
    return raw is Map ? raw.cast<String, dynamic>() : const {};
  }

  @override
  Widget build(BuildContext context) {
    final warningLines = _warningLines();
    final deckbuilderValidation = _deckbuilderValidation;
    final battleValidation = _battleValidation;

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
                    _TrustSignal(
                      label: 'Validação',
                      value:
                          deckbuilderValidation['label']?.toString() ??
                          'Preview seguro',
                      icon: Icons.verified_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DialogSectionCard(
                title: 'Validação da recomendação',
                accent: AppTheme.success,
                icon: Icons.verified_user_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ValidationLine(
                      icon: Icons.fact_check_outlined,
                      color: AppTheme.success,
                      title:
                          deckbuilderValidation['label']?.toString() ??
                          'Preview seguro',
                      message:
                          deckbuilderValidation['message']?.toString() ??
                          'As sugestões passaram pelas regras do deck antes de aparecerem aqui.',
                    ),
                    const SizedBox(height: 10),
                    _ValidationLine(
                      icon: Icons.sports_esports_outlined,
                      color: AppTheme.brass400,
                      title:
                          battleValidation['label']?.toString() ??
                          'Battle pendente',
                      message:
                          battleValidation['message']?.toString() ??
                          'Depois de aplicar, rode playtest, battle ou replay para confirmar desempenho real em mesa.',
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
                              height: AppTheme.lineHeightCompact,
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
                                    height: AppTheme.lineHeightCompact,
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
        TextButton(
          key: const Key('optimize-preview-share-report-button'),
          onPressed: _shareReport,
          child: const Text('Compartilhar relatório'),
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
    final prioritySourceLabel = _friendlyMetaSourceLabel(prioritySource);
    final selectionReasonLabel = _friendlyMetaSelectionLabel(selectionReason);

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
              if (selectionReasonLabel.isNotEmpty)
                DeckMetaChip(
                  label: selectionReasonLabel,
                  color: AppTheme.frost400,
                  icon: Icons.filter_alt_outlined,
                ),
              if (prioritySourceLabel.isNotEmpty)
                DeckMetaChip(
                  label: prioritySourceLabel,
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
      key: const Key('optimize-outcome-info-dialog'),
      backgroundColor: AppTheme.surfaceElevated,
      surfaceTintColor: AppTheme.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        side: BorderSide(color: AppTheme.brass400.withValues(alpha: 0.18)),
      ),
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
                                  height: AppTheme.lineHeightCompact,
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
      key: const Key('optimize-rebuild-guided-dialog'),
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
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: AppTheme.lineHeightCompact,
              ),
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
                                  height: AppTheme.lineHeightCompact,
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
          key: const Key('optimize-rebuild-guided-cancel-button'),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Agora não'),
        ),
        ElevatedButton.icon(
          key: const Key('optimize-rebuild-guided-create-button'),
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

class _ValidationLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _ValidationLine({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (message.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: AppTheme.lineHeightCompact,
                  ),
                ),
              ],
            ],
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
    final playerFacing =
        (item['player_facing'] is Map)
            ? (item['player_facing'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final battleValidation =
        (item['battle_validation'] is Map)
            ? (item['battle_validation'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final confidenceMap =
        (item['confidence'] is Map)
            ? (item['confidence'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final confidenceLevel = confidenceMap['level']?.toString() ?? '';
    final score = (confidenceMap['score'] as num?)?.toDouble();
    final reason =
        playerFacing['summary']?.toString() ?? item['reason']?.toString() ?? '';
    final role =
        playerFacing['primary_role_label']?.toString() ??
        _friendlyRoleLabel(
          item['role']?.toString() ?? item['function']?.toString() ?? '',
        );
    final priority =
        playerFacing['priority_label']?.toString() ??
        _friendlyPriorityLabel(item['priority']?.toString() ?? '');
    final risk =
        playerFacing['risk_label']?.toString() ??
        _friendlyRiskLabel(item['risk']?.toString() ?? '');
    final curve =
        playerFacing['curve_label']?.toString() ??
        _friendlyCurveLabel(
          item['curve']?.toString() ??
              item['curve_slot']?.toString() ??
              item['cmc']?.toString() ??
              '',
        );
    final price = _friendlyPriceLabel(
      item['estimated_price_brl'] ?? item['price_brl'] ?? item['price'],
    );
    final bracket =
        item['bracket']?.toString() ??
        item['bracket_note']?.toString() ??
        item['power_level']?.toString() ??
        '';
    final collection = _collectionLabel(item);
    final battleLabel = battleValidation['label']?.toString() ?? '';
    final metadata = [
      if (role.isNotEmpty) role,
      if (priority.isNotEmpty) priority,
      if (risk.isNotEmpty) risk,
      if (curve.isNotEmpty) curve,
      if (price.isNotEmpty) price,
      if (collection.isNotEmpty) collection,
      if (bracket.isNotEmpty) 'mesa $bracket',
      if (battleLabel.isNotEmpty) battleLabel,
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
                            fontSize: AppTheme.fontSm,
                            height: AppTheme.lineHeightCompact,
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
                            fontSize: AppTheme.fontSm,
                            height: AppTheme.lineHeightCompact,
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

String _friendlyRoleLabel(String role) {
  switch (role.trim().toLowerCase()) {
    case 'ramp':
    case 'mana':
    case 'mana_ramp':
      return 'aceleração de mana';
    case 'draw':
    case 'card_draw':
    case 'card_advantage':
      return 'compra e vantagem';
    case 'interaction':
    case 'removal':
    case 'spot_removal':
      return 'interação';
    case 'wipe':
    case 'board_wipe':
    case 'sweeper':
      return 'limpeza de mesa';
    case 'protection':
      return 'proteção';
    case 'win_condition':
    case 'finisher':
      return 'condição de vitória';
    case 'land':
    case 'lands':
      return 'base de mana';
    case 'tutor':
      return 'busca de peças';
    case 'utility':
      return 'consistência';
    default:
      return role.trim();
  }
}

String _friendlyPriorityLabel(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'high':
    case 'alta':
      return 'prioridade alta';
    case 'medium':
    case 'media':
    case 'média':
      return 'prioridade média';
    case 'low':
    case 'baixa':
      return 'prioridade baixa';
    default:
      return priority.trim().isEmpty ? '' : priority.trim();
  }
}

String _friendlyRiskLabel(String risk) {
  switch (risk.trim().toLowerCase()) {
    case 'low':
    case 'baixo':
      return 'baixo risco';
    case 'medium':
    case 'medio':
    case 'médio':
      return 'risco moderado';
    case 'high':
    case 'alto':
      return 'alto risco';
    default:
      return risk.trim().isEmpty ? '' : risk.trim();
  }
}

String _friendlyCurveLabel(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  if (text.toLowerCase().contains('curva')) return text;
  return 'curva $text';
}

String _friendlyPriceLabel(Object? value) {
  if (value == null) return '';
  if (value is num) return 'R\$ ${value.toStringAsFixed(2)}';
  final text = value.toString().trim();
  if (text.isEmpty) return '';
  if (text.toLowerCase().startsWith('r\$')) return text;
  final parsed = double.tryParse(text.replaceAll(',', '.'));
  if (parsed != null) return 'R\$ ${parsed.toStringAsFixed(2)}';
  return text;
}

String _collectionLabel(Map<String, dynamic> item) {
  final ownedQuantity = item['owned_quantity'];
  final collectionMatch = item['collection_match'] == true;
  final purchaseRequired = item['purchase_required'] == true;
  if (collectionMatch) {
    final qty =
        ownedQuantity is num && ownedQuantity > 0
            ? ownedQuantity.toInt().toString()
            : '';
    return qty.isEmpty ? 'na coleção' : '$qty na coleção';
  }
  if (purchaseRequired) return 'precisa comprar';
  return '';
}

String _friendlyMetaSourceLabel(String source) {
  switch (source.trim().toLowerCase()) {
    case 'competitive_meta_exact_shell_match':
      return 'Referência competitiva';
    case 'competitive_meta_commander_match':
      return 'Mesmo comandante no meta';
    case 'commander_learning':
    case 'learned_deck':
      return 'Aprendizado do comandante';
    case 'edhrec':
      return 'EDHREC';
    default:
      final text = source.trim();
      if (text.isEmpty) return '';
      if (text.contains('_')) return '';
      return text;
  }
}

String _friendlyMetaSelectionLabel(String reason) {
  switch (reason.trim().toLowerCase()) {
    case 'exact shell match':
    case 'exact_shell_match':
      return 'Plano parecido';
    case 'commander match':
    case 'commander_match':
      return 'Mesmo comandante';
    case 'theme match':
    case 'theme_match':
      return 'Mesmo tema';
    default:
      final text = reason.trim();
      if (text.isEmpty) return '';
      if (text.contains('_')) return '';
      return text;
  }
}
