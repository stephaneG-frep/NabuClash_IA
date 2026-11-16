# MISSION — CRÉER NABUCLASH AI

Tu es chargé de développer intégralement une application Flutter Android appelée :

**NabuClash AI**

Je veux un projet Flutter COMPLET, fonctionnel, compilable et réellement livrable.

Ne crée pas une simple maquette UI.

Tous les boutons, écrans et fonctions présentés à l'utilisateur doivent fonctionner.

À la fin du développement, je veux pouvoir installer l'APK sur un smartphone Android ARM64 et utiliser réellement l'application.

---

# 1 — CONCEPT

NabuClash AI est un agent IA spécialisé dans :

* la répartie
* le sarcasme
* l'humour
* l'ironie
* les réponses effrontées
* les réponses intelligentes
* les réponses élégantes
* l'autodérision
* les réponses absurdes
* les réponses courtes qui claquent
* les réponses diplomatiques

L'utilisateur indique ce qu'une personne vient de lui dire et éventuellement le contexte.

Exemple :

« Mon collègue vient de me dire que je ne suis vraiment pas rapide aujourd'hui. »

NabuClash analyse la situation et génère plusieurs réponses.

L'objectif est de produire de la vraie génération IA contextuelle.

INTERDICTION de simuler l'IA avec une liste locale de phrases prédéfinies.

---

# 2 — MULTI-FOURNISSEURS IA

L'application doit pouvoir utiliser plusieurs fournisseurs.

Supporter :

* OpenAI / ChatGPT
* Anthropic / Claude
* Google Gemini
* Mistral AI
* xAI / Grok
* Perplexity

Créer une architecture extensible.

Par exemple :

lib/
ai/
ai_provider.dart
ai_model.dart
ai_response.dart
providers/
openai_provider.dart
anthropic_provider.dart
gemini_provider.dart
mistral_provider.dart
grok_provider.dart
perplexity_provider.dart

Créer une abstraction commune du type :

AIProvider

avec notamment des méthodes pour :

* tester la connexion
* envoyer une requête
* envoyer une conversation
* récupérer/gérer les modèles disponibles
* traiter les erreurs
* annuler proprement une requête si possible

L'interface Flutter ne doit jamais dépendre directement d'un fournisseur particulier.

Je dois pouvoir changer de fournisseur sans modifier le reste de l'application.

---

# 3 — API OFFICIELLES

Utiliser uniquement les API officielles/documentées des fournisseurs.

Ne pas inventer :

* endpoint
* modèle
* paramètre API
* format de réponse

Centraliser les informations dépendantes du fournisseur.

Prévoir une gestion des changements de modèles sans devoir réécrire toute l'application.

Si un modèle précis n'est plus disponible, l'application doit permettre à l'utilisateur d'en sélectionner un autre.

---

# 4 — CLÉS API

Créer :

Paramètres
→ Fournisseurs IA

Afficher les fournisseurs sous forme de belles cartes.

Pour chaque fournisseur :

* nom
* icône
* état Configuré / Non configuré
* clé API
* modèle
* Tester la connexion
* Définir par défaut
* Modifier
* Supprimer

Ne mettre AUCUNE clé API dans le repository.

Ne mettre AUCUNE clé dans Git.

Stocker les clés de manière sécurisée sur Android avec une solution Flutter adaptée telle que flutter_secure_storage.

Masquer visuellement les clés.

---

# 5 — ACCUEIL

Créer un écran principal spectaculaire mais simple à utiliser.

Titre :

**Qu'est-ce qu'on t'a dit ?**

Grande zone :

« Écris, colle ou dicte ce qu'on vient de te dire… »

Actions :

🎤 Dicter

📋 Coller

🗑 Effacer

Ajouter éventuellement :

**Contexte**

Exemple :

« Mon collègue se moque de ma vieille voiture devant les autres. Je veux répondre avec humour sans être méchant. »

Bouton principal :

**⚡ Trouve-moi une répartie**

---

# 6 — STYLES

Permettre de choisir :

😏 Sarcastique

😈 Effronté

😂 Comique

🙃 Ironique

🎩 Élégant

🧠 Intelligent

🧊 Glacial

🎭 Théâtral

🤪 Absurde

😐 Pince-sans-rire

🥂 Gentleman assassin

