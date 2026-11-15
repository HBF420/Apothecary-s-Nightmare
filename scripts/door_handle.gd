extends StaticBody3D

var pivot: Node = null

func get_interact_label(_player = null) -> String:
	if pivot:
		return pivot.get_interact_label()
	return ""

func interact(player):
	if pivot:
		pivot.interact(player)
