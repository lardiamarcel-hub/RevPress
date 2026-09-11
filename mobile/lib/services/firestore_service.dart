import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/theme_angles.dart';
import '../models/article.dart';
import '../models/digest.dart';
import '../models/source_config.dart';

/// Point d'accès unique à Firestore : la app ne lit/écrit jamais les
/// collections directement, tout passe par ce service.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _articlesCollection = 'articles';
  static const _digestsCollection = 'digests';
  static const _sourcesCollection = 'sources';
  static const _configDoc = 'config/collecte';

  /// Flux des articles d'un angle thématique donné, du plus récent au plus ancien.
  Stream<List<Article>> watchArticlesByAngle(ThemeAngle angle, {int limit = 50}) {
    return _db
        .collection(_articlesCollection)
        .where('angleThematique', isEqualTo: angle.id)
        .orderBy('datePublication', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Article.fromFirestore).toList());
  }

  /// Récupère un lot d'articles récents (tous angles) pour la recherche plein
  /// texte côté client — approche volontairement simple pour le MVP.
  Future<List<Article>> fetchRecentArticles({int limit = 500}) async {
    final snap = await _db
        .collection(_articlesCollection)
        .orderBy('datePublication', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(Article.fromFirestore).toList();
  }

  Future<List<Article>> fetchArticlesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }
    final results = <Article>[];
    for (final chunk in chunks) {
      final snap = await _db
          .collection(_articlesCollection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snap.docs.map(Article.fromFirestore));
    }
    return results;
  }

  Stream<Digest?> watchDigest(String digestId) {
    return _db.collection(_digestsCollection).doc(digestId).snapshots().map(
          (doc) => doc.exists ? Digest.fromFirestore(doc) : null,
        );
  }

  Stream<List<Digest>> watchDigestHistory({int limit = 60}) {
    return _db
        .collection(_digestsCollection)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Digest.fromFirestore).toList());
  }

  Stream<List<SourceConfig>> watchSources() {
    return _db.collection(_sourcesCollection).orderBy('nom').snapshots().map(
          (snap) => snap.docs.map((d) => SourceConfig.fromFirestore(d.id, d.data())).toList(),
        );
  }

  Future<void> setSourceActive(String sourceId, bool actif) {
    return _db.collection(_sourcesCollection).doc(sourceId).update({'actif': actif});
  }

  Future<void> addSource(SourceConfig source) {
    return _db.collection(_sourcesCollection).doc(source.id).set(source.toFirestore());
  }

  Stream<Map<String, dynamic>> watchCollectionConfig() {
    return _db.doc(_configDoc).snapshots().map((doc) => doc.data() ?? {});
  }

  Future<void> updateCollectionConfig(Map<String, dynamic> patch) {
    return _db.doc(_configDoc).set(patch, SetOptions(merge: true));
  }
}
