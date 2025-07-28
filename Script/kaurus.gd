extends Node

class_name kaurus

var id = 0
var nom = ""
var spritePath = ""
var niveau = 0
var mhp = 0
var hp = 0
var type = ""
var attaques = [Attaque]
var stats = [0,0,0,0,0,0]
var dresseur = ""

func random() -> void:
	id = randi()
	var allKaurus = ["Electric","Feu","Glace","Bat"]
	nom = allKaurus[randi_range(0,allKaurus.size()-1)]
	spritePath = "res://AnimSprite/" + nom + ".tres"
	niveau = randi_range(1,100)
	for i in range(stats.size()):
		stats[i] = randi_range(1, 10)
	mhp = 50 + niveau*stats[4]
	hp = mhp
	type = nom
	attaques = [Attaque.new("Croc", "Feu", 40, 100),
	Attaque.new("Griffe", "Normal", 35, 95)]
	dresseur = "none"
