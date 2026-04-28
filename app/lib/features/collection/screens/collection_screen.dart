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
        title: const Text('Coleção'),
        backgroundColor: AppTheme.surfaceElevated,
        actions: [
          IconButton(
            tooltip: 'Catálogo de coleções',
            onPressed: () => context.push('/collection/sets'),
            icon: const Icon(Icons.auto_awesome_mosaic_outlined),
          ),
          IconButton(
            tooltip: 'Última edição',
            onPressed: () => context.push('/collection/latest-set'),
            icon: const Icon(Icons.new_releases_outlined),
          ),
          const ShellAppBarActions(),
        ],
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorColor: AppTheme.manaViolet,
          labelColor: AppTheme.manaViolet,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(
            fontSize: AppTheme.fontMd,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.collections_bookmark, size: 20),
              text: 'Fichário',
            ),
            Tab(icon: Icon(Icons.storefront, size: 20), text: 'Marketplace'),
            Tab(icon: Icon(Icons.swap_horiz, size: 20), text: 'Trades'),
            Tab(
              icon: Icon(Icons.auto_awesome_mosaic_outlined, size: 20),
              text: 'Coleções',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BinderTabContent(),
          MarketplaceTabContent(),
          TradeInboxTabContent(),
          SetsCatalogScreen(),
        ],
      ),
    );
  }
}
