extends KinematicBody2D

var state = "Run"
var next_anim = ""

export (int) var health_max #Total amount of health the enemy can ever have
onready var health_current = health_max

export (float) var gravity #The force of gravity pulling the character down
export (float) var move_speed #How fast will the character move
export (float) var jump_speed #How high the character can jump
var velocity = Vector2() #How much the character is moving per tick
var facing = -1 #Which direction the character is facing. 1 = Right | -1 = Left

export (float) var idle_time #How long the enemy will idle at the end of a path

export (bool) var can_jump = false #Whether or not the enemy can jump
export (int) var damage = 1 #How much damage the character does

var path = []
var path_index = 0
var path_flow = "Forward"
var direction = 0

var movement_mode = "Path"
var target

var injury_streak = 0

export (float) var backstep_speed

onready var level_root = get_parent().get_parent()

var knockback = Vector2()
export (float) var knockback_duration
export (float) var knockback_power

func _ready():
	for point in $Path.get_children():
		path.append(point.global_position)
	target = level_root.get_node("Player")
	set_state("Move")

#This function sets the character state
func set_state(new_state):
	match new_state: #It uses a match statement to get match the new_state to a case
		"Idle":
			next_anim = "Idle"
		"Move":
			next_anim = "Move"
		"Backstep":
			next_anim = "Backstep"
		"Hurt":
			next_anim = "Hurt"
			$DamageArea/AreaCollider.set_deferred("disabled", true)
			$DamageWarningArea/AreaCollider.set_deferred("disabled", true)
			if health_current <= 0: #Checks to see if the player is dead or not
				set_state("Dead")
				return
		"Dead":
			dead()
	
	state = new_state #At the end I set the state to new_state

#This function handles collisions and correcting states
func state_check():
	if state == "Hurt":
		return
	
	if state == "Jump": #If the state is in Jump
		if is_on_floor(): #If the character is on the floor
			landed()  #Set their state to Idle

#This function handles the animation playing
func animation_process():
	if $CharAnim.has_animation(next_anim): #If the animation player has the animation
		if $CharAnim.current_animation != next_anim: #Checks to see if the next animation is playing yet
			if $CharAnim.current_animation in ["Attack", "Hurt"]:
				yield($CharAnim, "animation_finished")
			$CharAnim.play(next_anim) #Plays the next animation
			next_anim = ""

#This function applies gravity to the character
func apply_gravity(delta):
	var gravity_mod = 0 #Gravity modifier set to 0
	
	#If the character is falling make them fall a little harder
	if state == "Jump" and velocity.y > 0: 
		gravity_mod = 500
	
	#Add gravity to the character's velocity.y
	velocity.y += (gravity + gravity_mod) * delta

func move_on_path():
	if path == [] or path == null:
		return
	
	var length = path[path_index].x - global_position.x
	set_state("Move")
	match path_flow:
		"Forward":
			if length <= 0:
				path_index += 1
				if path_index == path.size():
					finished_path()
					path_index = path.size() - 1
					return
			direction = 1
		"Backward":
			if length >= 0:
				path_index -= 1
				if path_index == -1:
					finished_path()
					path_index = 0
					return
			direction = -1
	
	velocity.x = direction * move_speed

#This function makes the enemy follow the target (Player)
func move_towards_target():
	var distance = target.global_position - global_position
	
	if distance.x > 0: direction = 1
	if distance.x < 0: direction = -1
	
	set_state("Move")
	
	if distance.length() <= 35:
		set_state("Idle")
		velocity.x = 0
		set_state("Idle")
		return
	
	velocity.x = move_speed * direction

#This function makes the enemy follow the target (Player)
func flee_from_target():
	if target == null:
		set_state("Idle")
		return
	
	var distance = target.global_position - global_position
	
	if distance.x < 0: direction = 1
	if distance.x > 0: direction = -1
	
	set_state("Move")
	
	if distance.length() >= 1000:
		set_state("Idle")
		direction = 0
	
	velocity.x = move_speed * direction

