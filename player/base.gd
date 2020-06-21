extends StaticBody2D

signal base_created
signal base_destroyed

func handleWeaponCollision(collider, collision):
	rpc('destroy')

remotesync func destroy():
	if is_queued_for_deletion():
		return

	queue_free()
	emit_signal('base_destroyed', get_name())

func _draw():
	draw_circle(Vector2(0, 0), 60, Color(0, 0, 1))

func _ready():
	connect('base_created', get_parent(), '_on_base_created')
	connect('base_destroyed', get_parent(), '_on_base_destroyed')
	emit_signal('base_created', get_name())

func _on_button_pressed():
	var base_name = get_name()
	get_parent().syncCurrentBase(base_name)
	rpc('syncPlayerBase', get_name())

remote func syncPlayerBase(base_name):
	get_parent().syncCurrentBase(base_name)
