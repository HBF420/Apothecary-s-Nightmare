extends CharacterBody3D

const DiseaseData = preload("res://scripts/disease_data.gd")

enum State { OUTSIDE, KNOCKING, WALKING, AT_COUNTER, CONVERSING, WAITING, REMEDIED, DEAD, CARRIED, DROPPING, LEAVING }

const WALK_SPEED = 2.5
const ARRIVE_DIST = 0.3
const KNOCK_REPEAT_INTERVAL = 30.0
const ANIM_BLEND = 0.3

enum SocialClass { DESPERATE, COMMON, ESTABLISHED, DISTINGUISHED, ROYAL }
const CLASS_NAMES = ["The Desperate", "Common Folk", "The Established", "The Distinguished", "Royal Court"]
const REP_CURE    = [10,  20,  40,  100, 200]
const REP_DISMISS = [-5, -10, -20,  -50, -100]
const REP_KILL    = [-10, -20, -40, -100, -200]

var state: State = State.OUTSIDE
var dialogue_label: Label3D = null
var _waypoints: Array = []
var _waypoint_idx: int = 0
var _walk_mode: String = ""
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var anim_player: AnimationPlayer = null
var _walking_mesh: Node = null
var _knock_player: AudioStreamPlayer3D = null
var _knock_timer: float = 0.0
var _voice_player: AudioStreamPlayer3D = null
var _apothecary_voice: AudioStreamPlayer3D = null

var _disease: Dictionary = {}
var _stored_answers: Dictionary = {}
var _current_tier: int = 0
var _is_carried: bool = false
var _carrying_player = null
var _dying_inst: Node = null
var _saved_xform: Transform3D = Transform3D.IDENTITY
var social_class: int = SocialClass.COMMON
var _last_player = null
var _dismissed: bool = false

func set_animation_player(player: AnimationPlayer):
	anim_player = player
	# Track the Walking.glb root so we can hide it on death
	var node: Node = player
	while node != null and node.get_parent() != self:
		node = node.get_parent()
	_walking_mesh = node
	var walk_anim = anim_player.get_animation("Armature|mixamo_com|Layer0")
	if walk_anim:
		walk_anim.loop_mode = Animation.LOOP_LINEAR
		var i = walk_anim.get_track_count() - 1
		while i >= 0:
			if walk_anim.track_get_type(i) == Animation.TYPE_POSITION_3D:
				walk_anim.remove_track(i)
			i -= 1

func _ready():
	dialogue_label = $DialogueLabel
	_set_dialogue("")
	global_position = Vector3(0, 0.9, 6.5)

	add_to_group("customer")

	_knock_player = AudioStreamPlayer3D.new()
	var stream = load("res://sounds/medieval-wooden-door-knock.wav")
	if stream:
		_knock_player.stream = stream
	_knock_player.max_distance = 20.0
	add_child(_knock_player)

	_voice_player = AudioStreamPlayer3D.new()
	var voice_stream = load("res://sounds/dahlia_whos_there.mp3")
	if voice_stream:
		_voice_player.stream = voice_stream
	_voice_player.max_distance = 20.0
	add_child(_voice_player)

	_apothecary_voice = AudioStreamPlayer3D.new()
	var apo_stream = load("res://sounds/apothecary_what_ails_you.mp3")
	if apo_stream:
		_apothecary_voice.stream = apo_stream
	_apothecary_voice.max_distance = 20.0
	add_child(_apothecary_voice)

	call_deferred("_load_idle")

	await get_tree().create_timer(5.0).timeout
	_begin_knocking()

