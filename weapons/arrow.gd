extends KinematicBody2D

var direction = Vector2(0, 0)
var speed = 100
onready var player = get_node('/root/arena/player')

func _ready():
	if get_tree().is_network_server():
		$updateTimer.start()

func init(dir, pos):
	direction = dir.normalized()
	position = pos
	rotation = dir.angle() + PI/2

func getOwner():
	var net_id = str(get_tree().get_network_unique_id())
	return get_node('/root/arena/' + net_id)

remotesync func destroy():
	queue_free()

func handleCollision(collision):
	var collider = collision.get_collider()

	if collider.is_in_group('collisionable'):
		collider.handleWeaponCollision(collider)

	var normal = collision.get_normal()
	direction = direction.bounce(normal)
	rotation = direction.angle() + PI/2

func _physics_process(delta):
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		self.handleCollision(collision)

remote func updateArrow(pos, dir):
	position = pos
	direction = dir

func _on_updateTimer_timeout():
	if get_tree().is_network_server():
		var X = 360
		var Y = 640
		var mirrored_x = X + (X - position.x)
		var mirrored_y = Y + (Y - position.y)
		var mirrored_pos = Vector2(mirrored_x, mirrored_y)
		var mirrored_dir = direction.rotated(PI)
		rpc('updateArrow', mirrored_pos, mirrored_dir)
		$updateTimer.start()
