extends Node3D
## Visual shell and lightweight, deterministic wall/deck collision.
## Door gameplay and staircase are owned by the parent scene.
var visual: Node3D
var solid_body: StaticBody3D
func _ready() -> void:
    visual = preload("res://apothecary_house/assets/grim-apothecary-house.glb").instantiate()
    add_child(visual)
    solid_body = StaticBody3D.new()
    solid_body.name = "ShellCollision"
    add_child(solid_body)
    var entries = JSON.parse_string(FileAccess.get_file_as_string("res://apothecary_house/assets/collisions.json"))
    for entry in entries:
        var collider = CollisionShape3D.new()
        collider.name = entry.name.validate_node_name()
        var shape = BoxShape3D.new()
        var p = entry.position
        var s = entry.size
        shape.size = Vector3(s[0],s[1],s[2])
        collider.shape = shape
        collider.position = Vector3(p[0],p[1],p[2])
        solid_body.add_child(collider)
    # Guard the upstairs void while leaving the stair exit at Z=3.4 open.
    _guard(Vector3(-4.29,4.64,.85),Vector3(.10,1.08,4.7))
    _guard(Vector3(-5.15,4.64,-1.5),Vector3(1.7,1.08,.10))
func _guard(pos: Vector3, size: Vector3) -> void:
    var col = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = size
    col.shape = shape
    col.position = pos
    solid_body.add_child(col)
func find_part(part_name: String) -> Node3D:
    return visual.find_child(part_name,true,false) as Node3D
