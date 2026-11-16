extends StaticBody3D

const BRAID_CONFIGS = [
	{ "node_name": "01 | Red chilli braid",     "item_prefix": "chilli ",         "item_type": "chilli",   "display_name": "Chilli" },
	{ "node_name": "02 | Copper onion braid",    "item_prefix": "onion ",          "item_type": "onion",    "display_name": "Onion" },
	{ "node_name": "03 | Ivory garlic braid",    "item_prefix": "garlic head ",    "item_type": "garlic",   "display_name": "Garlic" },
	{ "node_name": "04 | Smoked river fish",     "item_prefix": "smoked fish ",    "item_type": "fish",     "display_name": "Fish" },
	{ "node_name": "05 | Dried rosemary bundle", "item_prefix": "rosemary sprig ", "item_type": "rosemary", "display_name": "Rosemary" },
]

func setup(rack_node: Node):
	for config in BRAID_CONFIGS:
		var braid_node = _find_node(rack_node, config["node_name"])
		if not braid_node:
			continue
		var items: Array = []
		_collect_items(braid_node, config["item_prefix"], items)
		if items.is_empty():
			continue
		var trigger = StaticBody3D.new()
		trigger.set_script(load("res://scripts/ingredient_braid.gd"))
		trigger.collision_layer = 2
		trigger.collision_mask = 0
		var col = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.3
		col.shape = shape
		trigger.add_child(col)
		add_child(trigger)
		trigger.global_position = braid_node.global_position
		trigger.init_braid(config["item_type"], config["display_name"], items)

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

func get_interact_label(_player = null) -> String:
	return ""

func interact(_player):
	pass
