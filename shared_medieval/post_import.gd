@tool
extends EditorScenePostImport
func _post_import(scene: Node) -> Object:
 var mapping=JSON.parse_string(FileAccess.get_file_as_string("res://shared_medieval/material-map.json"))
 apply_materials(scene,mapping)
 return scene
func apply_materials(node: Node,mapping: Dictionary):
 if node is MeshInstance3D and node.mesh!=null:
  for i in node.mesh.get_surface_count():
   var old=node.mesh.surface_get_material(i)
   if old!=null and mapping.has(old.resource_name):
    var shared=load(mapping[old.resource_name])
    node.mesh.surface_set_material(i,shared)
 for child in node.get_children():apply_materials(child,mapping)
