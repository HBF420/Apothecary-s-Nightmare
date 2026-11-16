extends SceneTree

func _init():
	var glb = load("res://models/medieval-twin-chimney-house.glb")
	if not glb:
		print("FAILED")
		quit()
		return
	var scene = glb.instantiate()
	print("Root: %s rot=(%.1f,%.1f,%.1f) scale=(%.3f,%.3f,%.3f)" % [
		scene.name,
		scene.rotation_degrees.x, scene.rotation_degrees.y, scene.rotation_degrees.z,
		scene.scale.x, scene.scale.y, scene.scale.z
	])
	# Collect overall AABB from all meshes
	var overall_min = Vector3(INF, INF, INF)
	var overall_max = Vector3(-INF, -INF, -INF)
	_scan(scene, overall_min, overall_max)
	print("Overall AABB min=(%.3f,%.3f,%.3f) max=(%.3f,%.3f,%.3f)" % [
		overall_min.x, overall_min.y, overall_min.z,
		overall_max.x, overall_max.y, overall_max.z
	])
	print("Size: (%.3f,%.3f,%.3f)" % [
		overall_max.x - overall_min.x,
		overall_max.y - overall_min.y,
		overall_max.z - overall_min.z
	])
	# Print top-level children only
	for child in scene.get_children():
		if child is Node3D:
			print("  child: %s pos=(%.2f,%.2f,%.2f) rot=(%.1f,%.1f,%.1f)" % [
				child.name,
				child.position.x, child.position.y, child.position.z,
				child.rotation_degrees.x, child.rotation_degrees.y, child.rotation_degrees.z
			])
	scene.queue_free()
	quit()

func _scan(node: Node, mn: Vector3, mx: Vector3):
	if node is MeshInstance3D and node.mesh:
		var ab = node.mesh.get_aabb()
		mn.x = min(mn.x, ab.position.x)
		mn.y = min(mn.y, ab.position.y)
		mn.z = min(mn.z, ab.position.z)
		mx.x = max(mx.x, ab.position.x + ab.size.x)
		mx.y = max(mx.y, ab.position.y + ab.size.y)
		mx.z = max(mx.z, ab.position.z + ab.size.z)
	for child in node.get_children():
		_scan(child, mn, mx)
