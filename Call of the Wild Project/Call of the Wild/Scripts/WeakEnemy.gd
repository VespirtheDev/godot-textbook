extends "res://Scripts/EnemyCore.gd"

#Each enemy has their own script so that they can have their own unique behavior

func _physics_process(delta):
	apply_gravity(delta) #Apply gravity to the enemy
	
	ai_process() #Run to see what the enemy is going to do
	
	velocity = move_and_slide(velocity, Vector2(0, -1)) #Move enemy
	
	state_check() #Make sure the enemy is in the correct state
	correct_area_position() #Make sure the nodes the enemy uses are in the right position
	animation_process() #Play next animation

func ai_process():
	if state == "Hurt":
		return
	
	#If the enemy is being knocked back
	if movement_mode == "Knockback":
		knockback_process() #Use the knockback process
	
	if state == "Backstep":
		flee_from_target()
	
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

func char_anim_finished(anim_name):
	if anim_name == "Attack":
		set_state("Backstep")