func _load_idle():
	var idle_res = load("res://models/Idle.fbx")
	if not idle_res or not anim_player:
		return

	var idle_inst = idle_res.instantiate()
	idle_inst.visible = false
	add_child(idle_inst)

	var idle_ap = _find_anim_player(idle_inst)
	if idle_ap:
		var anim_name = ""
		for n in idle_ap.get_animation_list():
			if n not in ["RESET", "Take 001"]:
				anim_name = n
				break

		if anim_name != "":
			var src = idle_ap.get_animation(anim_name)
			if src:
				var idle_copy = src.duplicate()
				idle_copy.loop_mode = Animation.LOOP_LINEAR
				for t in range(idle_copy.get_track_count()):
					var path = str(idle_copy.track_get_path(t))
					if not path.begins_with("Armature/"):
						idle_copy.track_set_path(t, NodePath("Armature/" + path))
				var j = idle_copy.get_track_count() - 1
				while j >= 0:
					var path = str(idle_copy.track_get_path(j))
					if "Hips" in path or idle_copy.track_get_type(j) == Animation.TYPE_POSITION_3D:
						idle_copy.remove_track(j)
					j -= 1
				var lib: AnimationLibrary
				if anim_player.has_animation_library(""):
					lib = anim_player.get_animation_library("")
				else:
					lib = AnimationLibrary.new()
					anim_player.add_animation_library("", lib)
				if lib and not lib.has_animation("idle"):
					lib.add_animation("idle", idle_copy)

	idle_inst.queue_free()

func _collect_mesh_instances(node: Node, result: Array) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_collect_mesh_instances(child, result)

func _find_bone(skel: Skeleton3D, keyword: String) -> int:
	for i in range(skel.get_bone_count()):
		if keyword in skel.get_bone_name(i):
			return i
	return -1

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	return null

func _match_death_to_walking(dying_inst: Node) -> void:
	if not _walking_mesh:
		return
	# Copy materials surface-by-surface
	var src_meshes: Array = []
	var dst_meshes: Array = []
	_collect_mesh_instances(_walking_mesh, src_meshes)
	_collect_mesh_instances(dying_inst, dst_meshes)
	for i in range(min(src_meshes.size(), dst_meshes.size())):
		var src := src_meshes[i] as MeshInstance3D
		var dst := dst_meshes[i] as MeshInstance3D
		if src.mesh and dst.mesh:
			for s in range(min(src.mesh.get_surface_count(), dst.mesh.get_surface_count())):
				dst.set_surface_override_material(s, src.get_active_material(s))
	# Bone-based scale + position matching (AABB is unreliable due to Walking.glb internal 0.01 scale)
	var src_skel := _find_skeleton(_walking_mesh)
	var dst_skel := _find_skeleton(dying_inst)
	if not src_skel or not dst_skel:
		return
	var src_hips := _find_bone(src_skel, "Hips")
	var src_head := _find_bone(src_skel, "Head")
	var dst_hips := _find_bone(dst_skel, "Hips")
	var dst_head := _find_bone(dst_skel, "Head")
	if src_hips < 0 or src_head < 0 or dst_hips < 0 or dst_head < 0:
		return
	var src_hips_y := src_skel.to_global(src_skel.get_bone_global_pose(src_hips).origin).y
	var src_head_y := src_skel.to_global(src_skel.get_bone_global_pose(src_head).origin).y
	var dst_hips_y := dst_skel.to_global(dst_skel.get_bone_global_pose(dst_hips).origin).y
	var dst_head_y := dst_skel.to_global(dst_skel.get_bone_global_pose(dst_head).origin).y
	var src_h := src_head_y - src_hips_y
	var dst_h := dst_head_y - dst_hips_y
	if src_h < 0.1 or dst_h < 0.1:
		return
	var ratio := src_h / dst_h
	if ratio < 0.5 or ratio > 2.0:
		return
	dying_inst.scale *= ratio
	var new_dst_hips := dst_skel.to_global(dst_skel.get_bone_global_pose(dst_hips).origin)
	var src_hips_world := src_skel.to_global(src_skel.get_bone_global_pose(src_hips).origin)
	dying_inst.global_position += src_hips_world - new_dst_hips

func _dip_to_black(from_node: Node, to_node: Node) -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	var rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	get_tree().root.add_child(canvas)
	var t = create_tween()
	t.tween_property(rect, "color:a", 1.0, 0.07)
	await t.finished
	from_node.visible = false
	to_node.visible = true
	t = create_tween()
	t.tween_property(rect, "color:a", 0.0, 0.15)
	await t.finished
	canvas.queue_free()

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_anim_player(child)
		if result:
			return result
	return null

func _begin_knocking():
	state = State.KNOCKING
	_knock_timer = 0.0
	look_at(Vector3(global_position.x, global_position.y, global_position.z - 1.0), Vector3.UP)
	_play_idle()
	_knock_player.play()

