import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/product_identity.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../../../core/widgets/manaloom_theme_motif.dart';
import '../../../core/widgets/player_identity_name.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../../binder/providers/binder_provider.dart';
import '../../messages/providers/message_provider.dart';
import '../../trades/screens/create_trade_screen.dart';
import '../../trades/trade_route_contract.dart';
import '../providers/social_provider.dart';
import '../widgets/social_report_dialog.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Listener para mudanças de aba (swipe ou tap)
    _tabController.addListener(_onTabChange);
    // Carregar perfil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().fetchUserProfile(widget.userId);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    // Só carrega quando a animação termina (evita chamadas duplicadas)
    if (!_tabController.indexIsChanging) {
      _loadTab(_tabController.index);
    }
  }

  Future<void> _toggleFollow() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);

    final provider = context.read<SocialProvider>();
    var ok = true;
    if (provider.isFollowingVisited) {
      ok = await provider.unfollowUser(widget.userId);
    } else {
      ok = await provider.followUser(widget.userId);
    }

    if (!mounted) return;
    setState(() => _isToggling = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar follow')),
      );
    }
  }

  Future<void> _openChat(String userId) async {
    final msgProvider = context.read<MessageProvider>();
    final conv = await msgProvider.getOrCreateConversation(userId);
    if (!mounted) return;
    if (conv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir a conversa agora. Tente novamente.',
          ),
        ),
      );
      return;
    }

    context.push('/messages/${conv.id}', extra: conv.otherUser);
  }

  Future<void> _reportProfile() async {
    final draft = await showSocialReportDialog(context, targetLabel: 'perfil');
    if (draft == null || !mounted) return;
    final ok = await context.read<SocialProvider>().reportContent(
      targetType: 'profile',
      targetId: widget.userId,
      reason: draft.reason,
      details: draft.details,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Denúncia registrada.' : 'Não foi possível enviar a denúncia.',
        ),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  Future<void> _blockProfile() async {
    final user = context.read<SocialProvider>().visitedUser;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('user-profile-block-confirmation-dialog'),
        title: const Text('Bloquear jogador?'),
        content: Text(
          'Você e ${user.displayLabel} deixarão de interagir por mensagens, '
          'comunidade e novas trocas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('user-profile-block-confirm-button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<SocialProvider>().blockUser(widget.userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Jogador bloqueado.' : 'Não foi possível bloquear o jogador.',
        ),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
    if (ok) context.pop();
  }

  void _loadTab(int index) {
    final provider = context.read<SocialProvider>();
    if (index == 1) {
      provider.fetchFollowers(widget.userId, reset: true);
    } else if (index == 2) {
      provider.fetchFollowing(widget.userId, reset: true);
    } else if (index == 3) {
      context.read<BinderProvider>().fetchPublicBinder(
        widget.userId,
        reset: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppTheme.backgroundAbyss,
        actions: [
          Consumer<SocialProvider>(
            builder: (context, provider, _) {
              if (provider.isOwnProfile != false) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                key: const Key('user-profile-safety-menu'),
                tooltip: 'Opções de segurança',
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'report') {
                    _reportProfile();
                  } else if (value == 'block') {
                    _blockProfile();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'report',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.flag_outlined),
                      title: Text('Denunciar perfil'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.block_outlined),
                      title: Text('Bloquear jogador'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<SocialProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingProfile) {
            return const AppStatePanel.loading(
              key: Key('user-profile-loading'),
              title: 'Carregando perfil',
              message: 'Buscando dados públicos deste jogador.',
              accent: AppTheme.brass500,
            );
          }

          if (provider.profileError != null) {
            return AppStatePanel(
              key: const Key('user-profile-error'),
              status: AppStateStatus.error,
              icon: Icons.person_off_outlined,
              title: 'Perfil indisponível',
              message: provider.profileError!,
              accent: AppTheme.error,
              actionLabel: 'Tentar novamente',
              actionKey: const Key('user-profile-retry-button'),
              onAction: () => provider.fetchUserProfile(widget.userId),
            );
          }

          final user = provider.visitedUser;
          if (user == null) {
            return const AppStatePanel(
              key: Key('user-profile-unavailable'),
              status: AppStateStatus.unavailable,
              icon: Icons.person_search_outlined,
              title: 'Perfil não encontrado',
              message: 'Este jogador não está disponível para consulta.',
              accent: AppTheme.frost400,
            );
          }

          final compactTabs =
              MediaQuery.sizeOf(context).width < AppTheme.breakpointCompact;
          return ResponsivePageFrame(
            maxWidth: 1440,
            padding: EdgeInsets.fromLTRB(
              compactTabs ? AppTheme.space16 : AppTheme.space24,
              AppTheme.space16,
              compactTabs ? AppTheme.space16 : AppTheme.space24,
              AppTheme.space12,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1000;
                final identity = _buildPublicIdentity(
                  provider,
                  user,
                  compact: !wide,
                );
                final workspace = _buildPublicWorkspace(
                  provider,
                  compactTabs: compactTabs,
                );

                return KeyedSubtree(
                  key: const Key('user-profile-content'),
                  child: wide
                      ? Row(
                          key: const Key('user-profile-wide-workbench'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: AppTheme.identityRailWidth,
                              child: identity,
                            ),
                            const SizedBox(width: AppTheme.space24),
                            Expanded(child: workspace),
                          ],
                        )
                      : Column(
                          key: const Key('user-profile-stacked-workbench'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            identity,
                            const SizedBox(height: AppTheme.space12),
                            Expanded(child: workspace),
                          ],
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPublicIdentity(
    SocialProvider provider,
    PublicUser user, {
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final avatar = CircleAvatar(
      radius: compact ? 38 : 48,
      backgroundColor: AppTheme.brass400.withValues(alpha: 0.16),
      backgroundImage: user.avatarUrl != null
          ? CachedNetworkImageProvider(user.avatarUrl!)
          : null,
      child: user.avatarUrl == null
          ? Text(
              user.username.isEmpty ? '?' : user.username[0].toUpperCase(),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppTheme.brass400,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
    final identityCopy = Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerIdentityName(
          key: const Key('user-profile-identity-name'),
          name: user.displayName ?? user.username,
          textAlign: compact ? TextAlign.start : TextAlign.center,
          semanticPrefix: 'Nome público do jogador',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontFamily: AppTheme.displayFontFamily,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        Text(
          '@${user.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.frost400,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (user.createdAt != null) ...[
          const SizedBox(height: AppTheme.space5),
          Text(
            'No ${ProductIdentity.displayName} desde ${user.createdAt!.year}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );

    return ManaLoomThemeMotif(
      variant: ManaLoomMotifVariant.cardWeave,
      intensity: 0.70,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        key: const Key('user-profile-identity-rail'),
        padding: EdgeInsets.all(compact ? AppTheme.space16 : AppTheme.space20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSlate.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.22)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'IDENTIDADE PÚBLICA',
                textAlign: compact ? TextAlign.start : TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.brass400,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppTheme.space14),
              if (compact)
                Row(
                  children: [
                    avatar,
                    const SizedBox(width: AppTheme.space14),
                    Expanded(child: identityCopy),
                  ],
                )
              else ...[
                Center(child: avatar),
                const SizedBox(height: AppTheme.space14),
                identityCopy,
              ],
              const SizedBox(height: AppTheme.space18),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'Decks',
                      value: user.publicDeckCount,
                      icon: Icons.style_outlined,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Seguidores',
                      value: user.followerCount,
                      icon: Icons.people_outline,
                      onTap: () {
                        _tabController.animateTo(1);
                        _loadTab(1);
                      },
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Seguindo',
                      value: user.followingCount,
                      icon: Icons.person_add_outlined,
                      onTap: () {
                        _tabController.animateTo(2);
                        _loadTab(2);
                      },
                    ),
                  ),
                ],
              ),
              if (provider.isOwnProfile != true) ...[
                const SizedBox(height: AppTheme.space18),
                _buildProfileActions(provider, compact: compact),
              ],
              if (!compact && provider.visitedUserDecks.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.space20),
                  child: Divider(height: 1),
                ),
                Text(
                  'DECK EM DESTAQUE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: AppTheme.space10),
                _FeaturedPublicDeck(deck: provider.visitedUserDecks.first),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileActions(
    SocialProvider provider, {
    required bool compact,
  }) {
    final follow = FilledButton.icon(
      key: const Key('user-profile-follow-button'),
      onPressed: _isToggling ? null : _toggleFollow,
      style: FilledButton.styleFrom(
        backgroundColor: provider.isFollowingVisited
            ? AppTheme.surfaceElevated
            : AppTheme.brass500,
        foregroundColor: provider.isFollowingVisited
            ? AppTheme.brass400
            : AppTheme.backgroundAbyss,
      ),
      icon: _isToggling
          ? const SizedBox(
              width: AppTheme.space16,
              height: AppTheme.space16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              provider.isFollowingVisited
                  ? Icons.person_remove_outlined
                  : Icons.person_add_outlined,
              size: 18,
            ),
      label: Text(provider.isFollowingVisited ? 'Deixar de seguir' : 'Seguir'),
    );
    final message = OutlinedButton.icon(
      key: const Key('user-profile-message-button'),
      onPressed: () => _openChat(widget.userId),
      icon: const Icon(Icons.chat_bubble_outline, size: 18),
      label: const Text('Mensagem'),
    );

    if (compact) {
      return Wrap(
        spacing: AppTheme.space10,
        runSpacing: AppTheme.space10,
        children: [follow, message],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        follow,
        const SizedBox(height: AppTheme.space8),
        message,
      ],
    );
  }

  Widget _buildPublicWorkspace(
    SocialProvider provider, {
    required bool compactTabs,
  }) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('user-profile-workspace'),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.outlineMuted.withValues(alpha: 0.76)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space4,
              AppTheme.space16,
              AppTheme.space4,
              AppTheme.space12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MESA PÚBLICA',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.brass400,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        'Decks, comunidade e cartas disponíveis',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontFamily: AppTheme.displayFontFamily,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            key: const Key('user-profile-tabs'),
            controller: _tabController,
            isScrollable: compactTabs,
            tabAlignment: compactTabs ? TabAlignment.start : TabAlignment.fill,
            labelPadding: EdgeInsets.symmetric(
              horizontal: compactTabs ? AppTheme.space10 : AppTheme.space8,
            ),
            indicatorColor: AppTheme.brass400,
            labelColor: AppTheme.brass400,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(text: 'Decks (${provider.visitedUserDecks.length})'),
              const Tab(text: 'Seguidores'),
              const Tab(text: 'Seguindo'),
              const Tab(text: 'Fichário'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DecksTab(decks: provider.visitedUserDecks),
                _UsersListTab(
                  users: provider.followers,
                  isLoading: provider.isLoadingFollowers,
                  errorMessage: provider.followersError,
                  emptyMessage: 'Nenhum seguidor ainda',
                  hasMore: provider.hasMoreFollowers,
                  onLoadMore: () => provider.fetchFollowers(widget.userId),
                ),
                _UsersListTab(
                  users: provider.following,
                  isLoading: provider.isLoadingFollowing,
                  errorMessage: provider.followingError,
                  emptyMessage: 'Não segue ninguém ainda',
                  hasMore: provider.hasMoreFollowing,
                  onLoadMore: () => provider.fetchFollowing(widget.userId),
                ),
                _PublicBinderTabHaveWant(userId: widget.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Stat Widget
// =====================================================================

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primarySoft, size: 20),
          const SizedBox(height: AppTheme.space4),
          Text(
            '$value',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.fontXl,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSm,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Decks Tab
// =====================================================================

class _FeaturedPublicDeck extends StatelessWidget {
  const _FeaturedPublicDeck({required this.deck});

  final PublicDeckSummary deck;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        key: const Key('user-profile-featured-deck'),
        onTap: () => context.push('/community/decks/${deck.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space10),
          child: Row(
            children: [
              CachedCardImage(
                imageUrl: deck.commanderImageUrl,
                width: 62,
                height: 86,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (deck.commanderName != null) ...[
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        deck.commanderName!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Abrir deck  →',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.brass400,
                        fontWeight: FontWeight.w800,
                      ),
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
}

class _DecksTab extends StatelessWidget {
  final List<PublicDeckSummary> decks;

  const _DecksTab({required this.decks});

  @override
  Widget build(BuildContext context) {
    if (decks.isEmpty) {
      return const AppStatePanel(
        key: Key('user-profile-decks-empty'),
        status: AppStateStatus.firstUse,
        icon: Icons.style_outlined,
        title: 'Nenhum deck público por enquanto',
        message:
            'Quando este jogador publicar um deck, as cartas e o comandante aparecem aqui.',
        accent: AppTheme.brass400,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= 760;
        if (useGrid) {
          return GridView.builder(
            key: const Key('user-profile-decks-grid'),
            padding: const EdgeInsets.all(AppTheme.space16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 430,
              mainAxisExtent: 126,
              crossAxisSpacing: AppTheme.space12,
              mainAxisSpacing: AppTheme.space12,
            ),
            itemCount: decks.length,
            itemBuilder: (context, index) =>
                _PublicDeckTile(deck: decks[index]),
          );
        }

        return ListView.separated(
          key: const Key('user-profile-decks-list'),
          padding: const EdgeInsets.all(AppTheme.space12),
          itemCount: decks.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppTheme.space10),
          itemBuilder: (context, index) => _PublicDeckTile(deck: decks[index]),
        );
      },
    );
  }
}

class _PublicDeckTile extends StatelessWidget {
  const _PublicDeckTile({required this.deck});

  final PublicDeckSummary deck;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceSlate.withValues(alpha: 0.82),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: AppTheme.outlineMuted.withValues(alpha: 0.78),
          width: AppTheme.strokeHairline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/community/decks/${deck.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Row(
            children: [
              CachedCardImage(
                imageUrl: deck.commanderImageUrl,
                width: 66,
                height: 92,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: AppTheme.fontMd,
                      ),
                    ),
                    if (deck.commanderName != null) ...[
                      const SizedBox(height: AppTheme.space3),
                      Text(
                        deck.commanderName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontSm,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.space8),
                    Wrap(
                      spacing: AppTheme.space8,
                      runSpacing: AppTheme.space4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _capitalize(deck.format),
                          style: const TextStyle(
                            color: AppTheme.manaViolet,
                            fontSize: AppTheme.fontXs,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${deck.cardCount} cartas',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontSm,
                          ),
                        ),
                        if (deck.synergyScore != null)
                          Text(
                            'Sinergia ${deck.synergyScore}%',
                            style: TextStyle(
                              color: AppTheme.mythicGold.withValues(alpha: 0.9),
                              fontSize: AppTheme.fontSm,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                color: AppTheme.brass400,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

// =====================================================================
// Users List Tab (Followers / Following)
// =====================================================================

class _UsersListTab extends StatefulWidget {
  final List<PublicUser> users;
  final bool isLoading;
  final String? errorMessage;
  final String emptyMessage;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  const _UsersListTab({
    required this.users,
    required this.isLoading,
    this.errorMessage,
    required this.emptyMessage,
    this.hasMore = false,
    this.onLoadMore,
  });

  @override
  State<_UsersListTab> createState() => _UsersListTabState();
}

class _UsersListTabState extends State<_UsersListTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      if (widget.hasMore && !widget.isLoading) {
        widget.onLoadMore?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.manaViolet),
      );
    }

    if (widget.errorMessage != null && widget.users.isEmpty) {
      return AppStatePanel(
        key: const Key('user-profile-connections-error'),
        status: AppStateStatus.error,
        icon: Icons.cloud_off_outlined,
        title: 'Conexões não carregadas',
        message: widget.errorMessage!,
        accent: AppTheme.error,
        actionLabel: widget.onLoadMore == null ? null : 'Tentar novamente',
        onAction: widget.onLoadMore,
      );
    }

    if (widget.users.isEmpty) {
      return AppStatePanel(
        key: const Key('user-profile-connections-empty'),
        status: AppStateStatus.firstUse,
        icon: Icons.people_outline,
        title: widget.emptyMessage,
        message: 'Novas conexões públicas aparecerão nesta área.',
        accent: AppTheme.frost400,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.space12),
      itemCount: widget.users.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.users.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.space16),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.manaViolet),
            ),
          );
        }
        final user = widget.users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.space8),
          color: AppTheme.surfaceSlate,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: const BorderSide(
              color: AppTheme.outlineMuted,
              width: AppTheme.strokeHairline,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.manaViolet.withValues(alpha: 0.3),
              backgroundImage: user.avatarUrl != null
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.manaViolet,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              user.displayName ?? user.username,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '@${user.username}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSm,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
            onTap: () => context.push('/community/user/${user.id}'),
          ),
        );
      },
    );
  }
}

// =====================================================================
// Public Binder Tab — Have/Want sub-tabs + interaction buttons
// =====================================================================

class _PublicBinderTabHaveWant extends StatefulWidget {
  final String userId;

  const _PublicBinderTabHaveWant({required this.userId});

  @override
  State<_PublicBinderTabHaveWant> createState() =>
      _PublicBinderTabHaveWantState();
}

class _PublicBinderTabHaveWantState extends State<_PublicBinderTabHaveWant>
    with TickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    _subTabController.addListener(() {
      if (!_subTabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.backgroundAbyss,
          child: TabBar(
            controller: _subTabController,
            indicatorColor: AppTheme.brass400,
            labelColor: AppTheme.brass400,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: AppTheme.fontMd,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.inventory_2, size: 16),
                text: 'Tem',
                height: 48,
              ),
              Tab(
                icon: Icon(Icons.favorite_border, size: 16),
                text: 'Quer',
                height: 48,
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _PublicBinderListView(userId: widget.userId, listType: 'have'),
              _PublicBinderListView(userId: widget.userId, listType: 'want'),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Public Binder list for a single list_type
// =====================================================================

class _PublicBinderListView extends StatefulWidget {
  final String userId;
  final String listType;

  const _PublicBinderListView({required this.userId, required this.listType});

  @override
  State<_PublicBinderListView> createState() => _PublicBinderListViewState();
}

class _PublicBinderListViewState extends State<_PublicBinderListView>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  List<BinderItem> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  bool _retryShouldReset = false;
  int _page = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch(reset: true));
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
      if (_hasMore && !_isLoading) _fetch();
    }
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_isLoading) return;
    if (!reset && !_hasMore) return;
    if (reset) {
      _page = 1;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      if (reset) _hasMore = true;
    });
    try {
      final res = await context.read<BinderProvider>().fetchPublicBinderDirect(
        userId: widget.userId,
        listType: widget.listType,
        page: _page,
      );
      if (res != null) {
        if (reset) {
          _items = res;
        } else {
          _items.addAll(res);
        }
        _hasMore = res.length >= 20;
        _page++;
        _error = null;
        _retryShouldReset = false;
      } else {
        _error = _items.isEmpty
            ? 'Não foi possível carregar esta lista. Verifique sua conexão.'
            : 'A atualização falhou. Os itens já carregados foram mantidos.';
        _hasMore = false;
        _retryShouldReset = reset;
      }
    } catch (e) {
      debugPrint('[PublicBinder] Falha ao carregar ${widget.listType}: $e');
      _error = _items.isEmpty
          ? 'Não foi possível carregar esta lista. Verifique sua conexão.'
          : 'A atualização falhou. Os itens já carregados foram mantidos.';
      _hasMore = false;
      _retryShouldReset = reset;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _retryFetch() {
    setState(() => _hasMore = true);
    _fetch(reset: _retryShouldReset || _items.isEmpty);
  }

  void _onInteract(BinderItem item) {
    final isHave = widget.listType == 'have';
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CachedCardImage(
                      imageUrl: item.cardImageUrl,
                      width: 40,
                      height: 56,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.cardName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.fontLg,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space2),
                          Text(
                            isHave
                                ? 'Este jogador TEM esta carta'
                                : 'Este jogador QUER esta carta',
                            style: TextStyle(
                              color: isHave
                                  ? AppTheme.primarySoft
                                  : AppTheme.mythicGold,
                              fontSize: AppTheme.fontSm,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space8),
                // Info badges
                if (item.price != null || item.forTrade || item.forSale)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (item.forTrade)
                          _interactTag('Aceita troca', AppTheme.primarySoft),
                        if (item.forSale)
                          _interactTag('À venda', AppTheme.mythicGold),
                        if (item.price != null)
                          Text(
                            'R\$ ${item.price!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.mythicGold,
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.fontMd,
                            ),
                          ),
                      ],
                    ),
                  ),
                const Divider(color: AppTheme.outlineMuted),
                const SizedBox(height: AppTheme.space8),
                // Actions
                if (isHave && (item.forSale || item.forTrade)) ...[
                  // User HAS this card → I can propose to buy/trade for it
                  if (item.forTrade)
                    _actionButton(
                      icon: Icons.swap_horiz,
                      label: 'Propor troca',
                      color: AppTheme.primarySoft,
                      onTap: () {
                        Navigator.pop(ctx);
                        _openCreateTrade('trade', item);
                      },
                    ),
                  if (item.forSale)
                    _actionButton(
                      icon: Icons.shopping_cart,
                      label: 'Quero comprar',
                      color: AppTheme.mythicGold,
                      onTap: () {
                        Navigator.pop(ctx);
                        _openCreateTrade('sale', item);
                      },
                    ),
                ],
                if (!isHave) ...[
                  // User WANTS this card → I can offer to sell/trade
                  _actionButton(
                    icon: Icons.sell,
                    label: 'Posso vender / trocar',
                    color: AppTheme.manaViolet,
                    onTap: () {
                      Navigator.pop(ctx);
                      _openCreateTrade('trade', item);
                    },
                  ),
                ],
                // Always show message option
                _actionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Enviar mensagem',
                  color: AppTheme.textSecondary,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openChat();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _interactTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontSm,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: AppTheme.fontMd,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        tileColor: color.withValues(alpha: 0.06),
      ),
    );
  }

  void _openCreateTrade(String type, BinderItem targetItem) {
    context.push(
      createTradeRouteLocation(
        receiverId: widget.userId,
        binderItemId: targetItem.id,
        type: type,
        source: 'profile',
      ),
      extra: CreateTradeRouteArgs(
        initialType: type,
        preselectedItem: targetItem,
      ),
    );
  }

  Future<void> _openChat() async {
    final msgProvider = context.read<MessageProvider>();
    final conv = await msgProvider.getOrCreateConversation(widget.userId);
    if (!mounted) return;
    if (conv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir a conversa agora. Tente novamente.',
          ),
        ),
      );
      return;
    }
    context.push('/messages/${conv.id}', extra: conv.otherUser);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isHave = widget.listType == 'have';

    if (_isLoading && _items.isEmpty) {
      return AppStatePanel(
        icon: isHave ? Icons.inventory_2_rounded : Icons.favorite_rounded,
        title: isHave ? 'Carregando fichário' : 'Carregando wishlist',
        message: 'Buscando os itens públicos deste jogador.',
        accent: AppTheme.manaViolet,
      );
    }

    if (_error != null && _items.isEmpty) {
      return AppStatePanel(
        key: Key('public-binder-error-${widget.listType}'),
        icon: Icons.error_outline_rounded,
        title: 'Não foi possível carregar esta lista',
        message: _error,
        accent: AppTheme.error,
        actionLabel: 'Tentar novamente',
        onAction: _retryFetch,
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHave ? Icons.inventory_2 : Icons.favorite_border,
              size: 48,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              isHave
                  ? 'Nenhuma carta disponível para troca/venda'
                  : 'Nenhuma carta na lista de desejos',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontLg,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetch(reset: true),
      color: AppTheme.manaViolet,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppTheme.space12),
        itemCount: _items.length + ((_hasMore || _error != null) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            if (_error != null) {
              return Padding(
                key: Key('public-binder-pagination-error-${widget.listType}'),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontSize: AppTheme.fontSm,
                      ),
                    ),
                    TextButton.icon(
                      key: Key(
                        'public-binder-pagination-retry-${widget.listType}',
                      ),
                      onPressed: _retryFetch,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }
            if (_isLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.space16),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.manaViolet),
                ),
              );
            }
            return const SizedBox(height: AppTheme.space1);
          }
          final item = _items[index];
          return _PublicBinderItemCard(
            item: item,
            isHave: isHave,
            onTap: () => _onInteract(item),
          );
        },
      ),
    );
  }
}

