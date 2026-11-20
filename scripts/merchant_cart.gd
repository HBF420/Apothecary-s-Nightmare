extends StaticBody3D

func get_interact_label(_player = null) -> String:
	return "Browse Wares [E]"

func interact(player):
	var menu = load("res://scripts/merchant_shop.gd").new()
	menu.player = player
	get_tree().root.add_child(menu)
