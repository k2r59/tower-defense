extends CanvasLayer

## L'affichage tête haute : vies, or, vague, et le mot de la fin.
##
## Tout est construit en code, volontairement. Une interface de jeu se règle
## au pixel et change dix fois ; la décrire dans une scène obligerait à
## rouvrir l'éditeur pour chaque essai. Et surtout : elle ne sera JAMAIS
## générée par une IA d'image — on veut la même bordure partout, et du vrai
## texte.

var _vies: Label
var _or: Label
var _vague: Label
var _message: Label
var _fin: Label


func _ready() -> void:
	var barre := HBoxContainer.new()
	barre.add_theme_constant_override("separation", 18)
	barre.position = Vector2(16, 14)
	add_child(barre)

	_vies = _etiquette("20", Color("#ff7b7b"))
	_or = _etiquette("120", Color("#ffd166"))
	_vague = _etiquette("0/5", Color("#a9d8ff"))
	barre.add_child(_vies)
	barre.add_child(_or)
	barre.add_child(_vague)

	# Le message passager : « pas assez d'or », et il s'efface tout seul.
	_message = _etiquette("", Color("#ffffff"))
	_message.position = Vector2(16, 806)
	_message.size = Vector2(358, 24)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_message)

	_fin = _etiquette("", Color("#ffffff"))
	_fin.position = Vector2(20, 360)
	_fin.size = Vector2(350, 140)
	_fin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fin.add_theme_font_size_override("font_size", 22)
	_fin.visible = false
	add_child(_fin)


func _etiquette(texte: String, couleur: Color) -> Label:
	var l := Label.new()
	l.text = texte
	l.add_theme_color_override("font_color", couleur)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_font_size_override("font_size", 17)
	return l


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


func montrer_fin(gagne: bool, bilan: Dictionary) -> void:
	var lignes: Array[String] = []
	if gagne:
		lignes.append("NIVEAU TERMINÉ")
		lignes.append("%s" % "★".repeat(int(bilan.get("etoiles", 0))))
		var gagnees := int(bilan.get("essences_gagnees", 0))
		if gagnees > 0:
			lignes.append("+%d essence%s" % [gagnees, "s" if gagnees > 1 else ""])
		else:
			lignes.append("Aucune nouvelle essence")
	else:
		lignes.append("LA SOURCE EST TOMBÉE")
		lignes.append("Réessaie — le niveau est gagnable")
		lignes.append("sans aucune amélioration.")
	_fin.text = "\n".join(lignes)
	_fin.visible = true
