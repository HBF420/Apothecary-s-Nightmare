extends CharacterBody3D

const SPEED = 3.0
const RUN_SPEED = 5.0
const MOUSE_SENSITIVITY = 0.002
const BOB_FREQ = 0.6
const BOB_AMP = 0.003
const INTERACT_DISTANCE = 2.5

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var hand_position: Node3D = $Head/Camera3D/HandPosition
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var interact_label: Label = $HUD/InteractLabel
@onready var inventory_label: Label = $HUD/InventoryLabel
@onready var gold_label: Label = $HUD/GoldLabel
@onready var crosshair: Label = $HUD/Crosshair
@onready var seeds_label: Label = $HUD/SeedsLabel

var held_items: Array = []
var _bob_time: float = 0.0
var _last_step: int = 0
var _footstep_player: AudioStreamPlayer = null
var _footstep_wood: AudioStream = null
var _footstep_stone: AudioStream = null
var gold: int = 0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var crafting_spots: Array = []
var seeds: Dictionary = {"snake_plant": 5, "basil": 3, "aloe_vera": 3, "bee_balm": 3, "calendula": 3, "chamomile": 3}
var _active_well = null   # set by well_node when bucket is in hand
var _active_forge = null  # set by forge_trigger when pot is in hand
var _carried_body = null
var _last_hovered = null  # tracks ingredient braid under crosshair for highlight
var reputation: int = 0
var reputation_label: Label = null
var has_prayed_today: bool = false

func register_crafting_spot(spot):
	crafting_spots.append(spot)

func _get_nearby_crafting_spot():
	for spot in crafting_spots:
		if spot.is_player_nearby(self):
			return spot
	return null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_gold_label()
	_update_seeds_label()
	var rl = Label.new()
	rl.anchor_left = 1.0; rl.anchor_right = 1.0
	rl.offset_left = -200.0; rl.offset_top = 65.0
	rl.offset_right = -20.0; rl.offset_bottom = 100.0
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	$HUD.add_child(rl)
	reputation_label = rl
	update_reputation_label()
	_footstep_wood  = load("res://sounds/medieval-wood-floor-footstep-3.wav")
	_footstep_stone = load("res://sounds/medieval-stone-street-footstep-2.wav")
	_footstep_player = AudioStreamPlayer.new()
	_footstep_player.volume_db = -6.0
	add_child(_footstep_player)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_F:
			if _active_well and is_instance_valid(_active_well):
				_active_well.pour(self)
			elif interact_ray.is_colliding():
				var col = interact_ray.get_collider()
				if col.has_method("secondary_interact"):
					col.secondary_interact(self)
		elif event.keycode == KEY_G:
			if interact_ray.is_colliding():
				var col = interact_ray.get_collider()
				if col.has_method("tertiary_interact"):
					col.tertiary_interact(self)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	var speed = RUN_SPEED if Input.is_key_pressed(KEY_SHIFT) else SPEED
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	_check_interaction()
	_update_head_bob(delta)

func _update_head_bob(delta: float):
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.1 and is_on_floor():
		_bob_time += delta * horizontal_speed * BOB_FREQ
		camera.position.y = sin(_bob_time * TAU) * BOB_AMP
		# Play a footstep once per full bob cycle
		var step = int(_bob_time)
		if step != _last_step:
			_last_step = step
			if _footstep_player and not _footstep_player.playing:
				var outdoors = global_position.z > 5.0
				_footstep_player.stream = _footstep_stone if outdoors else _footstep_wood
				_footstep_player.volume_db = -12.0 if outdoors else -6.0
				_footstep_player.play()
	else:
		camera.position.y = lerp(camera.position.y, 0.0, delta * 10.0)

func _check_interaction():
	interact_label.text = ""

	# ── Ingredient hover highlight ──────────────────────────────────────────
	var hovered_now = null
	if interact_ray.is_colliding():
		var c = interact_ray.get_collider()
		if c.has_method("set_hover"):
			hovered_now = c
	if hovered_now != _last_hovered:
		if _last_hovered != null and is_instance_valid(_last_hovered):
			_last_hovered.set_hover(false)
		if hovered_now != null:
			hovered_now.set_hover(true)
		_last_hovered = hovered_now
	# ───────────────────────────────────────────────────────────────────────

	# Body carry hint
	if _carried_body != null:
		if _get_coffin_cart_in_range():
			interact_label.text = "Drop body [E]"
			return
		# Still show door labels while carrying
		if interact_ray.is_colliding():
			var col = interact_ray.get_collider()
			if col.has_method("get_interact_label"):
				interact_label.text = col.get_interact_label(self)
				return
		interact_label.text = "Take body to undertaker's cart"
		return
	# Well bucket hints when carrying it
	if _active_well and is_instance_valid(_active_well):
		if interact_ray.is_colliding():
			var col = interact_ray.get_collider()
			if col.has_method("get_interact_label"):
				interact_label.text = col.get_interact_label(self)
				return
		if _active_well.is_held_full():
			interact_label.text = "Pour water [F]"
		else:
			interact_label.text = "Return to well to reattach [E]"
		return
	# Forge pot hints when carrying it
	if _active_forge and is_instance_valid(_active_forge):
		if interact_ray.is_colliding():
			var col = interact_ray.get_collider()
			if col.has_method("get_interact_label"):
				interact_label.text = col.get_interact_label(self)
				return
		interact_label.text = "Return to forge to hang pot [E]"
		return

	var crafting_spot = _get_nearby_crafting_spot()
	if crafting_spot != null and crafting_spot._player_has_all_items(self):
		interact_label.text = crafting_spot.get_interact_label(self)
	elif interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider.has_method("get_interact_label"):
			interact_label.text = collider.get_interact_label(self)
		if collider.has_method("get_secondary_label"):
			var sec = collider.get_secondary_label(self)
			if sec != "":
				interact_label.text += "\n" + sec
		if collider.has_method("get_tertiary_label"):
			var tert = collider.get_tertiary_label(self)
			if tert != "":
				interact_label.text += "\n" + tert
	elif crafting_spot != null:
		interact_label.text = crafting_spot.get_interact_label(self)

