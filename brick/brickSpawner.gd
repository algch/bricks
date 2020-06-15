extends KinematicBody2D

var brick_class = preload('res://brick/brick.tscn')
var BRICK_X_SIZE
var BRICK_Y_SIZE
const BRICK_SPACE = 10
onready var arena = get_node('/root/arena/')
var should_move = false
var MAX_SPEED = 500
var speed = MAX_SPEED
var direction = null
var sender_id = null

func handleWeaponCollision(collider, collision):
	if collider.sender_id == get_tree().get_network_unique_id():
		collider.rpc('destroy')
		should_move = true
		var normal = collision.get_normal()
		direction = collider.direction.bounce(normal).rotated(PI)
		$movementTimer.start()

		var brick_dir = Vector2(0, -1)
		if collider.sender_id == sender_id:
			brick_dir *= -1
		var brick = self.createBrick(brick_dir)
		arena.add_child(brick)
		var raw_brick = self.parseBrick(brick)

		rpc('syncCollision', position, direction, raw_brick)

func init(spawner_name, emitter_id):
	name = spawner_name
	sender_id = emitter_id

remote func syncCollision(pos, dir, raw_brick):
	position = Utils.getMirrored(pos)
	direction = dir.rotated(PI)
	should_move = true
	$movementTimer.start()
	var brick = self.createBrickFromParsed(raw_brick)
	brick.position = position
	brick.move_dir = brick.move_dir.rotated(PI)
	arena.add_child(brick)

func _on_movementTimer_timeout():
	should_move = false
	var pos = Utils.getMirrored(position)
	rpc('syncPos', pos)

remote func syncPos(pos):
	position = pos

func _draw():
	draw_circle(Vector2(0, 0), 60, Color(0, 1, 1))

func _physics_process(delta):
	if not should_move:
		return

	speed = MAX_SPEED - (MAX_SPEED * (($movementTimer.get_wait_time() - $movementTimer.get_time_left()) / $movementTimer.get_wait_time()))
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if  collision:
		var normal = collision.get_normal()
		direction = direction.bounce(normal)

func _ready():
	var brick = brick_class.instance()
	BRICK_X_SIZE = brick.X_SIZE
	BRICK_Y_SIZE = brick.Y_SIZE
	$Label.set_text(get_name())

func parseBrick(brick):
	# TODO do we need all the data here?
	return {
		'name': brick.get_name(),
		'dir': brick.move_dir,
		'pos': brick.get_position(),
		'rot': brick.rotation,
		'type': brick.type,
	}

func createBrick(dir):
	var brick = brick_class.instance()
	var player_id = get_tree().get_network_unique_id()
	var brick_id = brick.get_instance_id()
	var name = str(player_id) + '_' + str(brick_id)
	brick.move_dir = dir
	brick.set_name(name)
	brick.set_position(position)
	# brick.set_rotation(rotation)

	return brick

func createBrickFromParsed(parsed_brick):
	var brick = brick_class.instance()
	brick.set_name(parsed_brick.get('name'))
	brick.set_position(parsed_brick.get('pos'))
	brick.type = parsed_brick.get('type')
	brick.move_dir = parsed_brick.get('dir')
	# brick.rotation = parsed_brick.get('rot')

	return brick

func mirrorBrick(brick):
	var mirrored_y = 640 + (640 - brick.position.y)
	var mirrored_x = 360 + (360 - brick.position.x)
	var mirrored_pos = Vector2(mirrored_x, mirrored_y)
	var mirrored_dir = brick.move_dir * -1

	return {
		'name': brick.get_name(),
		'dir': mirrored_dir,
		'pos': mirrored_pos,
		'type': brick.type,
	}

func getBrickByName(name):
	return get_node('/root/arena/' + name)

func moveBricksToNextPos():
	for brick_name in arena.player_bricks:
		if len(arena.player_bricks) >= 3:
			break
		var brick = getBrickByName(brick_name)
		brick.position += Vector2(0, BRICK_Y_SIZE + BRICK_Y_SIZE/2)
		arena.player_bricks[brick_name]['pos'] = brick.position

	for brick_name in arena.opponent_bricks:
		if len(arena.opponent_bricks) >= 3:
			break
		var brick = getBrickByName(brick_name)
		brick.position -= Vector2(0, BRICK_Y_SIZE + BRICK_Y_SIZE/2)
		arena.opponent_bricks[brick_name]['pos'] = brick.position

func spawnBricks():
	var mirrored_opponent_brick = null
	var mirrored_player_brick = null

	if len(arena.player_bricks) < 3:
		var player_brick = createBrick(1)
		var parsed_player_brick = parseBrick(player_brick)
		arena.player_bricks[player_brick.get_name()] = parsed_player_brick
		mirrored_player_brick = mirrorBrick(player_brick)

	if len(arena.opponent_bricks) < 3:
		var opponent_brick = createBrick(-1)
		var parsed_opponent_brick = parseBrick(opponent_brick)
		arena.opponent_bricks[opponent_brick.get_name()] = parsed_opponent_brick
		mirrored_opponent_brick = mirrorBrick(opponent_brick)

	rpc('syncSpawnedBricks', mirrored_opponent_brick, mirrored_player_brick)

remote func syncSpawnedBricks(player_brick, opponent_brick):
	if player_brick:
		arena.player_bricks[player_brick.get('name')] = player_brick
		createBrickFromParsed(player_brick)

	if opponent_brick:
		arena.opponent_bricks[opponent_brick.get('name')] = opponent_brick
		createBrickFromParsed(opponent_brick)
