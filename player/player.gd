extends Node2D

var arrow_class = preload('res://weapons/arrow.tscn')

onready var arena = get_node('/root/arena/')
var is_player = false
var is_pressed = false
var can_shoot = false
var reference_pos = null
var bases = {}

func init(player):
	is_player = player

func syncCurrentBase(base_name):
	if base_name in bases:
		var base = get_node(base_name)
		$shooter.position = base.position

func _ready():
	$shooter/Label.set_text(get_name())

func _on_base_created(base_name):
	bases[base_name] = {
		'is_alive': true,
		'development_stage': 0,
	}

func _on_base_destroyed(base_name):
	bases.erase(base_name)

	var game_over = true
	for key in bases.keys():
		if bases[key]['is_alive']:
			game_over = false
			break

	if game_over:
		# TODO trigger gameover / victory
		print('game over')

func shootArrow():
	var mouse_pos = get_global_mouse_position()
	var arrow_dir = (reference_pos - mouse_pos).normalized()
	var emitter_id = get_tree().get_network_unique_id()
	rpc('_shootArrow', emitter_id, arrow_dir)

remotesync func _shootArrow(emitter_id, arrow_dir):
	if emitter_id != get_tree().get_network_unique_id():
		arrow_dir = arrow_dir.rotated(PI)

	var start_pos = $shooter/nozzle.get_global_position()
	var arrow = arrow_class.instance()
	arrow.init(arrow_dir, start_pos, emitter_id)
	get_parent().add_child(arrow)

remote func syncArrow(x_pos, dir):
	var start_pos = $shooter/nozzle.get_global_position()
	start_pos.x = x_pos

	var arrow = arrow_class.instance()
	arrow.init(dir, start_pos)
	get_parent().add_child(arrow)

remote func syncShootingState(can):
	can_shoot = can

func _input(event):
	if not is_player:
		return
	if event.is_action_pressed('touch') and not is_pressed:
		is_pressed = true
		reference_pos = get_global_mouse_position()
		$weaponTimer.start()
	if event.is_action_released('touch'):
		if can_shoot:
			shootArrow()
		$weaponTimer.stop()
		is_pressed = false
		can_shoot = false
	rpc('syncShootingState', can_shoot)

func _draw():
	if is_pressed:
		var arrow_dir = reference_pos - get_global_mouse_position()
		draw_line(Vector2(0, 0), arrow_dir, Color(.8, .8, .8))
	if can_shoot:
		draw_circle(
			Vector2(0, -100),
			60,
			Color(1, 1, 1)
		)

func _process(delta):
	update()
	if is_pressed:
		var arrow_dir = reference_pos - get_global_mouse_position()
		$shooter.rotation = arrow_dir.angle() + PI/2

func _on_Area2D_body_entered(body):
	body.rpc('destroy')

func _on_weaponTimer_timeout():
	$weaponTimer.stop()
	can_shoot = true
	rpc('syncShootingState', can_shoot)
