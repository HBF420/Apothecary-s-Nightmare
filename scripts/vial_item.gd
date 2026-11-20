extends StaticBody3D

var item_type: String = "vial"
var display_name: String = "Vial"
var _liquid_mesh: MeshInstance3D = null

func setup(glb_instance: Node):
	_liquid_mesh = _find_named(glb_instance, "VialLiquid")
	if _liquid_mesh:
		_liquid_mesh.visible = false

func _find_named(node: Node, target: String) -> MeshInstance3D:
	if node.name == target and node is MeshInstance3D:
		return node
	for child in node.get_children():
		var r = _find_named(child, target)
		if r:
			return r
	return null

func get_interact_label(_player = null) -> String:
	return "Pick up " + display_name + " [E]"

func interact(player):
	player.pick_up_item(self)
	position = Vector3(0, -0.15, 0)

func fill():
	item_type = "plague_potion"
	display_name = "Plague Potion"
	if _liquid_mesh:
		_liquid_mesh.visible = true
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.95, 0.4, 0.0)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_liquid_mesh.material_override = mat

func reset_to_empty():
	item_type = "vial"
	display_name = "Vial"
	if _liquid_mesh:
		_liquid_mesh.visible = false

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