func _begin_entry():
	_start_walking([Vector3(0, 0.9, 3.0), Vector3(0, 0.9, -0.8)], "entering")

func _start_walking(waypoints: Array, mode: String):
	_waypoints = waypoints
	_waypoint_idx = 0
	_walk_mode = mode
	state = State.WALKING
	if anim_player:
		anim_player.speed_scale = 1.0
		anim_player.play("Armature|mixamo_com|Layer0", ANIM_BLEND)

func _play_idle():
	if not anim_player:
		return
	if anim_player.has_animation("idle"):
		anim_player.speed_scale = 1.0
		anim_player.play("idle", ANIM_BLEND)
	else:
		anim_player.speed_scale = 0.15
		anim_player.play("Armature|mixamo_com|Layer0")

func _physics_process(delta):
	if state == State.CARRIED:
		if _carrying_player and is_instance_valid(_carrying_player):
			var right = _carrying_player.transform.basis.x
			var fwd = -_carrying_player.transform.basis.z
			# Root follows player's right shoulder
			global_position = _carrying_player.global_position + right * 0.55 + fwd * 0.05 + Vector3(0, 0.9, 0)
			# Keep body facing the same direction as the player
			global_rotation.y = _carrying_player.global_rotation.y
		return

	if state == State.DEAD:
		return

	if state == State.DROPPING:
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if state == State.KNOCKING:
		_knock_timer += delta
		if _knock_timer >= KNOCK_REPEAT_INTERVAL:
			_knock_timer = 0.0
			_knock_player.play()
		var door_pivot = get_tree().get_first_node_in_group("door_pivot")
		if door_pivot and door_pivot.is_open and not door_pivot.is_animating:
			state = State.OUTSIDE
			_begin_entry()
	elif state == State.WALKING:
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
		var prev_idx = _waypoint_idx
		_waypoint_idx += 1
		if _walk_mode == "entering" and prev_idx == 0:
			var door_pivot = get_tree().get_first_node_in_group("door_pivot")
			if door_pivot and door_pivot.is_open:
				door_pivot.interact(null)
		return

	var dir = diff.normalized()
	velocity.x = dir.x * WALK_SPEED
	velocity.z = dir.z * WALK_SPEED
	look_at(Vector3(global_position.x + dir.x, global_position.y, global_position.z + dir.z), Vector3.UP)

func _on_walk_done():
	if _walk_mode == "entering":
		look_at(Vector3(global_position.x, global_position.y, global_position.z - 1.0), Vector3.UP)
		_arrive_at_counter()
	elif _walk_mode == "leaving":
		var door_pivot = get_tree().get_first_node_in_group("door_pivot")
		if door_pivot and door_pivot.is_open:
			door_pivot.interact(null)
		state = State.OUTSIDE
		_set_dialogue("")
		global_position = Vector3(0, 0.9, 6.5)
		_play_idle()
		await get_tree().create_timer(5.0).timeout
		if _dismissed:
			queue_free()
			return
		_begin_knocking()

func _pick_social_class(tier: int) -> int:
	# Each entry: [SocialClass int value, weight out of 100]
	const WEIGHTS = [
		[[0, 80], [1, 20]],               # tier 1: 80% DESPERATE, 20% COMMON
		[[0, 10], [1, 80], [2, 10]],      # tier 2: 10% DESPERATE, 80% COMMON, 10% ESTABLISHED
		[[1, 10], [2, 80], [3, 10]],      # tier 3: 10% COMMON, 80% ESTABLISHED, 10% DISTINGUISHED
		[[2, 10], [3, 80], [4, 10]],      # tier 4: 10% ESTABLISHED, 80% DISTINGUISHED, 10% ROYAL
		[[3, 20], [4, 80]],               # tier 5: 20% DISTINGUISHED, 80% ROYAL
	]
	var pool = WEIGHTS[tier - 1]
	var roll = randi() % 100
	var cumulative = 0
	for entry in pool:
		cumulative += entry[1]
		if roll < cumulative:
			return entry[0]
	return pool[-1][0]

