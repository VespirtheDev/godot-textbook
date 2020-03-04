extends Node2D

signal update_score
signal controller_updated

export (PackedScene) var weapon_pickup
export (PackedScene) var jam_pickup

var score = 0

func _ready():
	$Player.health = get_parent().get_parent().player_health
	$Player.max_health = get_parent().get_parent().player_max_health
	if get_parent().get_parent().player_weapons != null:
		$Player.weapon_slots = get_parent().get_parent().player_weapons
	$Player.root = name
	$Player.start()

func add_score(amount, money):
	score += amount
	emit_signal("update_score", score)

func _input(event):
	if event is InputEventMouseButton or event is InputEventKey and PlayerPref.control_type == "Controller":
		PlayerPref.control_type = "Keyboard"
		emit_signal("controller_updated")
	if event is InputEventJoypadMotion or event is InputEventJoypadButton and PlayerPref.control_type == "Keyboard":
		PlayerPref.control_type = "Controller"
		emit_signal("controller_updated")

func spawn_weapon_pickup(weapon_type, spawn_pos):
	var p = weapon_pickup.instance()
	p.weapon = weapon_type
	self.connect("controller_updated", p, "update_controls")
	$WeaponPickups.add_child(p)
	p.global_position = spawn_pos

func spawn_jam_pickup(spawn_pos):
	var p = jam_pickup.instance()
	$JamPickups.add_child(p)
	p.global_position = spawn_pos

func game_over():
	get_parent().get_parent().game_over()

func next_level():
	get_parent().get_parent().player_weapons = $Player.weapon_slots
	get_parent().get_parent().next_level()


