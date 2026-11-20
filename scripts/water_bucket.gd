extends StaticBody3D

var water_level: int = 10
var _water_node: Node = null

func _ready():
	var glb = load("res://models/medieval-oak-water-bucket.glb")
	if not glb:
		return
	var visual = glb.instantiate()
	visual.scale = Vector3(3.0, 3.0, 3.0)
	_strip_bad_meshes(visual)
	add_child(visual)
	_water_node = visual.find_child("BucketWater", true, false)
	_update_water_visual()

func _update_water_visual():
	if not _water_node:
		return
	for i in range(1, 11):
		var node = _water_node.get_node_or_null("WaterLevel%02d" % i)
		if node:
			node.visible = (i <= water_level)

func get_interact_label(player = null) -> String:
	if water_level <= 0:
		return "Bucket empty"
	if player:
		for item in player.held_items:
			if item.get("item_type") == "watering_cup_empty":
				return "Refill cup [E]"
	return ""

func interact(player):
	if water_level <= 0:
		return
	for item in player.held_items:
		if item.get("item_type") == "watering_cup_empty":
			item.refill()
			water_level -= 1
			_update_water_visual()
			break

func _strip_bad_meshes(node: Node):
	if node is MeshInstance3D and node.mesh:
		var aabb = node.mesh.get_aabb()
		if aabb.size.x > 1.0 or aabb.size.y > 1.0 or aabb.size.z > 1.0:
			node.visible = false
	for child in node.get_children():
		_strip_bad_meshes(child)

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