func _arrive_at_counter():
	state = State.AT_COUNTER
	_play_idle()
	_set_dialogue("")
	var player = get_tree().get_first_node_in_group("player")
	var tier = 1
	if player and player.has_method("get_rep_tier"):
		tier = player.get_rep_tier()
	social_class = _pick_social_class(tier)
	_disease = DiseaseData.get_disease("stonebelly")
	_generate_answers()

func _generate_answers():
	_stored_answers.clear()
	for key in _disease.answers_pool:
		var arr: Array = _disease.answers_pool[key]
		_stored_answers[key] = arr[randi() % arr.size()]

func get_interact_label(_player = null) -> String:
	match state:
		State.AT_COUNTER:
			return CLASS_NAMES[social_class] + "\nAsk what's wrong [E]"
		State.WAITING:
			if _player and _player_has_vial(_player):
				return "Give Remedy [E]"
		State.DEAD:
			if not _is_carried:
				return "Pick up body [E]"
		State.DROPPING:
			return ""
	return ""

func _player_has_vial(player) -> bool:
	for item in player.held_items:
		if item.item_type != "":
			return true
	return false

func interact(player):
	match state:
		State.AT_COUNTER:
			_start_consultation(player)
		State.WAITING:
			if _player_has_vial(player):
				_receive_remedy(player)
		State.DEAD:
			if not _is_carried:
				_be_picked_up(player)

func _start_consultation(_player):
	state = State.CONVERSING
	if _apothecary_voice:
		_apothecary_voice.play()
	_set_dialogue(_disease.complaint_text)
	var audio_length = 2.5
	if _apothecary_voice and _apothecary_voice.stream:
		audio_length = _apothecary_voice.stream.get_length()
		if audio_length <= 0.1:
			audio_length = 2.5
	await get_tree().create_timer(audio_length).timeout
	open_dialogue_at_tier(0)

func open_dialogue_at_tier(t: int):
	_current_tier = t
	var menu = load("res://scripts/dialogue_menu.gd").new()
	menu.customer = self
	menu.tier = t
	get_tree().root.add_child(menu)

func show_answer(key: String):
	var answer = _stored_answers.get(key, "...")
	_set_dialogue(answer)
	await get_tree().create_timer(3.0).timeout
	_set_dialogue("")
	open_dialogue_at_tier(_current_tier)

func _enter_waiting():
	state = State.WAITING
	_play_idle()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _receive_remedy(player):
	if player.held_items.is_empty():
		return
	var item = player.held_items[0]
	var item_type = item.item_type
	player.held_items.remove_at(0)
	player.hand_position.remove_child(item)
	item.queue_free()
	player._update_inventory_label()
	_last_player = player
	if item_type == _disease.get("remedy", ""):
		_cure(player)
	else:
		_wrong_remedy()

func _cure(player):
	state = State.REMEDIED
	_set_dialogue("I'm feeling better.\nThank you!")
	_play_idle()
	player.add_gold(15)
	player.add_reputation(REP_CURE[social_class])
	await get_tree().create_timer(2.0).timeout
	_set_dialogue("Goodbye!")
	await get_tree().create_timer(1.0).timeout
	_begin_leaving()

func _wrong_remedy():
	state = State.DEAD
	_set_dialogue("This made me feel much worse...")
	velocity = Vector3.ZERO
	set_physics_process(false)
	if _last_player and is_instance_valid(_last_player):
		_last_player.add_reputation(REP_KILL[social_class])
	if anim_player:
		anim_player.speed_scale = 0.0
	var saved_xform := Transform3D.IDENTITY
	if _walking_mesh:
		saved_xform = _walking_mesh.transform
		_saved_xform = saved_xform
	var dying_res = load("res://models/dying_backwards_skin.fbx")
	if dying_res:
		var dying_inst = dying_res.instantiate()
		_dying_inst = dying_inst
		dying_inst.transform = saved_xform
		dying_inst.visible = false
		add_child(dying_inst)
		await get_tree().process_frame
		var dying_ap := _find_anim_player(dying_inst)
		if dying_ap:
			var anim_name := "mixamo_com" if dying_ap.has_animation("mixamo_com") else ""
			if anim_name == "":
				for n in dying_ap.get_animation_list():
					if n not in ["RESET", "Take 001"]:
						anim_name = n
						break
			if anim_name != "":
				dying_ap.get_animation(anim_name).loop_mode = Animation.LOOP_NONE
				dying_ap.play(anim_name)
				dying_ap.seek(0.0, true)
				await get_tree().process_frame
				_match_death_to_walking(dying_inst)
				if _walking_mesh:
					_walking_mesh.visible = false
				dying_inst.visible = true
				await dying_ap.animation_finished
	else:
		await get_tree().create_timer(1.5).timeout
	_set_dialogue("")

