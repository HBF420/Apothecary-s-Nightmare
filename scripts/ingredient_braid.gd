extends StaticBody3D

var _item_type: String
var _display_name: String
var _items: Array = []

func init_braid(itype: String, dname: String, items: Array):
	_item_type = itype
	_display_name = dname
	_items = items.duplicate()

func get_interact_label(_player = null) -> String:
	if _items.size() > 0:
		return "Take " + _display_name + " [E]"
	return ""

func interact(player):
	if _items.is_empty():
		return
	var item_node = _items.pop_back()
	var mesh_res: Mesh = null
	for child in item_node.get_children():
		if child is MeshInstance3D:
			mesh_res = child.mesh
			break
	item_node.queue_free()

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
