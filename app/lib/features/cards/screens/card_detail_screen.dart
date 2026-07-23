import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/mana_helper.dart';
import '../../../core/widgets/card_artwork.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/mana_symbols.dart';
import '../../decks/models/deck_card_item.dart';
import '../providers/card_provider.dart';
import '../widgets/card_edition_metadata.dart';

String cardDetailRouteLocation(String cardId) =>
    '/cards/${Uri.encodeComponent(cardId)}';

Future<void> openCardDetailRoute(
  BuildContext context,
  DeckCardItem card,
) async {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    await router.push<void>(cardDetailRouteLocation(card.id), extra: card);
    return;
  }
  if (!context.mounted) return;
  await Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)));
}

class CardDetailRouteScreen extends StatefulWidget {
  const CardDetailRouteScreen({
    super.key,
    required this.cardId,
    this.initialCard,
  });

  final String cardId;
  final DeckCardItem? initialCard;

  @override
  State<CardDetailRouteScreen> createState() => _CardDetailRouteScreenState();
}

class _CardDetailRouteScreenState extends State<CardDetailRouteScreen> {
  DeckCardItem? _card;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _card = widget.initialCard?.id == widget.cardId ? widget.initialCard : null;
    if (_card == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void didUpdateWidget(covariant CardDetailRouteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cardId == widget.cardId &&
        oldWidget.initialCard == widget.initialCard) {
      return;
    }
    _card = widget.initialCard?.id == widget.cardId ? widget.initialCard : null;
    _hasError = false;
    if (_card == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _hasError = false);
    try {
      final card = await context.read<CardProvider>().fetchCardById(
        widget.cardId,
      );
      if (!mounted || widget.cardId != card.id) return;
      setState(() => _card = card);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  void _goBack() {
    final router = GoRouter.maybeOf(context);
    if (router?.canPop() == true) {
      router!.pop();
      return;
    }
    if (router != null) {
      router.go('/collection');
      return;
    }
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    if (card != null) return CardDetailScreen(card: card);

    return Scaffold(
      key: const Key('card-detail-route-state'),
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Detalhes da carta'),
      ),
      body: !_hasError
          ? const AppStatePanel.loading(
              title: 'Carregando carta',
              message: 'Buscando os dados canônicos desta impressão.',
              accent: AppTheme.brass400,
            )
          : AppStatePanel(
              icon: Icons.style_outlined,
              title: 'Carta indisponível',
              message:
                  'Não foi possível carregar esta impressão agora. Verifique a conexão e tente novamente.',
              accent: AppTheme.warning,
              actionLabel: 'Tentar novamente',
              onAction: _load,
            ),
    );
  }
}

class CardDetailScreen extends StatelessWidget {
  final DeckCardItem card;

  static const double _desktopBreakpoint = 900;
  static const double _tabletBreakpoint = 560;
  static const double _desktopCardMaxWidth = 400;
  static const double _stackedCardMaxWidth = 420;
  static const double _contentMaxWidth = 1120;
  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            backgroundColor: AppTheme.backgroundAbyss,
            title: Text(
              card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              tooltip: 'Voltar',
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: () {
                final router = GoRouter.maybeOf(context);
                if (router?.canPop() == true) {
                  router!.pop();
                } else if (router != null) {
                  router.go('/collection');
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          SliverToBoxAdapter(child: _buildResponsiveContent(context, theme)),
        ],
      ),
    );
  }

