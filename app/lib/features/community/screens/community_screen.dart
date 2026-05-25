import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../providers/community_provider.dart';
import '../../market/models/card_mover.dart';
import '../../market/providers/market_provider.dart';
import '../../social/providers/social_provider.dart';
import '../../social/screens/user_profile_screen.dart';
import 'community_deck_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchPublicDecks(reset: true);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      // Aba "Seguindo": carregar feed
      context.read<SocialProvider>().fetchFollowingFeed(reset: true);
    } else if (_tabController.index == 3) {
      // Aba "Cotações": carregar market movers
      context.read<MarketProvider>().fetchMovers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        title: const Text('Comunidade'),
        backgroundColor: AppTheme.backgroundAbyss,
        surfaceTintColor: AppTheme.transparent,
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontFamily: AppTheme.displayFontFamily,
          fontWeight: FontWeight.w800,
          fontSize: AppTheme.fontLg + 1,
        ),
        actions: const [ShellAppBarActions()],
        bottom: TabBar(
          key: const Key('community-tabs'),
          controller: _tabController,
          dividerColor: AppTheme.transparent,
          indicatorColor: AppTheme.brass400,
          labelColor: AppTheme.brass400,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(
            fontSize: AppTheme.fontMd,
            fontWeight: FontWeight.w700,
          ),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.public, size: 18), text: 'Explorar'),
            Tab(icon: Icon(Icons.people, size: 18), text: 'Seguindo'),
            Tab(icon: Icon(Icons.person_search, size: 18), text: 'Usuários'),
            Tab(icon: Icon(Icons.trending_up, size: 18), text: 'Cotações'),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
        child: TabBarView(
          controller: _tabController,
          children: const [
            _ExploreTab(),
            _FollowingFeedTab(),
            _UserSearchTab(),
            _CotacoesTab(),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// TAB 1: Explorar (decks públicos — antigo conteúdo da CommunityScreen)
// =====================================================================
class _ExploreTab extends StatefulWidget {
  const _ExploreTab();

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedFormat;

  static const _formats = [
    'commander',
    'brawl',
    'standard',
    'modern',
    'pioneer',
    'pauper',
    'legacy',
    'vintage',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CommunityProvider>().fetchPublicDecks();
    }
  }

  void _doSearch() {
    final query = _searchController.text.trim();
    context.read<CommunityProvider>().fetchPublicDecks(
      search: query.isEmpty ? null : query,
      format: _selectedFormat,
      reset: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // Search bar + filters
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          color: AppTheme.transparent,
          child: Column(
            children: [
              TextField(
                key: const Key('community-explore-search-field'),
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Pesquisar decks públicos...',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.brass400,
                  ),
                  suffixIcon: IconButton(
                    key: const Key('community-explore-search-clear-button'),
                    icon: const Icon(
                      Icons.clear,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _doSearch();
                    },
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceSlate.withValues(alpha: 0.94),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: AppTheme.outlineMuted.withValues(alpha: 0.75),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: AppTheme.outlineMuted.withValues(alpha: 0.75),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: AppTheme.brass400.withValues(alpha: 0.8),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _doSearch(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFormatChip(null, 'Todos'),
                    ..._formats.map((f) => _buildFormatChip(f, _capitalize(f))),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Deck list
        Expanded(
          child: Consumer<CommunityProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.decks.isEmpty) {
                return const Center(
                  key: Key('community-explore-loading'),
                  child: CircularProgressIndicator(color: AppTheme.brass400),
                );
              }

              if (provider.errorMessage != null && provider.decks.isEmpty) {
                return Center(
                  key: const Key('community-explore-error'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        key: const Key('community-explore-retry'),
                        onPressed: () => provider.fetchPublicDecks(reset: true),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.decks.isEmpty) {
                return Center(
                  key: const Key('community-explore-empty'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public_off,
                        size: 64,
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhum deck público encontrado',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontLg,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Compartilhe seus decks para aparecerem aqui!',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.7),
                          fontSize: AppTheme.fontMd,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                key: const Key('community-explore-deck-list'),
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  12 + MediaQuery.of(context).padding.bottom + 88,
                ),
                itemCount: provider.decks.length + (provider.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= provider.decks.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: AppTheme.brass400,
                        ),
                      ),
                    );
                  }

                  final deck = provider.decks[index];
                  return _CommunityDeckCard(
                    deck: deck,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    CommunityDeckDetailScreen(deckId: deck.id),
                          ),
                        ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormatChip(String? format, String label) {
    final isSelected = _selectedFormat == format;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        key: Key('community-explore-format-chip-${format ?? 'all'}'),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.backgroundAbyss : AppTheme.textPrimary,
            fontSize: AppTheme.fontSm,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.brass400.withValues(alpha: 0.16),
        backgroundColor: AppTheme.surfaceSlate,
        checkmarkColor: AppTheme.brass400,
        side: BorderSide(
          color:
              isSelected
                  ? AppTheme.brass400.withValues(alpha: 0.65)
                  : AppTheme.outlineMuted,
        ),
        onSelected: (_) {
          setState(() => _selectedFormat = format);
          _doSearch();
        },
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// =====================================================================
// TAB 2: Seguindo (feed de decks dos usuários que sigo)
// =====================================================================
class _FollowingFeedTab extends StatefulWidget {
  const _FollowingFeedTab();

  @override
  State<_FollowingFeedTab> createState() => _FollowingFeedTabState();
}

class _FollowingFeedTabState extends State<_FollowingFeedTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().fetchFollowingFeed(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SocialProvider>().fetchFollowingFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<SocialProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingFeed && provider.followingFeed.isEmpty) {
          return const Center(
            key: Key('community-following-loading'),
            child: CircularProgressIndicator(color: AppTheme.brass400),
          );
        }

        if (provider.feedError != null && provider.followingFeed.isEmpty) {
          return Center(
            key: const Key('community-following-error'),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.feedError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    key: const Key('community-following-retry'),
                    onPressed: () => provider.fetchFollowingFeed(reset: true),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.followingFeed.isEmpty) {
          return Center(
            key: const Key('community-following-empty'),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum deck dos seus seguidos',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontLg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Siga outros jogadores na aba "Usuários" para ver os decks públicos deles aqui!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      fontSize: AppTheme.fontMd,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchFollowingFeed(reset: true),
          color: AppTheme.brass400,
          child: ListView.builder(
            key: const Key('community-following-deck-list'),
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12 + MediaQuery.of(context).padding.bottom + 88,
            ),
            itemCount:
                provider.followingFeed.length + (provider.hasMoreFeed ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.followingFeed.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppTheme.brass400),
                  ),
                );
              }

              final deck = provider.followingFeed[index];
              return _FollowingDeckCard(
                deck: deck,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CommunityDeckDetailScreen(deckId: deck.id),
                      ),
                    ),
              );
            },
          ),
        );
      },
    );
  }
}

