import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/release_capabilities.dart';
import '../theme/app_theme.dart';
import 'manaloom_glyph.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  void _selectDestination(
    BuildContext context,
    int index,
    List<_MainDestination> destinations,
  ) {
    if (index < 0 || index >= destinations.length) return;
    context.go(destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final releaseCapabilities = context.watch<ReleaseCapabilitiesProvider?>();
    final decksAllowed =
        releaseCapabilities?.isAllowed(ReleaseCapability.decksPrivate) ?? false;
    final collectionAllowed =
        releaseCapabilities?.isAllowed(ReleaseCapability.collectionPrivate) ??
        false;
    final communityAllowed =
        releaseCapabilities != null &&
        (releaseCapabilities.isAllowed(ReleaseCapability.galleryPublic) ||
            releaseCapabilities.isAllowed(ReleaseCapability.marketplace) ||
            (releaseCapabilities.isAllowed(ReleaseCapability.profilesPublic) &&
                releaseCapabilities.isAllowed(ReleaseCapability.userSearch)));
    final destinations = <_MainDestination>[
      const _MainDestination(
        path: '/home',
        label: 'Início',
        icon: ManaLoomGlyphKind.brand,
      ),
      if (decksAllowed)
        const _MainDestination(
          path: '/decks',
          label: 'Decks',
          icon: ManaLoomGlyphKind.deck,
        ),
      if (collectionAllowed)
        const _MainDestination(
          path: '/collection',
          label: 'Coleção',
          icon: ManaLoomGlyphKind.collection,
        ),
      if (communityAllowed)
        const _MainDestination(
          path: '/community',
          label: 'Comunidade',
          icon: ManaLoomGlyphKind.community,
        ),
      const _MainDestination(
        path: '/profile',
        label: 'Perfil',
        icon: ManaLoomGlyphKind.player,
      ),
    ];
    final selectedIndex = destinations.indexWhere(
      (destination) => destination.matches(location),
    );
    final currentIndex = selectedIndex < 0 ? null : selectedIndex;

    final content = DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
      child: child,
    );
    final isPrimaryRoot = destinations.any(
      (destination) => destination.path == location,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= AppTheme.breakpointMedium;
        if (useRail) {
          final extended = constraints.maxWidth >= AppTheme.breakpointExpanded;
          return Scaffold(
            backgroundColor: AppTheme.backgroundAbyss,
            body: Row(
              children: [
                SafeArea(
                  right: false,
                  child: NavigationRail(
                    key: const Key('main-navigation-rail'),
                    selectedIndex: currentIndex,
                    extended: extended,
                    minExtendedWidth: 204,
                    labelType: extended
                        ? null
                        : NavigationRailLabelType.selected,
                    onDestinationSelected: (index) =>
                        _selectDestination(context, index, destinations),
                    destinations: [
                      for (final destination in destinations)
                        NavigationRailDestination(
                          icon: ManaLoomGlyph(destination.icon),
                          selectedIcon: ManaLoomGlyph(destination.icon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1, color: AppTheme.outlineMuted),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundAbyss,
          body: content,
          bottomNavigationBar: isPrimaryRoot
              ? Container(
                  key: const Key('main-bottom-navigation'),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.outlineMuted, width: 0.5),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: currentIndex ?? 0,
                    onDestinationSelected: (index) =>
                        _selectDestination(context, index, destinations),
                    destinations: [
                      for (final destination in destinations)
                        NavigationDestination(
                          icon: ManaLoomGlyph(destination.icon),
                          selectedIcon: ManaLoomGlyph(destination.icon),
                          label: destination.label,
                        ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}

@immutable
class _MainDestination {
  const _MainDestination({
    required this.path,
    required this.label,
    required this.icon,
  });

  final String path;
  final String label;
  final ManaLoomGlyphKind icon;

  bool matches(String location) {
    if (path == '/home') {
      return location == path || location.startsWith('/home/');
    }
    if (path == '/collection') {
      return location.startsWith('/collection') ||
          location.startsWith('/trades') ||
          location.startsWith('/market');
    }
    return location == path || location.startsWith('$path/');
  }
}
