import 'package:flutter/foundation.dart';

import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._firestoreService) {
    _subscribe();
  }

  final FirestoreService _firestoreService;

  String _frequence = 'quotidien';
  bool _notificationsActives = true;
  bool _loading = true;

  String get frequence => _frequence;
  bool get notificationsActives => _notificationsActives;
  bool get loading => _loading;

  void _subscribe() {
    _firestoreService.watchCollectionConfig().listen((config) {
      _frequence = config['frequence'] as String? ?? 'quotidien';
      _notificationsActives = config['notificationsActives'] as bool? ?? true;
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> setFrequence(String value) async {
    _frequence = value;
    notifyListeners();
    await _firestoreService.updateCollectionConfig({'frequence': value});
  }

  Future<void> setNotificationsActives(bool value) async {
    _notificationsActives = value;
    notifyListeners();
    await _firestoreService.updateCollectionConfig({'notificationsActives': value});
    await NotificationService.instance.setNotificationsEnabled(value);
  }
}
