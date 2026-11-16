extends StaticBody3D

enum State { EMPTY, SEEDED, SPROUT, YOUNG, MATURE, DEAD }

var state: State = State.EMPTY
var watered: bool = false
var missed_water_count: int = 0
var pot_visual_root = null
var _plant_node = null
var _seed_type: String = ""
var _blades: Array = []

func _ready():
	add_to_group("planter_pot")

func get_interact_label(player = null) -> String:
	match state:
		State.EMPTY:
			if player and _player_has_seeds(player):
				return "Plant a seed [E]"
			return ""
		State.DEAD:
			return "Remove dried plant [E]"
		State.SEEDED, State.SPROUT, State.YOUNG:
			if watered:
				return "Growing..."
			if player and _player_has_full_cup(player):
				return "Water plant [E]"
			return "Needs watering"
		State.MATURE:
			if watered and not _blades.is_empty():
				return "Harvest leaf [E]"
			if not watered and player and _player_has_full_cup(player):
				return "Water plant [E]"
			if not watered:
				return "Mature (needs water)"
			return ""
	return ""

func interact(player):
	match state:
		State.DEAD:
			state = State.EMPTY
			_seed_type = ""
			_update_plant_visual()
		State.EMPTY:
			if _player_has_seeds(player):
				_open_seed_menu(player)
		State.SEEDED, State.SPROUT, State.YOUNG:
			if not watered and _player_has_full_cup(player):
				_water(player)
		State.MATURE:
			if watered and not _blades.is_empty():
				_harvest(player)
			elif not watered and _player_has_full_cup(player):
				_water(player)

func plant_seed(seed_type: String, player):
	if player.seeds.has(seed_type) and player.seeds[seed_type] > 0:
		player.seeds[seed_type] -= 1
		player._update_seeds_label()
	_seed_type = seed_type
	state = State.SEEDED
	_update_plant_visual()

func on_sleep():
	if state == State.DEAD:
		return  # stays dried up until player removes it
	if watered:
		_advance()
		missed_water_count = 0
	else:
		missed_water_count += 1
		if missed_water_count >= 2:
			# Mature plants dry up visibly; younger plants just wither away
			state = State.DEAD if state == State.MATURE else State.EMPTY
			_seed_type = ""
			_update_plant_visual()
	watered = false

func _advance():
	if state == State.MATURE:
		return  # already mature — preserve remaining blades, no visual update
	match state:
		State.SEEDED: state = State.SPROUT
		State.SPROUT:  state = State.YOUNG
		State.YOUNG:   state = State.MATURE
	_update_plant_visual()

func _water(player):
	for item in player.held_items:
		if item.get("is_full") == true:
			item.use_water()
			break
	watered = true
	missed_water_count = 0

func _harvest(player):
	var blade = _blades.pop_back()
	blade.visible = false

	var leaf = StaticBody3D.new()
	leaf.set_script(load("res://scripts/item.gd"))
	leaf.set("item_type", "herbs")
	var harvest_name: String
	match _seed_type:
		"basil":     harvest_name = "Basil Sprig"
		"aloe_vera": harvest_name = "Aloe Vera Leaf"
		"bee_balm":  harvest_name = "Bee Balm Flower"
		"calendula": harvest_name = "Calendula Flower"
		"chamomile": harvest_name = "Chamomile Flower"
		_:           harvest_name = "Snake Plant Leaf"
	leaf.set("display_name", harvest_name)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.05, 0.3, 0.02)
	col.shape = shape
	leaf.add_child(col)

	if blade is MeshInstance3D and blade.mesh:
		var vis = MeshInstance3D.new()
		vis.mesh = blade.mesh
		vis.scale = Vector3(1.5, 1.5, 1.5)
		vis.rotation_degrees = Vector3(0, 0, -20)
		vis.position = Vector3(0, -0.4, 0)
		leaf.add_child(vis)

	get_parent().add_child(leaf)
	leaf.global_position = global_position + Vector3(0, 0.3, 0)
	player.pick_up_item(leaf)

	if randf() < 0.02:
		player.add_seed(_seed_type)

	if _blades.is_empty():
		state = State.EMPTY
		_seed_type = ""
		watered = false
		_update_plant_visual()

func _update_plant_visual():
	_blades.clear()
	if _plant_node:
		_plant_node.queue_free()
		_plant_node = null

	if state == State.EMPTY:
		return

	# SEEDED: tiny soil-coloured sphere placeholder (no GLB stage for seeds)
	if state == State.SEEDED:
		var mesh_inst = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.03
		sphere.height = 0.06
		mesh_inst.mesh = sphere
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.3, 0.2, 1)
		mesh_inst.material_override = mat
		mesh_inst.position = Vector3(0, 0.30, 0)
		add_child(mesh_inst)
		_plant_node = mesh_inst
		return

	# SPROUT / YOUNG / MATURE / DEAD: use the GLB stage nodes
	var glb_path: String
	match _seed_type:
		"basil":     glb_path = "res://models/basil-plant-four-stages.glb"
		"aloe_vera": glb_path = "res://models/aloe-vera-four-stages.glb"
		"bee_balm":  glb_path = "res://models/bee-balm-four-stages.glb"
		"calendula": glb_path = "res://models/calendula-four-stages.glb"
		"chamomile": glb_path = "res://models/chamomile-four-stages.glb"
		_:           glb_path = "res://models/snake-plant-four-stages.glb"
	var glb = load(glb_path)
	if not glb:
		return

	var scene = glb.instantiate()
	if not scene:
		return
	var stage_name: String = ""
	match state:
		State.SPROUT: stage_name = "Sprout"
		State.YOUNG:  stage_name = "Young"
		State.MATURE: stage_name = "Mature"
		State.DEAD:   stage_name = "DriedUp"

	for child in scene.get_children():
		child.visible = (child.name == stage_name)

	# Collect harvestable leaves/blades for the MATURE stage
	if state == State.MATURE:
		var mature_node = scene.get_node_or_null("Mature")
		if mature_node:
			var leaf_keyword: String
			match _seed_type:
				"basil":     leaf_keyword = "basilleaf"
				"aloe_vera": leaf_keyword = "aloeleaf"
				"bee_balm":  leaf_keyword = "beebalmflower"
				"calendula": leaf_keyword = "calendulaflower"
				"chamomile": leaf_keyword = "chamomileflower"
				_:           leaf_keyword = "blade"
			for child in mature_node.get_children():
				if leaf_keyword in child.name.to_lower():
					_blades.append(child)

	scene.position = Vector3(0, 0.30, 0)  # sit on the pot rim
	add_child(scene)
	_plant_node = scene

func _player_has_full_cup(player) -> bool:
	for item in player.held_items:
		if item.get("is_full") == true:
			return true
	return false

func _player_has_seeds(player) -> bool:
	for type in player.seeds:
		if player.seeds[type] > 0:
			return true
	return false

func _open_seed_menu(player):
	var menu = CanvasLayer.new()
	menu.set_script(load("res://scripts/seed_menu.gd"))
	menu.pot = self
	menu.player = player
	get_tree().root.add_child(menu)
