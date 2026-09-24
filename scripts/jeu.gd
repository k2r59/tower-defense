extends Node2D

## Le niveau : il lit les données, il fait vivre la boucle.
##
## Rien de ce qui se règle n'est écrit ici. Le chemin, les emplacements, les
## vagues et les tours autorisées viennent de `donnees/niveau-0N.json` ; les
## dégâts et les prix de `donnees/equilibrage.json`. On équilibre le jeu en
## éditant du JSON, jamais en touchant au code — c'est ce qui permet d'essayer
## dix réglages dans une soirée.

const CHEMIN_EQUILIBRAGE := "res://donnees/equilibrage.json"

## De quoi attraper un emplacement au pouce : la cible tactile est plus large
## que le dessin, sinon on rate une construction sur deux.
const RAYON_TOUCHE := 34.0

var niveau: Dictionary = {}
var equilibrage: Dictionary = {}

var chemin: PackedVector2Array
var emplacements: Array[Dictionary] = []
var ennemis: Array[Ennemi] = []

## Les familles de tours que CE niveau autorise. Le niveau 1 n'en propose
## qu'une : on n'apprend pas à choisir avant d'avoir appris à poser.
var tours_offertes: Array[String] = ["archers"]

var vies: int = 20
var vies_depart: int = 20
var argent: int = 120
var vague: int = 0

## Les racines du niveau 5 : le terrain devient une arme, quelques fois.
var racines_restantes: int = 0
var racines_duree: float = 0.0

var _fini := false
var _spawn_en_cours := false
var _longueur_chemin: float = 0.0

## La tour dont le panneau est ouvert. Toucher une tour la SÉLECTIONNE au lieu
## de l'améliorer aussitôt : on doit pouvoir regarder ce qu'elle coûte, et
## pouvoir la vendre, avant de décider.
var _selection: Tour = null

## L'emplacement vide qu'on vient de toucher, quand plusieurs tours sont
## possibles et qu'il faut d'abord demander laquelle.
var _en_attente: Dictionary = {}

@onready var ath: CanvasLayer = $ATH


func _ready() -> void:
	niveau = _lire_json("res://donnees/%s.json" % Partie.niveau_choisi)
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

	tours_offertes.clear()
	for f: String in niveau.get("tours", ["archers"]):
		tours_offertes.append(f)

	var racines: Dictionary = niveau.get("racines", {})
	racines_restantes = int(racines.get("charges", 0))
	racines_duree = float(racines.get("duree", 3.5))

	vies_depart = int(niveau["vies"])
	vies = vies_depart
	argent = int(niveau["or_depart"]) + int(Partie.bonus("or_depart"))

	ath.demande_amelioration.connect(_sur_amelioration)
	ath.demande_reprise.connect(_sur_reprise)
	ath.demande_construction.connect(_sur_construction)
	ath.demande_racines.connect(_sur_racines)
	ath.demande_rejouer.connect(func() -> void: get_tree().reload_current_scene())
	ath.demande_carte.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/carte.tscn"))

	ath.preparer(self)
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
		if "--test" in OS.get_cmdline_user_args():
			# Une trace par vague : savoir QUE le niveau se perd ne sert à rien,
			# il faut savoir à partir de quand il se perd.
			print("  vague %d — vies %d, or %d, tours %d" % [vague, vies, argent, _tours_posees()])
		for groupe: Dictionary in v["groupes"]:
			for n in range(int(groupe["nombre"])):
				if _fini:
					return
				_faire_naitre(str(groupe["type"]))
				await get_tree().create_timer(float(groupe["intervalle"])).timeout
	_spawn_en_cours = false
	_verifier_victoire()


func _tours_posees() -> int:
	var n := 0
	for emp: Dictionary in emplacements:
		if emp["tour"] != null:
			n += 1
	return n


## Ce que chaque espèce a donné : nés, abattus, passés. Sans ce décompte, un
## niveau perdu ne dit que « c'est trop dur » ; avec lui, il dit LEQUEL passe,
## et c'est la seule information qui permette de régler quoi que ce soit.
var _comptes: Dictionary = {}


func _compter(type: String, quoi: String) -> void:
	if not _comptes.has(type):
		_comptes[type] = { "nes": 0, "tues": 0, "passes": 0 }
	_comptes[type][quoi] += 1


