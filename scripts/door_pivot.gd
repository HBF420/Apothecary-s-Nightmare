extends Node3D

var is_open = false
var is_animating = false
var blocker: Node = null
var door_node: Node = null
var _voice_player: AudioStreamPlayer = null
var _voice_player_2: AudioStreamPlayer = null
var _ask_count: int = 0

func _ready() -> void:
	_voice_player = AudioStreamPlayer.new()
	var stream = load("res://sounds/apothecary_whos_there.mp3")
	if stream:
		_voice_player.stream = stream
	add_child(_voice_player)

	_voice_player_2 = AudioStreamPlayer.new()
	var stream2 = load("res://sounds/apothecary_whos_there_2.mp3")
	if stream2:
		_voice_player_2.stream = stream2
	add_child(_voice_player_2)

func _customer_is_knocking() -> bool:
	var customer = get_tree().get_first_node_in_group("customer")
	return customer != null and customer.has_method("is_knocking") and customer.is_knocking()

func get_interact_label(_player = null) -> String:
	if is_open:
		return "Close door [E]"
	return "Open door [E]"

func interact(_player):
	if is_animating or not door_node:
		return
	is_animating = true
	is_open = !is_open
	if is_open:
		_ask_count = 0  # reset for next visit
	if blocker:
		blocker.collision_layer = 0 if is_open else 1
		blocker.collision_mask = 0 if is_open else 1
	var tween = create_tween()
	tween.tween_property(door_node, "rotation_degrees:y", -85.0 if is_open else 0.0, 1.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_callback(func(): is_animating = false)

func get_secondary_label(_player = null) -> String:
	if not is_open and _ask_count < 2 and _customer_is_knocking():
		return "Ask who's there [F]"
	return ""

func get_tertiary_label(_player = null) -> String:
	if not is_open and _customer_is_knocking():
		return "Turn away [G]"
	return ""

func tertiary_interact(player = null) -> void:
	if not _customer_is_knocking():
		return
	get_tree().call_group("customer", "be_turned_away", player)

func secondary_interact(_player = null) -> void:
	if _ask_count >= 2 or not _customer_is_knocking():
		return
	var player = _voice_player if _ask_count == 0 else _voice_player_2
	if player and not player.playing:
		_ask_count += 1
		player.play()
		await player.finished
		get_tree().call_group("customer", "play_whos_there_response")
