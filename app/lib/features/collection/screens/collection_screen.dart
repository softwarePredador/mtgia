import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../binder/screens/binder_screen.dart' show BinderTabContent;
import '../../binder/screens/marketplace_screen.dart'
    show MarketplaceTabContent;
import '../../trades/screens/trade_inbox_screen.dart' show TradeInboxTabContent;
import 'sets_catalog_screen.dart';

/// Tela "Coleção" — hub unificado para Fichário, Marketplace e Trades.
/// Substitui os 3 menus órfãos por uma navegação clara com tabs.
class CollectionScreen extends StatefulWidget {
  /// Tab inicial: 0 = Fichário, 1 = Marketplace, 2 = Trades, 3 = Coleções
  final int initialTab;
  final ApiClient? setsApiClient;

  const CollectionScreen({super.key, this.initialTab = 0, this.setsApiClient});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _applyingRouteTab = false;

  int get _routeTab => widget.initialTab.clamp(0, 3).toInt();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _routeTab,
    );
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCanonicalLocation(_tabController.index);
    });
  }

  @override
  void didUpdateWidget(covariant CollectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetTab = _routeTab;
    if (_tabController.index != targetTab) {
      _applyingRouteTab = true;
      _tabController.index = targetTab;
      _applyingRouteTab = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tabController.index == targetTab) {
        _syncCanonicalLocation(targetTab);
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_applyingRouteTab || _tabController.indexIsChanging) return;
    _syncCanonicalLocation(_tabController.index);
  }

  void _syncCanonicalLocation(int tab) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;

    final canonicalUri = Uri(
      path: '/collection',
      queryParameters: {'tab': '$tab'},
    );
    if (GoRouterState.of(context).uri == canonicalUri) return;
    router.go(canonicalUri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        toolbarHeight: 54,
        title: const Text('Coleção'),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundAbyss,
        surfaceTintColor: AppTheme.transparent,
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontFamily: AppTheme.displayFontFamily,
          fontSize: AppTheme.fontLg + 1,
          fontWeight: FontWeight.w700,
        ),
        actions: const [ShellAppBarActions()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(AppTheme.touchTargetMin),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gutter = constraints.maxWidth < 600 ? 16.0 : 24.0;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: SizedBox(
                      key: const Key('collection-hub-tabs-canvas'),
                      width: double.infinity,
                      child: TabBar(
                        key: const Key('collection-hub-tabs'),
                        controller: _tabController,
                        isScrollable: false,
                        labelPadding: EdgeInsets.zero,
                        dividerColor: AppTheme.transparent,
                        indicatorColor: AppTheme.brass400,
                        labelColor: AppTheme.brass400,
                        unselectedLabelColor: AppTheme.textSecondary,
                        labelStyle: const TextStyle(
                          fontSize: AppTheme.fontXs,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: AppTheme.fontXs,
                          fontWeight: FontWeight.w700,
                        ),
                        tabs: const [
                          Tab(
                            key: Key('collection-tab-binder'),
                            text: 'Fichário',
                            height: AppTheme.touchTargetMin,
                          ),
                          Tab(
                            key: Key('collection-tab-market'),
                            text: 'Ofertas',
                            height: AppTheme.touchTargetMin,
                          ),
                          Tab(
                            key: Key('collection-tab-trades'),
                            text: 'Trocas',
                            height: AppTheme.touchTargetMin,
                          ),
                          Tab(
                            key: Key('collection-tab-sets'),
                            text: 'Edições',
                            height: AppTheme.touchTargetMin,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const BinderTabContent(),
          const MarketplaceTabContent(),
          const TradeInboxTabContent(),
          SetsCatalogScreen(apiClient: widget.setsApiClient, showAppBar: false),
        ],
      ),
    );
  }
}
