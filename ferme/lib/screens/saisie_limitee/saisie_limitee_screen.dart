import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/depense.dart';
import '../../models/user_role.dart';
import '../../providers/session_provider.dart';
import '../../widgets/entree_tile.dart';

/// Écran Collaborateur (fermier / technicien) : formulaire minimal pour
/// imputer une dépense liée à ses tâches, et historique de ses propres
/// imputations. Aucun accès aux recettes ni au bilan global.
class SaisieLimiteeScreen extends StatefulWidget {
  const SaisieLimiteeScreen({super.key});

  @override
  State<SaisieLimiteeScreen> createState() => _SaisieLimiteeScreenState();
}

class _SaisieLimiteeScreenState extends State<SaisieLimiteeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _ligne;
  bool _envoiEnCours = false;

  @override
  void dispose() {
    _montantCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate() || _ligne == null) return;
    setState(() => _envoiEnCours = true);
    final session = context.read<SessionProvider>();
    final profil = session.profil!;
    try {
      await session.firestore.ajouterDepense(Depense(
        id: '',
        montant: double.parse(_montantCtrl.text.replaceAll(',', '.')),
        date: DateTime.now(),
        ligne: _ligne!,
        note: _noteCtrl.text.trim(),
        saisiParUid: session.user!.uid,
        saisiParNom: profil.nom,
        saisiParRole: profil.role.value,
      ));
      _montantCtrl.clear();
      _noteCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dépense imputée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur d\'enregistrement')));
      }
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour ${session.profil?.nom ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: session.deconnexion,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Imputer une dépense', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _montantCtrl,
                  decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (val == null || val <= 0) return 'Montant invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<String>>(
                  stream: session.firestore.lignesStream(),
                  builder: (context, snap) {
                    final lignes = snap.data ?? [];
                    _ligne ??= lignes.isNotEmpty ? lignes.first : null;
                    return DropdownButtonFormField<String>(
                      value: lignes.contains(_ligne) ? _ligne : null,
                      decoration: const InputDecoration(labelText: 'Ligne'),
                      items: lignes.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (v) => setState(() => _ligne = v),
                      validator: (v) => v == null ? 'Choisissez une ligne' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: 'Note (optionnel)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _envoiEnCours ? null : _enregistrer,
                  child: Text(_envoiEnCours ? 'Enregistrement…' : 'Enregistrer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Mes imputations passées', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StreamBuilder<List<Depense>>(
            stream: session.firestore.mesDepensesStream(session.user!.uid),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final depenses = snap.data!;
              if (depenses.isEmpty) return const Text('Aucune imputation pour le moment.');
              return Column(
                children: depenses
                    .map((d) => EntreeTile(
                          estDepense: true,
                          montant: d.montant,
                          libelle: d.ligne,
                          date: d.date,
                          note: d.note,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
