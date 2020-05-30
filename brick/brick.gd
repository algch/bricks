extends KinematicBody2D

const X_SIZE = 80
const Y_SIZE = 80
const SPEED = 200

var move_dir = Vector2(1, 0)
var type = null

# TODO rpc call is being executed in the wrong brick

func _ready():
	type = 'normal'
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
	queue_free()

func handleWeaponCollision(collider):
	if get_tree().is_network_server():
		rpc('destroy')
		collider.rpc('destroy')

func _on_updateTimer_timeout():
	if get_tree().is_network_server():
		var X = 360
		var mirrored_x = X + (X - position.x)
		var mirrored_pos = Vector2(mirrored_x, position.y)
		var mirrored_dir = move_dir.rotated(PI)
		rpc_unreliable('updateBrick', mirrored_pos, mirrored_dir)
		$updateTimer.start()

remote func updateBrick(pos, dir):
	position = pos
	move_dir = dir

func _physics_process(delta):
	var motion = move_dir * SPEED * delta
	var collision = move_and_collide(motion)
	if collision:
		move_dir *= -1
