# Cahier des charges — Application de suivi de ferme à distance

## 1. Contexte

Application mobile Android permettant de gérer à distance les finances d'une
exploitation agricole (ferme), avec deux profils principaux qui ne sont pas
sur place, et un suivi terrain assuré par un fermier et un technicien.

## 2. Stack technique

- **Frontend** : Flutter
- **Backend** : Firebase (Firestore + Firebase Authentication)
- **Build** : APK généré automatiquement via GitHub Actions

## 3. Rôles et permissions

| Rôle | Qui | Permissions |
|---|---|---|
| **Promoteur** | Le propriétaire de la ferme (compte principal) | Lecture complète de toutes les saisies (dépenses, recettes) ; accès complet au bilan et aux statistiques ; gestion des accès (invite/retire des collaborateurs) ; ne saisit pas lui-même |
| **Superviseur** | Épouse, en charge de la supervision financière | Lecture + écriture complètes : ajoute, modifie, supprime dépenses et recettes ; gère les lignes/catégories |
| **Collaborateur (accès limité)** | Fermier et/ou technicien (optionnel, invités par le Promoteur) | Accès restreint : peut uniquement **imputer une dépense** (ajouter une dépense liée à ses propres tâches, avec montant, ligne, note) ; ne peut ni modifier/supprimer les entrées des autres, ni consulter le bilan global, ni voir les recettes |

> Le compte Collaborateur est optionnel et activable au cas par cas par le
> Promoteur (ex. donner un accès limité au fermier pour qu'il déclare
> lui-même ses achats d'intrants, sans voir le reste des finances).

## 4. Modèle de données (Firestore)

### Collection `depenses`
- `montant` (nombre)
- `date` (timestamp)
- `ligne` (catégorie : semences, engrais, main-d'œuvre, transport,
  technicien, équipement, autre — liste modifiable par le Superviseur)
- `note` (texte libre)
- `saisi_par` (référence utilisateur + rôle)

### Collection `recettes`
- `montant` (nombre)
- `date` (timestamp)
- `source` (vente récolte, autre)
- `note` (texte libre)
- `saisi_par` (référence utilisateur, Superviseur uniquement)

### Collection `utilisateurs`
- `nom`, `role` (promoteur / superviseur / collaborateur)
- `actif` (booléen, pour activer/désactiver un accès collaborateur)

## 5. Écrans

1. **Saisie (Superviseur)**
   - Formulaire rapide dépense / recette
   - Historique de ses propres saisies (modifiable/supprimable)
   - Gestion des lignes de dépense

2. **Saisie limitée (Collaborateur)**
   - Formulaire minimal : imputer une dépense (montant, ligne, note)
   - Voit uniquement ses propres imputations passées

3. **Suivi (Promoteur)**
   - Flux chronologique de toutes les entrées (dépenses + recettes), mise
     à jour en temps réel
   - Filtres par période et par ligne
   - Notifications optionnelles à chaque nouvelle saisie

4. **Bilan sommaire (Promoteur)**
   - Total dépenses / total recettes / bénéfice net sur période choisie
     (mois, campagne agricole)
   - Répartition des dépenses par ligne (graphique)
   - Export PDF ou partage simple

5. **Gestion des accès (Promoteur)**
   - Inviter / désactiver un compte Collaborateur (fermier, technicien)

## 6. Points d'attention pour le développement

- Synchronisation temps réel obligatoire (Firestore listeners) : le
  Promoteur doit voir les mises à jour sans rafraîchir manuellement
- Sécurité : règles Firestore strictes par rôle (un Collaborateur ne doit
  jamais pouvoir lire les recettes ni les dépenses des autres)
- Interface simple, faible consommation de données (contexte rural,
  connexion parfois limitée)
