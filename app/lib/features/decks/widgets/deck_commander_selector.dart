import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/card_artwork.dart';
import '../../../core/widgets/mana_symbols.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../../cards/providers/card_provider.dart';
import '../models/deck_card_item.dart';
import '../utils/commander_eligibility.dart';

class DeckCommanderSelector extends StatelessWidget {
  const DeckCommanderSelector({
    super.key,
    required this.format,
    required this.selectedCard,
    required this.onChanged,
  });

  final String format;
  final DeckCardItem? selectedCard;
  final ValueChanged<DeckCardItem?> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final provider = context.read<CardProvider>();
    provider.clearSearch();

    final card = await showDialog<DeckCardItem>(
      context: context,
      builder: (_) => _CommanderPickerDialog(
        format: format,
        selectedCardId: selectedCard?.id,
      ),
    );

    if (!context.mounted) return;
    provider.clearSearch();
    if (card != null) onChanged(card);
  }

  @override
  Widget build(BuildContext context) {
    final card = selectedCard;
    return Column(
      key: const Key('deck-create-commander-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comandante (opcional)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTheme.space5),
        Text(
          'Escolha agora ou conclua o deck como rascunho.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.space8),
        if (card == null)
          _EmptyCommanderSelection(onTap: () => _openPicker(context))
        else
          _SelectedCommander(
            card: card,
            onChange: () => _openPicker(context),
            onClear: () => onChanged(null),
          ),
      ],
    );
  }
}

