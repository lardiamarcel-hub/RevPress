import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'feed_parser.dart';

class FeedDiscoveryException implements Exception {
  FeedDiscoveryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DiscoveredFeed {
  const DiscoveredFeed({required this.feedUrl, required this.siteUrl, required this.parsed});
  final String feedUrl;
  final String siteUrl;
  final ParsedFeed parsed;
}

const _commonFeedPaths = [
  '/feed',
  '/feed/',
  '/rss',
  '/rss/',
  '/rss.xml',
  '/atom.xml',
  '/feeds/posts/default', // Blogger
  '/spip.php?page=backend', // SPIP, utilisé par plusieurs sites d'Afrique de l'Ouest
];

/// Récupère et découvre des flux RSS/Atom, sans jamais passer par un
/// serveur intermédiaire : les requêtes partent directement de l'appareil.
class FeedDiscoveryService {
  FeedDiscoveryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Récupère l'URL donnée et la parse comme flux RSS/Atom. Ne tente aucune
  /// découverte — utilisé pour actualiser un flux déjà connu. Laisse
  /// remonter les erreurs réseau et [FeedParseException].
  Future<ParsedFeed> fetchAndParse(String feedUrl) async {
    final response = await _client.get(Uri.parse(feedUrl)).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FeedDiscoveryException('Le serveur a répondu ${response.statusCode}.');
    }
    return parseFeedContent(response.body);
  }

  /// À partir d'une adresse saisie par l'utilisateur (site ou flux direct),
  /// retrouve et valide un flux RSS/Atom exploitable.
  Future<DiscoveredFeed> discover(String input) async {
    final normalized = _normalizeUrl(input);

    final direct = await _tryFetchAndParse(normalized);
    if (direct != null) {
      return DiscoveredFeed(feedUrl: normalized, siteUrl: normalized, parsed: direct);
    }

    final fromHtml = await _discoverFromHtml(normalized);
    if (fromHtml != null) {
      final parsed = await _tryFetchAndParse(fromHtml);
      if (parsed != null) {
        return DiscoveredFeed(feedUrl: fromHtml, siteUrl: normalized, parsed: parsed);
      }
    }

    final base = Uri.parse(normalized);
    for (final path in _commonFeedPaths) {
      final candidate = base.resolve(path).toString();
      final parsed = await _tryFetchAndParse(candidate);
      if (parsed != null) {
        return DiscoveredFeed(feedUrl: candidate, siteUrl: normalized, parsed: parsed);
      }
    }

    throw FeedDiscoveryException(
      "Impossible de trouver un flux RSS à cette adresse. Essayez l'adresse exacte du flux "
      '(par exemple https://lesite.com/feed).',
    );
  }

  String _normalizeUrl(String input) {
    var value = input.trim();
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    return value;
  }

  Future<ParsedFeed?> _tryFetchAndParse(String url) async {
    try {
      return await fetchAndParse(url);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _discoverFromHtml(String url) async {
    try {
      final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final document = html_parser.parse(response.body);
      final links = document.querySelectorAll('link[rel="alternate"]');
      for (final link in links) {
        final type = link.attributes['type'] ?? '';
        final href = link.attributes['href'];
        if (href == null || href.isEmpty) continue;
        if (type.contains('rss') || type.contains('atom') || type.contains('xml')) {
          return Uri.parse(url).resolve(href).toString();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
