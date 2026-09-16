# Suivi Ferme — Architecture

Application Flutter + Firebase (Firestore + Authentication) implémentant le
[cahier des charges](CAHIER_DES_CHARGES.md) « Application de suivi de ferme
à distance ».

## 1. Structure de dossiers (`ferme/lib/`)

```
lib/
├── main.dart                          # Firebase.initializeApp() + Provider tree -> AppGate
├── theme/app_theme.dart
├── models/
│   ├── user_role.dart                 # enum UserRole (promoteur/superviseur/collaborateur)
│   ├── user_profile.dart              # utilisateurs/{uid}
│   ├── depense.dart                   # depenses/{id}
│   ├── recette.dart                   # recettes/{id}
│   └── flux_entree.dart               # fusion dépenses+recettes pour l'écran Suivi
├── services/
│   ├── auth_service.dart              # connexion / inscription / déconnexion (Firebase Auth)
│   └── firestore_service.dart         # CRUD Firestore + amorçage + invitations
├── providers/
│   └── session_provider.dart          # État de session : User Firebase Auth + UserProfile Firestore
├── screens/
│   ├── app_gate.dart                  # Routage selon SessionStatus
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── onboarding_screen.dart     # Amorçage Promoteur / acceptation d'invitation
│   ├── home/home_shell.dart           # Navigation par rôle (bottom nav ou écran unique)
│   ├── saisie/                        # Superviseur : formulaire + historique + lignes
│   ├── saisie_limitee/                # Collaborateur : formulaire minimal
│   ├── suivi/                         # Promoteur+Superviseur : flux chronologique, filtres
│   ├── bilan/                         # Promoteur+Superviseur : totaux, graphique, export PDF
│   └── acces/                         # Promoteur : inviter / (dés)activer un compte
└── widgets/
```

## 2. Modèle de données (Firestore)

### `utilisateurs/{uid}`
`nom`, `role` (`promoteur`/`superviseur`/`collaborateur`), `actif` (bool).

### `depenses/{id}`
`montant`, `date`, `ligne`, `note`, `saisi_par_uid`, `saisi_par_nom`, `saisi_par_role`.

### `recettes/{id}`
`montant`, `date`, `source` (`vente récolte`/`autre`), `note`, `saisi_par_uid`, `saisi_par_nom`.

### `config/lignes`
`lignes: string[]` — catégories de dépense, modifiables par le Superviseur
(par défaut : semences, engrais, main-d'œuvre, transport, technicien,
équipement, autre).

### `invitations/{email}`
`nom`, `role`, `utilise` (bool), `date_creation`. Créé par le Promoteur
(écran Gestion des accès), consommé une fois par la personne invitée lors
de son inscription.

### `meta/bootstrap`
`promoteur_defini` (bool) — verrou d'amorçage, voir §3.

## 3. Comptes et permissions — sans Cloud Functions

Le stack ne comprend que Firestore + Authentication (pas de Cloud
Functions/Admin SDK), donc aucun compte ne peut être créé « à distance » par
le Promoteur : chaque personne crée son propre compte Firebase Auth
(e-mail/mot de passe) dans l'app. Le rôle attribué à ce compte est en
revanche entièrement contrôlé côté serveur par `firestore.rules`, pas par le
client, via deux mécanismes :

- **Amorçage** : `meta/bootstrap.promoteur_defini` démarre à `false`. Le
  tout premier compte à écrire `utilisateurs/{son-uid}` avec
  `role: 'promoteur'` le fait dans un batch atomique qui bascule
  simultanément `promoteur_defini` à `true` ; la règle `update` de
  `meta/bootstrap` n'autorise que la transition `false -> true`, donc un
  seul compte peut jamais devenir Promoteur par ce chemin.
- **Invitation** : pour tout autre rôle, la règle de création de
  `utilisateurs/{uid}` exige l'existence d'un document
  `invitations/{email}` (`email` = revendication `email` du jeton
  d'authentification, donc non falsifiable côté client) non utilisé, dont
  les champs `role` et `nom` correspondent **exactement** à ceux que le
  client tente d'écrire. Un utilisateur ne peut donc jamais s'auto-attribuer
  un rôle : il ne peut que reprendre celui déjà fixé par le Promoteur dans
  l'invitation.

`OnboardingScreen` orchestre ce flux côté client : à la première connexion
sans profil Firestore, il cherche une invitation correspondant à l'e-mail
connecté, sinon propose l'amorçage Promoteur si `meta/bootstrap` ne l'a pas
encore consommé, sinon affiche un message de blocage.

Désactiver un compte (`utilisateurs/{uid}.actif = false`) est réservé au
Promoteur ; `estActif()` conditionne tout accès aux données dans
`firestore.rules`, donc un compte désactivé perd immédiatement tout accès en
lecture/écriture, pas seulement l'affichage côté app.

## 4. Étanchéité des données par rôle (`firestore.rules`)

- **Collaborateur** : ne peut lire/écrire que les documents `depenses` où
  `saisi_par_uid == uid` (requête cliente filtrée en conséquence — Firestore
  refuse toute requête `list` dont le résultat potentiel pourrait inclure un
  document hors de ce filtre). Aucun accès à `recettes`, à `utilisateurs`
  (hors son propre document), ni aux totaux/bilan.
- **Superviseur** : lecture/écriture complètes sur `depenses` et `recettes`,
  gestion de `config/lignes`.
- **Promoteur** : lecture complète (`depenses`, `recettes`, `utilisateurs`,
  `invitations`), aucune écriture sur `depenses`/`recettes`, seul rôle
  pouvant modifier `utilisateurs` (activer/désactiver) et `invitations`.

## 5. Écran Suivi et Bilan

`FluxEntree.combiner` fusionne côté client les flux `depensesStream` et
`recettesStream` (deux `StreamBuilder` imbriqués) en une liste triée par
date pour l'affichage chronologique — Firestore ne permet pas de requêter
deux collections en une seule requête ordonnée.

Le Bilan agrège les dépenses par `ligne` pour le graphique (`fl_chart`) et
génère un PDF (`pdf` + `printing`) ouvrant directement la feuille de partage
native (« export PDF ou partage simple » du cahier des charges en une seule
action).

## 6. CI / génération de l'APK

Comme pour `mobile/`, le SDK Flutter n'étant pas disponible dans
l'environnement qui a produit ce dépôt, `.github/workflows/build-apk-ferme.yml`
génère les dossiers de plateforme Android à la volée, y installe
`google-services.json` (depuis le secret `FERME_GOOGLE_SERVICES_JSON`) et le
plugin Gradle « Google services », construit l'APK et publie une GitHub
Release — voir [README.md](README.md) pour la configuration Firebase
préalable requise.
