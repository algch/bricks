extends KinematicBody2D

const X_SIZE = 80
const Y_SIZE = 40
const SPEED = 50

var move_dir = null
var type = null

onready var arena = get_node('/root/arena')

# TODO rpc call is being executed in the wrong brick

func _ready():
	if not move_dir:
		move_dir = Vector2(1 if randi() % 2 == 0 else -1, 0)
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
		var mirrored_x = X + (X - position.x)
		var mirrored_dir = move_dir.rotated(PI)
		rpc_unreliable('updateBrick', mirrored_x, mirrored_dir)
		$updateTimer.start()

remote func updateBrick(x, dir):
	position.x = x
	move_dir = dir

func _physics_process(delta):
	var motion = move_dir * SPEED * delta
	var collision = move_and_collide(motion)
	if collision:
		move_dir *= -1
