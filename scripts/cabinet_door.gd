extends StaticBody3D

var is_open: bool = false
var is_animating: bool = false
const OPEN_ANGLE = -90.0
const CLOSE_ANGLE = 0.0
const ANIM_SPEED = 2.0

func get_interact_label(_player = null) -> String:
	if is_open:
		return "Close door [E]"
	return "Open door [E]"

func interact(_player):
	if not is_animating:
		is_animating = true
		if is_open:
			_animate_door(deg_to_rad(CLOSE_ANGLE))
		else:
			_animate_door(deg_to_rad(OPEN_ANGLE))
		is_open = not is_open

func _animate_door(target_angle: float):
	var tween = create_tween()
	tween.tween_property(self, "rotation:y", target_angle, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): is_animating = false)
