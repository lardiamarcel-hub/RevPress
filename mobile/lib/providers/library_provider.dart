import 'package:flutter/foundation.dart';

import '../config/curated_sources.dart';
import '../db/feed_repository.dart';
import '../models/feed.dart';
import '../models/folder.dart';
import '../services/feed_discovery_service.dart';
import '../services/feed_sync_service.dart';

class ImportResult {
  const ImportResult({required this.ajoutes, required this.echecs});
  final int ajoutes;
  final List<String> echecs; // noms des sources non résolues
}

/// Bibliothèque de l'utilisateur : dossiers et flux, et actions dessus
/// (ajout, modification, suppression, actualisation). Tout est local.
class LibraryProvider extends ChangeNotifier {
  LibraryProvider({FeedRepository? repository, FeedSyncService? syncService})
      : repository = repository ?? FeedRepository(),
        _sync = syncService ?? FeedSyncService(repository: repository ?? FeedRepository()) {
    _load();
  }

  final FeedRepository repository;
  final FeedSyncService _sync;
  final FeedDiscoveryService _discovery = FeedDiscoveryService();

  List<Folder> _folders = [];
  List<Feed> _feeds = [];
  Map<String, int> _unreadCounts = {};
  bool _loading = true;
  bool _syncingAll = false;

  List<Folder> get folders => _folders;
  List<Feed> get feeds => _feeds;
  bool get loading => _loading;
  bool get syncingAll => _syncingAll;

  int unreadCountForFeed(String feedId) => _unreadCounts[feedId] ?? 0;

  int unreadCountForFolder(String folderId) {
    return _feeds
        .where((f) => f.folderId == folderId)
        .fold(0, (sum, f) => sum + unreadCountForFeed(f.id));
  }

  int get unreadCountTotal => _unreadCounts.values.fold(0, (a, b) => a + b);

  List<Feed> feedsInFolder(String? folderId) => _feeds.where((f) => f.folderId == folderId).toList();

  Future<void> _load() async {
    _folders = await repository.listFolders();
    _feeds = await repository.listFeeds();
    _unreadCounts = await repository.unreadCountsByFeed();
    _loading = false;
    notifyListeners();
  }

  /// À appeler après qu'un écran a marqué un article lu/non-lu ou favori
  /// directement via [FeedRepository], pour que les compteurs affichés
  /// dans la bibliothèque restent à jour.
  Future<void> refreshUnreadCounts() async {
    _unreadCounts = await repository.unreadCountsByFeed();
    notifyListeners();
  }

  Future<void> _reloadLibrary() async {
    _folders = await repository.listFolders();
    _feeds = await repository.listFeeds();
    _unreadCounts = await repository.unreadCountsByFeed();
    notifyListeners();
  }

  // --- Dossiers ---

  Future<void> createFolder(String nom) async {
    await repository.createFolder(nom);
    await _reloadLibrary();
  }

  Future<void> renameFolder(String id, String nom) async {
    await repository.renameFolder(id, nom);
    await _reloadLibrary();
  }

  Future<void> deleteFolder(String id) async {
    await repository.deleteFolder(id);
    await _reloadLibrary();
  }

  // --- Flux ---

  /// Résout l'adresse saisie par l'utilisateur puis ajoute le flux trouvé.
  Future<Feed> addFeedFromUrl({
    required String url,
    String? nomPersonnalise,
    String? folderId,
    bool accesLimite = false,
  }) async {
    final discovered = await _discovery.discover(url);
    final nom = (nomPersonnalise != null && nomPersonnalise.trim().isNotEmpty)
        ? nomPersonnalise.trim()
        : (discovered.parsed.title.isNotEmpty ? discovered.parsed.title : discovered.siteUrl);
    final feed = await repository.addFeed(
      nom: nom,
      siteUrl: discovered.siteUrl,
      fluxUrl: discovered.feedUrl,
      folderId: folderId,
      accesLimite: accesLimite,
    );
    // Enregistre déjà les articles trouvés lors de la découverte, pour un
    // premier affichage immédiat sans attendre un second aller-retour réseau.
    await _sync.syncFeed(feed);
    await _reloadLibrary();
    return feed;
  }

  Future<void> updateFeed(Feed feed) async {
    await repository.updateFeed(feed);
    await _reloadLibrary();
  }

  Future<void> deleteFeed(String id) async {
    await repository.deleteFeed(id);
    await _reloadLibrary();
  }

  Future<void> refreshFeed(String feedId) async {
    final feed = _feeds.firstWhere((f) => f.id == feedId);
    await _sync.syncFeed(feed);
    await _reloadLibrary();
  }

  Future<int> refreshAll() async {
    _syncingAll = true;
    notifyListeners();
    try {
      final result = await _sync.syncAll(_feeds);
      await _reloadLibrary();
      return result.newArticles;
    } finally {
      _syncingAll = false;
      notifyListeners();
    }
  }

  /// Ajoute la sélection de sources suggérées, en créant les dossiers
  /// nécessaires et en ignorant les sources déjà présentes.
  Future<ImportResult> importCuratedSources() async {
    var ajoutes = 0;
    final echecs = <String>[];
    final folderIdByName = <String, String>{
      for (final f in _folders) f.nom: f.id,
    };
    final existingUrls = _feeds.map((f) => f.fluxUrl).toSet();

    for (final source in curatedSources) {
      try {
        var folderId = folderIdByName[source.dossier];
        if (folderId == null) {
          final folder = await repository.createFolder(source.dossier);
          folderId = folder.id;
          folderIdByName[source.dossier] = folderId;
        }
        final discovered = await _discovery.discover(source.url);
        if (existingUrls.contains(discovered.feedUrl)) continue;
        final feed = await repository.addFeed(
          nom: source.nom,
          siteUrl: discovered.siteUrl,
          fluxUrl: discovered.feedUrl,
          folderId: folderId,
          accesLimite: source.accesLimite,
        );
        existingUrls.add(discovered.feedUrl);
        await _sync.syncFeed(feed);
        ajoutes++;
      } catch (_) {
        echecs.add(source.nom);
      }
    }

    await _reloadLibrary();
    return ImportResult(ajoutes: ajoutes, echecs: echecs);
  }
}
