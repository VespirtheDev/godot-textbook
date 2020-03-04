extends Node

export (String, "unarmed", "rifle") var weapon_name = "unarmed"
var shoot_type : String
var target_groups = ["Enemy"]

var damage : int
var reload_rate : float
var fire_rate : float
var bullet_speed : int
var ammo : int
var ammo_loaded_max : int
var ammo_loaded : int
var magazine_size : int
var bullets_per_shot : int

var can_shoot = true

export (PackedScene) var projectile_tscn

func _ready():
	var weapon = WeaponLib[weapon_name]
	weapon_setup(weapon_name, weapon.Damage, weapon.Speed, weapon.ReloadRate, weapon.FireRate, weapon.MagazineSize, weapon.MagazineSize, weapon.AmmoLoad, weapon.BulletsPerShot, weapon.FireType)

func weapon_setup(_name, _damage, _speed, _reload_rate, _fire_rate, _magazine_size, _ammo, _ammo_load, _bullets_per_shot, _shoot_type):
	weapon_name = _name
	damage = _damage
	bullet_speed = _speed
	$ReloadTimer.wait_time = _reload_rate
	$FireRateTimer.wait_time = _fire_rate
	magazine_size = _magazine_size
	ammo = _ammo
	ammo_loaded_max = _ammo_load
	ammo_loaded = ammo_loaded_max
	bullets_per_shot = _bullets_per_shot
	shoot_type = _shoot_type

func shoot(direction):
	if not can_shoot:
		return
	
	can_shoot = false
	
	if ammo_loaded < bullets_per_shot:
		$ReloadTimer.start()
		return
	
	ammo_loaded -= bullets_per_shot
	
	match shoot_type:
		"Single":
			var bullet = projectile_tscn.instance()
			$BulletContainer.add_child(bullet)
			bullet.setup(damage, bullet_speed, direction, target_groups, weapon_name)
			bullet.global_position = get_parent().get_node("BulletSpawnPos").global_position
		"Rapid":
			var bullet = projectile_tscn.instance()
			var recoil = rand_range(-5, 5)
			bullet.setup()
			$BulletContainer.add_child(bullet)
			bullet.global_position = get_parent().get_node("BulletSpawnPos").global_position
		"Spread":
			pass
	
	$FireRateTimer.start()

func reload():
	var ammo_reduction = 0
	
	for bullet in ammo_loaded_max:
		if ammo - 1 > 0:
			ammo_reduction += 1
		if ammo == ammo_loaded_max: break
	
	ammo -= ammo_reduction
	
	ammo_loaded = ammo_reduction
	can_shoot = true

func fire_rate_over():
	can_shoot = true

func change_weapon(_weapon, _ammo):
	var weapon = WeaponLib[_weapon]
	var ammo_load = _ammo - weapon.AmmoLoad
	weapon_setup(weapon.Name, weapon.Damage, weapon.Speed, weapon.ReloadRate, weapon.FireRate, weapon.MagazineSize, _ammo, weapon.AmmoLoad, weapon.BulletsPerShot, weapon.FireType)

