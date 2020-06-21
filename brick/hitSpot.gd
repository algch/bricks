extends Particles2D


func _on_spanTimer_timeout():
	queue_free()
