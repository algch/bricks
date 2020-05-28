extends Node2D

var arrow_class = preload('res://weapons/arrow.tscn')

onready var arena = get_node('/root/arena/')
var is_player = false

func init(player):
	is_player = player

func _ready():
	pass

func shootArrow():
	var mouse_pos = get_global_mouse_position()
	var nozzle_pos = $nozzle.position
	var start_pos = position + nozzle_pos

	var arrow_dir = (mouse_pos - start_pos).normalized()
	var arrow = arrow_class.instance()
	var mirrored_dir = Vector2(-arrow_dir.x, arrow_dir.y)
	rpc('syncArrow', start_pos.x, mirrored_dir)
	arrow.init(arrow_dir, start_pos)
	get_parent().add_child(arrow)

remote func syncArrow(x_pos, dir):
	if is_player:
		return

	var nozzle_pos = $nozzle.position
	var start_pos = position + nozzle_pos
	start_pos.x = x_pos

	var arrow = arrow_class.instance()
	arrow.init(dir, start_pos)
	get_parent().add_child(arrow)

func _draw():
	if arena.is_player_turn:
		draw_circle(Vector2(0, 0), 100, Color(1, 0.2, 0.3))
		draw_circle(position, 100, Color(1, 0.2, 0.3))

func _input(event):
	if not get_parent().is_player_turn:
		return
	if event.is_action_released('touch'):
		self.shootArrow()

func _process(delta):
	update()
