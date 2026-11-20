extends Node
## ─────────────────────────────────────────────────────────────────────────────
## Debug Placement Tool
## Press F1 in-game to toggle.  Lets you grab any building with [ / ] and
## nudge it with keys, then press P to print all positions to the Output panel.
## ─────────────────────────────────────────────────────────────────────────────

const STEP_SM  := 0.1
const STEP_LG  := 1.0
const ROT_STEP := 15.0

var _active    := false
var _buildings := []        # Array[Node3D]
var _idx       := 0

var _canvas   : CanvasLayer
var _panel    : Panel
var _lbl      : Label
var _indicator : Label3D = null   # floating world-space arrow above selection

# ── setup ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_ui()
	# Wait two frames so all _place_* functions in main._ready() have finished.
	await get_tree().process_frame
	await get_tree().process_frame
	_collect()

func _collect() -> void:
	_buildings.clear()
	for child in get_parent().get_children():
		if _is_building(child):
			_buildings.append(child)
	_refresh()

func _is_building(node: Node) -> bool:
	# Only bare Node3D roots — this matches GLB instances (Blender exports).
	# Excludes StaticBody3D triggers, MeshInstance3D planes, CharacterBody3D player, etc.
	if node.get_class() != "Node3D":
		return false
	if node.name in ["DebugPlacer"]:
		return false
	return _has_mesh(node)

func _has_mesh(node: Node) -> bool:
	if node is MeshInstance3D:
		return true
	for c in node.get_children():
		if _has_mesh(c):
			return true
	return false

# ── ui ────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 100
	add_child(_canvas)

	_panel = Panel.new()
	_panel.size     = Vector2(420, 230)
	_panel.position = Vector2(20, 20)
	_panel.visible  = false
	_canvas.add_child(_panel)

	_lbl = Label.new()
	_lbl.position        = Vector2(14, 10)
	_lbl.size            = Vector2(392, 210)
	_lbl.autowrap_mode   = TextServer.AUTOWRAP_WORD
	_panel.add_child(_lbl)

func _refresh() -> void:
	_update_indicator()
	if not _active:
		return
	if _buildings.is_empty():
		_lbl.text = "No buildings found.\n\nB = close"
		return
	var node: Node3D = _buildings[_idx]
	var p  := node.global_position
	var ry := node.rotation_degrees.y
	_lbl.text = (
		"B = exit placer      P = print ALL positions\n"
		+ "────────────────────────────────────────\n"
		+ "[%d / %d]  %s\n" % [_idx + 1, _buildings.size(), node.name]
		+ "X=%.2f  Y=%.2f  Z=%.2f    rotY=%.0f°\n" % [p.x, p.y, p.z, ry]
		+ "────────────────────────────────────────\n"
		+ ",  /  .    prev / next building\n"
		+ "I / K     Z axis  (fwd / back)\n"
		+ "J / L     X axis  (left / right)\n"
		+ "U / O     Y axis  (up / down)\n"
		+ "N / M     rotate Y  (−15° / +15°)\n"
		+ "SHIFT     hold for ×10 step size"
	)

func _update_indicator() -> void:
	if _indicator and is_instance_valid(_indicator):
		_indicator.queue_free()
	_indicator = null
	if not _active or _buildings.is_empty():
		return
	var node: Node3D = _buildings[_idx]
	if not is_instance_valid(node):
		return
	var lbl := Label3D.new()
	lbl.text          = "▼  [%d]  %s  ▼" % [_idx + 1, node.name]
	lbl.billboard     = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.render_priority = 1
	lbl.font_size     = 48
	lbl.modulate      = Color(1.0, 0.95, 0.0)
	lbl.outline_size  = 8
	get_parent().add_child(lbl)
	lbl.global_position = node.global_position + Vector3(0, 8.0, 0)
	_indicator = lbl

# ── input ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	# B toggles the placer
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			_toggle()
			get_viewport().set_input_as_handled()
			return

	if not _active or _buildings.is_empty():
		return
	if not (event is InputEventKey and event.pressed):
		return

	# Consume the event so it doesn't reach the player
	get_viewport().set_input_as_handled()

	var step  := STEP_LG if Input.is_key_pressed(KEY_SHIFT) else STEP_SM
	var node  : Node3D = _buildings[_idx]

	match event.keycode:
		# ── cycle buildings (no echo repeat) ──────────────────────────────
		KEY_COMMA:
			if not event.echo:
				_idx = (_idx - 1 + _buildings.size()) % _buildings.size()
				_refresh()
			return
		KEY_PERIOD:
			if not event.echo:
				_idx = (_idx + 1) % _buildings.size()
				_refresh()
			return
		# ── print (no echo repeat) ─────────────────────────────────────────
		KEY_P:
			if not event.echo:
				_print_all()
			return
		# ── movement (echo = smooth repeat while held) ─────────────────────
		KEY_I: node.global_position.z -= step
		KEY_K: node.global_position.z += step
		KEY_J: node.global_position.x -= step
		KEY_L: node.global_position.x += step
		KEY_U: node.global_position.y += step
		KEY_O: node.global_position.y -= step
		KEY_N: node.rotation_degrees.y -= ROT_STEP
		KEY_M: node.rotation_degrees.y += ROT_STEP
		_: return

	# Move the floating label with the building
	if _indicator and is_instance_valid(_indicator):
		_indicator.global_position = node.global_position + Vector3(0, 8.0, 0)
	_refresh()

# ── helpers ───────────────────────────────────────────────────────────────────

func _toggle() -> void:
	_active = not _active
	_panel.visible = _active
	# Freeze player movement while placer is open (camera look still works)
	var player = get_parent().get_node_or_null("Player")
	if player:
		player.set_physics_process(not _active)
	if _active:
		_collect()
	else:
		_update_indicator()   # hides the Label3D

func _print_all() -> void:
	print("=== PLACER: ALL BUILDING POSITIONS ===")
	for i in _buildings.size():
		var n: Node3D = _buildings[i]
		if not is_instance_valid(n):
			continue
		var p  := n.global_position
		var ry := n.rotation_degrees.y
		print("[%d] %-40s  Vector3(%.3f, %.3f, %.3f)   rotY=%.1f" % [
			i + 1, n.name, p.x, p.y, p.z, ry
		])
	print("======================================")
