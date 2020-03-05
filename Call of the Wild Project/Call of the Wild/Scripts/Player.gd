extends KinematicBody2D

#Conventions I Use [Behind the Code]

#I use double empty lines to help organize different functions like categories. It's much easier to sift through
#than having a big cluster of functions

#I use can_blank() functions if I have multiple conditionals or something that may have multiple conditionals in the future. Or a conditional group used often.
#It's easier to manage a group of conditionals, they're in one spot; and it makes using that group of conditionals cleaner.
#Explaining return: return insert_variable will send replace the check function call with the returned value essentially. Or can be used to assign values to variables.

signal add_score #This will be emitted to add score in the HUD
signal update_health #This will be emitted to update the health visual in the HUD
signal update_stamina #This will be emitted to update the stamina visual in the HUD
signal player_died #This will emit to tell the Level script when a player has died

var state = "" #Current state of character
var sub_state = "Default" #Current sub state of character
var next_anim = "" #Next animation in queue to play

#This helps to make sure the player starts in the right direction in case
#Levels progress in opposite directions.
export (String, "Right", "Left") var starting_direction = "Left"

export (float) var gravity #The force of gravity pulling the player down

export (float) var run_speed_max #Max speed that can be reached while running
export (float) var run_speed_acceleration #Rate of acceleration while in Run state
export (float) var run_speed_deceleration #Rate of deceleration while in Run state
export (float) var sprint_speed_max #Max speed that can be reached while sprinting
export (float) var sprint_speed_acceleration #Rate of acceleration while in Sprint state
export (float) var sprint_speed_deceleration #Rate of deceleration while in Sprint state
export (float) var slide_decleration #Rate of deceleration while in slide state
export (float) var slide_speed_max #Max speed that can be reached while in slide state
export (float) var crouch_acceleration #Rate of acceleration in Crouch state
export (float) var crouch_speed_max #Max speed that can be reached while in the crouch state
export (float) var backstep_speed #How fast the player's backstep/evade ability is

export (float) var climb_speed #How fast the player can climb

export (float) var sprint_stamina_cost #The stamina cost of sprinting
export (float) var wallrun_stamina_cost #The stamina cost of wall running
export (float) var long_jump_stamina_cost

onready var speed_max = run_speed_max #Sets the current speed max
onready var acceleration = run_speed_acceleration #Sets the current acceleration
export (float) var deceleration #The deceleration of speed
var velocity = Vector2(0, 0) #Total velocity the player is being moved by

export (float, 0, 1) var acceleration_sensitivity #How effective acceleration is
export (float, 0, 1) var deceleration_sensitivity #How effective deceleration is

export (float) var jump_force_default #How powerful is the player jump
onready var jump_force = jump_force_default #How powerful is the player jump
export (float) var jump_duration_max #How long can the player hold the jump for a variable jump
export (float) var jump_count_max #How many times can a player jump before landing
onready var jump_count = jump_count_max #How many jumps the player has left
onready var jump_duration_current = jump_duration_max #How much longer the player can hold the jump for

var damage = 0.0 #How much damage player attacks do
var knockback = Vector2(0, 0) #How much knockback the player attack has
var knockback_duration = 0.0 #How long player attack knockback lasts
var knockback_movement = Vector2() #How much the player is being knocked back for

#True is the same as on and functional
#Example: var light_bulb = true is the same as turning on a light in a room with a switch
#False is the same as off and non-functional
#Example: var light_bulb = false is the same as turning off a light in a room with a switch
var gravity_stop_active = true #This is a anti-frustration measure that will tell the game when to stop gravity

export (int) var health_max = 100 #How much health the player can have
onready var health_current = health_max #How much health the player has right now
export (float) var stamina_max #Max amount of stamina the player can have
export (float) var stamina_regen_amount #How much stamina is regained each regen duration
onready var stamina_current = stamina_max #How much stamina the player has right now

export (float) var death_fall_height #How far the player can fall before dying

export (float) var slope_run_angle #The angle that requires at least a basic run
export (float) var slope_sprint_angle #The angle that requires the player to sprint up
export (float) var slope_slide_angle #The angle that will make the player slide when not sprinting

var current_slope_angle = 0 #The angle of the current ground

var direction = Vector2() #Records which direction the player is moving in

var can_wallrun = false #Tells if the player can wall run right now or not

export (Dictionary) var attack_library #Holds the attack information can be seen in editor. Attack names, damage, knockback data

export (Dictionary) var combo_library #Holds the combo information can be seen in editor. Sets of arrays to match with the combo array to determine a combo
export (int) var combo_limit #The max amount of attacks per combo
var attack_queue = [] #Attacks that have yet to happen. If the player attacks during an attack the new attack will be stored here for later use.
var combo = [] #The current combo attacks. Each attack is placed into the array to create an array of attack names.

var can_attack = true #This is an ultimate on or off switch for attacking. It has to be on for the player to be able to attack.

var ignore_speed_max = false #This determines if the player can go past the speed maximum or not

