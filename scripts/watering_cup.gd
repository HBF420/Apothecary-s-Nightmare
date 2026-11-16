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
