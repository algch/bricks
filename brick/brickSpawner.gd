extends Position2D

var brick_class = preload('res://brick/brick.tscn')
var BRICK_X_SIZE
var BRICK_Y_SIZE
const BRICK_SPACE = 10
onready var arena = get_node('/root/arena/')

func _ready():
	var brick = brick_class.instance()
	BRICK_X_SIZE = brick.X_SIZE
	BRICK_Y_SIZE = brick.Y_SIZE

func parseBrick(brick):
	return {
		'name': brick.get_name(),
		'dir': brick.move_dir,
		'pos': brick.get_global_position(),
		'type': brick.type,
	}

func createBrick(dir):
	var brick = brick_class.instance()
	var player_id = get_tree().get_network_unique_id()
	var brick_id = brick.get_instance_id()
	var name = str(player_id) + '_' + str(brick_id)
	var y_pos = position.y + (dir * BRICK_Y_SIZE)
	var brick_pos = Vector2(
		360,
		y_pos
	)
	brick.move_dir = Vector2(1 if randi() % 2 == 0 else -1, dir)
	brick.set_name(name)
	brick.set_position(brick_pos)
	arena.add_child(brick)

	return brick

func createBrickFromParsed(parsed_brick):
	var brick = brick_class.instance()
	brick.set_name(parsed_brick.get('name'))
	brick.set_position(parsed_brick.get('pos'))
	brick.type = parsed_brick.get('type')
	brick.move_dir = parsed_brick.get('dir')
	arena.add_child(brick)

func mirrorBrick(brick):
	var mirrored_y = 640 + (640 - brick.position.y)
	var mirrored_x = 360 + (360 - brick.position.x)
	var mirrored_pos = Vector2(mirrored_x, mirrored_y)
	return {
		'name': brick.get_name(),
		'dir': brick.move_dir,
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

	# bricks are mirrored
	rpc('syncSpawnedBricks', mirrored_opponent_brick, mirrored_player_brick) # executes in opponent

remote func syncSpawnedBricks(player_brick, opponent_brick):
	if player_brick:
		arena.player_bricks[player_brick.get('name')] = player_brick
		createBrickFromParsed(player_brick)

	if opponent_brick:
		arena.opponent_bricks[opponent_brick.get('name')] = opponent_brick
		createBrickFromParsed(opponent_brick)
