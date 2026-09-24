extends Node2D

## Le niveau : il lit les données, il fait vivre la boucle.
##
## Rien de ce qui se règle n'est écrit ici. Le chemin, les emplacements, les
## vagues viennent de `donnees/niveau-01.json` ; les dégâts et les prix de
## `donnees/equilibrage.json`. On équilibre le jeu en éditant du JSON, jamais
## en touchant au code — c'est ce qui permet d'essayer dix réglages dans une
## soirée.

const CHEMIN_NIVEAU := "res://donnees/niveau-01.json"
const CHEMIN_EQUILIBRAGE := "res://donnees/equilibrage.json"

## De quoi attraper un emplacement au pouce : la cible tactile est plus large
## que le dessin, sinon on rate une construction sur deux.
const RAYON_TOUCHE := 34.0

var niveau: Dictionary = {}
var equilibrage: Dictionary = {}

var chemin: PackedVector2Array
var emplacements: Array[Dictionary] = []
var ennemis: Array[Ennemi] = []

var vies: int = 20
var vies_depart: int = 20
var argent: int = 120
var vague: int = 0

var _fini := false
var _spawn_en_cours := false
var _longueur_chemin: float = 0.0

@onready var ath: CanvasLayer = $ATH


func _ready() -> void:
	niveau = _lire_json(CHEMIN_NIVEAU)
	equilibrage = _lire_json(CHEMIN_EQUILIBRAGE)

	for point: Array in niveau["chemin"]:
		chemin.append(Vector2(float(point[0]), float(point[1])))
	_longueur_chemin = _longueur(chemin)

	for coord: Array in niveau["emplacements"]:
		var e := {
			"position": Vector2(float(coord[0]), float(coord[1])),
			"tour": null,
		}
		emplacements.append(e)

	vies_depart = int(niveau["vies"])
	vies = vies_depart
	argent = int(niveau["or_depart"])

	ath.rafraichir(self)
	_lancer_vagues()

	# Un mode d'essai, pour vérifier la boucle sans éditeur ni écran :
	# `godot --headless -- --test`.
	if "--test" in OS.get_cmdline_user_args():
		_jouer_tout_seul()


func _lire_json(chemin_fichier: String) -> Dictionary:
	var brut := FileAccess.get_file_as_string(chemin_fichier)
	var lu: Variant = JSON.parse_string(brut)
	assert(typeof(lu) == TYPE_DICTIONARY, "Données illisibles : %s" % chemin_fichier)
	return lu


