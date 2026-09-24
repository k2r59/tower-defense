extends CanvasLayer

## L'affichage tête haute : ce que le joueur lit, et ce qu'il commande.
##
## Tout est construit en code, volontairement. Une interface de jeu se règle au
## pixel et change dix fois ; la décrire dans une scène obligerait à rouvrir
## l'éditeur pour chaque essai. Et surtout : elle ne sera JAMAIS générée par
## une IA d'image — on veut la même bordure partout, et du vrai texte.

signal demande_amelioration
signal demande_reprise
signal demande_rejouer
signal demande_carte

const OR_CLAIR := Color("#ffd166")
const ROUGE := Color("#ff7b7b")
const BLEU := Color("#a9d8ff")
const VERT := Color("#7ee8a8")

var _vies: Label
var _or: Label
var _vague: Label
var _message: Label

var _pause: Button
var _vitesse: Button

var _panneau: PanelContainer
var _titre_tour: Label
var _ameliorer: Button
var _vendre: Button

var _fin: PanelContainer
var _texte_fin: Label
var _rejouer: Button
var _suivant: Button

var _accelere := false


func _ready() -> void:
	# Les commandes doivent répondre même jeu en pause, sinon on ne peut plus
	# le reprendre.
	process_mode = Node.PROCESS_MODE_ALWAYS

	var barre := HBoxContainer.new()
	barre.add_theme_constant_override("separation", 18)
	barre.position = Vector2(16, 12)
	add_child(barre)
	_vies = _etiquette("20", ROUGE)
	_or = _etiquette("120", OR_CLAIR)
	_vague = _etiquette("0/5", BLEU)
	barre.add_child(_vies)
	barre.add_child(_or)
	barre.add_child(_vague)

	var commandes := HBoxContainer.new()
	commandes.add_theme_constant_override("separation", 8)
	commandes.position = Vector2(700, 8)
	add_child(commandes)
	_pause = _bouton("❚❚", _basculer_pause)
	_vitesse = _bouton("▶▶", _basculer_vitesse)
	commandes.add_child(_pause)
	commandes.add_child(_vitesse)

	_message = _etiquette("", Color.WHITE)
	_message.position = Vector2(16, 352)
	_message.size = Vector2(812, 24)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_message)

	_construire_panneau_tour()
	_construire_panneau_fin()


# --- Les briques ----------------------------------------------------------

func _etiquette(texte: String, couleur: Color, taille := 17) -> Label:
	var l := Label.new()
	l.text = texte
	l.add_theme_color_override("font_color", couleur)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_font_size_override("font_size", taille)
	return l


func _bouton(texte: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = texte
	b.custom_minimum_size = Vector2(56, 34)
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(action)
	return b


func _cadre() -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#101a14dd")
	st.border_color = Color("#3f5a4c")
	st.set_border_width_all(2)
	st.set_corner_radius_all(10)
	st.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", st)
	return p


# --- Le panneau d'une tour ------------------------------------------------

func _construire_panneau_tour() -> void:
	_panneau = _cadre()
	_panneau.position = Vector2(566, 300)
	_panneau.visible = false
	add_child(_panneau)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 6)
	_panneau.add_child(colonne)

	_titre_tour = _etiquette("Tour d'archers · niv. 1", Color.WHITE, 14)
	colonne.add_child(_titre_tour)

	var rangee := HBoxContainer.new()
	rangee.add_theme_constant_override("separation", 8)
	colonne.add_child(rangee)
	_ameliorer = _bouton("Améliorer", func() -> void: demande_amelioration.emit())
	_ameliorer.custom_minimum_size = Vector2(118, 32)
	_vendre = _bouton("Vendre", func() -> void: demande_reprise.emit())
	_vendre.custom_minimum_size = Vector2(96, 32)
	rangee.add_child(_ameliorer)
	rangee.add_child(_vendre)