class _EmptyCommanderSelection extends StatelessWidget {
  const _EmptyCommanderSelection({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Selecionar comandante',
      child: Material(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          key: const Key('deck-create-commander-select'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.brass400.withValues(alpha: 0.42),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.brass400.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppTheme.brass400.withValues(alpha: 0.32),
                    ),
                  ),
                  child: const ManaLoomGlyph(
                    ManaLoomGlyphKind.commander,
                    size: 22,
                    color: AppTheme.brass400,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecionar comandante',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.brass400,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space3),
                      Text(
                        'Busque por nome e confira a identidade de cor.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.brass400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedCommander extends StatelessWidget {
  const _SelectedCommander({
    required this.card,
    required this.onChange,
    required this.onClear,
  });

  final DeckCardItem card;
  final VoidCallback onChange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final identity = card.colorIdentity.isNotEmpty
        ? card.colorIdentity
        : card.colors;
    return Container(
      key: const Key('deck-create-commander-selected'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 67,
                child: CardArtwork(
                  variant: CardArtworkVariant.recentDeck,
                  imageUrl: card.effectiveImageUrl,
                  fallbackImageUrl: card.fallbackImageUrl,
                  semanticLabel: 'Arte de ${card.name}',
                  constrainAspectRatio: false,
                  errorPlaceholder: const _CommanderArtworkFallback(),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: AppTheme.space2),
                          child: ManaLoomGlyph(
                            ManaLoomGlyphKind.commander,
                            size: 17,
                            color: AppTheme.brass400,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space6),
                        Expanded(
                          child: Text(
                            card.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (card.typeLine.trim().isNotEmpty) ...[
                      const SizedBox(height: AppTheme.space5),
                      Text(
                        card.typeLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                    if (identity.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.space7),
                      ColorIdentityPips(
                        colors: identity,
                        symbolSize: 15,
                        spacing: 3,
                        decorated: false,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppTheme.space6,
            runSpacing: AppTheme.space4,
            children: [
              TextButton.icon(
                key: const Key('deck-create-commander-clear'),
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 17),
                label: const Text('Remover'),
              ),
              TextButton.icon(
                key: const Key('deck-create-commander-change'),
                onPressed: onChange,
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Trocar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommanderPickerDialog extends StatefulWidget {
  const _CommanderPickerDialog({
    required this.format,
    required this.selectedCardId,
  });

  final String format;
  final String? selectedCardId;

  @override
  State<_CommanderPickerDialog> createState() => _CommanderPickerDialogState();
}

class _CommanderPickerDialogState extends State<_CommanderPickerDialog> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String rawQuery) {
    _debounce?.cancel();
    final query = rawQuery.trim();
    setState(() => _query = query);

    if (query.length < 3) {
      context.read<CardProvider>().clearSearch();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted || _searchController.text.trim() != query) return;
      context.read<CardProvider>().searchCommanderCandidates(
        query,
        format: widget.format,
      );
    });
  }

  void _retry() {
    final query = _searchController.text.trim();
    if (query.length < 3) return;
    context.read<CardProvider>().searchCommanderCandidates(
      query,
      format: widget.format,
    );
  }

  List<DeckCardItem> _eligibleCandidates(List<DeckCardItem> cards) {
    final seenIdentities = <String>{};
    final eligible = <DeckCardItem>[];
    for (final card in cards) {
      if (!isPotentialCommander(card, format: widget.format)) continue;
      final oracleId = card.oracleId?.trim().toLowerCase();
      final normalizedName = card.name.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      final identity = oracleId != null && oracleId.isNotEmpty
          ? 'oracle:$oracleId'
          : 'name:$normalizedName';
      if (normalizedName.isEmpty || !seenIdentities.add(identity)) continue;
      eligible.add(card);
    }
    return eligible.take(20).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final availableHeight = math.max(288.0, mediaSize.height - 32);
    final dialogHeight = math.min(640.0, availableHeight);

    return Dialog(
      key: const Key('commander-picker-dialog'),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space16,
      ),
      backgroundColor: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.outlineMuted.withValues(alpha: 0.72)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SizedBox(
          height: dialogHeight,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.brass400.withValues(alpha: 0.12),
                      ),
                      child: const ManaLoomGlyph(
                        ManaLoomGlyphKind.commander,
                        size: 22,
                        color: AppTheme.brass400,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Escolher comandante',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: AppTheme.displayFontFamily,
                                ),
                          ),
                          Text(
                            widget.format.toLowerCase() == 'brawl'
                                ? 'Candidatos para Brawl'
                                : 'Candidatos para Commander',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('commander-picker-close'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Fechar busca',
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space14),
                TextField(
                  key: const Key('deck-create-commander-search-field'),
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Nome da carta',
                    hintText: 'Ex.: Atraxa',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('commander-picker-clear-search'),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              _searchFocusNode.requestFocus();
                            },
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Limpar busca',
                          ),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _retry(),
                ),
                const SizedBox(height: AppTheme.space12),
                Expanded(
                  child: Consumer<CardProvider>(
                    builder: (context, provider, _) {
                      if (_query.length < 3) {
                        return const _CommanderPickerMessage(
                          key: Key('deck-create-commander-empty'),
                          glyph: ManaLoomGlyphKind.commander,
                          title: 'Encontre seu comandante',
                          message:
                              'Digite pelo menos 3 letras. A busca mostra apenas comandantes elegíveis para o formato.',
                        );
                      }
                      if (provider.isLoading) {
                        return const Center(
                          key: Key('deck-create-commander-loading'),
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (provider.errorMessage != null) {
                        return Semantics(
                          container: true,
                          liveRegion: true,
                          child: _CommanderPickerMessage(
                            key: const Key('deck-create-commander-error'),
                            glyph: ManaLoomGlyphKind.card,
                            title: 'Busca indisponível',
                            message: provider.errorMessage!,
                            accent: AppTheme.error,
                            action: TextButton.icon(
                              key: const Key('commander-picker-retry'),
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Tentar novamente'),
                            ),
                          ),
                        );
                      }

                      final cards = _eligibleCandidates(provider.searchResults);
                      if (cards.isEmpty) {
                        return const _CommanderPickerMessage(
                          key: Key('deck-create-commander-empty'),
                          glyph: ManaLoomGlyphKind.card,
                          title: 'Nenhum comandante elegível',
                          message:
                              'Revise a grafia ou busque outro comandante pelo nome em inglês.',
                          accent: AppTheme.warning,
                        );
                      }

                      return ListView.separated(
                        key: const Key('deck-create-commander-results'),
                        itemCount: cards.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppTheme.space8),
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          return _CommanderCandidateTile(
                            card: card,
                            format: widget.format,
                            selected: widget.selectedCardId == card.id,
                            onSelected: () => Navigator.pop(context, card),
                          );
                        },
                      );
                    },
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

class _CommanderCandidateTile extends StatelessWidget {
  const _CommanderCandidateTile({
    required this.card,
    required this.format,
    required this.selected,
    required this.onSelected,
  });

  final DeckCardItem card;
  final String format;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final eligible = isPotentialCommander(card, format: format);
    final identity = card.colorIdentity.isNotEmpty
        ? card.colorIdentity
        : card.colors;
    final accent = eligible ? AppTheme.brass400 : AppTheme.textHint;

    return Semantics(
      button: eligible,
      enabled: eligible,
      label: eligible
          ? 'Selecionar ${card.name} como comandante'
          : '${card.name} não pode ser comandante',
      child: Opacity(
        opacity: eligible ? 1 : 0.62,
        child: Material(
          color: selected
              ? AppTheme.brass400.withValues(alpha: 0.1)
              : AppTheme.surfaceSlate,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InkWell(
            key: Key('deck-create-commander-result-${card.id}'),
            onTap: eligible ? onSelected : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.space10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: accent.withValues(alpha: 0.34)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    height: 67,
                    child: CardArtwork(
                      variant: CardArtworkVariant.recentDeck,
                      imageUrl: card.effectiveImageUrl,
                      fallbackImageUrl: card.fallbackImageUrl,
                      semanticLabel: 'Arte de ${card.name}',
                      constrainAspectRatio: false,
                      errorPlaceholder: const _CommanderArtworkFallback(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (card.typeLine.trim().isNotEmpty) ...[
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            card.typeLine,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.2,
                                ),
                          ),
                        ],
                        const SizedBox(height: AppTheme.space6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppTheme.space8,
                          runSpacing: AppTheme.space5,
                          children: [
                            if (identity.isNotEmpty)
                              ColorIdentityPips(
                                colors: identity,
                                symbolSize: 14,
                                spacing: 2,
                                decorated: false,
                              ),
                            Text(
                              eligible
                                  ? 'Elegível como comandante'
                                  : 'Não elegível como comandante',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.space6),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : eligible
                        ? Icons.chevron_right_rounded
                        : Icons.block_rounded,
                    color: accent,
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommanderPickerMessage extends StatelessWidget {
  const _CommanderPickerMessage({
    super.key,
    required this.glyph,
    required this.title,
    required this.message,
    this.accent = AppTheme.brass400,
    this.action,
  });

  final ManaLoomGlyphKind glyph;
  final String title;
  final String message;
  final Color accent;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ManaLoomGlyph(glyph, size: 34, color: accent),
            const SizedBox(height: AppTheme.space10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTheme.space6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppTheme.space10),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _CommanderArtworkFallback extends StatelessWidget {
  const _CommanderArtworkFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.backgroundAbyss,
      child: const Center(
        child: ManaLoomGlyph(
          ManaLoomGlyphKind.commander,
          size: 24,
          color: AppTheme.brass400,
        ),
      ),
    );
  }
}
