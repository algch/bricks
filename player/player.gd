extends Node2D

var arrow_class = preload('res://weapons/arrow.tscn')

onready var arena = get_node('/root/arena/')
var is_player = false
var bases = 0

func init(player):
	is_player = player

func _on_base_created():
	print('base created')
	bases += 1

func _on_base_destroyed():
	print('base destroyed')
	bases -= 1
	if bases <= 0:
		print('game over')

func shootArrow():
	if not is_player:
		return

	var mouse_pos = get_global_mouse_position()
	var start_pos = $shooter/nozzle.get_global_position()

	var arrow_dir = (mouse_pos - start_pos).normalized()
	var arrow = arrow_class.instance()
	var mirrored_dir = arrow_dir.rotated(PI)
	rpc('syncArrow', start_pos.x, mirrored_dir)
	arrow.init(arrow_dir, start_pos)
	get_parent().add_child(arrow)

remote func syncArrow(x_pos, dir):
	var start_pos = $shooter/nozzle.get_global_position()
	start_pos.x = x_pos

	var arrow = arrow_class.instance()
	arrow.init(dir, start_pos)
	get_parent().add_child(arrow)

func _draw():
	draw_rect(
		Rect2(
			Vector2(100, -50),
			Vector2(200, 100)
		),
		Color(0.2, 0.2, 0.2)
	)
	if arena.is_player_turn and is_player:
		draw_circle(Vector2(200, 0), 50, Color(1, 0.2, 0.3))
	if not arena.is_player_turn and not is_player:
		draw_circle(Vector2(200, 0), 50, Color(1, 0.2, 0.3))

func _input(event):
	if not get_parent().is_player_turn:
		return
	if event.is_action_released('touch'):
		self.shootArrow()

func _process(delta):
	update()
