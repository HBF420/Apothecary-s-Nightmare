extends StaticBody3D

func get_interact_label(_player = null) -> String:
	return "Read [E]"

func interact(_player):
	var popup = CanvasLayer.new()
	popup.set_script(preload("res://scripts/book_popup.gd"))
	get_tree().root.add_child(popup)
