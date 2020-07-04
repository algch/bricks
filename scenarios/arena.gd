extends Node

const player_class = preload('res://player/player.tscn')
const spawner_class = preload('res://brick/brickSpawner.tscn')

var server_id
var client_id

var arrow_class = preload('res://weapons/arrow.tscn')
var ball_class = preload('res://brick/brickSpawner.tscn')

func init(server, client):
	server_id = server
	client_id = client

func instantiatePlayer():
	var id = get_tree().get_network_unique_id()
	var player = player_class.instance()
	player.set_name(str(id))
	player.set_network_master(id)
	player.set_position($playerPos.position)
	player.init(true)
	add_child(player)
	rpc('syncPlayer', id)

remote func syncPlayer(id):
	var player = player_class.instance()
	player.set_name(str(id))
	player.set_network_master(id)
	player.set_position($opponentPos.position)
	player.rotate(PI)
	player.init(false)
	add_child(player)

remote func syncSpawner(ball_name, pos, emitter_id):
	print('sync spawner ', ball_name, pos, emitter_id)
	var spawner = spawner_class.instance()
	spawner.init(ball_name, Utils.getMirrored(pos), emitter_id)
	# spawner.rotate(PI)
	if get_node(ball_name):
		return
	add_child(spawner)

func spawnBall(): # TODO: spawn ball near the player that lost the point
	var pos = $spawnerPos.position
	var spawner = spawner_class.instance()
	var ball_name = str(get_tree().get_network_unique_id()) + '_' + str(get_instance_id())
	var emitter_id = get_tree().get_network_unique_id()
	spawner.init(ball_name, pos, emitter_id)
	spawner.can_trigger_respawn = true
	add_child(spawner)
	print('created spawner ', spawner.get_name(), pos, emitter_id)
	rpc('syncSpawner', ball_name, pos, emitter_id)
	$spawnBallTimer.stop()

func _ready():
	randomize()
	instantiatePlayer()

	if not get_tree().is_network_server():
		return

	$spawnBallTimer.start()
