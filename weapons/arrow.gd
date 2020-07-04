extends KinematicBody2D

var sender_id = null
var brick_dir = Vector2(0, 0)
var direction = Vector2(0, 0)
var speed = 640

func _ready():
	if get_tree().is_network_server():
		$updateTimer.start()

func init(dir, pos, emitter_id, b_dir):
	sender_id = emitter_id
	direction = dir.normalized()
	position = pos
	rotation = dir.angle() + PI/2
	brick_dir = direction

func getOwner():
	var net_id = str(get_tree().get_network_unique_id())
	return get_node('/root/arena/' + net_id)

remotesync func destroy():
	if is_queued_for_deletion():
		return

	queue_free()

func handleCollision(collision):
	var collider = collision.get_collider()

	if collider.is_in_group('collisionable'):
		collider.handleWeaponCollision(self, collision)

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
	rotation = dir.angle() + PI/2

func _on_updateTimer_timeout():
	if sender_id == get_tree().get_network_unique_id():
		var mirrored_pos = Utils.getMirrored(position)
		var mirrored_dir = direction.rotated(PI)
		rpc_unreliable('updateArrow', mirrored_pos, mirrored_dir)
		$updateTimer.start()

func handleEnteredGoal(player):
	rpc('destroy')
