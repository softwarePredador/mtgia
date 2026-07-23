import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_history.dart';
import 'life_counter_history_store.dart';

Future<void> showLifeCounterNativeHistorySheet(
  BuildContext context, {
  required LifeCounterHistorySnapshot history,
  Future<void> Function()? onExportPressed,
  Future<bool> Function(String rawPayload)? onImportSubmitted,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.transparent,
    builder: (context) {
      return _LifeCounterNativeHistorySheet(
        history: history,
        onExportPressed: onExportPressed,
        onImportSubmitted: onImportSubmitted,
      );
    },
  );
}

class _LifeCounterNativeHistorySheet extends StatefulWidget {
  const _LifeCounterNativeHistorySheet({
    required this.history,
    this.onExportPressed,
    this.onImportSubmitted,
  });

  final LifeCounterHistorySnapshot history;
  final Future<void> Function()? onExportPressed;
  final Future<bool> Function(String rawPayload)? onImportSubmitted;

  @override
  State<_LifeCounterNativeHistorySheet> createState() =>
      _LifeCounterNativeHistorySheetState();
}

class _LifeCounterNativeHistorySheetState
    extends State<_LifeCounterNativeHistorySheet> {
  late LifeCounterHistorySnapshot _history;

  LifeCounterHistorySnapshot get history => _history;
  Future<void> Function()? get onExportPressed => widget.onExportPressed;
  Future<bool> Function(String rawPayload)? get onImportSubmitted =>
      widget.onImportSubmitted;

  @override
  void initState() {
    super.initState();
    _history = widget.history;
  }

  Future<void> _refreshImportedHistory() async {
    final importedState = await LifeCounterHistoryStore().load();
    if (!mounted || importedState == null) {
      return;
    }

    setState(() {
      _history = LifeCounterHistorySnapshot.fromSources(
        historyState: importedState,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space12,
          AppTheme.space12,
          AppTheme.space12,
          AppTheme.space12,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.backgroundAbyss,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.outlineMuted),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.overlayBlack40,
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space20,
                    AppTheme.space18,
                    AppTheme.space20,
                    AppTheme.space8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Histórico do contador de vida',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space6),
                            Text(
                              history.currentGameName == null
                                  ? 'Revise eventos recentes e partidas concluídas.'
                                  : 'Partida atual: ${history.currentGameName}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontMd,
                                height: AppTheme.lineHeightCompact,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onExportPressed != null)
                        TextButton.icon(
                          key: const Key('life-counter-native-history-export'),
                          onPressed: () async {
                            await onExportPressed!.call();
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.maybeOf(context)
                              ?..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('Histórico copiado.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                          },
                          icon: const Icon(Icons.ios_share_rounded, size: 18),
                          label: const Text('Exportar'),
                        ),
                      if (onImportSubmitted != null)
                        TextButton.icon(
                          key: const Key('life-counter-native-history-import'),
                          onPressed: () async {
                            final imported = await _showHistoryImportDialog(
                              context,
                              onImportSubmitted!,
                              requireReplacementConfirmation:
                                  history.hasContent,
                            );
                            if (!context.mounted || imported == null) {
                              return;
                            }
                            if (imported) {
                              await _refreshImportedHistory();
                              if (!context.mounted) {
                                return;
                              }
                            }
                            ScaffoldMessenger.maybeOf(context)
                              ?..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    imported
                                        ? 'Histórico importado.'
                                        : 'Não foi possível importar o histórico.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                          },
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Importar'),
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppTheme.textSecondary,
                        tooltip: 'Fechar',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.outlineMuted),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space20,
                      AppTheme.space18,
                      AppTheme.space20,
                      AppTheme.space16,
                    ),
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _SummaryPill(
                            label: 'Eventos atuais',
                            value: history.currentGameEventCount.toString(),
                          ),
                          _SummaryPill(
                            label: 'Partidas arquivadas',
                            value: history.archivedGameCount.toString(),
                          ),
                          _SummaryPill(
                            label: 'Eventos arquivados',
                            value: history.archivedEventCount.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space18),
                      _SectionCard(
                        title: 'Último evento da mesa',
                        child: Text(
                          history.lastTableEvent ??
                              'Nenhum evento da mesa registrado.',
                          key: const Key(
                            'life-counter-native-history-last-event',
                          ),
                          style: TextStyle(
                            color: history.lastTableEvent == null
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                            fontSize: AppTheme.fontMd,
                            height: AppTheme.lineHeightCompact,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      _SectionCard(
                        title: 'Partida atual',
                        child: history.currentGameEntries.isEmpty
                            ? const _EmptyHistoryState(
                                message:
                                    'Nenhum evento da partida atual foi registrado.',
                              )
                            : Column(
                                children: [
                                  for (final entry
                                      in history.currentGameEntries)
                                    _HistoryEntryTile(entry: entry),
                                ],
                              ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      _SectionCard(
                        title: 'Arquivo',
                        child: history.archiveEntries.isEmpty
                            ? const _EmptyHistoryState(
                                message: 'Nenhuma partida arquivada.',
                              )
                            : Column(
                                children: [
                                  for (final entry
                                      in history.archiveEntries.take(12))
                                    _HistoryEntryTile(entry: entry),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> _showHistoryImportDialog(
  BuildContext context,
  Future<bool> Function(String rawPayload) onImportSubmitted, {
  required bool requireReplacementConfirmation,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => _HistoryImportDialog(
      onImportSubmitted: onImportSubmitted,
      requireReplacementConfirmation: requireReplacementConfirmation,
    ),
  );
}

class _HistoryImportDialog extends StatefulWidget {
  const _HistoryImportDialog({
    required this.onImportSubmitted,
    required this.requireReplacementConfirmation,
  });

  final Future<bool> Function(String rawPayload) onImportSubmitted;
  final bool requireReplacementConfirmation;

  @override
  State<_HistoryImportDialog> createState() => _HistoryImportDialogState();
}

class _HistoryImportDialogState extends State<_HistoryImportDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _isImportInFlight = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isImportInFlight = !widget.requireReplacementConfirmation;
    });
    var closed = false;
    try {
      if (widget.requireReplacementConfirmation) {
        final confirmed = await _confirmHistoryReplacement(context);
        if (confirmed != true || !mounted) {
          return;
        }
        setState(() {
          _isImportInFlight = true;
        });
      }

      final result = await widget.onImportSubmitted(_controller.text);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
      closed = true;
    } finally {
      if (mounted && !closed) {
        setState(() {
          _isSubmitting = false;
          _isImportInFlight = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text(
          'Importar histórico',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          key: const Key('life-counter-native-history-import-input'),
          controller: _controller,
          enabled: !_isSubmitting,
          maxLines: 10,
          minLines: 6,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Cole aqui o histórico exportado',
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('life-counter-native-history-import-confirm'),
            onPressed: _isSubmitting ? null : _submit,
            child: _isImportInFlight
                ? const SizedBox.square(
                    key: Key('life-counter-native-history-import-progress'),
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Importar'),
          ),
        ],
      ),
    );
  }
}

Future<bool?> _confirmHistoryReplacement(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (confirmationContext) {
      return AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text(
          'Substituir o histórico existente?',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'A importação substituirá o histórico da partida atual e todas as partidas arquivadas.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            key: const Key('life-counter-native-history-replace-cancel'),
            onPressed: () => Navigator.of(confirmationContext).pop(false),
            child: const Text('Manter histórico atual'),
          ),
          FilledButton(
            key: const Key('life-counter-native-history-replace-confirm'),
            onPressed: () => Navigator.of(confirmationContext).pop(true),
            child: const Text('Substituir histórico'),
          ),
        ],
      );
    },
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space14,
          AppTheme.space14,
          AppTheme.space14,
          AppTheme.space12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.primarySoft,
                fontSize: AppTheme.fontLg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space14,
          vertical: AppTheme.space10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontXl,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({required this.entry});

  final LifeCounterHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: AppTheme.space6),
            decoration: BoxDecoration(
              color: switch (entry.source) {
                LifeCounterHistoryEntrySource.archive => AppTheme.mythicGold,
                LifeCounterHistoryEntrySource.fallback => AppTheme.primarySoft,
                LifeCounterHistoryEntrySource.currentGame =>
                  AppTheme.manaViolet,
              },
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.message,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontMd,
                    fontWeight: FontWeight.w600,
                    height: AppTheme.lineHeightDense,
                  ),
                ),
                if (entry.occurredAt != null) ...[
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    _formatTimestamp(entry.occurredAt!),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: AppTheme.fontMd,
        fontWeight: FontWeight.w600,
        height: AppTheme.lineHeightCompact,
      ),
    );
  }
}
