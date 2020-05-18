extends Control


func _on_soloButton_pressed():
	var root = get_tree().get_root()
	var menu = root.get_node('mainMenu')
	root.remove_child(menu)
	menu.queue_free()
	root.add_child(scene)


func _on_ipAddress_text_changed(new_text):
	pass # Replace with function body.