func _be_picked_up(player):
	state = State.CARRIED
	_is_carried = true
	_carrying_player = player
	player._start_carrying_body(self)
	collision_layer = 0
	collision_mask = 0
	set_physics_process(true)
	# Hide for one frame while we reposition/reposes, to avoid a flash
	if _dying_inst and is_instance_valid(_dying_inst):
		_dying_inst.visible = false
		_dying_inst.position = Vector3.ZERO
		_dying_inst.rotation_degrees = Vector3(80.0, 0.0, 15.0)
		# Restore the pre-match scale so size (and thus visual position) is always identical.
		_dying_inst.scale = _saved_xform.basis.get_scale()
		# Snap the death animation to its very last frame before freezing.
		# Without this, picking up the body mid-animation leaves bones at a random frame,
		# so the shoulder position shifts depending on when E is pressed.
		var dying_ap := _find_anim_player(_dying_inst)
		if dying_ap:
			if dying_ap.is_playing():
				var anim := dying_ap.get_animation(dying_ap.current_animation)
				if anim:
					dying_ap.seek(anim.length, true)
			dying_ap.stop(true)
		# Shape the body for a carried look using absolute poses (not relative to anim)
		var skel := _find_skeleton(_dying_inst)
		if skel:
			var i_spine1 := _find_bone(skel, "Spine1")
			var i_spine2 := _find_bone(skel, "Spine2")
			if i_spine1 >= 0:
				skel.set_bone_pose_rotation(i_spine1, Quaternion(Vector3(1.0, 0.0, 0.0), deg_to_rad(35.0)))
			if i_spine2 >= 0:
				skel.set_bone_pose_rotation(i_spine2, Quaternion(Vector3(1.0, 0.0, 0.0), deg_to_rad(25.0)))
			var i_neck := _find_bone(skel, "Neck")
			if i_neck >= 0:
				skel.set_bone_pose_rotation(i_neck, skel.get_bone_pose_rotation(i_neck) * Quaternion(Vector3(1.0, 0.0, 0.0), deg_to_rad(50.0)))
			var i_la := _find_bone(skel, "LeftArm")
			var i_ra := _find_bone(skel, "RightArm")
			if i_la >= 0:
				skel.set_bone_pose_rotation(i_la, Quaternion(Vector3(0.0, 0.0, 1.0), deg_to_rad(90.0)))
			if i_ra >= 0:
				skel.set_bone_pose_rotation(i_ra, Quaternion(Vector3(0.0, 0.0, 1.0), deg_to_rad(-90.0)))
		# Snap to the shoulder position NOW so the renderer never sees the body at floor level
		var right = player.transform.basis.x
		var fwd = -player.transform.basis.z
		global_position = player.global_position + right * 0.55 + fwd * 0.05 + Vector3(0, 0.9, 0)
		global_rotation.y = player.global_rotation.y
		_dying_inst.visible = true

func _be_dropped():
	state = State.DROPPING
	_is_carried = false
	# Capture player direction and set drop position before clearing reference
	var drop_fwd := Vector3(0.0, 0.0, 1.0)
	if _carrying_player and is_instance_valid(_carrying_player):
		drop_fwd = -_carrying_player.transform.basis.z
		# Place body 1.2 m in front of player at standing height
		global_position = _carrying_player.global_position + drop_fwd * 1.2 + Vector3(0.0, 0.9, 0.0)
	_carrying_player = null
	collision_layer = 0  # don't push the player during the fall
	collision_mask = 1   # still land on the floor
	velocity = Vector3.ZERO
	set_physics_process(true)
	_start_drop_sequence(drop_fwd)

