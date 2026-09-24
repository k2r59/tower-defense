# Prompts — La forêt des Anciens (tranche jouable)

Les prompts sont **en anglais** : les générateurs d'images y sont nettement plus
précis, surtout sur les contraintes techniques (fond uni, angle, cadrage).

## Mode d'emploi

1. Colle **la bible de style** en tête de chaque demande, sans la modifier.
2. Ajoute ensuite **un seul** bloc d'asset.
3. Une image par asset. Jamais de planche de plusieurs objets : on ne peut pas
   les découper proprement, et l'échelle dérive d'un objet à l'autre.
4. Fond **magenta uni**, pas « transparent » : les modèles réussissent mal la
   transparence, et un aplat magenta se détoure parfaitement ensuite.

---

## 0. L'ordre — du simple au complexe

Le joueur doit pouvoir gagner le premier niveau sans rien comprendre, et se
retrouver à réfléchir au cinquième. La règle qui tient tout : **une seule idée
nouvelle par niveau**. Jamais une tour et un ennemi en même temps — sinon le
joueur ne sait pas ce qui a changé, ni à quoi attribuer sa défaite.

| Niveau | Ce qui arrive | Ce que le joueur apprend |
|---|---|---|
| 1 | Une tour (archers), un ennemi (gobelin), un chemin, 5 vagues | Poser une tour, la vendre |
| 2 | Le loup — rapide, peu de vie | La cadence de tir compte plus que les dégâts |
| 3 | La tour de cristal — dégâts de zone | Certaines tours répondent à certains groupes |
| 4 | L'arbre possédé — lent et blindé, et le canon qui lui répond | Choisir sa tour selon l'ennemi |
| 5 | Les racines : fermer un passage pendant quelques secondes | Le terrain est une arme |
| Boss | Le gardien corrompu | Tout ce qui précède, en même temps |

Les niveaux 2 et 3 de chaque tour ne se débloquent qu'au niveau 4 : avant ça,
le joueur a déjà assez de décisions à prendre.

**Donc on génère en trois lots**, et on ne passe au suivant qu'une fois le
précédent jouable :

- **Lot 1 — le jeu existe.** Tour d'archers (socle niveau 1 + tête), gobelin en
  morceaux, flèche, impact, emplacement vide, les quatre couches de map.
  Une quinzaine d'images, et le niveau 1 tourne.
- **Lot 2 — il devient intéressant.** Loup en morceaux, tour de cristal
  (niveau 1 + tête), éclat magique.
- **Lot 3 — il devient exigeant.** Arbre possédé, tour canon, boulet, puis les
  niveaux 2 et 3 des trois tours.

Tout ce qui suit est écrit dans cet ordre-là.

---

## BIBLE DE STYLE — à coller avant chaque prompt

```
STYLE (identical for every asset in this set):
Stylized fantasy mobile game asset, hand-painted look, clean readable
silhouette, slightly exaggerated proportions, vivid magical accents in
cyan and turquoise.
VIEW: three-quarter top-down, camera 50 degrees above the horizon,
orthographic projection, no perspective distortion, no vanishing point.
LIGHT: key light from the top-left, soft ambient fill, gentle rim light.
No cast shadow on the ground, no ground plane, no scenery.
FRAMING: one single object, centred, entirely inside the frame,
10% empty margin on every side.
BACKGROUND: flat uniform pure magenta #FF00FF, no gradient, no texture,
no vignette.
FORBIDDEN: text, letters, numbers, watermark, logo, border, frame,
user interface, multiple objects, variations grid, character other than
the subject.
OUTPUT: square image, 1024 x 1024.
```

---

## 1. Les tours — 3 familles, 3 niveaux

Un principe pour toutes : **le socle et la tête sont deux images séparées**
quand la tour vise. La tête tournera vers l'ennemi dans le moteur ; si elle est
peinte sur le socle, elle ne pourra jamais pivoter.

### 1.1 Tour d'archers elfe

**Socle, niveau 1**
```
SUBJECT: an elven archer tower, level 1. A small wooden watchtower grown from
a living tree: pale carved timber, spiral steps around the trunk, green leaf
canopy roof, a few glowing turquoise runes carved in the wood. Modest and
simple, clearly an early-game building. Seen from above at three-quarter
angle, the open platform at the top is EMPTY: no archer, no weapon, nothing
standing on it.
```

**Socle, niveau 2** — même bloc, en remplaçant la dernière phrase descriptive par :
```
Bigger and richer than level 1: two stacked platforms, thicker trunk, more
carved runes glowing brighter, small hanging lanterns, denser canopy.
Same species of tree, same palette, same proportions of trunk to platform.
```

