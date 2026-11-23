extends Node3D

const PLAYER_SPAWN = Vector3(0, 0.1, 1)

@export_group("Counter")
@export var counter_scale: float = 0.00052
@export var counter_pos: Vector3 = Vector3(-0.75, -0.5, 0.15)

@export_group("Workbench Table")
@export var workbench_scale: float = 1.0
@export var workbench_pos: Vector3 = Vector3(0, 0, 0)

@export_group("Mortar")
@export var mortar_scale: float = 0.128
@export var mortar_pos: Vector3 = Vector3(-0.257, -0.861, -0.065)

@export_group("Customer")
@export var customer_scale: float = 1.0
@export var customer_pos: Vector3 = Vector3(0, -0.9, 0)

func _ready():
	_load_apothecary_shell()
	var music = load("res://audio/music.mp3")
	if music:
		music.loop = true
		var music_player = AudioStreamPlayer.new()
		music_player.stream = music
		music_player.volume_db = -6.0
		add_child(music_player)
		music_player.play()
	var player = $Player
	if player:
		player.add_to_group("player")
		player.global_position = PLAYER_SPAWN
		player.rotation_degrees.y = 180.0
	_apply_floor_texture()
	_apply_wall_texture()
	_place_streets()
	_place_counter()
	_place_workbench_model()
	_place_mortar_model()
	# _place_herb_model() removed — herbs now come from planter pots
	_place_vial_model()
	_place_customer()
	_place_door()
	_place_windows()
	_place_interior_wall()
	_place_bookcase()
	_place_reading_table()
	_place_forge()
	_place_shelf()
	_place_ingredient_rack()
	_place_window_table()
	_place_back_door()
	_place_bed()
	_place_ceiling_and_second_floor()
	_place_staircase()
	_place_long_window_table()
	_place_pots()
	_place_watering_cup()
	_place_water_bucket()
	_place_bed_sleep_trigger()
	#_place_well()
	_place_field()
	_place_neighbor_house()
	_place_twin_chimney_house()
	_place_side_ground()
	_place_wagon()
	#_place_shed()
	_place_firewood_rack()
	_place_refuse_bin()
	_place_corner_house()
	_place_dyers_corner_house()
	_place_row_house()
	_place_coopers_house()
	_place_undertakers_house()
	_place_passage_house()

	_place_lantern_house()
	_place_narrow_merchant_courtyard()
	_place_crooked_spindle()
	_place_black_ledger()
	_place_row_house_west()
	_place_thirteenth_hour()
	_place_sable_court()
	_place_bell_ringers()
	_place_hollowmere()
	_place_hollow_stag_tavern()
	_place_hollow_lantern()
	_place_rookery()
	_place_tallow_lane()
	_place_ashwatch()
	_place_tallow_lane_2()

	_place_mid_cross_house()
	_place_tallow_lane_cross()
	_place_iron_quill()
	_place_saint_oswin()
	_place_barrowroot()
	#_place_left_tcross_houses()
	#_place_left_tcross_street()
	_place_river()
	_place_forest()
	var _placer := Node.new()
	_placer.name = "DebugPlacer"
	_placer.set_script(load("res://scripts/debug_placer.gd"))
	add_child(_placer)

func _place_river():
	var glb = load("res://models/broken-river-strip-50m.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	# River runs 50m along X, 16m across Z.
	# Near bank (GLB +Z) aligns with street end at world Z=-13;
	# center of river is 8m further: Z=-13-8=-21. Far bank ends at Z=-29.
	instance.position = Vector3(1.5, 0.0, -21.0)
	instance.rotation_degrees.y = 180.0
	add_child(instance)
	_strip_collision(instance)
	_fix_river_materials(instance)

	# Near-bank (apothecary side): Z -13 → -16.6, full river length in X
	var near_body = StaticBody3D.new()
	near_body.position = Vector3(1.5, 0.0, -14.8)
	add_child(near_body)
	var near_col = CollisionShape3D.new()
	var near_shape = BoxShape3D.new()
	near_shape.size = Vector3(50.0, 0.2, 3.6)
	near_col.shape = near_shape
	near_body.add_child(near_col)

	# Far-bank (other side): Z -25.4 → -29
	var far_body = StaticBody3D.new()
	far_body.position = Vector3(1.5, 0.0, -27.2)
	add_child(far_body)
	var far_col = CollisionShape3D.new()
	var far_shape = BoxShape3D.new()
	far_shape.size = Vector3(50.0, 0.2, 3.6)
	far_col.shape = far_shape
	far_body.add_child(far_col)

	# Bridge walkway — flat box at same level as banks (top at Y=0.1)
	# Spans from near-bank end (Z=-16.6) through far-bank start (Z=-25.4)
	var bridge_body = StaticBody3D.new()
	bridge_body.position = Vector3(1.5, 0.0, -21.0)
	add_child(bridge_body)
	var bridge_col = CollisionShape3D.new()
	var bridge_shape = BoxShape3D.new()
	bridge_shape.size = Vector3(3.0, 0.2, 9.0)
	bridge_col.shape = bridge_shape
	bridge_body.add_child(bridge_col)

	# Water — deep safety net only, far below walkable surfaces
	var water_body = StaticBody3D.new()
	water_body.position = Vector3(1.5, -5.0, -21.0)
	add_child(water_body)
	var water_col = CollisionShape3D.new()
	var water_shape = BoxShape3D.new()
	water_shape.size = Vector3(50.0, 0.2, 16.0)
	water_col.shape = water_shape
	water_body.add_child(water_col)

	# Bridge side walls — stop player walking off the edges into the river
	for side in [-1, 1]:
		var wall = StaticBody3D.new()
		wall.position = Vector3(1.5 + side * 1.6, 1.0, -21.0)
		add_child(wall)
		var wc = CollisionShape3D.new()
		var ws = BoxShape3D.new()
		ws.size = Vector3(0.2, 2.0, 9.5)
		wc.shape = ws
		wall.add_child(wc)

func _fix_river_materials(node: Node) -> void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var orig = node.mesh.surface_get_material(i)
			var mat_name = orig.resource_name if orig else ""
			var replacement: StandardMaterial3D
			match mat_name:
				"Wet dark river mud":
					replacement = StandardMaterial3D.new()
					replacement.albedo_color = Color(0.15, 0.11, 0.07)
					replacement.roughness = 1.0
				"Cut bank earth":
					replacement = StandardMaterial3D.new()
					replacement.albedo_color = Color(0.28, 0.20, 0.12)
					replacement.roughness = 1.0
				"Dark river stones":
					replacement = StandardMaterial3D.new()
					replacement.albedo_color = Color(0.18, 0.17, 0.15)
					replacement.roughness = 1.0
				"Old bridge oak":
					replacement = StandardMaterial3D.new()
					replacement.albedo_color = Color(0.22, 0.15, 0.09)
					replacement.roughness = 0.9
			if replacement:
				node.set_surface_override_material(i, replacement)
	for child in node.get_children():
		_fix_river_materials(child)

func _build_pine_mesh() -> ArrayMesh:
	var arr_mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	const SIDES = 12  # rounder silhouette, still cheap

	# Surface 0: trunk — 12-sided cylinder
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tr := 0.13; var th := 1.5
	for i in SIDES:
		var a0 := TAU * i / SIDES
		var a1 := TAU * (i + 1) / SIDES
		var b0 := Vector3(tr * cos(a0), 0.0, tr * sin(a0))
		var b1 := Vector3(tr * cos(a1), 0.0, tr * sin(a1))
		var t0 := Vector3(tr * cos(a0), th,  tr * sin(a0))
		var t1 := Vector3(tr * cos(a1), th,  tr * sin(a1))
		st.add_vertex(b0); st.add_vertex(t0); st.add_vertex(t1)
		st.add_vertex(b0); st.add_vertex(t1); st.add_vertex(b1)
	st.generate_normals()
	st.commit(arr_mesh)
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.20, 0.12, 0.07)
	tm.roughness = 1.0
	arr_mesh.surface_set_material(0, tm)

	# Surface 1: 5 overlapping foliage tiers — all in one surface, per-vertex colour
	# Each tier is a wide flat cone; they overlap so there are no gaps.
	# Colour gradient: darkest at base, slightly lighter at top.
	var tiers: Array = [
		# [base_y, radius, height, Color]
		[0.4,  2.0,  0.8,  Color(0.045, 0.130, 0.035)],
		[0.95, 1.65, 0.82, Color(0.055, 0.155, 0.045)],
		[1.5,  1.25, 0.86, Color(0.065, 0.175, 0.055)],
		[2.05, 0.82, 0.90, Color(0.080, 0.200, 0.065)],
		[2.6,  0.42, 1.10, Color(0.095, 0.225, 0.075)],
	]
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tier in tiers:
		var base_y: float = tier[0]
		var radius: float = tier[1]
		var height: float = tier[2]
		var col: Color  = tier[3]
		var apex := Vector3(0.0, base_y + height, 0.0)
		for i in SIDES:
			var a0 := TAU * i / SIDES
			var a1 := TAU * (i + 1) / SIDES
			var v0 := Vector3(radius * cos(a0), base_y, radius * sin(a0))
			var v1 := Vector3(radius * cos(a1), base_y, radius * sin(a1))
			# Cone face
			st.set_color(col); st.add_vertex(apex)
			st.set_color(col); st.add_vertex(v0)
			st.set_color(col); st.add_vertex(v1)
	st.generate_normals()
	st.commit(arr_mesh)
	var fm := StandardMaterial3D.new()
	fm.vertex_color_use_as_albedo = true
	fm.roughness = 1.0
	arr_mesh.surface_set_material(1, fm)

	return arr_mesh

