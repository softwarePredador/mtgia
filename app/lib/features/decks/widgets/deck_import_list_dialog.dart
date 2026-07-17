import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'deck_feedback_dialogs.dart';

typedef DeckImportListExecutor =
    Future<Map<String, dynamic>> Function({
      required String deckId,
      required String list,
      required bool replaceAll,
    });

typedef DeckRefreshExecutor = Future<void> Function(String deckId);
typedef DeckImportSnackBarPresenter =
    void Function({required String message, required Color backgroundColor});

Future<void> showDeckImportListDialog({
  required BuildContext context,
  required String deckId,
  required DeckImportListExecutor importListToDeck,
  required DeckRefreshExecutor refreshDeckDetails,
  required DeckImportSnackBarPresenter showSnackBar,
}) async {
  final listController = TextEditingController();
  final theme = Theme.of(context);
  bool isImporting = false;
  bool replaceAll = false;
  List<String> notFoundLines = [];
  List<String> importWarnings = [];
  int localizedMatchesCount = 0;
  bool missingCommander = false;
  bool commanderPreserved = false;
  bool importReviewVisible = false;
  String? error;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder:
        (dialogContext) => StatefulBuilder(
          builder:
              (ctx, setDialogState) => PopScope(
                canPop: !isImporting,
                child: AlertDialog(
                  key: const Key('deck-import-list-dialog'),
                  title: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Importar Lista',
                              style: TextStyle(
                                fontSize: AppTheme.fontXl,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Adicionar cartas de outra fonte',
                              style: TextStyle(
                                fontSize: AppTheme.fontSm,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Material(
                            color:
                                replaceAll
                                    ? AppTheme.warning.withValues(alpha: 0.1)
                                    : theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                              side: BorderSide(
                                color:
                                    replaceAll
                                        ? AppTheme.warning.withValues(
                                          alpha: 0.5,
                                        )
                                        : theme.colorScheme.outline.withValues(
                                          alpha: 0.3,
                                        ),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CheckboxListTile(
                              key: const Key(
                                'deck-import-list-dialog-replace-switch',
                              ),
                              value: replaceAll,
                              onChanged: (value) {
                                setDialogState(
                                  () => replaceAll = value ?? false,
                                );
                              },
                              title: Row(
                                children: [
                                  Icon(
                                    replaceAll
                                        ? Icons.swap_horiz
                                        : Icons.add_circle_outline,
                                    size: 18,
                                    color:
                                        replaceAll
                                            ? AppTheme.warning
                                            : theme.colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    replaceAll
                                        ? 'Substituir deck'
                                        : 'Adicionar cartas',
                                    style: const TextStyle(
                                      fontSize: AppTheme.fontMd,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                replaceAll
                                    ? 'Remove cartas atuais e usa apenas a nova lista'
                                    : 'Mantém cartas existentes e adiciona as novas',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSm,
                                  color: replaceAll ? AppTheme.warning : null,
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            key: const Key('deck-import-list-dialog-field'),
                            controller: listController,
                            decoration: InputDecoration(
                              hintText:
                                  'Cole sua lista de cartas aqui...\n\nFormato: 1 Sol Ring ou 1x Sol Ring',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                                fontSize: AppTheme.fontSm,
                              ),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                            ),
                            maxLines: 10,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: AppTheme.fontSm,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              key: const Key('deck-import-list-dialog-error'),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                                border: Border.all(
                                  color: AppTheme.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: AppTheme.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      error!,
                                      style: TextStyle(
                                        color: AppTheme.error,
                                        fontSize: AppTheme.fontSm,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (notFoundLines.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              key: const Key(
                                'deck-import-list-dialog-not-found',
                              ),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                                border: Border.all(
                                  color: AppTheme.warning.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⚠️ ${notFoundLines.length} cartas não encontradas:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.warning,
                                      fontSize: AppTheme.fontSm,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...notFoundLines
                                      .take(5)
                                      .map(
                                        (line) => Text(
                                          '• $line',
                                          style: TextStyle(
                                            fontSize: AppTheme.fontSm,
                                            color: AppTheme.warning.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                        ),
                                      ),
                                  if (notFoundLines.length > 5)
                                    Text(
                                      '... e mais ${notFoundLines.length - 5}',
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSm,
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.warning.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          if (localizedMatchesCount > 0) ...[
                            const SizedBox(height: 12),
                            Text(
                              '$localizedMatchesCount nomes localizados convertidos automaticamente.',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: AppTheme.fontSm,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (importWarnings.isNotEmpty ||
                              missingCommander ||
                              commanderPreserved) ...[
                            const SizedBox(height: 12),
                            DeckDialogSectionCard(
                              key: const Key(
                                'deck-import-list-dialog-import-status',
                              ),
                              title: 'Status da importação',
                              accent:
                                  importWarnings.isNotEmpty || missingCommander
                                      ? AppTheme.warning
                                      : AppTheme.success,
                              icon:
                                  importWarnings.isNotEmpty || missingCommander
                                      ? Icons.info_outline_rounded
                                      : Icons.verified_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (importWarnings.isNotEmpty)
                                    Column(
                                      key: const Key(
                                        'deck-import-list-dialog-warnings',
                                      ),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children:
                                          importWarnings
                                              .map(
                                                (warning) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 8,
                                                      ),
                                                  child: Text(
                                                    '• $warning',
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color:
                                                              AppTheme
                                                                  .textPrimary,
                                                          height: 1.35,
                                                        ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                  if (missingCommander)
                                    Padding(
                                      key: const Key(
                                        'deck-import-list-dialog-missing-commander',
                                      ),
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'Nenhum comandante foi identificado na lista importada.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.textPrimary,
                                              height: 1.35,
                                            ),
                                      ),
                                    ),
                                  if (commanderPreserved)
                                    Padding(
                                      key: const Key(
                                        'deck-import-list-dialog-commander-preserved',
                                      ),
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'O comandante atual do deck foi preservado.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.textPrimary,
                                              height: 1.35,
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
                    TextButton(
                      key: const Key('deck-import-list-dialog-cancel-button'),
                      onPressed: isImporting ? null : () => Navigator.pop(ctx),
                      child: Text(importReviewVisible ? 'Fechar' : 'Cancelar'),
                    ),
                    ElevatedButton.icon(
                      key: const Key('deck-import-list-dialog-submit-button'),
                      onPressed:
                          isImporting
                              ? null
                              : importReviewVisible
                              ? () => Navigator.pop(ctx)
                              : () async {
                                if (listController.text.trim().isEmpty) {
                                  setDialogState(
                                    () => error = 'Cole a lista de cartas',
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isImporting = true;
                                  error = null;
                                  notFoundLines = [];
                                  importWarnings = [];
                                  localizedMatchesCount = 0;
                                  missingCommander = false;
                                  commanderPreserved = false;
                                  importReviewVisible = false;
                                });

                                final result = await importListToDeck(
                                  deckId: deckId,
                                  list: listController.text,
                                  replaceAll: replaceAll,
                                );

                                if (!ctx.mounted) return;

                                final resultNotFoundLines = _stringListFrom(
                                  result['not_found_lines'],
                                );
                                final resultWarnings = _stringListFrom(
                                  result['warnings'],
                                );
                                final resultLocalizedMatchesCount = _intFrom(
                                  result['localized_matches_count'],
                                );
                                final resultMissingCommander =
                                    result['missing_commander'] == true;
                                final resultCommanderPreserved =
                                    result['commander_preserved'] == true;
                                final hasReviewDetails =
                                    resultNotFoundLines.isNotEmpty ||
                                    resultWarnings.isNotEmpty ||
                                    resultMissingCommander;

                                setDialogState(() {
                                  isImporting = false;
                                  notFoundLines = resultNotFoundLines;
                                  importWarnings = resultWarnings;
                                  localizedMatchesCount =
                                      resultLocalizedMatchesCount;
                                  missingCommander = resultMissingCommander;
                                  commanderPreserved = resultCommanderPreserved;
                                  importReviewVisible =
                                      result['success'] == true &&
                                      hasReviewDetails;
                                });

                                if (result['success'] == true) {
                                  final imported = _intFrom(
                                    result['cards_imported'],
                                  );
                                  showSnackBar(
                                    message: _buildImportToDeckSnackMessage(
                                      imported: imported,
                                      notFoundCount: resultNotFoundLines.length,
                                      localizedMatchesCount:
                                          resultLocalizedMatchesCount,
                                      hasReviewDetails: hasReviewDetails,
                                      commanderPreserved:
                                          resultCommanderPreserved,
                                    ),
                                    backgroundColor:
                                        resultNotFoundLines.isEmpty &&
                                                resultWarnings.isEmpty &&
                                                !resultMissingCommander
                                            ? theme.colorScheme.primary
                                            : AppTheme.warning,
                                  );

                                  await refreshDeckDetails(deckId);
                                  if (!ctx.mounted || hasReviewDetails) {
                                    return;
                                  }

                                  Navigator.pop(ctx);
                                } else {
                                  setDialogState(() {
                                    error =
                                        result['error']?.toString() ??
                                        'Erro ao importar';
                                  });
                                }
                              },
                      icon:
                          isImporting
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(
                                importReviewVisible
                                    ? Icons.check
                                    : Icons.upload,
                              ),
                      label: Text(
                        isImporting
                            ? 'Importando...'
                            : importReviewVisible
                            ? 'Concluído'
                            : 'Importar',
                      ),
                    ),
                  ],
                ),
              ),
        ),
  );
}

List<String> _stringListFrom(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
}

int _intFrom(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _buildImportToDeckSnackMessage({
  required int imported,
  required int notFoundCount,
  required int localizedMatchesCount,
  required bool hasReviewDetails,
  required bool commanderPreserved,
}) {
  if (hasReviewDetails) {
    if (notFoundCount > 0) {
      return '$imported cartas importadas ($notFoundCount não encontradas); revise os avisos';
    }
    return '$imported cartas importadas; revise os avisos';
  }

  if (localizedMatchesCount > 0) {
    final base =
        '$imported cartas importadas ($localizedMatchesCount traduzidas)';
    return commanderPreserved ? '$base; comandante preservado' : base;
  }

  if (commanderPreserved) {
    return '$imported cartas importadas; comandante preservado';
  }

  return '$imported cartas importadas!';
}
