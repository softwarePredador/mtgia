import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../cards/widgets/card_edition_metadata.dart';
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
  final isCommanderCard = card.isCommander;
  final consolidateSameName =
      isCommanderCard || format == 'commander' || format == 'brawl';

  bool isSaving = false;
  String? error;
  String selectedCardId = card.id;
  CardCondition selectedCondition = card.condition;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          title: Text(isCommanderCard ? 'Editar comandante' : 'Editar carta'),
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
                if (isCommanderCard) ...[
                  const SizedBox(height: AppTheme.space6),
                  Text(
                    'A edição escolhida fica no slot de comandante, fora das 99 cartas.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.space12),
                if (isCommanderCard)
                  const InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Quantidade',
                      border: OutlineInputBorder(),
                    ),
                    child: Text('1 cópia fixa para comandante'),
                  )
                else
                  TextField(
                    key: const Key('deck-card-edit-quantity-field'),
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: AppTheme.space12),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: loadPrintings(card.name),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppTheme.space4,
                        ),
                        child: Text('Carregando edições...'),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'Não foi possível carregar as edições agora. Tente novamente.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.error,
                        ),
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

                    final selectedPrinting = list.firstWhere(
                      (m) => (m['id'] ?? '').toString() == selectedCardId,
                      orElse: () => list.first,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Edição (set)',
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedCardId,
                              items: list.map((it) {
                                final id = (it['id'] ?? '').toString();
                                final label = cardEditionFullLabel(it);
                                return DropdownMenuItem<String>(
                                  value: id,
                                  child: Text(
                                    label.isEmpty ? id : label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: isSaving
                                  ? null
                                  : (v) {
                                      if (v == null) return;
                                      setDialogState(() => selectedCardId = v);
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space6),
                        Text(
                          cardEditionFullLabel(selectedPrinting),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppTheme.space12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Condição',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CardCondition>(
                      isExpanded: true,
                      value: selectedCondition,
                      items: CardCondition.values.map((c) {
                        return DropdownMenuItem<CardCondition>(
                          value: c,
                          child: Text('${c.code} — ${c.label}'),
                        );
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (v) {
                              if (v == null) return;
                              setDialogState(() => selectedCondition = v);
                            },
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppTheme.space12),
                  Text(
                    error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.error,
                    ),
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
              onPressed: isSaving
                  ? null
                  : () async {
                      final qty = isCommanderCard
                          ? 1
                          : int.tryParse(qtyController.text.trim());
                      if (qty == null || qty <= 0) {
                        setDialogState(() => error = 'Quantidade inválida');
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
                          error = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: AppTheme.space18,
                      height: AppTheme.space18,
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
