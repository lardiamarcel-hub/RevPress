import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';

/// Gestion des lignes (catégories) de dépense — réservée au Superviseur.
class LignesScreen extends StatefulWidget {
  const LignesScreen({super.key});

  @override
  State<LignesScreen> createState() => _LignesScreenState();
}

class _LignesScreenState extends State<LignesScreen> {
  final _nouvelleLigneCtrl = TextEditingController();

  @override
  void dispose() {
    _nouvelleLigneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Lignes de dépense')),
      body: StreamBuilder<List<String>>(
        stream: session.firestore.lignesStream(),
        builder: (context, snap) {
          final lignes = List<String>.from(snap.data ?? []);
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lignes.length,
                  itemBuilder: (context, i) {
                    final ligne = lignes[i];
                    return Card(
                      child: ListTile(
                        title: Text(ligne),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            final copie = List<String>.from(lignes)..removeAt(i);
                            session.firestore.definirLignes(copie);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nouvelleLigneCtrl,
                        decoration: const InputDecoration(labelText: 'Nouvelle ligne'),
                        onSubmitted: (_) => _ajouter(lignes),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () => _ajouter(lignes), child: const Text('Ajouter')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _ajouter(List<String> lignes) {
    final valeur = _nouvelleLigneCtrl.text.trim();
    if (valeur.isEmpty || lignes.contains(valeur)) return;
    final session = context.read<SessionProvider>();
    session.firestore.definirLignes([...lignes, valeur]);
    _nouvelleLigneCtrl.clear();
  }
}
