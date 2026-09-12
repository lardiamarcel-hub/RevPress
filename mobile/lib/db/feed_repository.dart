import 'package:sqflite/sqflite.dart';

import '../models/article.dart';
import '../models/feed.dart';
import '../models/folder.dart';
import 'app_database.dart';

/// Accès unique à la base locale : dossiers, flux, articles. Toute la
/// bibliothèque de l'utilisateur (et son historique de lecture) vit ici,
/// sur l'appareil, sans jamais passer par un serveur.
class FeedRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  // --- Dossiers ---

  Future<List<Folder>> listFolders() async {
    final db = await _db;
    final rows = await db.query('folders', orderBy: 'ordre ASC');
    return rows.map(_folderFromRow).toList();
  }

  Future<Folder> createFolder(String nom) async {
    final db = await _db;
    final ordre = await _count(db, 'folders');
    final folder = Folder(id: _newId(), nom: nom, ordre: ordre);
    await db.insert('folders', {'id': folder.id, 'nom': folder.nom, 'ordre': folder.ordre});
    return folder;
  }

  Future<void> renameFolder(String id, String nom) async {
    final db = await _db;
    await db.update('folders', {'nom': nom}, where: 'id = ?', whereArgs: [id]);
  }

  /// Supprime le dossier ; les flux qu'il contenait redeviennent "non classés".
  Future<void> deleteFolder(String id) async {
    final db = await _db;
    await db.update('feeds', {'folder_id': null}, where: 'folder_id = ?', whereArgs: [id]);
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  // --- Flux ---

  Future<List<Feed>> listFeeds() async {
    final db = await _db;
    final rows = await db.query('feeds', orderBy: 'ordre ASC');
    return rows.map(_feedFromRow).toList();
  }

  Future<bool> feedUrlExists(String fluxUrl) async {
    final db = await _db;
    final rows = await db.query('feeds', where: 'flux_url = ?', whereArgs: [fluxUrl], limit: 1);
    return rows.isNotEmpty;
  }

  Future<Feed> addFeed({
    required String nom,
    required String siteUrl,
    required String fluxUrl,
    String? folderId,
    bool accesLimite = false,
  }) async {
    final db = await _db;
    final ordre = await _count(db, 'feeds');
    final feed = Feed(
      id: _newId(),
      nom: nom,
      siteUrl: siteUrl,
      fluxUrl: fluxUrl,
      folderId: folderId,
      accesLimite: accesLimite,
      ordre: ordre,
      derniereMaj: null,
      derniereErreur: null,
    );
    await db.insert('feeds', _feedToRow(feed));
    return feed;
  }

  Future<void> updateFeed(Feed feed) async {
    final db = await _db;
    await db.update('feeds', _feedToRow(feed), where: 'id = ?', whereArgs: [feed.id]);
  }

  Future<void> deleteFeed(String id) async {
    final db = await _db;
    await db.delete('feeds', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markFeedSynced(String id, {String? erreur}) async {
    final db = await _db;
    await db.update(
      'feeds',
      {'derniere_maj': DateTime.now().millisecondsSinceEpoch, 'derniere_erreur': erreur},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Articles ---

  /// Insère les nouveaux articles d'un flux (ignore ceux déjà connus, par
  /// identifiant). Retourne le nombre d'articles réellement ajoutés.
  Future<int> upsertArticles(String feedId, List<ArticleDraft> drafts) async {
    final db = await _db;
    var inserted = 0;
    await db.transaction((txn) async {
      for (final draft in drafts) {
        final id = _articleId(feedId, draft.guid);
        final existing = await txn.query('articles', where: 'id = ?', whereArgs: [id], limit: 1);
        if (existing.isNotEmpty) continue;
        await txn.insert('articles', {
          'id': id,
          'feed_id': feedId,
          'titre': draft.title,
          'lien': draft.link,
          'contenu': draft.snippet,
          'date_publication': draft.publishedAt.millisecondsSinceEpoch,
          'date_ajout': DateTime.now().millisecondsSinceEpoch,
          'lu': 0,
          'favori': 0,
        });
        inserted++;
      }
    });
    return inserted;
  }

  Future<List<Article>> listArticles({
    String? folderId,
    String? feedId,
    bool favoritesOnly = false,
    bool unreadOnly = false,
    String? recherche,
    int limit = 500,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (feedId != null) {
      where.add('a.feed_id = ?');
      args.add(feedId);
    } else if (folderId != null) {
      where.add('f.folder_id = ?');
      args.add(folderId);
    }
    if (favoritesOnly) where.add('a.favori = 1');
    if (unreadOnly) where.add('a.lu = 0');
    if (recherche != null && recherche.trim().isNotEmpty) {
      where.add('(a.titre LIKE ? OR a.contenu LIKE ? OR f.nom LIKE ?)');
      final motif = '%${recherche.trim()}%';
      args.addAll([motif, motif, motif]);
    }
    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT a.*, f.nom AS feed_nom
      FROM articles a
      JOIN feeds f ON f.id = a.feed_id
      $whereClause
      ORDER BY a.date_publication DESC
      LIMIT ?
    ''', [...args, limit]);
    return rows.map(_articleFromRow).toList();
  }

  Future<Article?> getArticle(String id) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT a.*, f.nom AS feed_nom
      FROM articles a
      JOIN feeds f ON f.id = a.feed_id
      WHERE a.id = ?
      LIMIT 1
    ''', [id]);
    if (rows.isEmpty) return null;
    return _articleFromRow(rows.first);
  }

  Future<void> setRead(String articleId, bool lu) async {
    final db = await _db;
    await db.update('articles', {'lu': lu ? 1 : 0}, where: 'id = ?', whereArgs: [articleId]);
  }

  Future<void> setFavorite(String articleId, bool favori) async {
    final db = await _db;
    await db.update('articles', {'favori': favori ? 1 : 0}, where: 'id = ?', whereArgs: [articleId]);
  }

  /// Enregistre le résumé généré par l'IA à la demande, pour ne pas avoir à
  /// le regénérer (et le refacturer) à chaque ouverture de l'article.
  Future<void> setAiSummary(String articleId, String resumeIa) async {
    final db = await _db;
    await db.update('articles', {'resume_ia': resumeIa}, where: 'id = ?', whereArgs: [articleId]);
  }

  // --- Réglages (clé/valeur) ---

  Future<String?> getSetting(String cle) async {
    final db = await _db;
    final rows = await db.query('settings', where: 'cle = ?', whereArgs: [cle], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['valeur'] as String?;
  }

  Future<void> setSetting(String cle, String? valeur) async {
    final db = await _db;
    if (valeur == null || valeur.isEmpty) {
      await db.delete('settings', where: 'cle = ?', whereArgs: [cle]);
    } else {
      await db.insert(
        'settings',
        {'cle': cle, 'valeur': valeur},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> markAllRead({String? folderId, String? feedId}) async {
    final db = await _db;
    if (feedId != null) {
      await db.update('articles', {'lu': 1}, where: 'feed_id = ?', whereArgs: [feedId]);
    } else if (folderId != null) {
      await db.rawUpdate(
        'UPDATE articles SET lu = 1 WHERE feed_id IN (SELECT id FROM feeds WHERE folder_id = ?)',
        [folderId],
      );
    } else {
      await db.update('articles', {'lu': 1});
    }
  }

  /// Nombre d'articles non lus, par flux (`feed_id -> compte`).
  Future<Map<String, int>> unreadCountsByFeed() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT feed_id, COUNT(*) AS c FROM articles WHERE lu = 0 GROUP BY feed_id');
    return {for (final r in rows) r['feed_id'] as String: (r['c'] as int?) ?? 0};
  }

  Future<int> _count(Database db, String table) async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return (rows.first['c'] as int?) ?? 0;
  }

  Folder _folderFromRow(Map<String, Object?> row) =>
      Folder(id: row['id'] as String, nom: row['nom'] as String, ordre: row['ordre'] as int);

  Feed _feedFromRow(Map<String, Object?> row) => Feed(
        id: row['id'] as String,
        nom: row['nom'] as String,
        siteUrl: row['site_url'] as String? ?? '',
        fluxUrl: row['flux_url'] as String,
        folderId: row['folder_id'] as String?,
        accesLimite: ((row['acces_limite'] as int?) ?? 0) == 1,
        ordre: row['ordre'] as int,
        derniereMaj: row['derniere_maj'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['derniere_maj'] as int)
            : null,
        derniereErreur: row['derniere_erreur'] as String?,
      );

  Map<String, Object?> _feedToRow(Feed f) => {
        'id': f.id,
        'nom': f.nom,
        'site_url': f.siteUrl,
        'flux_url': f.fluxUrl,
        'folder_id': f.folderId,
        'acces_limite': f.accesLimite ? 1 : 0,
        'ordre': f.ordre,
        'derniere_maj': f.derniereMaj?.millisecondsSinceEpoch,
        'derniere_erreur': f.derniereErreur,
      };

  Article _articleFromRow(Map<String, Object?> row) => Article(
        id: row['id'] as String,
        feedId: row['feed_id'] as String,
        feedNom: row['feed_nom'] as String,
        titre: row['titre'] as String,
        lien: row['lien'] as String,
        contenu: row['contenu'] as String? ?? '',
        resumeIa: row['resume_ia'] as String?,
        datePublication: DateTime.fromMillisecondsSinceEpoch(row['date_publication'] as int),
        lu: ((row['lu'] as int?) ?? 0) == 1,
        favori: ((row['favori'] as int?) ?? 0) == 1,
      );

  String _articleId(String feedId, String guid) => '$feedId::${guid.hashCode}';

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  int _counter = 0;
}
