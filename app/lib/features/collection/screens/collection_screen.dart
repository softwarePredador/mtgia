import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
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

  const CollectionScreen({super.key, this.initialTab = 0});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        toolbarHeight: 52,
        title: const Text('Coleção'),
        backgroundColor: AppTheme.backgroundAbyss,
        actions: [
          IconButton(
            key: const Key('collection-open-sets-catalog'),
            tooltip: 'Catálogo de coleções',
            onPressed: () => context.push('/collection/sets'),
            icon: const Icon(Icons.grid_view_rounded, size: 21),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          ),
          const ShellAppBarActions(),
        ],
        bottom: TabBar(
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
            Tab(text: 'Fichário', height: 34),
            Tab(text: 'Market', height: 34),
            Tab(text: 'Trades', height: 34),
            Tab(text: 'Coleções', height: 34),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BinderTabContent(),
          MarketplaceTabContent(),
          TradeInboxTabContent(),
          SetsCatalogScreen(showAppBar: false),
        ],
      ),
    );
  }
}
