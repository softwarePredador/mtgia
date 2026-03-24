import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../models/deck_card_item.dart';
import 'deck_details_aux_widgets.dart';
import 'deck_ui_components.dart';

Future<String?> showDeckDescriptionEditorDialog({
  required BuildContext context,
  required String? currentDescription,
}) async {
  final controller = TextEditingController(
    text: currentDescription?.trim() ?? '',
  );
  final theme = Theme.of(context);

  return showDialog<String>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          title: const DialogTitleBlock(
            icon: Icons.edit_note_rounded,
            title: 'Descrição do deck',
            subtitle: 'Registre o plano, tema ou objetivo principal da lista.',
            accent: AppTheme.primarySoft,
          ),
          content: TextField(
            controller: controller,
            maxLines: 5,
            autofocus: true,
            decoration: InputDecoration(
              hintText:
                  'Descreva a estratégia, tema ou objetivo do deck...\n\nEx: Deck focado em tokens e sacrifício com sinergia Orzhov.',
              hintMaxLines: 5,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        ),
  );
}

Future<void> showDeckAiExplanationFlow({
  required BuildContext context,
  required DeckCardItem card,
  required Future<String?> Function(DeckCardItem card) explainCard,
}) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (ctx) => const Center(
          child: FlowLoadingDialog(
            title: 'Analisando a carta...',
            subtitle:
                'Relacionando a carta com o plano do deck e o papel dela na lista.',
            accent: AppTheme.manaViolet,
            icon: Icons.auto_awesome_rounded,
            tips: [
              'A análise tenta explicar função, sinergia e valor da carta no deck.',
              'Cartas boas isoladamente podem ter papel diferente dependendo do plano da lista.',
            ],
          ),
        ),
  );

  try {
    if (!context.mounted) return;
    final explanation = await explainCard(card);

    if (context.mounted) {
      Navigator.pop(context);
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            title: DialogTitleBlock(
              icon: Icons.auto_awesome_rounded,
              title: 'Análise: ${card.name}',
              subtitle: 'Leitura contextual da carta dentro do seu deck.',
              accent: AppTheme.manaViolet,
            ),
            content: SingleChildScrollView(
              child: DialogSectionCard(
                title: 'O que essa carta faz aqui',
                accent: AppTheme.manaViolet,
                icon: Icons.psychology_alt_outlined,
                child: Text(
                  explanation ?? 'Não foi possível gerar uma explicação.',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendi'),
              ),
            ],
          ),
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao explicar carta: $e')));
    }
  }
}

Future<void> showDeckEditionPicker({
  required BuildContext context,
  required DeckCardItem card,
  required Future<List<Map<String, dynamic>>> Function(String name)
  loadPrintings,
  required Future<void> Function(String newCardId) onReplaceEdition,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXl),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edições disponíveis',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(card.name, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: loadPrintings(card.name),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Erro ao buscar edições: ${snapshot.error}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  final list = snapshot.data ?? const [];
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Nenhuma edição encontrada no banco.'),
                    );
                  }

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final it = list[index];
                        final id = (it['id'] ?? '').toString();
                        final setName =
                            (it['set_name'] ?? it['set_code'] ?? '').toString();
                        final date = (it['set_release_date'] ?? '').toString();
                        final rarity = (it['rarity'] ?? '').toString();
                        final price = it['price'];
                        final priceText =
                            (price is num)
                                ? '\$${price.toStringAsFixed(2)}'
                                : (price is String && price.trim().isNotEmpty)
                                ? '\$$price'
                                : '—';

                        final isSelected = id == card.id;

                        return ListTile(
                          leading: CachedCardImage(
                            imageUrl: it['image_url'],
                            width: 40,
                            height: 56,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXs,
                            ),
                          ),
                          title: Text(setName),
                          subtitle: Text(
                            [
                              if (date.isNotEmpty) date,
                              if (rarity.isNotEmpty) rarity,
                            ].join(' • '),
                          ),
                          trailing: Text(
                            priceText,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          selected: isSelected,
                          onTap:
                              isSelected
                                  ? null
                                  : () async {
                                    Navigator.of(sheetContext).pop();
                                    await onReplaceEdition(id);
                                  },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showDeckCardDetailsDialog({
  required BuildContext context,
  required DeckCardItem card,
  required Future<void> Function() onShowAiExplanation,
  required Future<void> Function() onShowEditionPicker,
  required VoidCallback onOpenFullDetails,
}) async {
  await showDialog(
    context: context,
    builder:
        (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (card.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusMd),
                    ),
                    child: AspectRatio(
                      aspectRatio: 0.714,
                      child: CachedCardImage(
                        imageUrl: card.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: Theme.of(dialogContext).textTheme.titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      if (card.manaCost != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Custo: ',
                              style: Theme.of(dialogContext).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                            ManaCostRow(cost: card.manaCost),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        card.typeLine,
                        style: Theme.of(dialogContext).textTheme.bodyMedium
                            ?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      if ((card.setName ?? '').trim().isNotEmpty ||
                          (card.setReleaseDate ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          [
                            if ((card.setName ?? '').trim().isNotEmpty)
                              card.setName!,
                            if ((card.setReleaseDate ?? '').trim().isNotEmpty)
                              card.setReleaseDate!,
                          ].join(' • '),
                          style: Theme.of(dialogContext).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textHint),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: onShowEditionPicker,
                            icon: const Icon(Icons.collections_bookmark),
                            label: const Text('Trocar edição'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: onShowAiExplanation,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Theme.of(dialogContext).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Explicar',
                              style: TextStyle(
                                color:
                                    Theme.of(dialogContext).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontSize: AppTheme.fontSm,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (card.oracleText != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        OracleTextWidget(card.oracleText!),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: onOpenFullDetails,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Ver Detalhes'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Fechar'),
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
