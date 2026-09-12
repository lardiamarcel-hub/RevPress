import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme_angles.dart';
import '../../models/source_config.dart';
import '../../providers/settings_provider.dart';
import '../../services/cloud_functions_service.dart';
import '../../services/firestore_service.dart';
import 'source_form_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsProvider>(
      create: (context) => SettingsProvider(context.read<FirestoreService>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Réglages')),
        body: Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            if (settings.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              children: [
                const _SectionHeader('Collecte'),
                RadioListTile<String>(
                  title: const Text('Quotidienne'),
                  subtitle: const Text('Une nouvelle collecte chaque matin à 06h00'),
                  value: 'quotidien',
                  groupValue: settings.frequence,
                  onChanged: (value) => settings.setFrequence(value!),
                ),
                RadioListTile<String>(
                  title: const Text('Hebdomadaire'),
                  subtitle: const Text('Une collecte le lundi matin'),
                  value: 'hebdomadaire',
                  groupValue: settings.frequence,
                  onChanged: (value) => settings.setFrequence(value!),
                ),
                const _RefreshActions(),
                const Divider(),
                const _SectionHeader('Notifications'),
                SwitchListTile(
                  title: const Text('Notifier quand le digest est prêt'),
                  value: settings.notificationsActives,
                  onChanged: settings.setNotificationsActives,
                ),
                const Divider(),
                const _SourcesSection(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// Actions manuelles côté serveur : importer la liste de sources de départ
/// (rapide, gratuit) et lancer une collecte complète immédiatement au lieu
/// d'attendre la prochaine collecte planifiée (plus long, appelle l'IA).
class _RefreshActions extends StatefulWidget {
  const _RefreshActions();

  @override
  State<_RefreshActions> createState() => _RefreshActionsState();
}

class _RefreshActionsState extends State<_RefreshActions> {
  bool _seeding = false;
  bool _refreshing = false;

  Future<void> _runSeed() async {
    final service = context.read<CloudFunctionsService>();
    setState(() => _seeding = true);
    final result = await service.seedSources();
    if (!mounted) return;
    setState(() => _seeding = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _runRefresh() async {
    final service = context.read<CloudFunctionsService>();
    setState(() => _refreshing = true);
    final result = await service.manualRefresh();
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: _seeding
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_download_outlined),
          title: const Text('Importer la liste de sources'),
          subtitle: const Text('À faire une fois, quand la liste des sources est vide.'),
          onTap: (_seeding || _refreshing) ? null : _runSeed,
        ),
        ListTile(
          leading: _refreshing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          title: const Text('Actualiser maintenant'),
          subtitle: const Text('Lance une collecte complète immédiatement (peut prendre plusieurs minutes).'),
          onTap: (_seeding || _refreshing) ? null : _runRefresh,
        ),
      ],
    );
  }
}

class _SourcesSection extends StatelessWidget {
  const _SourcesSection();

  Future<void> _openAddDialog(BuildContext context, FirestoreService firestoreService) async {
    final result = await showSourceFormDialog(context);
    if (result == null) return;
    final ok = await firestoreService.addSource(result);
    if (context.mounted) _notify(context, ok, 'Source ajoutée.', "Échec de l'ajout de la source.");
  }

  Future<void> _openEditDialog(
    BuildContext context,
    FirestoreService firestoreService,
    SourceConfig source,
  ) async {
    final result = await showSourceFormDialog(context, existing: source);
    if (result == null) return;
    final ok = await firestoreService.updateSource(result);
    if (context.mounted) _notify(context, ok, 'Source modifiée.', 'Échec de la modification.');
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FirestoreService firestoreService,
    SourceConfig source,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette source ?'),
        content: Text('« ${source.nom} » ne sera plus interrogée lors des prochaines collectes.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await firestoreService.deleteSource(source.id);
    if (context.mounted) _notify(context, ok, 'Source supprimée.', 'Échec de la suppression.');
  }

  void _notify(BuildContext context, bool ok, String successMessage, String failureMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? successMessage : failureMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Sources suivies',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openAddDialog(context, firestoreService),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ),
        StreamBuilder<List<SourceConfig>>(
          stream: firestoreService.watchSources(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final sources = snapshot.data!;
            if (sources.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Aucune source configurée pour l'instant. Utilisez « Ajouter » ci-dessus, "
                  'ou patientez le temps que le backend amorce la liste de départ.',
                ),
              );
            }
            return Column(
              children: sources
                  .map((source) => _SourceTile(
                        source: source,
                        onToggleActive: (value) => firestoreService.setSourceActive(source.id, value),
                        onEdit: () => _openEditDialog(context, firestoreService, source),
                        onDelete: () => _confirmDelete(context, firestoreService, source),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final SourceConfig source;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(source.nom),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              source.url.isEmpty ? '(URL non renseignée)' : source.url,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            _Badge(label: source.acces.label),
            ...source.onglets.map((o) => _Badge(label: ongletLabel(o))),
          ],
        ),
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: source.actif, onChanged: onToggleActive),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'modifier') onEdit();
              if (value == 'supprimer') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'modifier', child: Text('Modifier')),
              PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
