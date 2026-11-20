extends Node3D

var model: Node3D
var door_pivot: Node3D
var _door_open := false
var _door_tween: Tween

func _ready() -> void:
	model = $Model

	# --- Collision from JSON -------------------------------------------------
	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)
	var entries = JSON.parse_string(
		FileAccess.get_file_as_string("res://models/thirteenth-hour-new-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			if entry.has("points"):
				var shape = ConvexPolygonShape3D.new()
				var pts = PackedVector3Array()
				for p in entry.points:
					pts.append(Vector3(p[0], p[1], p[2]))
				shape.points = pts
				col.shape = shape
			else:
				var shape = BoxShape3D.new()
				var s = entry["size"]
				shape.size = Vector3(s[0], s[1], s[2])
				col.shape = shape
				var p = entry["position"]
				col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

	# --- Door ----------------------------------------------------------------
	door_pivot = model.find_child("HerbShopDoorPivot", true, false)
	if door_pivot:
		var door_body = AnimatableBody3D.new()
		door_body.name = "DoorCollision"
		door_body.sync_to_physics = false
		door_pivot.add_child(door_body)
		var door_shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(0.11, 2.22, 1.16)
		door_shape.shape = box
		door_shape.position = Vector3(0, 1.11, 0.58)
		door_body.add_child(door_shape)
		call_deferred("_add_door_trigger")

	# --- Lights --------------------------------------------------------------
	for light in model.find_children("*", "OmniLight3D", true, false):
		light.shadow_enabled = false
		light.light_energy = 2.0 if "ceiling" in light.name.to_lower() else 1.5
		light.omni_range = 7.0

func _add_door_trigger() -> void:
	if not door_pivot:
		return
	var trigger = StaticBody3D.new()
	trigger.set_script(load("res://scripts/thirteenth_hour_door_trigger.gd"))
	trigger.set("house", self)
	trigger.collision_layer = 2
	trigger.collision_mask = 0
	var tcol = CollisionShape3D.new()
	var tbox = BoxShape3D.new()
	tbox.size = Vector3(1.4, 2.5, 1.4)
	tcol.shape = tbox
	trigger.add_child(tcol)
	get_tree().root.add_child(trigger)
	# Centre the trigger on the door pivot, offset up to match door centre
	trigger.global_position = door_pivot.global_position + Vector3(0, 1.1, 0)

func set_door_open(value: bool) -> void:
	_door_open = value
	if _door_tween:
		_door_tween.kill()
	var angle = deg_to_rad(-100.0) if value else 0.0
	_door_tween = create_tween()
	_door_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_door_tween.tween_property(door_pivot, "rotation:y", angle, 0.85)