#This function does any setup needed for the player; serves as a manual _ready function
func setup():
	#Find which case in this match statement that is the starting direction
	match starting_direction:
		#Right and Left are called cases which hold code to run
		#The game is finding which case is equal to the starting_direction value
		#Then it runs that code
		"Right":
			$CharSprite.flip_h = false #The player's sprite is not flipped over the horizontal axis
		"Left":
			$CharSprite.flip_h = true #The player's sprite is flipped over the horizontal axis 
	
	set_state("Idle") #We set the starting state to Idle
	update_hud() #Then the HUD gets updated to show the correct player information

#This function handles setting the character state
func set_state(new_state):
	#Matches new_state to the case that equals the value of new state | Example: "Idle" == new_state if new_state == "Idle"
	#Sub states are matched within main states since they act as state modifiers
	#We don't set the state to the new_state just yet.
	#This is so if we need to know what the last state was we don't need a new variable
	#We can just use state and nothing is harmed by doing this.
	
	match new_state: #First we find the case that equals the new_state value
		"Idle":
			set_camera_angle("Normal") #We set the camera angle back to normal which is a non-special angle
			match sub_state: #Then we find the sub-state to modify the main state
				"Default":
					next_anim = "Idle" #Queue Idle animation to play
				"Crouch":
					next_anim = "CrouchIdle" #Queue Crouch Idle animation to play
			$Sounds/RunSound.stop() #Stop run sounds since the player is not moving
		
		"Run":
			set_camera_angle("Normal") #We set the camera angle back to normal which is a non-special angle
			match sub_state: #Then we find the sub-state to modify the main state
				"Default":
					speed_max = run_speed_max #Change speed max
					acceleration = run_speed_acceleration #Change acceleration speed
					deceleration = run_speed_deceleration #Change deceleration speed
					deceleration_sensitivity = 1 #The player will decelarate at 1 sensitivity which is max sensitivity AKA full speed
					
					next_anim = "Run" #Queue Run Animation
					$Sounds/RunSound.play() #Play the run sound
				"Crouch":
					speed_max = crouch_speed_max #Change the speed max to the crouch speed max
					acceleration = crouch_acceleration #Change the acceleration speed
					next_anim = "CrouchWalk" #Queue the CrouchWalk animation to play
		
		"Sprint":
			next_anim = "Run" #Queue the Run animation to play
			speed_max = sprint_speed_max #Change the speed max
			acceleration = sprint_speed_acceleration #Change acceleration speed
			deceleration = sprint_speed_deceleration #Change the deceleration speed
			deceleration_sensitivity = 0.8 #The player will decelerate at a 0.8 sensitivity which is a little less than the max sensitivty so the player doesn't stop as quickly to simulate moving at a higher speed
		
		"Backstep":
			#Velocity is set to the negative value of their direction on the X axis multiplied by the backstep speed
			#This will move the player in the opposite direction their facing
			#Moving them away from the danger they were evading
			velocity = Vector2(-direction.x * backstep_speed, 0)
			$BackstepDuration.start() #Start the backstep duration timer
		
		"Jump":
			match sub_state: #Then we find the sub-state to modify the main state
				"Default":
					jump_force = jump_force_default #Sets the jump force back to the jump force to default to ensure the proper jump force amount
					next_anim = "Jump" #Queue Jump animation to play
					$Sounds/JumpSound.play() #Play the jump sound
					$Sounds/RunSound.stop() #Stop playing the run sound
				"LongJump":
					next_anim = "LongJump" #Queue the long jump animation to play
					jump_force = 350 #Set the jump force to 350
					velocity.x = direction.x * 350 #Their X velocity multiplies their direction by 450
					jump_duration_current -= 0.5 #A bit of their jump duration is taken
					stamina_current -= long_jump_stamina_cost #Stamina is also taken from the player
					ignore_speed_max = true #The player can ignore the max speed to give the proper movement
		
		"Fall":
			jump_force = jump_force_default #Sets the jump force back to the jump force to default to ensure the proper jump force amount
			$Sounds/RunSound.stop() #Stop the run sound
			match sub_state:
				"Default":
					next_anim = "Fall" #Queue Fall animation to play
		
		"Slide":
			next_anim = "Slide" #Queue the Slide animation to play
			deceleration = slide_decleration #Set the deceleration to the slide deceleration speed
			deceleration_sensitivity = 1 #The player will decelarate at 1 sensitivity which is max sensitivity AKA full speed
			speed_max = slide_speed_max #Set the speed max to the slide speed max speed
			$Sounds/RunSound.stop() #Stop run stounds
		
		"WallRun":
			next_anim = "Run" #Queue the Run animation to play
		
		"Hurt":
			set_camera_angle("Hurt") #Set the camera angle to Hurt
			next_anim = "Hurt" #Queue the Hurt animation to play
			$ImmortalTimer.start() #Start the immortal duration timer
			
			#If the player's current health is less than or equal to 0 then they're dead
			if health_current <= 0:
				set_state("Dead") #Their state is set to Dead then the function is left so it doesn't interrupt the dead state being run
				return
		
		"Climb":
			jump_count = jump_count_max #The player's jump count is reset to the max jump amount
			jump_duration_current = jump_duration_max #The jump duration is reset to the max jump duration
		
		"Dead":
			emit_signal("player_died") #This signal will tell the game the player has died.
	
	state = new_state #Change current state now

