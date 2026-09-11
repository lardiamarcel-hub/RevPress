// GENERATED PLACEHOLDER — à remplacer par le fichier produit par :
//   flutterfire configure --project=<votre-projet-firebase>
// Ne pas committer les vraies clés d'un projet de production sans vérifier
// la politique de sécurité du dépôt (les clés Firebase côté client ne sont
// pas secrètes mais restent spécifiques à un projet).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions n\'ont pas été générées pour le web. '
        'Exécutez `flutterfire configure`.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne sont pas configurées pour cette plateforme. '
          'Exécutez `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REMPLACER_PAR_FLUTTERFIRE_CONFIGURE',
    appId: 'REMPLACER_PAR_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REMPLACER_PAR_FLUTTERFIRE_CONFIGURE',
    projectId: 'revue-eco-bf',
    storageBucket: 'revue-eco-bf.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REMPLACER_PAR_FLUTTERFIRE_CONFIGURE',
    appId: 'REMPLACER_PAR_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REMPLACER_PAR_FLUTTERFIRE_CONFIGURE',
    projectId: 'revue-eco-bf',
    storageBucket: 'revue-eco-bf.appspot.com',
    iosBundleId: 'bf.cci.revueecobf',
  );
}