func _faire_naitre(type: String) -> void:
	var reglages: Dictionary = equilibrage["ennemis"][type]
	var e := Ennemi.new()
	add_child(e)
	e.set_meta("espece", type)
	_compter(type, "nes")
	e.demarrer(chemin, reglages)
	e.mort.connect(_sur_mort)
	e.arrive_au_bout.connect(_sur_sortie)
	ennemis.append(e)


func _sur_mort(e: Ennemi) -> void:
	_compter(str(e.get_meta("espece", "?")), "tues")
	argent += int(round(e.prime * (1.0 + Partie.bonus("prime_pct"))))
	ennemis.erase(e)
	ath.rafraichir(self)
	_verifier_victoire()


func _sur_sortie(e: Ennemi) -> void:
	_compter(str(e.get_meta("espece", "?")), "passes")
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
	_selectionner(null)
	ath.figer_commandes()
	var bilan := {}
	if gagne:
		bilan = Partie.terminer_niveau(str(niveau["id"]), vies, vies_depart, argent)
	ath.montrer_fin(gagne, bilan)

	if "--test" in OS.get_cmdline_user_args():
		print("--- Fin de partie ---")
		print("  niveau    : %s" % str(niveau["id"]))
		print("  issue     : %s" % ("victoire" if gagne else "défaite"))
		print("  vies      : %d / %d" % [vies, vies_depart])
		print("  or restant: %d" % argent)
		print("  vague     : %d / %d" % [vague, (niveau["vagues"] as Array).size()])
		if int((niveau.get("racines", {}) as Dictionary).get("charges", 0)) > 0:
			print("  racines   : %d restante(s) sur %d" % [
				racines_restantes, int((niveau["racines"] as Dictionary)["charges"])])
		for espece: String in _comptes:
			var c: Dictionary = _comptes[espece]
			print("  %-9s : %d nés, %d abattus, %d passés" % [espece, c["nes"], c["tues"], c["passes"]])
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
			_demander_construction(emp)
		else:
			_selectionner(emp["tour"])
		return
	# Un toucher dans le vide referme la sélection : sinon l'écran se couvre
	# de halos de portée au bout de trois tours.
	_selectionner(null)


## Toucher un emplacement vide.
##
## Une seule famille disponible : on construit tout de suite. C'est le niveau 1,
## et un menu d'un seul choix n'est pas un choix, c'est un obstacle. Dès qu'il y
## en a deux, on demande — et le menu affiche les prix, parce que le joueur
## compare des coûts, pas des noms.
func _demander_construction(emp: Dictionary) -> void:
	_selectionner(null)
	if tours_offertes.size() <= 1:
		_construire(emp, tours_offertes[0] if not tours_offertes.is_empty() else "archers")
		return
	_en_attente = emp
	ath.montrer_construction(tours_offertes, equilibrage, argent, emp["position"])


func _sur_construction(famille: String) -> void:
	if _en_attente.is_empty():
		return
	var emp := _en_attente
	_en_attente = {}
	ath.cacher_construction()
	_construire(emp, famille)


func _selectionner(tour: Tour) -> void:
	if not _en_attente.is_empty():
		_en_attente = {}
		ath.cacher_construction()
	if _selection != null and is_instance_valid(_selection):
		_selection.montrer_portee(false)
	_selection = tour
	if tour != null:
		tour.montrer_portee(true)
	ath.montrer_tour(tour, argent)


func _emplacement_de(tour: Tour) -> Dictionary:
	for emp: Dictionary in emplacements:
		if emp["tour"] == tour:
			return emp
	return {}


func _sur_amelioration() -> void:
	if _selection == null or not is_instance_valid(_selection):
		return
	_ameliorer(_emplacement_de(_selection))
	ath.montrer_tour(_selection, argent)


## Vendre.
##
## C'est la seconde leçon du premier niveau, avec « poser » : un joueur doit
## pouvoir se tromper de place sans perdre sa partie. La reprise ne rend pas
## tout — sinon le placement n'aurait plus de conséquence.
func _sur_reprise() -> void:
	if _selection == null or not is_instance_valid(_selection):
		return
	var emp := _emplacement_de(_selection)
	if emp.is_empty():
		return
	argent += _selection.valeur_reprise()
	var t := _selection
	_selectionner(null)
	emp["tour"] = null
	t.queue_free()
	ath.rafraichir(self)
	queue_redraw()


