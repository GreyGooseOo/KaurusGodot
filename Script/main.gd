extends Node

var potion = Item.new()

func _ready() -> void:
	potion.creer_item("Super Potion", "Soigne 50 HP", Item.ItemType.SOIN, 50)
	new_game()

func new_game():
	Inventaire.ajouter_item(potion, 1)
	$Player.start($StartPosition.position)

func _process(delta: float) -> void:
	if ($Player.position.x <= 700.0):
		get_tree().change_scene_to_file("res://Scene/battle.tscn")
