extends Node3D

signal state_changed(next_state: int)
signal bucket_poured(target: Vector3)

enum State { DOCKED_EMPTY, LOWERING, FILLING, RAISING, DOCKED_FULL, HELD_FULL, POURING, HELD_EMPTY }

@export var lower_seconds := 2.4
@export var fill_seconds := 1.7
@export var raise_seconds := 3.6
@export var pour_seconds := .65
@export var hand_offset := Vector3(0, -.23, 0)

const BUCKET = preload("res://models/well-bucket.glb")
const ROPE_RADIUS := .009
@onready var windlass := $Model.find_child("Windlass", true, false) as Node3D
@onready var rope_top := $Model.find_child("RopeTop", true, false) as Node3D
@onready var rest := $Model.find_child("BucketRest", true, false) as Node3D
@onready var depth := $Model.find_child("BucketDepth", true, false) as Node3D
@onready var interact_at := $Model.find_child("WellInteract", true, false) as Node3D

var state: State = State.DOCKED_EMPTY
var bucket: Node3D
var bucket_water: MeshInstance3D
var bucket_grip: Node3D
var rope: MeshInstance3D
var rope_mesh: CylinderMesh
var _hand_guard: Node
var _full := false

func _ready() -> void:
	bucket = BUCKET.instantiate() as Node3D
	add_child(bucket)
	bucket.global_transform = rest.global_transform
	bucket_water = bucket.find_child("BucketWater", true, false) as MeshInstance3D
	bucket_grip = bucket.find_child("BucketGrip", true, false) as Node3D
	bucket_water.hide()
	rope = MeshInstance3D.new()
	rope.name = "WorkingHempRope"
	rope_mesh = CylinderMesh.new()
	rope_mesh.radial_segments = 10
	rope_mesh.top_radius = ROPE_RADIUS
	rope_mesh.bottom_radius = ROPE_RADIUS
	rope_mesh.height = 1.0
	rope.mesh = rope_mesh
	var hemp := StandardMaterial3D.new()
	hemp.albedo_color = Color("#51391d")
	hemp.roughness = .93
	rope.material_override = hemp
	add_child(rope)
	_sync_rope()

func prompt() -> String:
	match state:
		State.DOCKED_EMPTY: return "Draw water"
		State.LOWERING: return "Lowering bucket…"
		State.FILLING: return "Filling bucket…"
		State.RAISING: return "Drawing water…"
		State.DOCKED_FULL: return "Take full bucket"
		State.HELD_FULL: return "Reattach full bucket"
		State.HELD_EMPTY: return "Reattach empty bucket"
		State.POURING: return "Pouring water…"
	return ""

func interact(hand: Node3D = null) -> bool:
	match state:
		State.DOCKED_EMPTY: return draw_water()
		State.DOCKED_FULL: return take_bucket(hand)
		State.HELD_EMPTY, State.HELD_FULL: return reattach_bucket()
	return false