## Ouvre le panneau sur une tour, ou le referme si l'on passe `null`.
func montrer_tour(tour: Tour, argent: int) -> void:
	if tour == null:
		_panneau.visible = false
		return
	var nom := str(tour.reglages.get("nom", "Tour"))
	_titre_tour.text = "%s · niv. %d" % [nom, tour.niveau + 1]

	var cout := tour.cout_amelioration()
	if cout < 0:
		_ameliorer.text = "Au maximum"
		_ameliorer.disabled = true
	else:
		_ameliorer.text = "Améliorer  %d" % cout
		_ameliorer.disabled = argent < cout
	_vendre.text = "Vendre  +%d" % tour.valeur_reprise()
	_panneau.visible = true


# --- Le panneau de fin ----------------------------------------------------

func _construire_panneau_fin() -> void:
	_fin = _cadre()
	_fin.position = Vector2(262, 110)
	_fin.custom_minimum_size = Vector2(320, 0)
	_fin.visible = false
	add_child(_fin)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 10)
	colonne.alignment = BoxContainer.ALIGNMENT_CENTER
	_fin.add_child(colonne)

	_texte_fin = _etiquette("", Color.WHITE, 18)
	_texte_fin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texte_fin.custom_minimum_size = Vector2(296, 0)
	colonne.add_child(_texte_fin)

	var rangee := HBoxContainer.new()
	rangee.add_theme_constant_override("separation", 10)
	rangee.alignment = BoxContainer.ALIGNMENT_CENTER
	colonne.add_child(rangee)
	_rejouer = _bouton("Rejouer", func() -> void: demande_rejouer.emit())
	_rejouer.custom_minimum_size = Vector2(110, 34)
	_suivant = _bouton("La carte", func() -> void: demande_carte.emit())
	_suivant.custom_minimum_size = Vector2(110, 34)
	rangee.add_child(_rejouer)
	rangee.add_child(_suivant)


func montrer_fin(gagne: bool, bilan: Dictionary) -> void:
	_panneau.visible = false
	var lignes: Array[String] = []
	if gagne:
		var etoiles := int(bilan.get("etoiles", 0))
		lignes.append("NIVEAU TERMINÉ")
		lignes.append("★".repeat(etoiles) + "☆".repeat(3 - etoiles))
		var gagnees := int(bilan.get("essences_gagnees", 0))
		if gagnees > 0:
			lignes.append("+%d essence%s" % [gagnees, "s" if gagnees > 1 else ""])
		else:
			lignes.append("Déjà obtenu — aucune nouvelle essence")
	else:
		lignes.append("LA SOURCE EST TOMBÉE")
		lignes.append("Le niveau est gagnable")
		lignes.append("sans aucune amélioration.")
	_texte_fin.text = "\n".join(lignes)
	_fin.visible = true


# --- Les commandes --------------------------------------------------------

func _basculer_pause() -> void:
	var en_pause := not get_tree().paused
	get_tree().paused = en_pause
	_pause.text = "▶" if en_pause else "❚❚"


func _basculer_vitesse() -> void:
	_accelere = not _accelere
	Engine.time_scale = 2.0 if _accelere else 1.0
	_vitesse.text = "▶" if _accelere else "▶▶"


## La partie se termine : plus de commandes, on ne rejoue pas en pause.
func figer_commandes() -> void:
	_pause.disabled = true
	_vitesse.disabled = true
	get_tree().paused = false
	Engine.time_scale = 1.0


func rafraichir(jeu: Node) -> void:
	var total: int = (jeu.niveau.get("vagues", []) as Array).size()
	_vies.text = "♥ %d" % jeu.vies
	_or.text = "◆ %d" % jeu.argent
	_vague.text = "vague %d/%d" % [jeu.vague, total]


func dire(texte: String) -> void:
	_message.text = texte
	await get_tree().create_timer(1.6).timeout
	if _message.text == texte:
		_message.text = ""
