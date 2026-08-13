import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config/release_capabilities.dart';
import '../../../core/theme/app_theme.dart';
import '../../binder/screens/binder_screen.dart' show BinderTabContent;
import '../../binder/screens/marketplace_screen.dart'
    show MarketplaceTabContent;
import '../../trades/screens/trade_inbox_screen.dart' show TradeInboxTabContent;
import 'sets_catalog_screen.dart';

/// Tela "Coleção" — hub unificado para Fichário, Marketplace e Trades.
/// Substitui os 3 menus órfãos por uma navegação clara com tabs.
class CollectionScreen extends StatelessWidget {
  /// Tab inicial: 0 = Fichário, 1 = Marketplace, 2 = Trades, 3 = Coleções
  final int initialTab;
  final String initialBinderList;
  final ApiClient? setsApiClient;

  const CollectionScreen({
    super.key,
    this.initialTab = 0,
    this.initialBinderList = 'have',
    this.setsApiClient,
  });

  @override
  Widget build(BuildContext context) {
    final capabilities = context.watch<ReleaseCapabilitiesProvider?>();
    final sections = _CollectionSection.values
        .where((section) => section.isAllowed(capabilities))
        .toList(growable: false);

    if (sections.isEmpty) {
      return const _CollectionUnavailableScaffold();
    }

    final sectionKey = sections.map((section) => section.routeId).join(',');
    return _CollectionTabs(
      key: ValueKey('collection-tabs-$sectionKey'),
      sections: sections,
      requestedRouteId: initialTab,
      initialBinderList: initialBinderList,
      setsApiClient: setsApiClient,
    );
  }
}

enum _CollectionSection {
  binder(
    routeId: 0,
    capability: ReleaseCapability.collectionPrivate,
    tabKey: 'collection-tab-binder',
    label: 'Fichário',
  ),
  marketplace(
    routeId: 1,
    capability: ReleaseCapability.marketplace,
    tabKey: 'collection-tab-market',
    label: 'Ofertas',
  ),
  trades(
    routeId: 2,
    capability: ReleaseCapability.trades,
    tabKey: 'collection-tab-trades',
    label: 'Trocas',
  ),
  sets(
    routeId: 3,
    capability: ReleaseCapability.catalogPrivate,
    tabKey: 'collection-tab-sets',
    label: 'Edições',
  );

  const _CollectionSection({
    required this.routeId,
    required this.capability,
    required this.tabKey,
    required this.label,
  });

  final int routeId;
  final ReleaseCapability capability;
  final String tabKey;
  final String label;

  bool isAllowed(ReleaseCapabilitiesProvider? capabilities) {
    return capabilities?.isAllowed(capability) ?? false;
  }

  Tab buildTab() {
    return Tab(key: Key(tabKey), text: label, height: AppTheme.touchTargetMin);
  }

  Widget buildContent({
    required String initialBinderList,
    required ApiClient? setsApiClient,
  }) {
    return switch (this) {
      _CollectionSection.binder => BinderTabContent(
        initialListType: initialBinderList,
      ),
      _CollectionSection.marketplace => const MarketplaceTabContent(),
      _CollectionSection.trades => const TradeInboxTabContent(),
      _CollectionSection.sets => SetsCatalogScreen(
        apiClient: setsApiClient,
        showAppBar: false,
      ),
    };
  }
}

class _CollectionTabs extends StatefulWidget {
  const _CollectionTabs({
    super.key,
    required this.sections,
    required this.requestedRouteId,
    required this.initialBinderList,
    required this.setsApiClient,
  });

  final List<_CollectionSection> sections;
  final int requestedRouteId;
  final String initialBinderList;
  final ApiClient? setsApiClient;

  @override
  State<_CollectionTabs> createState() => _CollectionTabsState();
}

class _CollectionTabsState extends State<_CollectionTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _applyingRouteTab = false;

  int get _requestedVisibleIndex {
    final index = widget.sections.indexWhere(
      (section) => section.routeId == widget.requestedRouteId,
    );
    return index < 0 ? 0 : index;
  }

  _CollectionSection get _selectedSection {
    return widget.sections[_tabController.index];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.sections.length,
      vsync: this,
      initialIndex: _requestedVisibleIndex,
    );
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCanonicalLocation(_selectedSection.routeId);
    });
  }

  @override
  void didUpdateWidget(covariant _CollectionTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = _requestedVisibleIndex;
    if (_tabController.index != targetIndex) {
      _applyingRouteTab = true;
      _tabController.index = targetIndex;
      _applyingRouteTab = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tabController.index == targetIndex) {
        _syncCanonicalLocation(_selectedSection.routeId);
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
    _syncCanonicalLocation(_selectedSection.routeId);
  }

  void _syncCanonicalLocation(int routeId) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;

    final canonicalUri = Uri(
      path: '/collection',
      queryParameters: {
        'tab': '$routeId',
        if (routeId == _CollectionSection.binder.routeId &&
            widget.initialBinderList == 'want')
          'list': 'want',
      },
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
                        tabs: widget.sections
                            .map((section) => section.buildTab())
                            .toList(growable: false),
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
        children: widget.sections
            .map(
              (section) => section.buildContent(
                initialBinderList: widget.initialBinderList,
                setsApiClient: widget.setsApiClient,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _CollectionUnavailableScaffold extends StatelessWidget {
  const _CollectionUnavailableScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        toolbarHeight: 54,
        title: const Text('Coleção'),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundAbyss,
        surfaceTintColor: AppTheme.transparent,
        actions: const [ShellAppBarActions()],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.space24),
          child: Text(
            'Coleção indisponível nesta versão.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }
}
