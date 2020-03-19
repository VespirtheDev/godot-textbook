extends Node2D

signal level_finished

func _ready():
	yield(get_tree().create_timer(1), "timeout")
	enemy_killed()

#This function will be called when an enemy is killed
#And it checks to see if all enemies have been killed
func enemy_killed():
	yield(get_tree().create_timer(0.2), "timeout") #Wait a short time to ensure the enemy was freed
	if $Enemies.get_child_count() == 0: #Check the enemy container node to see how many enemies are left
		
		emit_signal("level_finished") #Emit the level finished signal


