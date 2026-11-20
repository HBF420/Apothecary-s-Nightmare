extends StaticBody3D

var item_type: String = "watering_cup_full"
var display_name: String = "Watering Cup"
var is_full: bool = true
var water_uses: int = 3

var _visual: Node = null

func _ready():
	_load_visual()

func _load_visual():
	if _visual:
		_visual.queue_free()
		_visual = null
	var path = "res://models/medieval-copper-watering-cup-full.glb" if is_full \
			else "res://models/medieval-copper-watering-cup.glb"
	var glb = load(path)
	if not glb:
		return
	_visual = glb.instantiate()
	_visual.scale = Vector3(1.5, 1.5, 1.5)
	_visual.position = Vector3.ZERO
	_strip_collision(_visual)
	_strip_bad_meshes(_visual)
	add_child(_visual)

func get_interact_label(_player = null) -> String:
	return "Pick up %s [E]" % display_name

func interact(player):
	player.pick_up_item(self)
	position.y = -0.15                        # lower in hand
	rotation_degrees = Vector3(-25, 105, 15)

func use_water():
	water_uses -= 1
	if water_uses <= 0:
		is_full = false
		item_type = "watering_cup_empty"
		display_name = "Watering Cup (empty)"
		_load_visual()

func refill():
	is_full = true
	water_uses = 3
	item_type = "watering_cup_full"
	display_name = "Watering Cup"
	_load_visual()

func _strip_collision(node: Node):
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
	for child in node.get_children():
		_strip_collision(child)

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
