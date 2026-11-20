extends StaticBody3D

var _item_type: String
var _display_name: String
var _items: Array = []
var _hidden: Array = []
var _braid_node: Node = null
var _all_meshes: Array = []

static var _outline_mat: ShaderMaterial = null

func _get_outline_mat() -> ShaderMaterial:
	if _outline_mat != null:
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

func init_braid(itype: String, dname: String, items: Array, braid_node: Node):
	_item_type = itype
	_display_name = dname
	_items = items.duplicate()
	_braid_node = braid_node
	_collect_meshes(braid_node)

func _collect_meshes(node: Node):
	if node is MeshInstance3D:
		_all_meshes.append(node)
	for child in node.get_children():
		_collect_meshes(child)

# Called by player.gd whenever this trigger enters or leaves the crosshair.
func set_hover(val: bool):
	for mi in _all_meshes:
		if not is_instance_valid(mi):
			continue
		if val and not _items.is_empty():
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

func get_interact_label(player = null) -> String:
	if player != null and player.has_item_type(_item_type):
		return "Return " + _display_name + " [E]"
	if _items.size() > 0:
		return "Take " + _display_name + " [E]"
	return ""

func interact(player):
	if player != null and player.has_item_type(_item_type):
		return_item(player)
		return
	if _items.is_empty():
		return
	var item_node = _items.pop_back()
	# Grab the mesh from the first MeshInstance3D child for the held visual.
	var mesh_res: Mesh = null
	for child in item_node.get_children():
		if child is MeshInstance3D:
			mesh_res = child.mesh
			break
	item_node.hide()
	_hidden.append(item_node)
	set_hover(false)

	var item = StaticBody3D.new()
	item.set_script(load("res://scripts/item.gd"))
	item.set("item_type", _item_type)
	item.set("display_name", _display_name)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.08, 0.12, 0.08)
	col.shape = shape
	item.add_child(col)

	if mesh_res:
		var vis = MeshInstance3D.new()
		vis.mesh = mesh_res
		item.add_child(vis)

	get_parent().get_parent().add_child(item)
	item.global_position = global_position
	player.pick_up_item(item)

func return_item(player):
	player.remove_item_type(_item_type)
	if not _hidden.is_empty():
		var node = _hidden.pop_back()
		node.show()
		_items.append(node)