func _collect_meshes(node: Node, out: Array) -> void:
	if node is MeshInstance3D and node.mesh:
		out.append(node.mesh)
	for child in node.get_children():
		_collect_meshes(child, out)

func _gen_xforms(rng: RandomNumberGenerator, count: int,
		x_min: float, x_max: float, z_min: float, z_max: float,
		s_min: float, s_max: float) -> Array:
	# Tree GLB is Z-up — rotate -90° around X so it stands upright in Godot's Y-up world
	var stand_up := Basis(Vector3.RIGHT, -PI / 2.0)
	var result := []
	for i in count:
		var x := rng.randf_range(x_min, x_max)
		var z := rng.randf_range(z_min, z_max)
		var s := rng.randf_range(s_min, s_max)
		var rot := rng.randf_range(0.0, TAU)
		var basis := (Basis(Vector3.UP, rot) * stand_up).scaled(Vector3(s, s, s))
		result.append(Transform3D(basis, Vector3(x, 0.0, z)))
	return result

func _spawn_multimesh(mesh: Mesh, xforms: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)

func _place_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	# Collect all mesh parts from GLB (leaves + trunk); fallback to procedural
	var mesh_list: Array = []
	var glb = load("res://models/pine-tree.glb")
	if glb:
		var scene = glb.instantiate()
		_collect_meshes(scene, mesh_list)
		scene.queue_free()
	if mesh_list.is_empty():
		mesh_list.append(_build_pine_mesh())

	# Generate shared transforms for each layer (all mesh parts use same positions)
	var front := _gen_xforms(rng, 150, -40.0, 43.0, -30.0, -42.0, 3.0, 5.0)
	var back  := _gen_xforms(rng, 250, -40.0, 43.0, -42.0, -60.0, 4.5, 7.0)
	for mesh in mesh_list:
		_spawn_multimesh(mesh, front)
		_spawn_multimesh(mesh, back)

	# Dark backdrop wall — blocks the void behind the treeline
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.04, 0.03, 0.02)
	wall_mat.roughness = 1.0
	wall_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_make_wall_segment(Vector3(1.5, 7.0, -64.0), Vector3(120.0, 14.0, 0.3), wall_mat)

	# Forest floor — dark earthy ground from river bank to back of forest (Z -29 → -65)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.10, 0.08, 0.05)
	floor_mat.roughness = 1.0
	_make_street_plane(Vector3(1.5, 0.0, -47.0), Vector2(83.0, 36.0), floor_mat)

	# Invisible wall at treeline
	var wall := StaticBody3D.new()
	wall.position = Vector3(1.5, 3.0, -30.0)
	add_child(wall)
	var wc := CollisionShape3D.new()
	var ws := BoxShape3D.new()
	ws.size = Vector3(83.0, 6.0, 0.3)
	wc.shape = ws
	wall.add_child(wc)

	# Depth fog
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.06, 0.05)
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_density = 0.035
	env.fog_light_color = Color(0.08, 0.06, 0.05)
	env.fog_sky_affect = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _place_refuse_bin():
	var glb = load("res://models/medieval-apothecary-refuse-bin.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.position = Vector3(5.3, 0.0, -1.83)
	instance.rotation_degrees.y = -90
	instance.scale = Vector3(2, 2, 2)
	add_child(instance)
	_add_blocker(Vector3(5.3, 0.4, -1.83), Vector3(1.0, 0.8, 0.8))

func _place_firewood_rack():
	var body = StaticBody3D.new()
	body.set_script(load("res://scripts/firewood_trigger.gd"))
	# Next to the forge toward the back wall, against the right wall — front faces into the room
	body.position = Vector3(5.3, 0.0, -0.6)
	body.rotation_degrees.y = -90
	body.scale = Vector3(2, 2, 2)
	add_child(body)

func _place_well():
	var body = StaticBody3D.new()
	body.set_script(load("res://scripts/well_node.gd"))
	# In the backyard, 7m behind the house, slightly right of centre
	body.position = Vector3(4.5, 0.0, -12.0)
	body.rotation_degrees.y = 90
	add_child(body)

func _place_neighbor_house():
	var glb = load("res://models/medieval-narrow-merchant-house-2.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var s = 1.6
	instance.scale = Vector3(s, s, s)
	# Left edge at X=6.5, door face at Z=5 — offset accounts for scale
	instance.position = Vector3(
		6.5 - (-1.828 * s),  # 8.876
		0.0,
		5.0 - (1.295 * s)    # 3.317
	)
	add_child(instance)

func _place_twin_chimney_house():
	var glb = load("res://models/medieval-twin-chimney-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var s = 1.6
	instance.scale = Vector3(s, s, s)
	# Clean GLB — no Sketchfab rotation quirk, positions are direct world offsets.
	# Wing extends to local X≈-5.16; align left wing edge to X≈12.5 (small gap from merchant house)
	# Door face at local Z≈1.835; align to street front at Z=5.0
	instance.position = Vector3(
		12.5 + 5.16 * s,  # wing left edge at world X=12.5
		0.0,
		5.0 - 1.835 * s   # door face at world Z=5
	)
	add_child(instance)

func _place_wagon():
	var glb = load("res://models/medieval-trade-wagon-with-horse-2.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	# Horse faces +Z by default; 180° puts it facing away from the street
	instance.rotation_degrees.y = 180
	# Centered in the gap between merchant house (right edge X≈12.35) and twin chimney wing (X≈16.2)
	instance.position = Vector3(14.0, 0.0, 3.0)
	add_child(instance)

	# Interaction trigger on the near side of the wagon (player-facing side, Z≈4.5)
	var cart = StaticBody3D.new()
	cart.set_script(load("res://scripts/merchant_cart.gd"))
	cart.collision_layer = 2
	cart.collision_mask  = 0
	cart.position = Vector3(14.0, 1.0, 4.5)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.0, 2.0, 0.4)
	col.shape = shape
	cart.add_child(col)
	add_child(cart)

func _place_side_ground():
	# Gravel ground to the right of the shop and forward street (X: 6→28, Z: -8→40)
	var area_w = 22.0
	var area_d = 48.0
	var center = Vector3(17.0, 0.0, 16.0)

	# Collision so the player can walk here
	var body = StaticBody3D.new()
	body.position = center + Vector3(0, -0.1, 0)
	add_child(body)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(area_w, 0.2, area_d)
	col.shape = shape
	body.add_child(col)

	# Gravel material — same as the streets
	var albedo  = load("res://models/gravel_macro__tile_texture_0.jpg")
	var rough   = load("res://models/gravel_macro__tile_texture_1.png")
	var normal  = load("res://models/gravel_macro__tile_texture_2.jpg")
	var mat = StandardMaterial3D.new()
	if albedo: mat.albedo_texture = albedo
	if rough:  mat.roughness_texture = rough
	if normal:
		mat.normal_enabled = true
		mat.normal_texture = normal
	mat.uv1_scale = Vector3(14, 30, 1)
	mat.roughness = 1.0

	var ground = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(area_w, area_d)
	plane_mesh.material = mat
	ground.mesh = plane_mesh
	ground.position = center + Vector3(0, -0.001, 0)
	add_child(ground)

func _place_shed():
	var glb = load("res://models/medieval-open-backyard-shed.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	# Shed back wall sits at local Z≈-1.149; house outer back wall is at world Z=-5
	# Centered at X=0 (shed is ~4m wide, back door is at X=-4.5 — no overlap)
	instance.scale = Vector3(1.5, 1.5, 1.5)
	instance.rotation_degrees.y = 180
	# After 180° Y rotation, local X and Z axes flip in world space.
	# Right edge (local X=-2.029) → world X = pos.x + 2.029*scale; align to house right corner X=6
	# Back wall (local Z=-1.149) → world Z = pos.z + 1.149*scale; align flush to house back wall Z=-5
	instance.position = Vector3(
		6.0 - 2.029 * 1.5,   #  2.956 — right edge at X=6
		0.0,
		-5.0 - 1.149 * 1.5   # -6.724 — back wall at Z=-5
	)
	add_child(instance)

func _place_field():
	# Back lane — same gravel material as the front cross-street
	var albedo = load("res://models/gravel_macro__tile_texture_0.jpg")
	var rough  = load("res://models/gravel_macro__tile_texture_1.png")
	var normal = load("res://models/gravel_macro__tile_texture_2.jpg")
	var mat = StandardMaterial3D.new()
	if albedo: mat.albedo_texture = albedo
	if rough:  mat.roughness_texture = rough
	if normal:
		mat.normal_enabled = true
		mat.normal_texture = normal
	mat.roughness = 1.0
	mat.uv1_scale = Vector3(53, 5, 1)
	# 83m wide × 8m deep, covering Z -5 → -13 (behind house back wall)
	_make_street_plane(Vector3(1.5, 0, -9.0), Vector2(83, 8), mat)

func _place_riverside_field_border():
	var glb = load("res://models/riverside-field-border.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	# Field clear bounds in border local space: X -6..6, Z 0..25
	# Our backyard runs Z -5..-30, so place at (0, 0, -5) rotated 180° to flip Z
	var pos = Vector3(0.0, 0.0, -5.0)
	instance.position = pos
	instance.rotation_degrees.y = 180.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 180.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/riverside-field-border-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			if entry.has("points"):
				var shape = ConvexPolygonShape3D.new()
				var points = PackedVector3Array()
				for p in entry.points:
					points.append(Vector3(p[0], p[1], p[2]))
				shape.points = points
				col.shape = shape
			else:
				var shape = BoxShape3D.new()
				var s = entry["size"]
				shape.size = Vector3(s[0], s[1], s[2])
				col.shape = shape
				var p = entry["position"]
				col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

func _place_grass():
	var glb = load("res://models/grass_tile_texture.glb")
	if not glb:
		return
	# Extract the material from the GLB's Plane mesh
	var scene = glb.instantiate()
	var mesh_inst = scene.find_child("Plane_Material_0", true, false)
	var mat = null
	if mesh_inst is MeshInstance3D and mesh_inst.mesh and mesh_inst.mesh.get_surface_count() > 0:
		mat = mesh_inst.mesh.surface_get_material(0)
	scene.queue_free()
	# Build a clean PlaneMesh sized exactly to the field — no transform headaches
	var ground = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(12.0, 25.0)
	if mat:
		plane_mesh.material = mat
	ground.mesh = plane_mesh
	ground.position = Vector3(0.0, 0.01, -17.5)
	add_child(ground)

func _place_pots():
	# AABB: bottom at local Y=0, height=0.198, radius≈0.118.
	# Scale=1.5 → pot ~30 cm tall. Body Y=1.1 = table surface.
	var glb = load("res://models/medieval-terracotta-planter.glb")
	var pot_script = load("res://scripts/planter_pot.gd")
	var pot_y = 1.15
	var pot_scale = 1.5

	var pot_data = [
		{ "pos": Vector3(1.9,    pot_y, 4.35), "plant": "snake_plant" },
		{ "pos": Vector3(2.75,   pot_y, 4.35), "plant": "basil"       },
		{ "pos": Vector3(3.6,    pot_y, 4.35), "plant": "aloe_vera"   },
		{ "pos": Vector3(4.45,   pot_y, 4.35), "plant": "bee_balm"    },
		{ "pos": Vector3(5.3,    pot_y, 4.35), "plant": "calendula"   },
		{ "pos": Vector3(-3.525, pot_y, 4.35), "plant": "chamomile"   },
	]

	for entry in pot_data:
		var pos = entry["pos"]
		var body = StaticBody3D.new()
		body.set_script(pot_script)
		body.position = pos
		body.collision_layer = 2
		body.collision_mask = 0

		# Collision scaled to match GLB at pot_scale
		var col = CollisionShape3D.new()
		var shape = CylinderShape3D.new()
		shape.height = 0.198 * pot_scale
		shape.radius = 0.118 * pot_scale
		col.shape = shape
		col.position = Vector3(0, 0.099 * pot_scale, 0)  # centre over visible pot
		body.add_child(col)

		if glb:
			var visual = glb.instantiate()
			visual.scale = Vector3(pot_scale, pot_scale, pot_scale)
			visual.position = Vector3.ZERO
			body.add_child(visual)
			_strip_collision(visual)
			body.pot_visual_root = visual

		add_child(body)
		body.start_mature(entry["plant"])

func _place_watering_cup():
	var body = StaticBody3D.new()
	body.set_script(load("res://scripts/watering_cup.gd"))
	body.position = Vector3(1.4, 1.15, 4.35)
	body.collision_layer = 2
	body.collision_mask = 0

	# Collision centred over the cup body (local Y 0→0.16 at scale=1.5 → centre 0.12)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.3, 0.25, 0.3)
	col.shape = shape
	col.position = Vector3(0, 0.12, 0)
	body.add_child(col)

	body.rotation_degrees.y = -70  # 20° toward right wall
	add_child(body)  # _ready() in watering_cup.gd loads the GLB visual

	# Cup spot — always raycastable; handles put-back when cup is in hand
	var spot = StaticBody3D.new()
	spot.set_script(load("res://scripts/cup_spot.gd"))
	spot.position = Vector3(1.4, 1.15, 4.35)
	spot.collision_layer = 2
	spot.collision_mask = 0
	var spot_col = CollisionShape3D.new()
	var spot_shape = BoxShape3D.new()
	spot_shape.size = Vector3(0.3, 0.25, 0.3)
	spot_col.shape = spot_shape
	spot_col.position = Vector3(0, 0.12, 0)
	spot.add_child(spot_col)
	add_child(spot)
	spot.cup = body

func _place_water_bucket():
	var body = StaticBody3D.new()
	body.set_script(load("res://scripts/water_bucket.gd"))
	body.position = Vector3(5.1, 0, 3.4)
	body.collision_layer = 3
	body.collision_mask = 0

	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.height = 0.90
	shape.radius = 0.52
	col.shape = shape
	col.position = Vector3(0, 0.45, 0)
	body.add_child(col)

	add_child(body)  # _ready() in water_bucket.gd loads the GLB visual

func _place_bed_sleep_trigger():
	var body = StaticBody3D.new()
	body.set_script(load("res://scripts/bed_sleep.gd"))
	body.position = Vector3(-5.0, 0.5, 2.5)
	body.collision_layer = 2
	body.collision_mask = 0

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.5, 1.5, 2.0)
	col.shape = shape
	body.add_child(col)

	add_child(body)

func _apply_floor_texture():
	pass # Replaced by the imported architectural shell.

func _apply_wall_texture():
	pass # Replaced by the imported architectural shell.

func _place_streets():
	var albedo  = load("res://models/gravel_macro__tile_texture_0.jpg")
	var rough   = load("res://models/gravel_macro__tile_texture_1.png")
	var normal  = load("res://models/gravel_macro__tile_texture_2.jpg")
	var mat = StandardMaterial3D.new()
	if albedo: mat.albedo_texture = albedo
	if rough:  mat.roughness_texture = rough
	if normal:
		mat.normal_enabled = true
		mat.normal_texture = normal
	mat.roughness = 1.0

	# Left-right street: 83m wide × 7m deep, centered at X=1.5 (covers X -40 to +43), Z 5→12
	mat.uv1_scale = Vector3(53, 5, 1)
	_make_street_plane(Vector3(1.5, 0, 8.5), Vector2(83, 7), mat)

	# Forward area: Z 12→62, past Tallow Lane (Z=41) with some margin
	var mat2 = mat.duplicate()
	mat2.uv1_scale = Vector3(53, 33, 1)
	_make_street_plane(Vector3(1.5, 0.001, 37.0), Vector2(83, 50), mat2)

	# Left-end wall (X=-40) matched to forward area Z range
	var lw = StaticBody3D.new()
	lw.position = Vector3(-40.0, 2, 37.0)
	add_child(lw)
	var lwc = CollisionShape3D.new()
	var lws = BoxShape3D.new()
	lws.size = Vector3(0.2, 4, 50)
	lwc.shape = lws
	lw.add_child(lwc)

func _make_street_plane(pos: Vector3, size: Vector2, mat: Material):
	var body = StaticBody3D.new()
	body.position = pos
	add_child(body)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(size.x, 0.2, size.y)
	col.shape = shape
	body.add_child(col)
	var mesh_inst = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = size
	plane.material = mat
	mesh_inst.mesh = plane
	body.add_child(mesh_inst)

func _place_counter():
	var glb = load("res://models/counter.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(counter_scale, counter_scale, counter_scale)
	instance.position = counter_pos
	$Counter/Mesh.visible = false
	$Counter.add_child(instance)

func _place_workbench_model():
	var glb = load("res://models/apothecary_workbench.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var wb_scale = 5.0
	instance.scale = Vector3(wb_scale, wb_scale, wb_scale)
	instance.position = workbench_pos
	instance.rotation_degrees = Vector3(0, 90, 0)
	$Workbench/Mesh.visible = false
	$Workbench.add_child(instance)
	_add_blocker(Vector3(4.5, 0.55, -3.5), Vector3(1.0, 1.1, 2.5))

func _place_mortar_model():
	var glb = load("res://models/stone_mortar.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.name = "Mortar"
	instance.scale = Vector3(2.0, 2.0, 2.0)
	instance.position = Vector3(0, 0, 0)
	$Mortar/Mesh.visible = false
	$Mortar.add_child(instance)
	$Mortar.setup(instance)

func _place_herb_model():
	var glb = load("res://models/herb_plant.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(2.0, 2.0, 2.0)
	instance.position = Vector3(0, 0, 0)
	$Herbs/Mesh.visible = false
	$Herbs.add_child(instance)
	_strip_collision(instance)
	$Herbs.setup(instance)

func _place_windows():
	pass # Replaced by the imported architectural shell.

func _place_vial_model():
	var glb = load("res://models/vial.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(2.0, 2.0, 2.0)
	instance.position = Vector3(0, 0, 0)
	$Vial/Mesh.visible = false
	$Vial.add_child(instance)
	_strip_collision(instance)
	$Vial.setup(instance)

func _place_customer():
	var glb = load("res://models/Walking.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(customer_scale, customer_scale, customer_scale)
	instance.position = customer_pos
	instance.rotation_degrees = Vector3(0, 180, 0)
	$Customer/Mesh.visible = false
	$Customer.add_child(instance)
	var anim_player = _find_node_by_name(instance, "AnimationPlayer")
	if anim_player:
		$Customer.set_animation_player(anim_player)

func _place_door():
	var shell = get_node("ApothecaryHouseShell")
	var door_node = shell.find_part("FrontDoorPivot")
	var pivot = Node3D.new()
	pivot.set_script(preload("res://scripts/door_pivot.gd"))
	pivot.add_to_group("door_pivot")
	pivot.blocker = $DoorBlocker
	pivot.door_node = door_node
	add_child(pivot)
	var trigger = StaticBody3D.new()
	trigger.set_script(preload("res://scripts/door_handle.gd"))
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.5,3.5,.5)
	col.shape = shape
	col.position = Vector3(0,1.5,0)
	trigger.add_child(col)
	trigger.collision_layer = 2
	trigger.collision_mask = 0
	trigger.pivot = pivot
	add_child(trigger)
	trigger.global_position = Vector3(0,0,5)

func _place_reading_table():
	var glb = load("res://models/counter.glb")
	if not glb:
		return
	# Body offset so GLB (at counter_pos) ends up centred at world (-4, 0, -3)
	var body = StaticBody3D.new()
	body.position = Vector3(-4.1, 0.5, -2.5)
	add_child(body)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.5, 1.1, 1.0)
	col.shape = shape
	col.position = Vector3(-0.75, 0.0, 0.15)  # align with GLB visual centre
	body.add_child(col)
	var instance = glb.instantiate()
	var rt_scale = counter_scale * 1.05
	instance.scale = Vector3(rt_scale, rt_scale, rt_scale)
	instance.position = counter_pos
	body.add_child(instance)
	_place_books_on_table()

func _place_books_on_table():
	# Open book — upright in Godot, lay flat with Rx(-90)
	var open_glb = load("res://models/medieval_open_book_1.glb")
	if open_glb:
		var book_body = StaticBody3D.new()
		book_body.collision_layer = 2
		book_body.collision_mask = 0
		book_body.set_script(preload("res://scripts/open_book.gd"))
		book_body.position = Vector3(-3.95, 1.15, -2.75)
		add_child(book_body)
		var col = CollisionShape3D.new()
		var cshape = BoxShape3D.new()
		cshape.size = Vector3(0.55, 0.35, 0.45)
		col.shape = cshape
		book_body.add_child(col)
		var inst = open_glb.instantiate()
		inst.scale = Vector3(0.28, 0.28, 0.28)
		inst.rotation_degrees = Vector3(-90, 0, 0)
		book_body.add_child(inst)
		_strip_collision(inst)

	# Afflictions book — same mesh, slightly right and rotated, opens afflictions_popup
	if open_glb:
		var book_body2 = StaticBody3D.new()
		book_body2.collision_layer = 2
		book_body2.collision_mask = 0
		book_body2.set_script(preload("res://scripts/afflictions_book.gd"))
		book_body2.position = Vector3(-3.2, 1.15, -2.70)
		add_child(book_body2)
		var col2 = CollisionShape3D.new()
		var cshape2 = BoxShape3D.new()
		cshape2.size = Vector3(0.45, 0.08, 0.35)
		col2.shape = cshape2
		book_body2.add_child(col2)
		var inst2 = open_glb.instantiate()
		inst2.scale = Vector3(0.28, 0.28, 0.28)
		inst2.rotation_degrees = Vector3(-90, 20, 0)
		book_body2.add_child(inst2)
		_strip_collision(inst2)

	# Book stack — already upright
	var stack_glb = load("res://models/medieval_book_stack.glb")
	if stack_glb:
		var stack = stack_glb.instantiate()
		stack.scale = Vector3(0.011, 0.011, 0.011)
		stack.position = Vector3(-4.7, 1.15, -2.75)
		add_child(stack)
		_strip_collision(stack)

func _place_bookcase():
	var glb = load("res://models/medieval_bookcase.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(0.05, 0.05, 0.05)
	instance.rotation_degrees = Vector3(0, 180, 0)
	add_child(instance)
	instance.global_position = Vector3(-4.0, 0.0, -1.6)
	_strip_collision(instance)
	_add_blocker(Vector3(-4.0, 1.0, -1.6), Vector3(2.0, 2.0, 0.8))

func _place_interior_wall():
	pass # Replaced by the imported architectural shell.

func _place_forge():
	var body = StaticBody3D.new()
	body.set_script(load("res://scripts/forge_trigger.gd"))
	body.scale = Vector3(0.8, 0.8, 0.8)
	body.rotation_degrees = Vector3(0, -90, 0)
	body.position = Vector3(5.3, 0, 1.5)
	add_child(body)

func _place_window_table():
	var glb = load("res://models/window_plant_table.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(2.0, 2.0, 2.0)
	instance.position = Vector3(-3.525, 0, 4.35)
	add_child(instance)
	_strip_collision(instance)
	_add_blocker(Vector3(-3.525, 0.5, 4.35), Vector3(1.4, 1.0, 0.5))

func _place_long_window_table():
	var glb = load("res://models/medieval-long-window-plant-table-2.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(2.0, 2.0, 2.0)
	instance.position = Vector3(3.525, 0, 4.35)
	add_child(instance)
	_strip_collision(instance)
	_add_blocker(Vector3(3.525, 0.5, 4.35), Vector3(4.0, 1.0, 0.5))


func _place_ingredient_rack():
	var glb = load("res://models/ingredient_rack.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.3, 1.3, 1.3)
	instance.rotation_degrees = Vector3(0, 270, 0)
	# Local offset: $Rack body is at (5.0, 2.0, -1.0); GLB visual world target (5.5, 3.0, -1.0)
	instance.position = Vector3(0.5, 1.0, 0.0)
	$Rack.add_child(instance)
	_strip_collision(instance)
	$Rack.setup(instance)

func _place_bed():
	var glb = load("res://models/medieval-single-bed.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.5, 1.5, 1.5)
	# Bed along left wall (X=-6): length runs along Z, headboard toward back wall
	instance.rotation_degrees = Vector3(0, 180, 0)
	instance.position = Vector3(-5.0, 0.0, 2.5)
	add_child(instance)
	_strip_collision(instance)
	_add_blocker(Vector3(-5.0, 0.3, 2.5), Vector3(1.5, 0.6, 2.4))
	# Lower the bedding so it sits inside the frame rather than floating above it
	var bedding = ["Bedding | linen tick mattress", "Bedding | stuffed linen pillow", "Bedding | draped olive wool blanket"]
	for child in instance.get_children():
		if child.name in bedding:
			child.position.y -= 0.06

func _place_shelf():
	var glb = load("res://models/alchemist_shelf.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(2.8, 2.8, 2.8)
	instance.rotation_degrees = Vector3(0, 90, 0)
	instance.position = Vector3(5.5, 0.65, -3.5)
	add_child(instance)
	_strip_collision(instance)
	_add_blocker(Vector3(5.5, 1.5, -3.5), Vector3(0.4, 3.0, 2.5))

func _place_back_door():
	var shell = get_node("ApothecaryHouseShell")
	var blocker = StaticBody3D.new()
	blocker.position = Vector3(-4.5,1.2,-5)
	add_child(blocker)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.1,2.4,.2)
	col.shape = shape
	blocker.add_child(col)
	var pivot = Node3D.new()
	pivot.set_script(preload("res://scripts/door_pivot.gd"))
	pivot.blocker = blocker
	pivot.door_node = shell.find_part("BackDoorPivot")
	add_child(pivot)
	var trigger = StaticBody3D.new()
	trigger.set_script(preload("res://scripts/door_handle.gd"))
	var tc = CollisionShape3D.new()
	var ts = BoxShape3D.new()
	ts.size = Vector3(1.5,2.4,.5)
	tc.shape = ts
	tc.position = Vector3(0,1.2,0)
	trigger.add_child(tc)
	trigger.collision_layer = 2
	trigger.collision_mask = 0
	trigger.pivot = pivot
	add_child(trigger)
	trigger.global_position = Vector3(-4.5,0,-5)

func _place_staircase():
	var glb = load("res://models/medieval-left-turn-staircase.glb")
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

func _place_ceiling_and_second_floor():
	pass # Replaced by the imported architectural shell.

func _add_blocker(pos: Vector3, size: Vector3) -> void:
	var body = StaticBody3D.new()
	body.position = pos
	add_child(body)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

func _make_wall_segment(pos: Vector3, size: Vector3, mat: Material):
	var body = StaticBody3D.new()
	body.position = pos
	add_child(body)
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)


func _strip_oversized_meshes(node: Node, threshold: float):
	if node is MeshInstance3D and node.mesh:
		var aabb = node.mesh.get_aabb()
		if aabb.size.x > threshold or aabb.size.y > threshold or aabb.size.z > threshold:
			node.visible = false
	for child in node.get_children():
		_strip_oversized_meshes(child, threshold)

func _strip_collision(node: Node):
	if node is RigidBody3D:
		node.freeze = true
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
	for child in node.get_children():
		_strip_collision(child)

func _dim_glb_lights(node: Node, energy: float):
	if node is Light3D:
		node.light_energy = energy
	for child in node.get_children():
		_dim_glb_lights(child, energy)

func _disable_shadows(node: Node):
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows(child)

func _find_node_by_name(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var result = _find_node_by_name(child, target)
		if result:
			return result
	return null


func _place_corner_house():
	var glb = load("res://models/grim-medieval-corner-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.4, 1.4, 1.4)
	instance.rotation_degrees.y = 180.0
	# Left corner of the T-intersection: forward street left edge (X=-4) meets the cross-street (Z=12)
	instance.position = Vector3(-6.3, 0.0, 15.4)
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)

func _place_dyers_corner_house():
	var glb = load("res://models/grim-medieval-dyers-corner-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.4, 1.4, 1.4)
	instance.rotation_degrees.y = 270.0
	# Right corner of the T-intersection — mirrored from the left corner house
	instance.position = Vector3(6.3, 0.0, 15.4)
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)

func _place_row_house():
	var glb = load("res://models/grim-medieval-row-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.4, 1.4, 1.4)
	instance.rotation_degrees.y = 180.0
	# Next to the left corner house, shifted further left along the cross-street
	instance.position = Vector3(-13.6, 0.0, 14.6)
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)


func _place_coopers_house():
	var glb = load("res://models/grim-medieval-coopers-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.4, 1.4, 1.4)
	instance.rotation_degrees.y = 180.0
	# Next to the dyers corner house (right side, X=6.3, Z=15.4)
	instance.position = Vector3(13.1, 0.0, 14.8)
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)

func _place_undertakers_house():
	var glb = load("res://models/grim-medieval-undertakers-house-2.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.4, 1.4, 1.4)
	instance.rotation_degrees.y = 270.0
	# Further down the forward street, right side
	instance.position = Vector3(6.0, 0.0, 25.0)
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.3)

	var wagon_glb = load("res://models/undertaker-body-wagon.glb")
	if wagon_glb:
		var wagon = wagon_glb.instantiate()
		wagon.scale = Vector3(1.4, 1.4, 1.4)
		wagon.rotation_degrees.y = 270.0
		wagon.position = Vector3(12.6, 0.0, 23.4)
		add_child(wagon)
		_strip_collision(wagon)
	# Coffin cart drop trigger — player must be within DROP_RADIUS to drop a body
	var cart = Node3D.new()
	cart.set_script(load("res://scripts/coffin_cart.gd"))
	cart.position = Vector3(12.6, 0.0, 23.4)
	cart.rotation_degrees.y = 270.0
	add_child(cart)

func _place_passage_house():
	var glb = load("res://models/grim-medieval-passage-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.4, 1.4, 1.4)
	instance.rotation_degrees.y = 270.0
	# Next to the undertakers house, further down the right side
	instance.position = Vector3(6.1, 0.0, 34.3)
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)


func _place_undertaker_courtyard():
	# Closes the NE corner of the undertaker courtyard.
	# Gap runs from iron quill's north face (Z≈27) to passage house's south face (Z≈29.4),
	# spanning X≈13 (undertaker east face) to X≈23.6 (iron quill west face).
	# One building centred at X=18 with its back flush against the passage house fills it.
	var glb = load("res://models/grim-medieval-fire-scarred-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.4, 1.4, 1.4)
	instance.rotation_degrees.y = 180.0
	# Back face at Z≈29.4 (passage house south face); front faces south into courtyard
	instance.position = Vector3(18.0, 0.0, 25.9)
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)

func _place_lantern_house():
	var glb = load("res://models/grim-medieval-lantern-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.4, 1.4, 1.4)
	instance.rotation_degrees.y = 90.0
	# Left side, across the street from the undertakers house (Z≈25)
	instance.position = Vector3(-5.6, 0.0, 22.0)
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)

func _place_narrow_merchant_courtyard():
	var glb = load("res://models/blackthorn-gables-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.4, 1.4, 1.4)
	instance.rotation_degrees.y = 0.0
	# Behind and connected to the Tallow Lane house (5.3, 0, 41)
	var pos = Vector3(25.0, 0.0, 41.0)
	instance.position = pos
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	_disable_shadows(instance)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 0.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/blackthorn-gables-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			var s = entry.size
			shape.size = Vector3(s[0] * 1.4, s[1] * 1.4, s[2] * 1.4)
			col.shape = shape
			var p = entry.position
			col.position = Vector3(p[0] * 1.4, p[1] * 1.4, p[2] * 1.4)
			body.add_child(col)

func _place_ashwatch():
	var glb = load("res://models/ashwatch-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.4, 1.4, 1.4)
	instance.rotation_degrees.y = 0.0
	# Next to Blackthorn Gables (13.0, 0, 41), offset along X
	var pos = Vector3(16.0, 0.0, 41.0)
	instance.position = pos
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	_disable_shadows(instance)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 0.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/ashwatch-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			var s = entry.size
			shape.size = Vector3(s[0] * 1.4, s[1] * 1.4, s[2] * 1.4)
			col.shape = shape
			var p = entry.position
			col.position = Vector3(p[0] * 1.4, p[1] * 1.4, p[2] * 1.4)
			body.add_child(col)

func _place_black_ledger():
	var glb = load("res://models/black-ledger-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	# Left of Crooked Spindle (0.1m gap); front face matched to street
	var pos = Vector3(-17.81, 0.0, 1.95)
	instance.position = pos
	add_child(instance)
	_strip_collision(instance)
	# Passage-aware collision: boxes + convex vault sections from collisions.json
	var body = StaticBody3D.new()
	body.position = pos
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/black-ledger-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			if entry.has("points"):
				var shape = ConvexPolygonShape3D.new()
				var points = PackedVector3Array()
				for p in entry.points:
					points.append(Vector3(p[0], p[1], p[2]))
				shape.points = points
				col.shape = shape
			else:
				var shape = BoxShape3D.new()
				var s = entry.size
				shape.size = Vector3(s[0], s[1], s[2])
				col.shape = shape
				var p = entry.position
				col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

func _place_crooked_spindle():
	var glb = load("res://models/crooked-spindle-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	# Bounds: X ±3.918, Z: -3.6 to +4.258
	# Right edge flush with apothecary left wall (X=-6), 0.1m gap; front face at street Z=5
	instance.position = Vector3(-10.12, 0.0, 2.04)
	add_child(instance)
	_strip_collision(instance)
	# Box collision from house.tscn: 7.10 × 7.0 × 6.35, centre Y=3.5
	_add_blocker(Vector3(-10.12, 3.5, 2.04), Vector3(7.10, 7.0, 6.35))

func _place_row_house_west():
	var glb = load("res://models/grim-medieval-row-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.4, 1.4, 1.4)
	# Right up against the black ledger's west edge (X≈-21.2), same Z, facing north
	instance.position = Vector3(-24.0, 0.0, 2.15)
	instance.rotation_degrees.y = 180.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	_add_blocker(Vector3(-24.0, 5.5, 2.15), Vector3(9.0, 11.0, 6.0))

func _place_thirteenth_hour():
	var glb = load("res://models/thirteenth-hour-house.glb")
	if not glb:
		return
	var pos = Vector3(-24.86, 0.0, 11.06)
	var container = Node3D.new()
	container.set_script(load("res://scripts/thirteenth_hour_house.gd"))
	var model = glb.instantiate()
	model.name = "Model"
	container.add_child(model)
	_strip_collision(model)
	container.position = pos
	container.rotation_degrees.y = 90.0
	add_child(container)

func _place_sable_court():
	var glb = load("res://models/sable-court-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var pos = Vector3(-25.16, 0.0, 21.7)
	instance.position = pos
	instance.rotation_degrees.y = 90.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 90.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/sable-court-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			if entry.has("points"):
				var shape = ConvexPolygonShape3D.new()
				var points = PackedVector3Array()
				for p in entry.points:
					points.append(Vector3(p[0], p[1], p[2]))
				shape.points = points
				col.shape = shape
			else:
				var shape = BoxShape3D.new()
				var s = entry.size
				shape.size = Vector3(s[0], s[1], s[2])
				col.shape = shape
				var p = entry.position
				col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

func _place_bell_ringers():
	var glb = load("res://models/bell-ringers-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var pos = Vector3(-24.86, 0.0, 31.4)
	instance.position = pos
	instance.rotation_degrees.y = 90.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 90.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/bell-ringers-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			if entry.has("points"):
				var shape = ConvexPolygonShape3D.new()
				var points = PackedVector3Array()
				for p in entry.points:
					points.append(Vector3(p[0], p[1], p[2]))
				shape.points = points
				col.shape = shape
			else:
				var shape = BoxShape3D.new()
				var s = entry.size
				shape.size = Vector3(s[0], s[1], s[2])
				col.shape = shape
				var p = entry.position
				col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

func _place_hollow_stag_tavern():
	var glb = load("res://models/hollow-stag-tavern.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var pos = Vector3(-27.26, 0.0, 45.7)
	instance.position = pos
	instance.rotation_degrees.y = 90.0
	add_child(instance)
	# GLB includes interior collision — do not strip
	_dim_glb_lights(instance, 0.0)
	_disable_shadows(instance)
	var door = instance.find_child("FrontDoorPivot", true, false)
	if door:
		door.rotation_degrees.y = 98.0

func _place_hollowmere():
	var glb = load("res://models/hollowmere-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	# Across the street from Bell Ringers (X=-24.86, rot=90, faces +X)
	# Hollowmere at rot=270 faces -X — the two fronts look at each other
	var pos = Vector3(15.0, 0.0, 31.4)
	instance.position = pos
	instance.rotation_degrees.y = 270.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	_disable_shadows(instance)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 270.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/hollowmere-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			var s = entry.size
			shape.size = Vector3(s[0], s[1], s[2])
			col.shape = shape
			var p = entry.position
			col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

func _place_hollow_lantern():
	var glb = load("res://models/hollow-lantern-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var pos = Vector3(-5.6, 0.0, 30.0)
	instance.position = pos
	instance.rotation_degrees.y = 90.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 90.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/hollow-lantern-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			if entry.has("points"):
				var shape = ConvexPolygonShape3D.new()
				var points = PackedVector3Array()
				for p in entry.points:
					points.append(Vector3(p[0], p[1], p[2]))
				shape.points = points
				col.shape = shape
			else:
				var shape = BoxShape3D.new()
				var s = entry.size
				shape.size = Vector3(s[0], s[1], s[2])
				col.shape = shape
				var p = entry.position
				col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

func _place_tallow_lane_2():
	var glb = load("res://models/tallow-lane-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	instance.scale = Vector3(1.64, 1.64, 1.64)
	var pos = Vector3(25.0, 0.0, 30.0)
	instance.position = pos
	instance.rotation_degrees.y = 90.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 90.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/tallow-lane-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			if entry.has("points"):
				var shape = ConvexPolygonShape3D.new()
				var points = PackedVector3Array()
				for p in entry.points:
					points.append(Vector3(p[0], p[1], p[2]))
				shape.points = points
				col.shape = shape
			else:
				var shape = BoxShape3D.new()
				var s = entry.size
				shape.size = Vector3(s[0], s[1], s[2])
				col.shape = shape
				var p = entry.position
				col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

func _place_rookery():
	var glb = load("res://models/rookery-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var pos = Vector3(-5.3, 0.0, 38.0)
	instance.position = pos
	instance.rotation_degrees.y = 90.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 90.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/rookery-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			if entry.has("points"):
				var shape = ConvexPolygonShape3D.new()
				var points = PackedVector3Array()
				for p in entry.points:
					points.append(Vector3(p[0], p[1], p[2]))
				shape.points = points
				col.shape = shape
			else:
				var shape = BoxShape3D.new()
				var s = entry.size
				shape.size = Vector3(s[0], s[1], s[2])
				col.shape = shape
				var p = entry.position
				col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

func _place_tallow_lane():
	var glb = load("res://models/tallow-lane-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var pos = Vector3(5.3, 0.0, 41.0)
	instance.position = pos
	instance.rotation_degrees.y = 270.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 270.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/tallow-lane-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			if entry.has("points"):
				var shape = ConvexPolygonShape3D.new()
				var points = PackedVector3Array()
				for p in entry.points:
					points.append(Vector3(p[0], p[1], p[2]))
				shape.points = points
				col.shape = shape
			else:
				var shape = BoxShape3D.new()
				var s = entry.size
				shape.size = Vector3(s[0], s[1], s[2])
				col.shape = shape
				var p = entry.position
				col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

func _place_cathedral():
	const SaintAthanasius = preload("res://scripts/saint_athanasius_cathedral.gd")
	var glb = load("res://models/saint-athanasius-cathedral.glb")
	if not glb:
		return
	var container = Node3D.new()
	container.set_script(SaintAthanasius)
	var model = glb.instantiate()
	model.name = "Model"
	container.add_child(model)
	_strip_collision(model)
	container.position = Vector3(0.0, 0.0, 80.0)
	container.rotation_degrees.y = 180.0
	add_child(container)

	# Manual floor — _strip_collision removed the GLB's own collision
	# Nave floor: 14m wide × 22m deep, covering Z 68→90
	var floor_body = StaticBody3D.new()
	floor_body.position = Vector3(0.0, 0.0, 79.0)
	add_child(floor_body)
	var floor_col = CollisionShape3D.new()
	var floor_shape = BoxShape3D.new()
	floor_shape.size = Vector3(14.0, 0.2, 22.0)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)

	# Altar ramp: rises ~0.5m over 4m (Z 89→93), slopes up toward +Z
	var ramp_body = StaticBody3D.new()
	ramp_body.position = Vector3(0.0, 0.25, 91.0)
	ramp_body.rotation_degrees.x = 7.1  # atan(0.5/4) — slopes up toward altar
	add_child(ramp_body)
	var ramp_col = CollisionShape3D.new()
	var ramp_shape = BoxShape3D.new()
	ramp_shape.size = Vector3(8.0, 0.2, 4.03)
	ramp_col.shape = ramp_shape
	ramp_body.add_child(ramp_col)

	# Altar platform: raised floor at Z 93→98, Y 0.5m
	var altar_body = StaticBody3D.new()
	altar_body.position = Vector3(0.0, 0.5, 95.5)
	add_child(altar_body)
	var altar_col = CollisionShape3D.new()
	var altar_shape = BoxShape3D.new()
	altar_shape.size = Vector3(10.0, 1.0, 5.0)
	altar_col.shape = altar_shape
	altar_body.add_child(altar_col)

func _place_mid_cross_house():
	var glb = load("res://models/iron-quill-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var pos = Vector3(20.0, 0.0, 14.8)
	instance.position = pos
	instance.rotation_degrees.y = 180.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 180.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/iron-quill-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			if entry.has("points"):
				var shape = ConvexPolygonShape3D.new()
				var points = PackedVector3Array()
				for p in entry.points:
					points.append(Vector3(p[0], p[1], p[2]))
				shape.points = points
				col.shape = shape
			else:
				var shape = BoxShape3D.new()
				var s = entry.size
				shape.size = Vector3(s[0], s[1], s[2])
				col.shape = shape
				var p = entry.position
				col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

func _place_tallow_lane_cross():
	var glb = load("res://models/tallow-lane-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var pos = Vector3(27.0, 0.0, 14.8)
	instance.position = pos
	instance.rotation_degrees.y = 180.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 180.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/tallow-lane-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			if entry.has("points"):
				var shape = ConvexPolygonShape3D.new()
				var points = PackedVector3Array()
				for p in entry.points:
					points.append(Vector3(p[0], p[1], p[2]))
				shape.points = points
				col.shape = shape
			else:
				var shape = BoxShape3D.new()
				var s = entry.size
				shape.size = Vector3(s[0], s[1], s[2])
				col.shape = shape
				var p = entry.position
				col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

func _place_iron_quill():
	var glb = load("res://models/iron-quill-house.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var pos = Vector3(27.0, 0.0, 22.0)
	instance.position = pos
	instance.rotation_degrees.y = 180.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 180.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/iron-quill-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			if entry.has("points"):
				var shape = ConvexPolygonShape3D.new()
				var points = PackedVector3Array()
				for p in entry.points:
					points.append(Vector3(p[0], p[1], p[2]))
				shape.points = points
				col.shape = shape
			else:
				var shape = BoxShape3D.new()
				var s = entry.size
				shape.size = Vector3(s[0], s[1], s[2])
				col.shape = shape
				var p = entry.position
				col.position = Vector3(p[0], p[1], p[2])
			body.add_child(col)

func _place_saint_oswin():
	var glb = load("res://models/saint-oswin-church.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	var sc = 1.2
	instance.scale = Vector3(sc, sc, sc)
	var pos = Vector3(1.5, 0.0, 55.0)
	instance.position = pos
	instance.rotation_degrees.y = 180.0
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	_disable_shadows(instance)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = 180.0
	add_child(body)
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://models/saint-oswin-collisions.json"))
	if entries:
		for entry in entries:
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			var s = entry.size
			shape.size = Vector3(s[0] * sc, s[1] * sc, s[2] * sc)
			col.shape = shape
			var p = entry.position
			col.position = Vector3(p[0] * sc, p[1] * sc, p[2] * sc)
			body.add_child(col)

func _place_barrowroot():
	var glb = load("res://models/barrowroot-provisions.glb")
	if not glb:
		return
	var instance = glb.instantiate()
	# Back face (local Z=-3.24) aligned with church back (world Z=60.04)
	# At rotation=180° local -Z → world +Z, so center_Z = 60.04 - 3.24 = 56.8
	var pos = Vector3(11.0, 0.0, 56.8)
	instance.position = pos
	instance.rotation_degrees.y = 180.0
	add_child(instance)
	# GLB includes interior collision — do not strip
	_dim_glb_lights(instance, 0.0)
	_disable_shadows(instance)
	var door = instance.find_child("FrontDoorPivot", true, false)
	if door:
		door.rotation_degrees.y = 90.0

func _place_left_tcross_houses():
	var glb = load("res://models/grim-eight-new-house-fronts.glb")
	if not glb:
		return
	var pos = Vector3(36.0, 0.0, 8.5)
	var rot_y = 270.0
	var instance = glb.instantiate()
	instance.position = pos
	instance.rotation_degrees.y = rot_y
	add_child(instance)
	_strip_collision(instance)
	_dim_glb_lights(instance, 0.0)
	# Per-house collision boxes from layout.json (local space, rotation applied by body)
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = rot_y
	add_child(body)
	var houses = [
		{"p": [-22.0, 3.5,  -2.5], "s": [6.2, 7.0, 5.0]},
		{"p": [-16.2, 4.4,  -2.5], "s": [5.4, 8.8, 5.0]},
		{"p": [ -9.9, 3.6,  -2.5], "s": [7.2, 7.2, 5.0]},
		{"p": [ -3.3, 4.15, -2.5], "s": [6.0, 8.3, 5.0]},
		{"p": [  2.9, 3.55, -2.5], "s": [6.4, 7.1, 5.0]},
		{"p": [  9.0, 3.9,  -2.5], "s": [5.8, 7.8, 5.0]},
		{"p": [ 15.4, 4.4,  -2.5], "s": [7.0, 8.8, 5.0]},
		{"p": [ 22.0, 3.95, -2.5], "s": [6.2, 7.9, 5.0]},
	]
	for h in houses:
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(h["s"][0], h["s"][1], h["s"][2])
		col.shape = shape
		col.position = Vector3(h["p"][0], h["p"][1], h["p"][2])
		body.add_child(col)

func _place_left_tcross_street():
	var albedo = load("res://models/gravel_macro__tile_texture_0.jpg")
	var rough  = load("res://models/gravel_macro__tile_texture_1.png")
	var normal = load("res://models/gravel_macro__tile_texture_2.jpg")
	var mat = StandardMaterial3D.new()
	if albedo: mat.albedo_texture = albedo
	if rough:  mat.roughness_texture = rough
	if normal:
		mat.normal_enabled = true
		mat.normal_texture = normal
	mat.roughness = 1.0

	# South branch of the T — the only new surface needed (X 29→43, Z -14→5)
	# Main cross-street and forward street now extend to X=43, covering the rest seamlessly.
	mat.uv1_scale = Vector3(9, 14, 1)
	_make_street_plane(Vector3(36.0, 0.0, -4.5), Vector2(14, 19), mat)

	# Right-end wall behind houses at X=43
	var rw = StaticBody3D.new()
	rw.position = Vector3(43.0, 2.0, 9.0)
	add_child(rw)
	var rwc = CollisionShape3D.new()
	var rws = BoxShape3D.new()
	rws.size = Vector3(0.2, 4.0, 60.0)
	rwc.shape = rws
	rw.add_child(rwc)

	# South end wall at Z=-14
	var sw = StaticBody3D.new()
	sw.position = Vector3(36.0, 2.0, -14.0)
	add_child(sw)
	var swc = CollisionShape3D.new()
	var sws = BoxShape3D.new()
	sws.size = Vector3(14.0, 4.0, 0.2)
	swc.shape = sws
	sw.add_child(swc)

func _on_kill_zone_body_entered(body):
	if body.is_in_group("player"):
		body.global_position = PLAYER_SPAWN
		body.velocity = Vector3.ZERO

func _load_apothecary_shell():
	# Disable only the original building shell. Preserve all gameplay nodes.
	for part in ["Floor","WallBack","WallLeft","WallRight","WallFrontLeft","WallFrontRight","WallAboveDoor","Ceiling"]:
		var old = get_node_or_null(part)
		if old:
			for child in old.get_children():
				if child is GeometryInstance3D: child.visible = false
				if child is CollisionShape3D: child.disabled = true
	var shell = preload("res://apothecary_house/shell.tscn").instantiate()
	shell.name = "ApothecaryHouseShell"
	add_child(shell)

