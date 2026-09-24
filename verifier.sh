#!/usr/bin/env bash
#
# Vérifie les cinq niveaux, sans écran et sans personne devant.
#
# Pour chacun, deux parties. La première joue la solution écrite dans les
# données du niveau : elle DOIT se gagner. La seconde ne construit rien : elle
# DOIT se perdre. La seconde compte autant que la première — un niveau qu'on
# gagne les bras croisés n'est pas un niveau.
#
# Les deux tournent avec `--neuf`, donc sur une sauvegarde vide : c'est ce qui
# prouve la règle d'or, chaque niveau gagnable avec ZÉRO amélioration.
#
#   ./verifier.sh              avec le godot du PATH
#   GODOT=/chemin/godot ./verifier.sh

set -uo pipefail
GODOT="${GODOT:-godot}"
NIVEAUX=(niveau-01 niveau-02 niveau-03 niveau-04 niveau-05)
rate=0

jouer() { "$GODOT" --headless --path . -- --test --neuf "--niveau=$1" "${@:2}"; }

for n in "${NIVEAUX[@]}"; do
	if sortie=$(jouer "$n" 2>&1); then
		echo "  ok    $n  se gagne  ($(echo "$sortie" | grep -o 'étoiles   : [0-9]*' | tail -1))"
	else
		echo "  ECHEC $n  ne se gagne PAS avec sa propre solution"
		echo "$sortie" | grep -E 'issue|vies|vague|or restant|SCRIPT ERROR|Parse Error' | sed 's/^/          /'
		rate=$((rate + 1))
	fi

	if jouer "$n" --test-passif >/dev/null 2>&1; then
		echo "  ECHEC $n  se gagne SANS RIEN FAIRE"
		rate=$((rate + 1))
	else
		echo "  ok    $n  se perd si l'on ne fait rien"
	fi
done

# La raison d'être du niveau 4, vérifiée et non pas seulement annoncée :
# l'armure de l'arbre doit rendre les archers seuls insuffisants. Si ce test
# passe un jour, c'est que l'armure ou le canon a été déréglé, et que le niveau
# ne pose plus la question qu'il prétend poser.
if jouer niveau-04 --famille=archers >/dev/null 2>&1; then
	echo "  ECHEC niveau-04  se gagne avec des archers seuls : l'arbre n'est plus un mur"
	rate=$((rate + 1))
else
	echo "  ok    niveau-04  ne se gagne PAS avec des archers seuls"
fi

echo "--- Les règles de combat ---"
if "$GODOT" --headless --path . --script res://scripts/test_combat.gd 2>&1 | grep -q ECHEC; then
	echo "  ECHEC les règles de combat"
	rate=$((rate + 1))
else
	echo "  ok    les règles de combat"
fi

echo "--- Le sanctuaire ---"
if "$GODOT" --headless --path . --script res://scripts/test_sanctuaire.gd 2>&1 | grep -q ECHEC; then
	echo "  ECHEC le sanctuaire"
	rate=$((rate + 1))
else
	echo "  ok    le sanctuaire"
fi

if [ "$rate" -eq 0 ]; then echo "Tout passe."; else echo "$rate échec(s)."; fi
exit "$rate"
