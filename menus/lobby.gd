extends Control

var arena_class = preload('res://scenarios/arena.tscn')

const DEFAULT_IP = '127.0.0.1'
const DEFAULT_PORT = 31400
const MAX_PLAYERS = 2

var ip_address
var start_server

var server_id = 1
var client_id

var ready_players = {}

func init(ip, server):
	ip_address = ip
	start_server = server

func _ready():
	if start_server:
		self.initServer()
	else:
		self.connectToServer()

func initServer():
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('network_peer_connected', self, '_on_player_connected')
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	ready_players[1] = false

func _on_player_connected(player_id):
	ready_players[player_id] = false
	client_id = player_id
	print('[' + str(player_id) + '] joined the game')
	rpc('setReadyPlayers', ready_players)

func _on_player_disconnected(player_id):
	ready_players.erase(player_id)
	print('[' + str(player_id) + '] left the game')

func connectToServer():
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	var peer = NetworkedMultiplayerENet.new()
	print('Requesting connection to lobby [' + ip_address + ']')
	peer.create_client(ip_address, DEFAULT_PORT)
	get_tree().set_network_peer(peer)

func _connected_to_server(): # on client when connected to server
	client_id = get_tree().get_network_unique_id()
	print('connected')

func _on_ready_pressed():
	var player_id = get_tree().get_network_unique_id()
	var pressed = $VBoxContainer/ready.is_pressed()
	rpc('setPlayerStatus', player_id, pressed)

remote func setReadyPlayers(players):
	ready_players = players

remotesync func setPlayerStatus(player_id, ready):
	print('setting player status')
	ready_players[player_id] = ready
	startMatchIfAllReady()

func startMatchIfAllReady():
	print('ready players ', ready_players)
	if not ready_players:
		return
	for player_id in ready_players:
		if not ready_players[player_id]:
			return

	var arena = arena_class.instance()
	arena.init(server_id, client_id)

	var root = get_node('/root/')
	var lobby = root.get_node('lobby')
	root.remove_child(lobby)
	lobby.queue_free()
	root.add_child(arena)