  Widget _buildResponsiveContent(BuildContext context, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _desktopBreakpoint) {
          final imageWidth = (constraints.maxWidth * 0.34).clamp(
            320.0,
            _desktopCardMaxWidth,
          );

          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space32,
              AppTheme.space28,
              AppTheme.space32,
              AppTheme.space48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: imageWidth,
                      child: _buildCardImage(context, roundedAllCorners: true),
                    ),
                    const SizedBox(width: AppTheme.space36),
                    Expanded(
                      child: _buildCardInformation(
                        theme,
                        padding: const EdgeInsets.only(top: AppTheme.space4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final centerCard = constraints.maxWidth >= _tabletBreakpoint;
        final image = centerCard
            ? Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space24,
                  AppTheme.space24,
                  AppTheme.space24,
                  AppTheme.space0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _stackedCardMaxWidth,
                    ),
                    child: _buildCardImage(context, roundedAllCorners: true),
                  ),
                ),
              )
            : _buildCardImage(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            image,
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: _buildCardInformation(theme),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardInformation(
    ThemeData theme, {
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(
      AppTheme.space20,
      AppTheme.space20,
      AppTheme.space20,
      AppTheme.space32,
    ),
  }) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: AppTheme.space20),
          _buildDivider(),
          const SizedBox(height: AppTheme.space16),
          _buildOracleText(theme),
          const SizedBox(height: AppTheme.space16),
          _buildDivider(),
          const SizedBox(height: AppTheme.space16),
          _buildDetailsGrid(theme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card image (tappable for fullscreen)
  // ---------------------------------------------------------------------------
  Widget _buildCardImage(
    BuildContext context, {
    bool roundedAllCorners = false,
  }) {
    final imageUrl = card.effectiveImageUrl;
    final borderRadius = roundedAllCorners
        ? BorderRadius.circular(AppTheme.radiusLg)
        : const BorderRadius.only(
            bottomLeft: Radius.circular(AppTheme.radiusLg),
            bottomRight: Radius.circular(AppTheme.radiusLg),
          );

    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final imageFrame = Material(
      color: AppTheme.transparent,
      child: InkWell(
        key: const Key('card-detail-image-frame'),
        onTap: hasImage ? () => _showFullscreenImage(context) : null,
        borderRadius: borderRadius,
        child: hasImage
            ? CardArtwork(
                variant: CardArtworkVariant.fullCard,
                imageUrl: imageUrl,
                semanticLabel: 'Imagem completa da carta ${card.name}',
                borderRadius: borderRadius,
              )
            : AspectRatio(
                aspectRatio: CardArtworkSpec.mtgCardAspectRatio,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSlate,
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: AppTheme.outlineMuted.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.style,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(height: AppTheme.space8),
                        Text(
                          'Sem imagem',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontMd,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );

    if (!hasImage) return imageFrame;
    return Semantics(
      button: true,
      label: 'Ampliar imagem de ${card.name}',
      child: Tooltip(message: 'Ampliar imagem', child: imageFrame),
    );
  }

  void _showFullscreenImage(BuildContext context) {
    final imageUrl = card.effectiveImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: AppTheme.backgroundAbyss.withValues(alpha: 0.94),
      builder: (_) => Semantics(
        button: true,
        label: 'Fechar imagem da carta',
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Dialog(
            backgroundColor: AppTheme.transparent,
            insetPadding: const EdgeInsets.all(AppTheme.space16),
            child: InteractiveViewer(
              child: CardArtwork(
                variant: CardArtworkVariant.fullCard,
                imageUrl: imageUrl,
                semanticLabel: 'Imagem ampliada da carta ${card.name}',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header: name + mana cost + type line
  // ---------------------------------------------------------------------------
  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                card.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (card.manaCost != null && card.manaCost!.isNotEmpty) ...[
              const SizedBox(width: AppTheme.space12),
              _buildManaCostWidget(card.manaCost!),
            ],
          ],
        ),
        const SizedBox(height: AppTheme.space6),
        // Type line
        Text(
          card.typeLine,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mana cost symbols
  // ---------------------------------------------------------------------------
  Widget _buildManaCostWidget(String manaCost) {
    return ManaCostRow(cost: manaCost, symbolSize: 22, spacing: 3);
  }

  // ---------------------------------------------------------------------------
  // Oracle text
  // ---------------------------------------------------------------------------
  Widget _buildOracleText(ThemeData theme) {
    final hasText = card.oracleText != null && card.oracleText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Texto de Regras',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.primarySoft,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.space10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.space14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.outlineMuted.withValues(alpha: 0.4),
            ),
          ),
          child: hasText
              ? OracleTextWidget(card.oracleText!)
              : Text(
                  'Sem texto de regras',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Details grid
  // ---------------------------------------------------------------------------
  Widget _buildDetailsGrid(ThemeData theme) {
    final cmc = ManaHelper.calculateCMC(card.manaCost);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalhes',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.primarySoft,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space14,
            vertical: AppTheme.space12,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.outlineMuted.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              _detailRow(
                theme,
                icon: Icons.collections_bookmark,
                label: 'Set',
                value: card.setName ?? card.setCode,
              ),
              _detailDivider(),
              _detailRowWithWidget(
                theme,
                icon: Icons.grade_outlined,
                label: 'Raridade',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _rarityColor(card.rarity),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space6),
                    Text(
                      _capitalizeRarity(card.rarity),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _detailDivider(),
              if (card.setCode.trim().isNotEmpty) ...[
                _detailRow(
                  theme,
                  icon: Icons.confirmation_number_outlined,
                  label: 'Código',
                  value: cardEditionCodeLabel(
                    setCode: card.setCode,
                    collectorNumber: card.collectorNumber,
                  ),
                ),
                _detailDivider(),
              ],
              if ((card.setReleaseDate ?? '').trim().isNotEmpty) ...[
                _detailRow(
                  theme,
                  icon: Icons.event_outlined,
                  label: 'Lançamento',
                  value: card.setReleaseDate!.trim(),
                ),
                _detailDivider(),
              ],
              if (card.foil != null) ...[
                _detailRow(
                  theme,
                  icon: Icons.flare_rounded,
                  label: 'Acabamento',
                  value: cardFoilLabel(card.foil),
                ),
                _detailDivider(),
              ],
              _detailRowWithWidget(
                theme,
                icon: Icons.palette,
                label: 'Cores',
                child: _buildColorBadges(),
              ),
              _detailDivider(),
              _detailRow(
                theme,
                icon: Icons.speed,
                label: 'CMC',
                value: cmc.toString(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return _adaptiveDetailRow(
      theme,
      icon: icon,
      label: label,
      value: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.end,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _detailRowWithWidget(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return _adaptiveDetailRow(theme, icon: icon, label: label, value: child);
  }

  Widget _adaptiveDetailRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Widget value,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledBody = MediaQuery.textScalerOf(
          context,
        ).scale(AppTheme.fontMd);
        final stackValue =
            constraints.maxWidth < 320 || scaledBody >= AppTheme.fontXxl;
        final labelRow = Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: AppTheme.space10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
          child: stackValue
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    labelRow,
                    const SizedBox(height: AppTheme.space6),
                    Align(alignment: Alignment.centerRight, child: value),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: labelRow),
                    const SizedBox(width: AppTheme.space12),
                    Flexible(child: value),
                  ],
                ),
        );
      },
    );
  }

  Widget _detailDivider() {
    return Divider(
      height: 1,
      color: AppTheme.outlineMuted.withValues(alpha: 0.3),
    );
  }

  // ---------------------------------------------------------------------------
  // Color identity badges
  // ---------------------------------------------------------------------------
  Widget _buildColorBadges() {
    // Prefer colorIdentity (full commander identity) over colors (cast colors),
    // falling back to colors when identity data is absent.
    final identityColors = card.colorIdentity.isNotEmpty
        ? card.colorIdentity
        : card.colors;

    return ColorIdentityPips(
      colors: identityColors,
      symbolSize: 24,
      spacing: 4,
      decorated: false,
      colorlessWhenEmpty: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Divider helper
  // ---------------------------------------------------------------------------
  Widget _buildDivider() {
    return Divider(
      color: AppTheme.outlineMuted.withValues(alpha: 0.4),
      height: 1,
    );
  }

  // ---------------------------------------------------------------------------
  // Rarity helpers
  // ---------------------------------------------------------------------------
  Color _rarityColor(String rarity) {
    return AppTheme.rarityColor(rarity);
  }

  String _capitalizeRarity(String rarity) {
    if (rarity.isEmpty) return rarity;
    return rarity[0].toUpperCase() + rarity.substring(1);
  }
}
