extends Area2D

func _on_JamPickup_body_entered(body):
	if body.is_in_group("Player"):
		if body.health == body.max_health:
			return
		else:
			$PickupSound.play()
			body.heal(1)
			yield($PickupSound, "finished")
			queue_free()
