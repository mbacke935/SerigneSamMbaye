import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import 'mini_player.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : AppTheme.surface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.outlineDark : AppTheme.outline,
                  width: 1,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.headphones_outlined),
                  selectedIcon: Icon(Icons.headphones_rounded),
                  label: 'Audios',
                ),
                NavigationDestination(
                  icon: Icon(Icons.play_circle_outline_rounded),
                  selectedIcon: Icon(Icons.play_circle_rounded),
                  label: 'Vidéos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.format_quote_outlined),
                  selectedIcon: Icon(Icons.format_quote_rounded),
                  label: 'Citations',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
