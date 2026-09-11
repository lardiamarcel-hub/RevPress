import 'package:flutter/foundation.dart';

import '../config/theme_angles.dart';
import '../models/article.dart';
import '../services/firestore_service.dart';

/// Fournit, pour un angle thématique donné, le flux d'articles en cache.
class ArticlesProvider extends ChangeNotifier {
  ArticlesProvider(this._firestoreService, this.angle) {
    _subscribe();
  }

  final FirestoreService _firestoreService;
  final ThemeAngle angle;

  List<Article> _articles = [];
  bool _loading = true;
  Object? _error;

  List<Article> get articles => _articles;
  bool get loading => _loading;
  Object? get error => _error;

  void _subscribe() {
    _firestoreService.watchArticlesByAngle(angle).listen(
      (items) {
        _articles = items;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e;
        _loading = false;
        notifyListeners();
      },
    );
  }
}
