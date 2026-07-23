import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/friendly_error_mapper.dart';
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
    builder: (ctx) => AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space24,
        AppTheme.space24,
        AppTheme.space0,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space16,
        AppTheme.space24,
        AppTheme.space8,
      ),
      title: const DialogTitleBlock(
        icon: Icons.edit_note_rounded,
        title: 'Descrição do deck',
        subtitle: 'Registre o plano, tema ou objetivo principal da lista.',
        accent: AppTheme.frost400,
      ),
      content: TextField(
        key: const Key('deck-description-editor-field'),
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
          key: const Key('deck-description-editor-cancel-button'),
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('deck-description-editor-save-button'),
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

Future<bool?> showDeckRemoveCardConfirmationDialog({
  required BuildContext context,
  required DeckCardItem card,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space24,
        AppTheme.space24,
        AppTheme.space0,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space16,
        AppTheme.space24,
        AppTheme.space8,
      ),
      title: const DialogTitleBlock(
        icon: Icons.remove_circle_outline_rounded,
        title: 'Remover carta',
        subtitle: 'Confirme antes de alterar a composição estratégica do deck.',
        accent: AppTheme.error,
      ),
      content: DialogSectionCard(
        title: card.name,
        accent: AppTheme.error,
        icon: Icons.style_outlined,
        child: Text(
          'A carta será removida desta lista. Você poderá adicioná-la novamente pela busca.',
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: AppTheme.textPrimary,
          ),
          child: const Text('Remover'),
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
    builder: (ctx) => const Center(
      child: FlowLoadingDialog(
        title: 'Analisando a carta...',
        subtitle:
            'Relacionando a carta com o plano do deck e o papel dela na lista.',
        accent: AppTheme.frost400,
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
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(
          AppTheme.space24,
          AppTheme.space24,
          AppTheme.space24,
          AppTheme.space0,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppTheme.space24,
          AppTheme.space16,
          AppTheme.space24,
          AppTheme.space8,
        ),
        title: DialogTitleBlock(
          icon: Icons.auto_awesome_rounded,
          title: 'Análise: ${card.name}',
          subtitle: 'Leitura contextual da carta dentro do seu deck.',
          accent: AppTheme.frost400,
        ),
        content: SingleChildScrollView(
          child: DialogSectionCard(
            title: 'O que essa carta faz aqui',
            accent: AppTheme.frost400,
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
      final message = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.deckDetails,
        fallback:
            'Não foi possível explicar esta carta agora. Tente novamente em instantes.',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXl),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        key: Key('deck-edition-picker-sheet-${card.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key: const Key('deck-edition-picker-title'),
                card.isCommander
                    ? 'Escolher edição do comandante'
                    : 'Edições disponíveis',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.space4),
              Text(
                card.isCommander
                    ? '${card.name} fica no slot de comandante, fora das 99 cartas.'
                    : card.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.space12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: loadPrintings(card.name),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppTheme.space24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    final message = FriendlyErrorMapper.fromException(
                      snapshot.error,
                      context: FriendlyErrorContext.deckDetails,
                      fallback:
                          'Não foi possível carregar as edições agora. Tente novamente.',
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.space12,
                      ),
                      child: DialogSectionCard(
                        title: 'Edições indisponíveis',
                        accent: AppTheme.error,
                        icon: Icons.error_outline_rounded,
                        child: Text(
                          message,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                        ),
                      ),
                    );
                  }
                  final list = snapshot.data ?? const [];
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppTheme.space12),
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
                        final setCode = (it['set_code'] ?? '')
                            .toString()
                            .toUpperCase();
                        final setName = (it['set_name'] ?? it['set_code'] ?? '')
                            .toString();
                        final collector = (it['collector_number'] ?? '')
                            .toString();
                        final foil = it['foil'] == true;
                        final date = (it['set_release_date'] ?? '').toString();
                        final rarity = (it['rarity'] ?? '').toString();
                        final price = it['price'];
                        final priceText = (price is num)
                            ? '\$${price.toStringAsFixed(2)}'
                            : (price is String && price.trim().isNotEmpty)
                            ? '\$$price'
                            : '—';

                        final isSelected = id == card.id;

                        return ListTile(
                          key: Key('deck-edition-option-$id'),
                          leading: CachedCardImage(
                            imageUrl: it['image_url'],
                            fallbackImageUrl: card.fallbackImageUrl,
                            width: 40,
                            height: 56,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXs,
                            ),
                          ),
                          title: Text(
                            _editionTitle(
                              setCode: setCode,
                              collectorNumber: collector,
                              foil: foil,
                              fallback: setName.isEmpty ? id : setName,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (setName.isNotEmpty) setName,
                              if (date.isNotEmpty) date,
                              if (rarity.isNotEmpty) rarity,
                              if (isSelected) 'Atual',
                            ].join(' • '),
                          ),
                          trailing: Text(
                            priceText,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          selected: isSelected,
                          onTap: isSelected
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
    builder: (dialogContext) {
      final media = MediaQuery.sizeOf(dialogContext);
      return Dialog(
        key: Key('deck-card-details-dialog-${card.id}'),
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(
            color: AppTheme.outlineMuted.withValues(alpha: 0.72),
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: media.width >= 640 ? 560 : media.width - 32,
            maxHeight: media.height * 0.86,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: _DeckCardDetailsDialogBody(
                    card: card,
                    onShowAiExplanation: onShowAiExplanation,
                    onShowEditionPicker: () async {
                      Navigator.pop(dialogContext);
                      await onShowEditionPicker();
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.space8),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
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
      );
    },
  );
}

class _DeckCardDetailsDialogBody extends StatelessWidget {
  const _DeckCardDetailsDialogBody({
    required this.card,
    required this.onShowAiExplanation,
    required this.onShowEditionPicker,
  });

  final DeckCardItem card;
  final Future<void> Function() onShowAiExplanation;
  final Future<void> Function() onShowEditionPicker;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final imageWidth = compact
            ? constraints.maxWidth.clamp(118.0, 156.0)
            : constraints.maxWidth.clamp(124.0, 136.0);
        final info = _DeckCardDetailsInfo(
          card: card,
          onShowAiExplanation: onShowAiExplanation,
          onShowEditionPicker: onShowEditionPicker,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: _DeckCardDetailsImage(card: card, width: imageWidth),
              ),
              const SizedBox(height: AppTheme.space14),
              info,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeckCardDetailsImage(card: card, width: imageWidth),
            const SizedBox(width: AppTheme.space16),
            Expanded(child: info),
          ],
        );
      },
    );
  }
}