#Sub states are set in this function
func set_sub_state(new_sub_state):
	sub_state = new_sub_state #New sub state is assigned
	#I then set state to the current state so it uses the sub_state as a modifier
	set_state(state)

#This function handles ensuring the character is in the right state
func state_check():
	#If the player isn't on the floor
	
	#We don't want to check the state if the player is Backstepping so that they're not
	#Thrown into a different state. The state is changed when the backstep timer runs out
	#So we just leave the function with return
	if state in ["Backstep"]:
		return
	
	#If the player is hitting a wall
	if is_on_wall():
		if sub_state == "LongJump": #If the player is doing a long jump
			landed() #Then they've landed
	
	#If the player is not touching the ground
	if not is_on_floor():
		$DustParticles.emitting = false #Turn off the dust particles since they can't create them by running anymore.
		if velocity.y > 0 and state != "Climb": #If they're moving down and are not climbing
			set_state("Fall") #Then the player is falling so set them to the Fall state
	
	#If the player is on the floor
	if is_on_floor():
		if state == "Climb": #If the player is climbing then set them back to state Idle
			set_state("Idle")
		if state in ["Jump", "Fall"]: #If they're in an air state
			landed() #Then they've landed
		
		if velocity.x != 0: #If the player is moving
			$DustParticles.emitting = true #Turn on the dust particles
		else: #Otherwise turn off the dust particles
			$DustParticles.emitting = false
	
	#If the player state is Idle
	if state == "Idle":
		if velocity.x != 0: #If the player horizontal velocity is not 0
			if not $WallCheck/Bottom.is_colliding() and not $WallCheck/Mid.is_colliding() and not $WallCheck/Top.is_colliding():
				set_state("Run") #Then the player is running so set their state to Run
	
	#If the player state is either Run or Sprint (both are in an array)
	if state in ["Run", "Sprint"]:
		if velocity.x == 0: #If the player's horizontal velocity is 0
			set_state("Idle") #Then player isn't moving so set their state to Idle
	
	#If the player sub_state is Crouch
	if sub_state == "Crouch":
		if not is_on_floor(): #If the player isn't on the floor
			set_sub_state("Default") #They can't be crouching so set their sub state to Default
		if state in ["Sprint", "Slide"]: #If the player is sprinting or sliding they're no longer crouching
			set_sub_state("Default") #So set their sub state to Default
	
	#If the player state is WallRun
	if state == "WallRun":
		#abs() gets the absolute value of a number which is the positive value and never a negative
		if abs(velocity.x) < 1: #If the absolute value of the player' horizontal velocity is less than 1
			set_state("Run") #Set their state to Run since they've run out of speed
			can_wallrun = false #They can no longer wallrun
	
	#If the ground angle is less than the slide slope angle and it's above 0 and the player isn't sliding set their horizontal velocity to 0
	if check_ground_angle() < slope_slide_angle and check_ground_angle() > 0 and not state in ["Slide", "Sprint"]:
		velocity.x = 0
	#If the ground angle is greater than or equal to the slide slope angle and the state isn't in Slide or Sprint then set the player state to Slide
	elif check_ground_angle() >= slope_slide_angle and not state in ["Slide", "Sprint"]:
		if check_ground_angle() < 90 and $GroundCheck.is_colliding():
			set_state("Slide")
	
	#Checks to see which way the player should be moving and moves detectors accordingly
	#If the player is moving to the right
	if direction.x > 0:
		$CharSprite.flip_h = false #The player's sprite is no longer flipped over the horizontal axis
		$FallCatcher.position.x = 13 #Change FallCatcher position
		$DamageArea/AreaCollider.position.x = 7 #Moves the DamageArea to the right
		$DustParticles.process_material.set("gravity", Vector3(-200, 0, 0)) #The dust particles has their gravity changed
		$AttackConnectedParticles.process_material.set("gravity", Vector3(-250, 200, 0)) #The attack connect particles have their gravity changes
		$AttackConnectedParticles.position.x = 18 #The attack connect particles are moved to the right side of the player
	
	#If the player is moving to the left
	elif direction.x < 0:
		$CharSprite.flip_h = true #The player's sprite is flipped over the horizontal axis
		$FallCatcher.position.x = -13 #Change FallCatcher position
		$DamageArea/AreaCollider.position.x = -7 #Moves the DamageArea to the left
		$DustParticles.process_material.set("gravity", Vector3(200, 0, 0)) #The dust particles has their gravity changed
		$AttackConnectedParticles.process_material.set("gravity", Vector3(250, 200, 0)) #The attack connect particles have their gravity changes
		$AttackConnectedParticles.position.x = -18 #The attack connect particles are moved to the left side of the player


