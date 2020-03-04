extends Sprite

func _process(delta):
	look_at(get_global_mouse_position())