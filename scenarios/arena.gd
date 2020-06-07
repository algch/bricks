extends Node

const player_class = preload('res://player/player.tscn')

var server_id
var client_id

var player_bricks = {}
var opponent_bricks = {}

var is_player_turn = false

func init(server, client):
	server_id = server
	client_id = client

func instantiatePlayer():
	var id = server_id if get_tree().is_network_server() else client_id
	var player = player_class.instance()
	player.set_name(str(id))
	player.set_network_master(id)
	player.set_position($playerPos.position)
	player.init(true)
	add_child(player)

func instantiateOpponent():
	var id = client_id if get_tree().is_network_server() else server_id
	var player = player_class.instance()
	player.set_name(str(id))
	player.set_network_master(id)
	player.set_position($opponentPos.position)
	player.rotate(PI)
	player.init(false)
	add_child(player)

remotesync func endTurn(turn):
	$turnTimer.stop()

	for weapon in get_tree().get_nodes_in_group('weapons'):
		weapon.destroy()

	if get_tree().get_rpc_sender_id() == get_tree().get_network_unique_id():
		is_player_turn = turn
	else:
		is_player_turn = !turn

	# check logic. Should te server handle brick spawning?
	# $brickSpawner.moveBricksToNextPos()
	if is_player_turn:
		$brickSpawner.spawnBricks()

	if is_player_turn:
		$turnTimer.start()

func _on_turnTimer_timeout():
	rpc('endTurn', !is_player_turn)

func decideStartingTurn():
	is_player_turn = randi() % 2 == 0
	if is_player_turn:
		$brickSpawner.spawnBricks()
		$turnTimer.start()
	rpc('syncTurn', !is_player_turn)

remote func syncTurn(turn):
	is_player_turn = turn
	if is_player_turn:
		$brickSpawner.spawnBricks()
		$turnTimer.start()

func _ready():
	if get_tree().is_network_server():
		decideStartingTurn()

	instantiatePlayer()
	instantiateOpponent()
