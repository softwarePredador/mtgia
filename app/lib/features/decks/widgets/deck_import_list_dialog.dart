import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

typedef DeckImportListExecutor =
    Future<Map<String, dynamic>> Function({
      required String deckId,
      required String list,
      required bool replaceAll,
    });

typedef DeckRefreshExecutor = Future<void> Function(String deckId);
typedef DeckImportSnackBarPresenter =
    void Function({
      required String message,
      required Color backgroundColor,
    });

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
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  replaceAll
                                      ? AppTheme.warning.withValues(alpha: 0.1)
                                      : theme.colorScheme.surface,
                              border: Border.all(
                                color:
                                    replaceAll
                                        ? AppTheme.warning.withValues(
                                          alpha: 0.5,
                                        )
                                        : theme.colorScheme.outline.withValues(
                                          alpha: 0.3,
                                        ),
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                            ),
                            child: CheckboxListTile(
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
                                  color:
                                      replaceAll ? AppTheme.warning : null,
                                ),
                              ),
                              controlAffinity:
                                  ListTileControlAffinity.trailing,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
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
                                  ...notFoundLines.take(5).map(
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
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isImporting ? null : () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          isImporting
                              ? null
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
                                });

                                final result = await importListToDeck(
                                  deckId: deckId,
                                  list: listController.text,
                                  replaceAll: replaceAll,
                                );

                                if (!ctx.mounted) return;

                                setDialogState(() {
                                  isImporting = false;
                                  notFoundLines = List<String>.from(
                                    result['not_found_lines'] ?? const [],
                                  );
                                });

                                if (result['success'] == true) {
                                  Navigator.pop(ctx);

                                  final imported = result['cards_imported'] ?? 0;
                                  showSnackBar(
                                    message:
                                        notFoundLines.isEmpty
                                            ? '$imported cartas importadas!'
                                            : '$imported cartas importadas (${notFoundLines.length} não encontradas)',
                                    backgroundColor:
                                        notFoundLines.isEmpty
                                            ? theme.colorScheme.primary
                                            : AppTheme.warning,
                                  );

                                  await refreshDeckDetails(deckId);
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
                              : const Icon(Icons.upload),
                      label: Text(isImporting ? 'Importando...' : 'Importar'),
                    ),
                  ],
                ),
              ),
        ),
  );
}
