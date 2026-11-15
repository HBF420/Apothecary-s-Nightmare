extends StaticBody3D

var _chillis: Array = []

func setup(rack_node: Node):
	_collect_chillis(rack_node)

func _collect_chillis(node: Node):
	for child in node.get_children():
		var n = child.name.to_lower()
		if n.begins_with("chilli ") and not "mesh" in n:
			_chillis.append(child)
		else:
			_collect_chillis(child)

func get_interact_label(_player = null) -> String:
	if _chillis.size() > 0:
		return "Take Chilli [E]"
	return ""

func interact(player):
	if _chillis.is_empty():
		return

	var chilli_node = _chillis.pop_back()
	var mesh_res: Mesh = null
	for child in chilli_node.get_children():
		if child is MeshInstance3D:
			mesh_res = child.mesh
			break
	chilli_node.queue_free()

	var item = StaticBody3D.new()
	item.set_script(load("res://scripts/item.gd"))
	item.set("item_type", "chilli")
	item.set("display_name", "Chilli")

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.06, 0.12, 0.06)
	col.shape = shape
	item.add_child(col)

	if mesh_res:
		var vis = MeshInstance3D.new()
		vis.mesh = mesh_res
		item.add_child(vis)

	get_parent().add_child(item)
	item.global_position = global_position
	player.pick_up_item(item)
