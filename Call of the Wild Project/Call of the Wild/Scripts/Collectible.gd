extends Area2D

signal add_health
signal add_stamina
signal add_gold

export (String, "Health", "Stamina", "SilverCoin", "GoldCoin", "DiamondCoin") var type
export (Dictionary) var textures
var value

func setup():
	match type:
		"Health":
			value = 5
			
		"Stamina":
			value = 5
		"SilverCoin":
			value = 1
		"GoldCoin":
			value = 5
		"DiamondCoin":
			value = 10
	
	$Sprite.texture = textures[type]

func collected(body):
	if not body.is_in_group("Player"):
		return
	
	match type:
		"Health":
			emit_signal("add_health", value)
		"Stamina":
			emit_signal("add_stamina", value)
		"SilverCoin":
			emit_signal("add_gold", value)
		"GoldCoin":
			emit_signal("add_gold", value)
		"DiamondCoin":
			emit_signal("add_gold", value)
	
	$Anim.play("Death")
	yield($Anim, "animation_finished")
	call_deferred("free")


