import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../../../core/utils/scryfall_image_helper.dart';
import '../../../core/widgets/card_artwork.dart';
import '../../../core/widgets/horizontal_discovery_rail.dart';
import '../../cards/providers/card_provider.dart';
import '../../cards/widgets/card_edition_metadata.dart';
import '../providers/binder_provider.dart';

/// Modal (BottomSheet) para editar/ver detalhes de um item do fichário.
/// Usado tanto para edição (modo update) quanto para adicionar ao binder.
/// Ao adicionar, busca todas as edições da carta para o usuário escolher.
class BinderItemEditor extends StatefulWidget {
  /// Se não-nulo, estamos editando um item existente.
  final BinderItem? item;

  /// cardId obrigatório para adição. Quando [item] != null, usa item.cardId.
  final String? cardId;
  final String? cardName;
  final String? cardImageUrl;

  /// Metadados da impressão escolhida na superfície de origem.
  ///
  /// A busca complementar de edições nunca deve apagar ou substituir essa
  /// identidade sem uma escolha explícita da pessoa.
  final Map<String, dynamic>? initialPrinting;

  /// Tipo de lista inicial: 'have' ou 'want' (apenas para adição)
  final String initialListType;

  /// Callbacks
  final Future<bool> Function(Map<String, dynamic> data)? onSave;
  final Future<bool> Function()? onDelete;

  const BinderItemEditor({
    super.key,
    this.item,
    this.cardId,
    this.cardName,
    this.cardImageUrl,
    this.initialPrinting,
    this.initialListType = 'have',
    this.onSave,
    this.onDelete,
  });

  /// Helper estático para abrir o modal
  static Future<void> show(
    BuildContext context, {
    BinderItem? item,
    String? cardId,
    String? cardName,
    String? cardImageUrl,
    Map<String, dynamic>? initialPrinting,
    String initialListType = 'have',
    Future<bool> Function(Map<String, dynamic> data)? onSave,
    Future<bool> Function()? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (_) => BinderItemEditor(
        item: item,
        cardId: cardId,
        cardName: cardName,
        cardImageUrl: cardImageUrl,
        initialPrinting: initialPrinting,
        initialListType: initialListType,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<BinderItemEditor> createState() => _BinderItemEditorState();
}

class _BinderItemEditorState extends State<BinderItemEditor> {
  late int _quantity;
  late String _condition;
  late bool _isFoil;
  late bool _forTrade;
  late bool _forSale;
  late String _listType;
  late String _language;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  late FocusNode _priceFocusNode;
  final GlobalKey _saveErrorKey = GlobalKey();
  bool _saving = false;
  String? _saveError;

  /// Edições disponíveis da carta (só para adição)
  List<Map<String, dynamic>> _printings = [];
  bool _loadingPrintings = false;
  String? _printingsError;
  int _selectedPrintingIndex = -1;

  static const conditions = ['NM', 'LP', 'MP', 'HP', 'DMG'];
  static const conditionLabels = {
    'NM': 'Near Mint',
    'LP': 'Lightly Played',
    'MP': 'Moderately Played',
    'HP': 'Heavily Played',
    'DMG': 'Damaged',
  };
  static const languages = ['en', 'pt', 'pt-br', 'es', 'fr', 'de', 'it', 'ja'];
  static const languageLabels = {
    'en': 'EN',
    'pt': 'PT',
    'pt-br': 'PT-BR',
    'es': 'ES',
    'fr': 'FR',
    'de': 'DE',
    'it': 'IT',
    'ja': 'JP',
  };

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _quantity = item?.quantity ?? 1;
    _condition = item?.condition ?? 'NM';
    _isFoil = item?.isFoil ?? false;
    _forTrade = item?.forTrade ?? false;
    _forSale = item?.forSale ?? false;
    _listType = item?.listType ?? widget.initialListType;
    _language = item?.language ?? 'en';
    _priceController = TextEditingController(
      text: item?.price?.toStringAsFixed(2) ?? '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');
    _priceFocusNode = FocusNode();

    // Buscar edições tanto na criação quanto na correção de uma cópia
    // existente. A impressão atual continua selecionada até uma escolha
    // explícita substituir seu card_id.
    if (widget.item != null || widget.cardName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchPrintings();
      });
    }
  }

