extends CanvasLayer

var customer = null
var tier: int = 0

const TIER_TITLES = {
	0: "What would you have me do?",
	1: "What else can you tell me?",
	2: "Let me ask further.",
	3: "I must dig deeper.",
}

const TIER1_QUESTIONS = [
	["when_begin",  "When did it begin?"],
	["sleep",       "How's your sleep?"],
	["appetite",    "How's your appetite?"],
	["stomach",     "How's your stomach?"],
	["breathing",   "How's your breathing?"],
]

const TIER2_QUESTIONS = [
	["worst_when",    "When's it worst?"],
	["brings_on",     "What brings it on?"],
	["getting_worse", "Is it getting worse?"],
	["others_ill",    "Is anyone else at home ill?"],
	["spots_sores",   "Have you noticed any new spots, sores, or swelling?"],
]

const TIER3_QUESTIONS = [
	["sleep_elsewhere",  "Have you tried sleeping somewhere else?"],
	["home_changes",     "Have there been significant changes to your home?"],
	["bitten",           "Have you been bitten or stung?"],
	["unusual_handling", "Have you handled anything unusual lately?"],
	["bed_stain",        "Have you found a stain or smell near your bed?"],
]

func _ready():
	layer = 10

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260.0
	panel.offset_top = -220.0
	panel.offset_right = 260.0
	panel.offset_bottom = 220.0
	add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title_key = tier if tier <= 0 else tier
	var title_text = TIER_TITLES.get(tier, "...")
	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)

	match tier:
		0:
			_add_button(vbox, "I know what's wrong", func(): _on_know_whats_wrong())
			_add_button(vbox, "Tell me more", func(): _reopen_tier(1))
			_add_button(vbox, "I can't help you", func(): _on_cant_help())
		1:
			for pair in TIER1_QUESTIONS:
				var key = pair[0]
				var label = pair[1]
				_add_question_button(vbox, key, label)
			_add_button(vbox, "I need more information", func(): _reopen_tier(2))
			_add_button(vbox, "I need to think", func(): _reopen_tier(0))
		2:
			for pair in TIER2_QUESTIONS:
				var key = pair[0]
				var label = pair[1]
				_add_question_button(vbox, key, label)
			_add_button(vbox, "I need more information", func(): _reopen_tier(3))
			_add_button(vbox, "I need to think", func(): _reopen_tier(0))
		3:
			for pair in TIER3_QUESTIONS:
				var key = pair[0]
				var label = pair[1]
				_add_question_button(vbox, key, label)
			_add_button(vbox, "I need to think", func(): _reopen_tier(0))

	var hint = Label.new()
	hint.add_theme_font_size_override("font_size", 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.6)
	if tier >= 1:
		hint.text = "Press ESC to go back"
	else:
		hint.text = "Press ESC to close"
	vbox.add_child(hint)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _add_button(parent: VBoxContainer, label_text: String, callback: Callable):
	var btn = Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _add_question_button(parent: VBoxContainer, key: String, label_text: String):
	var btn = Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 17)
	btn.pressed.connect(func():
		queue_free()
		customer.show_answer(key)
	)
	parent.add_child(btn)

func _on_know_whats_wrong():
	queue_free()
	customer._enter_waiting()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _reopen_tier(t: int):
	queue_free()
	customer.open_dialogue_at_tier(t)

func _on_cant_help():
	queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var player = get_tree().get_first_node_in_group("player")
	customer.dismiss(player)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if tier >= 1:
			_reopen_tier(0)
		else:
			queue_free()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
