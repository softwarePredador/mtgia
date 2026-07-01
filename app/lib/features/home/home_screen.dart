import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/cached_card_image.dart';
import 'life_counter_route.dart';
import '../decks/models/deck.dart';
import '../decks/providers/deck_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _requestedDeckBootstrap = false;
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    final recentDecks = decks.take(4).toList();

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
              16,
              26,
              16,
              MediaQuery.of(context).padding.bottom + 96,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HomeHeader(),
                const SizedBox(height: 12),
                const _HomeHero(),
                const SizedBox(height: 16),
                const _SectionHeader(label: 'Acesso rápido'),
                const SizedBox(height: 10),
                const _QuickActions(),
                const SizedBox(height: 18),
                _SectionHeader(
                  label: 'Decks recentes',
                  trailing: TextButton(
                    onPressed: () => context.go('/decks'),
                    child: const Text('Ver todos'),
                  ),
                ),
                const SizedBox(height: 10),
                if (recentDecks.isNotEmpty)
                  _RecentDecksRail(decks: recentDecks)
                else if (isDeckLoading)
                  const _DecksLoadingState()
                else
                  const _EmptyDecksState(),
                const SizedBox(height: 18),
                _SectionHeader(
                  label: 'Atividade recente',
                  trailing: TextButton(
                    onPressed: () => context.go('/notifications'),
                    child: const Text('Ver tudo'),
                  ),
                ),
                const SizedBox(height: 8),
                _RecentActivity(deckCount: decks.length),
              ],
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
      height: 48,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.menu_rounded),
              color: AppTheme.textSecondary,
              tooltip: 'Menu',
            ),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.brass400,
                      size: 22,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'ManaLoom',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.brass400,
                        fontWeight: FontWeight.w900,
                        fontSize: AppTheme.fontXl + 4,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 112,
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
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      key: const Key('home-hero-frame'),
      child: Container(
        height: 190,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.backgroundAbyss,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.brass500.withValues(alpha: 0.42)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.backgroundAbyss.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/branding/home_hero_banner.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.backgroundAbyss.withValues(alpha: 0.18),
                      AppTheme.backgroundAbyss.withValues(alpha: 0.02),
                      AppTheme.transparent,
                    ],
                    stops: const [0.0, 0.52, 1],
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
                      letterSpacing: -0.45,
                    ),
                  ),
                  const SizedBox(height: 9),
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
                    height: 36,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.brass400,
                        foregroundColor: AppTheme.backgroundAbyss,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        textStyle: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: AppTheme.fontSm,
                        ),
                      ),
                      onPressed: () => openLifeCounterRoute(context),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('Jogar agora'),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 17),
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
          width: 3,
          height: AppTheme.iconSpinnerSm,
          decoration: BoxDecoration(
            color: AppTheme.frost400,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: AppTheme.fontXl + 1,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.favorite_rounded,
        title: 'Jogar agora',
        subtitle: 'Abrir contador de vida',
        accent: AppTheme.brass400,
        onTap: () => openLifeCounterRoute(context),
      ),
      _QuickActionData(
        icon: Icons.construction_rounded,
        title: 'Construir deck',
        subtitle: 'Criar, importar ou ajustar',
        accent: AppTheme.brass500,
        onTap: () => context.go('/onboarding/core-flow'),
      ),
      _QuickActionData(
        icon: Icons.collections_bookmark_rounded,
        title: 'Meus Decks',
        subtitle: 'Ver e gerenciar seus decks',
        accent: AppTheme.frost400,
        onTap: () => context.go('/decks'),
      ),
      _QuickActionData(
        icon: Icons.public_rounded,
        title: 'Coleção',
        subtitle: 'Suas cartas e coleções',
        accent: AppTheme.frost400,
        onTap: () => context.go('/collection'),
      ),
      _QuickActionData(
        icon: Icons.storefront_rounded,
        title: 'Trocas',
        subtitle: 'Marketplace e propostas',
        accent: AppTheme.brass500,
        onTap: () => context.go('/collection?tab=1'),
      ),
    ];

    return SizedBox(
      height: 108,
      child: Row(
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(child: _QuickActionCard(data: actions[index])),
          ],
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.outlineMuted.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.backgroundAbyss.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 32,
                decoration: BoxDecoration(
                  color: data.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: data.accent.withValues(alpha: 0.18),
                    width: AppTheme.strokeThin,
                  ),
                ),
                child: Icon(data.icon, color: data.accent, size: 18),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Center(
                  child: Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: AppTheme.fontXs,
                      height: 1.06,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontMicro - 0.5,
                  height: 1.08,
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
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: decks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
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
    final age = _relativeTime(deck.createdAt);

    return SizedBox(
      width: 86,
      child: Material(
        color: AppTheme.transparent,
        child: InkWell(
          onTap: () => context.go('/decks/${deck.id}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          splashColor: AppTheme.brass400.withValues(alpha: 0.08),
          highlightColor: AppTheme.brass400.withValues(alpha: 0.04),
          child: Ink(
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: frameColor.withValues(alpha: 0.74)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.backgroundAbyss.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _DeckArtwork(deck: deck),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.backgroundAbyss.withValues(alpha: 0.06),
                          AppTheme.backgroundAbyss.withValues(alpha: 0.07),
                          AppTheme.surfaceSlate.withValues(alpha: 0.93),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: AppTheme.touchTargetMin,
                        height: AppTheme.touchTargetMin,
                      ),
                      onPressed: () => context.go('/decks/${deck.id}'),
                      icon: const Icon(Icons.more_vert_rounded),
                      color: AppTheme.textSecondary,
                      tooltip: 'Ações do deck',
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
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
                            fontSize: AppTheme.fontSm - 1,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatLabel(deck.format),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontTiny,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _ManaPips(identity: deck.colorIdentity),
                            const Spacer(),
                            Text(
                              '${deck.cardCount}/$target',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: AppTheme.fontTiny,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
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
                        const SizedBox(height: 5),
                        Text(
                          age,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textHint,
                            fontSize: AppTheme.fontTiny,
                            height: 1.05,
                          ),
                        ),
                      ],
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
}

class _DeckArtwork extends StatelessWidget {
  final Deck deck;

  const _DeckArtwork({required this.deck});

  @override
  Widget build(BuildContext context) {
    final imageUrl = deck.commanderImageUrl;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return CachedCardImage(imageUrl: imageUrl, fit: BoxFit.cover);
    }
    return _DeckFallback(deck: deck);
  }
}

class _DeckFallback extends StatelessWidget {
  final Deck deck;

  const _DeckFallback({required this.deck});

  @override
  Widget build(BuildContext context) {
    final initial = deck.name.trim().isEmpty ? '?' : deck.name.trim()[0];
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
        Align(
          alignment: const Alignment(0, -0.12),
          child: Text(
            initial.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              color: AppTheme.textPrimary.withValues(alpha: 0.33),
              fontSize: AppTheme.fontDisplay * 2.125,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ManaPips extends StatelessWidget {
  final List<String> identity;

  const _ManaPips({required this.identity});

  @override
  Widget build(BuildContext context) {
    final symbols = identity.isEmpty ? const ['C'] : identity;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          symbols.take(5).map((symbol) {
            final normalized = symbol.toUpperCase();
            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.manaPipBackground(normalized),
                shape: BoxShape.circle,
              ),
              child: Text(
                normalized,
                style: TextStyle(
                  color: AppTheme.manaPipForeground(normalized),
                  fontSize: AppTheme.fontMicro - 2.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _EmptyDecksState extends StatelessWidget {
  const _EmptyDecksState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.brass400,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Você ainda não tem decks',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: AppTheme.fontLg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crie seu primeiro deck e comece sua jornada em Magic.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
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

class _DecksLoadingState extends StatelessWidget {
  const _DecksLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(width: 16),
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

class _RecentActivity extends StatelessWidget {
  final int deckCount;

  const _RecentActivity({required this.deckCount});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActivityData(
        icon: Icons.shopping_cart_outlined,
        color: AppTheme.brass500,
        title: 'Nova proposta recebida',
        subtitle: 'JohnDoe fez uma proposta pelo deck “lorehold”',
        trailing: '2h atrás',
      ),
      _ActivityData(
        icon: Icons.collections_bookmark_outlined,
        color: AppTheme.frost400,
        title: deckCount > 0 ? 'Deck finalizado' : 'Decks prontos para criar',
        subtitle:
            deckCount > 0
                ? '“simic tempo” foi marcado como completo'
                : 'Use Criar novo deck ou Gerar com IA.',
        trailing: '5h atrás',
      ),
      _ActivityData(
        icon: Icons.cloud_upload_outlined,
        color: AppTheme.frost400,
        title: 'Lista importada',
        subtitle: '“minha lista.txt” importada com sucesso',
        trailing: '1d atrás',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _ActivityRow(data: items[i]),
            if (i != items.length - 1)
              const Divider(height: 1, color: AppTheme.outlineMuted),
          ],
        ],
      ),
    );
  }
}

class _ActivityData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String trailing;

  const _ActivityData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
}

class _ActivityRow extends StatelessWidget {
  final _ActivityData data;

  const _ActivityRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: data.color.withValues(alpha: 0.16),
                width: AppTheme.strokeThin,
              ),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: AppTheme.fontSm + 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontXs,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            data.trailing,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textHint,
              fontSize: AppTheme.fontXs,
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

String _relativeTime(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inMinutes < 1) return 'Atualizado agora';
  if (difference.inHours < 1) {
    return 'Atualizado há ${math.max(1, difference.inMinutes)}min';
  }
  if (difference.inDays < 1) return 'Atualizado há ${difference.inHours}h';
  return 'Atualizado há ${difference.inDays}d';
}
