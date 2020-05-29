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
		'pos': brick.get_global_position(),
		'type': brick.get_type(),
	}

func spawnBricks():
	var player_brick = brick_class.instance()
	var opponent_brick = brick_class.instance()

	var player_brick_pos = Vector2(
		360,
		position.y + BRICK_Y_SIZE + BRICK_Y_SIZE/2 + BRICK_Y_SIZE * len(arena.player_bricks)
	)
	player_brick.set_position(player_brick_pos)
	arena.add_child(player_brick)
	var parsed_player_brick = parseBrick(player_brick)
	arena.player_bricks.append(parsed_player_brick)

	var opponent_brick_pos = Vector2(
		360,
		position.y - (BRICK_Y_SIZE + BRICK_Y_SIZE/2 + BRICK_Y_SIZE * len(arena.opponent_bricks))
	)
	opponent_brick.set_position(opponent_brick_pos)
	arena.add_child(opponent_brick)
	var parsed_opponent_brick = parseBrick(player_brick)
	arena.opponent_bricks.append(parsed_opponent_brick)

	# bricks are mirrored
	rpc('syncSpawnedBricks', arena.opponent_bricks, arena.player_bricks)

remote func syncSpawnedBricks(player_bricks, opponent_bricks):
	arena.player_bricks = player_bricks
	arena.opponent_bricks = opponent_bricks
