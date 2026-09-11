import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/source_config.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';

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
                const Divider(),
                const _SectionHeader('Notifications'),
                SwitchListTile(
                  title: const Text('Notifier quand le digest est prêt'),
                  value: settings.notificationsActives,
                  onChanged: settings.setNotificationsActives,
                ),
                const Divider(),
                const _SectionHeader('Sources suivies'),
                const _SourcesList(),
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

class _SourcesList extends StatelessWidget {
  const _SourcesList();

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    return StreamBuilder<List<SourceConfig>>(
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
            child: Text('Aucune source configurée. Exécutez la fonction `seedSources` côté backend.'),
          );
        }
        return Column(
          children: sources
              .map((source) => SwitchListTile(
                    title: Text(source.nom),
                    subtitle: Text('${source.domaine} · ${source.methodeCollecte}'
                        '${source.accesPayant ? ' · payant (titre + lien)' : ''}'),
                    value: source.actif,
                    onChanged: (value) => firestoreService.setSourceActive(source.id, value),
                  ))
              .toList(),
        );
      },
    );
  }
}
