# Les Gardiens des Sources

Tower defense fantasy, pour iOS, sous Godot 4.

Ce dépôt contient **les cinq niveaux de la première région**, jouables, avec
des formes de couleur à la place des dessins. Ce n'est pas une maquette : l'or,
les vagues, le tir, l'armure, les étoiles et les essences fonctionnent pour de
vrai. Les images viendront se poser par-dessus, sans changer une ligne de la
logique.

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

- **Clique un cercle de pierre** : une tour s'y construit. Au niveau 1 il n'y a
  qu'un type de tour, alors elle se pose directement ; dès qu'il y en a plusieurs, un
  petit menu demande laquelle, avec les prix.
- **Clique une tour déjà posée** : on peut l'améliorer ou la vendre. Son cercle
  de portée s'affiche.
- **Clique dans le vide** : les cercles de portée disparaissent.
- Les ennemis entrent par la gauche. Chacun qui atteint la sortie coûte des
  vies — une pour un gobelin ou un loup, **quatre pour un arbre**.
- Cinq vagues, puis le bilan : une étoile pour la victoire, une si rien n'est
  passé, une s'il te reste de l'or. Chaque étoile vaut une essence.

Les essences sont conservées d'une partie à l'autre, dans un fichier de
sauvegarde local. Elles se dépensent au sanctuaire, qui ne s'ouvre qu'après le
deuxième niveau — avant, le joueur a déjà assez à faire.

## La courbe : une idée par niveau

C'est la règle qui tient tout le reste. Chaque niveau introduit **une** chose,
et rien d'autre ne bouge, pour que la leçon soit lisible.

| Niveau | Ce qui arrive | Ce que le joueur apprend |
|---|---|---|
| 1 · Le sentier des racines | rien de neuf | poser une tour, et la vendre |
| 2 · La clairière basse | le **loup**, deux fois plus rapide | la *cadence* compte plus que les dégâts |
| 3 · Les pierres dressées | la **tour de cristal**, faible mais en zone | on choisit une tour pour la *forme* d'une vague |
| 4 · Le val d'écorce | l'**arbre** armuré, et le **canon** | monter ses tours ne suffit pas, il faut en *changer* |
| 5 · La source corrompue | les **racines**, deux fois par partie | la meilleure défense n'est pas toujours une tour |

Le niveau 4 est le seul vrai mur, et il est volontaire. L'armure retire un
montant **fixe** à chaque coup, jamais un pourcentage : un pourcentage se
compense en améliorant ce qu'on a déjà, un montant fixe oblige à changer
d'outil. Une flèche de niveau 1 (8 dégâts) contre une armure de 12 ne fait
**rien** — et ça se voit, le tir rebondit. Le canon (34) passe.

Le canon vise aussi différemment : le plus **résistant** à portée, pas le plus
avancé sur le chemin. Sans cette règle, un canon anti-blindé passerait sa
partie à tirer sur les gobelins rapides qui précèdent l'arbre, et ne tirerait
jamais sur ce pour quoi on l'a acheté.

## Régler le jeu sans programmer

Tout ce qui se règle est dans `donnees/`, en JSON. Ouvre-les dans n'importe
quel éditeur de texte, change un chiffre, relance : rien à recompiler.

- **`donnees/equilibrage.json`** — dégâts, portée, cadence, zone et prix des
  tours ; vie, vitesse, armure et prime des ennemis. Chaque entrée porte une
  note qui dit *pourquoi* elle existe : si deux lignes posent la même question
  au joueur, il y en a une de trop.
- **`donnees/niveau-0N.json`** — le tracé, les emplacements, les vies, l'or de
  départ, les tours autorisées et les vagues.
- **`donnees/ameliorations.json`** — ce que le sanctuaire vend.

Deux champs méritent une explication :

- **`tours`** — les familles que ce niveau propose. Le niveau 1 n'en a qu'une,
  exprès : un menu d'un seul choix n'est pas un choix, c'est un obstacle.