// =====================================================================
// TAB 3: Buscar Usuários (inline, sem navegar para outra tela)
// =====================================================================
class _UserSearchTab extends StatefulWidget {
  const _UserSearchTab();

  @override
  State<_UserSearchTab> createState() => _UserSearchTabState();
}

class _UserSearchTabState extends State<_UserSearchTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<SocialProvider>().searchUsers(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          color: AppTheme.transparent,
          child: TextField(
            key: const Key('community-users-search-field'),
            controller: _searchController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Buscar por nick ou nome de usuário...',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              prefixIcon: const Icon(
                Icons.person_search,
                color: AppTheme.brass400,
              ),
              suffixIcon: IconButton(
                key: const Key('community-users-search-clear-button'),
                icon: const Icon(
                  Icons.clear,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                onPressed: () {
                  _searchController.clear();
                  context.read<SocialProvider>().clearSearch();
                },
              ),
              filled: true,
              fillColor: AppTheme.surfaceSlate.withValues(alpha: 0.94),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: AppTheme.outlineMuted.withValues(alpha: 0.75),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: AppTheme.outlineMuted.withValues(alpha: 0.75),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: AppTheme.brass400.withValues(alpha: 0.8),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        // Results
        Expanded(
          child: Consumer<SocialProvider>(
            builder: (context, provider, _) {
              if (provider.isSearching) {
                return const Center(
                  key: Key('community-users-loading'),
                  child: CircularProgressIndicator(color: AppTheme.brass400),
                );
              }

              if (provider.searchError != null) {
                return Center(
                  key: const Key('community-users-error'),
                  child: Text(
                    provider.searchError!,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }

              if (_searchController.text.trim().isEmpty) {
                return Center(
                  key: const Key('community-users-empty-query'),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Encontre outros jogadores',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontLg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Busque pelo nick ou nome de usuário para ver perfis, decks e seguir jogadores.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: AppTheme.fontMd,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (provider.searchResults.isEmpty) {
                return Center(
                  key: const Key('community-users-empty'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nenhum usuário encontrado',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontLg,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                key: const Key('community-users-list'),
                padding: EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  12 + MediaQuery.of(context).padding.bottom + 88,
                ),
                itemCount: provider.searchResults.length,
                itemBuilder: (context, index) {
                  final user = provider.searchResults[index];
                  return _UserCard(
                    user: user,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(userId: user.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Widgets compartilhados
// =====================================================================

class _CommunityDeckCard extends StatelessWidget {
  final CommunityDeck deck;
  final VoidCallback onTap;

  const _CommunityDeckCard({required this.deck, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          key: Key('community-explore-deck-row-${deck.id}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.surfaceSlate.withValues(alpha: 0.98),
                  AppTheme.surfaceElevated.withValues(alpha: 0.62),
                ],
              ),
              border: Border.all(
                color: AppTheme.brass400.withValues(alpha: 0.20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.backgroundAbyss.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                // Commander image
                CachedCardImage(
                  imageUrl: deck.commanderImageUrl,
                  width: 56,
                  height: 78,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontFamily: AppTheme.displayFontFamily,
                          fontWeight: FontWeight.w900,
                          fontSize: AppTheme.fontLg,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: GestureDetector(
                              key:
                                  deck.ownerId != null
                                      ? Key(
                                        'community-explore-deck-owner-${deck.ownerId}',
                                      )
                                      : null,
                              onTap:
                                  deck.ownerId != null
                                      ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => UserProfileScreen(
                                                  userId: deck.ownerId!,
                                                ),
                                          ),
                                        );
                                      }
                                      : null,
                              child: Text(
                                deck.ownerUsername ?? 'Anônimo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      deck.ownerId != null
                                          ? AppTheme.textPrimary.withValues(
                                            alpha: 0.92,
                                          )
                                          : AppTheme.textSecondary.withValues(
                                            alpha: 0.8,
                                          ),
                                  fontSize: AppTheme.fontSm,
                                  fontWeight:
                                      deck.ownerId != null
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _CommunityChip(label: _capitalize(deck.format)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${deck.cardCount} cartas',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontSm,
                            ),
                          ),
                          if (deck.synergyScore != null) ...[
                            const SizedBox(width: 12),
                            _CommunityChip(
                              label: '${deck.synergyScore}%',
                              icon: Icons.auto_awesome,
                              accent: AppTheme.mythicGold,
                            ),
                          ],
                        ],
                      ),
                      if (deck.description != null &&
                          deck.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          deck.description!,
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: AppTheme.fontSm,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary.withValues(alpha: 0.72),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _FollowingDeckCard extends StatelessWidget {
  final PublicDeckSummary deck;
  final VoidCallback onTap;

  const _FollowingDeckCard({required this.deck, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          key: Key('community-following-deck-row-${deck.id}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.surfaceSlate.withValues(alpha: 0.98),
                  AppTheme.surfaceElevated.withValues(alpha: 0.62),
                ],
              ),
              border: Border.all(
                color: AppTheme.frost400.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                CachedCardImage(
                  imageUrl: deck.commanderImageUrl,
                  width: 56,
                  height: 78,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontFamily: AppTheme.displayFontFamily,
                          fontWeight: FontWeight.w900,
                          fontSize: AppTheme.fontLg,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _CommunityChip(label: _capitalize(deck.format)),
                          const SizedBox(width: 8),
                          Text(
                            '${deck.cardCount} cartas',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontSm,
                            ),
                          ),
                          if (deck.synergyScore != null) ...[
                            const SizedBox(width: 8),
                            _CommunityChip(
                              label: '${deck.synergyScore}%',
                              icon: Icons.auto_awesome,
                              accent: AppTheme.mythicGold,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary.withValues(alpha: 0.72),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _CommunityChip extends StatelessWidget {
  const _CommunityChip({
    required this.label,
    this.icon,
    this.accent = AppTheme.brass400,
  });

  final String label;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: accent),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: AppTheme.fontXs,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final PublicUser user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          key: Key('community-users-row-${user.id}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: AppTheme.outlineMuted.withValues(alpha: 0.62),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.brass500.withValues(alpha: 0.14),
                  backgroundImage:
                      user.avatarUrl != null
                          ? CachedNetworkImageProvider(user.avatarUrl!)
                          : null,
                  child:
                      user.avatarUrl == null
                          ? Text(
                            user.username[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.brass400,
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.fontXl,
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? user.username,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontFamily: AppTheme.displayFontFamily,
                          fontWeight: FontWeight.w900,
                          fontSize: AppTheme.fontMd,
                        ),
                      ),
                      if (user.displayName != null)
                        _CommunityChip(
                          label: '@${user.username}',
                          accent: AppTheme.frost400,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.style,
                            size: 13,
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.72,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user.publicDeckCount} decks',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontSm,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.people,
                            size: 13,
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.72,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user.followerCount} seguidores',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontSm,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
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

// =====================================================================
// TAB 4: Cotações (Market Movers — variações de preço diárias)
// =====================================================================
class _CotacoesTab extends StatefulWidget {
  const _CotacoesTab();

  @override
  State<_CotacoesTab> createState() => _CotacoesTabState();
}

class _CotacoesTabState extends State<_CotacoesTab>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _subTabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().fetchMovers();
    });
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<MarketProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.moversData == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.brass400),
                SizedBox(height: 16),
                Text(
                  'Carregando cotações...',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        if (provider.errorMessage != null && provider.moversData == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage ?? 'Erro desconhecido',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brass500,
                      foregroundColor: AppTheme.backgroundAbyss,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = provider.moversData;
        if (data == null) {
          return const Center(
            child: Text(
              'Sem dados de mercado',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        if (data.needsMoreData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.hourglass_top,
                    size: 48,
                    color: AppTheme.brass400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data.message ?? 'Aguardando dados...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontMd,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Os preços são atualizados diariamente.\nAmanhã teremos dados de variação!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSm,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Header com datas + info
            _buildDateHeader(data, provider),
            // Sub-tabs Valorizando / Desvalorizando
            Container(
              color: AppTheme.backgroundAbyss,
              child: TabBar(
                controller: _subTabController,
                indicatorColor: AppTheme.brass400,
                labelColor: AppTheme.brass400,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.arrow_upward, size: 16),
                    text: 'Valorizando',
                  ),
                  Tab(
                    icon: Icon(Icons.arrow_downward, size: 16),
                    text: 'Desvalorizando',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _subTabController,
                children: [
                  data.gainers.isEmpty
                      ? const Center(
                        child: Text(
                          'Nenhuma carta valorizou hoje',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                      : _buildMoversList(
                        data.gainers,
                        isGainer: true,
                        provider: provider,
                      ),
                  data.losers.isEmpty
                      ? const Center(
                        child: Text(
                          'Nenhuma carta desvalorizou hoje',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                      : _buildMoversList(
                        data.losers,
                        isGainer: false,
                        provider: provider,
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(MarketMoversData data, MarketProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            size: 14,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            data.date != null ? _formatDate(data.date!) : 'Hoje',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontMd,
            ),
          ),
          if (data.previousDate != null) ...[
            const Text(
              ' vs ',
              style: TextStyle(
                color: AppTheme.outlineMuted,
                fontSize: AppTheme.fontSm,
              ),
            ),
            Text(
              _formatDate(data.previousDate!),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontMd,
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: AppTheme.brass400.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              '${data.totalTracked} cartas',
              style: const TextStyle(
                color: AppTheme.brass400,
                fontSize: AppTheme.fontSm,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: provider.isLoading ? null : () => provider.refresh(),
            child: Icon(
              Icons.refresh,
              size: 20,
              color:
                  provider.isLoading
                      ? AppTheme.outlineMuted
                      : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoversList(
    List<CardMover> movers, {
    required bool isGainer,
    required MarketProvider provider,
  }) {
    return RefreshIndicator(
      color: AppTheme.brass400,
      backgroundColor: AppTheme.surfaceSlate,
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          0,
          8,
          0,
          8 + MediaQuery.of(context).padding.bottom + 88,
        ),
        itemCount: movers.length,
        itemBuilder: (context, index) {
          final mover = movers[index];
          final changeColor = isGainer ? AppTheme.success : AppTheme.error;
          final changeIcon =
              isGainer ? Icons.arrow_upward : Icons.arrow_downward;
          final changePrefix = isGainer ? '+' : '';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color:
                    index < 3
                        ? AppTheme.outlineMuted.withValues(alpha: 0.45)
                        : AppTheme.outlineMuted.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color:
                          index < 3
                              ? AppTheme.surfaceElevated
                              : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border:
                          index < 3
                              ? Border.all(
                                color: changeColor.withValues(alpha: 0.2),
                              )
                              : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color:
                            index < 3
                                ? AppTheme.textPrimary.withValues(alpha: 0.9)
                                : AppTheme.textSecondary,
                        fontSize: AppTheme.fontSm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Card image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: SizedBox(
                      width: 36,
                      height: 50,
                      child:
                          mover.imageUrl != null
                              ? CachedNetworkImage(
                                imageUrl: mover.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder:
                                    (_, __) => Container(
                                      color: AppTheme.surfaceElevated,
                                      child: const Icon(
                                        Icons.style,
                                        size: 16,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                errorWidget:
                                    (_, __, ___) => Container(
                                      color: AppTheme.surfaceElevated,
                                      child: const Icon(
                                        Icons.style,
                                        size: 16,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                              )
                              : Container(
                                color: AppTheme.surfaceElevated,
                                child: const Icon(
                                  Icons.style,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name + details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mover.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: AppTheme.fontMd,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (mover.setCode != null)
                              Text(
                                mover.setCode!.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.fontSm,
                                ),
                              ),
                            if (mover.rarity != null) ...[
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  color: AppTheme.outlineMuted,
                                  fontSize: AppTheme.fontSm,
                                ),
                              ),
                              Text(
                                _rarityLabel(mover.rarity!),
                                style: TextStyle(
                                  color: _rarityColor(
                                    mover.rarity!,
                                  ).withValues(alpha: 0.82),
                                  fontSize: AppTheme.fontSm,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Price + change
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${mover.priceToday.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: AppTheme.fontLg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          border: Border.all(
                            color: changeColor.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(changeIcon, size: 12, color: changeColor),
                            const SizedBox(width: 2),
                            Text(
                              '$changePrefix${mover.changePct.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: changeColor,
                                fontSize: AppTheme.fontSm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$changePrefix\$${mover.changeUsd.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.78),
                          fontSize: AppTheme.fontXs,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final parts = isoDate.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {
      return isoDate;
    }
  }

  String _rarityLabel(String rarity) {
    return switch (rarity.toLowerCase()) {
      'mythic' => 'Mítica',
      'rare' => 'Rara',
      'uncommon' => 'Incomum',
      'common' => 'Comum',
      _ => rarity,
    };
  }

  Color _rarityColor(String rarity) {
    return switch (rarity.toLowerCase()) {
      'mythic' => AppTheme.mythicGold,
      'rare' => AppTheme.mythicGold.withValues(alpha: 0.7),
      'uncommon' => AppTheme.primarySoft,
      _ => AppTheme.textSecondary,
    };
  }
}