func _process(_delta):
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	if Input.is_action_just_pressed("grab"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_try_interact()

func _try_interact():
	if _carried_body != null:
		var cart = _get_nearby_coffin_cart()
		if cart:
			_place_body_on_cart(cart)
			return
		# Allow door interactions while carrying
		if interact_ray.is_colliding():
			var col = interact_ray.get_collider()
			if col.has_method("interact"):
				col.interact(self)
		return
	var crafting_spot = _get_nearby_crafting_spot()
	if crafting_spot != null and crafting_spot._player_has_all_items(self):
		crafting_spot.interact(self)
	elif interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider.has_method("interact"):
			collider.interact(self)

func _start_carrying_body(body):
	_carried_body = body
	interact_label.text = "Drop body [E]"

func _drop_body():
	if _carried_body and is_instance_valid(_carried_body):
		_carried_body._be_dropped()
	_carried_body = null

func pick_up_item(item):
	held_items.append(item)
	item.get_parent().remove_child(item)
	hand_position.add_child(item)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	item.collision_layer = 0
	item.collision_mask = 0
	_update_inventory_label()

func drop_all_items():
	for item in held_items:
		hand_position.remove_child(item)
		get_parent().add_child(item)
		item.global_position = global_position + Vector3(0, 0.5, 0)
		item.collision_layer = 2
		item.collision_mask = 0
	held_items.clear()
	_update_inventory_label()

func has_item_type(type_name: String) -> bool:
	for item in held_items:
		if item.item_type == type_name:
			return true
	return false

func remove_item_type(type_name: String):
	for i in range(held_items.size() - 1, -1, -1):
		if held_items[i].item_type == type_name:
			var item = held_items[i]
			held_items.remove_at(i)
			hand_position.remove_child(item)
			item.queue_free()
			break
	_update_inventory_label()

func add_seed(seed_type: String, amount: int = 1):
	seeds[seed_type] = seeds.get(seed_type, 0) + amount
	_update_seeds_label()

func _update_seeds_label():
	var parts = []
	for type in seeds:
		if seeds[type] > 0:
			parts.append("%s x%d" % [type.replace("_", " ").capitalize(), seeds[type]])
	seeds_label.text = "Seeds: " + (", ".join(parts) if not parts.is_empty() else "none")

func add_gold(amount: int):
	gold += amount
	update_gold_label()

func update_gold_label():
	gold_label.text = "Gold: %d" % gold

func _get_coffin_cart_in_range() -> Node:
	for cart in get_tree().get_nodes_in_group("coffin_cart"):
		if cart.global_position.distance_to(global_position) <= 3.0:
			return cart
	return null

func _get_nearby_coffin_cart() -> Node:
	for cart in get_tree().get_nodes_in_group("coffin_cart"):
		if cart.global_position.distance_to(global_position) <= 3.0:
			if cart.can_drop(self):
				return cart
	return null

func _place_body_on_cart(cart: Node):
	if _carried_body and is_instance_valid(_carried_body):
		_carried_body._place_on_cart(cart)
	_carried_body = null

func _update_inventory_label():
	if held_items.is_empty():
		inventory_label.text = ""
	else:
		var names = []
		for item in held_items:
			names.append(item.item_type)
		inventory_label.text = "Holding: " + ", ".join(names)

func add_reputation(amount: int):
	reputation += amount
	update_reputation_label()

func update_reputation_label():
	if reputation_label:
		reputation_label.text = "Reputation: %d" % reputation

func on_sleep() -> void:
	has_prayed_today = false

func get_rep_tier() -> int:
	if reputation >= 1500:
		return 5
	elif reputation >= 700:
		return 4
	elif reputation >= 300:
		return 3
	elif reputation >= 100:
		return 2
	return 1
