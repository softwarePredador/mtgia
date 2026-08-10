import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/card_artwork.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../../decks/models/deck_card_item.dart';
import 'card_edition_metadata.dart';

typedef CardPrintingsLoader =
    Future<List<Map<String, dynamic>>> Function(String cardName);

/// Opens a persistent, visual printing decision before a physical card is
/// added or replaced.
///
/// The picker never guesses when several printings exist. The caller receives
/// a fully hydrated [DeckCardItem] only after the user explicitly confirms one
/// set/collector/finish combination.
Future<DeckCardItem?> showCardPrintingPicker({
  required BuildContext context,
  required DeckCardItem card,
  required CardPrintingsLoader loadPrintings,
  String title = 'Escolha a impressão',
  String confirmLabel = 'Usar esta impressão',
}) {
  return showModalBottomSheet<DeckCardItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppTheme.surfaceElevated,
    barrierColor: AppTheme.backgroundAbyss.withValues(alpha: 0.78),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXl),
      ),
    ),
    builder: (sheetContext) => CardPrintingPickerSheet(
      card: card,
      loadPrintings: loadPrintings,
      title: title,
      confirmLabel: confirmLabel,
    ),
  );
}

@immutable
class CardPrintingOption {
  const CardPrintingOption({
    required this.card,
    required this.hasExactArtwork,
    this.price,
    this.priceCurrency = 'USD',
    this.priceSource,
    this.priceUpdatedAt,
  });

  factory CardPrintingOption.fromJson(
    Map<String, dynamic> json, {
    required DeckCardItem fallbackCard,
  }) {
    String? nonEmpty(Object? value) {
      final text = value?.toString().trim();
      return text == null || text.isEmpty ? null : text;
    }

    final id = nonEmpty(json['id']) ?? fallbackCard.id;
    final name = nonEmpty(json['name']) ?? fallbackCard.name;
    final imageUrl = nonEmpty(json['image_url']);
    final faces = CardFaceArtwork.fromJsonValue(json['card_faces']);
    final hasFaceArtwork = faces.any((face) => nonEmpty(face.imageUrl) != null);
    final hasExactArtwork = imageUrl != null || hasFaceArtwork;
    final rawPrice = json['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '');

    final card = DeckCardItem(
      id: id,
      oracleId: nonEmpty(json['oracle_id']) ?? fallbackCard.oracleId,
      name: name,
      manaCost: nonEmpty(json['mana_cost']) ?? fallbackCard.manaCost,
      typeLine: nonEmpty(json['type_line']) ?? fallbackCard.typeLine,
      oracleText: nonEmpty(json['oracle_text']) ?? fallbackCard.oracleText,
      power: nonEmpty(json['power']) ?? fallbackCard.power,
      toughness: nonEmpty(json['toughness']) ?? fallbackCard.toughness,
      colors: _stringList(json['colors'], fallbackCard.colors),
      colorIdentity: _stringList(
        json['color_identity'],
        fallbackCard.colorIdentity,
      ),
      imageUrl: imageUrl,
      layout: nonEmpty(json['layout']) ?? fallbackCard.layout,
      cardFaces: faces,
      // These fields identify the physical printing. Falling back to the
      // grouped search result could silently label one edition as another.
      setCode: nonEmpty(json['set_code']) ?? '',
      setName: nonEmpty(json['set_name']),
      setReleaseDate: nonEmpty(json['set_release_date']),
      rarity: nonEmpty(json['rarity']) ?? '',
      isReserved: json['is_reserved'] as bool? ?? fallbackCard.isReserved,
      printingCount: fallbackCard.printingCount,
      quantity: fallbackCard.quantity,
      isCommander: fallbackCard.isCommander,
      collectorNumber: nonEmpty(json['collector_number']),
      foil: json.containsKey('foil') ? json['foil'] as bool? : null,
      condition: fallbackCard.condition,
    );

    return CardPrintingOption(
      card: card,
      hasExactArtwork: hasExactArtwork,
      price: price,
      priceCurrency: nonEmpty(json['price_currency']) ?? 'USD',
      priceSource: nonEmpty(json['price_source']),
      priceUpdatedAt: nonEmpty(json['price_updated_at']),
    );
  }

  final DeckCardItem card;
  final bool hasExactArtwork;
  final double? price;
  final String priceCurrency;
  final String? priceSource;
  final String? priceUpdatedAt;

  String? get primaryImageUrl =>
      hasExactArtwork ? card.effectiveImageUrl : card.fallbackImageUrl;

  String? get fallbackImageUrl =>
      hasExactArtwork ? card.fallbackImageUrl : null;

  String get editionCode => cardEditionCodeLabel(
    setCode: card.setCode,
    collectorNumber: card.collectorNumber,
  );

  String get semanticLabel {
    final parts = <String>[
      card.name,
      if (editionCode.isNotEmpty) editionCode,
      if ((card.setName ?? '').trim().isNotEmpty) card.setName!.trim(),
      if (card.foil != null) cardCatalogFinishLabel(card.foil),
      if (!hasExactArtwork) 'imagem de referência',
      if (price != null)
        CurrencyFormatter.format(price!, currencyCode: priceCurrency),
    ];
    return parts.join(', ');
  }

  static List<String> _stringList(Object? value, List<String> fallback) {
    if (value is! List) return fallback;
    return value.map((entry) => entry.toString()).toList(growable: false);
  }
}

class CardPrintingPickerSheet extends StatefulWidget {
  const CardPrintingPickerSheet({
    super.key,
    required this.card,
    required this.loadPrintings,
    required this.title,
    required this.confirmLabel,
  });

