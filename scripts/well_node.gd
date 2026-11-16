extends StaticBody3D

const GrimWell = preload("res://scripts/grim_well.gd")

var _well: Node3D = null
var _player_ref = null

func _ready():
	collision_layer = 2
	collision_mask = 0

	# Build the animated well node programmatically
	_well = Node3D.new()
	_well.set_script(GrimWell)
	var glb = load("res://models/grim-medieval-well.glb")
	if glb:
		var model = glb.instantiate()
		model.name = "Model"
		_well.add_child(model)
	add_child(_well)
	_well.bucket_poured.connect(_on_bucket_poured)
	_well.state_changed.connect(_on_state_changed)

	# Dark water surface cap — hides ground/grass visible through the shaft opening
	var cap = MeshInstance3D.new()
	var cap_mesh = CylinderMesh.new()
	cap_mesh.height = 0.02
	cap_mesh.top_radius = 0.62
	cap_mesh.bottom_radius = 0.62
	cap_mesh.radial_segments = 20
	cap.mesh = cap_mesh
	var cap_mat = StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.04, 0.06, 0.08)  # dark water
	cap_mat.roughness = 0.3
	cap_mat.metallic = 0.1
	cap.material_override = cap_mat
	cap.position = Vector3(0, 0.08, 0)  # just above grass plane, inside shaft
	add_child(cap)

	# Cylinder collision for raycast interaction + physical rim
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.height = 1.2
	shape.radius = 0.65
	col.shape = shape
	col.position = Vector3(0, 0.6, 0)
	add_child(col)

func get_interact_label(_player = null) -> String:
	if _well == null:
		return ""
	var s = _well.state
	# Busy animating — show status only, no [E]
	if s == GrimWell.State.LOWERING or s == GrimWell.State.FILLING \
			or s == GrimWell.State.RAISING or s == GrimWell.State.POURING:
		return _well.prompt()
	return _well.prompt() + " [E]"

func interact(player) -> void:
	if _well == null:
		return
	_player_ref = player
	_well.interact(player.hand_position)

func pour(player) -> void:
	if _well == null or _well.state != GrimWell.State.HELD_FULL:
		return
	var cam: Camera3D = player.camera
	var from = cam.global_position
	var to = from - cam.global_basis.z * 3.0
	var space = player.get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [player.get_rid()])
	var hit = space.intersect_ray(params)
	var target: Vector3 = hit.get("position", Vector3(to.x, 0.02, to.z))
	_well.pour_bucket(target)

func is_held_full() -> bool:
	return _well != null and _well.state == GrimWell.State.HELD_FULL

func is_bucket_held() -> bool:
	return _well != null and (_well.state == GrimWell.State.HELD_FULL \
			or _well.state == GrimWell.State.HELD_EMPTY)

func _on_state_changed(next_state: int) -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	if next_state == GrimWell.State.HELD_FULL:
		_player_ref._active_well = self
	elif next_state == GrimWell.State.DOCKED_EMPTY or next_state == GrimWell.State.DOCKED_FULL:
		_player_ref._active_well = null

func _on_bucket_poured(target: Vector3) -> void:
	# Water the nearest planter pot within reach of the pour target
	var closest = null
	var closest_dist = 1.8
	for pot in get_tree().get_nodes_in_group("planter_pot"):
		var d = pot.global_position.distance_to(target)
		if d < closest_dist:
			closest_dist = d
			closest = pot
	if closest:
		closest.watered = true
		closest.missed_water_count = 0
