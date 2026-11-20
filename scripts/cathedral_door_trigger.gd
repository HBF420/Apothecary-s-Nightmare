extends StaticBody3D

var cathedral: Node3D = null

func get_interact_label(_player = null) -> String:
	if cathedral and cathedral.doors_open:
		return "Close doors [E]"
	return "Open doors [E]"

func interact(_player = null) -> void:
	if cathedral:
		cathedral.toggle_doors()
