extends StaticBody2D

signal base_created
signal base_destroyed

func handleWeaponCollision(collider):
	queue_free()
	emit_signal('base_destroyed')
	# TODO trigger gameover check

func _ready():
	connect('base_created', get_parent(), '_on_base_created')
	connect('base_destroyed', get_parent(), '_on_base_destroyed')
	emit_signal('base_created')