class _DeckCardDetailsImage extends StatelessWidget {
  const _DeckCardDetailsImage({required this.card, required this.width});

  final DeckCardItem card;
  final double width;

  static const double _cardAspectRatio = 1.397;

  @override
  Widget build(BuildContext context) {
    final height = width * _cardAspectRatio;

    return Container(
      key: Key('deck-card-details-image-${card.id}'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.45),
          width: AppTheme.strokeThin,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedCardImage(
        imageUrl: card.effectiveImageUrl,
        fallbackImageUrl: card.fallbackImageUrl,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _DeckCardDetailsInfo extends StatelessWidget {
  const _DeckCardDetailsInfo({
    required this.card,
    required this.onShowAiExplanation,
    required this.onShowEditionPicker,
  });

  final DeckCardItem card;
  final Future<void> Function() onShowAiExplanation;
  final Future<void> Function() onShowEditionPicker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        _DeckEditionInfo(card: card),
        if (card.manaCost != null) ...[
          const SizedBox(height: AppTheme.space10),
          Row(
            children: [
              Text(
                'Custo: ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              ManaCostRow(cost: card.manaCost),
            ],
          ),
        ],
        const SizedBox(height: AppTheme.space6),
        Text(
          card.typeLine,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.space10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_hasEditionInfo(card))
              ActionChip(
                key: Key('deck-card-change-edition-${card.id}'),
                avatar: const Icon(
                  Icons.collections_bookmark,
                  size: 16,
                  color: AppTheme.frost400,
                ),
                label: const Text('Trocar edição'),
                labelStyle: const TextStyle(
                  color: AppTheme.frost400,
                  fontWeight: FontWeight.w700,
                ),
                backgroundColor: AppTheme.frost400.withValues(alpha: 0.12),
                side: BorderSide(
                  color: AppTheme.frost400.withValues(alpha: 0.28),
                ),
                onPressed: onShowEditionPicker,
              ),
            ActionChip(
              avatar: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppTheme.frost400,
              ),
              label: const Text('Explicar com IA'),
              labelStyle: const TextStyle(
                color: AppTheme.frost400,
                fontWeight: FontWeight.w800,
              ),
              backgroundColor: AppTheme.frost400.withValues(alpha: 0.12),
              side: BorderSide(
                color: AppTheme.frost400.withValues(alpha: 0.28),
              ),
              onPressed: onShowAiExplanation,
            ),
          ],
        ),
        if (card.oracleText != null) ...[
          const SizedBox(height: AppTheme.space16),
          Divider(color: AppTheme.outlineMuted.withValues(alpha: 0.45)),
          const SizedBox(height: AppTheme.space8),
          OracleTextWidget(card.oracleText!),
        ],
      ],
    );
  }
}

