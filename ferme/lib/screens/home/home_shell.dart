import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_role.dart';
import '../../providers/session_provider.dart';
import '../acces/gestion_acces_screen.dart';
import '../bilan/bilan_screen.dart';
import '../saisie/saisie_screen.dart';
import '../saisie_limitee/saisie_limitee_screen.dart';
import '../suivi/suivi_screen.dart';

/// Point d'entrée post-connexion : dispatch vers la navigation adaptée au
/// rôle du profil courant.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final profil = context.watch<SessionProvider>().profil!;
    switch (profil.role) {
      case UserRole.collaborateur:
        return const SaisieLimiteeScreen();
      case UserRole.superviseur:
        return const _NavigationParOnglets(
          onglets: [
            _Onglet(icone: Icons.edit_note, label: 'Saisie', ecran: SaisieScreen()),
            _Onglet(icone: Icons.timeline, label: 'Suivi', ecran: SuiviScreen()),
            _Onglet(icone: Icons.pie_chart_outline, label: 'Bilan', ecran: BilanScreen()),
          ],
        );
      case UserRole.promoteur:
        return const _NavigationParOnglets(
          onglets: [
            _Onglet(icone: Icons.timeline, label: 'Suivi', ecran: SuiviScreen()),
            _Onglet(icone: Icons.pie_chart_outline, label: 'Bilan', ecran: BilanScreen()),
            _Onglet(icone: Icons.people_outline, label: 'Accès', ecran: GestionAccesScreen()),
          ],
        );
    }
  }
}

class _Onglet {
  const _Onglet({required this.icone, required this.label, required this.ecran});

  final IconData icone;
  final String label;
  final Widget ecran;
}

class _NavigationParOnglets extends StatefulWidget {
  const _NavigationParOnglets({required this.onglets});

  final List<_Onglet> onglets;

  @override
  State<_NavigationParOnglets> createState() => _NavigationParOngletsState();
}

class _NavigationParOngletsState extends State<_NavigationParOnglets> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: widget.onglets.map((o) => o.ecran).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: widget.onglets
            .map((o) => NavigationDestination(icon: Icon(o.icone), label: o.label))
            .toList(),
      ),
    );
  }
}
