extends Node

var items: Dictionary = {}

func ajouter_item(item: Item, quantite: int = 1) -> void:
	if item.nom in items:
		items[item.nom]["quantite"] += quantite
	else:
		items[item.nom] = {
			"item": item,
			"quantite": quantite
		}

func utiliser_item(nom_item: String) -> Item:
	if nom_item in items and items[nom_item]["quantite"] > 0:
		items[nom_item]["quantite"] -= 1
		var item_retourne = items[nom_item]["item"]
		if items[nom_item]["quantite"] == 0:
			items.erase(nom_item)
		return item_retourne
	return null

func get_liste_items() -> Array:
	var liste = []
	for item_nom in items:
		liste.append([items[item_nom]["item"], items[item_nom]["quantite"]])
	return liste
