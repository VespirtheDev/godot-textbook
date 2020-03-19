extends "res://Scripts/Characters/Character.gd"

#This function handles the character states
func set_state(new_state):
	match new_state:
		IDLE:
			$StepSoundTimer.stop()
			next_anim = "Idle"
		RUN:
			if $StepSoundTimer.time_left == 0:
				$StepSoundTimer.start()
		HURT:
			$StepSoundTimer.stop()
			next_anim = "Hurt"
			animation_update()
			
			$ImmortalDuration.start()
			
			if health <= 0:
				set_state(DEAD)
				return
			else:
				set_state(IDLE)
				return
		DEAD:
			$StepSoundTimer.stop()
			next_anim = "Dead"
			animation_update()
	
	state = new_state

func _physics_process(delta):
	if state in [DEAD, HURT]: #If the player is hurt or dead they can't do much
		return
	
	control_process() #Checks for control inputs
	
	velocity = move_and_slide(velocity).normalized() #Moves the player
	
	state_check() #Ensures the player is in the correct state
	animation_update() #Checks to see if the animation needs to be updated

#This function handles the player's control type
func _input(event):
	if event is InputEventMouseButton:
		PlayerPref.control_type == "Keyboard"
	if event is InputEventMouseMotion:
		PlayerPref.control_type == "Keyboard"

#This function handles the control inputs
func control_process():
	var move_up = Input.is_action_pressed("Up")
	var move_down = Input.is_action_pressed("Down")
	var move_right = Input.is_action_pressed("Right")
	var move_left = Input.is_action_pressed("Left")
	var attack = Input.is_action_pressed("Attack")
	#--------------------------------------------------
	
	velocity = Vector2() #Set velocity to Vector2(0, 0) so the don't glide
	
	#Basic movement code
	if move_right:
		velocity.x += move_speed
	if move_left:
		velocity.x -= move_speed
	if move_up:
		velocity.y -= move_speed
	if move_down:
		velocity.y += move_speed
	
	rotate_player() #Rotate the player
	
	if attack: #If the player is attacking
		$Weapon.shoot(rotation) #Send the rotation to the Weapon node

#This function handles rotating the player
func rotate_player():
	var look_direction #This is the direction the player is looking at
	
	match PlayerPref.control_type:
		"Keyboard": #If using keyboard
			look_direction = get_local_mouse_position() #The player is looking at the local mouse position
			rotation += look_direction.angle() #Rotate player
		"Controller": #If using controller
			#Get the right joysticks Y and X values for player 1
			look_direction.y = Input.GetJoyAxis(0, 3);
			look_direction.x = Input.GetJoyAxis(0, 2);
			rotation = look_direction.angle() #Rotate player

#This function corrects the player's state
#To ensure the player is always in the correct state
func state_check():
	if state == IDLE:
		if velocity != Vector2(0, 0):
			set_state(RUN)
	
	if state == RUN:
		if velocity == Vector2(0, 0):
			set_state(IDLE)

#This function handles healing the player
func heal(amount):
	health += amount #Add the amount to the health value
	health = clamp(health, 0, health_max) #Clamp health to 0 and health max

#This function handles taking damage
func take_damage(amount):
	#If the player is hurt or dead they can't be hurt more
	if state in [HURT, DEAD]:
		return
	
	health -= amount #Reduce health by damage amount
	health = clamp(health, 0, health_max) #Clamp the health value at 0 or health_max
	
	set_state(HURT) #Set state to hurt

#This function plays the step sound when the timer goes off
func play_step_sound():
	$Sounds/Run.play()


