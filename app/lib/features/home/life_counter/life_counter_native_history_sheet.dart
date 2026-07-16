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
    backgroundColor: Colors.transparent,
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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Life Counter History',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              history.currentGameName == null
                                  ? 'Review recent events and completed games.'
                                  : 'Current game: ${history.currentGameName}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontMd,
                                height: 1.35,
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
                                  content: Text(
                                    'History copied to the clipboard.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                          },
                          icon: const Icon(Icons.ios_share_rounded, size: 18),
                          label: const Text('Export'),
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
                                        ? 'History imported.'
                                        : 'Could not import that history.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                          },
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Import'),
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppTheme.textSecondary,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.outlineMuted),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _SummaryPill(
                            label: 'Current events',
                            value: history.currentGameEventCount.toString(),
                          ),
                          _SummaryPill(
                            label: 'Archived games',
                            value: history.archivedGameCount.toString(),
                          ),
                          _SummaryPill(
                            label: 'Archived events',
                            value: history.archivedEventCount.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Last Table Event',
                        child: Text(
                          history.lastTableEvent ??
                              'No table event captured yet.',
                          key: const Key(
                            'life-counter-native-history-last-event',
                          ),
                          style: TextStyle(
                            color:
                                history.lastTableEvent == null
                                    ? AppTheme.textSecondary
                                    : AppTheme.textPrimary,
                            fontSize: AppTheme.fontMd,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Current Game',
                        child:
                            history.currentGameEntries.isEmpty
                                ? const _EmptyHistoryState(
                                  message:
                                      'No current-game history was captured yet.',
                                )
                                : Column(
                                  children: [
                                    for (final entry
                                        in history.currentGameEntries)
                                      _HistoryEntryTile(entry: entry),
                                  ],
                                ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Archive',
                        child:
                            history.archiveEntries.isEmpty
                                ? const _EmptyHistoryState(
                                  message: 'No archived games yet.',
                                )
                                : Column(
                                  children: [
                                    for (final entry in history.archiveEntries
                                        .take(12))
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
    builder:
        (dialogContext) => _HistoryImportDialog(
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
          'Import History',
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
            hintText: 'Paste exported history here',
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('life-counter-native-history-import-confirm'),
            onPressed: _isSubmitting ? null : _submit,
            child:
                _isImportInFlight
                    ? const SizedBox.square(
                      key: Key('life-counter-native-history-import-progress'),
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Import'),
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
          'Replace existing history?',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Importing this history will replace the current game history and every archived game.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            key: const Key('life-counter-native-history-replace-cancel'),
            onPressed: () => Navigator.of(confirmationContext).pop(false),
            child: const Text('Keep existing'),
          ),
          FilledButton(
            key: const Key('life-counter-native-history-replace-confirm'),
            onPressed: () => Navigator.of(confirmationContext).pop(true),
            child: const Text('Replace history'),
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
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
            const SizedBox(height: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            const SizedBox(height: 2),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
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
          const SizedBox(width: 10),
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
                    height: 1.3,
                  ),
                ),
                if (entry.occurredAt != null) ...[
                  const SizedBox(height: 4),
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
        height: 1.35,
      ),
    );
  }
}
