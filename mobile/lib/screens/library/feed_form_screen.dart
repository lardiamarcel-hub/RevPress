import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/feed.dart';
import '../../providers/library_provider.dart';

const _newFolderSentinel = '__nouveau_dossier__';

/// Formulaire d'ajout (à partir d'une adresse de site ou de flux) ou de
/// modification d'un flux existant.
class FeedFormScreen extends StatefulWidget {
  const FeedFormScreen({super.key, this.existing, this.dossierInitial});

  final Feed? existing;
  final String? dossierInitial;

  @override
  State<FeedFormScreen> createState() => _FeedFormScreenState();
}

class _FeedFormScreenState extends State<FeedFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  late final TextEditingController _nomController;
  final _newFolderController = TextEditingController();
  String? _selectedFolderId;
  bool _accesLimite = false;
  bool _submitting = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _urlController = TextEditingController(text: existing?.siteUrl ?? '');
    _nomController = TextEditingController(text: existing?.nom ?? '');
    _accesLimite = existing?.accesLimite ?? false;
    _selectedFolderId = existing?.folderId;
    if (!_isEdit && widget.dossierInitial != null) {
      // Sera résolu vers l'id une fois les dossiers chargés (voir build()).
      _pendingDossierNom = widget.dossierInitial;
    }
  }

  String? _pendingDossierNom;

  @override
  void dispose() {
    _urlController.dispose();
    _nomController.dispose();
    _newFolderController.dispose();
    super.dispose();
  }

  Future<void> _submit(LibraryProvider library) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      String? folderId = _selectedFolderId;
      if (folderId == _newFolderSentinel) {
        final nom = _newFolderController.text.trim();
        if (nom.isEmpty) {
          throw Exception('Donnez un nom au nouveau dossier.');
        }
        await library.createFolder(nom);
        folderId = library.folders.firstWhere((f) => f.nom == nom).id;
      }

      if (_isEdit) {
        final existing = widget.existing!;
        await library.updateFeed(existing.copyWith(
          nom: _nomController.text.trim(),
          folderId: folderId,
          accesLimite: _accesLimite,
        ));
      } else {
        await library.addFeedFromUrl(
          url: _urlController.text.trim(),
          nomPersonnalise: _nomController.text.trim().isEmpty ? null : _nomController.text.trim(),
          folderId: folderId,
          accesLimite: _accesLimite,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete(LibraryProvider library) async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce flux ?'),
        content: Text('« ${existing.nom} » et ses articles seront supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;
    await library.deleteFeed(existing.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();

    if (_pendingDossierNom != null) {
      final match = library.folders.where((f) => f.nom == _pendingDossierNom);
      if (match.isNotEmpty) {
        _selectedFolderId = match.first.id;
        _pendingDossierNom = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le flux' : 'Ajouter un journal ou un flux RSS'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: _submitting ? null : () => _delete(library),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEdit) ...[
              const Text(
                "Collez l'adresse d'un journal, d'un magazine local ou d'un flux RSS. "
                "Si c'est l'adresse du site, le flux est recherché automatiquement.",
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Adresse du site ou du flux RSS',
                  hintText: 'exemple.com ou exemple.com/feed',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Adresse requise' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _nomController,
              decoration: InputDecoration(
                labelText: _isEdit ? 'Nom' : 'Nom (optionnel, détecté automatiquement sinon)',
              ),
              validator: _isEdit ? (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFolderId,
              decoration: const InputDecoration(labelText: 'Dossier'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Non classé')),
                ...library.folders.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nom))),
                const DropdownMenuItem(value: _newFolderSentinel, child: Text('+ Nouveau dossier…')),
              ],
              onChanged: (value) => setState(() => _selectedFolderId = value),
            ),
            if (_selectedFolderId == _newFolderSentinel) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _newFolderController,
                decoration: const InputDecoration(labelText: 'Nom du nouveau dossier'),
              ),
            ],
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Accès limité (site payant)'),
              subtitle: const Text('Information seulement : le résumé du flux reste affiché.'),
              value: _accesLimite,
              onChanged: (v) => setState(() => _accesLimite = v ?? false),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : () => _submit(library),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEdit ? 'Enregistrer' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
