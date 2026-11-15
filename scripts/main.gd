extends Node3D

const PLAYER_SPAWN = Vector3(0, 0.1, 1)

@export_group("Counter")
@export var counter_scale: float = 0.00052
@export var counter_pos: Vector3 = Vector3(-0.75, -0.5, 0.15)

@export_group("Workbench Table")
@export var workbench_scale: float = 1.0
@export var workbench_pos: Vector3 = Vector3(0, 0, 0)

@export_group("Mortar")
@export var mortar_scale: float = 0.064
@export var mortar_pos: Vector3 = Vector3(-0.257, -0.861, -0.065)

@export_group("Customer")
@export var customer_scale: float = 1.0
@export var customer_pos: Vector3 = Vector3(0, -0.9, 0)

func _ready():
	var music = load("res://audio/music.mp3")
	if music:
		music.loop = true
		var music_player = AudioStreamPlayer.new()
		music_player.stream = music
		music_player.volume_db = -6.0
		add_child(music_player)
		music_player.play()
	var player = $Player
	if player:
		player.add_to_group("player")
		player.register_crafting_spot($CraftingSpot)
	_apply_floor_texture()
	_apply_wall_texture()
	_apply_street_texture()
	_place_counter()
	_place_workbench_model()
	_place_mortar_model()
	_place_herb_model()
	_place_customer()
	_place_door()
	_place_windows()

func _apply_floor_texture():
	var texture = load("res://models/dark_wooden_floor__tile_texture_0.png")
	if not texture:
		return
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.uv1_scale = Vector3(6, 6, 1)
	mat.roughness = 0.8
	$Floor/Mesh.material_override = mat

func _apply_wall_texture():
	var albedo = load("res://models/dark_log_wall__tile_texture_0.png")
	var normal = load("res://models/dark_log_wall__tile_texture_2.png")
	var roughness = load("res://models/dark_log_wall__tile_texture_1.png")

	var mat = StandardMaterial3D.new()
	mat.albedo_texture = albedo
	mat.normal_enabled = true
	mat.normal_texture = normal
	mat.roughness_texture = roughness
	mat.uv1_scale = Vector3(5, 2.5, 1)
	mat.roughness = 1.0
	for wall in [$WallBack/Mesh, $WallLeft/Mesh, $WallRight/Mesh, $WallFrontLeft/Mesh, $WallFrontRight/Mesh]:
		wall.material_override = mat

	# WallAboveDoor is 2×1m — scale UVs proportionally so planks match adjacent walls
	var mat_above = StandardMaterial3D.new()
	mat_above.albedo_texture = albedo
	mat_above.normal_enabled = true
	mat_above.normal_texture = normal
	mat_above.roughness_texture = roughness
	mat_above.uv1_scale = Vector3(2.1, 0.567, 1)
	mat_above.roughness = 1.0
	$WallAboveDoor/Mesh.material_override = mat_above

func _apply_street_texture():
	var albedo = load("res://models/gravel_macro__tile_texture_0.jpg")
	var roughness = load("res://models/gravel_macro__tile_texture_1.png")
	var normal = load("res://models/gravel_macro__tile_texture_2.jpg")
	if not albedo:
		return
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = albedo
	mat.roughness_texture = roughness
	mat.normal_enabled = true
	mat.normal_texture = normal
	mat.uv1_scale = Vector3(30, 8, 1)
	mat.roughness = 1.0
	$Street/Mesh.material_override = mat

