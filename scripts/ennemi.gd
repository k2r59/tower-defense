class_name Ennemi
extends Node2D

## Un ennemi suit le chemin, point par point.
##
## Il ne cherche pas son itinéraire : le chemin est une donnée du niveau, et
## c'est très bien ainsi. Un calcul de trajet coûterait cher pour un résultat
## que le concepteur du niveau a déjà décidé.

signal mort(ennemi: Ennemi)
signal arrive_au_bout(ennemi: Ennemi)

var vie_max: float = 40.0
var vie: float = 40.0
var vitesse: float = 46.0
var prime: int = 8
var degats_sortie: int = 1
var rayon: float = 11.0
var couleur: Color = Color("#7cc45a")

## Ce que chaque coup perd avant de compter. Un montant FIXE, jamais un
## pourcentage : un pourcentage se compense en améliorant les tours qu'on a
## déjà, un montant fixe oblige à en changer. C'est ce qui fait exister le
## canon au niveau 4.
var armure: float = 0.0

var _chemin: PackedVector2Array
var _cible: int = 1
var _vivant := true

## Un ralentissement en cours : un facteur de vitesse, et ce qu'il en reste.
## Le canon s'en sert pour faire tituber, les racines pour clouer sur place.
var _facteur: float = 1.0
var _reste_ralenti: float = 0.0

## Le temps qu'il reste à afficher un coup qui n'a rien fait.
var _rebond: float = 0.0


func demarrer(chemin: PackedVector2Array, reglages: Dictionary) -> void:
	_chemin = chemin
	position = chemin[0]
	vie_max = float(reglages.get("vie", 40))
	vie = vie_max
	vitesse = float(reglages.get("vitesse", 46))
	prime = int(reglages.get("prime", 8))
	degats_sortie = int(reglages.get("degats_sortie", 1))
	rayon = float(reglages.get("rayon", 11))
	armure = float(reglages.get("armure", 0.0))
	couleur = Color(str(reglages.get("couleur", "#7cc45a")))


func _process(delta: float) -> void:
	if not _vivant or _chemin.is_empty():
		return

	if _rebond > 0.0:
		_rebond = maxf(0.0, _rebond - delta)
		queue_redraw()

	var reste := vitesse * _facteur * delta
	# Une boucle, et non un simple déplacement : à vitesse élevée ou en avance
	# rapide, un ennemi peut franchir plusieurs points dans la même image. Sans
	# ça il coupait les virages.
	while reste > 0.0 and _cible < _chemin.size():
		var vers: Vector2 = _chemin[_cible]
		var ecart := vers - position
		var distance := ecart.length()
		if distance <= reste:
			position = vers
			reste -= distance
			_cible += 1
		else:
			position += ecart / distance * reste
			reste = 0.0

	# Le ralentissement s'épuise APRÈS le déplacement, jamais avant : sinon la
	# dernière image d'un ralentissement se joue déjà à pleine vitesse, et une
	# durée de 0,5 s en vaut 0,45. Invisible à l'œil, mais c'est exactement le
	# genre d'écart qui rend une capacité « bizarre » sans qu'on sache dire pourquoi.
	if _reste_ralenti > 0.0:
		_reste_ralenti = maxf(0.0, _reste_ralenti - delta)
		if _reste_ralenti == 0.0:
			_facteur = 1.0
			queue_redraw()

	if _cible >= _chemin.size():
		_vivant = false
		arrive_au_bout.emit(self)
		queue_free()


## Un ralentissement, qu'il vienne d'un boulet ou des racines.
##
## On garde toujours le PLUS FORT : deux canons qui tirent ensemble ne doivent
## pas annuler l'effet du premier, et les racines (facteur nul) ne doivent pas
## être levées par un coup de canon arrivé dans la seconde.
func ralentir(facteur: float, duree: float) -> void:
	if not _vivant:
		return
	if facteur <= _facteur or _reste_ralenti <= 0.0:
		_facteur = facteur
		_reste_ralenti = maxf(_reste_ralenti, duree)
	queue_redraw()


func est_ralenti() -> bool:
	return _reste_ralenti > 0.0


## Encaisser un coup, armure déduite.
##
## Aucun plancher : un coup plus faible que l'armure ne fait RIEN. C'est un
## choix, et c'est le cœur du niveau 4. Un plancher à un point paraissait plus
## aimable, mais il transformait la leçon en arithmétique : mille piqûres
## finissaient par abattre l'arbre, et le canon devenait un raccourci au lieu
## d'être la réponse. Ici, une flèche qui rebondit rebondit.
##
## Ce qui coûterait cher, c'est de ne pas le MONTRER : un tir qui touche sans
## rien faire se lit comme une panne. D'où le rebond visible ci-dessous, et
## l'anneau clair autour des blindés.
func encaisser(degats: float) -> void:
	if not _vivant:
		return
	var reel := maxf(0.0, degats - armure)
	if reel <= 0.0:
		_rebond = 0.18
		queue_redraw()
		return
	vie -= reel
	queue_redraw()
	if vie <= 0.0:
		_vivant = false
		mort.emit(self)
		queue_free()


func est_vivant() -> bool:
	return _vivant


func _draw() -> void:
	# Un disque et une barre de vie : de quoi juger l'équilibrage avant même
	# qu'un seul dessin définitif n'existe.
	draw_circle(Vector2.ZERO, rayon, couleur)
	draw_arc(Vector2.ZERO, rayon, 0.0, TAU, 20, Color(0, 0, 0, 0.35), 2.0)

	# L'armure se voit : un anneau clair, sinon le joueur croit que ses tours
	# ratent leurs tirs au lieu de comprendre qu'elles tapent trop faible.
	if armure > 0.0:
		draw_arc(Vector2.ZERO, rayon + 4.0, 0.0, TAU, 24, Color("#d9c38a"), 2.0)
	if _rebond > 0.0:
		# « Clang ». Le joueur doit voir que son tir a touché et n'a rien fait,
		# sinon il croit que sa tour rate, et il en construit une deuxième du
		# même type — exactement la conclusion qu'on ne veut pas qu'il tire.
		draw_arc(Vector2.ZERO, rayon + 4.0, 0.0, TAU, 24,
				Color(1.0, 0.95, 0.75, clampf(_rebond / 0.18, 0.0, 1.0)), 4.0)
	if _reste_ralenti > 0.0:
		draw_arc(Vector2.ZERO, rayon + 7.0, 0.0, TAU, 24, Color("#8fd8ff"), 2.0)

	var largeur := rayon * 2.0
	var haut := Vector2(-rayon, -rayon - 8.0)
	draw_rect(Rect2(haut, Vector2(largeur, 3.0)), Color(0, 0, 0, 0.5))
	var part: float = clampf(vie / vie_max, 0.0, 1.0)
	draw_rect(Rect2(haut, Vector2(largeur * part, 3.0)), Color("#ff5b5b"))