#This function runs each tick
func _physics_process(delta):
	#The main section of the process function do not get ran if the player is dead or hurt
	#If the player is dead or hurt they shouldn't be able to move but we still need animation to update
	if not state in ["Hurt", "Dead"]:
		apply_gravity(delta) #Adds gravity to the velocity (More details in the function/method)
		control_check() #Checks for inputs and handles them (More details in the function/method)
		
		#Snap is used for move_and_slide_with_snap which is really useful for keeping the player on the ground when they should be.
		var snap = 0 #Snap that we'll use to snap the player to the ground starts at 0
		if can_snap_to_ground(): #If the player can snap to the ground
			snap = 16 #The snap is 16 since the tiles are 16x16
		
		#It checks to see if the current angle is less or equal to a sliding slope
		#If the slope isn't too steep the player can stop on it
		#Otherwise if the slope is too steep they'll slide down it
		var stop_on_slope = check_ground_angle() <= slope_slide_angle
		
		knockback_process() #This moves the player with knockback (More details in function)
		#We move the player with move_and_slide_with_snap
		#With snap means we'll be using grid snapping which pulls the player to the nearest grid point
		#Which helps keep the player on the ground during moments they run fast.
		velocity = move_and_slide_with_snap(velocity, Vector2(0, snap), Vector2(0, -1), stop_on_slope, 10, 1.0) #Moves player
		
		collision_check() #Checks for collisions (More details in function)
		
		#Checks to see if the player dies from an endless fall
		if position.y >= death_fall_height and not state in ["Dead", "Hurt"]:
			set_state("Dead")
		
		state_check() #A final check to make sure the player is in the correct state and sub_state
	animation_process() #Run new animation if needed

#This function processes gravity
func apply_gravity(delta):
	if state in ["WallRun", "Climb"]: #If the player state is either state in the array then leave the function since they don't use gravity
		return
	
	var gravity_mod = 0 #Gravity modifier to add more or remove weight
	
	#Gravity stop is meant to give the player a split second to do a jump if they haven't already.
	if gravity_stop_active and not is_on_floor(): #Checks to see if the player has a grace period from falling
		yield(get_tree().create_timer(0.2), "timeout") #This is how long the gravity is stopped for
		gravity_stop_active = false #Set gravity stop to false
	
	if state == "Fall": #If the player is falling then make gravity pull them down more for weight
		gravity_mod = 300
	
	velocity.y += (gravity + gravity_mod) * delta #Add gravity to velocity

#This function handles adding knockback to the player until it's over
func knockback_process():
	#If the player isn't being knocked back the knockback power is 0, 0 so no harm done by adding it
	velocity += knockback_movement #Add knockback to velocity

#This function processes the animation queue
func animation_process():
	if $CharAnim.has_animation(next_anim): #If the animation player has the animation
		if $CharAnim.current_animation != next_anim: #If it's not currently playing the animation
			$CharAnim.play(next_anim) #Play the next animation

#This function checks for collisions and how to handle them
func collision_check():
	if is_on_floor(): #If the character is on the floor
		gravity_stop_active = true #Gravity stop is active
	
	#Checks for bodies overlapping (colliding) with the HitboxArea
	for collision in $HitboxArea.get_overlapping_bodies():
		if collision.is_in_group("Hazard"): #If the collider is in the Hazard group
			var hazard_knockback_power = Vector2(10 * -direction.x, -20) #We set a hazard knockback for the player that will push them away from the hazard
			collision.take_damage(1, hazard_knockback_power, 0.2) #Hurt the player
	
	#Same as above but with areas. This is reserved for enemies since they'll only have damage Area2Ds
	for collision in $HitboxArea.get_overlapping_areas():
		if collision.is_in_group("Hazard"):
			take_damage(collision.damage, collision.knockback_power, collision.knockback_duration)
	
	#If the player is climbing
	if state == "Climb":
		#If the ladder detection area is colliding with no areas
		if $LadderDetection.get_overlapping_areas().size() == 0:
			set_state("Idle") #Set the state back to Idle because they can't climb without a ladder.

