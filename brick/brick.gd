extends KinematicBody2D

const X_SIZE = 80
const Y_SIZE = 80
const SPEED = 200

var move_dir = Vector2(1, 0)

func drawBrick():
	var brick = Rect2(
		Vector2(-X_SIZE/2, -Y_SIZE/2),
		Vector2(X_SIZE, Y_SIZE)
	)
	var color = Color(1, 0, 0.8, 0.7)
	draw_rect(brick, color)

func _draw():
	drawBrick()

func handleWeaponCollision(collider):
	collider.rpc('destroy')
	queue_free()

remote func updateBrickPos(pos):
	position = pos

func _physics_process(delta):
	var motion = move_dir * SPEED * delta
	var collision = move_and_collide(motion)
	if collision:
		move_dir *= -1
		if get_tree().is_network_server():
			# update using a timer or on every collision maybe?
			rpc('updateBrickPos', position)
