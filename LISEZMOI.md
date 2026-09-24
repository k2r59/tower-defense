# Les Gardiens des Sources

Tower defense fantasy, pour iOS, sous Godot 4.

Ce dépôt contient le **niveau 1 jouable**, avec des formes de couleur à la
place des dessins. Ce n'est pas une maquette : l'or, les vagues, le tir, les
étoiles et les essences fonctionnent pour de vrai. Les images viendront se
poser par-dessus, sans changer une ligne de la logique.

---

## L'ouvrir, sans rien connaître à Godot

1. Télécharge Godot sur [godotengine.org](https://godotengine.org/download) —
   version **4.7 ou plus**, édition standard (pas .NET). Pas d'installateur :
   tu glisses l'application dans ton dossier Applications.
2. Ouvre Godot. Il demande un projet : clique **Importer**, choisis le fichier
   `project.godot` de ce dossier, puis **Importer et modifier**.
3. Appuie sur **▶** en haut à droite (ou F5). Le jeu se lance.

C'est tout. Tu n'as jamais besoin de toucher aux scènes ni aux scripts.

## Y jouer

- **Clique un cercle de pierre** : une tour d'archers s'y construit (50 or).
- **Clique une tour déjà posée** : elle s'améliore, si tu as l'or (60, puis 100).
  Son cercle de portée s'affiche.
- **Clique dans le vide** : les cercles de portée disparaissent.
- Les gobelins arrivent par le haut. Chacun qui atteint le bas coûte une vie.
- Cinq vagues, puis le bilan : une étoile pour la victoire, une si rien n'est
  passé, une s'il te reste de l'or. Chaque étoile vaut une essence.

Les essences sont conservées d'une partie à l'autre, dans un fichier de
sauvegarde local. Elles serviront à l'arbre d'améliorations permanent, qui ne
s'ouvrira qu'après le deuxième niveau — avant, le joueur a déjà assez à faire.

## Régler le jeu sans programmer

Tout ce qui se règle est dans `donnees/`, en JSON. Ouvre-les dans n'importe
quel éditeur de texte, change un chiffre, relance : rien à recompiler.

- **`donnees/equilibrage.json`** — dégâts, portée, cadence et prix des tours ;
  vie, vitesse et prime des ennemis.
- **`donnees/niveau-01.json`** — le tracé du chemin, les emplacements de
  construction, le nombre de vies, l'or de départ et la composition des vagues.

Si le jeu te paraît trop facile, baisse `or_depart` ou monte la `vie` du
gobelin. Si une tour te semble inutile, touche à sa `cadence` avant ses
`degats` : c'est presque toujours la cadence qui décide.

## Ce qu'il y a dans le dossier

```
project.godot          réglages du projet (écran vertical, rendu mobile)
scenes/jeu.tscn        la scène lancée au démarrage
scripts/jeu.gd         la boucle : vagues, or, construction, victoire
scripts/tour.gd        viser, tirer, s'améliorer
scripts/ennemi.gd      suivre le chemin, encaisser, mourir
scripts/projectile.gd  le tir qui poursuit sa cible
scripts/ath.gd         vies, or, vague, écran de fin
scripts/partie.gd      ce qui survit entre les parties : essences, étoiles
donnees/               les deux fichiers à régler
```

## Vérifier que tout marche, sans écran

Deux parties automatiques, utiles après chaque modification :

```bash
# avec des tours : doit se gagner, et la revente doit rendre son dû
godot --headless --path . -- --test

# sans aucune tour : doit se perdre
godot --headless --path . -- --test --test-passif

# le sanctuaire : ouverture, achat, prérequis, reprise des essences
godot --headless --path . --script res://scripts/test_sanctuaire.gd
```

La seconde compte autant que la première : un niveau qu'on gagne sans rien
faire n'est pas un niveau.

## Le sanctuaire

Les essences gagnées en finissant un niveau s'y dépensent, et elles seules.
Trois choses le rendent jouable plutôt que subi :

- **Il n'existe pas avant le deuxième niveau.** Un écran de choix devant
  quelqu'un qui n'a pas encore posé sa première tour ne décide rien.
- **Les nœuds s'ouvrent au fil des niveaux**, et certains demandent un
  prérequis : on en voit trois à la fois, jamais vingt.
- **Tout se reprend gratuitement, à tout moment.** C'est ce qui supprime
  l'angoisse du mauvais choix définitif — et le besoin de lire un guide avant
  de dépenser.

La règle qui protège l'équilibrage : **chaque niveau doit être gagnable avec
zéro amélioration**. Le sanctuaire donne du confort et ouvre des façons de
jouer, jamais un passage obligé. Si un niveau exige d'y passer, c'est le
niveau qui est mal réglé.

Ce qu'on y achète se règle dans `donnees/ameliorations.json`.

## La suite

Le niveau 1 n'a qu'une tour et qu'un ennemi, volontairement — on apprend à
poser et à vendre, rien d'autre. La complexité arrive ensuite, une idée par
niveau : le loup rapide, puis la tour de zone, puis l'ennemi blindé et le
canon qui lui répond, puis les racines qui ferment un passage.
