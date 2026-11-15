extends StaticBody3D

var has_contents: bool = false
var _liquid_mesh: MeshInstance3D = null

func setup(glb_instance: Node):
	_liquid_mesh = _find_named(glb_instance, "Water | rippling surface")
	if _liquid_mesh:
		_set_material(Color(0.2, 0.3, 0.45, 0.85))  # water

func _find_named(node: Node, target: String) -> MeshInstance3D:
	if node.name == target and node is MeshInstance3D:
		return node
	for child in node.get_children():
		var r = _find_named(child, target)
		if r:
			return r
	return null

func _set_material(color: Color):
	if not _liquid_mesh:
		return
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_liquid_mesh.material_override = mat

func get_interact_label(player = null) -> String:
	if player == null:
		return ""
	for item in player.held_items:
		if item.get("item_type") == "mortar" and item.has_method("empty_contents"):
			if not item.contents.is_empty():
				return "Pour into Pot [E]"
	if has_contents and player.has_item_type("vial"):
		return "Fill Vial [E]"
	return ""

func interact(player):
	for item in player.held_items:
		if item.get("item_type") == "mortar" and item.has_method("empty_contents"):
			if not item.contents.is_empty():
				item.empty_contents()
				has_contents = true
				_set_material(Color(0.95, 0.45, 0.0, 0.85))  # orange potion
				return
	if has_contents and player.has_item_type("vial"):
		for item in player.held_items:
			if item.get("item_type") == "vial" and item.has_method("fill"):
				item.fill()
				has_contents = false
				_set_material(Color(0.2, 0.3, 0.45, 0.85))   # back to water
				return