func _construire(emp: Dictionary, famille: String) -> bool:
	if not equilibrage["tours"].has(famille):
		return false
	var reglages: Dictionary = equilibrage["tours"][famille]
	var cout := int(reglages["cout"])
	if argent < cout:
		ath.dire("Pas assez d'or — %s coûte %d" % [str(reglages.get("nom", famille)), cout])
		return false
	argent -= cout

	var t := Tour.new()
	add_child(t)
	t.position = emp["position"]
	t.construire(famille, reglages)
	t.veut_tirer.connect(_sur_tir)
	t.montrer_portee(true)
	emp["tour"] = t
	_selectionner(t)
	ath.rafraichir(self)
	queue_redraw()
	return true


func _ameliorer(emp: Dictionary) -> bool:
	if emp.is_empty():
		return false
	var t: Tour = emp["tour"]
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


# --- Les dégâts, en un seul endroit ---------------------------------------

func _sur_tir(tour: Tour, cible: Ennemi) -> void:
	var p := Projectile.new()
	add_child(p)
	p.impact.connect(_sur_impact)
	p.lancer(tour.position, cible, tour.reglages.get("projectile", {}), tour.coup())


## Un tir arrive. C'est ici, et nulle part ailleurs, que la vie baisse.
##
## Zone ou non, armure ou non, ralentissement ou non : tout passe par cette
## fonction. Deux endroits qui infligent des dégâts finissent toujours par ne
## plus dire la même chose, et l'écart ne se voit qu'après des heures de jeu.
func _sur_impact(centre: Vector2, coup: Dictionary, cible: Ennemi) -> void:
	var degats := float(coup.get("degats", 0.0))
	var zone := float(coup.get("rayon_zone", 0.0))
	var ralenti: Dictionary = coup.get("ralentissement", {})

	var touches: Array[Ennemi] = []
	if zone > 0.0:
		for e: Ennemi in ennemis:
			if is_instance_valid(e) and e.est_vivant() and centre.distance_to(e.position) <= zone + e.rayon:
				touches.append(e)
	elif is_instance_valid(cible) and cible.est_vivant():
		touches.append(cible)

	for e: Ennemi in touches:
		if not ralenti.is_empty():
			e.ralentir(float(ralenti.get("facteur", 1.0)), float(ralenti.get("duree", 0.0)))
		# En dernier : encaisser peut le faire mourir et le sortir de la liste.
		e.encaisser(degats)

	if zone > 0.0:
		_eclats.append({ "centre": centre, "rayon": zone, "reste": 0.18 })


# --- Les racines -----------------------------------------------------------

## Le terrain comme arme, deux fois par niveau.
##
## Ce n'est pas une tour de plus : ça ne s'achète pas, ça ne se place pas, et
## ça ne tue personne. Ça donne du TEMPS, et c'est au joueur de décider quel
## moment mérite d'être payé avec une des deux charges. C'est la leçon du
## niveau 5 : la meilleure défense n'est pas toujours une tour.
func _sur_racines() -> void:
	if _fini or racines_restantes <= 0:
		return
	racines_restantes -= 1
	var pris := 0
	for e: Ennemi in ennemis:
		if is_instance_valid(e) and e.est_vivant():
			e.ralentir(0.0, racines_duree)
			pris += 1
	ath.rafraichir(self)
	ath.dire("Les racines se referment — %d immobilisé%s" % [pris, "s" if pris > 1 else ""])


# --- Le décor de prototype -------------------------------------------------

## Les éclats de zone encore visibles. Sans eux, une tour de cristal a l'air de
## rater ses tirs : on voit trois ennemis mourir et rien qui les relie.
var _eclats: Array[Dictionary] = []


func _physics_process(delta: float) -> void:
	if _eclats.is_empty():
		return
	for eclat: Dictionary in _eclats:
		eclat["reste"] = float(eclat["reste"]) - delta
	_eclats = _eclats.filter(func(e: Dictionary) -> bool: return float(e["reste"]) > 0.0)
	queue_redraw()