func _longueur(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total


# --- Les vagues ------------------------------------------------------------

func _lancer_vagues() -> void:
	_spawn_en_cours = true
	var vagues: Array = niveau["vagues"]
	for i in range(vagues.size()):
		var v: Dictionary = vagues[i]
		await get_tree().create_timer(float(v.get("pause", 5.0))).timeout
		if _fini:
			return
		vague = i + 1
		ath.rafraichir(self)
		for groupe: Dictionary in v["groupes"]:
			for n in range(int(groupe["nombre"])):
				if _fini:
					return
				_faire_naitre(str(groupe["type"]))
				await get_tree().create_timer(float(groupe["intervalle"])).timeout
	_spawn_en_cours = false
	_verifier_victoire()


func _faire_naitre(type: String) -> void:
	var reglages: Dictionary = equilibrage["ennemis"][type]
	var e := Ennemi.new()
	add_child(e)
	e.demarrer(chemin, reglages)
	e.mort.connect(_sur_mort)
	e.arrive_au_bout.connect(_sur_sortie)
	ennemis.append(e)


func _sur_mort(e: Ennemi) -> void:
	argent += e.prime
	ennemis.erase(e)
	ath.rafraichir(self)
	_verifier_victoire()


func _sur_sortie(e: Ennemi) -> void:
	vies -= e.degats_sortie
	ennemis.erase(e)
	ath.rafraichir(self)
	if vies <= 0:
		_terminer(false)
	else:
		_verifier_victoire()


func _verifier_victoire() -> void:
	if _fini or _spawn_en_cours:
		return
	if ennemis.is_empty():
		_terminer(true)


func _terminer(gagne: bool) -> void:
	if _fini:
		return
	_fini = true
	var bilan := {}
	if gagne:
		bilan = Partie.terminer_niveau(str(niveau["id"]), vies, vies_depart, argent)
	ath.montrer_fin(gagne, bilan)

	if "--test" in OS.get_cmdline_user_args():
		print("--- Fin de partie ---")
		print("  issue     : %s" % ("victoire" if gagne else "défaite"))
		print("  vies      : %d / %d" % [vies, vies_depart])
		print("  or restant: %d" % argent)
		print("  vague     : %d / %d" % [vague, (niveau["vagues"] as Array).size()])
		if gagne:
			print("  étoiles   : %d" % int(bilan.get("etoiles", 0)))
			print("  essences  : +%d (total %d)" % [int(bilan.get("essences_gagnees", 0)), Partie.essences])
		await get_tree().create_timer(0.1).timeout
		get_tree().quit(0 if gagne else 1)


# --- Les tours -------------------------------------------------------------

func _process(_delta: float) -> void:
	# La progression sert à viser : la tour tire sur celui qui est le plus
	# près de la sortie, pas sur le plus proche d'elle.
	for e: Ennemi in ennemis:
		if is_instance_valid(e):
			e.set_meta("progression", _longueur_chemin - e.position.distance_to(chemin[chemin.size() - 1]))

	for emp: Dictionary in emplacements:
		var t: Tour = emp["tour"]
		if t != null:
			t.viser(ennemis)


func _unhandled_input(evenement: InputEvent) -> void:
	if _fini:
		return
	var point := Vector2.ZERO
	if evenement is InputEventScreenTouch and evenement.pressed:
		point = evenement.position
	elif evenement is InputEventMouseButton and evenement.pressed and evenement.button_index == MOUSE_BUTTON_LEFT:
		point = evenement.position
	else:
		return
	_toucher(get_canvas_transform().affine_inverse() * point)


func _toucher(point: Vector2) -> void:
	for emp: Dictionary in emplacements:
		if point.distance_to(emp["position"]) > RAYON_TOUCHE:
			continue
		if emp["tour"] == null:
			_construire(emp, "archers")
		else:
			_ameliorer(emp)
		return
	# Un toucher dans le vide referme les cercles de portée : sinon l'écran
	# se couvre de halos au bout de trois tours.
	for emp: Dictionary in emplacements:
		if emp["tour"] != null:
			emp["tour"].montrer_portee(false)


func _construire(emp: Dictionary, famille: String) -> bool:
	var reglages: Dictionary = equilibrage["tours"][famille]
	var cout := int(reglages["cout"])
	if argent < cout:
		ath.dire("Pas assez d'or — il en faut %d" % cout)
		return false
	argent -= cout

	var t := Tour.new()
	add_child(t)
	t.position = emp["position"]
	t.construire(famille, reglages)
	t.veut_tirer.connect(_sur_tir)
	t.montrer_portee(true)
	emp["tour"] = t
	ath.rafraichir(self)
	return true


func _ameliorer(emp: Dictionary) -> bool:
	var t: Tour = emp["tour"]
	t.montrer_portee(true)
	var cout := t.cout_amelioration()
	if cout < 0:
		ath.dire("Tour au maximum")
		return false
	if argent < cout:
		ath.dire("Améliorer coûte %d" % cout)
		return false
	argent -= cout
	t.ameliorer()
	ath.rafraichir(self)
	return true


func _sur_tir(tour: Tour, cible: Ennemi) -> void:
	var p := Projectile.new()
	add_child(p)
	p.lancer(tour.position, cible, tour.reglages.get("projectile", {}), tour.degats)


# --- Le décor de prototype -------------------------------------------------

func _draw() -> void:
	# Des formes, pas des images. Quand les dessins arriveront, ce `_draw`
	# disparaîtra au profit de Sprite2D — la logique, elle, ne bougera pas.
	draw_rect(Rect2(Vector2(-200, -200), Vector2(800, 1300)), Color("#1b2a1f"))
	draw_polyline(chemin, Color("#6b5433"), 34.0)
	draw_polyline(chemin, Color("#8a6d44"), 28.0)

	for emp: Dictionary in emplacements:
		if emp["tour"] == null:
			draw_arc(emp["position"], 19.0, 0.0, TAU, 28, Color("#9ab0a0"), 3.0)
			draw_circle(emp["position"], 16.0, Color(0.6, 0.75, 0.65, 0.18))


# --- Le mode d'essai -------------------------------------------------------

## Joue une partie sans personne devant l'écran.
##
## Il ne s'agit pas de gagner joliment, mais de prouver que la boucle tourne :
## les vagues arrivent, les tours tirent, l'or rentre, la partie se termine.
func _jouer_tout_seul() -> void:
	Engine.time_scale = 12.0
	# `--test-passif` : on ne construit rien. La partie DOIT se perdre — un
	# niveau qu'on gagne sans rien faire n'est pas un niveau.
	if "--test-passif" in OS.get_cmdline_user_args():
		while not _fini:
			await get_tree().create_timer(0.25).timeout
		return
	while not _fini:
		await get_tree().create_timer(0.25).timeout
		for emp: Dictionary in emplacements:
			if emp["tour"] == null:
				_construire(emp, "archers")
			else:
				_ameliorer(emp)
