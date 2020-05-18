extends Node2D

var arrow_class = preload('res://weapons/arrow.tscn')


func _ready():
	pass

func shootArrow():
	var mouse_pos = get_global_mouse_position()
	var nozzle_pos = $nozzle.position
	var start_pos = position + nozzle_pos

	var arrow_dir = (mouse_pos - start_pos).normalized()
	var arrow = arrow_class.instance()
	arrow.init(arrow_dir, start_pos)
	get_parent().add_child(arrow)



func _input(event):
	if event.is_action_released('touch'):
		self.shootArrow()
