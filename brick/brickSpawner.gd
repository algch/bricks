extends Position2D

var brick_class = preload('res://brick/brick.tscn')
var BRICK_X_SIZE
var BRICK_Y_SIZE
const BRICK_SPACE = 10
onready var arena = get_node('/root/arena/')

# TODO mirror birck rpc calls, server must decide brick type

func _ready():
	var brick = brick_class.instance()
	BRICK_X_SIZE = brick.X_SIZE
	BRICK_Y_SIZE = brick.Y_SIZE

func parseBrick(brick):
	return {
		'name': brick.get_name(),
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
	print('brick ', name, ' y_pos ', y_pos)
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
	arena.add_child(brick)

func mirrorBrick(brick):
	var mirrored_y = 640 + (640 - brick.position.y)
	var mirrored_x = 360 + (360 - brick.position.x)
	var mirrored_pos = Vector2(mirrored_x, mirrored_y)
	return {
		'name': brick.get_name(),
		'pos': mirrored_pos,
		'type': brick.type,
	}

func spawnBricks():
	var player_brick = createBrick(arena.player_bricks, 1)
	var parsed_player_brick = parseBrick(player_brick)
	arena.player_bricks.append(parsed_player_brick)

	var opponent_brick = createBrick(arena.opponent_bricks, -1)
	var parsed_opponent_brick = parseBrick(opponent_brick)
	arena.opponent_bricks.append(parsed_opponent_brick)

	print('created brick pos ', player_brick.get_position(), player_brick.get_name())
	print('created brick pos ', opponent_brick.get_position(), opponent_brick.get_name())

	# bricks are mirrored
	var mirrored_opponent_brick = mirrorBrick(opponent_brick)
	var mirrored_player_brick = mirrorBrick(player_brick)
	print('mirrored brick pos ', mirrored_player_brick['pos'], mirrored_player_brick['name'])
	print('mirrored brick pos ', mirrored_opponent_brick['pos'], mirrored_opponent_brick['name'])
	rpc('syncSpawnedBricks', mirrored_opponent_brick, mirrored_player_brick) # executes in opponent

remote func syncSpawnedBricks(player_brick, opponent_brick):
	print('received brick pos ', player_brick['pos'], player_brick['name'])
	print('received brick pos ', opponent_brick['pos'], opponent_brick['name'])
	arena.player_bricks.append(player_brick)
	createBrickFromParsed(player_brick)
	arena.opponent_bricks.append(opponent_brick)
	createBrickFromParsed(opponent_brick)
