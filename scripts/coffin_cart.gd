extends Node3D

const DROP_RADIUS = 3.0

func _ready():
	add_to_group("coffin_cart")

func can_drop(player: Node3D) -> bool:
	return global_position.distance_to(player.global_position) <= DROP_RADIUS
