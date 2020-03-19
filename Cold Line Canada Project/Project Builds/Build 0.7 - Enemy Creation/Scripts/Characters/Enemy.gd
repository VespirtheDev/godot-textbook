extends "res://Scripts/Characters/Character.gd"

signal killed

var target

export (int) var point_value
export (float) var response_time

export (int, "fangs", "rifle", "shotgun", "assault_rifle") var current_weapon
export (PackedScene) var projectile_tscn

var can_attack = true

func state_manager(new_state):
	state = new_state
	match state:
		IDLE:
			pass
		RUN:
			pass
		ATTACK:
			pass
		HURT:
			next_anim = "Hurt"
			$Sounds/Hurt.play()
			$ImmortalDuration.start()
			if health <= 0:
				state_manager(DEAD)
				return
			state_manager(IDLE)
		DEAD:
			next_anim = "Dead"
			$Sounds/Death.play()
			killed()
			animation_update()

func _physics_process(delta):
	if state in [HURT, DEAD]:
		return
	
	if target != null:
		var distance = (target.global_position - global_position).normalized()
		velocity = Vector2(distance.x, distance.y) * move_speed
		look_at(target.global_position)
	
	velocity_check()
	
	animation_update()
	move_and_slide(velocity)

func velocity_check():
	if velocity != Vector2(0,0) and state == IDLE:
		state_manager(RUN)
	if velocity == Vector2(0,0) and state == RUN:
		state_manager(IDLE)

func _on_DetectionRange_body_entered(body):
	if body.is_in_group("Player"):
		target = body

func heal(amount):
	health += amount
	health = clamp(health, 0, health_max)

func take_damage(amount):
	if state in [HURT, DEAD] or $ImmortalDuration.time_left != 0:
		return
	
	health -= amount
	health = clamp(health, 0, health_max)
	
	var percent = health * 100 / health_max
	
	state_manager(HURT)

func shoot():
	if target == null or state in [HURT, DEAD] or not can_attack:
		return
	
	var p = projectile_tscn.instance()
	
	p.damage = WeaponLib[current_weapon].Damage
	p.direction = $Weapon.global_rotation
	$Projectiles.add_child(p)
	p.global_position = $Weapon.global_position
	p.group = "Enemy"
	p.add_to_group("Enemy")
	$Sounds/Attack.play()
	
	$BeforeAttackTimer.wait_time =  WeaponLib[current_weapon].FireRate + response_time

func killed():
	#Drop gun 
	emit_signal("killed")
	queue_free()
	pass

func ready_attack():
	can_attack == true