⚡ Courte et efficace

🪶 Subtile

🤣 Autodérision

🤝 Diplomatique

😜 Taquine

🎲 Surprends-moi

Ces styles ne doivent PAS être purement décoratifs.

Ils doivent modifier réellement les instructions envoyées au modèle IA.

---

# 7 — JAUGE DE PIQUANT

Ajouter une jauge :

🌶️ **Niveau de piquant**

1 — Gentil

2 — Taquin

3 — Piquant

4 — Corsé

5 — Sans détour

Cette valeur doit être envoyée au moteur de génération.

Même au niveau 5, privilégier la créativité et l'esprit plutôt que les menaces, le harcèlement ou les attaques discriminatoires.

---

# 8 — CONTEXTE SOCIAL

L'utilisateur peut préciser avec qui il parle :

* Ami
* Collègue
* Patron
* Famille
* Partenaire
* Inconnu
* Réseaux sociaux
* Autre

Et le contexte :

* Travail
* Amis
* Famille
* Couple
* Internet
* Conversation publique
* Conversation privée

La génération doit réellement tenir compte de ces informations.

Une réponse à un patron ne doit pas être générée exactement comme une réponse à un ami.

---

# 9 — GÉNÉRATION

Après génération, proposer idéalement 5 réparties différentes.

Exemple de présentation :

### 😏 Subtile

« Je prends mon temps, ça laisse une chance aux autres de suivre. »

### 😂 Comique

« J'étais en mode économie d'énergie. »

etc.

Chaque carte doit proposer :

* Copier
* Favori
* Partager
* Lire à voix haute
* Régénérer

---

# 10 — MODIFICATEURS

Sous les résultats ajouter :

😂 Plus drôle

😏 Plus sarcastique

🧠 Plus intelligent

🪶 Plus subtil

⚡ Plus court

🔥 Plus culotté

😇 Moins méchant

🎲 Surprends-moi

🔄 Complètement différent

Ces boutons doivent conserver la situation originale et demander une nouvelle génération à l'IA.

Ne pas remplacer simplement quelques mots localement.

---

# 11 — MODE SAUVE-MOI

Créer un mode rapide :

**🆘 SAUVE-MOI !**

L'utilisateur appuie.

Une interface minimale apparaît :

« Il/elle vient de dire quoi ? »

Texte ou dictée.

Puis générer immédiatement :

😇 Réponse tranquille

😏 Réponse piquante

🔥 Réponse audacieuse

Ce mode doit nécessiter le minimum d'interactions possible.

---

# 12 — CLASH CHAT

Créer un véritable chat IA.

Nom :

**Clash Chat**

Exemple :

Utilisateur :

« Mon voisin critique toujours ma voiture. »

NabuClash :

« Tu veux lui répondre plutôt avec humour, élégance ou sarcasme ? »

Utilisateur :

« Humour, mais sans être méchant. »

NabuClash conserve le contexte et continue la conversation.

Prévoir :

* historique de conversation
* bulles utilisateur/IA
* indicateur de génération
* nouvelle conversation
* suppression
* copie
* TTS

---

# 13 — DOJO DE LA RÉPARTIE

Créer :

🥋 **Dojo**

Ce mode sert à entraîner l'utilisateur.

L'IA joue différents personnages fictifs :

* ami moqueur
* collègue sarcastique
* personne arrogante
* troll Internet
* personnage ironique
* adversaire verbal fictif

L'IA lance une remarque.

L'utilisateur invente sa propre répartie.

NabuClash analyse ensuite descriptivement :

* humour
* originalité
* clarté
* agressivité
* subtilité
* efficacité
* élégance

Expliquer :

* ce qui fonctionne
* ce qui peut être amélioré
* comment raccourcir
* comment rendre plus drôle
* comment rendre plus subtil

Puis proposer des alternatives.

---

# 14 — VOIX

Implémenter :

Speech-To-Text

et

Text-To-Speech.

L'utilisateur doit pouvoir dicter :

« Mon collègue vient de me dire… »

et écouter la répartie générée.

Gérer correctement les permissions Android.

Si la permission micro est refusée, expliquer comment la réactiver.

---

# 15 — HISTORIQUE LOCAL

Pas de backend obligatoire pour la V1.

Stocker localement :

