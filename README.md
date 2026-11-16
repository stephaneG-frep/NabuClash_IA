# NabuClash AI

Application Flutter Android de répartie contextuelle. Interface française « Cyber Comedy / Neon Glass », six fournisseurs IA, aucune génération locale prédéfinie et aucun backend propriétaire.

## Installation

Installer `delivery/NabuClash_AI_arm64_release.apk` sur un téléphone **Android ARM64, Android 7/API 24 minimum**. Autoriser ponctuellement l’installation depuis l’application qui ouvre l’APK. Le package est `fr.nabuclash.nabuclash_ai`.

Avec USB :

```bash
adb install -r delivery/NabuClash_AI_arm64_release.apk
```

L’application est signée avec une clé Release propre à ce projet. Conserver en lieu sûr `.private/` sur la machine de développement pour signer les mises à jour. Ce dossier est ignoré par Git et exclu du ZIP source ; il contient la clé de signature, pas des clés de fournisseurs IA.

## Premier lancement

1. Ouvrir **Réglages → Fournisseurs IA → Configurer**.
2. Saisir sa clé API personnelle, masquée par défaut.
3. Appuyer sur **Récupérer les modèles**, sélectionner un modèle de conversation texte, ou saisir un identifiant officiel.
4. **Tester la connexion**, puis **Enregistrer** et **Définir par défaut**. Le test fait un appel de génération et peut être facturé.
5. À l’accueil, écrire « Mon collègue vient de me dire que ma voiture date de la préhistoire. ».
6. Choisir Sarcastique, piquant 3, interlocuteur Collègue et contexte Travail, puis générer.

Les abonnements ChatGPT/Claude/Grok grand public ne constituent pas des crédits API. Les clés ne sont jamais fournies avec le projet. Leur disponibilité, les modèles autorisés, les quotas et la facturation dépendent du compte du fournisseur.

## Fonctions

- Accueil : texte, collage, dictée, contexte libre, 17 styles, piquant 1–5 et contexte social ; demande de cinq réponses distinctes.
- Chaque réponse : copie, partage Android, lecture vocale, favori et régénération individuelle.
- Neuf modificateurs relancent réellement l’IA avec la situation originale et les réponses précédentes.
- Sauve-moi : accès direct à trois réponses tranquille, piquante et audacieuse.
- Clash Chat : messages contextuels, plusieurs conversations persistantes, sélection, suppression, copie et lecture. Les messages nécessaires de la conversation active sont envoyés au fournisseur choisi.
- Dojo : six personnages fictifs, remarque générée, réponse libre de l’utilisateur et analyse descriptive en sept dimensions avec conseils et alternatives.
- Favoris et historique : recherche, suppression, copie, partage et réutilisation des situations.
- Préférences : sept personnalités et réponses en français, anglais ou espagnol.
- Guide intégré, erreurs lisibles, nouvelle tentative et annulation réseau.

La quantité exacte des réponses dépend de la sortie du modèle. Une sortie partielle exploitable est conservée ; aucun complément n’est fabriqué localement.

## Fournisseurs et formats

Les endpoints et formats sont centralisés dans `lib/ai/ai_provider.dart`, derrière `AIProvider` et `ProviderRegistry`. Aucun widget ne construit d’appel fournisseur.

| Fournisseur | Génération | Catalogue de modèles |
| --- | --- | --- |
| OpenAI | `https://api.openai.com/v1/chat/completions` | `/v1/models` |
| Anthropic | `https://api.anthropic.com/v1/messages` | `/v1/models`, pagination |
| Gemini | `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent` | `/v1beta/models`, pagination, filtre generateContent |
| Mistral | `https://api.mistral.ai/v1/chat/completions` | `/v1/models`, capacités chat |
| xAI | `https://api.x.ai/v1/chat/completions` | `/v1/models` |
| Perplexity | `https://api.perplexity.ai/v1/sonar` | Catalogue Sonar documenté + saisie manuelle |

OpenAI, Mistral et Grok utilisent le mode JSON objet ; Gemini le MIME JSON ; Anthropic et Perplexity un schéma JSON. L’option « Format JSON natif » permet de désactiver cette contrainte pour un modèle incompatible, en conservant les instructions de format dans le prompt. Chat et Dojo demandent du texte simple. La recherche Web Sonar est désactivée : elle n’est pas nécessaire à la répartie.

Aucun modèle n’est choisi arbitrairement pour le compte de l’utilisateur. La liste OpenAI/xAI peut comprendre des modèles incompatibles avec le chat texte ; sélectionner un modèle de conversation. Une erreur 404 invite à en changer. Le catalogue Sonar est explicite, sans faux endpoint de découverte. Sources officielles : [docs/API_SOURCES.md](docs/API_SOURCES.md).

