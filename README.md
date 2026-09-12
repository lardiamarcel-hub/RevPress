# Revue Éco BF

Lecteur de flux RSS façon **Feedly**, pour suivre la presse économique du
Burkina Faso, les journaux et magazines locaux, et les sources régionales et
internationales de son choix — voir [ARCHITECTURE.md](ARCHITECTURE.md) pour
le détail technique.

**Aucun serveur à déployer, aucun compte à créer.** Tout fonctionne sur le
téléphone dès l'installation : ajoutez un journal ou un flux RSS, l'app va
chercher les articles directement, sans intermédiaire.

## Fonctionnalités

- Organisez vos flux en dossiers (comme dans Feedly) : Presse Burkina,
  International, ou tout autre classement de votre choix.
- Ajoutez n'importe quel journal ou magazine par son adresse web — le flux
  RSS est retrouvé automatiquement — ou collez directement l'URL d'un flux.
- Une sélection de départ (presse burkinabè, institutions BCEAO/UEMOA/BOAD,
  presse régionale et internationale) s'importe en un tap.
- Glisser pour actualiser, marquer lu/non lu, favoris, partage, recherche
  locale dans les articles déjà téléchargés.

## Structure du dépôt

- `mobile/` — application Flutter (Android)
- `.github/workflows/build-apk.yml` — construit l'APK et publie une release GitHub

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥ 3.24) —
  non installé dans l'environnement qui a généré ce scaffold ; à installer
  localement pour développer.

## Mise en route

```bash
cd mobile
flutter create . --platforms=android   # génère android/, etc. (absent du dépôt)
flutter pub get
flutter run
```

Aucune configuration supplémentaire (pas de clé API, pas de projet cloud) :
l'app est utilisable immédiatement.

## Construire l'APK

Un workflow GitHub Actions (`.github/workflows/build-apk.yml`) construit
l'APK de release et le publie comme
[GitHub Release](../../releases) à chaque déclenchement manuel
(`workflow_dispatch`).
