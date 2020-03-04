extends "res://Scripts/Character.gd"

signal update_health
signal update_score
signal update_ammo
signal player_dead

var player_id = 0

var current_weapon

var root

func start():
	take_damage(0, false)

func state_manager(new_state):
	state = new_state
	match state:
		IDLE:
			$StepSoundTimer.stop()
			next_anim = "Idle"
		RUN:
			if $StepSoundTimer.time_left == 0:
				$StepSoundTimer.start()
			if direction in ["up", "down"]:
				next_anim = "Run_Vertical"
			if direction in ["right", "left"]:
				next_anim = "Run_Horizontal"
		ATTACK:
			$StepSoundTimer.stop()
			$Sounds/Attack.play()
			next_anim = "Attack"
		ROLL:
			#$Sounds/Roll.play()
			$StepSoundTimer.stop()
			velocity = velocity * 2
			next_anim = "Roll"
		HURT:
			$StepSoundTimer.stop()
			next_anim = "Hurt"
			immortal = true
			$ImmortalDuration.start()
			if health <= 0:
				state_manager(DEAD)
			else:
				state_manager(IDLE)
		DEAD:
			$StepSoundTimer.stop()
			next_anim = "Dead"
			anim_process()

func _physics_process(delta):
	if state == DEAD:
		return
	
	if !state in [HURT, DEAD]:
		control_process()
		anim_process()
	
	velocity = move_and_slide(velocity * delta).normalized()
	
	state_check()

func _input(event):
	if event is InputEventMouseButton:
		PlayerPref.control_type == "Keyboard"
	if event is InputEventMouseMotion:
		PlayerPref.control_type == "Keyboard"

func control_process():
	var move_up = Input.is_action_pressed("Up")
	var move_down = Input.is_action_pressed("Down")
	var move_right = Input.is_action_pressed("Right")
	var move_left = Input.is_action_pressed("Left")
	var attack = Input.is_action_pressed("Attack")
	#--------------------------------------------------
	
	velocity = Vector2()
	
	if move_right:
		velocity.x += movespeed
	if move_left:
		velocity.x -= movespeed
	if move_up:
		velocity.y -= movespeed
	if move_down:
		velocity.y += movespeed
	
	rotate_player()
	
	if attack:
		$Weapon.shoot(rotation)

func rotate_player():
	var look_direction
	match PlayerPref.control_type:
		"Keyboard":
			look_direction = get_local_mouse_position()
			rotation += look_direction.angle()
		"Controller":
			look_direction.y = Input.GetJoyAxis(player_id, 3);
			look_direction.x = Input.GetJoyAxis(player_id, 2);
			rotation = look_direction.Angle();

#This function corrects the player's state
#To ensure the player is always in the correct state
func state_check():
	if state == IDLE:
		if velocity != Vector2(0, 0):
			state_manager(RUN)
	
	if state == RUN:
		if velocity == Vector2(0, 0):
			state_manager(IDLE)

func heal(amount):
	health += amount
	health = clamp(health, 0, max_health)
	emit_signal("update_jam", health, max_health)
	take_damage(0, false)

func take_damage(amount, sound=true):
	if state in [HURT, DEAD]:
		return
	health -= amount
	health = clamp(health, 0, max_health)
	
	if sound:
		$Sounds/Hurt.play()
	
	get_parent().get_parent().get_parent().player_health = health
	emit_signal("update_health", health, max_health)
	
	state_manager(HURT)

func _on_StepSoundTimer_timeout():
	$Sounds/Run.play()


