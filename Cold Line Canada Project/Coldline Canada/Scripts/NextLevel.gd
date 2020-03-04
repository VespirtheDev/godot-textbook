extends Area2D

signal next_level

func _on_NextLevel_body_entered(body):
	if body.is_in_group("Player"):
		emit_signal("next_level")
