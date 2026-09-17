import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

/// Écran d'accueil affiché avant toute connexion : présente les sections de
/// l'application (sans y donner accès, faute de compte) et met en avant la
/// création de compte / connexion. Permet de découvrir l'app avant de
/// s'engager à créer un compte réel pour la ferme.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _sections = [
    _Section(
      icone: Icons.edit_note,
      titre: 'Saisie',
      description: 'Superviseur : enregistrer dépenses et recettes, gérer les lignes',
    ),
    _Section(
      icone: Icons.assignment_outlined,
      titre: 'Saisie limitée',
      description: "Collaborateur (fermier, technicien) : imputer une dépense",
    ),
    _Section(
      icone: Icons.timeline,
      titre: 'Suivi',
      description: 'Flux chronologique en temps réel, filtres par période et par ligne',
    ),
    _Section(
      icone: Icons.pie_chart_outline,
      titre: 'Bilan',
      description: 'Totaux, bénéfice net, répartition par ligne, export PDF',
    ),
    _Section(
      icone: Icons.people_outline,
      titre: 'Gestion des accès',
      description: 'Promoteur : inviter ou désactiver un Superviseur/Collaborateur',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/icon/icon.png', width: 88, height: 88),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Suivi Ferme',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Suivi financier à distance de la ferme',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Text('Ce que propose l\'application', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._sections.map((s) => Card(
                  child: ListTile(
                    leading: Icon(s.icone, color: AppTheme.vertFerme),
                    title: Text(s.titre),
                    subtitle: Text(s.description),
                  ),
                )),
            const SizedBox(height: 16),
            Card(
              color: AppTheme.vertFerme.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Prêt·e à commencer avec votre ferme ?",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Connectez-vous, ou créez un compte si c\'est votre première fois '
                      '(le premier compte créé devient automatiquement le Promoteur).',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text('Se connecter / Créer un compte'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section {
  const _Section({required this.icone, required this.titre, required this.description});

  final IconData icone;
  final String titre;
  final String description;
}
