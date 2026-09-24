class_name Projectile
extends Node2D

## Un tir qui poursuit sa cible.
##
## Il vise l'ennemi, pas un point : une flèche qui tombe là où l'ennemi ÉTAIT
## se lit comme un bug, même quand les chiffres sont justes. Si la cible meurt
## en vol, le tir disparaît — il ne doit pas frapper un mort ni chercher
## quelqu'un d'autre, sinon les dégâts ne correspondent plus à ce qu'on voit.
##
## Il n'inflige RIEN lui-même : il annonce un impact, et le niveau le résout.
## Une seule porte d'entrée pour les dégâts, c'est ce qui permet à la zone, à
## l'armure et au ralentissement de se combiner sans se contredire.

signal impact(centre: Vector2, coup: Dictionary, cible: Ennemi)

var vitesse: float = 420.0
var couleur: Color = Color("#e8f4a0")

## Ce que ce tir fera en arrivant : dégâts, rayon de zone, ralentissement.
var coup: Dictionary = {}

var _cible: Ennemi
var _rayon_zone: float = 0.0


func lancer(depart: Vector2, cible: Ennemi, reglages: Dictionary, coup_porte: Dictionary) -> void:
	position = depart
	_cible = cible
	coup = coup_porte
	_rayon_zone = float(coup_porte.get("rayon_zone", 0.0))
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
		position = _cible.position
		impact.emit(position, coup, _cible)
		queue_free()
		return

	position += ecart / distance * pas
	rotation = ecart.angle()
	queue_redraw()


func _draw() -> void:
	if _rayon_zone > 0.0:
		# Un éclat, pas un trait : on doit voir d'un coup d'œil que ce tir-là
		# frappe large, avant même qu'il n'arrive.
		draw_circle(Vector2.ZERO, 5.0, couleur)
		draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 12, Color(couleur.r, couleur.g, couleur.b, 0.5), 2.0)
		return
	# Un trait, pas un point : l'orientation dit d'où vient le tir.
	draw_line(Vector2(-7, 0), Vector2(7, 0), couleur, 3.0)
	draw_circle(Vector2(7, 0), 2.5, couleur)