func draw_water() -> bool:
	if state != State.DOCKED_EMPTY or not is_instance_valid(bucket):
		return false
	_set_state(State.LOWERING)
	var end := to_local(depth.global_position)
	var start := bucket.position
	var turn := windlass.rotation.x
	var travel := start.distance_to(end) / .124
	var motion := create_tween()
	motion.tween_method(_draw_pose.bind(start, end, turn, travel), 0.0, 1.0, lower_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_callback(_set_state.bind(State.FILLING))
	motion.tween_interval(fill_seconds)
	motion.tween_callback(_begin_raising)
	motion.tween_method(_draw_pose.bind(end, start, turn + travel, -travel), 0.0, 1.0, raise_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_callback(_set_state.bind(State.DOCKED_FULL))
	return true

func _draw_pose(fraction: float, a: Vector3, b: Vector3, angle: float, amount: float) -> void:
	bucket.position = a.lerp(b, fraction)
	windlass.rotation.x = angle + amount * fraction
	_sync_rope()

func _begin_raising() -> void:
	_full = true
	bucket_water.show()
	_set_state(State.RAISING)

func take_bucket(hand: Node3D) -> bool:
	if state != State.DOCKED_FULL or not is_instance_valid(hand) or not hand.is_inside_tree():
		return false
	bucket.reparent(hand, false)
	bucket.transform = Transform3D(Basis.IDENTITY, hand_offset)
	_hand_guard = hand
	hand.tree_exiting.connect(_return_before_hand_exits, CONNECT_ONE_SHOT)
	_set_state(State.HELD_FULL)
	_sync_rope()
	return true

func pour_bucket(target: Vector3) -> bool:
	if state != State.HELD_FULL:
		return false
	_set_state(State.POURING)
	var rotation_at_rest := bucket.rotation
	var sequence := create_tween()
	sequence.tween_property(bucket, "rotation:x", rotation_at_rest.x - 1.14, pour_seconds * .37).set_trans(Tween.TRANS_SINE)
	sequence.tween_callback(_spill.bind(target))
	sequence.tween_interval(pour_seconds * .37)
	sequence.tween_property(bucket, "rotation", rotation_at_rest, pour_seconds * .26).set_trans(Tween.TRANS_SINE)
	sequence.tween_callback(_set_state.bind(State.HELD_EMPTY))
	return true

func _spill(target: Vector3) -> void:
	_full = false
	bucket_water.hide()
	var start := bucket.to_global(Vector3(.13,.274,0))
	var effect := Node3D.new()
	var host: Node = get_tree().current_scene
	if host == null: host = self
	host.add_child(effect)
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("#7cabc2")
	water.roughness = .2
	for i in range(13):
		var drop := MeshInstance3D.new()
		var shape := SphereMesh.new()
		shape.radius = .019 + .005 * sin(float(i))
		shape.height = shape.radius * 2
		shape.radial_segments = 8
		shape.rings = 4
		drop.mesh = shape
		drop.material_override = water
		effect.add_child(drop)
		drop.global_position = start
		drop.hide()
		var end := target + Vector3(.092 * sin(i*2.7), 0, .089 * cos(i*3.7))
		_fly_drop(drop, start, end, float(i)*.023)
	get_tree().create_timer(.82).timeout.connect(effect.queue_free)
	bucket_poured.emit(target)

func _fly_drop(drop: Node3D, a: Vector3, b: Vector3, delay: float) -> void:
	var tween := drop.create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(drop.show)
	tween.tween_method(_drop_position.bind(drop, a, b), 0.0, 1.0, .36)
	tween.tween_callback(drop.hide)

func _drop_position(t: float, drop: Node3D, a: Vector3, b: Vector3) -> void:
	drop.global_position = a.lerp(b, t) + Vector3.UP * (.12 * sin(PI * t))

func reattach_bucket() -> bool:
	if state != State.HELD_EMPTY and state != State.HELD_FULL:
		return false
	_dock()
	return true

func _return_before_hand_exits() -> void:
	if is_inside_tree() and is_instance_valid(bucket):
		_dock()

func _dock() -> void:
	if is_instance_valid(_hand_guard) and _hand_guard.tree_exiting.is_connected(_return_before_hand_exits):
		_hand_guard.tree_exiting.disconnect(_return_before_hand_exits)
	_hand_guard = null
	bucket.reparent(self, false)
	bucket.global_transform = rest.global_transform
	_set_state(State.DOCKED_FULL if _full else State.DOCKED_EMPTY)
	_sync_rope()

func _sync_rope() -> void:
	var attached := bucket.get_parent() == self
	rope.visible = attached
	if not attached:
		return
	var a := to_local(rope_top.global_position)
	var b := to_local(bucket_grip.global_position)
	rope.position = a.lerp(b,.5)
	rope_mesh.height = maxf(.001, a.distance_to(b))
	rope.quaternion = Quaternion(Vector3.UP, (a-b).normalized())

func _set_state(next_state: State) -> void:
	state = next_state
	state_changed.emit(state)
