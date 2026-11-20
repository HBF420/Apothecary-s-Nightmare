extends StaticBody3D

var pivot: Node = null

func get_interact_label(_player = null) -> String:
	if pivot:
		return pivot.get_interact_label()
	return ""

func interact(player):
	if pivot:
		pivot.interact(player)

func get_secondary_label(_player = null) -> String:
	if pivot:
		return pivot.get_secondary_label(_player)
	return ""

func secondary_interact(player = null) -> void:
	if pivot:
		pivot.secondary_interact(player)
