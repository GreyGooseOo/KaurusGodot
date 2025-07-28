extends Node

# Kaurus
var kaurusAllie = kaurus.new()
var kaurusEnemy = kaurus.new()
var equipe = kaurusListe.new()
var kaurus_disponibles: Array = []

# Combat
var attaque_selectionnee = null
var attaques_disponibles: Array = []
var nbActionTour = 0
var action_joueur_type = ActionJoueurType.ATTAQUE
var vitesse_joueur = 0
var vitesse_ennemi = 0

# Fuite
var fuite_autorisee = true
var tentatives_fuite = 0

# États
enum ActionJoueurType { ATTAQUE, CHANGEMENT_KAURUS, OBJET, AUCUNE }
enum CombatState { START, CHOIX_JOUEUR, ACTION_JOUEUR, ACTION_ENNEMI, VERIF_FIN, FIN }
var etat = CombatState.START
signal item_selectionne(index)


func _ready() -> void:
	initialiser_combat()
	start_combat()

func _process(delta: float) -> void:
	$JaugeKaurus.value = kaurusAllie.hp
	$JaugeEnemy.value = kaurusEnemy.hp
	# Retour arrière depuis le menu ArrayOfItem
	if $ArrayOfItem.visible and Input.is_action_just_pressed("Annuler"):
		$ArrayOfItem.hide()
		$ChoixPrincipal.show()


func initialiser_combat() -> void:
	# a supprimer
	kaurusEnemy.random()
	kaurusAllie.random()
	equipe.add(kaurusAllie)
	for i in 3:
		var tempKaurus = kaurus.new()
		tempKaurus.random()
		equipe.add(tempKaurus)
	#
	vitesse_joueur = kaurusAllie.stats[3]
	vitesse_ennemi = kaurusEnemy.stats[3]
	tentatives_fuite = 0
	if kaurusEnemy.dresseur == "none":
		fuite_autorisee = true
	else :
		fuite_autorisee = false
	$DialogueBox.hide()
	$Kaurus.animation = "Base"
	$Enemy.animation = "Base"
	$Dresseur.animation = "base"
	$DresseurEnemy.animation = "base"
	$Enemy.flip_h = true
	$Kaurus.sprite_frames = load(kaurusAllie.spritePath)
	$Enemy.sprite_frames = load(kaurusEnemy.spritePath)
	$Kaurus.play()
	$Enemy.play()
	$Dresseur.play()
	$DresseurEnemy.play()
	$JaugeKaurus.max_value = kaurusAllie.mhp
	$JaugeEnemy.max_value = kaurusEnemy.mhp
	$JaugeKaurus.value = kaurusAllie.hp
	$JaugeEnemy.value = kaurusEnemy.hp
	$ArrayOfItem.hide()
	$KaurusName.text = kaurusAllie.nom + " lvl: " + str(kaurusAllie.niveau)
	$EnemyName.text = kaurusEnemy.nom + " lvl: " + str(kaurusEnemy.niveau)

func afficher_dialogue(texte: String) -> void:
	$DialogueBox/Label.text = texte
	$DialogueBox.show()

func masquer_dialogue() -> void:
	await attente_validation()
	$DialogueBox.hide()

func start_combat() -> void:
	# Lance la séquence de combat en tâche asynchrone
	await boucle_de_combat()

func boucle_de_combat() -> void:
	nbActionTour = 0
	attaque_selectionnee = null
	action_joueur_type = ActionJoueurType.AUCUNE
	vitesse_joueur = kaurusAllie.stats[3]
	vitesse_ennemi = kaurusEnemy.stats[3]

	while true:
		etat = CombatState.CHOIX_JOUEUR
		$ChoixPrincipal.show()
		await attente_selection_joueur()
		$ChoixPrincipal.hide()

		# Tour du joueur en premier
		if vitesse_joueur >= vitesse_ennemi:
			await jouer_action_joueur()
			if kaurusEnemy.hp <= 0:
				break
			await jouer_action_ennemi()
			if kaurusAllie.hp <= 0:
				break
		else:
			await jouer_action_ennemi()
			if kaurusAllie.hp <= 0:
				break
			await jouer_action_joueur()
			if kaurusEnemy.hp <= 0:
				break

		if nbActionTour >= 2:
			break

	# Fin du combat
	etat = CombatState.FIN
	fin_de_combat()

func attente_selection_joueur() -> void:
	while action_joueur_type == ActionJoueurType.AUCUNE:
		await get_tree().process_frame

func attente_validation() -> void:
	while !Input.is_action_just_pressed("Select"):
		await get_tree().process_frame


func jouer_action_joueur() -> void:
	nbActionTour += 1
	var index = await self.item_selectionne
	match action_joueur_type:
		ActionJoueurType.ATTAQUE:
			etat = CombatState.ACTION_JOUEUR
			await anime_dresseur($Dresseur)
			await effet_attaque_joueur(index)

		ActionJoueurType.CHANGEMENT_KAURUS:
			etat = CombatState.ACTION_JOUEUR
			await anime_dresseur($Dresseur)
			await effet_changement_kaurus(index)

		ActionJoueurType.OBJET:
			etat = CombatState.ACTION_JOUEUR
			await anime_dresseur($Dresseur)
			await effet_utilisation_objet(index)

