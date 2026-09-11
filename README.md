# Revue Éco BF

Application Flutter + Firebase qui automatise une revue de presse économique
quotidienne/hebdomadaire pour le Burkina Faso, la sous-région (UEMOA/AES) et
l'international — voir [ARCHITECTURE.md](ARCHITECTURE.md) pour le plan complet
(schéma Firestore, Cloud Functions, structure de dossiers).

## Structure du dépôt

- `mobile/` — application Flutter (5 onglets thématiques, digest, historique, recherche, réglages)
- `functions/` — Cloud Functions Firebase (TypeScript) : collecte RSS, classification IA, digest, notifications
- `firebase.json`, `firestore.rules`, `firestore.indexes.json` — configuration du projet Firebase

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥ 3.24) — non installé dans cet environnement de génération de code ; à installer localement.
- [Node.js 20](https://nodejs.org/) pour les Cloud Functions.
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`).
- Un projet Firebase (Firestore, Cloud Messaging, Cloud Functions, Cloud Scheduler activés).
- Une clé API Anthropic pour la classification/résumé des articles.

## Mise en route

### 1. Projet Firebase

```bash
firebase login
firebase use --add   # associer ce dossier à votre projet Firebase
```

### 2. Mobile (Flutter)

Le SDK Flutter n'étant pas disponible dans l'environnement qui a généré ce
scaffold, deux étapes sont nécessaires avant le premier lancement :

```bash
cd mobile
flutter create . --platforms=android,ios   # génère android/, ios/, etc.
flutterfire configure                       # génère lib/firebase_options.dart avec vos vraies clés
flutter pub get
flutter run
```

Le fichier `lib/firebase_options.dart` fourni est un **placeholder** — il doit
être régénéré par `flutterfire configure` avant toute exécution réelle.

### 3. Cloud Functions

```bash
cd functions
npm install
firebase functions:secrets:set ANTHROPIC_API_KEY
npm run build
firebase deploy --only functions,firestore:rules,firestore:indexes
```

Au premier déclenchement (planifié ou via le bouton « Actualiser maintenant »
dans Réglages), la fonction `seedSources` amorce automatiquement la
collection `sources` avec la liste de départ si elle est vide.

### 4. Vérifications effectuées dans cet environnement

- `functions/` : `npm install` + `npm run build` (compilation TypeScript stricte) — ✅ sans erreur.
- `mobile/` : code Dart écrit à la main (pas de Flutter SDK disponible ici pour `flutter analyze`/`pub get`) — à valider localement après `flutter pub get`.

## Décisions par défaut (modifiables dans Réglages)

- Fréquence de collecte : **quotidienne**, 06h00 (heure d'Ouagadougou).
- Langue des résumés générés : **français**.

## Sources de départ

La liste complète des sources (presse burkinabè, presse économique
spécialisée, institutions, presse régionale/panafricaine, sources
internationales) est documentée dans le prompt d'origine et amorcée dans
`functions/src/config/defaultSources.ts` (miroir : `mobile/lib/config/default_sources.dart`).
Les sources payantes (Jeune Afrique, The Africa Report, etc.) ne sont jamais
stockées au-delà du titre et du lien.
