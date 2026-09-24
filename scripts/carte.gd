extends Control

## La carte de campagne, qui sert aussi de menu.
##
## Un menu principal séparé — « Jouer », « Options », « Quitter » — serait un
## écran de plus à traverser avant de jouer. La carte fait les deux : elle
## montre où l'on en est, et lancer un niveau est le premier geste possible.
##
## Elle est dessinée en formes et en texte. Les vignettes illustrées viendront
## plus tard remplacer les cartons de couleur, sans rien changer ici.

const NIVEAUX := [
	{ "id": "niveau-01", "nom": "Le sentier des racines", "sous_titre": "Poser une tour, la vendre" },
	{ "id": "niveau-02", "nom": "La clairière basse", "sous_titre": "Le loup — la cadence compte" },
	{ "id": "niveau-03", "nom": "Les pierres dressées", "sous_titre": "La tour de cristal" },
	{ "id": "niveau-04", "nom": "Le val d'écorce", "sous_titre": "L'arbre blindé, et le canon" },
	{ "id": "niveau-05", "nom": "La source corrompue", "sous_titre": "Les racines — le terrain est une arme" },
]

var _essences: Label


func _ready() -> void:
	var fond := ColorRect.new()
	fond.color = Color("#111c16")
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	var titre := _texte("LES GARDIENS DES SOURCES", 24, Color("#5fd39a"))
	titre.position = Vector2(24, 18)
	add_child(titre)

	var region := _texte("Région 1 — la forêt des Anciens", 14, Color("#8fa89a"))
	region.position = Vector2(26, 50)
	add_child(region)

	_essences = _texte("", 16, Color("#5fd3c8"))
	_essences.position = Vector2(660, 24)
	_essences.size = Vector2(160, 24)
	_essences.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_essences)

	var rangee := HBoxContainer.new()
	rangee.add_theme_constant_override("separation", 12)
	rangee.position = Vector2(24, 92)
	add_child(rangee)

	# Un niveau n'est jouable que si le précédent est terminé : la difficulté
	# monte d'un cran à la fois, et l'on ne tombe pas sur l'arbre blindé avant
	# d'avoir rencontré le loup.
	var precedent_fini := true
	for n: Dictionary in NIVEAUX:
		var fait: Dictionary = Partie.niveaux.get(n["id"], {})
		var etoiles := int(fait.get("etoiles", 0))
		rangee.add_child(_carton(n, etoiles, precedent_fini))
		precedent_fini = etoiles > 0

	var pied := HBoxContainer.new()
	pied.add_theme_constant_override("separation", 10)
	pied.position = Vector2(24, 300)
	add_child(pied)

	var b := Button.new()
	b.custom_minimum_size = Vector2(180, 34)
	b.add_theme_font_size_override("font_size", 13)
	if Partie.sanctuaire_ouvert():
		b.text = "Le sanctuaire  ✦ %d" % Partie.essences
		b.pressed.connect(func() -> void:
				get_tree().change_scene_to_file("res://scenes/sanctuaire.tscn"))
	else:
		# On ne grise pas un bouton sans dire pourquoi : le joueur croirait à
		# une panne. On annonce la condition, et elle devient un objectif.
		b.text = "Sanctuaire — au niveau 2"
		b.disabled = true
	pied.add_child(b)

	_rafraichir_essences()

	# En mode d'essai, on ne s'arrête pas sur la carte : le test joue un niveau.
	# `--niveau=niveau-04` choisit lequel ; sans précision, le premier.
	if "--test" in OS.get_cmdline_user_args():
		_lancer(_niveau_demande())


## Le niveau réclamé en ligne de commande, pour les essais sans écran.
func _niveau_demande() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--niveau="):
			return arg.substr("--niveau=".length())
	return "niveau-01"


func _texte(contenu: String, taille: int, couleur: Color) -> Label:
	var l := Label.new()
	l.text = contenu
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	return l


func _carton(niveau: Dictionary, etoiles: int, ouvert: bool) -> Control:
	var carte := PanelContainer.new()
	carte.custom_minimum_size = Vector2(150, 190)

	var st := StyleBoxFlat.new()
	st.bg_color = Color("#1b2a21") if ouvert else Color("#151d18")
	st.border_color = Color("#3f7a5e") if ouvert else Color("#2a332d")
	st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	st.set_content_margin_all(12)
	carte.add_theme_stylebox_override("panel", st)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 7)
	carte.add_child(colonne)

	var nom := _texte(str(niveau["nom"]), 15, Color.WHITE if ouvert else Color("#5c6b61"))
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nom.custom_minimum_size = Vector2(126, 42)
	colonne.add_child(nom)

	var sous := _texte(str(niveau["sous_titre"]), 11, Color("#8fa89a") if ouvert else Color("#4a554e"))
	sous.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sous.custom_minimum_size = Vector2(126, 46)
	colonne.add_child(sous)

	var note := _texte("★".repeat(etoiles) + "☆".repeat(3 - etoiles), 15,
			Color("#ffd166") if etoiles > 0 else Color("#3f4a43"))
	colonne.add_child(note)

	var bouton := Button.new()
	bouton.custom_minimum_size = Vector2(126, 32)
	bouton.add_theme_font_size_override("font_size", 13)
	if not ouvert:
		bouton.text = "Verrouillé"
		bouton.disabled = true
	else:
		bouton.text = "Rejouer" if etoiles > 0 else "Jouer"
		bouton.pressed.connect(func() -> void: _lancer(str(niveau["id"])))
	colonne.add_child(bouton)

	return carte


func _lancer(id: String) -> void:
	# Mieux vaut le dire que d'ouvrir un écran vide : un niveau annoncé sur la
	# carte et absent des données se lit comme une panne.
	if not FileAccess.file_exists("res://donnees/%s.json" % id):
		_essences.text = "Ce niveau n'existe pas encore"
		return
	Partie.niveau_choisi = id
	get_tree().change_scene_to_file("res://scenes/jeu.tscn")


func _rafraichir_essences() -> void:
	_essences.text = "✦ %d essence%s" % [Partie.essences, "s" if Partie.essences > 1 else ""]