func effet_changement_kaurus(index: int) -> void:
	changer_kaurus(kaurus_disponibles[index])

func effet_utilisation_objet(index: int) -> void:
	var pair = Inventaire.get_liste_items()[index]
	var item = pair[0]
	if item.type == Item.ItemType.SOIN and kaurusAllie.hp < kaurusAllie.mhp:
		kaurusAllie.hp = min(kaurusAllie.hp + item.valeur, kaurusAllie.mhp)
		afficher_dialogue("Tu utilises " + item.nom + " et soignes " + str(item.valeur) + " PV !")
		masquer_dialogue()
		Inventaire.utiliser_item(item.nom)

func jouer_action_ennemi() -> void:
	nbActionTour += 1
	etat = CombatState.ACTION_ENNEMI
	await anime_dresseur($DresseurEnemy)
	await effet_attaque_ennemi()


func afficher_attaques(attaques: Array) -> void:
	$ArrayOfItem/ItemList.clear()
	attaques_disponibles = attaques  # on garde une référence aux attaques affichées
	for i in attaques.size():
		var attaque = attaques[i]
		var texte = attaque.nom + " (" + attaque.type + ", " + str(attaque.puissance) + ")"
		$ArrayOfItem/ItemList.add_item(texte)
		$ArrayOfItem/ItemList.set_item_custom_fg_color(i, get_color_par_type(attaque.type))


func get_color_par_type(type: String) -> Color:
	match type:
		"Feu": return Color.RED
		"Glace": return Color.CYAN
		"Electric": return Color.YELLOW
		"Bat": return Color.VIOLET
		_: return Color.WHITE

func effet_attaque_joueur(index: int) -> void:
	animer_secousse($Enemy,$Kaurus)
	attaque_selectionnee = attaques_disponibles[index]
	var attaque = attaque_selectionnee
	var degats = calculer_degats(kaurusAllie, kaurusEnemy, attaque)
	kaurusEnemy.hp -= degats
	# Affiche le texte
	afficher_dialogue(kaurusAllie.nom + " attaque avec " + attaque.nom + " et inflige " + str(degats) + " dégâts !")
	masquer_dialogue()

func effet_attaque_ennemi() -> void:
	animer_secousse($Kaurus,$Enemy)
	var attaque = kaurusEnemy.attaques[randi_range(0, kaurusEnemy.attaques.size() - 1)]
	var degats = calculer_degats(kaurusEnemy, kaurusAllie, attaque)
	kaurusAllie.hp -= degats
	afficher_dialogue(kaurusEnemy.nom + " attaque avec " + attaque.nom + " et inflige " + str(degats) + " dégâts !")
	masquer_dialogue()

func fin_de_combat() -> void:
	if kaurusAllie.hp <= 0:
		afficher_dialogue(kaurusAllie.nom + " est KO.. ")
		masquer_dialogue()
		var teamAlive = false
		for elem in equipe.liste:
			if elem.hp > 0:
				teamAlive = true
				break
		if teamAlive:
			# Demander au joueur de choisir un nouveau Kaurus
			afficher_dialogue("Choisis un autre Kaurus pour continuer le combat.")
			masquer_dialogue()
			# Afficher la sélection de Kaurus (on saute une phase de boucle_de_combat)
			action_joueur_type = ActionJoueurType.CHANGEMENT_KAURUS
			afficher_kaurus(equipe.liste)
			$ArrayOfItem.show()
			await attente_selection_joueur()
			var index = await self.item_selectionne
			await effet_changement_kaurus(index)
			# On revient dans la boucle de combat une fois un Kaurus choisi
			await boucle_de_combat()
		else:
			afficher_dialogue("\nTu as perdu.")
			masquer_dialogue()
			get_tree().change_scene_to_file("res://Scene/main.tscn")
	elif kaurusEnemy.hp <= 0:
		get_tree().change_scene_to_file("res://Scene/main.tscn")
		#print("L’ennemi est KO ! Victoire !")
	else :
		await boucle_de_combat()

func calculer_degats(attacker, defender, attaque) -> int:
	var att = attacker.stats[1]  # exemple : attaque physique
	var def = defender.stats[2]  # exemple : défense
	var puissance = attaque.puissance

	var degats = (puissance * att / max(def, 1)) * randf_range(0.85, 1.0)
	return int(degats)

func _on_attaque_mouse_entered() -> void:
	$ChoixPrincipal/hBoxContainer/vBoxContainer/Attaque.disabled = false

func _on_attaque_mouse_exited() -> void:
	$ChoixPrincipal/hBoxContainer/vBoxContainer/Attaque.disabled = true

func _on_objets_mouse_entered() -> void:
	$ChoixPrincipal/hBoxContainer/vBoxContainer/Objets.disabled = false

