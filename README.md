# Jalon

Outil de recherche d'alternance/stage pour étudiants ingénieurs : profil structuré, matching automatique avec une offre, génération de CV et lettre de motivation, suivi des candidatures avec historique daté.

## Stack

- **Frontend** : Flutter Web
- **Backend** : Firebase (Auth, Firestore, Storage, Cloud Functions)
- **Paiement** : Stripe Checkout (redirection hébergée, pas le SDK client — flutter_stripe_web est encore instable)
- **Matching** : appel LLM via Cloud Function (function calling pour une sortie structurée), pas de ML custom
- **Environnement de dev** : GitHub Codespaces (devcontainer Flutter), le temps d'acheter un Mac

## Structure du projet

~~~
lib/
├── main.dart                 # point d'entrée, initialise Firebase
├── firebase_options.dart     # généré par flutterfire configure
├── app.dart                  # widget racine, navigation (login vs app)
│
├── theme/
│   └── app_theme.dart        # couleurs, typographie (IBM Plex), espacements
│
├── models/
│   ├── competence.dart
│   ├── experience.dart
│   ├── profil.dart
│   └── candidature.dart      # statut + historique (StatutCandidature, TypeEvenement)
│
├── repositories/             # seules classes autorisées à parler à Firestore
│   ├── profil_repository.dart
│   └── candidatures_repository.dart
│
├── services/
│   ├── auth_service.dart              # login/signup/logout
│   └── matching_service.dart          # appel Cloud Function LLM (à venir)
│
├── screens/
│   ├── auth/
│   ├── profil/
│   ├── candidature/
│   └── suivi/
│
└── widgets/                  # composants réutilisés (gauge, timeline, status_pill, status_dialog...)
~~~

## Schéma Firestore

~~~
users/{uid}
  nom, prenom, email, formation, ecole
  disponibilite: { type: "alternance" | "stage", dateDebutSouhaitee }
  competences: [{ id, nom, domaine, outils[] }]
  photoUrl

users/{uid}/candidatures/{candidatureId}
  poste, entreprise
  offreTexteBrut, offreUrl
  domainePoste, competencesMatchees[], scoreMatching, raisonsMatching[]
  cvGenereUrl, lmGeneree
  statut: "a_postuler" | "envoyee" | "relance" | "entretien" | "refus"
  historique: [{ type, date }]   # type inclut aussi "ajoutee"
  createdAt
~~~

## Scope V1

**Inclus** : profil structuré, import manuel d'offre (lien/texte collé), matching + score de pertinence (seuil indicatif à 75), génération CV/LM éditable, export PDF, dashboard de suivi avec statut modifiable et historique daté, authentification email/mot de passe.

**Hors scope V1** : auto-candidature, scraping/contact automatique, sourcing automatique d'offres (France Travail — prévu V2), responsive mobile complet (desktop uniquement pour l'instant).

## Avancement

- [x] Modèles Dart (Competence, Experience, Profil, Candidature)
- [x] AuthService
- [x] ProfilRepository, CandidaturesRepository
- [x] Écrans auth (login / signup)
- [x] Squelette de navigation (sidebar + 3 écrans vides)
- [ ] Écran nouvelle candidature (import offre + matching + génération)
- [ ] Cloud Function de matching (appel LLM)
- [ ] Écran suivi (feed + statut + historique)
- [ ] Génération PDF (CV + LM)
- [ ] Stripe Checkout

## Setup

~~~
flutter pub get
flutterfire configure
flutter run -d web-server
~~~

## Mise à jour du profil (formations, projets, langues, certifications)

Le profil ingénieur est passé de 4 sections (infos, compétences, expériences, dashboard) à un inventaire complet aligné sur les conventions d'un CV ingénieur junior français :

- `users/{uid}` : ajout de `telephone`, `ville`, `linkedinUrl`, `githubUrl`, `mobilite`, `permis[]`, `langues[]`, `certifications[]`, `centresInteret[]`
- `users/{uid}/formations/{id}` : nouvelle sous-collection (diplôme, établissement, dates, mention)
- `users/{uid}/projets/{id}` : nouvelle sous-collection (projets académiques/personnels, distincts des expériences pro)
- Les champs `formation`/`ecole` uniques ont été retirés du profil au profit de la liste `formations`

Deux niveaux de jauge de complétude : une jauge globale pondérée (photo 10%, contact 10%, formation 15%, expérience/projet 20%, compétences 15%, langues 10%, mobilité/permis 5%, certifications/centres d'intérêt 15%), et un badge de statut par section (vide/partiel/complet).

Volontairement exclu du modèle : date de naissance, nationalité, situation familiale.
