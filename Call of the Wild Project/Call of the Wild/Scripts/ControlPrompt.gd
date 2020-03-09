extends Node2D

func player_detected(body):
	if body.is_in_group("Player"):
		$PromptAnim.play_backwards("Fade")

func player_left(body):
	if body.is_in_group("Player"):
		$PromptAnim.play("Fade")


