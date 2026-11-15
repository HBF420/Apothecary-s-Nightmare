extends StaticBody3D

var _blades: Array = []

func setup(plant_node: Node):
	for child in plant_node.get_children():
		if "blade" in child.name.to_lower():
			_blades.append(child)

func get_interact_label(_player = null) -> String:
	if _blades.size() > 0:
		return "Harvest (Snake Plant) [E]"
	return ""

func interact(player):
	if _blades.is_empty():
		return

	var blade = _blades.pop_back()
	var mesh_res: Mesh = null
	if blade is MeshInstance3D:
		mesh_res = blade.mesh
	blade.queue_free()

	# Build a held leaf item
	var leaf = StaticBody3D.new()
	leaf.set_script(load("res://scripts/item.gd"))
	leaf.set("item_type", "herbs")
	leaf.set("display_name", "Snake Plant Leaf")

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.05, 0.3, 0.02)
	col.shape = shape
	leaf.add_child(col)

	if mesh_res:
		var vis = MeshInstance3D.new()
		vis.mesh = mesh_res
		vis.scale = Vector3(1.5, 1.5, 1.5)
		vis.rotation_degrees = Vector3(0, 0, -20)
		vis.position = Vector3(0, -0.4, 0)
		leaf.add_child(vis)

	get_parent().add_child(leaf)
	leaf.global_position = global_position
	player.pick_up_item(leaf)
