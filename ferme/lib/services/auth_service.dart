import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> connexion(String email, String motDePasse) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: motDePasse,
    );
  }

  Future<void> inscription(String email, String motDePasse) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: motDePasse,
    );
  }

  Future<void> deconnexion() => _auth.signOut();
}
