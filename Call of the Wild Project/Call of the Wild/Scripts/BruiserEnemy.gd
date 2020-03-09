extends "res://Scripts/EnemyCore.gd"

func _physics_process(delta):
	apply_gravity(delta) #Apply gravity to the enemy
	
	ai_process()
	
	velocity = move_and_slide(velocity, Vector2(0, -1)) #Move enemy
	
	state_check()
	correct_area_position()
	
	if is_on_floor():
		if state == "Jump":
			landed()
	
	animation_process() #Play next animation

func ai_process():
	if state == "Hurt":
		return
	
	#If the enemy is being knocked back
	if movement_mode == "Knockback":
		knockback_process() #Use the knockback process
	
	attack_check() #Check to do an attack
	
	if state in ["Move", "Jump"]:
		if movement_mode == "Path":
			move_on_path()
		if movement_mode == "Follow":
			move_towards_target()
	elif state == "Idle":
		yield(get_tree().create_timer(idle_time), "timeout")
		set_state("Move")
	
	wall_check() #Check for walls
	correct_area_position() #Correct detector area positions
	check_for_ground() #Make sure there's ground in front of the enemy


