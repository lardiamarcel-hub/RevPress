import '../db/feed_repository.dart';
import '../models/article.dart';
import '../models/feed.dart';
import 'feed_discovery_service.dart';

class FeedSyncResult {
  const FeedSyncResult({required this.newArticles, required this.errors});

  final int newArticles;

  /// feedId -> message d'erreur, pour les flux dont l'actualisation a échoué.
  final Map<String, String> errors;
}

/// Récupère et enregistre les nouveaux articles d'un ou plusieurs flux,
/// directement depuis l'appareil (aucun serveur).
class FeedSyncService {
  FeedSyncService({required this.repository, FeedDiscoveryService? discoveryService})
      : _discovery = discoveryService ?? FeedDiscoveryService();

  final FeedRepository repository;
  final FeedDiscoveryService _discovery;

  Future<int> syncFeed(Feed feed) async {
    try {
      final parsed = await _discovery.fetchAndParse(feed.fluxUrl);
      final drafts = parsed.items
          .map((item) => ArticleDraft(
                guid: item.guid,
                title: item.title,
                link: item.link,
                snippet: item.snippet,
                publishedAt: item.publishedAt,
              ))
          .toList();
      final inserted = await repository.upsertArticles(feed.id, drafts);
      await repository.markFeedSynced(feed.id);
      return inserted;
    } catch (e) {
      await repository.markFeedSynced(feed.id, erreur: e.toString());
      rethrow;
    }
  }

  Future<FeedSyncResult> syncAll(List<Feed> feeds) async {
    var total = 0;
    final errors = <String, String>{};
    for (final feed in feeds) {
      try {
        total += await syncFeed(feed);
      } catch (e) {
        errors[feed.id] = e.toString();
      }
    }
    return FeedSyncResult(newArticles: total, errors: errors);
  }
}
