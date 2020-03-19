extends Sprite

func _process(delta):
	var aimer = Vector2(Input.get_joy_axis(get_parent().player_id, JOY_AXIS_2), Input.get_joy_axis(get_parent().player_id, JOY_AXIS_3))
	var cursor_pos = Vector2()
	
	if PlayerPref.control_type == "Keyboard":
		look_at(get_global_mouse_position())
		#Keyboard angles need work
	
	if PlayerPref.control_type == "Controller":
		if aimer.length() < 0.25:
			cursor_pos.x = aimer.x 
			cursor_pos.y = aimer.y
		var new_angle = aimer.angle()
		
		#look_at(cursor_pos)
		if aimer.length() > 0.25:
			rotation = new_angle