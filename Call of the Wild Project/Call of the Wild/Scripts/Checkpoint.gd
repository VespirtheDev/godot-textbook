extends Area2D

signal checkpoint_triggered #This will emit to tell the game when it's been activated

export (int) var checkpoint_order = 0 #This is the order of the checkpoint in the level

#This function handles the checkpoint being triggered
func triggered(body):
	if body.is_in_group("Player"): #If the body is in the Player group
		emit_signal("checkpoint_triggered", checkpoint_order) #Emit the signal with the checkpoint order


