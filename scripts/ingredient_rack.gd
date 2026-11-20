extends StaticBody3D

# Node names and item prefixes come from the GLB hierarchy.
# Run once with the debug dump below to verify these match the new rack-5 model.
const BRAID_CONFIGS = [
	{ "node_name": "01 | Red chilli braid",   "item_prefix": "chilli ",      "item_type": "chilli",  "display_name": "Chilli" },
	{ "node_name": "02 | Copper onion braid", "item_prefix": "onion ",       "item_type": "onion",   "display_name": "Onion" },
	{ "node_name": "03 | Ivory garlic braid", "item_prefix": "garlic head ", "item_type": "garlic",  "display_name": "Garlic" },
	{ "node_name": "04 | Smoked river fish",  "item_prefix": "smoked fish ", "item_type": "fish",    "display_name": "Fish" },
	{ "node_name": "05 | Ginger root braid",  "item_prefix": "ginger ",      "item_type": "ginger",  "display_name": "Ginger" },
]

func _ready():
	# Remove the rack body from all collision layers so it never intercepts
	# the interaction ray before it reaches an individual ingredient trigger.
	collision_layer = 0

func setup(rack_node: Node):
	for config in BRAID_CONFIGS:
		var braid_node = _find_node(rack_node, config["node_name"])
		if not braid_node:
			print("RACK: braid node not found: ", config["node_name"])
			continue
		var items: Array = []
		_collect_items(braid_node, config["item_prefix"], items)
		if items.is_empty():
			print("RACK: no items found with prefix '", config["item_prefix"], "' under ", config["node_name"])
			continue

		# Compute centroid and vertical span across all individual items.
		var centroid = Vector3.ZERO
		var min_y = INF
		var max_y = -INF
		for it in items:
			centroid += it.global_position
			min_y = min(min_y, it.global_position.y)
			max_y = max(max_y, it.global_position.y)
		centroid /= items.size()
		var cap_height = max(max_y - min_y + 0.25, 0.4)

		var trigger = StaticBody3D.new()
		trigger.set_script(load("res://scripts/ingredient_braid.gd"))
		trigger.collision_layer = 2
		trigger.collision_mask = 0

		# Generous upright capsule that follows the hanging shape of the braid.
		var col = CollisionShape3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 0.15
		shape.height = cap_height
		col.shape = shape
		trigger.add_child(col)

		add_child(trigger)
		trigger.global_position = centroid
		trigger.init_braid(config["item_type"], config["display_name"], items, braid_node)

# Rack body no longer handles interaction; each braid trigger handles take/return.
func get_interact_label(_player = null) -> String:
	return ""

func interact(_player):
	pass

# ── helpers ────────────────────────────────────────────────────────────────

func _dump(node: Node, depth: int, max_depth: int):
	if depth > max_depth:
		return
	print("  ".repeat(depth) + node.name)
	for child in node.get_children():
		_dump(child, depth + 1, max_depth)

func _find_node(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var r = _find_node(child, target)
		if r:
			return r
	return null

func _collect_items(node: Node, prefix: String, items: Array):
	for child in node.get_children():
		var n = child.name.to_lower()
		if n.begins_with(prefix) and not "mesh" in n:
			items.append(child)
		else:
			_collect_items(child, prefix, items)
