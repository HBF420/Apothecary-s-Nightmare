extends CanvasLayer

func _ready():
	layer = 10

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var tex_rect = TextureRect.new()
	tex_rect.texture = load("res://textures/Aged apothecary book in flat ink.png")
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(tex_rect)

	var hint = Label.new()
	hint.text = "Press ESC to close"
	hint.add_theme_font_size_override("font_size", 22)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -48
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.7)
	add_child(hint)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		queue_free()
