extends StaticBody3D

func get_interact_label(_player = null) -> String:
	if _player and _player.has_prayed_today:
		return "You have already prayed today"
	return "Pray [E]"

func interact(player) -> void:
	if player and player.has_prayed_today:
		return
	if player and player.has_method("add_reputation"):
		player.has_prayed_today = true
		player.add_reputation(10)