// =====================================================================
// Public Binder Item Card (with interaction hint)
// =====================================================================

class _PublicBinderItemCard extends StatelessWidget {
  final BinderItem item;
  final bool isHave;
  final VoidCallback onTap;

  const _PublicBinderItemCard({
    required this.item,
    required this.isHave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      color: AppTheme.surfaceSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(
          color: AppTheme.outlineMuted,
          width: AppTheme.strokeHairline,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space10),
          child: Row(
            children: [
              CachedCardImage(
                imageUrl: item.cardImageUrl,
                width: 42,
                height: 58,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.cardName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: AppTheme.fontMd,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Row(
                      children: [
                        _binderBadge('×${item.quantity}', AppTheme.manaViolet),
                        const SizedBox(width: AppTheme.space4),
                        _binderBadge(
                          item.condition,
                          AppTheme.conditionColor(item.condition),
                        ),
                        if (item.isFoil) ...[
                          const SizedBox(width: AppTheme.space4),
                          Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: AppTheme.mythicGold.withValues(alpha: 0.8),
                          ),
                        ],
                        if (item.forTrade) ...[
                          const SizedBox(width: AppTheme.space4),
                          _binderStatusTag('Troca', AppTheme.primarySoft),
                        ],
                        if (item.forSale) ...[
                          const SizedBox(width: AppTheme.space4),
                          _binderStatusTag('Venda', AppTheme.mythicGold),
                        ],
                      ],
                    ),
                    if (item.price != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppTheme.space2),
                        child: Text(
                          'R\$ ${item.price!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.mythicGold,
                            fontSize: AppTheme.fontSm,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Interaction hint icon
              Container(
                padding: const EdgeInsets.all(AppTheme.space6),
                decoration: BoxDecoration(
                  color: (isHave ? AppTheme.primarySoft : AppTheme.mythicGold)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  isHave ? Icons.shopping_cart_outlined : Icons.sell_outlined,
                  color: isHave ? AppTheme.primarySoft : AppTheme.mythicGold,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _binderBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space5,
        vertical: AppTheme.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _binderStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space5,
        vertical: AppTheme.space1,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
