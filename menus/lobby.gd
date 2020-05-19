extends Control

const DEFAULT_IP = '127.0.0.1'
const DEFAULT_PORT = 31400
const MAX_PLAYERS = 2

var ip_address
var start_server

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

func connectToServer():
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	var peer = NetworkedMultiplayerENet.new()
	print('Requesting connection to lobby [' + ip_address + ']')
	peer.create_client(ip_address, DEFAULT_PORT)
	get_tree().set_network_peer(peer)

func _connected_to_server(): # on client when connected to server
	var local_player_id = get_tree().get_network_unique_id()
	rpc_id(1, 'requestGameState', local_player_id)

func startMatch():
	# instance players
	get_tree().change_scene('res://scenarios/arena.tscn')
