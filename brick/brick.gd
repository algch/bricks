extends KinematicBody2D

const X_SIZE = 80
const Y_SIZE = 40

const X_SPEED = 50
const Y_SPEED = 30

var move_dir = null
var type = null

onready var arena = get_node('/root/arena')

# TODO rpc call is being executed in the wrong brick

func _ready():
	if not type:
		type = 'normal'
	$Label.set_text(get_name())
	if get_tree().is_network_server():
		$updateTimer.start()

func drawBrick():
	var brick = Rect2(
		Vector2(-X_SIZE/2, -Y_SIZE/2),
		Vector2(X_SIZE, Y_SIZE)
	)
	var color = Color(1, 0, 0.8, 0.7)
	draw_rect(brick, color)

func _draw():
	drawBrick()
	var motion = Vector2(move_dir.x * X_SPEED, move_dir.y * Y_SPEED)
	draw_line(Vector2(0, 0), motion, Color(1, 1, 1))

remotesync func destroy():
	var name = get_name()

	if name in arena.player_bricks:
		arena.player_bricks.erase(name)

	if name in arena.opponent_bricks:
		arena.opponent_bricks.erase(name)

	queue_free()

func handleWeaponCollision(collider):
	if get_tree().is_network_server():
		rpc('destroy')
		collider.rpc('destroy')
		arena.rpc('endTurn')

func _on_updateTimer_timeout():
	if get_tree().is_network_server():
		var X = 360
		var Y = 640
		var mirrored_x = X + (X - position.x)
		var mirrored_y = Y + (Y - position.y)
		var mirrored_pos = Vector2(mirrored_x, mirrored_y)
		var mirrored_dir = move_dir * -1
		rpc_unreliable('updateBrick', mirrored_pos, mirrored_dir)
		$updateTimer.start()

remote func updateBrick(pos, dir):
	position = pos
	move_dir = dir

func _process(delta):
	update()

func _physics_process(delta):
	var motion = Vector2(move_dir.x * X_SPEED, move_dir.y * Y_SPEED) * delta
	var collision = move_and_collide(motion)
	if collision:
		move_dir = Vector2(-move_dir.x, move_dir.y)