  Future<void> _fetchPrintings() async {
    setState(() {
      _loadingPrintings = true;
      _printingsError = null;
    });
    try {
      final provider = context.read<CardProvider?>();
      if (provider == null) return;
      final name = widget.item?.cardName ?? widget.cardName!;
      var results = await provider.fetchPrintingsByName(name);

      // Se só encontrou 0-1 edição, importa do Scryfall e busca de novo
      if (results.length <= 1 && widget.item == null) {
        debugPrint(
          '[BinderItemEditor] Poucas edições (${results.length}), resolvendo via Scryfall...',
        );
        results = await provider.resolveAndFetchPrintings(name);
        debugPrint(
          '[BinderItemEditor] Após resolve: ${results.length} edições',
        );
      }

      if (!mounted) return;
      setState(() {
        _printings = results;
        // Selecionar a edição que corresponde ao cardId passado
        final currentCardId = widget.cardId ?? widget.item?.cardId;
        if (currentCardId != null) {
          final idx = _printings.indexWhere(
            (p) => p['id']?.toString() == currentCardId,
          );
          _selectedPrintingIndex = idx;
        }
      });
    } catch (e) {
      debugPrint('[BinderItemEditor] Erro ao buscar edições: $e');
      if (mounted) {
        setState(() {
          _printingsError =
              'Não foi possível carregar as edições agora. Você ainda pode salvar a carta selecionada.';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingPrintings = false);
    }
  }

  /// Retorna o card_id efetivo (da edição selecionada ou o original)
  String? get _effectiveCardId {
    if (_selectedPrintingIndex >= 0 &&
        _selectedPrintingIndex < _printings.length) {
      return _printings[_selectedPrintingIndex]['id']?.toString();
    }
    return widget.cardId ?? widget.item?.cardId;
  }

  /// Retorna a image_url da edição selecionada (fallback: imagem original)
  String? get _selectedImageUrl {
    if (_selectedPrintingIndex >= 0 &&
        _selectedPrintingIndex < _printings.length) {
      return _printings[_selectedPrintingIndex]['image_url'] as String?;
    }
    return widget.item?.cardPrintingImageUrl ??
        widget.initialPrinting?['image_url']?.toString() ??
        widget.cardImageUrl;
  }

  /// Retorna o preço de mercado da edição selecionada
  double? get _selectedMarketPrice {
    if (_selectedPrintingIndex >= 0 &&
        _selectedPrintingIndex < _printings.length) {
      final p = _printings[_selectedPrintingIndex]['price'];
      if (p is num) return p.toDouble();
    }
    final initialPrice =
        widget.item?.cardMarketPrice ?? widget.initialPrinting?['price'];
    return initialPrice is num ? initialPrice.toDouble() : null;
  }

  Map<String, dynamic>? get _selectedPrinting {
    if (_selectedPrintingIndex >= 0 &&
        _selectedPrintingIndex < _printings.length) {
      return _printings[_selectedPrintingIndex];
    }
    return null;
  }

  Map<String, dynamic>? get _effectivePrintingMetadata =>
      _selectedPrinting ?? widget.initialPrinting ?? _itemPrintingMetadata;

  Map<String, dynamic>? get _itemPrintingMetadata {
    final item = widget.item;
    if (item == null) return null;
    return {
      'id': item.cardId,
      'name': item.cardName,
      'image_url': item.cardPrintingImageUrl,
      'set_code': item.cardSetCode,
      'collector_number': item.cardCollectorNumber,
      'set_name': item.cardSetName,
      'set_release_date': item.cardSetReleaseDate,
      'rarity': item.cardRarity,
      'foil': item.isFoil,
    };
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  void _showSaveError(String message) {
    setState(() {
      _saving = false;
      _saveError = message;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final errorContext = _saveErrorKey.currentContext;
      if (!mounted || errorContext == null) return;
      Scrollable.ensureVisible(
        errorContext,
        alignment: 0.85,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (widget.item == null && (_effectiveCardId ?? '').isEmpty) {
      setState(() {
        _saveError = 'Selecione uma edição válida da carta.';
      });
      return;
    }

    final priceText = _priceController.text.trim();
    final parsedPrice = !_forSale || priceText.isEmpty
        ? null
        : double.tryParse(priceText.replaceAll(',', '.'));
    if (_forSale &&
        (parsedPrice == null || !parsedPrice.isFinite || parsedPrice <= 0)) {
      setState(() {
        _saveError = 'Informe um preço válido maior que zero.';
      });
      _priceFocusNode.requestFocus();
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    final data = <String, dynamic>{
      'quantity': _quantity,
      'condition': _condition,
      'is_foil': _isFoil,
      'for_trade': _forTrade,
      'for_sale': _forSale,
      'language': _language,
      'list_type': _listType,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    data['price'] = parsedPrice;

    // Criação sempre inclui a impressão. Em edição, só envia card_id quando a
    // pessoa escolheu explicitamente outra impressão.
    if (widget.item == null || _effectiveCardId != widget.item?.cardId) {
      data['card_id'] = _effectiveCardId;
    }

    try {
      final ok = await widget.onSave?.call(data) ?? false;
      if (!mounted) return;

      if (ok) {
        Navigator.pop(context);
      } else {
        _showSaveError(
          'Não foi possível salvar esta carta. Revise os dados e tente novamente.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showSaveError(
        FriendlyErrorMapper.fromException(
          error,
          context: FriendlyErrorContext.binder,
          fallback:
              'Não foi possível salvar esta carta agora. Tente novamente.',
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('binder-editor-delete-dialog'),
        backgroundColor: AppTheme.surfaceSlate,
        title: const Text(
          'Remover do Fichário?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Remover "${widget.item?.cardName}" do seu fichário?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            key: const Key('binder-editor-delete-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('binder-editor-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);
    final ok = await widget.onDelete?.call() ?? false;
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível remover a carta do fichário. Tente novamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final name = widget.item?.cardName ?? widget.cardName ?? 'Carta';

    return Padding(
      key: const Key('binder-editor-sheet'),
      padding: EdgeInsets.only(
        left: AppTheme.space20,
        right: AppTheme.space20,
        top: AppTheme.space16,
        bottom: AppTheme.space16 + bottomInset,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          key: const Key('binder-editor-content-frame'),
          constraints: const BoxConstraints(maxWidth: 1120),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.outlineMuted,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                // Título
                Text(
                  isEditing ? 'Editar — $name' : 'Adicionar — $name',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontXl,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.space16),

                // ===== Arte da carta + Seletor de edição =====
                ...[
                  // Imagem da carta selecionada
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 252,
                      child: CardArtwork(
                        variant: CardArtworkVariant.gallery,
                        imageUrl: _selectedImageUrl,
                        fallbackImageUrl: ScryfallImageHelper.namedImageUrl(
                          name,
                        ),
                        semanticLabel: _selectedPrintingIndex >= 0
                            ? 'Arte da impressão selecionada de $name'
                            : 'Arte da impressão atual de $name',
                        constrainAspectRatio: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),

                  // Preço de mercado
                  if (_selectedMarketPrice != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space10,
                          vertical: AppTheme.space4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.mythicGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          border: Border.all(
                            color: AppTheme.mythicGold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Preço de mercado: US\$ ${_selectedMarketPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.mythicGold,
                            fontSize: AppTheme.fontSm,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppTheme.space12),

                  // Seletor de edições (horizontal scroll)
                  if (_loadingPrintings)
                    const Center(
                      child: Padding(
                        key: Key('binder-editor-printings-loading'),
                        padding: EdgeInsets.symmetric(
                          vertical: AppTheme.space8,
                        ),
                        child: SizedBox(
                          width: AppTheme.iconSpinnerSm,
                          height: AppTheme.iconSpinnerSm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.manaViolet,
                          ),
                        ),
                      ),
                    )
                  else if (_printingsError != null) ...[
                    Semantics(
                      liveRegion: true,
                      container: true,
                      child: Container(
                        key: const Key('binder-editor-printings-error'),
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.space10),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          border: Border.all(
                            color: AppTheme.warning.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _printingsError!,
                              style: const TextStyle(
                                color: AppTheme.warning,
                                fontSize: AppTheme.fontSm,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space6),
                            TextButton.icon(
                              key: const Key('binder-editor-printings-retry'),
                              onPressed: _fetchPrintings,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_printings.isNotEmpty) ...[
                    if (_selectedPrintingIndex < 0) ...[
                      Container(
                        key: const Key(
                          'binder-editor-original-printing-warning',
                        ),
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppTheme.space8),
                        padding: const EdgeInsets.all(AppTheme.space10),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          border: Border.all(
                            color: AppTheme.warning.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          'A impressão atual não apareceu nesta lista. Ela será preservada até você escolher outra edição explicitamente.',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: AppTheme.fontSm,
                          ),
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        const Text(
                          'Edição',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontMd,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_printings.length} ${_printings.length == 1 ? 'disponível' : 'disponíveis'}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontSm,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space8),
                    HorizontalDiscoveryRail(
                      key: const Key('binder-editor-printings-rail'),
                      semanticLabel:
                          '${_printings.length} impressões físicas disponíveis',
                      hintText: 'Deslize para comparar as impressões.',
                      backwardHintText:
                          'Volte para comparar as impressões anteriores.',
                      forwardSemanticLabel: 'Ver próximas impressões',
                      backwardSemanticLabel: 'Voltar às impressões anteriores',
                      hintKey: const Key('binder-editor-printings-hint'),
                      forwardButtonKey: const Key(
                        'binder-editor-printings-next',
                      ),
                      backwardButtonKey: const Key(
                        'binder-editor-printings-previous',
                      ),
                      builder: (context, controller) => SizedBox(
                        key: const Key('binder-editor-printings-list'),
                        height: 78,
                        child: ListView.separated(
                          controller: controller,
                          scrollDirection: Axis.horizontal,
                          itemCount: _printings.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppTheme.space8),
                          itemBuilder: (context, index) {
                            final p = _printings[index];
                            final setCode = (p['set_code'] as String? ?? '')
                                .toUpperCase();
                            final setName = p['set_name'] as String? ?? setCode;
                            final releaseDate =
                                p['set_release_date'] as String? ?? '';
                            final collector = (p['collector_number'] ?? '')
                                .toString();
                            final rarity = (p['rarity'] ?? '').toString();
                            final foil = p['foil'] as bool?;
                            final year = releaseDate.length >= 4
                                ? releaseDate.substring(0, 4)
                                : '';
                            final price = p['price'] is num
                                ? (p['price'] as num).toDouble()
                                : null;
                            final isSelected = index == _selectedPrintingIndex;

                            return Semantics(
                              button: true,
                              selected: isSelected,
                              label:
                                  'Edição ${cardEditionCodeLabel(setCode: setCode, collectorNumber: collector)}${year.isEmpty ? '' : ', $year'}',
                              child: GestureDetector(
                                key: Key(
                                  'binder-editor-printing-option-${p['id'] ?? index}',
                                ),
                                excludeFromSemantics: true,
                                onTap: () => setState(
                                  () => _selectedPrintingIndex = index,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  constraints: const BoxConstraints(
                                    minHeight: AppTheme.touchTargetMin,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.space14,
                                    vertical: AppTheme.space8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.manaViolet.withValues(
                                            alpha: 0.25,
                                          )
                                        : AppTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd,
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.manaViolet
                                          : AppTheme.outlineMuted,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppTheme.space5,
                                              vertical: AppTheme.space1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppTheme.manaViolet
                                                  : AppTheme.outlineMuted
                                                        .withValues(alpha: 0.5),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusXs,
                                                  ),
                                            ),
                                            child: Text(
                                              cardEditionCodeLabel(
                                                setCode: setCode,
                                                collectorNumber: collector,
                                              ),
                                              style: TextStyle(
                                                color: isSelected
                                                    ? AppTheme.backgroundAbyss
                                                    : AppTheme.textPrimary,
                                                fontWeight: FontWeight.w800,
                                                fontSize: AppTheme.fontSm - 1,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          if (year.isNotEmpty) ...[
                                            const SizedBox(
                                              width: AppTheme.space6,
                                            ),
                                            Text(
                                              year,
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: AppTheme.fontSm - 1,
                                              ),
                                            ),
                                          ],
                                          if (price != null) ...[
                                            const SizedBox(
                                              width: AppTheme.space6,
                                            ),
                                            Text(
                                              '\$${price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: AppTheme.mythicGold,
                                                fontSize: AppTheme.fontSm - 1,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (rarity.isNotEmpty ||
                                          foil != null) ...[
                                        const SizedBox(height: AppTheme.space2),
                                        Text(
                                          [
                                            if (rarity.isNotEmpty) rarity,
                                            if (cardCatalogFinishLabel(
                                              foil,
                                            ).isNotEmpty)
                                              cardCatalogFinishLabel(foil),
                                          ].join(' • '),
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: AppTheme.fontXs,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: AppTheme.space2),
                                      Text(
                                        setName,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppTheme.textPrimary
                                              : AppTheme.textSecondary,
                                          fontSize: AppTheme.fontXs,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (_effectivePrintingMetadata != null) ...[
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        cardEditionFullLabel(_effectivePrintingMetadata!),
                        key: const Key('binder-editor-printing-metadata'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontSm,
                        ),
                      ),
                    ],
                  ] else if (_effectivePrintingMetadata != null) ...[
                    Text(
                      cardEditionFullLabel(_effectivePrintingMetadata!),
                      key: const Key('binder-editor-printing-metadata'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSm,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.space16),
                ],

                // Lista: Tenho / Quero
                const Text(
                  'Lista',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontMd,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: _listType == 'have',
                        label: 'Lista Tenho',
                        child: GestureDetector(
                          key: const Key('binder-editor-list-have'),
                          excludeFromSemantics: true,
                          onTap: () => setState(() => _listType = 'have'),
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: AppTheme.touchTargetMin,
                            ),
                            decoration: BoxDecoration(
                              color: _listType == 'have'
                                  ? AppTheme.primarySoft.withValues(alpha: 0.15)
                                  : AppTheme.surfaceElevated,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(AppTheme.radiusMd),
                              ),
                              border: Border.all(
                                color: _listType == 'have'
                                    ? AppTheme.primarySoft
                                    : AppTheme.outlineMuted,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: 16,
                                  color: _listType == 'have'
                                      ? AppTheme.primarySoft
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: AppTheme.space6),
                                Text(
                                  'Tenho',
                                  style: TextStyle(
                                    color: _listType == 'have'
                                        ? AppTheme.primarySoft
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: _listType == 'want',
                        label: 'Lista Quero',
                        child: GestureDetector(
                          key: const Key('binder-editor-list-want'),
                          excludeFromSemantics: true,
                          onTap: () => setState(() => _listType = 'want'),
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: AppTheme.touchTargetMin,
                            ),
                            decoration: BoxDecoration(
                              color: _listType == 'want'
                                  ? AppTheme.mythicGold.withValues(alpha: 0.15)
                                  : AppTheme.surfaceElevated,
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(AppTheme.radiusMd),
                              ),
                              border: Border.all(
                                color: _listType == 'want'
                                    ? AppTheme.mythicGold
                                    : AppTheme.outlineMuted,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: 16,
                                  color: _listType == 'want'
                                      ? AppTheme.mythicGold
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: AppTheme.space6),
                                Text(
                                  'Quero',
                                  style: TextStyle(
                                    color: _listType == 'want'
                                        ? AppTheme.mythicGold
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space16),

                // Quantidade
                Row(
                  children: [
                    const Text(
                      'Quantidade',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontMd,
                      ),
                    ),
                    const Spacer(),
                    _QuantityButton(
                      key: const Key('binder-editor-quantity-decrement'),
                      icon: Icons.remove,
                      onTap: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Padding(
                      key: const Key('binder-editor-quantity-value'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                      ),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: AppTheme.fontXl,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      key: const Key('binder-editor-quantity-increment'),
                      icon: Icons.add,
                      onTap: () => setState(() => _quantity++),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space16),

                // Condição (chips)
                const Text(
                  'Condição',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontMd,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                Wrap(
                  spacing: 8,
                  children: conditions.map((c) {
                    final selected = _condition == c;
                    return ChoiceChip(
                      key: Key('binder-editor-condition-$c'),
                      label: Text(c),
                      selected: selected,
                      onSelected: (_) => setState(() => _condition = c),
                      selectedColor: AppTheme.brass400.withValues(alpha: 0.22),
                      backgroundColor: AppTheme.surfaceSlate,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppTheme.brass400
                            : AppTheme.textSecondary,
                        fontSize: AppTheme.fontSm,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppTheme.brass400
                            : AppTheme.outlineMuted,
                      ),
                      tooltip: conditionLabels[c],
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.space16),

                // Idioma
                const Text(
                  'Idioma',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontMd,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                Wrap(
                  spacing: 8,
                  children:
                      {
                        ...languages,
                        if (_language.trim().isNotEmpty) _language,
                      }.map((language) {
                        final selected = _language == language;
                        return ChoiceChip(
                          key: Key('binder-editor-language-$language'),
                          label: Text(
                            languageLabels[language] ?? language.toUpperCase(),
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _language = language),
                          selectedColor: AppTheme.brass400.withValues(
                            alpha: 0.22,
                          ),
                          backgroundColor: AppTheme.surfaceSlate,
                          labelStyle: TextStyle(
                            color: selected
                                ? AppTheme.brass400
                                : AppTheme.textSecondary,
                            fontSize: AppTheme.fontSm,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: selected
                                ? AppTheme.brass400
                                : AppTheme.outlineMuted,
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: AppTheme.space16),

                // Foil toggle
                SwitchListTile(
                  key: const Key('binder-editor-foil-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Foil',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  secondary: Icon(
                    Icons.flare_rounded,
                    color: _isFoil
                        ? AppTheme.mythicGold
                        : AppTheme.outlineMuted,
                  ),
                  value: _isFoil,
                  onChanged: (v) => setState(() => _isFoil = v),
                  activeThumbColor: AppTheme.mythicGold,
                ),

                // Para Troca
                SwitchListTile(
                  key: const Key('binder-editor-for-trade-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Disponível para troca',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  secondary: Icon(
                    Icons.swap_horiz,
                    color: _forTrade
                        ? AppTheme.primarySoft
                        : AppTheme.outlineMuted,
                  ),
                  value: _forTrade,
                  onChanged: (v) => setState(() => _forTrade = v),
                  activeThumbColor: AppTheme.primarySoft,
                ),

                // Para Venda
                SwitchListTile(
                  key: const Key('binder-editor-for-sale-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Disponível para venda',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  secondary: Icon(
                    Icons.sell,
                    color: _forSale
                        ? AppTheme.mythicGold
                        : AppTheme.outlineMuted,
                  ),
                  value: _forSale,
                  onChanged: (v) {
                    setState(() {
                      _forSale = v;
                      if (!v) _saveError = null;
                    });
                  },
                  activeThumbColor: AppTheme.mythicGold,
                ),

                // Preço
                if (_forSale) ...[
                  const SizedBox(height: AppTheme.space8),
                  TextField(
                    key: const Key('binder-editor-price-field'),
                    controller: _priceController,
                    focusNode: _priceFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) {
                      if (_saveError != null) {
                        setState(() => _saveError = null);
                      }
                    },
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Preço (R\$)',
                      labelStyle: const TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                      prefixText: 'R\$ ',
                      prefixStyle: const TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(
                          color: AppTheme.outlineMuted,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: AppTheme.brass400),
                      ),
                    ),
                  ),
                ],

                // Notas
                const SizedBox(height: AppTheme.space12),
                TextField(
                  key: const Key('binder-editor-notes-field'),
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Notas (opcional)',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(
                        color: AppTheme.outlineMuted,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(color: AppTheme.brass400),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                if (_saveError != null) ...[
                  Semantics(
                    key: const Key('binder-editor-save-error'),
                    liveRegion: true,
                    container: true,
                    child: Container(
                      key: _saveErrorKey,
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Text(
                        _saveError!,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),
                ],

                // Botões
                Row(
                  children: [
                    if (isEditing)
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('binder-editor-remove-button'),
                          onPressed: _saving ? null : _delete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.space14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remover'),
                        ),
                      ),
                    if (isEditing) const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('binder-editor-save-button'),
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brass500,
                          foregroundColor: AppTheme.backgroundAbyss,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.space14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                key: Key('binder-editor-saving'),
                                width: AppTheme.iconSpinnerSm,
                                height: AppTheme.iconSpinnerSm,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.backgroundAbyss,
                                ),
                              )
                            : Text(isEditing ? 'Salvar' : 'Adicionar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Quantity +/- button
// =====================================================================

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final semanticLabel = icon == Icons.remove
        ? 'Diminuir quantidade'
        : 'Aumentar quantidade';
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(
                color: onTap != null
                    ? AppTheme.brass400
                    : AppTheme.outlineMuted,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              icon,
              size: 18,
              color: onTap != null ? AppTheme.brass400 : AppTheme.outlineMuted,
            ),
          ),
        ),
      ),
    );
  }
}
