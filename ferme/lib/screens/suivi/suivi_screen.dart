import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/depense.dart';
import '../../models/flux_entree.dart';
import '../../models/recette.dart';
import '../../providers/session_provider.dart';
import '../../utils/periode.dart';
import '../../widgets/deconnexion_action.dart';
import '../../widgets/entree_tile.dart';

/// Écran Promoteur (et Superviseur) : flux chronologique de toutes les
/// entrées (dépenses + recettes), mis à jour en temps réel, avec filtres
/// par période et par ligne.
class SuiviScreen extends StatefulWidget {
  const SuiviScreen({super.key});

  @override
  State<SuiviScreen> createState() => _SuiviScreenState();
}

class _SuiviScreenState extends State<SuiviScreen> {
  Periode _periode = Periode.moisEnCours();
  String? _filtreLigne;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi'), actions: const [DeconnexionAction()]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _SelecteurPeriode(
                    periode: _periode,
                    onChanged: (p) => setState(() => _periode = p),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StreamBuilder<List<String>>(
                    stream: session.firestore.lignesStream(),
                    builder: (context, snap) {
                      final lignes = snap.data ?? [];
                      return DropdownButtonFormField<String?>(
                        value: _filtreLigne,
                        decoration: const InputDecoration(labelText: 'Ligne'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Toutes les lignes')),
                          ...lignes.map((l) => DropdownMenuItem(value: l, child: Text(l))),
                        ],
                        onChanged: (v) => setState(() => _filtreLigne = v),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: StreamBuilder<List<Depense>>(
              stream: session.firestore.depensesStream(debut: _periode.debut, fin: _periode.fin),
              builder: (context, depSnap) {
                return StreamBuilder<List<Recette>>(
                  stream: session.firestore.recettesStream(debut: _periode.debut, fin: _periode.fin),
                  builder: (context, recSnap) {
                    if (!depSnap.hasData || !recSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var depenses = depSnap.data!;
                    if (_filtreLigne != null) {
                      depenses = depenses.where((d) => d.ligne == _filtreLigne).toList();
                    }
                    final recettes = _filtreLigne == null ? recSnap.data! : <Recette>[];
                    final entrees = FluxEntree.combiner(depenses, recettes);
                    if (entrees.isEmpty) {
                      return const Center(child: Text('Aucune entrée pour cette période.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: entrees.length,
                      itemBuilder: (context, i) {
                        final e = entrees[i];
                        return EntreeTile(
                          estDepense: e.type == TypeFlux.depense,
                          montant: e.montant,
                          libelle: e.libelle,
                          date: e.date,
                          note: e.note,
                          sousTitre: e.saisiParNom,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SelecteurPeriode extends StatelessWidget {
  const _SelecteurPeriode({required this.periode, required this.onChanged});

  final Periode periode;
  final ValueChanged<Periode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PeriodePreset>(
      value: periode.preset == PeriodePreset.personnalisee ? null : periode.preset,
      decoration: const InputDecoration(labelText: 'Période'),
      items: const [
        DropdownMenuItem(value: PeriodePreset.moisEnCours, child: Text('Ce mois-ci')),
        DropdownMenuItem(value: PeriodePreset.campagneAgricole, child: Text('Campagne (12 mois)')),
        DropdownMenuItem(value: PeriodePreset.tout, child: Text('Tout')),
      ],
      onChanged: (preset) {
        switch (preset) {
          case PeriodePreset.moisEnCours:
            onChanged(Periode.moisEnCours());
            break;
          case PeriodePreset.campagneAgricole:
            onChanged(Periode.campagneAgricole());
            break;
          case PeriodePreset.tout:
            onChanged(Periode.tout());
            break;
          default:
            break;
        }
      },
    );
  }
}
