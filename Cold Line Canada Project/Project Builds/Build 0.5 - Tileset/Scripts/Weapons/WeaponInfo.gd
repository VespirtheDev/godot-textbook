extends Node

export (bool) var camera_shake_enabled = false #This turns cam shake on or off
#Cam shake should only be on for the player

onready var parent = get_parent() #This is the parent of the weapon
onready var cam = parent.get_node("Camera") #This is the player's camera
onready var cam_default_pos = cam.position #This is the player's camera default position

#This is the name of the weapon with some presets I added
export (String, "unarmed", "rifle", "assault_rifle", "shotgun") var weapon_name = "unarmed"
var target_groups = ["Enemy"] #This is the group label the bullets can hit

var damage : int #How much damage each bullet deals
var reload_rate : float #How long a reload takes
var fire_rate : float #How long the player has to wait between shots to shoot again
var bullet_speed : int #How fast the bullet moves

var ammo_reserve_max : int #How much reserve ammo the player can carry
var ammo_reserve : int #How much ammo the player has in reserve
var ammo_loaded_max : int #How much ammo the player can have loaded at one time
var ammo_loaded : int #How much ammo the player does have loaded
var ammo_cost : int #How much ammo each shot costs

var can_shoot = true #This tells the weapon if the player can shoot or not

export (PackedScene) var projectile_tscn #This is the projectile TSCN used for all weapons

#Variables End
#-------------

func _ready():
	var weapon = WeaponLib[weapon_name]
	weapon_setup(weapon_name, weapon.Damage, weapon.Speed, weapon.ReloadRate, weapon.FireRate, weapon.AmmoReserve, weapon.AmmoReserve, weapon.AmmoLoad, weapon.AmmoCost)

#This function sets up the weapon's stats
func weapon_setup(_name, _damage, _speed, _reload_rate, _fire_rate, _ammo_reserve_max, _ammo_reserveo, _ammo_load, _ammo_cost):
	weapon_name = _name
	damage = _damage
	bullet_speed = _speed
	$ReloadTimer.wait_time = _reload_rate
	$FireRateTimer.wait_time = _fire_rate
	ammo_reserve_max = _ammo_reserve_max
	ammo_reserve = _ammo_reserveo
	ammo_loaded_max = _ammo_load
	ammo_loaded = ammo_loaded_max
	ammo_cost = _ammo_cost
	
	can_shoot = true

#This function handles shooting
func shoot(direction):
	if not can_shoot: #If the weapon isn't ready to shoot then leave function
		return
	
	can_shoot = false #The weapon now cannot shoot
	
	#If the ammo loaded can't cover the ammo cost
	if ammo_loaded < ammo_cost:
		$ReloadTimer.start() #Start reloading
		return #Leave function since there's nothing more to do
		#Since can_shoot is already set to false the player can't enter to this point until they've reloaded
		#So we don't need a if reload timer is running check
	
	#Otherwise if the ammo loaded can cover the ammo cost
	ammo_loaded -= ammo_cost #Reduce ammo loaded by the ammo cost
	
	#Match the shoot type to the respective shoot type case
	#I use BulletContainer to hold the bullets because it's self contained inside of the weapon controller tscn
	#Plain Nodes don't hold any transform properties so it ignores the character's transform properties
	
	var spread = WeaponLib[weapon_name].Spread #This is the weapon's spread stat
	var recoil_intensity = WeaponLib[weapon_name].RecoilIntensity #This is the weapon's recoil intensity stat
	var spread_amount = 0 #This is how much spread the next bullet will have
	
	#If the spread of the gun is more than 0 then set the spread amount ot -spread to achieve a full spread shot
	if spread > 0: spread_amount = -spread
	
	if camera_shake_enabled:
		cam_shake(WeaponLib[weapon_name].CamShakeStrength)
	#Each ammo cost is another shot that goes out
	for shot in ammo_cost:
		var bullet = projectile_tscn.instance() #Get an instance of the bullet ready
		var recoil = rand_range(-recoil_intensity, recoil_intensity) #Get a random recoil within this range
		
		bullet.setup(damage, bullet_speed, direction, target_groups, weapon_name) #Setup the bullet
		$BulletContainer.add_child(bullet) #Add the bullet as a child of BulletContainer
		#Set the bullet's position with recoil and spread added
		bullet.global_position = get_parent().get_node("BulletSpawnPos").global_position + Vector2(0, recoil + spread_amount).rotated(get_parent().rotation)
		
		spread_amount += spread #Increase spread size to keep the bullets spreading
	
	$FireRateTimer.start() #Start the fire rate timer

#This function handles reloading
func reload():
	var ammo_to_reload = 0 #This is the total amount of ammo to be reloaded
	
	#This for loop ensures the player is only taking ammo from their reserve to reload
	#And are not getting extra ammo
	for bullet in ammo_loaded_max:
		if ammo_reserve - 1 > 0: #If the player has more ammo
			ammo_to_reload += 1 #Add one more bullet to reload
		
		#If the weapon is fully loaded or the weapon's ammo runs dry it breaks the for loop
		if ammo_reserve == ammo_loaded_max: break
		if ammo_reserve - 1 <= 0: break
	
	ammo_reserve -= ammo_to_reload #Take reloaded ammo out of the reserves
	ammo_loaded = ammo_to_reload #Set the ammo loaded to the ammo put to reload
	
	can_shoot = true #The player can shoot again

#This handles the end of a fire rate wait
func fire_rate_over():
	can_shoot = true #The player can shoot this weapon again

#This handles picking up new weapons
func change_weapon(_weapon, _ammo):
	can_shoot = false
	
	var weapon = WeaponLib[_weapon] #This is a little cleaner and faster way of getting the weapon in the WeaponLib singleton
	
	#Then the weapon is setup with the weapon's stats from the weapon library singleton
	weapon_setup(weapon.Name, weapon.Damage, weapon.Speed, weapon.ReloadRate, weapon.FireRate, weapon.AmmoReserve, _ammo, weapon.AmmoLoad, weapon.AmmoCost)

#This function handles the camera shake effect
#This is meant to give guns an extra OOMPH feel
func cam_shake(strength):
	#I take a 1 and rotate to the negative of the player's rotation
	#This gives the opposite direction of where the player is shooting to
	var shake_dir = Vector2(0, 1).rotated(-parent.rotation)
	
	#This tween moves the camera away from the original position
	$CamShakeTween.interpolate_property(cam, "position", cam.position, cam.position + (Vector2(strength, 0) * shake_dir), 0.1, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
	$CamShakeTween.start()
	yield($CamShakeTween, "tween_completed")
	
	#This tween moves the camera to the original position
	$CamShakeTween.interpolate_property(cam, "position", cam.position, cam_default_pos, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
	$CamShakeTween.start()
	yield($CamShakeTween, "tween_completed")


