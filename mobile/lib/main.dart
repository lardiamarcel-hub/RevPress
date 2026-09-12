import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/cloud_functions_service.dart';
import 'services/favorites_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  // L'application doit s'ouvrir et être utilisable sans aucune condition de
  // connexion : si Firebase n'est pas encore configuré pour ce build (pas de
  // vrai projet, pas de backend déployé) ou si le réseau est indisponible,
  // on continue quand même — les écrans affichent alors simplement "aucun
  // article disponible" au lieu de planter au démarrage.
  final firebaseReady = await _initFirebaseSafely();

  runApp(RevueEcoBfApp(firebaseReady: firebaseReady));
}

Future<bool> _initFirebaseSafely() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase indisponible, l\'application démarre en mode hors-ligne : $e');
    return false;
  }

  // Authentification anonyme, requise par les règles Firestore. Un échec
  // (projet non configuré, pas de réseau) ne doit jamais bloquer l'ouverture
  // de l'application — il n'y a de toute façon aucun écran de connexion.
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Authentification anonyme indisponible (pas bloquant) : $e');
  }

  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notifications indisponibles (pas bloquant) : $e');
  }

  return true;
}

class RevueEcoBfApp extends StatelessWidget {
  const RevueEcoBfApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirestoreService>(
          create: (_) => FirestoreService(
            firestore: firebaseReady ? FirebaseFirestore.instance : null,
          ),
        ),
        Provider<CloudFunctionsService>(
          create: (_) => CloudFunctionsService(
            functions: firebaseReady ? FirebaseFunctions.instance : null,
          ),
        ),
        ChangeNotifierProvider<FavoritesService>(
          create: (_) => FavoritesService()..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Revue Éco BF',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const HomeScreen(),
      ),
    );
  }
}