#This function checks for inputs
func control_check():
	#Variable Control shortcuts
	var move_right = Input.is_action_pressed("Right") and can_move()
	var move_left = Input.is_action_pressed("Left") and can_move()
	var jump_start = Input.is_action_just_pressed("Jump") and can_jump()
	var jump = Input.is_action_pressed("Jump") and can_jump()
	var sprint = Input.is_action_pressed("Sprint")
	var climb_up = Input.is_action_pressed("ClimbUp")
	var climb_down = Input.is_action_pressed("ClimbDown")
	var slide = Input.is_action_just_pressed("Slide")
	var crouch = Input.is_action_just_pressed("Slide")
	var wallrun = Input.is_action_pressed("Sprint") and can_wallrun
	var attack = Input.is_action_just_pressed("Attack")
	var backstep = Input.is_action_just_pressed("Backstep")
	#----------------------------------------------------
	
	#If the player is hurt or dead then leave this function since they can't move
	if state in ["Hurt", "Dead", "Backstep"]:
		return
	
	if backstep and can_backstep():
		set_state("Backstep")
		return
	
	#Checks for sprinting
	if sprint:
		if state in ["Run", "Sprint"]: #If the current player state is Run or Sprint
			if stamina_current >= sprint_stamina_cost: #It checks to see if the stamina is above the stamina cost
				set_state("Sprint") #Sets the player state to Sprint
				reduce_stamina(sprint_stamina_cost) #Reduces stamina by the sprint cost
			else: #Otherwise if the player doesn't have enough stamina
				set_state("Run") #Set the state to Run
	#If the player is in the Sprint state but is not sprinting
	if not sprint and state == "Sprint":
		set_state("Run") #Set the state to run
	
	#If the player is wallrunning
	if wallrun:
		if not state in ["Slide", "Climb"]:
			if stamina_current >= wallrun_stamina_cost: #If the stamina is greater or equal to the cost
				set_state("WallRun") #Set the state to Wallrun
				velocity.y = 0 #Vertical velocity is lost
				reduce_stamina(wallrun_stamina_cost) #Reduce the stamina by the wallrun cost
			else: #Otherwise if the player doesn't have enough stamina
				set_state("Idle") #Set their state to Idle
	#If the player is in the Wallrun state but is not wallrunning or can't wallrun anymore
	if state == "WallRun":
		if not wallrun or not can_wallrun:
			set_state("Idle") #Set the state to Idle
	
	#If the player is in the Climb state
	if state == "Climb":
		velocity = Vector2(0, 0) #Set their velocity to 0
	
	#Checks to see if the player is climbing and can climb
	if climb_up and can_climb():
		velocity.y = -climb_speed
	if climb_down and can_climb():
		velocity.y = climb_speed
	
	#Checks to see if the player is and can move right
	if move_right and not state in ["Climb", "Slide"]:
		direction.x = 1 #Sets the horizontal direction to 1 because right is a positive number
	
	#Checks to see if the player is and can move left
	if move_left and not state in ["Climb", "Slide"]:
		direction.x = -1 #Sets the horizontal direction to 1 because right is a negative number
	if not move_right and not move_left and not state in ["Climb"] or state in ["Slide"]:
		if can_move():
			decelerate()
		
		#If the player can quickly stop then quick stop
		if can_quick_stop():
			quick_stop() 
	
	#If the player is actively moving then accelerate the player
	if move_right and not state in ["WallRun", "Climb", "Slide"] or move_left and not state in ["WallRun", "Climb", "Slide"]:
		accelerate()
	
	#Checks to see if the player is and can slide
	if slide and can_slide():
		if state != "Slide": #If the player state isn't Slide set it to Slide
			set_state("Slide")
			velocity.x += 5 * direction.x #Add a little bit of velocity to the player in the direction they're moving
	
	#If the player state is Slide
	if state == "Slide":
		if velocity.x == 0 and head_collision_check(): #If the player's horizontal movement is 0 then they're no longer sliding
			if slide: #If the slide button is still held then the player will crouch
				set_sub_state("Crouch")
			else: #Otherwise they'll go back to standing
				set_sub_state("Default")
			set_state("Idle")
	
	#Checks to see if the player is and can crouch
	if crouch and can_crouch():
		if sub_state != "Crouch": #If the sub state isn't Crouch
			set_sub_state("Crouch") #Set the sub state to Crouch
		elif sub_state == "Crouch":
			set_sub_state("Default")
		set_state("Idle") #Set the state to Idle
	
	if jump_start:
		jump_start()
	#Checks to see if the player is and can jump
	if jump and can_jump() and state == "Jump" and sub_state != "JumpOver":
		jump_movement()
	
	#If the player state is Jump
	if state == "Jump" and sub_state != "JumpOver":
		if not jump or not can_jump(): #If the player isn't jumping or can't jump anymore
			jump_count -= 1 #Reduce jump count by 1
			jump_duration_current = jump_duration_max #Reset jump duration
			if sub_state != "LongJump":
				set_sub_state("JumpOver")
	
	#Checks to see if the player is and can attack
	if attack and can_attack_func():
		queue_attack()
	#If the player sub state is Attack
	if sub_state == "Attack":
		velocity.x = 0 #Set the velocity of X to 0 so that the player isn't moving during an attack
	
	#In some cases the
	if not ignore_speed_max:
		velocity.x = clamp(velocity.x, -speed_max, speed_max) #Limits the player's movement speed to the speed max