- **`solution`** — une façon de gagner, une famille par emplacement. Elle ne
  sert pas au jeu : elle sert au **test automatique**, qui la joue et vérifie
  qu'elle gagne encore. Si un réglage la rend perdante, on le sait avant le
  joueur.

Si un niveau te paraît trop facile, baisse `or_depart` avant de gonfler les
vagues. Si une tour te semble inutile, touche à sa `cadence` avant ses
`degats` : c'est presque toujours la cadence qui décide.

## Ce qu'il y a dans le dossier

```
project.godot          réglages du projet (écran paysage, rendu mobile)
scenes/carte.tscn      la carte de campagne, qui sert aussi de menu
scenes/jeu.tscn        un niveau
scenes/sanctuaire.tscn la boutique d'améliorations permanentes
scripts/jeu.gd         la boucle : vagues, or, construction, dégâts, victoire
scripts/tour.gd        viser, tirer, s'améliorer
scripts/ennemi.gd      suivre le chemin, encaisser, être ralenti, mourir
scripts/projectile.gd  le tir qui poursuit sa cible et annonce son impact
scripts/ath.gd         vies, or, vague, menu de construction, racines, fin
scripts/carte.gd       les cinq niveaux, le verrouillage, le sanctuaire
scripts/partie.gd      ce qui survit entre les parties : essences, étoiles
donnees/               tout ce qui se règle
scripts/test_combat.gd les règles de combat, vérifiées une par une
scripts/test_sanctuaire.gd  l'ouverture, l'achat, les prérequis, la reprise
verifier.sh            lance tout ce qui précède
```

## Vérifier que tout marche, sans écran

```bash
./verifier.sh                       # tout : les cinq niveaux + le sanctuaire
GODOT=/chemin/vers/godot ./verifier.sh
```

Il fait trois choses. D'abord les **règles de combat**, une par une : une armure
qui s'appliquerait deux fois, un ralentissement qui s'annulerait tout seul — le
niveau resterait gagnable et la faute ne se verrait qu'après des heures de jeu,
sur la seule impression que « quelque chose cloche ». Ensuite le **sanctuaire**.
Enfin les **niveaux**.

Pour chaque niveau, il joue **deux** parties : une avec la solution écrite dans
ses données, qui doit se gagner, et une sans construire une seule tour, qui
doit se perdre. La seconde compte autant que la première — un niveau qu'on
gagne les bras croisés n'est pas un niveau.

Il vérifie en plus une affirmation de conception, et pas seulement un
commentaire : **le niveau 4 ne doit PAS se gagner avec des archers seuls**. Le
jour où ce test passe, c'est que l'armure ou le canon a été déréglé et que le
niveau ne pose plus la question qu'il prétend poser.

Tout tourne sur une sauvegarde vide (`--neuf`), ce qui prouve la règle d'or
ci-dessous.

À la main, pour regarder une partie de près :

```bash
godot --headless --path . -- --test --neuf --niveau=niveau-04
godot --headless --path . -- --test --neuf --niveau=niveau-04 --test-passif
godot --headless --path . -- --test --neuf --niveau=niveau-04 --famille=archers
godot --headless --path . --script res://scripts/test_combat.gd
godot --headless --path . --script res://scripts/test_sanctuaire.gd
```

Chaque partie d'essai affiche l'état à chaque vague, puis un décompte par
espèce : nés, abattus, passés. C'est ce décompte qui dit *lequel* passe, et
c'est la seule information qui permette de régler quoi que ce soit — « c'est
trop dur » n'en est pas une.

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
niveau qui est mal réglé. `verifier.sh` lance tout sur une sauvegarde vide,
donc cette règle est vérifiée à chaque fois, pas seulement espérée.

## La suite

La première région est complète. Ce qui vient ensuite :

- **Les dessins.** Les formes de couleur seront remplacées par des Sprite2D.
  Le brief destiné au générateur d'images est dans
  `brief-assets-foret-des-anciens.pdf` et `docs-prompts-images.md`.
- **Une deuxième région**, avec sa propre idée neuve — et la même règle : une
  seule à la fois.