func _on_objets_mouse_exited() -> void:
	$ChoixPrincipal/hBoxContainer/vBoxContainer/Objets.disabled = true

func _on_kaurus_mouse_entered() -> void:
	$ChoixPrincipal/hBoxContainer/vBoxContainer2/Kaurus.disabled = false

func _on_kaurus_mouse_exited() -> void:
	$ChoixPrincipal/hBoxContainer/vBoxContainer2/Kaurus.disabled = true

func _on_fuire_mouse_entered() -> void:
	$ChoixPrincipal/hBoxContainer/vBoxContainer2/Fuire.disabled = false

func _on_fuire_mouse_exited() -> void:
	$ChoixPrincipal/hBoxContainer/vBoxContainer2/Fuire.disabled = true

func _on_attaque_pressed() -> void:
	$ChoixPrincipal.hide()
	$ArrayOfItem.show()
	action_joueur_type = ActionJoueurType.ATTAQUE
	afficher_attaques(kaurusAllie.attaques)

func _on_item_list_item_selected(index: int) -> void:
	$ArrayOfItem.hide()
	emit_signal("item_selectionne", index)

func animer_secousse(spriteDef: AnimatedSprite2D, spriteAtk: AnimatedSprite2D) -> void:
	var original_pos = spriteDef.position
	# Joue l'animation "Atk"
	spriteAtk.play("Atk")
	spriteDef.play("Hit")
	# Tween pour secousse
	var tween = create_tween()
	tween.tween_property(spriteDef, "position", original_pos + Vector2(10, 0), 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(spriteDef, "position", original_pos - Vector2(10, 0), 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(spriteDef, "position", original_pos, 0.05)
	# Timer pour remettre à "Base" après un court délai
	await get_tree().create_timer(0.8).timeout
	spriteDef.play("Base")
	spriteAtk.play("Base")

func anime_dresseur(sprite: AnimatedSprite2D) -> void:
	# Joue l'animation "Atk"
	sprite.play("ordre")
	# Timer pour remettre à "Base" après un court délai
	await get_tree().create_timer(1).timeout
	sprite.play("base")

func changer_kaurus(nouveau_kaurus):
	kaurusAllie = nouveau_kaurus
	$Kaurus.sprite_frames = load(kaurusAllie.spritePath)
	$Kaurus.play("Base")
	$KaurusName.text = kaurusAllie.nom + " lvl: " + str(kaurusAllie.niveau)
	$JaugeKaurus.max_value = kaurusAllie.mhp
	$JaugeKaurus.value = kaurusAllie.hp
	# Affiche un message de changement
	afficher_dialogue("Tu envoies " + kaurusAllie.nom + " au combat !")
	masquer_dialogue()

func _on_kaurus_pressed() -> void:
	$ChoixPrincipal.hide()
	$ArrayOfItem.show()
	action_joueur_type = ActionJoueurType.CHANGEMENT_KAURUS
	afficher_kaurus(equipe.liste)

func afficher_kaurus(kaurusList) -> void:
	$ArrayOfItem/ItemList.clear()
	kaurus_disponibles = kaurusList
	for i in kaurusList.size():
		var k = kaurusList[i]
		var texte = k.nom + " (HP: " + str(k.hp) + "/" + str(k.mhp) + ")"
		$ArrayOfItem/ItemList.add_item(texte)
		# Grise les Kaurus KO ou déjà en combat
		if k == kaurusAllie or k.hp <= 0:
			$ArrayOfItem/ItemList.set_item_disabled(i, true)

func _on_objets_pressed() -> void:
	$ChoixPrincipal.hide()
	$ArrayOfItem.show()
	action_joueur_type = ActionJoueurType.OBJET
	afficher_objets(Inventaire.get_liste_items())

func afficher_objets(liste_items: Array) -> void:
	$ArrayOfItem/ItemList.clear()
	for pair in liste_items:
		var item = pair[0]         # C'est un objet Item
		var quantite = pair[1]     # C'est un entier
		var texte = item.nom + " x" + str(quantite) + " (" + item.description + ")"
		$ArrayOfItem/ItemList.add_item(texte)

func _on_fuire_pressed() -> void:
	$ChoixPrincipal.hide()
	tenter_fuite()

func tenter_fuite():
	if not fuite_autorisee:
		afficher_dialogue("Tu ne peux pas fuir ce combat !")
		masquer_dialogue()
		return
	var chance = float(vitesse_joueur * 32) / (vitesse_ennemi / 4.0 + 30.0)
	chance += 10.0 * tentatives_fuite
	chance = min(chance / 100.0, 0.95)  # converti en pourcentage puis limité à 95 %

	if randf() < chance:
		afficher_dialogue("Tu réussis à fuir !")
		masquer_dialogue()
		get_tree().change_scene_to_file("res://Scene/main.tscn")
	else:
		tentatives_fuite += 1
		afficher_dialogue("La fuite a échoué !")
		masquer_dialogue()

		etat = CombatState.ACTION_ENNEMI
		await effet_attaque_ennemi()
		fin_de_combat()
