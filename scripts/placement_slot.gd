extends StaticBody3D

@export var accepted_item_type: String = "mortar"
@export var slot_display_name: String = "Mortar"

func get_interact_label(player = null) -> String:
	if player and player.has_item_type(accepted_item_type):
		return "Place " + slot_display_name + " [E]"
	return ""

func interact(player):
	if not player.has_item_type(accepted_item_type):
		return
	for item in player.held_items:
		if item.get("item_type") == accepted_item_type:
			player.held_items.erase(item)
			player.hand_position.remove_child(item)
			get_parent().add_child(item)
			item.global_position = global_position
			item.collision_layer = 1
			item.collision_mask = 1
			player._update_inventory_label()
			return
