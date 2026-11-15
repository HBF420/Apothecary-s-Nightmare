extends Node3D

const REQUIRED_ITEMS = ["mortar", "herbs", "vial"]
const INTERACT_DISTANCE = 2.5

func is_player_nearby(player) -> bool:
	return global_position.distance_to(player.global_position) < INTERACT_DISTANCE

func get_interact_label(player) -> String:
	if _player_has_all_items(player):
		return "Craft Potion [E]"
	else:
		var missing = _get_missing_items(player)
		return "Need: " + ", ".join(missing)

func interact(player):
	if _player_has_all_items(player):
		_craft_potion(player)

func _player_has_all_items(player) -> bool:
	for item in REQUIRED_ITEMS:
		if not player.has_item_type(item):
			return false
	return true

func _get_missing_items(player) -> Array:
	var missing = []
	for item in REQUIRED_ITEMS:
		if not player.has_item_type(item):
			missing.append(item)
	return missing

func _craft_potion(player):
	for item in REQUIRED_ITEMS:
		player.remove_item_type(item)
	var potion = _create_potion()
	get_parent().add_child(potion)
	potion.global_position = player.global_position + Vector3(0, 0.5, 0)
	player.pick_up_item(potion)

func _create_potion() -> Node:
	var potion = StaticBody3D.new()
	potion.set_script(load("res://scripts/item.gd"))
	potion.item_type = "potion"
	potion.display_name = "Potion"

	var glb = load("res://models/flask_with_potion.glb")
	if glb:
		var instance = glb.instantiate()
		instance.scale = Vector3(0.01, 0.01, 0.01)
		potion.add_child(instance)

	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.05
	shape.height = 0.15
	col.shape = shape
	potion.add_child(col)

	return potion