**Socle, niveau 3**
```
Grand and imposing: three stacked platforms, massive ancient trunk with
exposed roots, bright turquoise runes flowing along the bark like veins,
a crown of golden leaves, small floating light motes. Clearly the same
tower as level 1, fully grown. Same palette, same silhouette language.
```

**Tête (les trois niveaux partagent la même, à trois tailles)**
```
SUBJECT: the top weapon of an elven archer tower, seen from directly above at
three-quarter angle, detached from any building. A curved elven bow mounted on
a small wooden pivot ring, carved leaf motifs, turquoise rune glow on the
limbs, aiming toward the RIGHT side of the image. Nothing below the pivot
ring, no platform, no tower, no archer.
```

### 1.2 Tour de cristal

**Socle, niveau 1**
```
SUBJECT: a crystal mage tower, level 1. A short round tower of pale grey
stone with a single turquoise crystal shard growing out of its open top,
thin glowing veins running down the stonework, small moss patches at the
base. Simple and compact, early-game. The crystal points straight up.
```

Niveaux 2 et 3 : même bloc, en remplaçant la description par
```
[niveau 2] Taller, two stone tiers, three crystal shards of different heights
on the top, brighter glow, faint floating shards orbiting slowly.
```
```
[niveau 3] Tall and ornate, carved stone arches, a large central crystal
surrounded by six orbiting shards, intense turquoise light, glowing runic ring
floating around the tower. Same stone, same crystal colour as level 1.
```

**Tête**
```
SUBJECT: a single floating turquoise crystal shard, seen at three-quarter
top-down angle, detached, hovering. Faceted like a gemstone, glowing from
within, faint energy wisps around it, pointing toward the RIGHT side of the
image. No base, no stone, no tower.
```

### 1.3 Tour canon

**Socle, niveau 1**
```
SUBJECT: the base of a dwarven cannon tower, level 1, WITHOUT its cannon.
A squat cylinder of riveted brass and dark oak beams, a circular metal
turntable on top, ready to receive a gun. Steam vents, bolts, a small
pressure gauge. Sturdy and mechanical. The turntable is bare and empty.
```

Niveaux 2 et 3 :
```
[niveau 2] Wider and taller, two metal bands, extra pipes, a small boiler on
the side, brighter polished brass.
```
```
[niveau 3] Massive and industrial, heavy armour plating, thick pipes with
escaping steam, glowing turquoise pressure core visible through a grate.
Same brass and oak palette as level 1.
```

**Tête**
```
SUBJECT: a single dwarven cannon barrel on its pivot mount, seen at
three-quarter top-down angle, detached from any tower. Brass barrel with iron
rings, wooden grip, a turquoise glow inside the muzzle, pointing toward the
RIGHT side of the image. No base, no turntable, no tower, no wheels.
```

---

## 2. Les ennemis — en morceaux, pas en images de marche

Pour chaque ennemi : **une image entière** (silhouette de référence) puis
**les morceaux séparés**. Ce sont les morceaux qui servent vraiment ; l'image
entière me sert de repère pour les assembler.

### 2.1 Loup corrompu

**Entier**
```
SUBJECT: a corrupted forest wolf, seen from a three-quarter top-down angle,
walking toward the RIGHT side of the image, side profile. Dark violet fur,
glowing purple eyes, crystalline purple growths on the spine and shoulders,
wisps of purple smoke. Lean and dangerous, stylized, readable silhouette.
All four legs visible, standing.
```

**Morceaux** — une image par morceau, même bloc de style :
```
SUBJECT: the BODY ONLY of a corrupted forest wolf: torso, neck and head,
no legs, no tail. Side profile facing RIGHT, three-quarter top-down angle.
Dark violet fur, glowing purple eyes, crystalline purple growths on the
spine. Clean cut where the legs would attach.
```
```
SUBJECT: a SINGLE FRONT LEG of a corrupted forest wolf, side profile facing
RIGHT, detached, no body. Dark violet fur, purple claw, clean cut at the
shoulder.
```
```
SUBJECT: a SINGLE HIND LEG of a corrupted forest wolf, side profile facing
RIGHT, detached, no body. Dark violet fur, muscular thigh, purple claw, clean
cut at the hip.
```
```
SUBJECT: the TAIL ONLY of a corrupted forest wolf, detached, no body. Dark
violet fur with a faint purple glow at the tip, gently curved, clean cut at
the base.
```

### 2.2 Gobelin des bois

**Entier**
```
SUBJECT: a forest goblin, seen from a three-quarter top-down angle, walking
toward the RIGHT side of the image, side profile. Green skin, large pointed
ears, leather scraps and a bark shoulder pad, a crude wooden club in one hand,
a mischievous grin. Small, hunched, fast-looking. Stylized, chunky
proportions, readable silhouette.
```

