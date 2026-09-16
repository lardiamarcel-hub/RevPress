import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../models/user_role.dart';
import '../../providers/session_provider.dart';
import '../../widgets/deconnexion_action.dart';

/// Écran Promoteur : inviter / désactiver un compte Superviseur ou
/// Collaborateur (fermier, technicien).
class GestionAccesScreen extends StatelessWidget {
  const GestionAccesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des accès'), actions: const [DeconnexionAction()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ouvrirDialogueInvitation(context),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Inviter'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text('Comptes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StreamBuilder<List<UserProfile>>(
            stream: session.firestore.utilisateursStream(),
            builder: (context, snap) {
              final comptes = (snap.data ?? []).where((u) => u.role != UserRole.promoteur).toList();
              if (comptes.isEmpty) {
                return const Text('Aucun compte Superviseur ou Collaborateur pour le moment.');
              }
              return Column(
                children: comptes
                    .map((u) => Card(
                          child: ListTile(
                            title: Text(u.nom),
                            subtitle: Text(u.role.libelle),
                            trailing: Switch(
                              value: u.actif,
                              onChanged: (v) => session.firestore.definirActif(u.uid, v),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Invitations en attente', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: session.firestore.invitationsEnAttenteStream(),
            builder: (context, snap) {
              final invitations = snap.data ?? [];
              if (invitations.isEmpty) {
                return const Text('Aucune invitation en attente.');
              }
              return Column(
                children: invitations
                    .map((inv) => Card(
                          child: ListTile(
                            title: Text(inv['nom'] as String? ?? ''),
                            subtitle: Text('${inv['id']} · ${UserRoleX.fromValue(inv['role'] as String?).libelle}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => session.firestore.supprimerInvitation(inv['id'] as String),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _ouvrirDialogueInvitation(BuildContext context) async {
    final session = context.read<SessionProvider>();
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    UserRole role = UserRole.collaborateur;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Inviter un accès'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Rôle'),
                  items: const [
                    DropdownMenuItem(value: UserRole.collaborateur, child: Text('Collaborateur (fermier, technicien)')),
                    DropdownMenuItem(value: UserRole.superviseur, child: Text('Superviseur')),
                  ],
                  onChanged: (v) => setState(() => role = v ?? UserRole.collaborateur),
                ),
                const SizedBox(height: 4),
                const Text(
                  "La personne invitée devra créer son propre compte dans l'application avec cette adresse e-mail.",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await session.firestore.creerInvitation(
                  email: emailCtrl.text,
                  nom: nomCtrl.text.trim(),
                  role: role,
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }
}
