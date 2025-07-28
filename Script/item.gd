extends Node
class_name Item

enum ItemType { SOIN, BUFF, STATUT, CAPTURE }

var nom: String
var description: String
var type: ItemType
var valeur: int = 0  # ex : pour une potion = 20 HP
#@export var sprite: Texture2D

func creer_item(Nom: String, Description: String, Type: Item.ItemType, Valeur: int) -> void:
	self.nom = Nom
	self.description = Description
	self.type = Type
	self.valeur = Valeur
