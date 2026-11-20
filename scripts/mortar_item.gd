extends StaticBody3D

var item_type: String = "mortar"
var display_name: String = "Mortar"
var contents: Array = []
var _powder_mesh: MeshInstance3D = null

func setup(glb_instance: Node):
	_powder_mesh = _find_named(glb_instance, "MortarPowder")
	if _powder_mesh:
		_powder_mesh.visible = false

func _find_named(node: Node, target: String) -> MeshInstance3D:
	if node.name == target and node is MeshInstance3D:
		return node
	for child in node.get_children():
		var r = _find_named(child, target)
		if r:
			return r
	return null

func _update_powder():
	if not _powder_mesh:
		return
	if contents.is_empty():
		_powder_mesh.visible = false
		return
	_powder_mesh.visible = true
	var mat = StandardMaterial3D.new()
	var has_herbs  = "herbs"  in contents
	var has_chilli = "chilli" in contents
	if has_herbs and has_chilli:
		mat.albedo_color = Color(0.95, 0.5, 0.0)   # orange
	elif has_herbs:
		mat.albedo_color = Color(0.25, 0.75, 0.2)  # green
	else:
		mat.albedo_color = Color(0.85, 0.2, 0.05)  # red
	_powder_mesh.material_override = mat

func get_interact_label(player = null) -> String:
	if player and player.has_item_type("herbs") and not "herbs" in contents:
		return "Add Leaf to Mortar [E]"
	if player and player.has_item_type("chilli") and not "chilli" in contents:
		return "Add Chilli to Mortar [E]"
	return "Pick up Mortar [E]"

func interact(player):
	if player.has_item_type("herbs") and not "herbs" in contents:
		player.remove_item_type("herbs")
		contents.append("herbs")
		_update_powder()
	elif player.has_item_type("chilli") and not "chilli" in contents:
		player.remove_item_type("chilli")
		contents.append("chilli")
		_update_powder()
	else:
		player.pick_up_item(self)
		position = Vector3(0, -0.15, 0)

func empty_contents():
	contents.clear()
	_update_powder()

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
