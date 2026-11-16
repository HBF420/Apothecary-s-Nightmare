extends Node3D

signal log_taken(log_piece: Node3D, remaining: int)

@export var held_position := Vector3(0, -.06, -.10)
@export var held_rotation_degrees := Vector3(0, 72, 0)
@onready var _stack := $Model.find_child("Firewood", true, false) as Node3D
var _logs: Array[Node3D] = []

func _ready() -> void:
	for child in _stack.get_children():
		if child is Node3D and String(child.name).begins_with("Firewood_"):
			_logs.append(child as Node3D)
	_logs.sort_custom(func(a: Node3D, b: Node3D) -> bool: return String(a.name) < String(b.name))

func remaining_count() -> int:
	return _logs.size()

func prompt() -> String:
	return "Take firewood" if remaining_count() > 0 else "Firewood rack is empty"

func interact(hand: Node3D) -> Node3D:
	if hand == null or not hand.is_inside_tree() or _logs.is_empty():
		return null
	for item in hand.get_children():
		if item.is_in_group("held_firewood"):
			return null
	var piece: Node3D = _logs.pop_back()
	piece.reparent(hand, false)
	piece.position = held_position
	piece.rotation_degrees = held_rotation_degrees
	piece.add_to_group("held_firewood")
	log_taken.emit(piece, remaining_count())
	return piece
