import 'package:flutter/material.dart';

import 'favorites_tab.dart';
import 'library_tab.dart';
import 'recent_tab.dart';
import 'scanner_tab.dart';
import 'settings_screen.dart';

/// Shell with the four main views of the app.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  // Rebuilding a tab after a change is done through these keys.
  final libraryKey = GlobalKey<LibraryTabState>();
  final favoritesKey = GlobalKey<FavoritesTabState>();
  final recentKey = GlobalKey<RecentTabState>();

  static const titles = ['Library', 'Favourites', 'Recent', 'Scanner'];

  void refreshAll() {
    libraryKey.currentState?.load();
    favoritesKey.currentState?.load();
    recentKey.currentState?.load();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      LibraryTab(key: libraryKey, onChanged: refreshAll),
      FavoritesTab(key: favoritesKey, onChanged: refreshAll),
      RecentTab(key: recentKey, onChanged: refreshAll),
      ScannerTab(onSaved: refreshAll),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              refreshAll();
            },
          ),
        ],
      ),
      body: IndexedStack(index: index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
          refreshAll();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.picture_as_pdf_outlined),
            selectedIcon: Icon(Icons.picture_as_pdf),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'Favourites',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Recent',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scanner',
          ),
        ],
      ),
    );
  }
}
