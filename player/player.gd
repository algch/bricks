extends Node2D

var arrow_class = preload('res://weapons/arrow.tscn')
var ball_class = preload('res://brick/brickSpawner.tscn')

onready var arena = get_node('/root/arena/')
var is_player = false
var is_pressed = false
var can_shoot = false
var reference_pos = null
var bases = {}

var self_score = 0
var vs_score = 0

var should_show_presentation = true

func init(player):
	is_player = player

func syncCurrentBase(base_name):
	if base_name in bases:
		var base = get_node(base_name)
		$shooter.position = base.position

func _on_base_created(base_name):
	bases[base_name] = {
		'is_alive': true,
		'development_stage': 0,
	}

func _on_base_destroyed(base_name):
	bases[base_name]['is_alive'] = false

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
	var brick_dir = 1
	if is_player:
		brick_dir *= -1
	arrow.init(arrow_dir, start_pos, emitter_id, brick_dir)
	get_parent().add_child(arrow)
	$shooter.play('shoot')

remote func syncShootingState(can):
	can_shoot = can

func _input(event):
	if not is_player:
		return
	if event.is_action_pressed('touch') and not is_pressed:
		is_pressed = true
		reference_pos = get_global_mouse_position()
		$weaponTimer.start()
		$shooter.play('aim')
	if event.is_action_released('touch'):
		if can_shoot:
			shootArrow()
		$weaponTimer.stop()
		is_pressed = false
		can_shoot = false
		rpc('syncShootingState', can_shoot)
	if event.is_action_released('test'):
		print('ball ', str(get_tree().get_nodes_in_group('ball')))

func _on_shooter_animation_finished():
	match $shooter.get_animation():
		'aim':
			$shooter.stop()
			$shooter.set_frame(0)
			if is_pressed:
				$shooter.stop()
				$shooter.set_frame(15)
		'shoot':
			$shooter.stop()
			$shooter.set_animation('aim')
			$shooter.set_frame(0)

func presentation():
	var poly = $Area2D/Polygon2D
	poly.position -= Vector2(0, 30)
	draw_polygon(poly.polygon, PoolColorArray([Color(0, 0, 0)]))

func _on_presentationTimer_timeout():
	should_show_presentation = false

func _draw():
	if should_show_presentation:
		presentation()
	if is_pressed:
		var arrow_dir = reference_pos - get_global_mouse_position()
		var color = Color(0.8, 0.8, 0.8)
		if can_shoot:
			color = Color(1, 0.5, 0.5)
		draw_line($shooter.position, $shooter.position + arrow_dir, color)

func _process(delta):
	update()
	if is_pressed:
		var arrow_dir = reference_pos - get_global_mouse_position()
		$shooter.rotation = arrow_dir.angle() + PI/2

func _on_weaponTimer_timeout():
	$weaponTimer.stop()
	can_shoot = true
	rpc('syncShootingState', can_shoot)

func generateBall():
	var ball = ball_class.instance()
	var name = str(get_tree().get_network_unique_id()) + '_' + str(get_instance_id())
	var emitter_id = get_tree().get_network_unique_id()
	ball.init(name, emitter_id)
	ball.position = arena.get_node('spawnerPos').position

remote func syncBall(name):
	var ball = ball_class.instance()
	ball.position = Utils.getMirrored(arena.get_node('spawnerPos').position)
	ball.set_name(name)
	ball.rotate(PI)
	add_child(ball)

func _on_Area2D_body_entered(body):
	if body.is_in_group('enters_goal'):
		body.handleEnteredGoal(self)

remote func syncScore(vs, s):
	self_score = s
	vs_score = vs
	arena.get_node('selfScoreLabel').set_text(str(self_score))
	arena.get_node('vsScoreLabel').set_text(str(vs_score))

func receivedGoal():
	if is_player:
		vs_score += 1
	else:
		self_score += 1
	arena.get_node('selfScoreLabel').set_text(str(self_score))
	arena.get_node('vsScoreLabel').set_text(str(vs_score))
	rpc('syncScore', self_score, vs_score)
