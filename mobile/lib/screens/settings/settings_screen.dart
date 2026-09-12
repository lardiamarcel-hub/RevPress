import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../db/feed_repository.dart';
import '../../services/ai_summary_service.dart';

/// Réglages de l'application. Pour l'instant : la clé API Anthropic
/// optionnelle qui active le résumé par IA à la demande sur un article.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<FeedRepository>();
    final key = await repo.getSetting(anthropicApiKeySettingKey);
    if (!mounted) return;
    setState(() {
      _controller.text = key ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = context.read<FeedRepository>();
    await repo.setSetting(anthropicApiKeySettingKey, _controller.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_controller.text.trim().isEmpty ? 'Clé API retirée.' : 'Clé API enregistrée.')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Résumé par IA (optionnel)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  "Pour générer un résumé en français sur un article, à la demande, l'app "
                  "appelle directement l'API Claude (Anthropic) avec votre propre clé — aucun "
                  'serveur intermédiaire. Cette clé reste uniquement sur cet appareil, dans sa '
                  'base de données locale. Chaque résumé généré est facturé sur votre compte '
                  'Anthropic (quelques fractions de centime).',
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://console.anthropic.com/settings/keys'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    'Créer une clé sur console.anthropic.com →',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Clé API Anthropic',
                    hintText: 'sk-ant-...',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            ),
    );
  }
}