## Confidentialité et permissions

- `INTERNET` : appels HTTPS au seul fournisseur sélectionné pour chaque requête.
- `RECORD_AUDIO` : demandé par la reconnaissance vocale lors de la première dictée.
- Refus du micro : explication et accès aux paramètres Android. Une reconnaissance vocale Android doit être installée ; elle peut dépendre d’Internet et des politiques du service vocal.
- Synthèse vocale : utilise les voix Android installées. Installer une voix de la langue voulue si nécessaire.
- Clés : `flutter_secure_storage`, jamais SharedPreferences, logs applicatifs ou ZIP source.
- Historique, favoris, conversations et préférences : espace privé local via SharedPreferences, sans sauvegarde Android automatique (`allowBackup=false`). Ces textes ne sont pas chiffrés par l’application ; la protection repose sur l’espace privé Android et le verrouillage de l’appareil.
- Aucun SDK analytique ni télémétrie applicative. Les règles de conservation du fournisseur sélectionné restent applicables.
- L’annulation ferme la requête côté client ; elle ne garantit pas l’arrêt du calcul ni de la facturation côté fournisseur.

## Architecture

```text
lib/
  main.dart                  démarrage et navigation
  models/domain.dart         situations, réponses, conversations, fournisseurs
  ai/                        interface, adaptateur réseau, erreurs, schéma JSON
  services/app_state.dart    état Provider/ChangeNotifier et orchestration
  services/prompt_builder.dart  instructions hors UI
  services/reply_parser.dart    parsing JSON tolérant, fallback texte
  storage/local_store.dart   persistance locale et abstraction des secrets
  screens/                   accueil, chat, dojo, bibliothèque et réglages
  widgets/common.dart        composants, voix et actions partagées
  theme/nabu_theme.dart       identité visuelle Material 3
```

Pour ajouter un fournisseur, étendre l’énumération et le registre, puis implémenter `AIProvider` ou ajouter le protocole au transport officiel commun. L’interface utilise l’abstraction. Les secrets sont injectables afin de tester sans coffre réel.

## Compilation reproductible

Environnement utilisé : Flutter 3.47.2 / Dart 3.13.2, JDK 17 ou JBR Android Studio, Android SDK compile 37, minimum 24 ; Gradle et versions des dépendances sont verrouillés dans les fichiers du projet. Les versions exactes de l’environnement et résultats figurent dans le rapport de validation.

Pour une copie source nouvelle, créer une clé de signature personnelle :

```bash
python3 tool/create_signing.py
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
python3 tool/verify_apk.py build/app/outputs/flutter-apk/app-release.apk
python3 tool/package_delivery.py
```

`create_signing.py` conserve le secret de signature uniquement dans `.private/` (droits restreints), ne l’imprime pas, et ne remplace pas de clé existante. Une clé différente ne permet pas de mettre à jour une installation signée avec l’ancienne : conserver la clé originale. Le ZIP exclut toutes les clés, caches, sorties de build et fichiers propres à la machine.

Les fichiers `.so` sont vérifiés directement dans l’APK : en-tête ELF 64 bits et champ `e_machine = 183` (AArch64), uniquement dans `lib/arm64-v8a/`. Aucun binaire natif n’est copié d’une autre architecture ou d’un autre projet.

## Tests et limites de validation

Voir [docs/VALIDATION.md](docs/VALIDATION.md) pour les commandes réellement exécutées et le statut de la validation sur appareil. Les tests du transport utilisent des réponses HTTP contrôlées **uniquement dans les tests**, jamais dans l’application. Ils ne prouvent pas l’accès à un compte API réel.

La validation finale de génération avec un fournisseur nécessite une clé personnelle et un quota disponible. Les tests micro/TTS nécessitent également les services vocaux du téléphone.

## Dépannage

| Problème | Action |
| --- | --- |
| Aucune clé / aucun modèle | Configurer le fournisseur puis le définir par défaut |
| 401 | Remplacer la clé invalide ou expirée |
| 403 | Vérifier les droits, restrictions du compte et accès au modèle |
| 404 | Actualiser les modèles et sélectionner un modèle texte disponible |
| 429 / quota | Vérifier les crédits API et attendre avant de réessayer |
| 400 / 422 | Vérifier le modèle et désactiver le format JSON natif si incompatible |
| Timeout / réseau | Vérifier Internet, puis Réessayer |
| 5xx | Attendre le rétablissement du fournisseur |
| JSON incorrect / sortie vide | Réessayer, reformuler ou choisir un autre modèle |
| Dictée absente | Activer le micro et installer/activer un moteur vocal Android |
| Lecture muette | Vérifier le volume multimédia et les voix de synthèse installées |
| Signature introuvable au build | Exécuter `python3 tool/create_signing.py` |
