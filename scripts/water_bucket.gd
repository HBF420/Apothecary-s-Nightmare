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
