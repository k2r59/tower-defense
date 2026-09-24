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

var _chemin: PackedVector2Array
var _cible: int = 1
var _vivant := true


func demarrer(chemin: PackedVector2Array, reglages: Dictionary) -> void:
	_chemin = chemin
	position = chemin[0]
	vie_max = float(reglages.get("vie", 40))
	vie = vie_max
	vitesse = float(reglages.get("vitesse", 46))
	prime = int(reglages.get("prime", 8))
	degats_sortie = int(reglages.get("degats_sortie", 1))
	rayon = float(reglages.get("rayon", 11))
	couleur = Color(str(reglages.get("couleur", "#7cc45a")))


func _process(delta: float) -> void:
	if not _vivant or _chemin.is_empty():
		return

	var reste := vitesse * delta
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

	if _cible >= _chemin.size():
		_vivant = false
		arrive_au_bout.emit(self)
		queue_free()


func encaisser(degats: float) -> void:
	if not _vivant:
		return
	vie -= degats
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

	var largeur := rayon * 2.0
	var haut := Vector2(-rayon, -rayon - 8.0)
	draw_rect(Rect2(haut, Vector2(largeur, 3.0)), Color(0, 0, 0, 0.5))
	var part: float = clampf(vie / vie_max, 0.0, 1.0)
	draw_rect(Rect2(haut, Vector2(largeur * part, 3.0)), Color("#ff5b5b"))
