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

func createBrick(brick_list, dir):
	var brick = brick_class.instance()
	var player_id = get_tree().get_network_unique_id()
	var brick_id = brick.get_instance_id()
	var name = str(player_id) + '_' + str(brick_id)
	var y_pos = position.y + (dir * BRICK_Y_SIZE)
	y_pos += (dir) * (BRICK_Y_SIZE/2 + BRICK_Y_SIZE * len(brick_list))
	var brick_pos = Vector2(
		360,
		y_pos
	)
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

func moveBricksToNextPos():
	for brick_name in arena.player_bricks:
		arena.player_bricks[brick_name]['pos'] += BRICK_Y_SIZE

	for brick_name in arena.opponent_bricks:
		arena.opponent_bricks[brick_name]['pos'] -= BRICK_Y_SIZE

func spawnBricks():
	var player_brick = createBrick(arena.player_bricks, 1)
	var parsed_player_brick = parseBrick(player_brick)
	arena.player_bricks[player_brick.get_name()] = parsed_player_brick

	var opponent_brick = createBrick(arena.opponent_bricks, -1)
	var parsed_opponent_brick = parseBrick(opponent_brick)
	arena.opponent_bricks[opponent_brick.get_name()] = parsed_opponent_brick

	# bricks are mirrored
	var mirrored_opponent_brick = mirrorBrick(opponent_brick)
	var mirrored_player_brick = mirrorBrick(player_brick)
	rpc('syncSpawnedBricks', mirrored_opponent_brick, mirrored_player_brick) # executes in opponent

remote func syncSpawnedBricks(player_brick, opponent_brick):
	arena.player_bricks[player_brick.get('name')] = player_brick
	createBrickFromParsed(player_brick)
	arena.opponent_bricks[opponent_brick.get('name')] = opponent_brick
	createBrickFromParsed(opponent_brick)
