import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/card_artwork.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../../cards/widgets/card_edition_metadata.dart';
import '../../community/providers/community_provider.dart';
import '../trade_route_contract.dart';

class TradeMatchesScreen extends StatefulWidget {
  const TradeMatchesScreen({super.key, this.deckId});

  final String? deckId;

  @override
  State<TradeMatchesScreen> createState() => _TradeMatchesScreenState();
}

class _TradeMatchesScreenState extends State<TradeMatchesScreen> {
  CommunityTradeMatchSearchResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    final result = await context
        .read<CommunityProvider>()
        .fetchTradeMatchResult(deckId: widget.deckId);
    if (!mounted) return;
    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  Future<void> _openProposal(CommunityTradeMatch match) async {
    if (!match.isActionable) return;
    await context.push(
      createTradeRouteLocation(
        receiverId: match.ownerId,
        binderItemId: match.binderItemId,
        type: match.proposalType,
        source: match.proposalSource,
        deckId: widget.deckId,
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundAbyss,
        title: const Text('Matches de troca'),
        actions: [
          IconButton(
            key: const Key('trade-matches-open-marketplace'),
            tooltip: 'Abrir Marketplace',
            onPressed: () => context.push(marketplaceRouteLocation),
            icon: const Icon(Icons.storefront_outlined),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppStatePanel.loading(
        key: Key('trade-matches-loading'),
        title: 'Cruzando suas faltantes',
        message:
            'Verificando wishlist, disponibilidade pública e cópias livres para negociar.',
        accent: AppTheme.brass400,
      );
    }

    final result = _result;
    if (result == null || result.failed) {
      return AppStatePanel(
        key: const Key('trade-matches-error'),
        icon: Icons.sync_problem_rounded,
        title: 'Matches temporariamente indisponíveis',
        message:
            result?.error ??
            'Não foi possível consultar as ofertas. Sua lista não foi alterada.',
        accent: AppTheme.error,
        actionLabel: 'Tentar novamente',
        actionKey: const Key('trade-matches-retry'),
        onAction: _load,
      );
    }

    if (result.matches.isEmpty) {
      return AppStatePanel(
        key: const Key('trade-matches-empty'),
        iconWidget: const ManaLoomGlyph(ManaLoomGlyphKind.trade),
        title: 'Nenhum match público agora',
        message: result.message?.trim().isNotEmpty == true
            ? result.message
            : 'Marque cartas na wishlist ou explore ofertas diretamente no Marketplace.',
        accent: AppTheme.brass400,
        actionLabel: 'Explorar Marketplace',
        actionKey: const Key('trade-matches-empty-marketplace'),
        onAction: () => context.push(marketplaceRouteLocation),
      );
    }

    return ResponsivePageFrame(
      key: const Key('trade-matches-content'),
      maxWidth: 1280,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final singleWide =
              result.matches.length == 1 && constraints.maxWidth >= 1040;
          final header = _TradeMatchHeader(
            count: result.matches.length,
            includesDeck: widget.deckId?.trim().isNotEmpty == true,
          );
          Widget matchCard(CommunityTradeMatch match) => _TradeMatchCard(
            match: match,
            onProposal: () => _openProposal(match),
            onOwner: match.ownerId.isEmpty
                ? null
                : () => context.push('/community/user/${match.ownerId}'),
          );

          return RefreshIndicator(
            color: AppTheme.brass400,
            onRefresh: _load,
            child: ListView(
              key: const Key('trade-matches-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                0,
                AppTheme.space20,
                0,
                AppTheme.space32,
              ),
              children: [
                if (singleWide)
                  KeyedSubtree(
                    key: const Key('trade-matches-single-workbench'),
                    child: AdaptiveMasterDetail(
                      masterWidth: 320,
                      breakpoint: 1040,
                      gap: AppTheme.space32,
                      master: header,
                      detail: matchCard(result.matches.single),
                    ),
                  )
                else ...[
                  header,
                  const SizedBox(height: AppTheme.space18),
                  for (
                    var index = 0;
                    index < result.matches.length;
                    index++
                  ) ...[
                    matchCard(result.matches[index]),
                    if (index < result.matches.length - 1)
                      const SizedBox(height: AppTheme.space10),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TradeMatchHeader extends StatelessWidget {
  const _TradeMatchHeader({required this.count, required this.includesDeck});

  final int count;
  final bool includesDeck;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('trade-matches-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          includesDeck
              ? 'Cópias para fechar seu deck'
              : 'Cópias para sua lista',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontFamily: AppTheme.displayFontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTheme.space6),
        Text(
          '$count ${count == 1 ? 'oferta compatível' : 'ofertas compatíveis'} com identidade e disponibilidade verificáveis.',
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.35),
        ),
        const SizedBox(height: AppTheme.space10),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              size: 16,
              color: AppTheme.frost400,
            ),
            SizedBox(width: AppTheme.space6),
            Expanded(
              child: Text(
                'Somente fichários e perfis permitidos aparecem. Localização só é mostrada quando o jogador a tornou pública.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontSm,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TradeMatchCard extends StatelessWidget {
  const _TradeMatchCard({
    required this.match,
    required this.onProposal,
    this.onOwner,
  });

  final CommunityTradeMatch match;
  final VoidCallback onProposal;
  final VoidCallback? onOwner;

  @override
  Widget build(BuildContext context) {
    final item = match.item;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.cardName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontLg,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTheme.space4),
            CardEditionMetadataLine(
              setCode: item.cardSetCode ?? '',
              collectorNumber: item.cardCollectorNumber,
              setName: item.cardSetName,
              setReleaseDate: item.cardSetReleaseDate,
              rarity: item.cardRarity,
              foil: item.isFoil,
              finishContext: CardFinishContext.physicalCopy,
              warning: item.hasPrintingArtwork ? null : 'Arte de referência',
            ),
            const SizedBox(height: AppTheme.space8),
            Wrap(
              spacing: AppTheme.space6,
              runSpacing: AppTheme.space6,
              children: [
                _MatchTag(
                  label: match.sources.contains('deck_missing')
                      ? 'Falta no deck'
                      : 'Wishlist',
                  color: AppTheme.brass400,
                ),
                _MatchTag(label: item.condition, color: AppTheme.frost400),
                _MatchTag(
                  label: item.language.toUpperCase(),
                  color: AppTheme.textSecondary,
                ),
                if (item.isFoil)
                  const _MatchTag(label: 'Foil', color: AppTheme.brass400),
                _MatchTag(
                  label:
                      '${item.availableQuantity} ${item.availableQuantity == 1 ? 'disponível' : 'disponíveis'}',
                  color: AppTheme.success,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space8),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: AppTheme.frost400,
                ),
                const SizedBox(width: AppTheme.space5),
                Flexible(
                  child: TextButton(
                    key: Key('trade-match-owner-${match.ownerId}'),
                    onPressed: onOwner,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.frost400,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, AppTheme.touchTargetMin),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      match.ownerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (match.ownerLocationLabel != null) ...[
                  const SizedBox(width: AppTheme.space8),
                  Flexible(
                    child: Text(
                      match.ownerLocationLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontXs,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              match.freshnessLabel,
              key: Key('trade-match-freshness-${match.binderItemId}'),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontXs,
              ),
            ),
          ],
        );

        final action = Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.end,
          children: [
            if (item.price != null)
              Text(
                CurrencyFormatter.format(
                  item.price!,
                  currencyCode: item.currency,
                ),
                style: const TextStyle(
                  color: AppTheme.brass400,
                  fontSize: AppTheme.fontLg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (item.price != null) const SizedBox(height: AppTheme.space8),
            FilledButton.icon(
              key: Key('trade-match-propose-${match.binderItemId}'),
              onPressed: match.isActionable ? onProposal : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brass500,
                foregroundColor: AppTheme.backgroundAbyss,
              ),
              icon: Icon(
                match.proposalType == 'sale'
                    ? Icons.shopping_cart_outlined
                    : Icons.swap_horiz_rounded,
              ),
              label: Text(
                match.proposalType == 'sale' ? 'Quero comprar' : 'Propor troca',
              ),
            ),
          ],
        );

        return Container(
          key: Key('trade-match-card-${match.binderItemId}'),
          padding: const EdgeInsets.all(AppTheme.space14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.outlineMuted),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TradeMatchArtwork(match: match),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(child: details),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),
                    action,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TradeMatchArtwork(match: match),
                    const SizedBox(width: AppTheme.space14),
                    Expanded(child: details),
                    const SizedBox(width: AppTheme.space18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 180),
                      child: action,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _TradeMatchArtwork extends StatelessWidget {
  const _TradeMatchArtwork({required this.match});

  final CommunityTradeMatch match;

  @override
  Widget build(BuildContext context) {
    final item = match.item;
    return SizedBox(
      width: 72,
      height: 101,
      child: CardArtwork(
        variant: CardArtworkVariant.gallery,
        imageUrl: item.cardPrintingImageUrl,
        fallbackImageUrl: item.cardFallbackImageUrl,
        semanticLabel: item.hasPrintingArtwork
            ? 'Arte da impressão ${item.cardName}'
            : 'Arte de referência de ${item.cardName}',
        constrainAspectRatio: false,
      ),
    );
  }
}

class _MatchTag extends StatelessWidget {
  const _MatchTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space6,
        vertical: AppTheme.space2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
