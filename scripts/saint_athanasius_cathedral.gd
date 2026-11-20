extends Node3D

@onready var model: Node3D = $Model
var left: Node3D
var right: Node3D
var doors_open := false
var door_tween: Tween

func _ready() -> void:
	add_to_group("cathedral")
	left = model.find_child("DoorLeftPivot", true, false)
	right = model.find_child("DoorRightPivot", true, false)
	assert(left != null and right != null)
	_make_door_body(left, 1.0)
	_make_door_body(right, -1.0)
	var forecourt = model.find_child("Entrance forecourt*", true, false)
	if forecourt:
		forecourt.visible = false
	var trigger = StaticBody3D.new()
	trigger.set_script(load("res://scripts/cathedral_door_trigger.gd"))
	trigger.set("cathedral", self)
	trigger.collision_layer = 2
	trigger.collision_mask = 0
	var tcol = CollisionShape3D.new()
	var tbox = BoxShape3D.new()
	tbox.size = Vector3(5.0, 3.5, 1.0)
	tcol.shape = tbox
	tcol.position = Vector3(0, 1.75, 0)
	trigger.add_child(tcol)
	trigger.position = Vector3(0, 0, 20.0)
	add_child(trigger)
	var altar_trigger = StaticBody3D.new()
	altar_trigger.set_script(load("res://scripts/altar_trigger.gd"))
	altar_trigger.collision_layer = 2
	altar_trigger.collision_mask = 0
	var acol = CollisionShape3D.new()
	var abox = BoxShape3D.new()
	abox.size = Vector3(4.0, 2.5, 2.0)
	acol.shape = abox
	acol.position = Vector3(0, 1.25, 0)
	altar_trigger.add_child(acol)
	altar_trigger.position = Vector3(0.0, 0.0, -15.0)
	add_child(altar_trigger)
	for node in model.find_children("*", "OmniLight3D", true, false):
		node.shadow_enabled = false
		if node.name.begins_with("Clerestory"):
			node.light_energy = 2.2
			node.omni_range = 11.0
		elif node.name.begins_with("Sanctuary"):
			node.light_energy = 3.0
			node.omni_range = 10.0
		elif node.name.begins_with("Crossing"):
			node.light_energy = 2.8
			node.omni_range = 13.0
		else:
			node.light_energy = 1.7
			node.omni_range = 7.0

func _make_door_body(pivot: Node3D, side: float) -> void:
	var body := AnimatableBody3D.new()
	body.name = "DoorCollision"
	body.sync_to_physics = false
	body.collision_layer = 1
	body.collision_mask = 1
	pivot.add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.85, 4.7, 0.24)
	shape.shape = box
	shape.position = Vector3(side * 0.925, 2.35, 0)
	body.add_child(shape)

func toggle_doors() -> void:
	set_doors_open(not doors_open)

func set_doors_open(value: bool, instant := false) -> void:
	doors_open = value
	if door_tween != null:
		door_tween.kill()
	var angle := deg_to_rad(105.0) if value else 0.0
	if instant:
		left.rotation.y = angle
		right.rotation.y = -angle
	else:
		door_tween = create_tween().set_parallel(true)
		door_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		door_tween.tween_property(left, "rotation:y", angle, 1.45)
		door_tween.tween_property(right, "rotation:y", -angle, 1.45)
