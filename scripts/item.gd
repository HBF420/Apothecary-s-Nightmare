extends StaticBody3D

@export var item_type: String = "item"
@export var display_name: String = "Item"

func get_interact_label(_player = null) -> String:
	return "Pick up " + display_name + " [E]"

func interact(player):
	player.pick_up_item(self)
