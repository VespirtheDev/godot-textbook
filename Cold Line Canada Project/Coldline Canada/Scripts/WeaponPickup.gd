extends Area2D

export (String, "rifle") var weapon = "rifle"
export (Dictionary) var textures = {"unarmed": Texture, "rifle": Texture}

var can_pickup = false
var player
var ammo : int

func _ready():
	update_controls()
	$Sprite.texture = textures[weapon]
	ammo = WeaponLib[weapon].MagazineSize

func update_pickup(_weapon, _ammo):
	weapon = _weapon
	
	$Sprite.texture = textures[_weapon]
	ammo = _ammo

func update_controls():
	if PlayerPref.control_type == "Controller":
		$PopUpUI/PC.hide()
		$PopUpUI/PlayStation.show()
	if PlayerPref.control_type == "Keyboard":
		$PopUpUI/PlayStation.hide()
		$PopUpUI/PC.show()

func _input(event):
	if Input.is_action_just_pressed("Interact"):
		if can_pickup:
			picked_up()

func picked_up():
	var player_weapon = player.get_node("Weapon")
	var _weapon = player_weapon.weapon_name
	var _ammo = player_weapon.ammo
	player_weapon.change_weapon(weapon, ammo)
	
	if _weapon == "unarmed":
		call_deferred("free")
	else:
		update_pickup(_weapon.to_lower(), _ammo)

func _on_WeaponPickup_body_entered(body):
	if body.is_in_group("Player"):
		player = body
		can_pickup = true

func _on_WeaponPickup_body_exited(body):
	if body.is_in_group("Player"):
		can_pickup = false


