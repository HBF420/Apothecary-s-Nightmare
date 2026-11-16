extends StaticBody3D

var cup = null

func get_interact_label(player = null) -> String:
	if cup == null or player == null:
		return ""
	if cup in player.held_items:
		return "Put cup down [E]"
	if cup.get_parent() == get_parent():
		return "Pick up %s [E]" % cup.display_name
	return ""

func interact(player):
	if cup == null:
		return
	if cup in player.held_items:
		# Return cup to its home spot
		player.held_items.erase(cup)
		player.hand_position.remove_child(cup)
		get_parent().add_child(cup)
		cup.global_position = global_position
		cup.rotation_degrees = Vector3(0, -70, 0)
		cup.collision_layer = 2
		cup.collision_mask = 0
		player._update_inventory_label()
	elif cup.get_parent() == get_parent():
		cup.interact(player)
