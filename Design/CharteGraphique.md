# Charte graphique Score3D

Cette charte formalise l'interface existante de Score3D pour servir de base aux prochaines evolutions. Elle decrit ce qui est deja present dans `ContentView.swift`, sans introduire de nouveau langage visuel.

## Principes

- Interface calme, lisible en situation de parcours, avec des zones tactiles larges.
- Priorite aux informations de score, de cible, de progression et d'etat du parcours.
- Les ecrans doivent rester sobres: fond global, surfaces claires, bordures fines, accent bleu pour les actions interactives.
- Les composants doivent rester coherents entre accueil, scoring, recapitulatif et feuille de score.

## Couleurs

Les couleurs sont adaptatives clair/sombre via `Score3DTheme`.

| Token | Clair | Sombre | Usage |
| --- | --- | --- | --- |
| `background` | `#F5F3EC` | `#111612` | Fond principal des ecrans |
| `surface` | `#FCFBF7` | `#1A201B` | Cartes, panneaux, boutons ronds |
| `textPrimary` | `#1E2521` | `#F1F3EE` | Titres, scores, textes principaux |
| `textSecondary` | `#6F756F` | `#A8AEA8` | Metadonnees, titres de barre, textes secondaires |
| `forest` | `#28513D` | `#8CB7A0` | Actions principales, progression terminee |
| `paleForest` | `#E7EEE8` | `#26362D` | Badges termines, fonds discrets, zones de synthese |
| `interaction` | `#2878C8` | `#7BB7F0` | Accent interactif, liens, chevrons, selection active |
| `selection` | `#E5F1FB` | `#17314A` | Etat selectionne, fonds de boutons secondaires actifs |
| `border` | `#D9DDD7` | `#3B463F` | Contours et separations |

Regles d'usage:

- Utiliser `background` comme fond d'ecran continu.
- Utiliser `surface` pour les cartes et panneaux contenant de l'information.
- Utiliser `interaction` uniquement pour les elements actionnables ou actifs.
- Utiliser `forest` pour les actions principales et la progression validee.
- Eviter d'ajouter de nouvelles couleurs sans les ajouter au theme avec une version clair/sombre.

## Typographie

La typographie repose sur les styles systeme SwiftUI.

| Role | Style | Usage |
| --- | --- | --- |
| Titre de section/action importante | `.title3.weight(.semibold)` | "Parcours", boutons principaux, noms de parcours en liste |
| Titre de top bar | `.title3` ou `.title3.weight(.semibold)` | Nom du parcours en scoring, titre "Parcours termine" |
| Grand titre de contenu | `.system(size: 30, weight: .semibold)` | Nom du parcours dans le recapitulatif, nom d'archer en feuille de score |
| Score fort | `.system(size: 30...32, weight: .bold).monospacedDigit()` | Totaux et scores de synthese |
| Score courant | `.system(size: 20...28).monospacedDigit()` | Lignes de score, panneau de scoring |
| Texte courant | `.body` | Dates, libelles de formulaire, contenu standard |
| Texte secondaire dense | `.callout` | Dates, compteurs, lignes de tableau |
| Badge | `.caption.weight(.semibold)` | Statuts "En cours" et "Termine" |

Regles d'usage:

- Utiliser les chiffres monospaces pour les scores, totaux et colonnes numeriques.
- Garder les noms de parcours coherents entre accueil, scoring et recapitulatif.
- Limiter les grands titres a l'information centrale de l'ecran.

## Formes et espacements

| Element | Valeur |
| --- | --- |
| Cartes et panneaux principaux | Rayon `14`, bordure `1` |
| Bouton d'action principal | Rayon `16`, hauteur minimale `52...54` |
| Boutons de score | Rayon `12`, bordure `1.5` |
| Petits controles carres | Rayon `8...10` |
| Boutons ronds de navigation | `44 x 44`, fond `surface`, bordure `border` |
| Chevrons de cible | `36 x 36`, fond `surface`, bordure `border` |
| Progression segmentee | Hauteur `8`, rayon `2`, espacement `3` |
| Padding de carte | `14...16` |
| Padding d'ecran | `16`, ou `10` horizontal sur l'ecran de scoring |

Regles d'usage:

- Les cartes ne doivent pas etre imbriquees dans d'autres cartes.
- Les controles tactiles principaux doivent rester autour de `44 x 44` minimum.
- Les listes de scores doivent garder des largeurs fixes pour eviter les sauts de mise en page.

## Composants

### Bouton principal

`PrimaryActionButtonStyle` sert aux actions fortes:

- "Nouveau parcours"
- "Demarrer le parcours"
- "Enregistrer les modifications"
- "Retour a l'accueil"
- action principale du scoring

Style: texte blanc, fond `forest`, rayon `16`, opacite reduite a l'appui, fond `border` si desactive.

### Boutons de score

`ScoreValueButtonStyle` sert aux valeurs de fleche.

Style: fond `surface`, bordure `interaction`, rayon `12`. L'etat desactive passe en `paleForest` avec texte secondaire.

### Badge de statut

`StatusBadge` affiche l'etat d'un parcours.

- Termine: texte secondaire sur `paleForest`.
- En cours: accent `interaction` sur `selection`.

### Barre de progression segmentee

`SegmentedTargetProgressView` represente les 24 cibles.

- Cible courante: `interaction`.
- Cible completee: `forest`.
- Cible restante: `surface` avec bordure `border`.

### Top bars custom

Les ecrans de scoring et de recapitulatif utilisent une barre custom avec:

- bouton rond `chevron.left` a gauche;
- titre en `.title3`;
- navigation bar native masquee.

Le chevron doit utiliser `dismiss()` quand il ramene a l'accueil.

### Cartes de parcours et recapitulatif

Les cartes utilisent:

- fond `surface`;
- bordure `border`;
- rayon `14`;
- padding interne `14...16`;
- titre en `textPrimary`;
- metadonnees en `textSecondary`.

## Iconographie

- Utiliser les SF Symbols existants.
- `chevron.left`: retour/quitter l'ecran courant.
- `chevron.right`: navigation vers une feuille de score ou une cible suivante.
- `pencil`: modification d'un parcours.
- `trash`: suppression.
- `square.and.arrow.up`: partage/export.
- `plus`: ajout d'un archer.

Les icones actionnables utilisent `interaction` quand elles sont disponibles.

## Accessibilite

- Chaque bouton icon-only doit avoir un `accessibilityLabel`.
- Les progressions doivent fournir un libelle et une valeur lisible.
- Les textes de score et de total doivent rester lisibles en clair et sombre.
- Les noms longs doivent utiliser `lineLimit` ou un retour sur deux lignes selon le contexte.

## Regles pour les evolutions

- Reutiliser les composants existants avant d'ajouter un nouveau style.
- Ajouter tout nouveau token visuel dans `Score3DTheme` avec variantes clair et sombre.
- Garder les actions principales en bas ou en tete de flux selon le contexte, jamais perdues au milieu d'une liste dense.
- Pour un nouvel ecran de parcours, reprendre la structure: fond `background`, contenus en `surface`, accent `interaction`, action principale `PrimaryActionButtonStyle`.
- Pour les donnees chiffrees, preferer `.monospacedDigit()` et des largeurs stables.
