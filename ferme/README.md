# Suivi Ferme

Application mobile Android pour gérer à distance les finances d'une
exploitation agricole : dépenses, recettes, bilan, avec trois rôles
(Promoteur, Superviseur, Collaborateur) — voir
[ARCHITECTURE.md](ARCHITECTURE.md) pour le détail technique et
[CAHIER_DES_CHARGES.md](CAHIER_DES_CHARGES.md) pour le contexte d'origine.

## Stack

- **Frontend** : Flutter
- **Backend** : Firebase (Firestore + Firebase Authentication)
- **Build** : APK généré via GitHub Actions (`.github/workflows/build-apk-ferme.yml`)

## Rôles

| Rôle | Qui | Permissions |
|---|---|---|
| **Promoteur** | Propriétaire de la ferme | Lecture complète (Suivi, Bilan) ; gestion des accès ; ne saisit pas |
| **Superviseur** | En charge de la supervision financière | Lecture + écriture complètes (dépenses, recettes, lignes) |
| **Collaborateur** | Fermier / technicien (optionnel) | Imputer une dépense uniquement ; ne voit ni les recettes ni le bilan |

## Configuration Firebase (obligatoire avant le premier build)

1. Créez un projet sur la [console Firebase](https://console.firebase.google.com).
2. Activez **Authentication → Email/Password**.
3. Activez **Firestore Database** (mode production).
4. Déployez les règles de sécurité fournies (`firestore.rules`) et les
   index (`firestore.indexes.json`) — avec la
   [CLI Firebase](https://firebase.google.com/docs/cli) :
   ```bash
   cd ferme
   firebase deploy --only firestore:rules,firestore:indexes
   ```
5. Ajoutez une application Android au projet Firebase (package
   `bf.cci.suivi.ferme`, celui généré par le workflow CI), téléchargez le
   fichier `google-services.json` fourni par Firebase.
6. Encodez-le en base64 et enregistrez-le comme secret du dépôt GitHub sous
   le nom **`FERME_GOOGLE_SERVICES_JSON`** :
   ```bash
   base64 -w0 google-services.json   # macOS : base64 -i google-services.json
   ```
   (Réglages du dépôt → Secrets and variables → Actions → New repository secret)

Sans ce secret, le workflow `build-apk-ferme.yml` échoue volontairement
avec un message explicite plutôt que de produire un APK non fonctionnel.

## Premier lancement (amorçage du compte Promoteur)

Il n'y a pas de compte pré-créé : la toute première personne qui s'inscrit
dans l'application (bouton « Créer un compte » sur l'écran de connexion)
se voit proposer de devenir le **Promoteur** de la ferme. Ce mécanisme est
verrouillé côté serveur (`firestore.rules`) pour n'être utilisable qu'une
seule fois.

Ensuite, le Promoteur invite les autres comptes depuis l'écran
**Gestion des accès** (nom, e-mail, rôle Superviseur ou Collaborateur). La
personne invitée doit alors créer son propre compte dans l'app avec cette
même adresse e-mail : l'invitation détermine automatiquement son rôle, elle
ne peut pas se l'attribuer elle-même.

## Mode démonstration (essai sans compte)

L'écran de connexion propose un bouton « Essayer sans compte » qui crée un
compte Firebase Auth anonyme (aucun e-mail requis) pour découvrir l'app
rapidement. Il suit le même amorçage que n'importe quel compte (devient
Promoteur si aucun ne l'est encore), mais consomme donc l'unique jeton
d'amorçage `meta/bootstrap` s'il est utilisé en premier.

Avant de passer à un usage réel avec la ferme :
- Activez **Authentication → Sign-in method → Anonymous** dans la console
  Firebase pour rendre ce bouton fonctionnel pendant la phase d'essai.
- Une fois prêt·e, **désactivez ce même fournisseur Anonymous** pour forcer
  une vraie adresse e-mail à chaque nouvelle inscription.
- Si un compte anonyme est devenu Promoteur pendant les essais, supprimez-le
  (Authentication → onglet Users) ainsi que son document `utilisateurs/{uid}`
  et repassez `meta/bootstrap.promoteur_defini` à `false` dans Firestore,
  pour permettre au vrai Promoteur de s'amorcer proprement.

## Connexion Google

En plus de l'e-mail/mot de passe, l'écran de connexion propose
« Continuer avec Google ». Pour l'activer :

1. **Authentication → Sign-in method → Google** → activer (un e-mail
   d'assistance du projet est demandé).
2. **Paramètres du projet (⚙️) → Général → vos applications** → l'app
   Android `bf.cci.suivi.ferme` → section **Certificats SHA** → **Ajouter
   une empreinte** → collez l'empreinte SHA-1 du certificat qui signe les
   APK produits par la CI (voir ci-dessous pour l'obtenir).
3. **Re-téléchargez `google-services.json`** (il doit maintenant contenir
   un `oauth_client` non vide) et mettez à jour le secret GitHub
   `FERME_GOOGLE_SERVICES_JSON` avec ce nouveau fichier encodé en base64.

Les APK sont actuellement signés avec le keystore de debug par défaut de
l'environnement CI (`signingConfig = signingConfigs.debug`, pratique pour
les essais mais **à remplacer par un vrai keystore de release avant toute
diffusion large** — voir la [documentation Flutter sur la signature
d'app](https://docs.flutter.dev/deployment/android#signing-the-app)).
Pour obtenir l'empreinte SHA-1 de ce certificat de debug à partir d'un APK
déjà construit :

```bash
unzip -p suivi-ferme.apk META-INF/*.RSA > cert.rsa
openssl pkcs7 -inform DER -in cert.rsa -print_certs -out cert.pem
openssl x509 -in cert.pem -noout -fingerprint -sha1
```

## Mise en route (développement local)

```bash
cd ferme
flutter create . --platforms=android   # génère android/, etc. (absent du dépôt)
# placez google-services.json téléchargé depuis Firebase dans android/app/
flutter pub get
flutter run
```

## Construire l'APK

Le workflow `.github/workflows/build-apk-ferme.yml` (déclenchement manuel,
`workflow_dispatch`) génère les dossiers Android, installe
`google-services.json` depuis le secret `FERME_GOOGLE_SERVICES_JSON`,
construit l'APK et le publie comme
[GitHub Release](../../../releases).

## Limite connue

Les « notifications optionnelles à chaque nouvelle saisie » du cahier des
charges nécessiteraient un déclencheur serveur (Cloud Functions + FCM), hors
du périmètre actuel (Firestore + Authentication uniquement, sans Cloud
Functions). En l'état, la mise à jour en temps réel de l'écran Suivi
(listeners Firestore) tient lieu de notification tant que l'app est
ouverte ; une notification push app fermée reste une extension possible.
