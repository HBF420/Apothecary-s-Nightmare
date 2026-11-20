extends CanvasLayer

var player = null
var _gold_label: Label = null

const GOODS = [
	{"label": "Snake Plant Seeds — 5g",  "action": "seed", "seed": "snake_plant", "cost": 5},
	{"label": "Basil Seeds — 5g",        "action": "seed", "seed": "basil",       "cost": 5},
	{"label": "Aloe Vera Seeds — 5g",    "action": "seed", "seed": "aloe_vera",   "cost": 5},
	{"label": "Bee Balm Seeds — 5g",     "action": "seed", "seed": "bee_balm",    "cost": 5},
	{"label": "Calendula Seeds — 5g",    "action": "seed", "seed": "calendula",   "cost": 5},
	{"label": "Chamomile Seeds — 5g",    "action": "seed", "seed": "chamomile",   "cost": 5},
	{"label": "Empty Vial — 8g",         "action": "vial",                        "cost": 8},
]

func _ready():
	layer = 10

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left  = -280.0
	panel.offset_top   = -300.0
	panel.offset_right =  280.0
	panel.offset_bottom =  300.0
	add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   20)
	margin.add_theme_constant_override("margin_right",  20)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Merchant's Wares"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 16)
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.modulate = Color(1.0, 0.85, 0.3)
	vbox.add_child(_gold_label)
	_refresh_gold()

	for good in GOODS:
		_add_buy_button(vbox, good)

	_add_separator(vbox)
	_add_button(vbox, "Leave", func(): _close())

	var hint = Label.new()
	hint.text = "Press ESC to leave"
	hint.add_theme_font_size_override("font_size", 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.6)
	vbox.add_child(hint)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _refresh_gold():
	if _gold_label and player:
		_gold_label.text = "Gold: %d" % player.gold

func _add_buy_button(parent: VBoxContainer, good: Dictionary):
	var btn = Button.new()
	btn.text = good["label"]
	btn.add_theme_font_size_override("font_size", 17)
	btn.pressed.connect(func(): _purchase(good))
	parent.add_child(btn)

func _add_button(parent: VBoxContainer, label_text: String, callback: Callable):
	var btn = Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _add_separator(parent: VBoxContainer):
	var sep = HSeparator.new()
	parent.add_child(sep)

func _purchase(good: Dictionary):
	if not player:
		return
	if player.gold < good["cost"]:
		_gold_label.text = "Not enough gold!"
		get_tree().create_timer(1.5).timeout.connect(func():
			if is_instance_valid(_gold_label):
				_refresh_gold()
		)
		return

	player.gold -= good["cost"]
	player.update_gold_label()
	_refresh_gold()

	match good["action"]:
		"seed":
			player.add_seed(good["seed"], 1)
		"vial":
			_spawn_vial_near_player()

func _spawn_vial_near_player():
	if not player:
		return

	var vial_script = load("res://scripts/vial_item.gd")
	var glb_res     = load("res://models/vial.glb")
	if not vial_script or not glb_res:
		return

	var body = StaticBody3D.new()
	body.set_script(vial_script)
	body.collision_layer = 2
	body.collision_mask  = 0

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.08, 0.18, 0.08)
	col.shape = shape
	col.position = Vector3(0, 0.09, 0)
	body.add_child(col)

	var visual = glb_res.instantiate()
	visual.scale = Vector3(2.0, 2.0, 2.0)
	body.add_child(visual)
	body.setup(visual)

	# Drop 1 m in front of the player on the floor
	var fwd = -player.transform.basis.z
	body.global_position = player.global_position + fwd * 1.0 + Vector3(0, 0.0, 0)
	get_tree().root.add_child(body)

func _close():
	queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