bool _hasEditionInfo(DeckCardItem card) {
  return card.setCode.trim().isNotEmpty ||
      (card.collectorNumber ?? '').trim().isNotEmpty ||
      (card.setName ?? '').trim().isNotEmpty ||
      (card.setReleaseDate ?? '').trim().isNotEmpty ||
      card.foil == true;
}

String _editionTitle({
  required String setCode,
  required String collectorNumber,
  required bool foil,
  required String fallback,
}) {
  final parts = [
    if (setCode.trim().isNotEmpty) setCode.trim().toUpperCase(),
    if (collectorNumber.trim().isNotEmpty) '#${collectorNumber.trim()}',
    if (foil) 'foil',
  ];
  if (parts.isEmpty) return fallback;
  return parts.join(' ');
}

class _DeckEditionInfo extends StatelessWidget {
  const _DeckEditionInfo({required this.card});

  final DeckCardItem card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final setCode = card.setCode.trim().toUpperCase();
    final collector = (card.collectorNumber ?? '').trim();
    final editionTitle = _editionTitle(
      setCode: setCode,
      collectorNumber: collector,
      foil: card.foil == true,
      fallback: 'Edição não informada',
    );
    final editionSubtitle = [
      if ((card.setName ?? '').trim().isNotEmpty) card.setName!.trim(),
      if ((card.setReleaseDate ?? '').trim().isNotEmpty)
        card.setReleaseDate!.trim(),
      if (card.rarity.trim().isNotEmpty) card.rarity.trim(),
      if (card.isCommander) 'Comandante',
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space10,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.collections_bookmark_outlined,
            size: 18,
            color: card.isCommander ? AppTheme.mythicGold : AppTheme.frost400,
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editionTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (editionSubtitle.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space2),
                  Text(
                    editionSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
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
}

Future<void> showDeckPricingDetailsSheet({
  required BuildContext context,
  required Map<String, dynamic> pricing,
}) async {
  final items =
      (pricing['items'] as List?)?.whereType<Map>().toList() ?? const [];
  final currency = pricing['currency']?.toString() ?? 'USD';
  final total = pricing['estimated_total_usd'];
  final missing = pricing['missing_price_cards'];
  final source = switch (pricing['price_source']?.toString()) {
    'scryfall' => 'Scryfall',
    'mtgjson' => 'MTGJSON',
    'mixed' => 'fontes mistas',
    'legacy' => 'fonte legada',
    _ => 'fonte não informada',
  };

  await showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXl),
      ),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custo do deck',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                total is num
                    ? '${missing is num && missing > 0 ? 'Total parcial' : 'Total estimado'}: ${CurrencyFormatter.format(total, currencyCode: currency)}'
                    : 'Total indisponível',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.space4),
              Text(
                '${missing is num && missing > 0 ? '${missing.toInt()} carta(s) sem preço • ' : ''}Fonte: $source',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.space12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final it = items[index].cast<String, dynamic>();
                    final name = (it['name'] ?? '').toString();
                    final qty = (it['quantity'] as int?) ?? 0;
                    final setCode = (it['set_code'] ?? '').toString();
                    final unit = it['unit_price_usd'];
                    final unitText = (unit is num)
                        ? CurrencyFormatter.format(
                            unit,
                            currencyCode:
                                it['price_currency']?.toString() ?? currency,
                          )
                        : 'Sem preço';
                    final line = it['line_total_usd'];
                    final lineText = (line is num)
                        ? CurrencyFormatter.format(
                            line,
                            currencyCode:
                                it['price_currency']?.toString() ?? currency,
                          )
                        : '—';

                    return ListTile(
                      dense: true,
                      title: Text('$qty× $name'),
                      subtitle: Text(
                        setCode.isEmpty ? '' : setCode.toUpperCase(),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            lineText,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            unitText,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
