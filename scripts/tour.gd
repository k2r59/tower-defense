class_name Tour
extends Node2D

## Une tour : elle choisit une cible, elle tire, elle s'améliore.
##
## La cible retenue est celle qui est LE PLUS AVANCÉE sur le chemin, pas la
## plus proche. C'est la règle de presque tous les tower defense, et pour une
## bonne raison : viser le plus proche laisse filer celui qui allait sortir.

signal veut_tirer(tour: Tour, cible: Ennemi)

const RAYON_SOCLE := 17.0

var famille: String = "archers"
var niveau: int = 0
var reglages: Dictionary = {}

var degats: float = 8.0
var portee: float = 115.0
var cadence: float = 0.8
var couleur: Color = Color("#5fd39a")

## Tout ce qu'on a mis dedans, achat et ameliorations comprises : c'est sur
## cette somme que se calcule la reprise.
var investi: int = 0

var _repos: float = 0.0
var _angle_canon: float = -PI / 2.0
var _montre_portee := false


func construire(famille_choisie: String, reglages_tour: Dictionary) -> void:
	famille = famille_choisie
	reglages = reglages_tour
	couleur = Color(str(reglages.get("couleur", "#5fd39a")))
	investi = int(reglages.get("cout", 0))
	_appliquer_niveau(0)


func ameliorer() -> bool:
	var paliers: Array = reglages.get("niveaux", [])
	if niveau + 1 >= paliers.size():
		return false
	investi += maxi(0, cout_amelioration())
	_appliquer_niveau(niveau + 1)
	return true


## Ce que rend une reprise.
##
## Soixante pour cent, pas la totalite : une tour qu'on revend sans perte
## supprimerait toute consequence au placement, et le jeu n'aurait plus a etre
## joue, seulement corrige. Mais pas dix pour cent non plus : personne
## n'oserait essayer quoi que ce soit.
const PART_REPRISE := 0.6

func valeur_reprise() -> int:
	return int(floor(investi * PART_REPRISE))


## Ce que coûte le palier suivant, ou -1 s'il n'y en a plus.
func cout_amelioration() -> int:
	var paliers: Array = reglages.get("niveaux", [])
	if niveau >= paliers.size():
		return -1
	var c: Variant = paliers[niveau].get("cout_amelioration")
	return -1 if c == null else int(c)


func _appliquer_niveau(n: int) -> void:
	niveau = n
	var palier: Dictionary = reglages["niveaux"][n]
	degats = float(palier["degats"])
	portee = float(palier["portee"])
	cadence = float(palier["cadence"])
	queue_redraw()


func viser(ennemis: Array) -> void:
	if _repos > 0.0:
		return
	var cible := _meilleure_cible(ennemis)
	if cible == null:
		return
	_angle_canon = (cible.position - position).angle()
	_repos = cadence
	veut_tirer.emit(self, cible)
	queue_redraw()


func _meilleure_cible(ennemis: Array) -> Ennemi:
	var meilleure: Ennemi = null
	var avancee := -1.0
	for e: Ennemi in ennemis:
		if not is_instance_valid(e) or not e.est_vivant():
			continue
		if position.distance_to(e.position) > portee:
			continue
		# `progression` croît le long du chemin : le plus grand est le plus
		# près de la sortie.
		var p := float(e.get_meta("progression", 0.0))
		if p > avancee:
			avancee = p
			meilleure = e
	return meilleure


func _process(delta: float) -> void:
	if _repos > 0.0:
		_repos = maxf(0.0, _repos - delta)


func montrer_portee(oui: bool) -> void:
	_montre_portee = oui
	queue_redraw()


func _draw() -> void:
	if _montre_portee:
		draw_circle(Vector2.ZERO, portee, Color(couleur.r, couleur.g, couleur.b, 0.10))
		draw_arc(Vector2.ZERO, portee, 0.0, TAU, 48, Color(couleur.r, couleur.g, couleur.b, 0.45), 1.5)

	# Le socle, puis le canon : deux pièces distinctes dès le prototype, parce
	# que les vrais dessins arriveront eux aussi en deux morceaux.
	draw_circle(Vector2.ZERO, RAYON_SOCLE, couleur.darkened(0.45))
	draw_circle(Vector2.ZERO, RAYON_SOCLE - 4.0, couleur)
	draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(_angle_canon) * (RAYON_SOCLE + 8.0), couleur.lightened(0.5), 5.0)

	# Un point par niveau : on lit l'amélioration d'un coup d'œil.
	for i in range(niveau + 1):
		draw_circle(Vector2(-8.0 + i * 8.0, RAYON_SOCLE + 9.0), 2.5, Color("#ffd166"))
