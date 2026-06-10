import 'package:flutter/material.dart';
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
            Tab(
              key: Key('collection-tab-binder'),
              text: 'Fichário',
              height: 34,
            ),
            Tab(key: Key('collection-tab-market'), text: 'Market', height: 34),
            Tab(key: Key('collection-tab-trades'), text: 'Trades', height: 34),
            Tab(key: Key('collection-tab-sets'), text: 'Coleções', height: 34),
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
