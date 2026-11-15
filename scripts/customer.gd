extends CharacterBody3D

enum State { OUTSIDE, WALKING, ASKING, HAPPY }

const WALK_SPEED = 2.5
const ARRIVE_DIST = 0.3

var state: State = State.OUTSIDE
var dialogue_label: Label3D = null
var _waypoints: Array = []
var _waypoint_idx: int = 0
var _walk_mode: String = ""
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var anim_player: AnimationPlayer = null

func set_animation_player(player: AnimationPlayer):
	anim_player = player
	var anim = anim_player.get_animation("Armature|mixamo_com|Layer0")
	if not anim:
		return
	anim.loop_mode = Animation.LOOP_LINEAR
	var i = 0
	while i < anim.get_track_count():
		if anim.track_get_type(i) == Animation.TYPE_POSITION_3D:
			anim.remove_track(i)
		else:
			i += 1

func _ready():
	dialogue_label = $DialogueLabel
	_set_dialogue("")
	global_position = Vector3(0, 0.9, 7.5)
	await get_tree().create_timer(5.0).timeout
	_begin_entry()

func _begin_entry():
	var door_pivot = get_tree().get_first_node_in_group("door_pivot")
	if door_pivot and not door_pivot.is_open:
		door_pivot.interact(null)
	await get_tree().create_timer(1.5).timeout
	_start_walking([Vector3(0, 0.9, 3.0), Vector3(0, 0.9, -0.8)], "entering")

func _start_walking(waypoints: Array, mode: String):
	_waypoints = waypoints
	_waypoint_idx = 0
	_walk_mode = mode
	state = State.WALKING
	if anim_player:
		anim_player.play("Armature|mixamo_com|Layer0")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if state == State.WALKING:
		_step_toward_waypoint()
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func _step_toward_waypoint():
	if _waypoint_idx >= _waypoints.size():
		velocity.x = 0
		velocity.z = 0
		_on_walk_done()
		return

	var target: Vector3 = _waypoints[_waypoint_idx]
	var flat_pos = Vector3(global_position.x, 0, global_position.z)
	var flat_target = Vector3(target.x, 0, target.z)
	var diff = flat_target - flat_pos

	if diff.length() < ARRIVE_DIST:
		_waypoint_idx += 1
		return

	var dir = diff.normalized()
	velocity.x = dir.x * WALK_SPEED
	velocity.z = dir.z * WALK_SPEED
	look_at(Vector3(global_position.x + dir.x, global_position.y, global_position.z + dir.z), Vector3.UP)

func _on_walk_done():
	if _walk_mode == "entering":
		look_at(Vector3(global_position.x, global_position.y, global_position.z - 1.0), Vector3.UP)
		_start_asking()
	elif _walk_mode == "leaving":
		var door_pivot = get_tree().get_first_node_in_group("door_pivot")
		if door_pivot and door_pivot.is_open:
			door_pivot.interact(null)
		state = State.OUTSIDE
		_set_dialogue("")
		global_position = Vector3(0, 0.9, 7.5)
		await get_tree().create_timer(5.0).timeout
		_begin_entry()

func _start_asking():
	state = State.ASKING
	if anim_player:
		anim_player.stop()
	_set_dialogue("Could I have a\nPlague Potion please?")

func get_interact_label(_player = null) -> String:
	if state == State.ASKING:
		return "Give Potion [E]"
	return ""

func interact(player):
	if state == State.ASKING and player.has_item_type("plague_potion"):
		for item in player.held_items:
			if item.get("item_type") == "plague_potion":
				if item.has_method("reset_to_empty"):
					item.reset_to_empty()
				break
		player._update_inventory_label()
		_receive_potion(player)

func _receive_potion(player):
	state = State.HAPPY
	_set_dialogue("Thank you!\nThat'll fix me right up!")
	player.add_gold(10)

	await get_tree().create_timer(2.0).timeout
	_set_dialogue("Goodbye!")
	await get_tree().create_timer(1.0).timeout
	var door_pivot = get_tree().get_first_node_in_group("door_pivot")
	if door_pivot and not door_pivot.is_open:
		door_pivot.interact(null)
		await get_tree().create_timer(1.5).timeout
	_start_walking([Vector3(0, 0.9, 7.5)], "leaving")

func _set_dialogue(text: String):
	if dialogue_label:
		dialogue_label.text = text