**Morceaux** — même logique : `torso and head only`, `one arm holding a crude
wooden club, detached, cut at the shoulder`, `one empty arm, detached`,
`one leg, detached, cut at the hip` (les deux jambes seront la même image,
retournée).

### 2.3 Arbre possédé

**Entier**
```
SUBJECT: a possessed tree creature, seen from a three-quarter top-down angle,
walking toward the RIGHT side of the image. A twisted dead tree with a face in
its bark, two long root-like legs, branch arms, glowing purple sap running
through the cracks, a few purple crystal shards embedded in the trunk. Heavy
and slow-looking, large readable silhouette.
```

**Morceaux** : `trunk and face only, no limbs`, `one branch arm, detached`,
`one root leg, detached`.

---

## 3. Projectiles et impacts

Petits, générés en 512×512 (précise-le en remplacement de la ligne OUTPUT).

```
SUBJECT: a single elven arrow, seen from a three-quarter top-down angle,
flying toward the RIGHT side of the image, with a faint turquoise energy
trail behind it. Carved wooden shaft, green fletching, glowing tip.
```
```
SUBJECT: a single floating turquoise magic bolt, a compressed shard of crystal
energy with a comet-like trail behind it, travelling toward the RIGHT side of
the image. Bright core, soft outer glow.
```
```
SUBJECT: a single dwarven cannonball, dark iron sphere with a turquoise glowing
crack pattern, small steam puffs trailing behind it, travelling toward the
RIGHT of the image.
```
```
SUBJECT: a circular impact burst of turquoise magical energy seen from directly
above, top-down, flat on the ground: a bright ring expanding outward with
sparks and small shards. Centred, symmetrical, no object in the middle.
```

---

## 4. Le décor de la map, en couches

Une image par couche, **au format de l'écran** : remplace la ligne OUTPUT par
`OUTPUT: vertical image, 1170 x 2532 pixels.` Et pour ces quatre-là seulement,
supprime la contrainte de fond magenta sur la première.

**Couche 1 — le sol** (la seule sans fond magenta)
```
SUBJECT: a top-down fantasy forest floor for a tower defense map, seen from
50 degrees above. Rich dark soil, moss, scattered small stones, fallen leaves,
tree roots crossing the ground, a few patches of turquoise glowing mushrooms.
No path, no buildings, no characters. Even lighting, no strong focal point,
the whole surface usable as a background. Fills the entire frame edge to edge.
```

**Couche 2 — le chemin**
```
SUBJECT: a single winding dirt path segment for a top-down game map, seen from
50 degrees above, flat on the ground. Packed pale earth bordered by small
stones and moss, worn and travelled. The path enters at the TOP-LEFT of the
image and exits at the BOTTOM-RIGHT, curving twice in a smooth S shape.
Everything outside the path is flat uniform magenta #FF00FF.
```

**Couche 3 — derrière** (les ennemis passent devant)
```
SUBJECT: a set of background forest elements for a top-down game map: distant
giant tree trunks, elven stone ruins, a broken arch, a small glowing spring.
Arranged along the TOP and LEFT edges of the frame only, the centre completely
empty. Everything else flat uniform magenta #FF00FF.
```

**Couche 4 — devant** (les ennemis passent derrière)
```
SUBJECT: foreground forest foliage for a top-down game map: large fern leaves,
hanging vines and low branches, seen from above, slightly out of focus.
Arranged along the BOTTOM and RIGHT edges of the frame only, the centre
completely empty. Everything else flat uniform magenta #FF00FF.
```

**L'emplacement de construction vide**
```
SUBJECT: an empty circular building plot for a tower defense game, seen from
directly above at a slight three-quarter angle, flat on the ground. A ring of
carved pale stone slabs set into mossy earth, faint turquoise runes on the
inner edge, the centre bare and empty, inviting. No building, no tower, no
character.
```

---

## 5. Ce qu'il ne faut PAS générer

- **L'interface** : barres, boutons, compteurs, arbre d'amélioration, écran de
  victoire. Formes et thème Godot — net, cohérent, modifiable en une ligne.
- **Les auras de portée** : un cercle dessiné par shader, pas une image.
- **Les images de marche** : voir plus haut, c'est le découpage qui anime.
- **Les icônes de tours pour le menu** : une capture du sprite suffit.

---

## 6. Quand tu me rends les fichiers

Dépose les PNG tels quels, sans les retoucher. Je m'occupe du détourage du
magenta, de la mise à l'échelle commune, des points d'ancrage (les pieds pour
un ennemi, la base pour une tour), du découpage en atlas et de l'arborescence
Godot avec les ressources d'animation.

Nomme-les simplement, ça suffit :
`tour-elfe-1.png`, `tour-elfe-tete.png`, `loup-corps.png`, `loup-patte-avant.png`,
`map-sol.png`, `map-chemin.png`…
