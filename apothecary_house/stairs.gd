extends Node3D
func _ready():
	_place_staircase()
func _place_staircase():
	var glb = load("res://apothecary_house/assets/medieval-left-turn-staircase.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.7, 1.7, 1.7)
	instance.rotation_degrees = Vector3(0, 90, 0)
	instance.position = Vector3(-2.2, 0.0, -0.7)
	add_child(instance)
	_strip_collision(instance)

	# Ramp 1 — lower flight (runs in -X direction, rises from Y=0 to Y=1.9)
	# Right end top: X=-2.1, Y=0.1 (floor level)
	# Left  end top: X=-4.661, Y=1.9 (landing right edge)
	var r1 = StaticBody3D.new()
	r1.position = Vector3(-3.467, 0.877, -0.7)
	r1.rotation_degrees = Vector3(0.0, 0.0, -35.0)
	var rc1 = CollisionShape3D.new()
	var rs1 = BoxShape3D.new()
	rs1.size = Vector3(3.126, 0.3, 1.5)
	rc1.shape = rs1
	r1.add_child(rc1)
	add_child(r1)

	# Landing pad (flat, connects lower to upper flight)
	var rl = StaticBody3D.new()
	rl.position = Vector3(-5.261, 1.75, -0.7)
	var rcl = CollisionShape3D.new()
	var rsl = BoxShape3D.new()
	rsl.size = Vector3(1.2, 0.3, 1.5)
	rcl.shape = rsl
	rl.add_child(rcl)
	add_child(rl)

	# Ramp 2 — upper flight (runs in +Z direction, rises from Y=1.9 to Y=4.1)
	# rotation.x must be NEGATIVE so the ramp rises with +Z (not descends)
	# center Y=2.885 puts the low end top surface at Y=1.9, flush with the landing
	var r2 = StaticBody3D.new()
	r2.position = Vector3(-5.073, 2.885, 1.749)
	r2.rotation_degrees = Vector3(-33.0, 0.0, 0.0)
	var rc2 = CollisionShape3D.new()
	var rs2 = BoxShape3D.new()
	rs2.size = Vector3(1.5, 0.3, 4.08)
	rc2.shape = rs2
	r2.add_child(rc2)
	add_child(r2)

	# Handrail collision — lower flight open side (Z≈+0.08, runs along -X direction)
	# X extent matches ramp body (-4.833 to -2.101) — stops before transition zone at X≈-5
	var hg1 = StaticBody3D.new()
	hg1.position = Vector3(-3.467, 1.25, 0.08)
	var hc1 = CollisionShape3D.new()
	var hs1 = BoxShape3D.new()
	hs1.size = Vector3(2.73, 2.5, 0.1)
	hc1.shape = hs1
	hg1.add_child(hc1)
	add_child(hg1)

	# Handrail collision — upper flight open side (X≈-4.3, runs along +Z direction)
	var hg2 = StaticBody3D.new()
	hg2.position = Vector3(-4.3, 3.1, 1.75)
	var hc2 = CollisionShape3D.new()
	var hs2 = BoxShape3D.new()
	hs2.size = Vector3(0.1, 2.5, 3.5)
	hc2.shape = hs2
	hg2.add_child(hc2)
	add_child(hg2)

func _strip_collision(node: Node):
	for child in node.get_children():
		if child is CollisionObject3D:
			child.collision_layer = 0
			child.collision_mask = 0
		_strip_collision(child)
