extends Control

func update_health(current, maximum):
	var percent = (current * 100) / maximum
	$Health/HealthTween.interpolate_property($Health/HealthBar, "value", $Health/HealthBar.value, percent, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Health/HealthTween.start()
	yield($Health/HealthTween, "tween_completed")

func update_score(new_score):
	$Score/ScoreLabel.text = str(new_score)

func update_weapon(weapon, jam_cost, damage):
	if weapon == "Empty":
		return
	$Weapons/WeaponPreview.frame = WeaponLib.weapon_sprite_frames[weapon]
	$Weapons/JamCost.text = "Cost: %s" % jam_cost
	$Weapons/Damage.text = str(damage)

func update_controls():
	if PlayerPref.control_type == "Keyboard":
		$Control/PlayStation.hide()
		$Control/PC.show()
	if PlayerPref.control_type == "Controller":
		$Control/PC.hide()
		$Control/PlayStation.show()

