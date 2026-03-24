import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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

class OptimizationPreviewDialog extends StatelessWidget {
  final String mode;
  final String archetype;
  final bool keepTheme;
  final String? preservedTheme;
  final String reasoning;
  final Map<String, dynamic>? qualityWarning;
  final Map<String, dynamic> deckAnalysis;
  final Map<String, dynamic> postAnalysis;
  final Map<String, dynamic> warnings;
  final List<Map<String, dynamic>> displayRemovals;
  final List<Map<String, dynamic>> displayAdditions;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final Future<void> Function()? onCopyDebug;

  const OptimizationPreviewDialog({
    super.key,
    required this.mode,
    required this.archetype,
    required this.keepTheme,
    required this.preservedTheme,
    required this.reasoning,
    required this.qualityWarning,
    required this.deckAnalysis,
    required this.postAnalysis,
    required this.warnings,
    required this.displayRemovals,
    required this.displayAdditions,
    required this.onCancel,
    required this.onConfirm,
    this.onCopyDebug,
  });

  List<String> _warningLines() {
    final lines = <String>[];
    if (warnings['filtered_by_color_identity'] is Map) {
      lines.add(
        'Algumas adições foram removidas por estarem fora da identidade do comandante.',
      );
    }
    if (warnings['blocked_by_bracket'] is Map) {
      lines.add(
        'Algumas adições foram bloqueadas por exceder limites do bracket.',
      );
    }
    if (warnings['invalid_cards'] != null) {
      lines.add(
        'Algumas cartas sugeridas não foram encontradas e foram removidas.',
      );
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final warningLines = _warningLines();

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: DialogTitleBlock(
        icon:
            mode == 'complete'
                ? Icons.playlist_add_check_circle_outlined
                : Icons.auto_awesome_rounded,
        title:
            mode == 'complete'
                ? 'Completar deck ($archetype)'
                : 'Sugestões para $archetype',
        subtitle: 'Revise as mudanças antes de aplicar no deck.',
        accent: mode == 'complete' ? AppTheme.mythicGold : AppTheme.manaViolet,
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
                        mode == 'complete' ? 'Modo Complete' : 'Modo Optimize',
                    color:
                        mode == 'complete'
                            ? AppTheme.mythicGold
                            : AppTheme.manaViolet,
                    icon:
                        mode == 'complete'
                            ? Icons.playlist_add_rounded
                            : Icons.auto_fix_high_rounded,
                  ),
                  if (keepTheme && preservedTheme != null)
                    DeckMetaChip(
                      label: 'Tema: $preservedTheme',
                      color: AppTheme.primarySoft,
                      icon: Icons.category_outlined,
                    ),
                ],
              ),
              if (reasoning.isNotEmpty) ...[
                const SizedBox(height: 16),
                DialogSectionCard(
                  title: 'Leitura da IA',
                  accent: AppTheme.primarySoft,
                  icon: Icons.psychology_alt_outlined,
                  child: Text(
                    reasoning,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              if (qualityWarning != null) ...[
                const SizedBox(height: 16),
                DialogSectionCard(
                  title: 'Aviso de qualidade',
                  accent: AppTheme.mythicGold,
                  icon: Icons.info_outline_rounded,
                  child: Text(
                    qualityWarning!['message'] as String? ??
                        'Otimização parcial.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              if (deckAnalysis.isNotEmpty && postAnalysis.isNotEmpty) ...[
                const SizedBox(height: 16),
                DialogSectionCard(
                  title: 'Antes vs Depois',
                  accent: AppTheme.manaViolet,
                  icon: Icons.compare_arrows_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MetricDiffRow(
                        label: 'CMC médio',
                        before: '${deckAnalysis['average_cmc'] ?? '-'}',
                        after: '${postAnalysis['average_cmc'] ?? '-'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Curva: ${deckAnalysis['mana_curve_assessment'] ?? '-'}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      if (postAnalysis['improvements'] is List &&
                          (postAnalysis['improvements'] as List).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Ganhos: ${(postAnalysis['improvements'] as List).take(2).join(' • ')}',
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
                  accent: AppTheme.mythicGold,
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
              if (displayRemovals.isNotEmpty) ...[
                const SizedBox(height: 16),
                DialogSectionCard(
                  title: 'Remover',
                  accent: AppTheme.error,
                  icon: Icons.remove_circle_outline_rounded,
                  child: Column(
                    children:
                        displayRemovals
                            .take(20)
                            .map(
                              (item) => _SuggestionLineItem(
                                item: item,
                                accent: AppTheme.error,
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
              if (displayAdditions.isNotEmpty) ...[
                const SizedBox(height: 16),
                DialogSectionCard(
                  title: 'Adicionar',
                  accent: AppTheme.success,
                  icon: Icons.add_circle_outline_rounded,
                  child: Column(
                    children: [
                      ...displayAdditions
                          .take(30)
                          .map(
                            (item) => _SuggestionLineItem(
                              item: item,
                              accent: AppTheme.success,
                            ),
                          ),
                      if (displayAdditions.length > 30)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '+ ${displayAdditions.length - 30} cartas…',
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
        TextButton(onPressed: onCancel, child: const Text('Cancelar')),
        if (onCopyDebug != null)
          TextButton(
            onPressed: () {
              onCopyDebug!();
            },
            child: const Text('Copiar debug'),
          ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('Aplicar mudanças'),
        ),
      ],
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
        accent: AppTheme.primarySoft,
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
                accent: AppTheme.primarySoft,
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

class _SuggestionLineItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color accent;

  const _SuggestionLineItem({required this.item, required this.accent});

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

    String suffix = '';
    if (confidenceLevel.isNotEmpty && score != null) {
      suffix = ' • ${confidenceLevel.toUpperCase()} ${(score * 100).round()}%';
    } else if (confidenceLevel.isNotEmpty) {
      suffix = ' • ${confidenceLevel.toUpperCase()}';
    } else if (score != null) {
      suffix = ' • ${(score * 100).round()}%';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $name$suffix',
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
          if (reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                reason,
                maxLines: 2,
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
    );
  }
}
