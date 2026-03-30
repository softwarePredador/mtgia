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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback:
                  (bounds) => AppTheme.primaryGradient.createShader(bounds),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback:
                  (bounds) => AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                'ManaLoom',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: const [ShellAppBarActions()],
      ),
      body: SingleChildScrollView(
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
                  // Quick Actions
                  _SectionHeader(label: 'Ações Rápidas', icon: Icons.bolt),
                  const SizedBox(height: 12),

                  // CTA principal com gradiente
                  _GradientButton(
                    icon: Icons.auto_awesome,
                    label: 'Criar e otimizar deck',
                    gradient: AppTheme.primaryGradient,
                    glowColor: AppTheme.manaViolet,
                    onTap: () => context.go('/onboarding/core-flow'),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add_rounded,
                          label: 'Novo Deck',
                          accentColor: AppTheme.primarySoft,
                          highlighted: true,
                          onTap: () => context.go('/decks'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.content_paste,
                          label: 'Importar lista',
                          accentColor: AppTheme.primarySoft,
                          highlighted: true,
                          onTap: () => context.go('/decks/import'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.auto_awesome,
                          label: 'Gerar com IA',
                          accentColor: AppTheme.primarySoft,
                          highlighted: true,
                          onTap: () => context.go('/decks/generate'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.collections_bookmark,
                          label: 'Minha Coleção',
                          accentColor: AppTheme.textSecondary,
                          onTap: () => context.go('/collection'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.favorite,
                          label: 'Vida',
                          accentColor: AppTheme.textSecondary,
                          onTap: () => context.push(lifeCounterRoutePath),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.store,
                          label: 'Marketplace',
                          accentColor: AppTheme.textSecondary,
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
                            color: AppTheme.primarySoft,
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
                  color: AppTheme.manaViolet.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
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
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primarySoft,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Gradient CTA Button ──────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _GradientButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: AppTheme.fontLg,
                    letterSpacing: 0.2,
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

// ── Quick Action ─────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool highlighted;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.accentColor,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        splashColor: accentColor.withValues(alpha: 0.08),
        highlightColor: accentColor.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color:
                highlighted
                    ? AppTheme.primarySoft.withValues(alpha: 0.05)
                    : AppTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color:
                  highlighted
                      ? AppTheme.primarySoft.withValues(alpha: 0.24)
                      : AppTheme.outlineMuted,
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      highlighted
                          ? accentColor.withValues(alpha: 0.14)
                          : AppTheme.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        highlighted
                            ? accentColor.withValues(alpha: 0.18)
                            : AppTheme.outlineMuted.withValues(alpha: 0.55),
                  ),
                ),
                child: Icon(
                  icon,
                  color: highlighted ? accentColor : AppTheme.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
        color: Colors.transparent,
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
              color: AppTheme.primarySoft.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.style_outlined,
              size: 28,
              color: AppTheme.primarySoft,
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
                    color: AppTheme.manaViolet,
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
