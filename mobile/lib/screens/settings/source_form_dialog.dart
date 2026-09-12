import 'package:flutter/material.dart';

import '../../config/theme_angles.dart';
import '../../models/source_config.dart';

/// Formulaire d'ajout/modification d'une source, affiché en boîte de
/// dialogue. Retourne le [SourceConfig] saisi, ou `null` si l'utilisateur a
/// annulé. Pour une nouvelle source, `existing` est `null` et l'id retourné
/// est vide (un identifiant Firestore est généré à l'enregistrement).
Future<SourceConfig?> showSourceFormDialog(BuildContext context, {SourceConfig? existing}) {
  return showDialog<SourceConfig>(
    context: context,
    builder: (context) => _SourceFormDialog(existing: existing),
  );
}

class _SourceFormDialog extends StatefulWidget {
  const _SourceFormDialog({this.existing});

  final SourceConfig? existing;

  @override
  State<_SourceFormDialog> createState() => _SourceFormDialogState();
}

class _SourceFormDialogState extends State<_SourceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _urlController;
  late AccesType _acces;
  late Set<String> _onglets;
  String? _ongletsError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nomController = TextEditingController(text: existing?.nom ?? '');
    _urlController = TextEditingController(text: existing?.url ?? '');
    _acces = existing?.acces ?? AccesType.gratuit;
    _onglets = {...(existing?.onglets ?? const [])};
  }

  @override
  void dispose() {
    _nomController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  bool get _isTransverse => _onglets.contains(transverseOngletId);

  void _toggleTransverse(bool? value) {
    setState(() {
      _ongletsError = null;
      if (value ?? false) {
        _onglets = {transverseOngletId};
      } else {
        _onglets.remove(transverseOngletId);
      }
    });
  }

  void _toggleAngle(ThemeAngle angle, bool? value) {
    setState(() {
      _ongletsError = null;
      _onglets.remove(transverseOngletId);
      if (value ?? false) {
        _onglets.add(angle.id);
      } else {
        _onglets.remove(angle.id);
      }
    });
  }

  void _submit() {
    final formOk = _formKey.currentState!.validate();
    final ongletsOk = _onglets.isNotEmpty;
    setState(() {
      _ongletsError = ongletsOk ? null : 'Sélectionnez au moins un onglet.';
    });
    if (!formOk || !ongletsOk) return;

    final result = SourceConfig(
      id: widget.existing?.id ?? '',
      nom: _nomController.text.trim(),
      url: _urlController.text.trim(),
      acces: _acces,
      onglets: _onglets.toList(),
      actif: widget.existing?.actif ?? true,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Ajouter une source' : 'Modifier la source'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom de la source'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Site web (URL)',
                    hintText: 'https://exemple.com',
                    helperText: 'Laisser vide si vous ne connaissez pas encore l\'URL officielle.',
                    helperMaxLines: 2,
                  ),
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return null;
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return "L'URL doit commencer par http:// ou https://";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text("Type d'accès", style: Theme.of(context).textTheme.labelLarge),
                ...AccesType.values.map(
                  (a) => RadioListTile<AccesType>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(a.label),
                    value: a,
                    groupValue: _acces,
                    onChanged: (v) => setState(() => _acces = v!),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Onglets couverts', style: Theme.of(context).textTheme.labelLarge),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Tous les onglets (transverse)'),
                  value: _isTransverse,
                  onChanged: _toggleTransverse,
                ),
                ...ThemeAngleX.navigationTabs.map(
                  (angle) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(angle.label),
                    value: _isTransverse || _onglets.contains(angle.id),
                    onChanged: _isTransverse ? null : (v) => _toggleAngle(angle, v),
                  ),
                ),
                if (_ongletsError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_ongletsError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        FilledButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }
}
