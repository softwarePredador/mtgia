import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import 'life_counter_route.dart';
import '../auth/providers/auth_provider.dart';
import '../decks/models/deck.dart';
import '../decks/providers/deck_provider.dart';
import '../market/providers/market_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _requestedDeckBootstrap = false;

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context
        .select<AuthProvider, ({String? displayName, String? username})>(
          (a) => (displayName: a.user?.displayName, username: a.user?.username),
        );
    final isDeckLoading = context.select<DeckProvider, bool>(
      (dp) => dp.isLoading,
    );
    final recentDecks = context.select<DeckProvider, List<Deck>>(
      (dp) => dp.decks.take(3).toList(),
    );
    final deckStats = context.select<DeckProvider, ({int total, int formats})>(
      (dp) => (
        total: dp.decks.length,
        formats: dp.decks.map((d) => d.format).toSet().length,
      ),
    );
    final username = auth.displayName ?? auth.username ?? 'Planeswalker';

    return Scaffold(
      backgroundColor: AppTheme.transparent,
      appBar: AppBar(
        backgroundColor: AppTheme.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback:
                  (bounds) => AppTheme.primaryGradient.createShader(bounds),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.textPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ShaderMask(
                shaderCallback:
                    (bounds) => AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  'ManaLoom',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: const [ShellAppBarActions()],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 88,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero / Greeting Banner ───────────────────────────
            _HeroBanner(username: username),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    label: 'Escolha sua intenção',
                    icon: Icons.explore_outlined,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quatro caminhos claros para jogar, construir, colecionar ou negociar sem ruído.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _IntentCard(
                    icon: Icons.favorite,
                    title: 'Jogar agora',
                    subtitle: 'Abrir contador de vida para a mesa.',
                    accentColor: AppTheme.brass500,
                    primary: true,
                    onTap: () => openLifeCounterRoute(context),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _IntentCard(
                          icon: Icons.construction_rounded,
                          title: 'Construir deck',
                          subtitle: 'Criar, importar ou ajustar uma lista.',
                          accentColor: AppTheme.brass500,
                          onTap: () => context.go('/onboarding/core-flow'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _IntentCard(
                          icon: Icons.auto_awesome,
                          title: 'IA de decks',
                          subtitle: 'Gerar e otimizar com revisão.',
                          accentColor: AppTheme.frost400,
                          onTap: () => context.go('/decks/generate'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _IntentCard(
                          icon: Icons.collections_bookmark,
                          title: 'Minha coleção',
                          subtitle: 'Fichário, wishlist e coleções.',
                          accentColor: AppTheme.frost400,
                          onTap: () => context.go('/collection'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _IntentCard(
                          icon: Icons.storefront,
                          title: 'Trocas e mercado',
                          subtitle: 'Marketplace e propostas seguras.',
                          accentColor: AppTheme.brass400,
                          onTap: () => context.go('/collection?tab=1'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Recent Decks
                  if (recentDecks.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionHeader(
                          label: 'Decks Recentes',
                          icon: Icons.style,
                        ),
                        TextButton(
                          onPressed: () => context.go('/decks'),
                          child: const Text('Ver todos'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...recentDecks.map((deck) => _RecentDeckTile(deck: deck)),
                  ] else if (isDeckLoading) ...[
                    const _DecksLoadingState(),
                  ] else ...[
                    // Empty state
                    const _EmptyDecksState(),
                  ],

                  const SizedBox(height: 32),

                  // Stats summary
                  if (deckStats.total > 0) ...[
                    _SectionHeader(label: 'Resumo', icon: Icons.bar_chart),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Decks',
                            value: '${deckStats.total}',
                            icon: Icons.style,
                            color: AppTheme.frost400,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            label: 'Formatos',
                            value: '${deckStats.formats}',
                            icon: Icons.category,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Cotações
                  _MarketPreviewSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final String username;
  const _HeroBanner({required this.username});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        border: const Border(
          bottom: BorderSide(color: AppTheme.outlineMuted, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Teça sua estratégia perfeita',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Decorative mana orb
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brass500.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppTheme.backgroundAbyss,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedWidth;
        final labelText = Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        );

        return Row(
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: AppTheme.frost400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            if (bounded) Flexible(child: labelText) else labelText,
          ],
        );
      },
    );
  }
}

// ── Intent Card ──────────────────────────────────────────────────────────────

class _IntentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool primary;
  final VoidCallback onTap;

  const _IntentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        splashColor: accentColor.withValues(alpha: 0.08),
        highlightColor: accentColor.withValues(alpha: 0.04),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                primary
                    ? AppTheme.brass500.withValues(alpha: 0.12)
                    : AppTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color:
                  primary
                      ? AppTheme.brass500.withValues(alpha: 0.34)
                      : accentColor.withValues(alpha: 0.22),
              width: primary ? 0.9 : 0.6,
            ),
          ),
          child: primary ? _horizontalContent(theme) : _stackedContent(theme),
        ),
      ),
    );
  }

  Widget _accentIcon({required double size, required double iconSize}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: primary ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: accentColor, size: iconSize),
    );
  }

  Widget _titleText(ThemeData theme, {int maxLines = 1}) {
    return Text(
      title,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w800,
        height: 1.12,
      ),
    );
  }

  Widget _subtitleText(ThemeData theme, {int maxLines = 2}) {
    return Text(
      subtitle,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: AppTheme.textSecondary,
        height: 1.25,
      ),
    );
  }

  Widget _chevron() {
    return Icon(
      Icons.chevron_right_rounded,
      color: accentColor.withValues(alpha: 0.78),
      size: 20,
    );
  }

  Widget _horizontalContent(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _accentIcon(size: 40, iconSize: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titleText(theme),
              const SizedBox(height: 3),
              _subtitleText(theme),
            ],
          ),
        ),
        _chevron(),
      ],
    );
  }

  Widget _stackedContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _accentIcon(size: 36, iconSize: 19),
            const Spacer(),
            _chevron(),
          ],
        ),
        const SizedBox(height: 10),
        _titleText(theme, maxLines: 2),
        const SizedBox(height: 4),
        _subtitleText(theme, maxLines: 3),
      ],
    );
  }
}

