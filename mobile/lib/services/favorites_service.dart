import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favoris (articles enregistrés pour plus tard). Stockés localement sur
/// l'appareil : pas besoin d'un backend pour cette fonctionnalité, elle
/// fonctionne même avant que Firebase soit configuré.
class FavoritesService extends ChangeNotifier {
  static const _prefsKey = 'favoris_article_ids';

  Set<String> _ids = {};
  bool _loaded = false;

  Set<String> get ids => _ids;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids = (prefs.getStringList(_prefsKey) ?? const []).toSet();
    _loaded = true;
    notifyListeners();
  }

  bool isFavorite(String articleId) => _ids.contains(articleId);

  Future<void> toggle(String articleId) async {
    if (_ids.contains(articleId)) {
      _ids.remove(articleId);
    } else {
      _ids.add(articleId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _ids.toList());
  }
}
