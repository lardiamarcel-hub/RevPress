import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/depense.dart';
import '../../models/recette.dart';
import '../../models/user_role.dart';
import '../../providers/session_provider.dart';
import '../../widgets/deconnexion_action.dart';
import '../../widgets/entree_tile.dart';
import 'lignes_screen.dart';

/// Écran Superviseur : saisie rapide dépense / recette + historique de ses
/// propres saisies (modifiables/supprimables) + accès à la gestion des lignes.
class SaisieScreen extends StatefulWidget {
  const SaisieScreen({super.key});

  @override
  State<SaisieScreen> createState() => _SaisieScreenState();
}

class _SaisieScreenState extends State<SaisieScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saisie'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Dépense'), Tab(text: 'Recette')],
        ),
        actions: [
          IconButton(
            tooltip: 'Gérer les lignes de dépense',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LignesScreen()),
            ),
          ),
          const DeconnexionAction(),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_FormulaireDepense(), _FormulaireRecette()],
      ),
    );
  }
}

class _FormulaireDepense extends StatefulWidget {
  const _FormulaireDepense();

  @override
  State<_FormulaireDepense> createState() => _FormulaireDepenseState();
}

class _FormulaireDepenseState extends State<_FormulaireDepense> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
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
        date: _date,
        ligne: _ligne!,
        note: _noteCtrl.text.trim(),
        saisiParUid: session.user!.uid,
        saisiParNom: profil.nom,
        saisiParRole: profil.role.value,
      ));
      _montantCtrl.clear();
      _noteCtrl.clear();
      setState(() => _date = DateTime.now());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dépense enregistrée')));
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
              _SelecteurDate(date: _date, onChanged: (d) => setState(() => _date = d)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optionnel)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _envoiEnCours ? null : _enregistrer,
                child: Text(_envoiEnCours ? 'Enregistrement…' : 'Enregistrer la dépense'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Mes dépenses', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<Depense>>(
          stream: session.firestore.mesDepensesStream(session.user!.uid),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final depenses = snap.data!;
            if (depenses.isEmpty) return const Text('Aucune dépense enregistrée pour le moment.');
            return Column(
              children: depenses
                  .map((d) => EntreeTile(
                        estDepense: true,
                        montant: d.montant,
                        libelle: d.ligne,
                        date: d.date,
                        note: d.note,
                        onSupprimer: () => session.firestore.supprimerDepense(d.id),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _FormulaireRecette extends StatefulWidget {
  const _FormulaireRecette();

  @override
  State<_FormulaireRecette> createState() => _FormulaireRecetteState();
}

class _FormulaireRecetteState extends State<_FormulaireRecette> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _source = recetteSources.first;
  bool _envoiEnCours = false;

  @override
  void dispose() {
    _montantCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoiEnCours = true);
    final session = context.read<SessionProvider>();
    final profil = session.profil!;
    try {
      await session.firestore.ajouterRecette(Recette(
        id: '',
        montant: double.parse(_montantCtrl.text.replaceAll(',', '.')),
        date: _date,
        source: _source,
        note: _noteCtrl.text.trim(),
        saisiParUid: session.user!.uid,
        saisiParNom: profil.nom,
      ));
      _montantCtrl.clear();
      _noteCtrl.clear();
      setState(() => _date = DateTime.now());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recette enregistrée')));
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
              DropdownButtonFormField<String>(
                value: _source,
                decoration: const InputDecoration(labelText: 'Source'),
                items: recetteSources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _source = v ?? recetteSources.first),
              ),
              const SizedBox(height: 12),
              _SelecteurDate(date: _date, onChanged: (d) => setState(() => _date = d)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optionnel)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _envoiEnCours ? null : _enregistrer,
                child: Text(_envoiEnCours ? 'Enregistrement…' : 'Enregistrer la recette'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Mes recettes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<Recette>>(
          stream: session.firestore.mesRecettesStream(session.user!.uid),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final recettes = snap.data!;
            if (recettes.isEmpty) return const Text('Aucune recette enregistrée pour le moment.');
            return Column(
              children: recettes
                  .map((r) => EntreeTile(
                        estDepense: false,
                        montant: r.montant,
                        libelle: r.source,
                        date: r.date,
                        note: r.note,
                        onSupprimer: () => session.firestore.supprimerRecette(r.id),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SelecteurDate extends StatelessWidget {
  const _SelecteurDate({required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final choisie = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (choisie != null) onChanged(choisie);
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Date'),
        child: Text('${date.day}/${date.month}/${date.year}'),
      ),
    );
  }
}
