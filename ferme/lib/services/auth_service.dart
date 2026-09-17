import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  /// Mode démonstration : essayer l'application sans créer de compte réel.
  /// À désactiver côté Firebase (Authentication → Sign-in method →
  /// Anonymous) une fois la ferme passée en usage réel.
  Future<void> connexionAnonyme() => _auth.signInAnonymously();

  /// Connexion ou inscription via un compte Google. Nécessite le
  /// fournisseur "Google" activé dans Firebase Authentication et le
  /// certificat SHA-1 de signature de l'app enregistré dans les paramètres
  /// du projet Firebase.
  Future<void> connexionGoogle() async {
    final compteGoogle = await _googleSignIn.signIn();
    if (compteGoogle == null) {
      // L'utilisateur a annulé la sélection de compte.
      return;
    }
    final authGoogle = await compteGoogle.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: authGoogle.accessToken,
      idToken: authGoogle.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> deconnexion() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
