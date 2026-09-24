class_name Projectile
extends Node2D

## Un tir qui poursuit sa cible.
##
## Il vise l'ennemi, pas un point : une flèche qui tombe là où l'ennemi ÉTAIT
## se lit comme un bug, même quand les chiffres sont justes. Si la cible meurt
## en vol, le tir disparaît — il ne doit pas frapper un mort ni chercher
## quelqu'un d'autre, sinon les dégâts ne correspondent plus à ce qu'on voit.

var vitesse: float = 420.0
var degats: float = 8.0
var couleur: Color = Color("#e8f4a0")

var _cible: Ennemi


func lancer(depart: Vector2, cible: Ennemi, reglages: Dictionary, degats_tour: float) -> void:
	position = depart
	_cible = cible
	degats = degats_tour
	vitesse = float(reglages.get("vitesse", 420))
	couleur = Color(str(reglages.get("couleur", "#e8f4a0")))


func _process(delta: float) -> void:
	if not is_instance_valid(_cible) or not _cible.est_vivant():
		queue_free()
		return

	var ecart := _cible.position - position
	var distance := ecart.length()
	var pas := vitesse * delta

	if distance <= pas:
		_cible.encaisser(degats)
		queue_free()
		return

	position += ecart / distance * pas
	rotation = ecart.angle()
	queue_redraw()


func _draw() -> void:
	# Un trait, pas un point : l'orientation dit d'où vient le tir.
	draw_line(Vector2(-7, 0), Vector2(7, 0), couleur, 3.0)
	draw_circle(Vector2(7, 0), 2.5, couleur)