#This function handles acceleration
func accelerate():
	if abs(velocity.x) < speed_max: #If the character isn't moving fastr than the speed max
		#If the character is turning then turn
		if velocity.x > 0 and direction.x == -1 or velocity.x < 0 and direction.x == 1:
			turn()
	
	var acceleration_mod = 0 #This modifies the current acceleration as needed
	
	#Match the player state with a case within the indents
	match state:
		"Run":
			#If the ground angle is less than or equal to the slope run angle then add 0.8 to the acceleration
			if check_ground_angle() <= slope_run_angle:
				acceleration_mod = 0.8
		"Sprint":
			#If the ground angle is less than or equal to the slope run angle then add 1 to the acceleration since the player is sprinting up a shallow slope
			if check_ground_angle() <= slope_run_angle:
				acceleration_mod = 1
			#If the ground anlg eis less than or equal tot he slope run angle then add 0.7 to the acceleration
			if check_ground_angle() <= slope_sprint_angle:
				acceleration_mod = 0.7
	
	#Add to the horizontal velocity value
	velocity.x += (acceleration * (acceleration_sensitivity + acceleration_mod)) * direction.x 

#This function handles deceleration
func decelerate():
	#This is so that if the player is under something while sliding they'll keep sliding until they're out
	if state == "Slide" and not head_collision_check():
		if abs(velocity.x) < 50:
			velocity.x += direction.x * 50
		return
	
	#Adds or subtracts the horizontal velocity by deceleration
	if velocity.x > 0:
		velocity.x -= deceleration * deceleration_sensitivity #Deceleration * sensitivity gives the true deceleration
	if velocity.x < 0:
		velocity.x += deceleration * deceleration_sensitivity
	
	#If the character is basically stopped set them to a complete stop or else player will glide slowly
	if abs(velocity.x) <= 8:
		velocity.x = 0

func head_collision_check():
	#If the headcheck has no overlapping bodies then the player passes the head check
	if $HeadCheck.get_overlapping_bodies().size() == 0:
		return true #The player isn't bonking their head
	
	return false #The player will bonk their head

#This function helps the character turn
func turn():
	var default_accel_sens = acceleration_sensitivity #We store the original sensitivty
	acceleration_sensitivity = 2.0 #We bump the acceleration sensitivty past the normal possibilities
	yield(get_tree().create_timer(0.2), "timeout") #We hold the code for a short time
	acceleration_sensitivity = default_accel_sens #Then we set the acceleration sensitivty to the original

func jump_start():
	if state == "Sprint":
		set_sub_state("LongJump")
		jump_count = 0
	else:
		set_sub_state("Default")
	set_state("Jump") #Set the player state to Jump
	velocity.y = -jump_force #Set the vertical velocity to the jump force

#This function handles jumping movement
func jump_movement():
	gravity_stop_active = false #The gravity stop is set to false
	
	velocity.y = -jump_force #Just set the vertical velocity to the jump force
	
	jump_duration_current -= 0.1 #Subtract 0.1 from the current jump duration
	if jump_duration_current <= 0: #If the current jump duration is less than or equal to 0
		jump_count -= 1 #Take a jump from jump count
		jump_duration_current = jump_duration_max #Reset the jump duration
		if sub_state != "LongJump":
			set_sub_state("JumpOver")

#This function handles landing from the air
func landed():
	jump_count = jump_count_max #Set jump count back to max
	jump_duration_current = jump_duration_max #Reset jump duration
	
	#If the sub state is LongJump
	if sub_state == "LongJump":
		ignore_speed_max = false #The player doesn't need to ignore the max speed
	set_sub_state("Default") #Set the sub state back to Default
	set_state("Idle") #Set state back to Idle


#This function queues attacks
func queue_attack():
	#If the player can't attack then leave the function
	if not can_attack:
		return
	
	can_attack = false #The player can't attack now until the game enables attacking. This is just to ensure the player can't overspam attacks and mess up combos while delivering a fluid combo system.
	#ComboDuration is started here and in use attack so the player gets a proper combo duration with some advantage
	$ComboDuration.start() #Start the combo duration
	var final_attack = "Slash1" #The default attack is always Slash1 since there's only a single attack method.
	#If there was a light and heavy the first attack would be have to be sent to the attack function.
	
	combo.append(final_attack) #Add the final attack to the combo
	final_attack = check_combo(final_attack) #Set the final attack to a combo if there's a compatible combo
	if final_attack != "Slash1": #If the player reached a combo
		combo.remove(combo.size()-1) #Remove the last attack
		combo.append(final_attack) #And add the new final attack
	
	#If the player sub_state is Attack (The player is already in an attack)
	if sub_state == "Attack":
		if attack_queue.size() != combo_limit: #If the attack queue size is less than the combo limit
			attack_queue.append(final_attack) #Add the attack to the attack queue
	else: #Otherwise use (commit) the attack
		use_attack(final_attack)
	
	combo_reset() #Check to see if the combo needs to be reset

#Resets the player's attack combo
func combo_reset():
	#If the combo size is at the limit (Max number of attacks per combo)
	if combo.size() == combo_limit:
		combo = [] #Set the combo to an empty array

