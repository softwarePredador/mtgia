import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:provider/provider.dart';

import '../../core/config/visual_fixture.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/scryfall_image_helper.dart';
import '../../core/widgets/card_artwork.dart';
import '../../core/widgets/mana_symbols.dart';
import '../../core/widgets/manaloom_glyph.dart';
import 'life_counter_route.dart';
import '../decks/models/deck.dart';
import '../decks/providers/deck_provider.dart';

class HomeScreen extends StatefulWidget {
  final bool? lifeCounterAvailable;

  const HomeScreen({super.key, this.lifeCounterAvailable});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _requestedDeckBootstrap = false;
  bool _introStarted = false;
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_introStarted) {
      _introStarted = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        _introController.value = 1;
      } else {
        _introController.forward();
      }
    }
    if (_requestedDeckBootstrap) {
      return;
    }

    _requestedDeckBootstrap = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<DeckProvider>();
      if (provider.decks.isEmpty && !provider.isLoading) {
        provider.fetchDecks();
      }
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDeckLoading = context.select<DeckProvider, bool>(
      (dp) => dp.isLoading,
    );
    final decks = context.select<DeckProvider, List<Deck>>(
      (dp) => dp.decks.toList(),
    );
    final deckError = context.select<DeckProvider, String?>(
      (dp) => dp.errorMessage,
    );
    final deckStatusCode = context.select<DeckProvider, int?>(
      (dp) => dp.listStatusCode,
    );
    final recentDecks = decks.take(4).toList();
    final lifeCounterAvailable = widget.lifeCounterAvailable ?? true;

    return Scaffold(
      backgroundColor: AppTheme.transparent,
      body: SafeArea(
        top: false,
        bottom: false,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _introController,
            curve: Curves.easeOutCubic,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppTheme.space16,
              26,
              AppTheme.space16,
              MediaQuery.of(context).padding.bottom + 96,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HomeHeader(),
                    const SizedBox(height: AppTheme.space12),
                    _HomeHero(lifeCounterAvailable: lifeCounterAvailable),
                    const SizedBox(height: AppTheme.space16),
                    const _SectionHeader(label: 'Acesso rápido'),
                    const SizedBox(height: AppTheme.space10),
                    _QuickActions(lifeCounterAvailable: lifeCounterAvailable),
                    const SizedBox(height: AppTheme.space18),
                    _SectionHeader(
                      label: 'Decks recentes',
                      trailing: TextButton(
                        onPressed: () => context.go('/decks'),
                        child: const Text('Ver todos'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space10),
                    if (deckStatusCode == 401)
                      const _DecksSessionExpiredState()
                    else if (recentDecks.isNotEmpty)
                      Column(
                        children: [
                          if (isDeckLoading) ...[
                            const _CachedDecksStatus(
                              isLoading: true,
                              message: 'Atualizando seus decks...',
                            ),
                            const SizedBox(height: AppTheme.space8),
                          ] else if (deckError != null) ...[
                            _CachedDecksStatus(
                              isLoading: false,
                              message: deckError,
                            ),
                            const SizedBox(height: AppTheme.space8),
                          ],
                          _RecentDecksRail(decks: recentDecks),
                        ],
                      )
                    else if (isDeckLoading)
                      const _DecksLoadingState()
                    else if (deckError != null)
                      _DecksErrorState(message: deckError)
                    else
                      const _EmptyDecksState(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: AppTheme.space48,
      child: Row(
        children: [
          SizedBox(
            width: AppTheme.space48,
            child: IconButton(
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.account_circle_outlined),
              color: AppTheme.textSecondary,
              tooltip: 'Perfil',
            ),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ManaLoomGlyph(
                      ManaLoomGlyphKind.brand,
                      color: AppTheme.brass400,
                      size: 22,
                    ),
                    const SizedBox(width: AppTheme.space7),
                    Text(
                      'ManaLoom',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.brass400,
                        fontWeight: FontWeight.w900,
                        fontSize: AppTheme.fontXl + 4,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            width: AppTheme.space112,
            child: Align(
              alignment: Alignment.centerRight,
              child: ShellAppBarActions(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  final bool lifeCounterAvailable;

  const _HomeHero({required this.lifeCounterAvailable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionLabel = lifeCounterAvailable ? 'Jogar agora' : 'Montar deck';
    final wideArtwork = MediaQuery.sizeOf(context).width >= 840;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final heroHeight = textScale >= 1.5 ? 280.0 : 190.0;
    final artworkSize = wideArtwork ? 680.0 : 430.0;
    final artworkOverflow = (artworkSize - heroHeight) / 2;
    return RepaintBoundary(
      key: const Key('home-hero-frame'),
      child: Container(
        key: const Key('home-hero-surface'),
        height: heroHeight,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.backgroundAbyss,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppTheme.backgroundAbyss.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        // The frame is painted above the artwork. A border in [decoration]
        // sits behind the child and can disappear at clipped corners.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: AppTheme.brass500.withValues(alpha: 0.5),
            width: AppTheme.strokeThin,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: wideArtwork ? -10 : -34,
              top: -artworkOverflow,
              bottom: -artworkOverflow,
              width: artworkSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/branding/home_hero.png',
                    key: const Key('home-hero-artwork'),
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppTheme.backgroundAbyss,
                          AppTheme.transparent,
                        ],
                        stops: [0, 0.32],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.backgroundAbyss,
                      AppTheme.backgroundAbyss.withValues(alpha: 0.98),
                      AppTheme.backgroundAbyss.withValues(alpha: 0.7),
                      AppTheme.transparent,
                    ],
                    stops: const [0.0, 0.24, 0.5, 0.78],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 24,
              bottom: 20,
              width: 194,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá,\nPlaneswalker',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: AppTheme.fontDisplay - 8,
                      height: 1.03,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space9),
                  Text(
                    'Sua próxima jogada começa aqui.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSm,
                      height: 1.32,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 122,
                    height: AppTheme.touchTargetMin,
                    child: FilledButton(
                      key: const Key('home-primary-action'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.brass400,
                        foregroundColor: AppTheme.backgroundAbyss,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space18,
                        ),
                        textStyle: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: AppTheme.fontSm,
                        ),
                      ),
                      onPressed: lifeCounterAvailable
                          ? () => openLifeCounterRoute(context)
                          : () => context.go('/onboarding/core-flow'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(actionLabel),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          const Icon(Icons.arrow_forward_rounded, size: 17),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SectionHeader({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 2,
          height: AppTheme.iconSpinnerSm,
          decoration: BoxDecoration(
            color: AppTheme.brass500,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: AppTheme.fontXl,
              letterSpacing: 0,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool lifeCounterAvailable;

  const _QuickActions({required this.lifeCounterAvailable});

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (lifeCounterAvailable)
        _QuickActionData(
          glyph: ManaLoomGlyphKind.lifeCounter,
          title: 'Jogar agora',
          accent: AppTheme.brass400,
          onTap: () => openLifeCounterRoute(context),
        )
      else
        _QuickActionData(
          icon: Icons.groups_outlined,
          title: 'Comunidade',
          accent: AppTheme.brass400,
          onTap: () => context.go('/community'),
        ),
      _QuickActionData(
        glyph: ManaLoomGlyphKind.deck,
        title: 'Construir deck',
        accent: AppTheme.brass500,
        onTap: () => context.go('/onboarding/core-flow'),
      ),
      _QuickActionData(
        glyph: ManaLoomGlyphKind.deck,
        title: 'Meus Decks',
        accent: AppTheme.textSecondary,
        onTap: () => context.go('/decks'),
      ),
      _QuickActionData(
        glyph: ManaLoomGlyphKind.collection,
        title: 'Coleção',
        accent: AppTheme.textSecondary,
        onTap: () => context.go('/collection'),
      ),
      _QuickActionData(
        glyph: ManaLoomGlyphKind.trade,
        title: 'Trocas',
        accent: AppTheme.brass500,
        onTap: () => context.go('/collection?tab=2'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            key: const Key('home-quick-actions-list'),
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const SizedBox(width: AppTheme.space10),
                Expanded(child: _QuickActionCard(data: actions[index])),
              ],
            ],
          );
        }

        return SizedBox(
          height: AppTheme.space72,
          child: ListView.separated(
            key: const Key('home-quick-actions-list'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppTheme.space10),
            itemBuilder: (context, index) => SizedBox(
              width: 136,
              child: _QuickActionCard(data: actions[index]),
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionData {
  final ManaLoomGlyphKind? glyph;
  final IconData? icon;
  final String title;
  final Color accent;
  final VoidCallback onTap;

  const _QuickActionData({
    this.glyph,
    this.icon,
    required this.title,
    required this.accent,
    required this.onTap,
  }) : assert(
         (glyph == null) != (icon == null),
         'Provide exactly one of glyph or icon.',
       );
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        splashColor: data.accent.withValues(alpha: 0.08),
        highlightColor: data.accent.withValues(alpha: 0.04),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space10,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.outlineMuted.withValues(alpha: 0.55),
              width: AppTheme.strokeHairline,
            ),
          ),
          child: Row(
            children: [
              if (data.glyph != null)
                ManaLoomGlyph(data.glyph!, color: data.accent, size: 21)
              else
                Icon(data.icon, color: data.accent, size: 21),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: AppTheme.fontSm,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDecksRail extends StatelessWidget {
  final List<Deck> decks;

  const _RecentDecksRail({required this.decks});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 144,
      child: ListView.separated(
        key: const Key('home-recent-decks-rail'),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space2,
          AppTheme.space4,
          AppTheme.space2,
          AppTheme.space12,
        ),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: decks.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppTheme.space12),
        itemBuilder: (context, index) => _RecentDeckCard(deck: decks[index]),
      ),
    );
  }
}

class _RecentDeckCard extends StatelessWidget {
  final Deck deck;

  const _RecentDeckCard({required this.deck});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = _deckTarget(deck.format);
    final ratio = (deck.cardCount / target).clamp(0.0, 1.0);
    final frameColor = ratio >= 1 ? AppTheme.brass500 : AppTheme.outlineMuted;
    final age = _createdTime(deck.createdAt);
    final commanderName = deck.commanderName?.trim();

    return SizedBox(
      key: Key('home-recent-deck-${deck.id}'),
      width: 244,
      child: Material(
        color: AppTheme.surfaceSlate,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(
            color: frameColor.withValues(alpha: 0.74),
            width: AppTheme.strokeThin,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/decks/${deck.id}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          splashColor: AppTheme.brass400.withValues(alpha: 0.08),
          highlightColor: AppTheme.brass400.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space8),
            child: Row(
              children: [
                ClipRRect(
                  key: Key('home-recent-deck-art-${deck.id}'),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: SizedBox(
                    width: AppTheme.space72,
                    height: 102,
                    child: _DeckArtwork(deck: deck),
                  ),
                ),
                const SizedBox(width: AppTheme.space10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space0,
                      AppTheme.space3,
                      AppTheme.space3,
                      AppTheme.space2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: AppTheme.fontSm,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space3),
                        Text(
                          commanderName == null || commanderName.isEmpty
                              ? _formatLabel(deck.format)
                              : commanderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontXs,
                            height: 1.1,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatLabel(deck.format),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.fontXs,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _ManaPips(
                              identity: deck.colorIdentity,
                              identityKnown: deck.colorIdentityKnown,
                            ),
                            const SizedBox(width: AppTheme.space6),
                            Text(
                              '${deck.cardCount}/$target',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: AppTheme.fontXs,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            value: ratio,
                            backgroundColor: AppTheme.outlineMuted,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ratio >= 1
                                  ? AppTheme.brass400
                                  : AppTheme.frost400,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space5),
                        Text(
                          age,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textHint,
                            fontSize: AppTheme.fontMicro,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
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

class _DeckArtwork extends StatelessWidget {
  final Deck deck;

  const _DeckArtwork({required this.deck});

  @override
  Widget build(BuildContext context) {
    final imageUrl = deck.commanderImageUrl;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return CardArtwork(
        variant: CardArtworkVariant.recentDeck,
        imageUrl: imageUrl,
        fallbackImageUrl: ScryfallImageHelper.namedImageUrl(deck.commanderName),
        semanticLabel: 'Carta do comandante ${deck.commanderName ?? deck.name}',
        constrainAspectRatio: false,
      );
    }
    return _DeckFallback(deck: deck);
  }
}

class _DeckFallback extends StatelessWidget {
  final Deck deck;

  const _DeckFallback({required this.deck});

  @override
  Widget build(BuildContext context) {
    final identity = deck.colorIdentity.toSet();
    final accent = AppTheme.identityColor(identity);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.34),
                AppTheme.surfaceElevated,
                AppTheme.backgroundAbyss,
              ],
            ),
          ),
        ),
        ManaLoomGlyph(
          ManaLoomGlyphKind.deck,
          color: AppTheme.textPrimary.withValues(alpha: 0.26),
          size: 34,
        ),
      ],
    );
  }
}

class _ManaPips extends StatelessWidget {
  final List<String> identity;
  final bool identityKnown;

  const _ManaPips({required this.identity, required this.identityKnown});

  @override
  Widget build(BuildContext context) {
    if (identity.isEmpty && !identityKnown) {
      return const Tooltip(
        message: 'Identidade de cor pendente',
        child: Icon(
          Icons.help_outline_rounded,
          size: 13,
          color: AppTheme.textHint,
        ),
      );
    }
    return ColorIdentityPips(
      colors: identity,
      symbolSize: 12,
      spacing: 2,
      decorated: false,
      colorlessWhenEmpty: identityKnown,
    );
  }
}

class _EmptyDecksState extends StatelessWidget {
  const _EmptyDecksState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('home-decks-empty-state'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space14,
        AppTheme.space14,
        AppTheme.space14,
        AppTheme.space14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.brass500.withValues(alpha: 0.34)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.brass400.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: AppTheme.brass400.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brass400.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const ManaLoomGlyph(
              ManaLoomGlyphKind.deck,
              color: AppTheme.brass400,
              size: 28,
            ),
          ),
          const SizedBox(height: AppTheme.space10),
          Text(
            'Você ainda não tem decks',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: AppTheme.fontLg,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Crie seu primeiro deck e comece sua jornada em Magic.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/decks'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar novo deck'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecksErrorState extends StatelessWidget {
  const _DecksErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('home-decks-error-state'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.42)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppTheme.error, size: 28),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Não foi possível carregar seus decks',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.onErrorContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          OutlinedButton.icon(
            key: const Key('home-decks-retry'),
            onPressed: () => context.read<DeckProvider>().fetchDecks(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _DecksSessionExpiredState extends StatelessWidget {
  const _DecksSessionExpiredState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('home-decks-session-expired-state'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.brass500.withValues(alpha: 0.52)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            color: AppTheme.brass400,
            size: 28,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Sua sessão expirou',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Entre novamente para recarregar seus decks com segurança.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          FilledButton.icon(
            key: const Key('home-decks-login-again'),
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Entrar novamente'),
          ),
        ],
      ),
    );
  }
}

class _CachedDecksStatus extends StatelessWidget {
  const _CachedDecksStatus({required this.isLoading, required this.message});

  final bool isLoading;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key(
        isLoading
            ? 'home-decks-cache-refreshing-state'
            : 'home-decks-cached-read-only-state',
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: AppTheme.space18,
              height: AppTheme.space18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.cloud_off_rounded,
              size: AppTheme.space18,
              color: AppTheme.brass400,
            ),
          const SizedBox(width: AppTheme.space10),
          Expanded(
            child: Text(
              isLoading ? message : 'Mostrando decks salvos. $message',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          if (!isLoading)
            IconButton(
              key: const Key('home-decks-cache-retry'),
              onPressed: () => context.read<DeckProvider>().fetchDecks(),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Tentar novamente',
              color: AppTheme.brass400,
            ),
        ],
      ),
    );
  }
}

class _DecksLoadingState extends StatelessWidget {
  const _DecksLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home-decks-loading-state'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: AppTheme.space24,
            height: AppTheme.space24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(width: AppTheme.space16),
          Expanded(
            child: Text(
              'Carregando seus decks...',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

int _deckTarget(String format) {
  final normalized = format.toLowerCase();
  if (normalized.contains('commander') || normalized.contains('brawl')) {
    return 100;
  }
  return 60;
}

String _formatLabel(String format) {
  final normalized = format.toLowerCase();
  if (normalized.contains('commander')) return 'Commander';
  if (normalized.contains('standard') || normalized.contains('padr')) {
    return 'Padrão';
  }
  if (normalized.isEmpty) return 'Deck';
  return format[0].toUpperCase() + format.substring(1);
}

String _createdTime(DateTime date) {
  if (manaloomVisualFixtureMode) return 'Criado agora';
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inMinutes < 1) return 'Criado agora';
  if (difference.inHours < 1) {
    return 'Criado há ${math.max(1, difference.inMinutes)}min';
  }
  if (difference.inDays < 1) return 'Criado há ${difference.inHours}h';
  return 'Criado há ${difference.inDays}d';
}
