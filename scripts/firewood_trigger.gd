extends StaticBody3D

const FirewoodRack = preload("res://scripts/firewood_rack.gd")

var _rack: Node3D = null

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0

	_rack = Node3D.new()
	_rack.set_script(FirewoodRack)
	var glb = load("res://models/medieval-firewood-rack.glb")
	if glb:
		var model = glb.instantiate()
		model.name = "Model"
		_rack.add_child(model)
	add_child(_rack)

	# Interaction collider matching the rack's BoxShape3D from the README
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.76, 0.60, 0.39)
	col.shape = shape
	col.position = Vector3(0, 0.30, 0)
	add_child(col)

func get_interact_label(_player = null) -> String:
	if _rack == null:
		return ""
	return _rack.prompt() + (" [E]" if _rack.remaining_count() > 0 else "")

func interact(player) -> void:
	if _rack == null:
		return
	# firewood_rack.gd reparents the log to hand_position itself
	# and adds it to group "held_firewood" — no held_items tracking needed
	_rack.interact(player.hand_position)