func _draw() -> void:
	# Des formes, pas des images. Quand les dessins arriveront, ce `_draw`
	# disparaîtra au profit de Sprite2D — la logique, elle, ne bougera pas.
	draw_rect(Rect2(Vector2(-200, -200), Vector2(1300, 800)), Color("#1b2a1f"))
	draw_polyline(chemin, Color("#6b5433"), 34.0)
	draw_polyline(chemin, Color("#8a6d44"), 28.0)

	for emp: Dictionary in emplacements:
		if emp["tour"] == null:
			draw_arc(emp["position"], 19.0, 0.0, TAU, 28, Color("#9ab0a0"), 3.0)
			draw_circle(emp["position"], 16.0, Color(0.6, 0.75, 0.65, 0.18))

	for eclat: Dictionary in _eclats:
		var part: float = clampf(float(eclat["reste"]) / 0.18, 0.0, 1.0)
		draw_circle(eclat["centre"], float(eclat["rayon"]), Color(0.7, 0.83, 1.0, 0.22 * part))


# --- Le mode d'essai -------------------------------------------------------

## Joue une partie sans personne devant l'écran.
##
## Il ne s'agit pas de gagner joliment, mais de prouver que le niveau TIENT :
## qu'il se gagne en jouant la solution écrite dans ses données, et qu'il se
## perd si l'on ne fait rien. Les deux comptent autant — un niveau qu'on gagne
## les bras croisés n'est pas un niveau.
func _jouer_tout_seul() -> void:
	Engine.time_scale = 12.0

	# On pose une tour, on la revend, et l'on verifie ce qui revient. La
	# revente est la seconde lecon du premier niveau : si elle se casse, le
	# niveau n'enseigne plus ce qu'il annonce.
	var avant := argent
	_construire(emplacements[0], tours_offertes[0])
	var apres_achat := argent
	var rendu := _selection.valeur_reprise()
	_sur_reprise()
	print("Revente : %d or, achat a %d, rendu %d, solde %d (attendu %d)" % [
		avant, avant - apres_achat, rendu, argent, apres_achat + rendu])
	assert(argent == apres_achat + rendu, "La revente ne rend pas ce qu'elle annonce")
	assert(emplacements[0]["tour"] == null, "L'emplacement reste occupe apres une revente")

	# `--test-passif` : on ne construit rien. La partie DOIT se perdre.
	if "--test-passif" in OS.get_cmdline_user_args():
		while not _fini:
			await get_tree().create_timer(0.25).timeout
		return

	# La solution du niveau, ecrite dans ses donnees : une famille par
	# emplacement. Si elle ne suffit plus apres un reglage, c'est le reglage
	# qu'il faut revoir, et le test le dira avant le joueur.
	var solution: Array = niveau.get("solution", [])

	# `--famille=archers` remplace la solution par une seule famille partout.
	# C'est ce qui permet de VÉRIFIER une affirmation de conception plutôt que
	# de l'écrire dans un commentaire : au niveau 4, des archers seuls doivent
	# perdre, sinon l'armure ne sert à rien et le canon non plus.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--famille="):
			var seule := arg.substr("--famille=".length())
			solution = []
			for i in range(emplacements.size()):
				solution.append(seule)

	while not _fini:
		await get_tree().create_timer(0.25).timeout
		# Couvrir le terrain PASSE AVANT améliorer, mais on n'économise jamais :
		# ce qui reste après la passe de construction part en améliorations.
		# Attendre d'avoir posé les huit tours avant de toucher aux paliers
		# laissait le test assis sur son or pendant trois vagues — une stratégie
		# que personne ne joue, et qui faisait échouer un niveau réglable.
		for i in range(emplacements.size()):
			if emplacements[i]["tour"] == null:
				_construire(emplacements[i], str(solution[i]) if i < solution.size() else tours_offertes[0])
		for emp: Dictionary in emplacements:
			if emp["tour"] != null:
				_ameliorer(emp)
		_selectionner(null)
		# Les racines se depensent des que la vague est fournie : le test doit
		# passer par ce bouton, sinon il ne prouve rien sur le niveau 5.
		if racines_restantes > 0 and ennemis.size() >= 6:
			_sur_racines()
