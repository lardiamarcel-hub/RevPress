# Revue Éco BF — Architecture

Lecteur de flux RSS façon **Feedly**, entièrement local : aucun backend à
déployer, aucun compte à créer. L'application ajoute la possibilité
d'inclure n'importe quel journal ou magazine (burkinabè ou non) via son
adresse web ou son flux RSS/Atom direct.

> Ce projet a d'abord été construit autour de Firebase (Firestore, Cloud
> Functions, classification par IA). Cette architecture a été abandonnée :
> elle exigeait un projet Firebase déployé, une clé API Anthropic et une
> facturation pour fonctionner, ce qui rendait l'app inutilisable tant que
> ce backend n'était pas configuré. La version actuelle fonctionne dès
> l'installation.

## 1. Principe

- L'utilisateur ajoute des flux (journaux, magazines, institutions...),
  organisés en dossiers, comme dans Feedly.
- L'application va chercher les articles **directement depuis le
  téléphone** (aucun serveur intermédiaire) et les stocke dans une base
  SQLite locale.
- Aucun classement par IA : c'est l'utilisateur qui organise ses flux en
  dossiers. Aucun résumé généré : le texte affiché est celui que le flux
  RSS du site fournit lui-même à ses lecteurs (titre + extrait), jamais
  l'article complet.

## 2. Structure de dossiers (`mobile/lib/`)

```
lib/
├── main.dart                          # Provider tree + MaterialApp -> LibraryScreen
├── theme/app_theme.dart
├── utils/relative_time.dart           # "il y a 2 h", "hier"...
├── models/
│   ├── folder.dart
│   ├── feed.dart
│   ├── article.dart                   # Article + ArticleDraft (avant insertion en base)
│   └── article_query.dart             # Sélection affichée par ArticleListScreen
├── db/
│   ├── app_database.dart              # Ouverture/schéma SQLite (sqflite)
│   └── feed_repository.dart           # CRUD dossiers/flux/articles
├── services/
│   ├── feed_parser.dart               # Parsing RSS/Atom (dart_rss) + date RFC 822 + nettoyage HTML
│   ├── feed_discovery_service.dart    # Résout une adresse (site ou flux) en flux exploitable
│   └── feed_sync_service.dart         # Récupère + enregistre les nouveaux articles d'un ou tous les flux
├── config/
│   └── curated_sources.dart           # Sélection de départ (presse BF, institutions, régional, international)
├── providers/
│   └── library_provider.dart          # État de la bibliothèque (dossiers/flux, compteurs, actions)
├── widgets/
│   └── article_tile.dart
└── screens/
    ├── library/
    │   ├── library_screen.dart        # Accueil : Tous / Favoris / dossiers / flux
    │   └── feed_form_screen.dart      # Ajout (résolution d'URL) / modification d'un flux
    ├── articles/
    │   ├── article_list_screen.dart   # Liste pour une sélection (tout/dossier/flux/favoris)
    │   └── article_detail_screen.dart
    └── search/
        └── search_screen.dart         # Recherche locale (déjà téléchargé)
```

## 3. Schéma SQLite (`feed_repository.dart` / `app_database.dart`)

### `folders`
| Champ | Type | Description |
|---|---|---|
| id | TEXT PK | |
| nom | TEXT | |
| ordre | INTEGER | |

### `feeds`
| Champ | Type | Description |
|---|---|---|
| id | TEXT PK | |
| nom | TEXT | |
| site_url | TEXT | Adresse du site (pour référence) |
| flux_url | TEXT | URL du flux RSS/Atom réellement interrogé |
| folder_id | TEXT NULL | `NULL` = non classé ; `ON DELETE SET NULL` |
| acces_limite | INTEGER (bool) | Indicatif seulement (site payant) |
| ordre | INTEGER | |
| derniere_maj | INTEGER NULL | Timestamp de la dernière collecte réussie |
| derniere_erreur | TEXT NULL | Dernier message d'erreur, affiché dans la bibliothèque |

