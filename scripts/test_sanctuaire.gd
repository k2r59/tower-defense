extends SceneTree

## Vérifie que le sanctuaire fait ce qu'il annonce.
##
## Une boutique qui prend la monnaie sans rien changer au jeu est le pire des
## défauts : invisible en lisant le code, évident après trois heures de jeu.
##
##   godot --headless --path . --script res://scripts/test_sanctuaire.gd

func _init() -> void:
	var partie: Node = load("res://scripts/partie.gd").new()
	get_root().add_child(partie)
	partie.effacer()

	var rate := 0
	var verifier := func(quoi: String, obtenu: Variant, attendu: Variant) -> void:
		var ok: bool = str(obtenu) == str(attendu)
		if not ok:
			rate += 1
		print("  %s %s : %s (attendu %s)" % ["ok  " if ok else "ECHEC", quoi, obtenu, attendu])

	print("--- Le sanctuaire ---")

	# 1. Il n'existe pas au depart.
	verifier.call("ferme au premier lancement", partie.sanctuaire_ouvert(), false)

	# 2. Il s'ouvre quand le deuxieme niveau est termine.
	partie.niveaux["niveau-02"] = { "etoiles": 2 }
	verifier.call("ouvert apres le niveau 2", partie.sanctuaire_ouvert(), true)

	# 3. On ne peut pas acheter sans essences.
	verifier.call("achat refuse sans essence", partie.acheter("degats-1"), false)

	# 4. Avec des essences, l'achat passe et la monnaie descend.
	partie.essences = 4
	verifier.call("achat accepte", partie.acheter("degats-1"), true)
	verifier.call("essences debitees", partie.essences, 3)
	verifier.call("bonus de degats applique", partie.bonus("degats_pct"), 0.1)

	# 5. Un noeud verrouille par son prerequis reste inaccessible.
	partie.niveaux["niveau-04"] = { "etoiles": 1 }
	verifier.call("prime-1 fermee sans son prerequis",
			partie.noeud_ouvert(partie.noeud("prime-1")), false)

	# 6. Tout se reprend, et l'on retrouve exactement sa mise.
	partie.tout_reprendre()
	verifier.call("essences rendues", partie.essences, 4)
	verifier.call("bonus annule", partie.bonus("degats_pct"), 0.0)

	# 7. La cadence est un delai : son bonus doit etre negatif.
	partie.essences = 9
	partie.acheter("degats-1")
	partie.niveaux["niveau-03"] = { "etoiles": 1 }
	partie.acheter("cadence-1")
	var plus_vite: bool = partie.bonus("cadence_pct") < 0.0
	verifier.call("la cadence accelere", plus_vite, true)

	partie.effacer()
	print("--- %s ---" % ("tout passe" if rate == 0 else "%d echec(s)" % rate))
	quit(1 if rate > 0 else 0)
