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

func spawnBricks():
	var player_brick = createBrick(arena.player_bricks, 1)
	var parsed_player_brick = parseBrick(player_brick)
	arena.player_bricks.append(parsed_player_brick)

	var opponent_brick = createBrick(arena.opponent_bricks, -1)
	var parsed_opponent_brick = parseBrick(opponent_brick)
	arena.opponent_bricks.append(parsed_opponent_brick)

	# bricks are mirrored
	rpc('syncSpawnedBricks', parsed_opponent_brick, parsed_player_brick)

remote func syncSpawnedBricks(player_brick, opponent_brick):
	arena.player_bricks.append(player_brick)
	createBrickFromParsed(player_brick)
	arena.opponent_bricks.append(opponent_brick)
	createBrickFromParsed(opponent_brick)
