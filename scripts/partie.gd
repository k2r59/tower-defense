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


## Remettre à zéro, pour les essais.
func effacer() -> void:
	essences = 0
	niveaux = {}
	ameliorations = {}
	enregistrer()