### `articles`
| Champ | Type | Description |
|---|---|---|
| id | TEXT PK | `feedId::hash(guid)` — dédoublonne automatiquement |
| feed_id | TEXT | `ON DELETE CASCADE` |
| titre, lien, contenu | TEXT | `contenu` = extrait nettoyé (HTML retiré, paragraphes conservés) |
| date_publication | INTEGER | Fournie par le flux (RFC 822 ou ISO 8601) |
| date_ajout | INTEGER | Date de récupération par l'app |
| lu, favori | INTEGER (bool) | |

Index sur `feed_id`, `date_publication`, `favori`, `folder_id`.

## 4. Récupération des flux (aucun serveur)

`FeedDiscoveryService.discover(url)` :
1. Essaie l'adresse telle quelle comme flux (`RssFeed.parse` puis `AtomFeed.parse` — l'un des deux lève une exception explicite si le contenu n'est pas le sien, ce qui permet une détection fiable).
2. Sinon, télécharge la page et cherche `<link rel="alternate" type=".../rss+xml|atom+xml">`.
3. Sinon, essaie des chemins usuels : `/feed`, `/rss`, `/rss.xml`, `/atom.xml`, `/feeds/posts/default` (Blogger), `/spip.php?page=backend` (SPIP, utilisé par plusieurs sites ouest-africains).

`FeedSyncService.syncFeed(feed)` télécharge le flux connu, parse, et insère
les nouveaux articles (les doublons sont ignorés via l'id stable
`feedId::guid`). Utilisé par le glisser-actualiser et par le bouton
« Actualiser » de chaque écran.

Le parsing de dates RSS (`parseRfc822Date`) est un parseur maison : ni
`DateTime.tryParse` (ISO 8601 seulement) ni `HttpDate.parse` de `dart:io`
(rejette les offsets numériques comme `+0000`) ne couvrent le format RFC 822
réel des flux RSS — validé empiriquement avant intégration.

## 5. Navigation

- **Accueil (`LibraryScreen`)** : « Tous les articles », « Favoris », puis
  chaque dossier (dépliable) avec ses flux, compteurs nombre non lus, menu
  « Importer une sélection de sources ». Bouton **+** pour ajouter un
  journal/magazine par son adresse.
- **Liste d'articles** : glisser pour actualiser, filtre non-lus, tout
  marquer comme lu.
- **Détail d'un article** : extrait fourni par le flux, favori, partage,
  marquer non lu, lien vers l'article complet sur le site d'origine, et un
  bouton optionnel « Résumer avec l'IA ».
- **Recherche** : filtre local sur les articles déjà téléchargés (titre,
  extrait, nom du flux).
- **Réglages** : clé API Anthropic (optionnelle), pour le résumé IA.

## 5bis. Résumé par IA (optionnel, à la demande)

Fonctionnalité annexe qui ne remet pas en cause l'architecture 100% locale :
l'utilisateur fournit sa **propre** clé API Anthropic (Réglages), stockée
dans la table `settings` (clé/valeur) de la base locale — jamais envoyée
ailleurs qu'à `api.anthropic.com`. `services/ai_summary_service.dart` appelle
`POST https://api.anthropic.com/v1/messages` en HTTP brut (Dart n'a pas de
SDK officiel Anthropic) avec `claude-opus-5` et `output_config.effort: "low"`
(tâche de résumé simple, pas besoin de raisonnement poussé). Le résumé
généré est stocké dans `articles.resume_ia` pour ne pas être régénéré (et
refacturé) à chaque ouverture. Sans clé configurée, le bouton affiche
simplement une invite vers Réglages — le reste de l'app est inchangé.

## 6. CI / génération de l'APK

Le SDK Flutter n'est pas disponible dans l'environnement qui a produit ce
dépôt (accès réseau restreint à certains domaines). `.github/workflows/build-apk.yml`
génère les dossiers de plateforme Android à la volée (`flutter create`),
applique l'icône et le nom de l'app, construit l'APK et publie une
GitHub Release — le tout sur les runners GitHub, qui n'ont pas cette
restriction.