* réparties
* favoris
* paramètres
* conversations
* fournisseur sélectionné
* préférences utilisateur

Les clés API restent dans le stockage sécurisé et non dans le stockage classique.

Permettre :

* recherche
* suppression
* réutilisation
* copie
* partage

---

# 16 — DESIGN

Je veux un design réellement original.

Pas une application Flutter générique composée de Card blanches.

Utiliser Material 3 comme base mais créer une identité visuelle propre à NabuClash.

Direction artistique :

**Cyber Comedy / Neon Glass**

Fond sombre :

bleu nuit / violet profond.

Utiliser des accents :

🟣 violet électrique

🩷 magenta

🟠 orange

🔵 cyan

Créer :

* gradients
* cartes colorées semi-transparentes
* léger glassmorphism
* coins très arrondis
* ombres douces
* animations
* transitions fluides
* grandes icônes
* excellente lisibilité

Attention :

le glassmorphism ne doit jamais diminuer la lisibilité.

Le contraste du texte doit rester excellent.

---

# 17 — ANIMATIONS DE GÉNÉRATION

Pendant l'appel IA, afficher aléatoirement des messages humoristiques :

« Chargement du sarcasme… »

« Nabu cherche la petite phrase… »

« Affûtage de la répartie… »

« Préparation de la riposte… »

« Dosage du piquant… »

« Recherche d'une réponse qui claque… »

Ajouter une animation légère.

Ne pas bloquer l'interface.

---

# 18 — NAVIGATION

Créer une BottomNavigationBar avec :

🏠 Accueil

💬 Clash Chat

🥋 Dojo

⭐ Favoris

⚙️ Réglages

Le mode :

🆘 Sauve-moi !

doit être immédiatement accessible depuis l'accueil.

---

# 19 — PROMPT ENGINE

Ne pas écrire les prompts dans les widgets.

Créer un service :

PromptBuilder

ou équivalent.

Il construit les instructions à partir de :

* texte utilisateur
* contexte
* interlocuteur
* style
* niveau de piquant
* personnalité
* langue
* historique conversationnel

Prompt système général :

« Tu es NabuClash, un agent spécialisé dans la répartie, l'humour, le sarcasme et l'ironie. Analyse la situation et produis des réponses originales adaptées au contexte et au niveau de piquant demandé. Privilégie l'esprit, la créativité, le rythme et l'humour plutôt que l'insulte gratuite. »

Adapter ensuite dynamiquement les instructions.

---

# 20 — SORTIES STRUCTURÉES

Lorsque le fournisseur le permet, demander une réponse JSON structurée.

Exemple conceptuel :

{
"replies": [
{
"text": "...",
"style": "sarcastique",
"intensity": 3
}
]
}

Créer un parseur robuste.

Ne jamais afficher du JSON brut à l'utilisateur.

Si le modèle renvoie une réponse imparfaite, prévoir un fallback raisonnable.

---

# 21 — PERSONNALITÉ NABUCLASH

Permettre à l'utilisateur de sélectionner une personnalité globale :

🎩 Classe

😏 Insolent

🤡 Comique

🧠 Intello

🧊 Glacial

🎭 Théâtral

🌀 Absurde

La personnalité doit modifier les instructions envoyées à l'IA.

---

# 22 — MODE D'EMPLOI

Créer un écran intégré :

**Comment utiliser NabuClash ?**

Expliquer clairement :

1. Ajouter une clé API.
2. Choisir le fournisseur.
3. Choisir le modèle.
4. Écrire ou dicter la situation.
5. Choisir le style.
6. Régler le piquant.
7. Générer.
8. Copier, écouter, partager ou sauvegarder une réponse.

Expliquer également :

Clash Chat

Dojo

Sauve-moi

Favoris

Fournisseurs IA.

---

# 23 — ACCESSIBILITÉ

Prévoir :

* textes lisibles
* contraste élevé
* tailles de texte adaptatives
* zones tactiles suffisamment grandes
* support du lecteur d'écran
* labels sémantiques Flutter
* navigation compréhensible

Éviter les textes minuscules.

---

# 24 — ARCHITECTURE

Utiliser une architecture Flutter claire.

Par exemple :

lib/
main.dart
app/
core/
models/
ai/
services/
repositories/
storage/
screens/
widgets/
theme/
utils/

