import 'package:flutter/material.dart';

import '../config/theme_angles.dart';
import 'digest/digest_history_screen.dart';
import 'digest/digest_screen.dart';
import 'favorites/favorites_screen.dart';
import 'search/search_screen.dart';
import 'settings/settings_screen.dart';
import 'tabs/angle_tab_screen.dart';

/// Shell de navigation principal : BottomNavigationBar à 5 onglets fixes,
/// plus les accès Digest / Historique / Recherche / Réglages depuis l'AppBar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  ThemeAngle get _currentAngle => ThemeAngleX.navigationTabs[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentAngle.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Rechercher',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SearchScreen(initialAngle: _currentAngle)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.star_border),
            tooltip: 'Favoris',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.today_outlined),
            tooltip: 'Digest du jour',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DigestScreen()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'historique') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DigestHistoryScreen()),
                );
              } else if (value == 'reglages') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'historique', child: Text('Historique des digests')),
              PopupMenuItem(value: 'reglages', child: Text('Réglages')),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: ThemeAngleX.navigationTabs
            .map((angle) => AngleTabScreen(angle: angle))
            .toList(growable: false),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: ThemeAngleX.navigationTabs
            .map((angle) => NavigationDestination(
                  icon: Icon(_iconFor(angle)),
                  label: _shortLabel(angle),
                ))
            .toList(growable: false),
      ),
    );
  }

  IconData _iconFor(ThemeAngle angle) {
    switch (angle) {
      case ThemeAngle.investissement:
        return Icons.trending_up;
      case ThemeAngle.exportations:
        return Icons.local_shipping_outlined;
      case ThemeAngle.monnaieAes:
        return Icons.account_balance_outlined;
      case ThemeAngle.financesPubliques:
        return Icons.receipt_long_outlined;
      case ThemeAngle.secteurPrive:
        return Icons.business_center_outlined;
      case ThemeAngle.horsSujet:
        return Icons.help_outline;
    }
  }

  String _shortLabel(ThemeAngle angle) {
    switch (angle) {
      case ThemeAngle.investissement:
        return 'Invest.';
      case ThemeAngle.exportations:
        return 'Export';
      case ThemeAngle.monnaieAes:
        return 'Monnaie';
      case ThemeAngle.financesPubliques:
        return 'Finances';
      case ThemeAngle.secteurPrive:
        return 'Privé';
      case ThemeAngle.horsSujet:
        return '—';
    }
  }
}
