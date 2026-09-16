import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum SessionStatus {
  chargement,
  deconnecte,
  // Connecté, mais aucun document utilisateurs/{uid} : premier lancement
  // (devient Promoteur) ou inscription sur invitation en attente.
  enAttenteProfil,
  // Connecté avec profil, mais désactivé par le Promoteur.
  compteDesactive,
  pret,
}

class SessionProvider extends ChangeNotifier {
  SessionProvider(this._authService, this._firestoreService) {
    _authSub = _authService.authStateChanges.listen(_onAuthChange);
  }

  final AuthService _authService;
  final FirestoreService _firestoreService;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserProfile?>? _profilSub;

  User? _user;
  UserProfile? _profil;
  SessionStatus _status = SessionStatus.chargement;

  User? get user => _user;
  UserProfile? get profil => _profil;
  SessionStatus get status => _status;
  FirestoreService get firestore => _firestoreService;

  void _onAuthChange(User? user) {
    _user = user;
    _profilSub?.cancel();
    _profilSub = null;

    if (user == null) {
      _profil = null;
      _status = SessionStatus.deconnecte;
      notifyListeners();
      return;
    }

    _status = SessionStatus.chargement;
    notifyListeners();

    _profilSub = _firestoreService.profilStream(user.uid).listen((profil) {
      _profil = profil;
      if (profil == null) {
        _status = SessionStatus.enAttenteProfil;
      } else if (!profil.actif) {
        _status = SessionStatus.compteDesactive;
      } else {
        _status = SessionStatus.pret;
      }
      notifyListeners();
    });
  }

  Future<void> deconnexion() => _authService.deconnexion();

  @override
  void dispose() {
    _authSub?.cancel();
    _profilSub?.cancel();
    super.dispose();
  }
}
