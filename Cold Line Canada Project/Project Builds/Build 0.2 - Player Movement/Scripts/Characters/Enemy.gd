extends "res://Scripts/Character.gd"

signal dead
signal spawn_weapon
signal spawn_jam

var target
export (NodePath) var root

export (int) var point_value
export var drop_chances = {"Jam": 0, "Weapon": 0, "SweetPewPew": 0, "ScatterIcer": 0}
export (float) var response_time

var weapons = {"SweetPewPew": {"Damage": 1, "FireRate": 1.5, "JamCost": 1, "ProjectileType": 1, "Ready": true},
			   "ScatterIcer": {"Damage": 5, "FireRate": 3, "JamCost": 2, "ProjectileType": 1, "Ready": true}
			  }
const NUM_TO_WEAPON = {0: "SweetPewPew", 1: "ScatterIcer"}
export (int, "Sweet Pew Pew", "Scatter Icer") var current_weapon

func _ready():
	health = max_health
	take_damage(0)
	self.connect("dead", get_node(root), "add_score")
	self.connect("spawn_jam", get_node(root), "spawn_jam_pickup")
	self.connect("spawn_weapon", get_node(root), "spawn_weapon_pickup")

func state_manager(new_state):
	state = new_state
	match state:
		IDLE:
			next_anim = "Idle"
		RUN:
			if direction in ["up", "down"]:
				next_anim = "Run_Vertical"
			if direction in ["right", "left"]:
				next_anim = "Run_Side"
		ATTACK:
			next_anim = "Attack"
		ROLL:
			velocity = velocity * 2
			next_anim = "Roll"
		HURT:
			next_anim = "Hurt"
			$Sounds/Hurt.play()
			immortal = true
			$ImmortalDuration.start()
			if health <= 0:
				state_manager(DEAD)
				return
			state_manager(IDLE)
		DEAD:
			next_anim = "Dead"
			$Sounds/Death.play()
			drop_generator()
			anim_process()

func _physics_process(delta):
	if state in [HURT, DEAD]:
		return
	
	if target != null:
		var distance = (target.global_position - global_position).normalized()
		velocity = Vector2(distance.x, distance.y) * movespeed
	
		sprite_direction_check()
	velocity_check()
	
	anim_process()
	move_and_slide(velocity * delta)

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
	health = clamp(health, 0, max_health)

func take_damage(amount):
	if state in [HURT, DEAD, ROLL] or immortal:
		return
	health -= amount
	health = clamp(health, 0, max_health)
	
	var percent = health * 100 / max_health
	$HealthLabel.text = str(health)
	
	if percent > 80:
		$HealthLabel.add_color_override("font_color", Color("#a3ff70"))
	elif percent < 75:
		$HealthLabel.add_color_override("font_color", Color("#fff970"))
	elif percent < 45:
		$HealthLabel.add_color_override("font_color", Color("#ffb670"))
	elif percent < 15:
		$HealthLabel.add_color_override("font_color", Color("#ff5a5a"))
	
	state_manager(HURT)

func attack():
	if target == null or state in [HURT, DEAD]:
		return
	var p = projectile.instance()
	
	weapons[NUM_TO_WEAPON[current_weapon]].Ready = false
	p.damage = weapons[NUM_TO_WEAPON[current_weapon]].Damage
	p.projectile_type = weapons[NUM_TO_WEAPON[current_weapon]].ProjectileType
	p.direction = $Weapon.global_rotation
	$Projectiles.add_child(p)
	p.global_position = $Weapon.global_position
	p.group = "Enemy"
	p.add_to_group("Enemy")
	$Sounds/Attack.play()
	
	$BeforeAttackTimer.wait_time = weapons[NUM_TO_WEAPON[current_weapon]].FireRate + response_time

func sprite_direction_check():
	$Weapon.look_at(target.global_position)
	
	#Up angles
	if $Weapon.rotation < -0.7 and $Weapon.rotation > -2.6:
		direction = "up"
	#Down Angles
	if $Weapon.rotation < 1.9 and $Weapon.rotation > 0.5:
		direction = "down"
	#Left Angles
	if $Weapon.rotation < 3.2 and $Weapon.rotation > 1.9:
		direction = "left"
	#Right angles
	if $Weapon.rotation < 0.7 and $Weapon.rotation > -1.5:
		direction = "right"
	
	if direction == "right":
		$BodySprite.flip_h = true
		$FaceSideSprite.flip_h = true
		$FaceBackSprite.hide()
		$FaceSideSprite.show()
		$FaceFrontSprite.hide()
	
	if direction == "left":
		$BodySprite.flip_h = false
		$FaceSideSprite.flip_h = false
		$FaceBackSprite.hide()
		$FaceSideSprite.show()
		$FaceFrontSprite.hide()
	
	if direction == "up":
		$FaceFrontSprite.hide()
		$FaceSideSprite.hide()
		$FaceBackSprite.show()
	
	if direction == "down":
		$FaceBackSprite.hide()
		$FaceSideSprite.hide()
		$FaceFrontSprite.show()

func drop_generator():
	randomize()
	var rand_item = randi()%100
	if rand_item <= drop_chances.Jam:
		emit_signal("spawn_jam", global_position)
	if rand_item <= drop_chances.Weapon:
		randomize()
		var rand_weapon = randi()%100
		var selected_weapon = ""
		if rand_weapon <= drop_chances.SweetPewPew:
			selected_weapon = "SweetPewPew"
		if rand_weapon <= drop_chances.ScatterIcer:
			selected_weapon = "ScatterIcer"
		
		if selected_weapon == "":
			selected_weapon = "SweetPewPew"
		emit_signal("spawn_weapon", selected_weapon, global_position)

func _on_ImmortalDuration_timeout():
	immortal = false

func _on_FaceAnim_animation_finished(anim_name):
	if anim_name == "Dead":
		emit_signal("dead", point_value, randi()%10)
		queue_free()
