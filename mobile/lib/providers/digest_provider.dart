import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/article.dart';
import '../models/digest.dart';
import '../services/firestore_service.dart';

/// Gère le digest du jour : identifiant `YYYY-MM-DD`, son contenu, et les
/// articles complets qui le composent.
class DigestProvider extends ChangeNotifier {
  DigestProvider(this._firestoreService) {
    _subscribeToday();
  }

  final FirestoreService _firestoreService;

  Digest? _todayDigest;
  List<Article> _topArticles = [];
  bool _loading = true;

  Digest? get todayDigest => _todayDigest;
  List<Article> get topArticles => _topArticles;
  bool get loading => _loading;

  static String todayDigestId() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void _subscribeToday() {
    _firestoreService.watchDigest(todayDigestId()).listen((digest) async {
      _todayDigest = digest;
      if (digest != null && digest.syntheseGlobale.isNotEmpty) {
        _topArticles = await _firestoreService.fetchArticlesByIds(digest.syntheseGlobale);
      } else {
        _topArticles = [];
      }
      _loading = false;
      notifyListeners();
    });
  }
}
