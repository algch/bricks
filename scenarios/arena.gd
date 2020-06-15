extends Node

const player_class = preload('res://player/player.tscn')
const spawner_class = preload('res://brick/brickSpawner.tscn')

var server_id
var client_id

var player_bricks = {}
var opponent_bricks = {}

var is_player_turn = false

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

func instantiateSpawner():
	var spawner = spawner_class.instance()
	spawner.position = $spawnerPos.position
	var name = str(get_tree().get_network_unique_id()) + '_' + str(get_instance_id())
	var emitter_id = get_tree().get_network_unique_id()
	spawner.init(name, emitter_id)
	add_child(spawner)
	rpc('syncSpawner', name)

remote func syncSpawner(name):
	var spawner = spawner_class.instance()
	spawner.position = Utils.getMirrored($spawnerPos.position)
	spawner.set_name(name)
	spawner.rotate(PI)
	add_child(spawner)

func _ready():
	instantiatePlayer()
	instantiateSpawner()