func _place_counter():
	var glb = load("res://models/counter.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(counter_scale, counter_scale, counter_scale)
	instance.position = counter_pos
	$Counter/Mesh.visible = false
	$Counter.add_child(instance)

func _place_workbench_model():
	var glb = load("res://models/old_wooden_dinner_table.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(workbench_scale, workbench_scale, workbench_scale)
	instance.position = workbench_pos
	$Workbench/Mesh.visible = false
	$Workbench.add_child(instance)

func _place_mortar_model():
	var glb = load("res://models/mortar.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(mortar_scale, mortar_scale, mortar_scale)
	instance.position = mortar_pos
	$Mortar/Mesh.visible = false
	$Mortar.add_child(instance)

func _place_herb_model():
	pass

func _place_windows():
	var glb = load("res://models/window2.glb")
	if not glb:
		return
	var albedo = load("res://models/dark_log_wall__tile_texture_0.png")
	var normal_tex = load("res://models/dark_log_wall__tile_texture_2.png")
	var roughness_tex = load("res://models/dark_log_wall__tile_texture_1.png")
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = albedo
	mat.normal_enabled = true
	mat.normal_texture = normal_tex
	mat.roughness_texture = roughness_tex
	mat.uv1_scale = Vector3(5, 2.5, 1)
	mat.roughness = 1.0
	for panel_x in [-3.525, 3.525]:
		var old_wall = $WallFrontLeft if panel_x < 0 else $WallFrontRight
		old_wall.get_node("Mesh").visible = false
		for child in old_wall.get_children():
			if child is CollisionShape3D:
				child.disabled = true
		var csg = CSGCombiner3D.new()
		csg.use_collision = true
		csg.position = Vector3(panel_x, 2, 5)
		add_child(csg)
		var wall_box = CSGBox3D.new()
		wall_box.size = Vector3(4.95, 4, 0.2)
		wall_box.material = mat
		csg.add_child(wall_box)
		# Rectangular hole — sill at world Y=1.1, csg origin at Y=2, local Y=-0.9
		var hole = CSGCombiner3D.new()
		hole.operation = CSGShape3D.OPERATION_SUBTRACTION
		hole.position = Vector3(0, -0.9, 0)
		csg.add_child(hole)
		var rect = CSGBox3D.new()
		rect.size = Vector3(1.40, 1.74, 0.3)
		rect.position = Vector3(0, 0.87, 0)
		hole.add_child(rect)
		var win = glb.instantiate()
		win.scale = Vector3(0.25, 0.25, 0.25)
		add_child(win)
		win.global_position = Vector3(panel_x, 1.1, 5.0)
		win.rotation_degrees = Vector3(0, 180, 0)
		_strip_collision(win)


func _place_customer():
	var glb = load("res://models/Walking.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(customer_scale, customer_scale, customer_scale)
	instance.position = customer_pos
	instance.rotation_degrees = Vector3(0, 180, 0)
	$Customer/Mesh.visible = false
	$Customer.add_child(instance)
	var anim_player = _find_node_by_name(instance, "AnimationPlayer")
	if anim_player:
		$Customer.set_animation_player(anim_player)

func _place_door():
	var glb = load("res://models/simple_room_door.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.rotation_degrees = Vector3(0, -90, 0)
	instance.scale = Vector3(0.7, 0.7, 0.7)
	add_child(instance)
	instance.global_position = Vector3(-0.658, 0, 5.0)
	_strip_collision(instance)

	var door_node = _find_node_by_name(instance, "Door")
	if not door_node:
		return

	# Re-parent Handle under Door so it moves with the panel
	var handle_node = _find_node_by_name(instance, "Handle")
	if handle_node:
		var saved_transform = handle_node.global_transform
		handle_node.get_parent().remove_child(handle_node)
		door_node.add_child(handle_node)
		handle_node.global_transform = saved_transform

	var pivot = Node3D.new()
	pivot.set_script(preload("res://scripts/door_pivot.gd"))
	pivot.add_to_group("door_pivot")
	pivot.blocker = $DoorBlocker
	pivot.door_node = door_node
	add_child(pivot)

	var trigger = StaticBody3D.new()
	trigger.set_script(preload("res://scripts/door_handle.gd"))
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.5, 3.5, 0.5)
	col.shape = shape
	col.position = Vector3(0.0, 1.5, 0.0)
	trigger.add_child(col)
	trigger.collision_layer = 2
	trigger.collision_mask = 0
	trigger.pivot = pivot
	add_child(trigger)
	trigger.global_position = Vector3(0.0, 0.0, 5.0)

func _strip_collision(node: Node):
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
	for child in node.get_children():
		_strip_collision(child)

func _find_node_by_name(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var result = _find_node_by_name(child, target)
		if result:
			return result
	return null

func _on_kill_zone_body_entered(body):
	if body.is_in_group("player"):
		body.global_position = PLAYER_SPAWN
		body.velocity = Vector3.ZERO