#This function commits an attack
func use_attack(attack):
	damage = attack_library[attack].Damage #Assign the damage from the attack's damage stat in the attack library
	knockback = attack_library[attack].KnockbackPower * Vector2(sign(direction.x), 1) #Assign the knockback power from the attack's knockback power in the attack library
	knockback_duration = attack_library[attack].KnockbackDuration #Assign the duration of the knockback from the attack's knockback duration in the attack library
	
	set_camera_angle("Combat") #Set the camera angle to the Combat angle
	set_sub_state("Attack") #Set the sub state to Attack
	next_anim = attack #The next animation is the attack name
	
	$ComboDuration.start() #Start the ComboDuration
	yield(get_tree().create_timer(0.2), "timeout") #Wait 0.2 seconds which gives just enough time to allow the game to keep up with inputs and not overwriting moves and messing up combos
	can_attack = true #The player can attack again

#This function checks to see if the player is doing a combo
func check_combo(original_attack):
	for attack in combo_library: #For each combo
		if attack == combo: #If the combo in the library equals the player's current combo
			return combo_library[attack] #Return the combo from the library
	
	return original_attack #Otherwise return the original attack


#This function reduces the stamina
func reduce_stamina(amount):
	stamina_current -= amount #Subtract the amount from current stamina
	stamina_current = clamp(stamina_current, 0, stamina_max) #Clamp the stamina
	
	#This updates the HUD visuals
	update_hud()

#This regenerates stamina
func regen_stamina():
	stamina_current += stamina_regen_amount #Add the regen amount to the current amount of stamina
	stamina_current = clamp(stamina_current, 0, stamina_max) #Clamps the current amount of stamina so it can't go above the max
	
	#Update the visual HUD
	update_hud()

#This function handles healing the character
func heal(amount):
	health_current += amount #Add heal amount to the current health
	health_current = clamp(health_current, 0, health_max) #Clamp the current health so health can't be greater than the max health
	
	#Then we update the hud visuals
	update_hud()


