# Revue Éco BF — Plan d'architecture

Application Flutter + Firebase qui automatise une revue de presse économique
(Burkina Faso, UEMOA/AES, international) pour un usage individuel
(Conseiller Technique CCI-BF / enseignant-chercheur).

Décisions par défaut retenues (modifiables depuis l'écran Réglages) :
- **Fréquence de collecte** : quotidienne (06h00, heure d'Ouagadougou), avec bascule hebdomadaire possible.
- **Langue des résumés** : français.

## 1. Structure de dossiers

```
RevPress/
├── ARCHITECTURE.md
├── README.md
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── mobile/                        # App Flutter
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── firebase_options.dart          # généré par `flutterfire configure`
│       ├── config/
│       │   ├── theme_angles.dart          # les 5 angles thématiques (enum + libellés)
│       │   └── default_sources.dart       # liste de sources par défaut (seed local/UI)
│       ├── models/
│       │   ├── article.dart
│       │   ├── digest.dart
│       │   └── source_config.dart
│       ├── services/
│       │   ├── firestore_service.dart     # lecture/écriture Firestore
│       │   └── notification_service.dart  # FCM + notifications locales
│       ├── providers/
│       │   ├── articles_provider.dart
│       │   ├── digest_provider.dart
│       │   └── settings_provider.dart
│       ├── theme/
│       │   └── app_theme.dart
│       ├── widgets/
│       │   ├── article_card.dart
│       │   └── angle_articles_list.dart
│       └── screens/
│           ├── home_screen.dart           # shell : BottomNavigationBar à 5 onglets
│           ├── tabs/
│           │   └── angle_tab_screen.dart  # vue générique réutilisée par les 5 onglets
│           ├── digest/
│           │   ├── digest_screen.dart         # "Digest du jour"
│           │   └── digest_history_screen.dart # historique des digests
│           ├── search/
│           │   └── search_screen.dart
│           └── settings/
│               └── settings_screen.dart
└── functions/                      # Firebase Cloud Functions (TypeScript, gen 2)
    ├── package.json
    ├── tsconfig.json
    └── src/
        ├── index.ts                        # exports des Cloud Functions
        ├── types.ts
        ├── config/
        │   └── defaultSources.ts           # miroir de default_sources.dart, seedé en base
        ├── collectors/
        │   ├── rssCollector.ts              # flux RSS officiels (/feed, /rss)
        │   └── googleNewsFallback.ts        # Google News RSS filtré par domaine (sources sans flux)
        ├── classification/
        │   └── claudeClassifier.ts          # appel API Claude : angle + résumé + fiabilité
        ├── dedup/
        │   └── deduplicate.ts               # regroupement des articles d'un même évènement
        ├── digest/
        │   └── buildDigest.ts               # construction du digest quotidien/hebdo
        ├── notifications/
        │   └── sendDigestNotification.ts    # FCM à la création d'un digest
        ├── scripts/
        │   └── seedSources.ts               # callable d'amorçage de la collection `sources`
        └── utils/
            ├── robots.ts                    # vérification robots.txt avant tout fetch direct
            └── textSimilarity.ts            # similarité de titres pour le dédoublonnage
```

## 2. Schéma Firestore

### `sources/{sourceId}`
Config modifiable depuis l'écran Réglages ; source de vérité pour la collecte.
| Champ | Type | Description |
|---|---|---|
| nom | string | Nom affiché (ex. « L'Économiste du Faso ») |
| domaine | string | Domaine racine (ex. `leconomistedufaso.bf`) |
| fluxRss | string \| null | URL du flux RSS officiel si trouvé |
| methodeCollecte | `rss` \| `google_news_rss` | Stratégie de repli si pas de flux RSS |
| categorie | `presse_bf` \| `presse_eco_bf` \| `institution` \| `presse_regionale` \| `presse_aes` \| `international` | Catégorie de la table de sources |
| accesPayant | bool | Si vrai, on ne stocke jamais que titre + lien |
| actif | bool | Source incluse ou non dans la prochaine collecte |

### `articles/{articleId}`
| Champ | Type | Description |
|---|---|---|
| titre | string | |
| source | string | Nom de la source |
| sourceId | string | Référence `sources/{sourceId}` |
| url | string | Lien vers l'article original |
| datePublication | Timestamp | |
| dateCollecte | Timestamp | |
| angleThematique | `investissement` \| `exportations` \| `monnaie_aes` \| `finances_publiques` \| `secteur_prive` \| `hors_sujet` | Déterminé par Claude |
| resume | string \| null | 2-3 phrases générées par IA ; `null` si source payante |
| langueOriginale | `fr` \| `en` | |
| fiabilite | `haute` \| `moyenne` \| `faible` | Priorité d'affichage |
| accesPayant | bool | |
| eventGroupId | string \| null | Regroupe les articles couvrant le même évènement |

Index composites : (`angleThematique` asc, `datePublication` desc), (`eventGroupId` asc, `datePublication` desc).

### `digests/{digestId}` (id = `YYYY-MM-DD`)
| Champ | Type | Description |
|---|---|---|
| date | Timestamp | |
| frequence | `quotidien` \| `hebdomadaire` | |
| articlesParAngle | Map<angle, string[]> | IDs d'articles, triés par importance |
| syntheseGlobale | string[] | IDs des articles les plus importants tous angles confondus |
| genereA | Timestamp | |

### `config/collecte` (document singleton)
| Champ | Type | Description |
|---|---|---|
| frequence | `quotidien` \| `hebdomadaire` | Défaut : `quotidien` |
| heureCollecte | string | Défaut : `"06:00"` (Africa/Ouagadougou) |
| notificationsActives | bool | Défaut : `true` |
| langueResumes | `fr` \| `en` | Défaut : `fr` |

## 3. Cloud Functions

| Fonction | Déclencheur | Rôle |
|---|---|---|
| `dailyPressReview` | Cloud Scheduler (`onSchedule`, 06:00 Africa/Ouagadougou, tous les jours — vérifie en interne si la fréquence configurée est hebdomadaire et si le jour correspond) | Orchestre : collecte RSS/Google News → classification+résumé Claude → dédoublonnage → écriture `articles` → construction du digest du jour → écriture `digests/{date}` |
| `onDigestCreated` | Firestore trigger `onDocumentCreated('digests/{id}')` | Envoie la notification FCM « Votre revue de presse économique est prête » |
| `manualRefresh` | HTTPS Callable | Relance `dailyPressReview` à la demande (bouton « Actualiser maintenant » dans Réglages) |
| `seedSources` | HTTPS Callable (admin, à usage unique) | Amorce la collection `sources` avec la liste de départ |

Contraintes respectées : flux RSS officiels en priorité, repli Google News RSS filtré par domaine (jamais de parsing HTML direct de sites tiers), vérification de `robots.txt` avant tout fetch, aucun stockage de contenu intégral (titre + source + date + lien + résumé 2-3 phrases IA uniquement), sources payantes limitées à titre + lien.

## 4. Navigation Flutter

- `BottomNavigationBar` à **5 onglets fixes** (Investissement, Exportations, Monnaie & AES, Finances publiques, Secteur privé) — non négociables.
- `AppBar` commune avec actions : icône recherche (plein texte, contextualisée à l'onglet actif), icône « Digest du jour », menu (Historique des digests, Réglages).
- Écran Réglages : fréquence de collecte, gestion des sources (activer/désactiver, ajouter), notifications on/off, bouton actualisation manuelle.

---

Ce plan sert de base validée pour l'implémentation qui suit dans ce même commit (scaffold complet Flutter + Cloud Functions).