#This function handles the result of the enemy finishing their path
func finished_path():
	set_state("Idle")
	match path_flow:
		"Forward":
			path_flow = "Backward"
			return
		"Backward":
			path_flow = "Forward"
			return

#This function makes the character jump
func jump():
	set_state("Jump") #Sets state to Jump
	velocity.y = -jump_speed #Sets the velocity.y value

#This function handles landing from a fall
func landed():
	set_state("Idle") #Set their state to Idle

#This function handles adding knockback to the AI movement
func knockback_process():
	velocity += knockback

#This funciton stops knockback
func end_knockback():
	knockback = Vector2()
	set_state("Idle")
	if target == null:
		movement_mode = "Path"
	else:
		movement_mode = "Follow"

#This function checks to see if there's ground ahead
func check_for_ground():
	#If there's no ground ahead then turn around
	if not $GroundDetection.is_colliding():
		velocity = Vector2()
		match movement_mode:
			"Path":
				finished_path()
			"Follow":
				movement_mode = "Path"

#This function checks for walls ahead
func wall_check():
	#A wall is anything higher up than the character
	if $WallDetection.is_colliding(): #If there's a wall detected
		if can_jump: #If the character can jump then jump
			jump()
		else:
			match movement_mode:
				"Path":
					match path_flow:
						"Forward":
							path_flow = "Backward"
						"Backward":
							path_flow = "Forward"
				"Follow":
					if not can_jump or $JumpHeightDetector.is_colliding:
						movement_mode = "Path"

#This function handles when the character dies
func dead():
	#Play death animation
	#Wait until death animation is over
	call_deferred("free") #Delete the character

#This function handles attacking
func attack():
	velocity = Vector2()
	set_state("Attack")
	$CharAnim.play("Attack")
	yield($CharAnim, "animation_finished")

#This function handles what happens when an attack connects
func attack_connected(area):
	if area.get_parent().has_method("take_damage") and area.get_parent() != self:
		area.get_parent().take_damage(damage, knockback_power * Vector2(sign(direction), 1), knockback_duration)
		set_state("Move")

#This function handles taking damage
func take_damage(dam, kb_power, kb_duration):
	injury_streak += 1
	$InjuryStreakTimer.start()
	
	health_current -= dam
	
	knockback = kb_power
	$KnockbackTimer.wait_time = kb_duration
	$KnockbackTimer.start()
	movement_mode = "Knockback"
	set_state("Hurt")

func reset_injury_streak():
	injury_streak = 0

#This will correct the position of any Areas
func correct_area_position():
	if direction == 1:
		$PositionCorrectionAnim.play("Right")
		$WallDetection.cast_to.x = 35
		$GroundDetection.position.x = 30 #Move the position of the ground detection to the opposite side
	
	if direction == -1:
		$PositionCorrectionAnim.play("Left")
		$WallDetection.cast_to.x = -35
		$GroundDetection.position.x = -30 #Move the position of the ground detection to the opposite side

#This function checks to see if the enemy can attack
func attack_check():
	#Gets overlapping bodies (bodies colliding with AttackRange)
	var collisions = $AttackRange.get_overlapping_bodies()
	
	for col in collisions: #Checks each collision
		if col.is_in_group("Player"): #If the collision is the Player
			set_state("Attack") #Set state to attack
			attack() #And attack
			return true
	
	return false

func player_in_range(body):
	if movement_mode == "Follow":
		return
	
	if body.is_in_group("Player"):
		target = body
		
		movement_mode = "Follow"
		set_state("Move")

func player_out_of_range(body):
	if body.is_in_group("Player"):
		movement_mode = "Path"
		target = null
		set_state("Move")

func end_backstep():
	set_state("Idle")

func _on_CharAnim_animation_finished(anim_name):
	print(anim_name)
	print(state)
	if anim_name == "Hurt":
		set_state("Idle")
		$AttackRange/AreaCollider.disabled = false
	
	if state == "Attack":
		set_state("Move")


