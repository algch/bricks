extends KinematicBody2D

const X_SIZE = 80
const Y_SIZE = 40

const X_SPEED = 200
const Y_SPEED = 30
const MAX_SPEED = 100
var speed = MAX_SPEED

var move_dir = null
var type = null
var sender_id = null

onready var arena = get_node('/root/arena')

func init(brick_name, dir, pos, s_id):
	sender_id = s_id
	move_dir = dir
	set_name(brick_name)
	set_position(pos)

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
	if is_queued_for_deletion():
		return

	queue_free()

func handleWeaponCollision(collider, collision):
	collider.rpc('destroy')
	rpc('destroy')

func _on_updateTimer_timeout():
	# TODO trust the sender instead of the server
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
	var motion = move_dir * speed * delta
	var collision = move_and_collide(motion)
	if collision:
		var collider = collision.get_collider()

		if collider.is_in_group('collisionable'):
			collider.handleWeaponCollision(self, collision)
			rpc('destroy')
