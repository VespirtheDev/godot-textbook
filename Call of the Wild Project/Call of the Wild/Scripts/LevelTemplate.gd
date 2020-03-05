extends Node2D

export (String) var level_name = "" #The name of the level to be displayed
onready var root = get_parent().get_parent() #The Main tscn
var level_finished = false #Tracks to see if the level has been finished
var player_dead = false #Tracks to see if the player is dead or not. Mainly used so the game doesn't spam the dead function

func _ready():
	if self.has_node("ControlManager"):
		$ControlManager.update_controls()
	
	SaveData.save_dict["Save%s" % SaveData.save_slot].LevelName = level_name #Set the current level's name in the save slot
	$Player.setup() #Setup the player scene
#	$Player.global_position = $Checkpoints.get_child(SaveData.save_dict["Save%s" % SaveData.save_slot].Checkpoint).global_position #Move the player to the spawn position
	$Player.set_physics_process(false) #Stop the player from moving
	$GameAnim.play("EnterLevel")
	
	#For each checkpoint in the level
	$Checkpoints/SpawnPoint/PlayerGuideSprite.hide()
	for checkpoint in $Checkpoints.get_children():
		if checkpoint.has_method("triggered"): #Make sure it's a checkpoint
			checkpoint.connect("checkpoint_triggered", self, "checkpoint_triggered") #Connect the triggered signal to this script
			checkpoint.get_node("PlayerGuideSprite").hide()
	
	setup_camera_limits() #Sets the camera limits for all directions
	yield($GameAnim, "animation_finished")
	$Interface/HUD.can_pause = true
	$Player.set_physics_process(true) #Let the player move

#This function will run anytime input is used
func _input(_event):
	#If the control manager is a valid instance update the controls it has.
	if self.has_node("ControlManager"):
		$ControlManager.update_controls()

#This will setup the camera limits automatically
func setup_camera_limits():
	$Player/CharCam.limit_left = $LeftCamRestraint.global_position.x
	$Player/CharCam.limit_right = $RightCamRestraint.global_position.x
	$Player/CharCam.limit_bottom = $Player.death_fall_height
	$Player/CharCam.limit_top = $SkyCamRestraint.global_position.y

#This function will handle when the level is completed
func level_completed():
	if level_finished == true:
		return
	
	level_finished = true
	$Player.set_state("Idle")
	$Player/CharAnim.play("Idle")
	$Player.set_physics_process(false)
	$GameAnim.play_backwards("EnterLevel")
	root.level_finished() #The level finished is called from the root
	yield(get_tree().create_timer(1.8), "timeout")
	self.queue_free()

#This handles the end goal being entered
func end_goal_entered(body):
	if body.is_in_group("Player"): #If the player entered it
		level_completed() #Then the level is completed

#This function handles when the player dies
func player_died():
	#If the play is dead then leave the function
	if player_dead == true:
		return
	player_dead = true #The player is now dead.
	
	$GameAnim.play("Death") #Play the Death animation
	
	#If the death music isn't playing then play it
	$DeathMusic.play()
	#Wait a few seconds for the player to experience death
	yield(get_tree().create_timer(4), "timeout")
	
	root.restart_level() #The level restart function is called from the root node

#This function updates the checkpoint once it's triggered
func checkpoint_triggered(order):
	#If the order is greater than the current checkpoint then set it to the new checkpoint order
	if order > SaveData.save_dict["Save%s" % SaveData.save_slot].Checkpoint:
		SaveData.save_dict["Save%s" % SaveData.save_slot].Checkpoint = order


