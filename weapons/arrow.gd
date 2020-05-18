extends KinematicBody2D

var direction = Vector2(0, 0)
var speed = 400
onready var player = get_node('/root/arena/player')

func init(dir, pos):
	direction = dir.normalized()
	position = pos
	rotation = dir.angle() + PI/2

func handleCollision(collision):
	var collider = collision.get_collider()

	if collider is TileMap and position.y > player.position.y:
		queue_free()

	if collider.is_in_group('collisionable'):
		collider.handleWeaponCollision()

	var normal = collision.get_normal()
	direction = direction.bounce(normal)
	rotation = direction.angle() + PI/2

func _physics_process(delta):
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		self.handleCollision(collision)
