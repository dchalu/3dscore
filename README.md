# Score3D

Score3D est une application iOS de suivi de scores pour les parcours de tir 3D.
Elle permet de créer un parcours, gérer un peloton de 1 à 6 archers, saisir les deux flèches par cible, reprendre un parcours en cours et consulter le résumé final.

## Fonctionnalités

- Création d'un parcours avec date, nom et cible de départ.
- Gestion d'un peloton de 1 à 6 archers.
- Tri alphabétique automatique des archers avant le départ.
- Ordre des 24 cibles recalculé selon la cible de départ.
- Saisie rapide des valeurs FFTA 3D: `11`, `10`, `8`, `5`, `M`.
- Correction des flèches déjà saisies.
- Navigation entre les cibles déjà atteintes.
- Sauvegarde locale des parcours en cours.
- Résumé final par archer avec total et détail des impacts.
- Suppression d'un parcours avec confirmation.
- Interface en français, compatible mode clair et mode sombre.

## Confidentialité

Score3D est conçue comme une application 100% locale.

- Aucun compte utilisateur.
- Aucun serveur.
- Aucun tracking.
- Aucune publicité.
- Aucun analytics.
- Aucune synchronisation cloud.
- Les scores sont stockés localement sur l'appareil via SwiftData.

Cette approche simplifie la déclaration de confidentialité App Store Connect: tant qu'aucun SDK tiers ou service réseau n'est ajouté, l'application ne collecte pas de données.

## Règles de score

Les valeurs disponibles correspondent au scoring 3D utilisé dans l'application:

| Valeur | Libellé |
| --- | --- |
| 11 | 11 |
| 10 | 10 |
| 8 | 8 |
| 5 | 5 |
| 0 | M |

Chaque cible reçoit deux flèches par archer. Le total d'une cible est la somme des deux flèches, et le total d'un archer est recalculé depuis toutes ses saisies.

## Architecture

Le projet est une application SwiftUI avec persistance SwiftData.

```text
Score3D/
  LaunchScreen.storyboard
  Score3D.xcodeproj/
  Score3D/
    Assets.xcassets/
    ContentView.swift
    Item.swift
    Score3DApp.swift
    ScoreRules.swift
  Score3DTests/
    ScoreRulesTests.swift
```

### Fichiers principaux

- `Score3DApp.swift`: point d'entrée de l'application et configuration SwiftData.
- `ContentView.swift`: interface principale, création de parcours, scoring et résumé.
- `Item.swift`: modèles SwiftData `ShootingRound`, `ScoreEntry` et `Archer`.
- `ScoreRules.swift`: règles métier testables hors UI.
- `ScoreRulesTests.swift`: tests unitaires des règles de score, navigation et persistance.

## Persistance

Les données sont stockées localement avec SwiftData.

L'application évite les échecs silencieux:

- si le conteneur SwiftData ne peut pas s'ouvrir au lancement, un écran d'erreur est affiché au lieu d'un crash volontaire;
- si une sauvegarde échoue pendant l'utilisation, les changements non persistés sont annulés et une alerte informe l'utilisateur.

## Pré-requis

- Xcode 26 ou plus.
- iOS 26.5 comme cible de déploiement actuelle du projet.
- SwiftUI.
- SwiftData.
- Swift Testing pour les tests unitaires.

## Build

Ouvrir le projet Xcode:

```bash
open Score3D/Score3D.xcodeproj
```

Puis sélectionner le schéma `Score3D` et lancer le build depuis Xcode.

## Tests

Les tests sont dans le target `Score3DTests`.

Ils couvrent notamment:

- les valeurs de score;
- l'ordre des cibles;
- la génération des noms de parcours;
- la gestion du peloton;
- la navigation de scoring;
- les corrections;
- la persistance SwiftData en mémoire.

Dernière validation locale:

```text
35 tests passed, 0 failed
```

## Statut

Version V1 fonctionnelle, préparée pour une première soumission App Store.

Les prochaines évolutions probables:

- tests UI sur petits écrans et Dynamic Type;
- préparation des captures App Store;
- éventuelle stratégie de migration SwiftData pour les versions futures.

## Licence

Voir le fichier `LICENSE`.
