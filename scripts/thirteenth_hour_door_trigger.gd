extends StaticBody3D

var house: Node3D = null

func get_interact_label(_player = null) -> String:
	if not house:
		return ""
	return "Close [E]" if house._door_open else "Open [E]"

func interact(_player) -> void:
	if house:
		house.set_door_open(not house._door_open)
