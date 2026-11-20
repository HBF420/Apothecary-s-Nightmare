extends StaticBody3D

var _sleeping: bool = false

func get_interact_label(_player = null) -> String:
	if _sleeping:
		return ""
	return "Sleep [E]"

func interact(_player):
	if _sleeping:
		return
	_sleeping = true

	var canvas = CanvasLayer.new()
	canvas.layer = 20
	get_tree().root.add_child(canvas)

	var rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)

	var tween = create_tween()
	tween.tween_property(rect, "color", Color(0, 0, 0, 1), 1.0)
	tween.tween_callback(func():
		get_tree().call_group("planter_pot", "on_sleep")
		get_tree().call_group("forge_station", "on_sleep")
		get_tree().call_group("player", "on_sleep")
	)
	tween.tween_interval(0.5)
	tween.tween_property(rect, "color", Color(0, 0, 0, 0), 1.0)
	tween.tween_callback(func():
		canvas.queue_free()
		_sleeping = false
	)