#Changes the camera angle
func set_camera_angle(new_angle):
	var new_zoom = Vector2() #This is the new zoom the camera will have
	var speed = 0.8 #This is how fast the tween is
	
	#Matches the new_angle to a possible angle below
	match new_angle:
		"Normal": #This is the default camera angle
			new_zoom = Vector2(0.45, 0.45)
			speed = 0.8
		"Combat": #This camera is zoomed out a little so the player can see the full combat situation without being flanked
			new_zoom = Vector2(0.40, 0.40)
			speed = 0.5
	
	#The camera is then tweened to the right angle
	$CharCam/CamTween.interpolate_property($CharCam, "zoom", $CharCam.zoom, new_zoom, speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$CharCam/CamTween.start() #Tween is committed

#This function quickly stops the character
#This to help the player so if they're still decelerating they won't slide off edges if they're not pressing the move buttons
func quick_stop():
	velocity.x = 0 #Sets the player velocity.x to 0

#This function handles taking damage
func take_damage(hitDamage, kb_power, kb_duration):
	if $ImmortalTimer.time_left != 0: #If the ImmortalTimer's time left is not 0 then the player is Immortal
		return #Leave the function
	
	health_current -= hitDamage #Subtract damage from health
	
	#Update the visual HUD
	update_hud()
	
	#New knockback system
	knockback_movement = kb_power #Set the knockback movement to the knockback power
	#$KnockbackTimer.wait_time = knockback_duration #Set the Knockback timer duration
	if kb_duration != 0:
		$KnockbackTimer.start(kb_duration) #Start the knockback timer
	
	set_state("Hurt") #Set the state to Hurt
	$HitboxArea/AreaCollider.set_deferred("disabled", true) #Disable the Hitbox Collider. set_deferred is how you properly modify an CollisionShape in code like this

#This function handles attacks that connect
func attack_connected(area):
	#If the parent of the area has the function/method take_damage and the parent of the area isn't the player
	if area.get_parent().has_method("take_damage") and area.get_parent() != self:
		$CamAnim.play("AttackConnected") #Play the camera animation for attack connected
		#This is a camerea shake and not a new angle
		$AttackConnectedParticles.emitting = true #Emit the attack connect particles
		$Sounds/AttackConnectSound.play() #Play the attack connect SFX
		area.get_parent().take_damage(damage, knockback, knockback_duration) #Calls the parent of the area's take_damage function with damage, knockback power; and knockback duration

#This function ends knockback
func end_knockback():
	knockback_movement = Vector2() #Knockback movement is set to 0

#This function handles ending immortality
func end_immortality():
	#The hitbox is turned back on so the player can get hurt
	$HitboxArea/AreaCollider.set_deferred("disabled", false)

#This function handles what happens after an animation finishes
func _on_CharAnim_animation_finished(anim_name):
	match anim_name:
		"Hurt": #If the player hurt animation ended
			set_state("Idle") #Set the state to idle since they're no longer hurting
			set_sub_state("Default") #Set the sub state to Default
			can_attack = true
		
		"FallTransition": #If the player's initial fall animation ended
			next_anim = "Fall" #Play the loop fall animation
		
	if sub_state == "Attack": #If a player attack animation has ended
		if attack_queue.size() > 0: #If the attack queue isn't empty
			use_attack(attack_queue[0]) #Commit the next attack in the queue
			attack_queue.remove(0) #Remove that attack from the queue
		else: #Otherwise just set the sub state to Default
			set_sub_state("Default")


#These check to see if the player has collided or left collision with an interactible body
func interactibleDetected(body):
	match body.name:
		"WallRun": #If the body detected has the name WallRun
			can_wallrun = true #The player can wallrun
func interactibleUndetected(body):
	match body.name:
		"WallRun": #If the body detected has the name WallRun
			can_wallrun = false #The player can't wallrun since these are the wallrun tiles and they're off of the tiles now

#This function handles collecting collectibles
func collect_collectible(area):
	#If the area is not in the collectible group then leave the function
	if not area.is_in_group("Collectible"):
		return
	
	#The idea is that having one object handle collisions is better than a dozen
	
	var type = area.pickup_type #Excessive but makes more slightly easier reading
	match type: #Match the pickup type
		"Coin":
			emit_signal("add_score", area.value) #Emit the signal to add score
	
	area.destroy() #Destroy the area

#This function emits the signals to the HUD to update visuals
func update_hud():
	emit_signal("update_health", health_current, health_max) #Update health visuals in HUD
	emit_signal("update_stamina", stamina_current, stamina_max) #Emit the update stamina signal to update the HUD's stamina bar

func can_move():
	#If the substate is not LongJump
	if sub_state != "LongJump":
		return true #The player can move

#Checks to see if the player can attack
func can_attack_func():
	#If the sub state isn't LongJump
	if sub_state != "LongJump":
		#If the state is not in the array
		if not state in ["Backstep"]:
			#If the player won't bonk their head
			if head_collision_check():
				return true #The player can attack
	
	return false #The player can't attack

#Checks to see if the player can slide
func can_slide():
	if velocity.x != 0: #If velocity.x is not 0, if the player isn't standing still
		if sub_state == "Default": #If the sub state is Default
			if is_on_floor():
				return true #The player can slide
	
	#Otherwise the player can't slide
	return false

#Checks to see if the player can crouch
func can_crouch():
	if velocity.x == 0: #If the player isn't moving
		if state != "Slide": #If the current state isn't in Slide
			return true #The player can crouch
	
	#Otherwise the player can't crouch
	return false

#Checks to see if the player will snap to the ground
func can_snap_to_ground():
	if is_on_floor(): #If the player is on the ground
		if not state in ["Jump", "Fall", "Climb"]: #If the player isn't in these states
			return true #The player will snap to the ground
	
	#Otherwise the player won't snap to the ground
	return false

#Gets the current angle of the ground the player is on
func check_ground_angle():
	var return_angle = 0 #We establish the angle we're returning
	
	for col in get_slide_count(): #For each collision 
		#The get the normal angle of the ground 
		return_angle = rad2deg(acos(get_slide_collision(col).normal.dot(Vector2(0, -1))))
	
	return return_angle #We then return the final angle

#Checks to see if the player can climb
func can_climb():
	if state == "Climb": #If the player state is in Climb
		return true #The player can climb
	
	return false #The player can't climb

#This function handles checking to see if the character can jump
func can_jump():
	if jump_count > 0: #If the jump count is more than 0
		return true #The player can jump
	
	
	return false #The player can't jump

#This function handles checking to see if the character can quick_stop
func can_quick_stop():
	#If the player state is either of these in the array
	if state in ["Idle", "Run", "Sprint"]:
		if not $FallCatcher.is_colliding(): #If the FallCatcher isn't colliding with the ground
			return true #The player can quick stop
	
	#The player can't quick stop
	return false

#Checks to see if the player can backstep
func can_backstep():
	#If the substate is Default
	if sub_state == "Default":
		#If the state is in the array
		if state in ["Run", "Idle"]:
			return true #The player can backstep
	
	return false #The player can't backstep

#Activates the parry mode
func enter_parry_mode(_area):
	#If the player is in the air or not in one of these states in the array then leave the function
	if not is_on_floor() or not state in ["Idle", "Run", "Sprint"]:
		return
	
	Engine.time_scale = 0.6 #Slow the time scale down to make a slow motion effect
	$ParryTimer.start() #Start the parry timer
	$CharCam/EffectAnim.play("Parry_Mode_Toggle") #Play the parry toggle animation

#This function checks to see if the parry should be ended or not before the timer ends
func check_parry_mode():
	yield(get_tree().create_timer(0.05), "timeout") #Wait a short time to give players a little extra time
	if $ParryArea.get_overlapping_areas().size() == 0: #If there's not overlapping areas with the Parry area
		end_parry() #Then end the parry

#This function ends the backstep
func end_backstep():
	set_state("Idle") #Set the state to Idle
	velocity = Vector2(0, 0) #Set velocity to 0, 0

#This function ends the parry
func end_parry():
	Engine.time_scale = 1 #Set the time scale (Turns off slow motion) back to 1
	$CharCam/EffectAnim.play_backwards("Parry_Mode_Toggle") #Play the parry animation backwards