Ne pas créer un main.dart de plusieurs milliers de lignes.

Séparer UI, logique métier, stockage et appels réseau.

Choisir une solution cohérente de state management et l'utiliser correctement dans tout le projet.

---

# 25 — GESTION DES ERREURS

Traiter explicitement :

* aucune clé API
* clé invalide
* modèle invalide
* absence Internet
* timeout
* HTTP 401
* HTTP 403
* HTTP 404
* HTTP 429
* HTTP 5xx
* quota dépassé
* fournisseur indisponible
* JSON incorrect
* réponse vide

Ne jamais afficher simplement :

Exception: ...

Afficher un message compréhensible.

Exemple :

« Impossible de contacter Mistral. Vérifie ta connexion et ta clé API. »

Prévoir un bouton :

**Réessayer**

---

# 26 — CONFIDENTIALITÉ

Afficher clairement que les textes soumis sont envoyés au fournisseur IA sélectionné.

Ne pas envoyer les conversations vers plusieurs fournisseurs simultanément.

Aucune télémétrie cachée.

Aucun envoi de données inutile.

---

# 27 — TESTS

Tester réellement les parcours principaux.

Créer au minimum les tests pertinents pour :

* PromptBuilder
* parsing réponse IA
* stockage
* changement de fournisseur
* erreurs API

Puis tester manuellement :

Accueil → génération

Sauve-moi → génération

Chat → conversation

Dojo → exercice

Favoris

Historique

Paramètres

configuration fournisseur

redémarrage application.

---

# 28 — BUILD ANDROID

Avant livraison exécuter :

flutter clean

flutter pub get

flutter analyze

flutter test

Corriger les problèmes rencontrés.

Puis effectuer un vrai build Android Release.

Exemple :

flutter build apk --release --target-platform android-arm64

Ne considère PAS la mission terminée si seule l'interface fonctionne avec des données fictives.

---

# 29 — VÉRIFICATION APK

C'est une exigence importante.

J'ai déjà rencontré des projets où un APK prétendument x86_64 contenait en réalité des binaires ARM64 copiés incorrectement.

Donc :

NE PAS copier manuellement libapp.so ou d'autres binaires depuis une architecture différente.

NE PAS réutiliser un ancien APK.

NE PAS réutiliser le build d'un autre projet.

Effectuer un build propre de NabuClash.

Vérifier que les bibliothèques présentes dans :

lib/arm64-v8a/

sont réellement ARM64/AArch64.

L'APK livré doit correspondre exactement au projet source livré.

---

# 30 — LIVRABLES

À la fin je veux :

**NabuClash_AI_source.zip**

et

**NabuClash_AI_arm64_release.apk**

ainsi qu'un :

**README.md**

Le README doit expliquer :

* installation APK
* configuration
* clés API
* fournisseurs
* modèles
* permissions Android
* architecture
* compilation
* dépannage

Donner également un résumé des tests réalisés.

---

# 31 — RÈGLE IMPORTANTE POUR CODEX

Travaille directement sur les fichiers du projet.

Ne te contente pas de m'expliquer comment développer l'application.

Quand une erreur apparaît :

1. analyser l'erreur
2. identifier sa cause
3. modifier les fichiers concernés
4. relancer l'analyse/test
5. continuer jusqu'à résolution

Ne me demander d'intervenir manuellement que lorsqu'une action nécessite réellement un secret, un compte externe ou une intervention que tu ne peux pas effectuer.

Ne prétends jamais qu'un build ou un test a réussi s'il n'a pas réellement été exécuté.

---

# OBJECTIF FINAL

Je veux pouvoir prendre :

NabuClash_AI_arm64_release.apk

l'installer sur mon smartphone Android,

ouvrir NabuClash,

aller dans :

Réglages → Fournisseurs IA,

configurer au choix :

OpenAI / ChatGPT
Anthropic / Claude
Mistral
Gemini
Grok
Perplexity,

puis revenir sur l'accueil et écrire :

« Mon collègue vient de me dire que ma voiture date de la préhistoire. »

Choisir :

Sarcastique + niveau 3

et recevoir de véritables réparties générées par le fournisseur IA sélectionné.

Le projet n'est considéré comme terminé que lorsque ce parcours fonctionne réellement.
