extends StaticBody3D

const ForgeStation = preload("res://scripts/forge_station.gd")

var _station: Node3D = null
var _player_ref = null

func _ready() -> void:
	collision_layer = 3
	collision_mask = 0

	_station = Node3D.new()
	_station.set_script(ForgeStation)

	var forge_glb = load("res://models/forge.glb")
	if forge_glb:
		var m = forge_glb.instantiate()
		m.name = "Forge"
		_station.add_child(m)

	var pot_glb = load("res://models/boiling_pot_lightblue.glb")
	if pot_glb:
		var p = pot_glb.instantiate()
		p.name = "Pot"
		_station.add_child(p)

	var glow = OmniLight3D.new()
	glow.name = "FireGlow"
	glow.position = Vector3(0.504, 0.68, 0.55)
	glow.light_color = Color(1, 0.46, 0.16, 1)
	glow.omni_range = 1.35
	_station.add_child(glow)

	add_child(_station)

	add_to_group("forge_trigger")
	_station.add_to_group("forge_station")
	_station.boil_ready.connect(_on_boil_ready)
	_station.start_ready()

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.2, 2.2, 1.5)
	col.shape = shape
	col.position = Vector3(0, 1.1, 0)
	add_child(col)

func get_interact_label(player = null) -> String:
	if _station == null:
		return ""
	var s = _station
	var P = ForgeStation.Placement
	var F = ForgeStation.Fuel

	# Player is holding the pot and looking at the forge
	if s.placement == P.HELD and player != null and player.hand_position.is_ancestor_of(s.pot):
		return "Hang pot [E]"

	# Firewood in hand — show hearth action regardless of pot position
	if player != null and _get_held_firewood(player) != null:
		if s.fuel == F.COLD:
			var count = _count_held_firewood(player)
			if count >= 3:
				return "Add logs [E]"
			return "Need 3 logs (%d/3)" % count
		if s.fuel == F.LOGS:
			return "Light fire [E]"

	# Pot on hearth
	if s.placement == P.HEARTH:
		if s.doses == 0:
			if player != null and _player_has_water(player):
				return "Fill pot [E]"
			return "Fill with water"
		if s.is_boiling and player != null and _player_has_empty_vial(player):
			return "Draw remedy [E]"
		return "Take pot [E]"

	# Pot on hook
	if s.placement == P.HOOK or s.placement == P.REST:
		if s.fuel == F.EMBERS:
			return "Place pot on ashes [E]"
		match s.fuel:
			F.COLD: return "Take pot [E]"
			F.LOGS: return "Light fire [E]"
			F.FIRE: return "Burning…"
		return "Take pot [E]"

	# Fallback hearth state
	match s.fuel:
		F.COLD: return "Add firewood to load"
		F.LOGS: return "Light fire [E]"
		F.FIRE: return "Burning…"
		F.EMBERS: return "Embers — place a filled pot"
	return ""

func interact(player) -> void:
	if _station == null:
		return
	var s = _station
	var P = ForgeStation.Placement
	var F = ForgeStation.Fuel
	_player_ref = player

	# Holding the pot — always hang it back on the hook
	if s.placement == P.HELD and player.hand_position.is_ancestor_of(s.pot):
		s.hang_pot(s.pot)
		player._active_forge = null
		return

	# Firewood in hand — hearth actions take priority over pot taking
	var log = _get_held_firewood(player)
	if log != null:
		if s.fuel == F.COLD:
			if _count_held_firewood(player) >= 3 and s.add_logs():
				for child in player.hand_position.get_children().duplicate():
					if child.is_in_group("held_firewood"):
						child.queue_free()
		elif s.fuel == F.LOGS:
			s.light_logs()
		return

	# Light loaded hearth before allowing pot pickup
	if s.fuel == F.LOGS:
		s.light_logs()
		return

	# Pot on hook/rest — place on ashes if embers, otherwise take
	if s.placement == P.HOOK or s.placement == P.REST:
		if s.fuel == F.EMBERS:
			s.place_pot_on_ashes(s.pot)
		elif s.take_pot(player.hand_position):
			player._active_forge = self
		return

	# Take pot from hearth / fill / draw remedy
	if s.placement == P.HEARTH:
		if s.doses == 0:
			var water = _get_held_water(player)
			if water != null and s.fill_pot():
				water.use_water()
			return
		if s.is_boiling:
			var vial = _get_held_empty_vial(player)
			if vial != null:
				var result = s.draw_vial(true)
				if not result.is_empty():
					vial.fill_with_remedy(result.remedy_id, result.color)
				return
		# Pot is full but player has no vial (or not boiling yet) — pick it up
		if s.take_pot(player.hand_position):
			player._active_forge = self
		return


# Called by well_node when bucket is poured near the forge
func try_fill_from_pour() -> bool:
	if _station == null:
		return false
	return _station.fill_pot()

func _get_held_firewood(player) -> Node3D:
	for child in player.hand_position.get_children():
		if child.is_in_group("held_firewood"):
			return child
	return null

func _count_held_firewood(player) -> int:
	var n := 0
	for child in player.hand_position.get_children():
		if child.is_in_group("held_firewood"):
			n += 1
	return n

func _player_has_water(player) -> bool:
	return _get_held_water(player) != null

func _get_held_water(player) -> Node3D:
	for child in player.hand_position.get_children():
		if child.get("is_full") == true:
			return child
	for item in player.held_items:
		if item.get("is_full") == true:
			return item
	return null

func _player_has_empty_vial(player) -> bool:
	return _get_held_empty_vial(player) != null

func _get_held_empty_vial(player) -> Node3D:
	for item in player.held_items:
		if item.get("item_type") == "vial" and item.has_method("fill_with_remedy"):
			return item
	return null

func _on_boil_ready() -> void:
	pass

static var _outline_mat: ShaderMaterial = null
var _hover_meshes: Array = []

func _get_outline_mat() -> ShaderMaterial:
	if _outline_mat:
		return _outline_mat
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_front, unshaded;
void vertex() { VERTEX += NORMAL * 0.004; }
void fragment() { ALBEDO = vec3(1.0, 0.85, 0.3); }
"""
	_outline_mat = ShaderMaterial.new()
	_outline_mat.shader = shader
	return _outline_mat

func set_hover(val: bool) -> void:
	if val:
		_hover_meshes.clear()
		_collect_hover_meshes(self)
	for mi in _hover_meshes:
		if not is_instance_valid(mi):
			continue
		if val:
			if mi.material_override == null:
				var src = mi.get_active_material(0)
				if src != null:
					var dup = src.duplicate() as Material
					dup.next_pass = _get_outline_mat()
					mi.material_override = dup
		else:
			if mi.material_override != null:
				mi.material_override.next_pass = null
			mi.material_override = null
	if not val:
		_hover_meshes.clear()

func _collect_hover_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		_hover_meshes.append(node)
	for child in node.get_children():
		_collect_hover_meshes(child)
