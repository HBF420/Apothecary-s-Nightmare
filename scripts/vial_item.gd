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
