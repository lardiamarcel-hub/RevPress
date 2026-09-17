import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';

/// Affiché quand un utilisateur est connecté mais n'a pas encore de profil
/// Firestore : soit il est le tout premier compte (devient Promoteur), soit
/// il a été invité par le Promoteur (Superviseur ou Collaborateur) et doit
/// accepter son invitation.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _EtatOnboarding { chargement, invitationTrouvee, bootstrapDisponible, aucunAcces, enCours, erreurChargement }

class _OnboardingScreenState extends State<OnboardingScreen> {
  _EtatOnboarding _etat = _EtatOnboarding.chargement;
  Map<String, dynamic>? _invitation;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyser());
  }

  Future<void> _analyser() async {
    setState(() => _etat = _EtatOnboarding.chargement);
    final session = context.read<SessionProvider>();
    final firestore = session.firestore;
    final email = session.user?.email;

    try {
      // Un compte anonyme (mode démonstration) n'a pas d'e-mail : aucune
      // invitation n'est possible pour lui, on passe direct à l'amorçage.
      if (email != null) {
        final invitation = await firestore.chercherInvitation(email);
        if (invitation != null) {
          setState(() {
            _invitation = invitation;
            _etat = _EtatOnboarding.invitationTrouvee;
          });
          return;
        }
      }

      await firestore.assurerBootstrapExiste();
      final dejaDefini = await firestore.promoteurDejaDefini();
      setState(() {
        _etat = dejaDefini ? _EtatOnboarding.aucunAcces : _EtatOnboarding.bootstrapDisponible;
      });
    } catch (e) {
      setState(() {
        _erreur = "Impossible de joindre Firestore : $e\n\n"
            "Vérifiez que la base Firestore est créée et que les règles de "
            "sécurité (firestore.rules) ont bien été publiées dans la "
            "console Firebase.";
        _etat = _EtatOnboarding.erreurChargement;
      });
    }
  }

  Future<void> _accepterInvitation() async {
    final session = context.read<SessionProvider>();
    final email = session.user!.email!;
    setState(() => _etat = _EtatOnboarding.enCours);
    try {
      await session.firestore.accepterInvitation(session.user!.uid, email);
    } catch (e) {
      setState(() {
        _erreur = "Impossible de finaliser l'inscription. Réessayez.";
        _etat = _EtatOnboarding.invitationTrouvee;
      });
    }
  }

  Future<void> _devenirPromoteur() async {
    final session = context.read<SessionProvider>();
    setState(() => _etat = _EtatOnboarding.enCours);
    final controleur = TextEditingController();
    final nom = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Votre nom'),
        content: TextField(
          controller: controleur,
          decoration: const InputDecoration(labelText: 'Nom affiché'),
          autofocus: true,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controleur.text.trim()),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (nom == null || nom.isEmpty) {
      setState(() => _etat = _EtatOnboarding.bootstrapDisponible);
      return;
    }
    try {
      await session.firestore.devenirPromoteurFondateur(session.user!.uid, nom);
    } catch (e) {
      setState(() {
        _erreur = 'Un autre compte a déjà été défini comme Promoteur entre-temps.';
        _etat = _EtatOnboarding.aucunAcces;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: session.deconnexion,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _contenu(session),
          ),
        ),
      ),
    );
  }

  Widget _contenu(SessionProvider session) {
    switch (_etat) {
      case _EtatOnboarding.chargement:
      case _EtatOnboarding.enCours:
        return const Center(child: CircularProgressIndicator());

      case _EtatOnboarding.invitationTrouvee:
        final nom = _invitation!['nom'] as String;
        final role = _invitation!['role'] as String;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mail_outline, size: 48),
            const SizedBox(height: 16),
            Text('Bonjour $nom', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Vous avez été invité(e) en tant que : $role', textAlign: TextAlign.center),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: _accepterInvitation, child: const Text("Confirmer et accéder à l'application")),
          ],
        );

      case _EtatOnboarding.bootstrapDisponible:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.agriculture, size: 48),
            const SizedBox(height: 16),
            Text('Premier lancement', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              "Aucun Promoteur n'est encore défini pour cette ferme. "
              'En continuant, ce compte deviendra le Promoteur (accès complet).',
              textAlign: TextAlign.center,
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: _devenirPromoteur, child: const Text('Devenir le Promoteur de la ferme')),
          ],
        );

      case _EtatOnboarding.aucunAcces:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            Text('Aucun accès trouvé', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              session.user?.email == null
                  ? "Un Promoteur existe déjà pour cette ferme : le mode démonstration "
                      "(sans e-mail) ne peut pas rejoindre un accès existant. Créez un "
                      "compte avec une vraie adresse e-mail pour être invité(e)."
                  : "Ce compte n'a pas d'invitation en attente. "
                      'Demandez au Promoteur de la ferme de vous inviter avec cette même adresse e-mail.',
              textAlign: TextAlign.center,
            ),
            if (session.user?.email != null) ...[
              const SizedBox(height: 16),
              Text(
                session.user!.email!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton(onPressed: session.deconnexion, child: const Text('Se déconnecter')),
          ],
        );

      case _EtatOnboarding.erreurChargement:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Connexion à Firestore impossible', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_erreur ?? 'Erreur inconnue', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: _analyser, child: const Text('Réessayer')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: session.deconnexion, child: const Text('Se déconnecter')),
          ],
        );
    }
  }
}