  final DeckCardItem card;
  final CardPrintingsLoader loadPrintings;
  final String title;
  final String confirmLabel;

  @override
  State<CardPrintingPickerSheet> createState() =>
      _CardPrintingPickerSheetState();
}

class _CardPrintingPickerSheetState extends State<CardPrintingPickerSheet> {
  var _loading = true;
  String? _error;
  List<CardPrintingOption> _options = const [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final rows = await widget.loadPrintings(widget.card.name);
      final seenIds = <String>{};
      final options = <CardPrintingOption>[];
      for (final row in rows) {
        final option = CardPrintingOption.fromJson(
          row,
          fallbackCard: widget.card,
        );
        if (option.card.id.trim().isEmpty || !seenIds.add(option.card.id)) {
          continue;
        }
        options.add(option);
      }
      if (!mounted) return;
      setState(() {
        _options = List.unmodifiable(options);
        if (_selectedId != null &&
            !_options.any((option) => option.card.id == _selectedId)) {
          _selectedId = null;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Não foi possível carregar as impressões agora. Tente novamente.';
      });
    }
  }

  CardPrintingOption? get _selectedOption {
    final selectedId = _selectedId;
    if (selectedId == null) return null;
    for (final option in _options) {
      if (option.card.id == selectedId) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final transitionDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final selected = _selectedOption;
    final visibleOptionCount = _loading || _error != null || _options.isEmpty
        ? 2
        : math.min(_options.length, 5);
    final sheetHeight = math.min(
      viewport.height * 0.9,
      math.max(460.0, 190 + (visibleOptionCount * 116.0)),
    );
    final compactFooter = viewport.width < 520;

    return SizedBox(
      height: sheetHeight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space18,
                  AppTheme.space14,
                  AppTheme.space10,
                  AppTheme.space12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: AppTheme.space2),
                      child: ManaLoomGlyph(
                        ManaLoomGlyphKind.card,
                        size: 24,
                        color: AppTheme.brass400,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            '${widget.card.name}: confirme set, número e acabamento antes de adicionar.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('card-printing-picker-close'),
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: AppTheme.outlineMuted.withValues(alpha: 0.72),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: transitionDuration,
                  child: _buildBody(context),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space18,
                  AppTheme.space12,
                  AppTheme.space18,
                  AppTheme.space16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundAbyss.withValues(alpha: 0.36),
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.outlineMuted.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: transitionDuration,
                        child: Text(
                          selected == null
                              ? compactFooter
                                    ? 'Escolha uma opção.'
                                    : 'Selecione uma impressão para continuar.'
                              : '${selected.editionCode} selecionada',
                          key: ValueKey(selected?.card.id),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected == null
                                ? AppTheme.textSecondary
                                : AppTheme.frost400,
                            fontSize: AppTheme.fontSm,
                            fontWeight: selected == null
                                ? FontWeight.w500
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    FilledButton.icon(
                      key: const Key('card-printing-picker-confirm'),
                      onPressed: selected == null
                          ? null
                          : () => Navigator.of(context).pop(selected.card),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(widget.confirmLabel),
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

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const AppStatePanel.loading(
        key: ValueKey('card-printing-picker-loading'),
        title: 'Carregando impressões',
        message: 'Buscando as opções físicas disponíveis no catálogo.',
        accent: AppTheme.frost400,
      );
    }

    if (_error != null) {
      return AppStatePanel(
        key: const ValueKey('card-printing-picker-error'),
        icon: Icons.cloud_off_rounded,
        title: 'Impressões indisponíveis',
        message: _error,
        accent: AppTheme.warning,
        actionLabel: 'Tentar novamente',
        actionKey: const Key('card-printing-picker-retry'),
        onAction: _load,
      );
    }

    if (_options.isEmpty) {
      return const AppStatePanel(
        key: ValueKey('card-printing-picker-empty'),
        iconWidget: ManaLoomGlyph(ManaLoomGlyphKind.card),
        title: 'Nenhuma impressão encontrada',
        message:
            'O catálogo não possui uma opção física confirmável para esta carta.',
        accent: AppTheme.warning,
      );
    }

    return ListView.separated(
      key: const ValueKey('card-printing-picker-options'),
      padding: const EdgeInsets.all(AppTheme.space14),
      itemCount: _options.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space8),
      itemBuilder: (context, index) {
        final option = _options[index];
        return CardPrintingOptionTile(
          key: Key('card-printing-option-${option.card.id}'),
          option: option,
          selected: option.card.id == _selectedId,
          onTap: () => setState(() => _selectedId = option.card.id),
        );
      },
    );
  }
}

class CardPrintingOptionTile extends StatelessWidget {
  const CardPrintingOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CardPrintingOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final price = option.price;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: option.semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: AppTheme.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(AppTheme.space10),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.brass400.withValues(alpha: 0.08)
                    : AppTheme.surfaceSlate.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: selected
                      ? AppTheme.brass400.withValues(alpha: 0.72)
                      : AppTheme.outlineMuted.withValues(alpha: 0.7),
                  width: selected
                      ? AppTheme.strokeRegular
                      : AppTheme.strokeHairline,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 58,
                    height: 82,
                    child: CardArtwork(
                      variant: CardArtworkVariant.gallery,
                      imageUrl: option.primaryImageUrl,
                      fallbackImageUrl: option.fallbackImageUrl,
                      semanticLabel:
                          'Arte de ${option.card.name}, ${option.editionCode}',
                      constrainAspectRatio: false,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: AppTheme.space6,
                          runSpacing: AppTheme.space4,
                          children: [
                            if (option.editionCode.isNotEmpty)
                              _PrintingFactPill(label: option.editionCode),
                            if (option.card.foil != null)
                              _PrintingFactPill(
                                label: cardCatalogFinishLabel(option.card.foil),
                              ),
                          ],
                        ),
                        if ((option.card.setName ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: AppTheme.space5),
                          Text(
                            option.card.setName!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.fontSm,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (_printingFacts(option).isNotEmpty) ...[
                          const SizedBox(height: AppTheme.space2),
                          Text(
                            _printingFacts(option),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontXs,
                            ),
                          ),
                        ],
                        if (!option.hasExactArtwork) ...[
                          const SizedBox(height: AppTheme.space4),
                          const Text(
                            'Arte de referência; confirme pelos metadados.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.warning,
                              fontSize: AppTheme.fontXs,
                            ),
                          ),
                        ],
                        if (price != null ||
                            (option.priceSource ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: AppTheme.space6),
                          Wrap(
                            spacing: AppTheme.space8,
                            runSpacing: AppTheme.space3,
                            children: [
                              if (price != null)
                                Text(
                                  CurrencyFormatter.format(
                                    price,
                                    currencyCode: option.priceCurrency,
                                  ),
                                  style: const TextStyle(
                                    color: AppTheme.brass400,
                                    fontSize: AppTheme.fontSm,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              if ((option.priceSource ?? '').trim().isNotEmpty)
                                Text(
                                  'Fonte ${option.priceSource}',
                                  style: const TextStyle(
                                    color: AppTheme.textHint,
                                    fontSize: AppTheme.fontXs,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.space10),
                  AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 140),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(selected),
                      color: selected ? AppTheme.brass400 : AppTheme.textHint,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _printingFacts(CardPrintingOption option) {
    return cardEditionDescription(
      setReleaseDate: option.card.setReleaseDate,
      rarity: option.card.rarity,
      releaseYearOnly: true,
    );
  }
}

class _PrintingFactPill extends StatelessWidget {
  const _PrintingFactPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space6,
        vertical: AppTheme.space2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.frost400.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.frost400,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.25,
        ),
      ),
    );
  }
}
