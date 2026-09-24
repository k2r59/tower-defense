extends Control

## Le sanctuaire : ce que les essences achètent, et qui reste acquis.
##
## Trois choses le distinguent d'une boutique ordinaire, et ce sont elles qui
## le rendent jouable :
##
##  · il n'existe pas avant le deuxième niveau — un écran de choix devant
##    quelqu'un qui n'a pas encore posé sa première tour ne décide rien ;
##  · les nœuds s'ouvrent au fil des niveaux, donc on en voit trois, pas vingt ;
##  · tout se reprend gratuitement. Le joueur essaie une orientation, la défait,
##    en essaie une autre. Sans cela il ira lire un guide avant de dépenser, et
##    jouer deviendra une vérification.

var _essences: Label
var _liste: VBoxContainer


func _ready() -> void:
	var fond := ColorRect.new()
	fond.color = Color("#0f1a18")
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	var titre := _texte("LE SANCTUAIRE", 22, Color("#5fd3c8"))
	titre.position = Vector2(24, 16)
	add_child(titre)

	var sous := _texte("Les essences ne se dépensent qu'ici, et tout se reprend.",
			12, Color("#7f978f"))
	sous.position = Vector2(26, 45)
	add_child(sous)

	_essences = _texte("", 17, Color("#5fd3c8"))
	_essences.position = Vector2(600, 20)
	_essences.size = Vector2(220, 24)
	_essences.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_essences)

	var defile := ScrollContainer.new()
	defile.position = Vector2(24, 74)
	defile.size = Vector2(796, 258)
	add_child(defile)

	_liste = VBoxContainer.new()
	_liste.add_theme_constant_override("separation", 7)
	_liste.custom_minimum_size = Vector2(780, 0)
	defile.add_child(_liste)

	var pied := HBoxContainer.new()
	pied.add_theme_constant_override("separation", 10)
	pied.position = Vector2(24, 342)
	add_child(pied)
	pied.add_child(_bouton("La carte", 120, func() -> void:
			get_tree().change_scene_to_file("res://scenes/carte.tscn")))
	pied.add_child(_bouton("Tout reprendre", 150, func() -> void:
			Partie.tout_reprendre()
			_redessiner()))

	_redessiner()


func _texte(contenu: String, taille: int, couleur: Color) -> Label:
	var l := Label.new()
	l.text = contenu
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	return l


func _bouton(contenu: String, largeur: int, action: Callable) -> Button:
	var b := Button.new()
	b.text = contenu
	b.custom_minimum_size = Vector2(largeur, 32)
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(action)
	return b


func _redessiner() -> void:
	for enfant in _liste.get_children():
		enfant.queue_free()

	_essences.text = "✦ %d essence%s" % [Partie.essences, "s" if Partie.essences > 1 else ""]

	var ouverts := 0
	for n: Dictionary in Partie.noeuds():
		if not Partie.noeud_ouvert(n) and not Partie.achete(str(n["id"])):
			continue
		ouverts += 1
		_liste.add_child(_ligne(n))

	if ouverts == 0:
		var rien := _texte(
			"Rien à dépenser pour l'instant. Termine le deuxième niveau et le "
			+ "sanctuaire s'ouvrira.", 14, Color("#7f978f"))
		rien.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rien.custom_minimum_size = Vector2(760, 44)
		_liste.add_child(rien)


func _ligne(n: Dictionary) -> Control:
	var id := str(n["id"])
	var possede := Partie.achete(id)
	var cout := int(n["cout"])

	var cadre := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#16241f") if possede else Color("#131d1a")
	st.border_color = Color("#3f7a6e") if possede else Color("#26332e")
	st.set_border_width_all(2)
	st.set_corner_radius_all(9)
	st.set_content_margin_all(10)
	cadre.add_theme_stylebox_override("panel", st)

	var rangee := HBoxContainer.new()
	rangee.add_theme_constant_override("separation", 12)
	cadre.add_child(rangee)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 2)
	colonne.custom_minimum_size = Vector2(560, 0)
	rangee.add_child(colonne)
	colonne.add_child(_texte(str(n["nom"]), 15, Color.WHITE if possede else Color("#d7e5df")))
	var desc := _texte(str(n["description"]), 12, Color("#8fa89a"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(556, 0)
	colonne.add_child(desc)

	rangee.add_child(_texte("✦ %d" % cout, 15, Color("#5fd3c8")))

	if possede:
		var acquis := _texte("acquis", 13, Color("#7ee8a8"))
		acquis.custom_minimum_size = Vector2(104, 0)
		acquis.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rangee.add_child(acquis)
	else:
		var b := _bouton("Acheter", 104, func() -> void:
				if Partie.acheter(id):
					_redessiner())
		b.disabled = Partie.essences < cout
		rangee.add_child(b)

	return cadre
