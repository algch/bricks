extends Node

var my_turn = false

func _ready():
    if get_tree().is_network_server():
        decideTurn()

func decideTurn():
    var server_starts = randi() % 2 == 0
    if server_starts:
        my_turn = true
    else:
        handleTurnEnded()

func handleTurnEnded():
    print('turn ended')
    my_turn = false
    rpc('startTurn')

remote func startTurn():
    my_turn = true
