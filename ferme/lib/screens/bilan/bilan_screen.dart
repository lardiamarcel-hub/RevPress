import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/depense.dart';
import '../../models/recette.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatage.dart';
import '../../utils/periode.dart';
import '../../widgets/deconnexion_action.dart';

/// Écran Promoteur (et Superviseur) : totaux dépenses/recettes/bénéfice net
/// sur une période choisie, répartition des dépenses par ligne, export PDF
/// ou partage simple.
class BilanScreen extends StatefulWidget {
  const BilanScreen({super.key});

  @override
  State<BilanScreen> createState() => _BilanScreenState();
}

class _BilanScreenState extends State<BilanScreen> {
  Periode _periode = Periode.moisEnCours();

  static const _palette = [
    Color(0xFF2E7D32),
    Color(0xFF66BB6A),
    Color(0xFFA5D6A7),
    Color(0xFFF9A825),
    Color(0xFFEF6C00),
    Color(0xFFC62828),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Bilan'), actions: const [DeconnexionAction()]),
      body: StreamBuilder<List<Depense>>(
        stream: session.firestore.depensesStream(debut: _periode.debut, fin: _periode.fin),
        builder: (context, depSnap) {
          return StreamBuilder<List<Recette>>(
            stream: session.firestore.recettesStream(debut: _periode.debut, fin: _periode.fin),
            builder: (context, recSnap) {
              if (!depSnap.hasData || !recSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final depenses = depSnap.data!;
              final recettes = recSnap.data!;
              final totalDepenses = depenses.fold<double>(0, (s, d) => s + d.montant);
              final totalRecettes = recettes.fold<double>(0, (s, r) => s + r.montant);
              final benefice = totalRecettes - totalDepenses;

              final parLigne = <String, double>{};
              for (final d in depenses) {
                parLigne[d.ligne] = (parLigne[d.ligne] ?? 0) + d.montant;
              }
              final lignesTriees = parLigne.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SelecteurPeriodeBilan(
                    periode: _periode,
                    onChanged: (p) => setState(() => _periode = p),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _CarteTotal(label: 'Recettes', montant: totalRecettes, couleur: AppTheme.orRecette)),
                      const SizedBox(width: 8),
                      Expanded(child: _CarteTotal(label: 'Dépenses', montant: totalDepenses, couleur: AppTheme.orDepense)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _CarteTotal(
                    label: 'Bénéfice net',
                    montant: benefice,
                    couleur: benefice >= 0 ? AppTheme.orRecette : AppTheme.orDepense,
                  ),
                  const SizedBox(height: 24),
                  Text('Répartition des dépenses par ligne', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (lignesTriees.isEmpty)
                    const Text('Aucune dépense sur cette période.')
                  else ...[
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            for (var i = 0; i < lignesTriees.length; i++)
                              PieChartSectionData(
                                value: lignesTriees[i].value,
                                color: _palette[i % _palette.length],
                                title: '',
                                radius: 60,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(lignesTriees.length, (i) {
                      final entree = lignesTriees[i];
                      final pourcentage = totalDepenses == 0 ? 0 : (entree.value / totalDepenses * 100);
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(radius: 8, backgroundColor: _palette[i % _palette.length]),
                        title: Text(entree.key),
                        trailing: Text('${formaterMontant(entree.value)} (${pourcentage.toStringAsFixed(0)}%)'),
                      );
                    }),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Exporter / partager le bilan (PDF)'),
                    onPressed: () => _exporterPdf(
                      periodeLibelle: _periode.libelle,
                      totalDepenses: totalDepenses,
                      totalRecettes: totalRecettes,
                      benefice: benefice,
                      parLigne: lignesTriees,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _exporterPdf({
    required String periodeLibelle,
    required double totalDepenses,
    required double totalRecettes,
    required double benefice,
    required List<MapEntry<String, double>> parLigne,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Bilan de la ferme', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.Text('Période : $periodeLibelle'),
            pw.SizedBox(height: 16),
            pw.Text('Total recettes : ${formaterMontant(totalRecettes)}'),
            pw.Text('Total dépenses : ${formaterMontant(totalDepenses)}'),
            pw.Text('Bénéfice net : ${formaterMontant(benefice)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Répartition des dépenses par ligne', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Ligne', 'Montant'],
              data: parLigne.map((e) => [e.key, formaterMontant(e.value)]).toList(),
            ),
          ],
        ),
      ),
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: 'bilan-ferme.pdf');
  }
}

class _CarteTotal extends StatelessWidget {
  const _CarteTotal({
    required this.label,
    required this.montant,
    required this.couleur,
  });

  final String label;
  final double montant;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: couleur.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: couleur)),
            const SizedBox(height: 4),
            Text(
              formaterMontant(montant),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: couleur),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelecteurPeriodeBilan extends StatelessWidget {
  const _SelecteurPeriodeBilan({required this.periode, required this.onChanged});

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
