extends SceneTree

## Vérifie les règles de combat, une par une.
##
## Les essais de niveau (`verifier.sh`) disent si une partie se gagne. Ils ne
## disent pas POURQUOI. Une armure qui s'appliquerait deux fois, un
## ralentissement qui s'annulerait tout seul : le niveau resterait gagnable, et
## la faute ne se verrait qu'après des heures de jeu, sur la seule impression
## que « quelque chose cloche ». D'où ce fichier.
##
##   godot --headless --path . --script res://scripts/test_combat.gd

## Une ligne droite très longue : l'ennemi ne doit jamais atteindre le bout
## pendant un test, sinon il se libère et les mesures ne veulent plus rien dire.
static func _chemin() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, 0), Vector2(40000, 0)])

var _rate := 0


func _init() -> void:
	print("--- Le combat ---")

	_armure_arrete_les_coups_faibles()
	_armure_laisse_passer_les_coups_lourds()
	_sans_armure_tout_compte()
	_on_meurt_quand_la_vie_tombe()
	_le_ralentissement_freine()
	_les_racines_immobilisent()
	_le_plus_fort_ralentissement_gagne()
	_le_ralentissement_finit_par_passer()

	print("Tout passe." if _rate == 0 else "%d échec(s)." % _rate)
	quit(_rate)


func _verifier(quoi: String, obtenu: Variant, attendu: Variant) -> void:
	# Comparaison numérique quand c'est un nombre : 170.0 et 170 sont la même
	# vie, et un test qui les distingue ne teste que lui-même.
	var ok: bool = str(obtenu) == str(attendu)
	if obtenu is float or obtenu is int:
		ok = is_equal_approx(float(obtenu), float(attendu))
	if not ok:
		_rate += 1
	print("  %s %s : %s (attendu %s)" % ["ok  " if ok else "ECHEC", quoi, obtenu, attendu])


func _ennemi(reglages: Dictionary) -> Ennemi:
	var e := Ennemi.new()
	get_root().add_child(e)
	e.demarrer(_chemin(), reglages)
	return e


## Le cœur du niveau 4 : un coup plus faible que l'armure ne fait RIEN. Pas un
## point, rien. Sans ça, mille piqûres finissent par abattre l'arbre et le canon
## n'est plus une réponse, seulement un raccourci.
func _armure_arrete_les_coups_faibles() -> void:
	var a := _ennemi({ "vie": 170, "armure": 12 })
	a.encaisser(8.0)
	a.encaisser(12.0)
	_verifier("une flèche de 8 puis de 12 sur une armure de 12", a.vie, 170)
	_verifier("et il est toujours vivant", a.est_vivant(), true)
	a.free()


func _armure_laisse_passer_les_coups_lourds() -> void:
	var a := _ennemi({ "vie": 170, "armure": 12 })
	a.encaisser(34.0)
	_verifier("un boulet de 34 sur une armure de 12", a.vie, 148)
	a.free()


func _sans_armure_tout_compte() -> void:
	var g := _ennemi({ "vie": 40 })
	g.encaisser(8.0)
	_verifier("sans armure, 8 dégâts retirent 8", g.vie, 32)
	g.free()


func _on_meurt_quand_la_vie_tombe() -> void:
	var g := _ennemi({ "vie": 40 })
	# Un tableau, pas un entier : une lambda GDScript capture une COPIE des
	# variables locales, donc `morts += 1` ne remonterait jamais ici.
	var morts: Array[int] = []
	g.mort.connect(func(_e: Ennemi) -> void: morts.append(1))
	g.encaisser(40.0)
	_verifier("la mort est annoncée une fois", morts.size(), 1)
	_verifier("et il n'est plus vivant", g.est_vivant(), false)


## Un ralentissement doit freiner, pas figer : c'est le boulet de canon.
func _le_ralentissement_freine() -> void:
	var g := _ennemi({ "vie": 40, "vitesse": 100 })
	g.ralentir(0.5, 2.0)
	g._process(1.0)
	_verifier("à 100 de vitesse, ralenti de moitié, en 1 s", g.position.x, 50)
	g.free()


## Les racines, elles, figent. C'est un facteur de zéro, et zéro doit vraiment
## vouloir dire zéro — sinon la charge dépensée ne se voit pas.
func _les_racines_immobilisent() -> void:
	var g := _ennemi({ "vie": 40, "vitesse": 100 })
	g.ralentir(0.0, 3.0)
	g._process(1.0)
	_verifier("racines : il n'avance pas d'un pixel", g.position.x, 0)
	g.free()


## Un coup de canon tiré pendant les racines ne doit pas LIBÉRER l'ennemi.
## C'est le genre de faute qui rend une capacité « parfois inutile » sans qu'on
## comprenne jamais pourquoi.
func _le_plus_fort_ralentissement_gagne() -> void:
	var g := _ennemi({ "vie": 40, "vitesse": 100 })
	g.ralentir(0.0, 3.0)
	g.ralentir(0.6, 1.0)
	g._process(1.0)
	_verifier("un boulet pendant les racines ne les lève pas", g.position.x, 0)
	g.free()


func _le_ralentissement_finit_par_passer() -> void:
	var g := _ennemi({ "vie": 40, "vitesse": 100 })
	g.ralentir(0.0, 0.5)
	g._process(0.5)
	_verifier("pendant la durée, immobile", g.position.x, 0)
	g._process(1.0)
	_verifier("la durée écoulée, il repart à pleine vitesse", g.position.x, 100)
	g.free()
