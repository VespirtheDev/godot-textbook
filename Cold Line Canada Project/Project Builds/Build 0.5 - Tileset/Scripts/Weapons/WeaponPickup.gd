extends Area2D

export (bool) var random_weapon = false

#This is the weapon name with some presets I added
export (String, "rifle", "assault_rifle", "shotgun") var weapon_name = "rifle"

#These are the weapon textures
export (Dictionary) var textures = {"unarmed": Texture, "rifle": Texture, "assault_rifle": Texture, "shotgun": Texture}

var ammo : int #This is how much ammo is on the pickup
var can_pickup = false

var player

export (Dictionary) var weapon_list = {"Rifle": {"Name": "rifle", "Active": true}, 
									   "AssaultRifle": {"Name": "assault_rifle", "Active": true},
									   "Shotgun": {"Name": "shotgun", "Active": true},
									  }
var possible_weapons = []

#This function
func _ready():
	if random_weapon: #If the weapon is supposed to be random it runs the randomize weapon function
		yield(randomize_weapon(), "completed")
	
	update_pickup(weapon_name, WeaponLib[weapon_name].AmmoReserve)

#This function randomizes the weapon
func randomize_weapon():
	print("Randomize Weapon")
	#This for loop adds the possible weapons selected for this pickup and adds them into a possible array
	for weapon in weapon_list:
		print(weapon)
		if weapon_list[weapon].Active:
			possible_weapons.append(weapon_list[weapon].Name)
			break
	
	var rand_num = randi()%possible_weapons.size()-1 #Get a random number for the weapons
	weapon_name = possible_weapons[rand_num] 
	print(weapon_name)
	
	yield(get_tree().create_timer(0.1), "timeout")

#This function updates the weapon pickup sprite and info
func update_pickup(_weapon_name, _ammo):
	weapon_name = _weapon_name #Set the weapon name to the new weapon name
	ammo = _ammo
	
	$Sprite.texture = textures[_weapon_name]

#This function handles input checks for the pickup
func _input(event):
	if Input.is_action_just_pressed("Interact"): #If the input is in the Interact action
		if can_pickup: #If the pickup can be picked up
			picked_up() #Pick it up

#This function handles picking up weapons
func picked_up():
	var player_weapon = player.get_node("Weapon")
	var _weapon = player_weapon.weapon_name
	var _ammo = player_weapon.ammo_reserve_max
	player_weapon.change_weapon(weapon_name, ammo)
	
	if _weapon == "unarmed":
		call_deferred("free")
		print("Player was unarmed")
	else:
		print("Exchange weapons")
		update_pickup(_weapon, ammo)

#These two functions handle whether the weapon can be picked up or not
func _on_WeaponPickup_body_entered(body):
	if body.is_in_group("Player"):
		player = body
		can_pickup = true

func _on_WeaponPickup_body_exited(body):
	if body.is_in_group("Player"):
		can_pickup = false


