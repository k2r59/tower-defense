extends Node

## Ce qui survit à une partie.
##
## L'or se gagne et se dépense DANS un niveau, puis disparaît. L'essence, elle,
## reste : c'est elle qui donne le sentiment de revenir plus fort. Les deux ne
## doivent jamais se confondre, sinon le joueur ne sait plus ce qu'il achète.
##
## Tout tient dans un fichier de sauvegarde local. Aucun compte, aucun serveur :
## un jeu solo n'a rien à demander à personne.

const CHEMIN := "user://sauvegarde.json"

## Les essences disponibles, non dépensées.
var essences: int = 0

## Ce qu'on a fait de chaque niveau : { "niveau-01": { "etoiles": 2 } }.
var niveaux: Dictionary = {}

## Le niveau que la carte vient de lancer. C'est la seule chose que la carte
## dit au jeu : le reste, il le lit dans ses données.
var niveau_choisi: String = "niveau-01"

## Les nœuds d'amélioration achetés. Vide tant que l'arbre n'existe pas —
## il ne s'ouvre qu'après le deuxième niveau, pour ne pas noyer le joueur.
var ameliorations: Dictionary = {}


func _ready() -> void:
	charger()


func charger() -> void:
	if not FileAccess.file_exists(CHEMIN):
		return
	var brut := FileAccess.get_file_as_string(CHEMIN)
	var lu: Variant = JSON.parse_string(brut)
	if typeof(lu) != TYPE_DICTIONARY:
		# Sauvegarde illisible : on repart à zéro plutôt que de planter au
		# démarrage. Perdre sa progression est pénible ; ne plus pouvoir
		# lancer le jeu l'est davantage.
		push_warning("Sauvegarde illisible, on repart d'une partie neuve.")
		return
	essences = int(lu.get("essences", 0))
	niveaux = lu.get("niveaux", {})
	ameliorations = lu.get("ameliorations", {})


func enregistrer() -> void:
	var f := FileAccess.open(CHEMIN, FileAccess.WRITE)
	if f == null:
		push_warning("Sauvegarde impossible : %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify({
		"essences": essences,
		"niveaux": niveaux,
		"ameliorations": ameliorations,
	}, "  "))
	f.close()


## Les étoiles d'un niveau, et l'essence qu'elles rapportent.
##
## Une par victoire, une si rien n'est passé, une si l'on a fini sans tout
## dépenser. Trois par niveau, pas une de plus : chaque essence doit peser.
## Et l'on ne gagne que la DIFFÉRENCE avec son meilleur score — sinon rejouer
## le premier niveau en boucle deviendrait la meilleure stratégie du jeu.
func terminer_niveau(id: String, vies_restantes: int, vies_depart: int, or_restant: int) -> Dictionary:
	var etoiles := 1
	if vies_restantes == vies_depart:
		etoiles += 1
	if or_restant > 0:
		etoiles += 1

	var avant := int(niveaux.get(id, {}).get("etoiles", 0))
	var gagnees: int = max(0, etoiles - avant)
	essences += gagnees
	if etoiles > avant:
		niveaux[id] = { "etoiles": etoiles }
	enregistrer()

	return { "etoiles": etoiles, "essences_gagnees": gagnees, "deja_obtenues": avant }


# --- Le sanctuaire ---------------------------------------------------------

const CHEMIN_AMELIORATIONS := "res://donnees/ameliorations.json"

var _noeuds_cache: Array = []

## Les nœuds tels qu'ils sont écrits dans les données.
func noeuds() -> Array:
	if _noeuds_cache.is_empty():
		var lu: Variant = JSON.parse_string(FileAccess.get_file_as_string(CHEMIN_AMELIORATIONS))
		if typeof(lu) == TYPE_DICTIONARY:
			_noeuds_cache = lu.get("noeuds", [])
	return _noeuds_cache


func noeud(id: String) -> Dictionary:
	for n: Dictionary in noeuds():
		if str(n["id"]) == id:
			return n
	return {}


func achete(id: String) -> bool:
	return ameliorations.get(id, false) == true


## Un nœud s'ouvre quand le niveau qui le déverrouille est terminé, et quand
## son prérequis est acheté. Deux verrous, pour la même raison : on ne montre
## une décision qu'au moment où le joueur a une opinion dessus.
func noeud_ouvert(n: Dictionary) -> bool:
	var apres: Variant = n.get("ouvre_apres")
	if apres != null and int(niveaux.get(str(apres), {}).get("etoiles", 0)) == 0:
		return false
	var prereq: Variant = n.get("prerequis")
	return prereq == null or achete(str(prereq))


## Le sanctuaire n'existe pas avant d'avoir fini le deuxième niveau : sinon le
## joueur ouvrirait un écran de choix avant d'avoir posé sa première tour.
func sanctuaire_ouvert() -> bool:
	for n: Dictionary in noeuds():
		if noeud_ouvert(n):
			return true
	return false


func acheter(id: String) -> bool:
	var n := noeud(id)
	if n.is_empty() or achete(id) or not noeud_ouvert(n):
		return false
	var cout := int(n["cout"])
	if essences < cout:
		return false
	essences -= cout
	ameliorations[id] = true
	enregistrer()
	return true


## Tout reprendre, sans frais.
##
## C'est ce qui supprime l'angoisse du mauvais choix définitif : on essaie une
## orientation, on la défait, on en essaie une autre. Sans cela, le joueur
## prudent va lire un guide avant de dépenser — et jouer devient une
## vérification, plus une découverte.
func tout_reprendre() -> void:
	for id: String in ameliorations.keys():
		var n := noeud(id)
		if not n.is_empty():
			essences += int(n["cout"])
	ameliorations = {}
	enregistrer()


## La somme des effets achetés, pour une clé donnée.
func bonus(cle: String) -> float:
	var total := 0.0
	for n: Dictionary in noeuds():
		if not achete(str(n["id"])):
			continue
		var effet: Dictionary = n.get("effet", {})
		if str(effet.get("cle", "")) == cle:
			total += float(effet.get("valeur", 0.0))
	return total


## Remettre à zéro, pour les essais.
func effacer() -> void:
	essences = 0
	niveaux = {}
	ameliorations = {}
	enregistrer()
