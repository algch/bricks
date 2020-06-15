extends Control

var lobby_class = preload('res://menus/lobby.tscn')
# TODO create solo scene
# var solo_class = preload('res://scenarios/solo.tscn')
var ip_address = ''

func _ready():
	ip_address = $VBoxContainer/HBoxContainer2/ipAddress.get_text()

func _on_solo():
	pass

func _on_createMatch():
	self.createLobby(true)

func _on_join():
	self.createLobby(false)

func createLobby(server):
	var root = get_tree().get_root()
	var menu = root.get_node('mainMenu')
	root.remove_child(menu)
	menu.queue_free()
	var lobby = lobby_class.instance()
	lobby.init(ip_address, server)
	root.add_child(lobby)

func _on_ipAddress_text_changed(new_text):
	ip_address = new_text
