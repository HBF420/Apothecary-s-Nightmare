extends StaticBody3D

const FirewoodRack = preload("res://scripts/firewood_rack.gd")

var _rack: Node3D = null

func _ready() -> void:
	collision_layer = 3
	collision_mask = 0

	_rack = Node3D.new()
	_rack.set_script(FirewoodRack)
	var glb = load("res://models/medieval-firewood-rack.glb")
	if glb:
		var model = glb.instantiate()
		model.name = "Model"
		_rack.add_child(model)
	add_child(_rack)

	# Interaction collider matching the rack's BoxShape3D from the README
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.76, 0.60, 0.39)
	col.shape = shape
	col.position = Vector3(0, 0.30, 0)
	add_child(col)

func get_interact_label(_player = null) -> String:
	if _rack == null:
		return ""
	return _rack.prompt() + (" [E]" if _rack.remaining_count() > 0 else "")

func interact(player) -> void:
	if _rack == null:
		return
	_rack.interact(player.hand_position)

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
