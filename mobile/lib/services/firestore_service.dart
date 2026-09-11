import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/theme_angles.dart';
import '../models/article.dart';
import '../models/digest.dart';
import '../models/source_config.dart';

/// Point d'accès unique à Firestore : la app ne lit/écrit jamais les
/// collections directement, tout passe par ce service.
///
/// `firestore` est `null` quand Firebase n'a pas pu être initialisé (pas de
/// backend configuré, pas de réseau). Dans ce cas, toutes les méthodes
/// renvoient des valeurs vides au lieu de lancer une exception : l'app doit
/// rester utilisable sans aucune condition de connexion.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  static const _articlesCollection = 'articles';
  static const _digestsCollection = 'digests';
  static const _sourcesCollection = 'sources';
  static const _configDoc = 'config/collecte';

  /// Flux des articles d'un angle thématique donné, du plus récent au plus ancien.
  Stream<List<Article>> watchArticlesByAngle(ThemeAngle angle, {int limit = 50}) {
    final db = _db;
    if (db == null) return Stream.value(const []);
    return _safe(
      db
          .collection(_articlesCollection)
          .where('angleThematique', isEqualTo: angle.id)
          .orderBy('datePublication', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs.map(Article.fromFirestore).toList()),
      const <Article>[],
    );
  }

  /// Récupère un lot d'articles récents (tous angles) pour la recherche plein
  /// texte côté client — approche volontairement simple pour le MVP.
  Future<List<Article>> fetchRecentArticles({int limit = 500}) async {
    final db = _db;
    if (db == null) return const [];
    try {
      final snap = await db
          .collection(_articlesCollection)
          .orderBy('datePublication', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(Article.fromFirestore).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Article>> fetchArticlesByIds(List<String> ids) async {
    final db = _db;
    if (db == null || ids.isEmpty) return const [];
    try {
      final chunks = <List<String>>[];
      for (var i = 0; i < ids.length; i += 10) {
        chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
      }
      final results = <Article>[];
      for (final chunk in chunks) {
        final snap = await db.collection(_articlesCollection).where(FieldPath.documentId, whereIn: chunk).get();
        results.addAll(snap.docs.map(Article.fromFirestore));
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  Stream<Digest?> watchDigest(String digestId) {
    final db = _db;
    if (db == null) return Stream.value(null);
    return _safe(
      db.collection(_digestsCollection).doc(digestId).snapshots().map(
            (doc) => doc.exists ? Digest.fromFirestore(doc) : null,
          ),
      null,
    );
  }

  Stream<List<Digest>> watchDigestHistory({int limit = 60}) {
    final db = _db;
    if (db == null) return Stream.value(const []);
    return _safe(
      db
          .collection(_digestsCollection)
          .orderBy('date', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs.map(Digest.fromFirestore).toList()),
      const <Digest>[],
    );
  }

  Stream<List<SourceConfig>> watchSources() {
    final db = _db;
    if (db == null) return Stream.value(const []);
    return _safe(
      db.collection(_sourcesCollection).orderBy('nom').snapshots().map(
            (snap) => snap.docs.map((d) => SourceConfig.fromFirestore(d.id, d.data())).toList(),
          ),
      const <SourceConfig>[],
    );
  }

  Future<void> setSourceActive(String sourceId, bool actif) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection(_sourcesCollection).doc(sourceId).update({'actif': actif});
    } catch (_) {
      // Pas de backend connecté : action silencieusement ignorée.
    }
  }

  Future<void> addSource(SourceConfig source) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection(_sourcesCollection).doc(source.id).set(source.toFirestore());
    } catch (_) {
      // Pas de backend connecté : action silencieusement ignorée.
    }
  }

  Stream<Map<String, dynamic>> watchCollectionConfig() {
    final db = _db;
    if (db == null) return Stream.value(const {});
    return _safe(
      db.doc(_configDoc).snapshots().map((doc) => doc.data() ?? {}),
      const <String, dynamic>{},
    );
  }

  Future<void> updateCollectionConfig(Map<String, dynamic> patch) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.doc(_configDoc).set(patch, SetOptions(merge: true));
    } catch (_) {
      // Pas de backend connecté : action silencieusement ignorée.
    }
  }

  /// Convertit un flux qui pourrait planter (permissions, réseau, projet non
  /// configuré) en flux qui se contente d'émettre [fallback] au lieu de
  /// remonter une erreur jusqu'à l'UI.
  Stream<T> _safe<T>(Stream<T> source, T fallback) {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;
    controller = StreamController<T>.broadcast(
      onListen: () {
        subscription = source.listen(
          controller.add,
          onError: (_) => controller.add(fallback),
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }
}