// ── Recent Deck Tile ─────────────────────────────────────────────────────────

class _RecentDeckTile extends StatelessWidget {
  final Deck deck;
  const _RecentDeckTile({required this.deck});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted, width: 0.5),
      ),
      child: Material(
        color: AppTheme.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () => context.go('/decks/${deck.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    Icons.style,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: AppTheme.fontMd,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        deck.format.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.outlineMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyDecksState extends StatelessWidget {
  const _EmptyDecksState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineMuted, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.frost400.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.style_outlined,
              size: 28,
              color: AppTheme.frost400,
            ),
          ),
          const SizedBox(height: 12),
          Text('Nenhum deck criado ainda', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Comece criando um deck manualmente ou importando uma lista que você já usa.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => context.go('/decks'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Abrir decks'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/decks/import'),
                icon: const Icon(Icons.content_paste_rounded),
                label: const Text('Importar lista'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat Tile ────────────────────────────────────────────────────────────────

class _DecksLoadingState extends StatelessWidget {
  const _DecksLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineMuted, width: 0.5),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Carregando seus decks para montar o resumo da home...',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontMd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Seção de cotações (Market) embutida na Home — mostra top gainers resumido.
class _MarketPreviewSection extends StatefulWidget {
  @override
  State<_MarketPreviewSection> createState() => _MarketPreviewSectionState();
}

class _MarketPreviewSectionState extends State<_MarketPreviewSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MarketProvider>();
      if (provider.moversData == null && !provider.isLoading) {
        provider.fetchMovers(limit: 5);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketProvider>(
      builder: (context, provider, _) {
        final gainers = provider.moversData?.gainers.take(3).toList() ?? [];
        if (gainers.isEmpty && !provider.isLoading) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionHeader(label: 'Cotações', icon: Icons.trending_up),
                TextButton(
                  onPressed: () => context.go('/market'),
                  child: const Text('Ver mais'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (provider.isLoading && gainers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: AppTheme.brass500,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              ...gainers.map((card) {
                final isUp = card.changePct >= 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: AppTheme.outlineMuted,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: AppTheme.fontMd,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${card.priceToday.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontSm,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isUp ? AppTheme.success : AppTheme.error)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXs,
                          ),
                        ),
                        child: Text(
                          '${isUp ? '+' : ''}${card.changePct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isUp ? AppTheme.success : AppTheme.error,
                            fontSize: AppTheme.fontXs,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
