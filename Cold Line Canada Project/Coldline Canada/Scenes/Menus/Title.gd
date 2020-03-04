extends Node2D

signal start_game

func play():
	emit_signal("start_game")

func quit():
	get_tree().quit()
