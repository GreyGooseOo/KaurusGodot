extends Resource

class_name Attaque
# ou extends Object si tu préfères

var nom: String
var type: String
var puissance: int
var precision: int

func _init(Nom: String = "", Type: String = "", Puissance: int = 0, Precision: int = 100) -> void:
	self.nom = Nom
	self.type = Type
	self.puissance = Puissance
	self.precision = Precision
