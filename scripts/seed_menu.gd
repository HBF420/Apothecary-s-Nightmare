extends CanvasLayer

var pot = null
var player = null

func _ready():
	layer = 10

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200.0
	panel.offset_top = -150.0
	panel.offset_right = 200.0
	panel.offset_bottom = 150.0
	add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Choose a seed to plant:"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for seed_type in player.seeds:
		if player.seeds[seed_type] > 0:
			var btn = Button.new()
			btn.text = "%s (x%d)" % [seed_type.replace("_", " ").capitalize(), player.seeds[seed_type]]
			btn.add_theme_font_size_override("font_size", 20)
			var st = seed_type
			btn.pressed.connect(func():
				pot.plant_seed(st, player)
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				queue_free()
			)
			vbox.add_child(btn)

	var hint = Label.new()
	hint.text = "Press ESC to cancel"
	hint.add_theme_font_size_override("font_size", 16)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.7)
	vbox.add_child(hint)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		queue_free()
