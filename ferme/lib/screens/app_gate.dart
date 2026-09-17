import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import 'auth/onboarding_screen.dart';
import 'home/home_shell.dart';
import 'landing/landing_screen.dart';

/// Route vers l'écran adapté à l'état de connexion / profil de l'utilisateur.
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    switch (session.status) {
      case SessionStatus.chargement:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case SessionStatus.deconnecte:
        return const LandingScreen();
      case SessionStatus.enAttenteProfil:
        return const OnboardingScreen();
      case SessionStatus.compteDesactive:
        return _CompteDesactiveScreen(deconnexion: session.deconnexion);
      case SessionStatus.pret:
        return const HomeShell();
      case SessionStatus.erreurProfil:
        return _ErreurProfilScreen(session: session);
    }
  }
}

class _ErreurProfilScreen extends StatelessWidget {
  const _ErreurProfilScreen({required this.session});

  final SessionProvider session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                const Text('Connexion à Firestore impossible', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  session.erreurProfil ?? 'Erreur inconnue',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vérifiez que la base Firestore est créée et que les règles de '
                  'sécurité (firestore.rules) ont bien été publiées dans la console Firebase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: session.reessayerProfil, child: const Text('Réessayer')),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: session.deconnexion, child: const Text('Se déconnecter')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompteDesactiveScreen extends StatelessWidget {
  const _CompteDesactiveScreen({required this.deconnexion});

  final Future<void> Function() deconnexion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, size: 48),
              const SizedBox(height: 16),
              const Text('Accès désactivé', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Le Promoteur a désactivé cet accès. Contactez-le si vous pensez que ceci est une erreur.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(onPressed: deconnexion, child: const Text('Se déconnecter')),
            ],
          ),
        ),
      ),
    );
  }
}
