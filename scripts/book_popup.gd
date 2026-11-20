extends CanvasLayer

const PAGES = [
	"res://textures/Aged apothecary book in flat ink.png",
	"res://textures/Bellyease draught apothecary ledger.png",
]

var _current_page: int = 0
var _tex_rect: TextureRect = null
var _prev_btn: Button = null
var _next_btn: Button = null
var _page_label: Label = null

func _ready():
	layer = 10

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_tex_rect = TextureRect.new()
	_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tex_rect.offset_bottom = -60
	add_child(_tex_rect)

	# Bottom bar
	var bar = HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -56
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 24)
	add_child(bar)

	_prev_btn = Button.new()
	_prev_btn.text = "◀  Previous"
	_prev_btn.add_theme_font_size_override("font_size", 20)
	_prev_btn.pressed.connect(_go_prev)
	bar.add_child(_prev_btn)

	_page_label = Label.new()
	_page_label.add_theme_font_size_override("font_size", 20)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.custom_minimum_size = Vector2(100, 0)
	bar.add_child(_page_label)

	_next_btn = Button.new()
	_next_btn.text = "Next  ▶"
	_next_btn.add_theme_font_size_override("font_size", 20)
	_next_btn.pressed.connect(_go_next)
	bar.add_child(_next_btn)

	var hint = Label.new()
	hint.text = "ESC to close"
	hint.add_theme_font_size_override("font_size", 16)
	hint.modulate = Color(1, 1, 1, 0.5)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -24
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)

	_show_page(_current_page)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _show_page(idx: int):
	_current_page = idx
	_tex_rect.texture = load(PAGES[_current_page])
	_page_label.text = "%d / %d" % [_current_page + 1, PAGES.size()]
	_prev_btn.disabled = (_current_page == 0)
	_next_btn.disabled = (_current_page == PAGES.size() - 1)

func _go_prev():
	if _current_page > 0:
		_show_page(_current_page - 1)

func _go_next():
	if _current_page < PAGES.size() - 1:
		_show_page(_current_page + 1)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		queue_free()
	elif event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		_go_prev()
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_go_next()
