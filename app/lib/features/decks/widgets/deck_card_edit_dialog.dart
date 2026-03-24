import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/deck_card_item.dart';

typedef DeckCardEditSave =
    Future<void> Function({
      required String selectedCardId,
      required int quantity,
      required CardCondition selectedCondition,
      required bool consolidateSameName,
    });

Future<void> showDeckCardEditDialog({
  required BuildContext context,
  required DeckCardItem card,
  required String deckFormat,
  required Future<List<Map<String, dynamic>>> Function(String name)
  loadPrintings,
  required DeckCardEditSave onSave,
  VoidCallback? onSaved,
}) async {
  final theme = Theme.of(context);
  final qtyController = TextEditingController(text: '${card.quantity}');
  final format = deckFormat.toLowerCase();
  final consolidateSameName = format == 'commander' || format == 'brawl';

  bool isSaving = false;
  String? error;
  String selectedCardId = card.id;
  CardCondition selectedCondition = card.condition;

  await showDialog<void>(
    context: context,
    builder:
        (dialogContext) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Editar carta'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: loadPrintings(card.name),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text('Carregando edições...'),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Erro ao carregar edições: ${snapshot.error}',
                            style: TextStyle(color: theme.colorScheme.error),
                          );
                        }

                        final list = snapshot.data ?? const [];
                        if (list.isEmpty) {
                          return const Text('Nenhuma edição encontrada.');
                        }

                        if (!list.any(
                          (m) => (m['id'] ?? '').toString() == selectedCardId,
                        )) {
                          selectedCardId = list.first['id'].toString();
                        }

                        return InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Edição (set)',
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedCardId,
                              items:
                                  list.map((it) {
                                    final id = (it['id'] ?? '').toString();
                                    final setCode =
                                        (it['set_code'] ?? '')
                                            .toString()
                                            .toUpperCase();
                                    final setName =
                                        (it['set_name'] ?? '').toString();
                                    final date =
                                        (it['set_release_date'] ?? '')
                                            .toString();
                                    final label = [
                                      if (setCode.isNotEmpty) setCode,
                                      if (setName.isNotEmpty) setName,
                                      if (date.isNotEmpty) '($date)',
                                    ].join(' • ');
                                    return DropdownMenuItem<String>(
                                      value: id,
                                      child: Text(
                                        label.isEmpty ? id : label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                              onChanged:
                                  isSaving
                                      ? null
                                      : (v) {
                                        if (v == null) return;
                                        setDialogState(() => selectedCardId = v);
                                      },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Condição',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CardCondition>(
                          isExpanded: true,
                          value: selectedCondition,
                          items:
                              CardCondition.values.map((c) {
                                return DropdownMenuItem<CardCondition>(
                                  value: c,
                                  child: Text('${c.code} — ${c.label}'),
                                );
                              }).toList(),
                          onChanged:
                              isSaving
                                  ? null
                                  : (v) {
                                    if (v == null) return;
                                    setDialogState(
                                      () => selectedCondition = v,
                                    );
                                  },
                        ),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      isSaving
                          ? null
                          : () async {
                            final qty = int.tryParse(qtyController.text.trim());
                            if (qty == null || qty <= 0) {
                              setDialogState(
                                () => error = 'Quantidade inválida',
                              );
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                              error = null;
                            });

                            try {
                              await onSave(
                                selectedCardId: selectedCardId,
                                quantity: qty,
                                selectedCondition: selectedCondition,
                                consolidateSameName: consolidateSameName,
                              );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              onSaved?.call();
                            } catch (e) {
                              if (!ctx.mounted) return;
                              setDialogState(() {
                                isSaving = false;
                                error = e.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                );
                              });
                            }
                          },
                  child:
                      isSaving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Salvar'),
                ),
              ],
            );
          },
        ),
  );
}