func _start_drop_sequence(drop_fwd: Vector3):
	if not _dying_inst or not is_instance_valid(_dying_inst):
		state = State.DEAD
		set_physics_process(false)
		return
	# Reset dying_inst to original transform, then aim it so it falls away from player
	_dying_inst.transform = _saved_xform
	drop_fwd = drop_fwd.normalized()
	_dying_inst.rotation.y = atan2(-drop_fwd.x, -drop_fwd.z) + PI
	# Play dying animation starting from halfway so the collapse feels quick
	var dying_ap := _find_anim_player(_dying_inst)
	if dying_ap:
		var anim_name := ""
		for n in dying_ap.get_animation_list():
			if n not in ["RESET", "Take 001"]:
				anim_name = n
				break
		if anim_name != "":
			var anim := dying_ap.get_animation(anim_name)
			anim.loop_mode = Animation.LOOP_NONE
			dying_ap.play(anim_name)
			dying_ap.seek(anim.length * 0.3, true)
			await dying_ap.animation_finished
	state = State.DEAD
	collision_layer = 1  # restore so body can be picked up again
	collision_mask = 1
	set_physics_process(false)

func _place_on_cart(cart: Node3D):
	state = State.DEAD
	_is_carried = false
	_carrying_player = null
	set_physics_process(false)

	if not _dying_inst or not is_instance_valid(_dying_inst):
		return

	# Back of cart (away from horse/house) = -transform.basis.z = world +X for rotation.y=270°
	var cart_back = -cart.transform.basis.z
	# Place body flush with the cart bed (wagon model origin is at bed level)
	global_position = cart.global_position + cart_back * 1.0 + Vector3(0.5, 1.1, -0.15)
	# Collision stays disabled — body on the cart is never interacted with again,
	# and re-enabling it would let the player collide with the capsule near the cart.
	# While CARRIED, _physics_process tracks the player's rotation every frame.
	# We must reset it here so dying_inst's LOCAL rotation equals its global rotation.
	global_rotation = Vector3.ZERO

	# Re-orient along the cart length, body faces INTO the cart (toward front/horse end).
	var into_cart = cart.transform.basis.z
	_dying_inst.position = Vector3.ZERO
	_dying_inst.scale = _saved_xform.basis.get_scale()
	_dying_inst.rotation_degrees = Vector3(
		0.0,
		rad_to_deg(atan2(-into_cart.x, -into_cart.z)),
		0.0
	)
	# Straighten spine/neck/head; rotate arms down alongside the body (toward feet).
	var skel := _find_skeleton(_dying_inst)
	if skel:
		for bone_name in ["Spine1", "Spine2", "Neck", "Head",
				"LeftForeArm", "RightForeArm", "LeftHand", "RightHand"]:
			var idx := _find_bone(skel, bone_name)
			if idx >= 0:
				skel.set_bone_pose_rotation(idx, Quaternion.IDENTITY)
		var i_la := _find_bone(skel, "LeftArm")
		var i_ra := _find_bone(skel, "RightArm")
		if i_la >= 0:
			skel.set_bone_pose_rotation(i_la, Quaternion(Vector3(0, 0, 1), deg_to_rad(-90)))
		if i_ra >= 0:
			skel.set_bone_pose_rotation(i_ra, Quaternion(Vector3(0, 0, 1), deg_to_rad(90)))

func _begin_leaving():
	var door_pivot = get_tree().get_first_node_in_group("door_pivot")
	if door_pivot and not door_pivot.is_open:
		door_pivot.interact(null)
		await get_tree().create_timer(1.5).timeout
	_start_walking([Vector3(0, 0.9, 6.5)], "leaving")

func is_knocking() -> bool:
	return state == State.KNOCKING

func play_whos_there_response():
	if state == State.KNOCKING and _voice_player:
		_voice_player.play()

func dismiss(player):
	_dismissed = true
	if player and is_instance_valid(player):
		player.add_reputation(REP_DISMISS[social_class])
	_begin_leaving()

func be_turned_away(player = null):
	_dismissed = true
	if player and is_instance_valid(player):
		player.add_reputation(REP_DISMISS[social_class])
	state = State.OUTSIDE
	global_position = Vector3(0, 0.9, 6.5)
	_start_walking([Vector3(0, 0.9, 10.0)], "leaving")

func _set_dialogue(text: String):
	if dialogue_label:
		dialogue_label.text = text
