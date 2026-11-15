extends CharacterBody3D

const SPEED = 4.0
const MOUSE_SENSITIVITY = 0.002
const INTERACT_DISTANCE = 2.5

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var hand_position: Node3D = $Head/Camera3D/HandPosition
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var interact_label: Label = $HUD/InteractLabel
@onready var inventory_label: Label = $HUD/InventoryLabel
@onready var gold_label: Label = $HUD/GoldLabel
@onready var crosshair: Label = $HUD/Crosshair

var held_items: Array = []
var gold: int = 0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var crafting_spots: Array = []

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

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	_check_interaction()

func _check_interaction():
	interact_label.text = ""
	var crafting_spot = _get_nearby_crafting_spot()
	if crafting_spot != null and crafting_spot._player_has_all_items(self):
		interact_label.text = crafting_spot.get_interact_label(self)
	elif interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider.has_method("get_interact_label"):
			interact_label.text = collider.get_interact_label(self)
	elif crafting_spot != null:
		interact_label.text = crafting_spot.get_interact_label(self)

func _process(_delta):
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	if Input.is_action_just_pressed("grab"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_try_interact()

func _try_interact():
	var crafting_spot = _get_nearby_crafting_spot()
	if crafting_spot != null and crafting_spot._player_has_all_items(self):
		crafting_spot.interact(self)
	elif interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider.has_method("interact"):
			collider.interact(self)

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
		item.collision_layer = 1
		item.collision_mask = 1
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

func add_gold(amount: int):
	gold += amount
	update_gold_label()

func update_gold_label():
	gold_label.text = "Gold: %d" % gold

func _update_inventory_label():
	if held_items.is_empty():
		inventory_label.text = ""
	else:
		var names = []
		for item in held_items:
			names.append(item.item_type)
		inventory_label.text = "Holding: " + ", ".join(names)
