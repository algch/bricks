extends KinematicBody2D

var brick_class = preload('res://brick/brick.tscn')
var hitspot_class = preload('res://brick/hitSpot.tscn')
const BRICK_SPACE = 10
onready var arena = get_node('/root/arena/')
var should_move = false
var MAX_SPEED = 250
var speed = MAX_SPEED
var direction = Vector2(0, 0)
var sender_id = null
var can_trigger_respawn = false

func handleWeaponCollision(collider, collision):
	if collider.sender_id == get_tree().get_network_unique_id():
		should_move = true
		var normal = collision.get_normal()
		direction += collider.direction.bounce(normal).rotated(PI)
		var hitspot = hitspot_class.instance()
		hitspot.position = collider.position - position
		hitspot.rotation = collider.direction.bounce(normal).angle()
		add_child(hitspot)
		$movementTimer.start()

		var brick = self.createBrick(collider.brick_dir, collider.sender_id)
		arena.add_child(brick)
		var raw_brick = self.parseBrick(brick)

		collider.rpc('destroy')

		rpc('syncCollision', position, direction, raw_brick, collider.position)

func init(spawner_name, pos, emitter_id):
	set_name(spawner_name)
	set_position(pos)
	sender_id = emitter_id

remote func syncCollision(pos, dir, raw_brick, colli_pos):
	position = Utils.getMirrored(pos)
	direction = dir.rotated(PI)
	should_move = true
	$movementTimer.start()
	var brick = self.createBrickFromParsed(raw_brick)
	brick.position = position
	brick.move_dir = brick.move_dir.rotated(PI)
	arena.add_child(brick)

	var hitspot = hitspot_class.instance()
	hitspot.position = Utils.getMirrored(colli_pos) - position
	hitspot.rotation = dir.angle()
	add_child(hitspot)

func _on_movementTimer_timeout():
	should_move = false
	var pos = Utils.getMirrored(position)
	direction = Vector2(0, 0)
	rpc('syncPos', pos)

remote func syncPos(pos):
	position = pos
	direction = Vector2(0, 0)

func _draw():
	draw_circle(Vector2(0, 0), 60, Color(0, 1, 1))

func _physics_process(delta):
	if not should_move:
		return

	speed = MAX_SPEED - (MAX_SPEED * (($movementTimer.get_wait_time() - $movementTimer.get_time_left()) / $movementTimer.get_wait_time()))
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		var normal = collision.get_normal()
		direction = direction.bounce(normal)
		for child in get_children():
			if child is Particles2D:
				child.queue_free()

remotesync func destroy():
	print('destroy was called')
	if is_queued_for_deletion():
		return
	
	queue_free()
	if can_trigger_respawn:
		arena.get_node('spawnBallTimer').start()


func _ready():
	pass

func parseBrick(brick):
	# do we need all the data here?
	return {
		'name': brick.get_name(),
		'dir': brick.move_dir,
		'pos': brick.get_position(),
		'rot': brick.rotation,
		'type': brick.type,
		'sender_id': brick.sender_id,
	}

func createBrick(dir, emitter_id):
	var brick = brick_class.instance()
	var player_id = get_tree().get_network_unique_id()
	var brick_id = brick.get_instance_id()
	var name = str(player_id) + '_' + str(brick_id)
	brick.init(name, dir, position, emitter_id)

	return brick

func createBrickFromParsed(parsed_brick):
	var brick = brick_class.instance()
	brick.init(
		parsed_brick.get('name'),
		parsed_brick.get('dir'),
		parsed_brick.get('pos'),
		parsed_brick.get('sender_id')
	)
	brick.type = parsed_brick.get('type')

	return brick

func handleEnteredGoal(player):
	if is_queued_for_deletion():
		return

	rpc('destroy')
	if can_trigger_respawn:
		player.receivedGoal()
