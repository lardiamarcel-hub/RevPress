import 'dart:convert';

import 'package:http/http.dart' as http;

/// Clé de réglage sous laquelle la clé API Anthropic de l'utilisateur est
/// stockée localement (table `settings` de la base sqlite).
const anthropicApiKeySettingKey = 'anthropic_api_key';

class AiSummaryException implements Exception {
  AiSummaryException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Génère un résumé d'article à la demande, en appelant directement l'API
/// Claude (Anthropic) avec la clé fournie par l'utilisateur (Réglages).
/// Fonctionnalité entièrement optionnelle : sans clé configurée, le reste de
/// l'app fonctionne normalement.
class AiSummaryService {
  AiSummaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-opus-5';

  Future<String> summarize({
    required String apiKey,
    required String titre,
    required String contenu,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw AiSummaryException(
        'Aucune clé API Anthropic configurée. Ajoutez-en une depuis Réglages.',
      );
    }
    if (contenu.trim().isEmpty) {
      throw AiSummaryException("Cet article n'a pas d'extrait à résumer.");
    }

    final prompt =
        'Résume cet article de presse économique en 2 à 3 phrases claires, en '
        "français, en te basant UNIQUEMENT sur le texte fourni ci-dessous — n'invente "
        'aucune information absente de ce texte.\n\n'
        'Titre : $titre\n\n'
        'Extrait : $contenu';

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey.trim(),
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 300,
              'output_config': {'effort': 'low'},
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw AiSummaryException("Échec de connexion à l'API Anthropic : $e");
    }

    if (response.statusCode == 401) {
      throw AiSummaryException('Clé API refusée (401) — vérifiez-la dans Réglages.');
    }
    if (response.statusCode != 200) {
      throw AiSummaryException("Erreur de l'API Anthropic (${response.statusCode}).");
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AiSummaryException("Réponse illisible de l'API Anthropic.");
    }

    final content = data['content'];
    if (content is! List) {
      throw AiSummaryException("Réponse de l'IA sans contenu exploitable.");
    }
    for (final block in content) {
      if (block is Map<String, dynamic> && block['type'] == 'text') {
        final text = (block['text'] as String?)?.trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }
    throw AiSummaryException("Réponse de l'IA sans texte exploitable.");
  }
}
