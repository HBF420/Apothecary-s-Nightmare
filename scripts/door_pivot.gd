extends Node3D

var is_open = false
var is_animating = false
var blocker: Node = null
var door_node: Node = null

func get_interact_label(_player = null) -> String:
	if is_open:
		return "Close door [E]"
	return "Open door [E]"

func interact(_player):
	if is_animating or not door_node:
		return
	is_animating = true
	is_open = !is_open
	if blocker:
		blocker.collision_layer = 0 if is_open else 1
		blocker.collision_mask = 0 if is_open else 1
	var tween = create_tween()
	tween.tween_property(door_node, "rotation_degrees:y", -85.0 if is_open else 0.0, 1.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_callback(func(): is_animating = false)
