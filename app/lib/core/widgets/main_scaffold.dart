import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static const _primaryPaths = <String>{
    '/home',
    '/decks',
    '/collection',
    '/community',
    '/profile',
    '/market',
    '/trades',
  };

  void _selectDestination(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/decks');
        break;
      case 2:
        context.go('/collection');
        break;
      case 3:
        context.go('/community');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int? currentIndex;
    if (location == '/home' || location.startsWith('/home/')) {
      currentIndex = 0;
    }
    if (location.startsWith('/decks')) {
      currentIndex = 1;
    } else if (location.startsWith('/collection') ||
        location.startsWith('/trades') ||
        location.startsWith('/market')) {
      currentIndex = 2;
    } else if (location.startsWith('/community')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile')) {
      currentIndex = 4;
    }

    final content = DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
      child: child,
    );
    final isPrimaryRoot = _primaryPaths.contains(location);

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
                    labelType:
                        extended ? null : NavigationRailLabelType.selected,
                    onDestinationSelected:
                        (index) => _selectDestination(context, index),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: Text('Início'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.style_outlined),
                        selectedIcon: Icon(Icons.style),
                        label: Text('Decks'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.collections_bookmark_outlined),
                        selectedIcon: Icon(Icons.collections_bookmark),
                        label: Text('Coleção'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.public_outlined),
                        selectedIcon: Icon(Icons.public),
                        label: Text('Comunidade'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: Text('Perfil'),
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
          bottomNavigationBar:
              isPrimaryRoot
                  ? Container(
                    key: const Key('main-bottom-navigation'),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.outlineMuted,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: NavigationBar(
                      selectedIndex: currentIndex ?? 0,
                      onDestinationSelected:
                          (index) => _selectDestination(context, index),
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: 'Início',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.style_outlined),
                          selectedIcon: Icon(Icons.style),
                          label: 'Decks',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.collections_bookmark_outlined),
                          selectedIcon: Icon(Icons.collections_bookmark),
                          label: 'Coleção',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.public_outlined),
                          selectedIcon: Icon(Icons.public),
                          label: 'Comunidade',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: 'Perfil',
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
