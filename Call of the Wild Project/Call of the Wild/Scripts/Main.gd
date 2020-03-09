extends Node

var game_state = "Title" #This is the state of the game (Title, playing, etc.)

#This is the current level the player is currently on (Integer)
#The save dict is a Dictionary in the SaveData singleton that holds 3 sets of save slot sub-Dictionaries
#I index into the save dictionaries with a string that uses %s to insert the current save slot
#This gets us to the correct save slot the player is using and then we edit the values
onready var current_lvl = SaveData.save_dict["Save%s" % str(SaveData.save_slot)].CurrentLevel

#This is an array of all the levels in the game
#The first parameter Array establishes what data type is being exported
#The second parameter tells Godot the type of resource we want to be placed in that data type
#In this case we want an array of PackedScenes so we can place our levels in them.
#I prefer a level list because it's something we can directly change and place levels in specific spots
export (Array, PackedScene) var level_list

#Ready is a function that will run as soon as the scene's loaded in
func _ready():
	#On ready we just play an animation to fade in the game
	$TransitionAnim.play_backwards("CompleteFade")

#This function sets the game state
func set_game_state(new_game_state):
	#I match the game state to Fade Out the current interface and such
	match game_state:
		"Title":
			$Title.set_process(false)
			$TransitionAnim.play("Title_Fade")
			fade_audio($Title/TitleMusic)
		"Game":
			$TransitionAnim.play("Game_Fade")
	
	#Then we wait for the animation to finish before continuing
	yield($TransitionAnim, "animation_finished")
	
	#Then I match the new game state to Fade In the new interface and such
	match new_game_state:
		"Title":
			SaveData.set_state("NotPlay") #This sets the SaveData state to Not play so it doesn't record time played
			$TransitionAnim.play_backwards("TitleFade") 
			$Title.set_process(true)
		
		"Game":
			$Title.queue_free() #We destroy the Title scene since we won't need it and will reset the scene when we need to get back to the title
			#Current level gets the current save slot and then gets the CurrentLevel in that save slot
			current_lvl = SaveData.save_dict["Save%s" % str(SaveData.save_slot)].CurrentLevel
			load_level(current_lvl) #Load the current level
	
	#Then we wait for the animation to finish before continuing
	yield($TransitionAnim, "animation_finished")
	
	game_state = new_game_state #Then I set the game state to the new state


#This function loads the next level in
func load_level(level):
	#We get the level scene by indexing into level_list with our current level value level
	var level_tscn = level_list[level].instance() #Then we create an instance of it to add to the scene
	
	$LevelContainer.add_child(level_tscn) #Add the level to the main scene
	$CanvasLayer/Transition/LevelNameLabel.text = $LevelContainer.get_child(0).level_name #Set the level name text
	SaveData.save_dict["Save%s" % SaveData.save_slot].LevelName = $LevelContainer.get_child(0).level_name
	SaveData.save_game()
	$TransitionAnim.play("Fade_In_Level") #Play the fade in level transition animation
	level_tscn.get_node("GameAnim").play("EnterLevel") #We get the level's GameAnim node to play the EnterLevel animation
	
	yield($TransitionAnim, "animation_finished") #Wait for the transition animation to end

#This function handles restarting the level
func restart_level():
	$TransitionAnim.play_backwards("Fade_Out_Level") #Plays the fade out animation for levels
	yield($TransitionAnim, "animation_finished") #We wait for this animation to finish playing
	$LevelContainer.get_child(0).call_deferred("free") #Removes the level from the scene
	load_level(current_lvl) #Load the current level again

#This function handles completing a level
func level_finished():
	#Making a variable for the save slot the player is using just makes the function
	#Look less chaotic (What this is doing is explained in the set_game_state function)
	var save_slot = SaveData.save_dict["Save%s" % SaveData.save_slot]
	System.currentCP = 0 #Set the save's checkpoint to 0 since the level with the checkpoints is finished
	save_slot.CurrentLevel += 1 #Increase current level in save slot to progress the player to the next level
	
	#If the current level is the size of the level_list
	#This means the game is finished since Level 1 reads as Level 0 in the engine since computers start at 0
	if save_slot.CurrentLevel == level_list.size():
		save_slot = SaveData.blank_slot #We wipe the current save slot since the game was finished
		$TransitionAnim.play("CompleteFade") #Play the complete fade animation
		
		#Updates the save information
		SaveData.save_game()
		
		#Wait for the transition animation to finish
		yield($TransitionAnim, "animation_finished")
		get_tree().reload_current_scene() #Reload the scene which effectively restarts the game
		return #Leave this function
	
	#If there's more levels still
	
	$TransitionAnim.play_backwards("Fade_Out_Level") #Play the fade out level animation
	
	yield($TransitionAnim, "animation_finished") #Wait for the animation to finish
	$SaveSound.play() #Play the save sound
	current_lvl = save_slot.CurrentLevel #Update current level in the save slot
	
	SaveData.save_game() #Update and save the game (More details in the function)
	
	load_level(current_lvl) #Loads the current level


#This function fades the target audio 
func fade_audio(target):
	#While the target audio volume is above -50 db reduce it
	while target.volume_db > -50:
		target.volume_db -= 0.01 #Reduce the target db by 0.1
		if target.volume_db <= -50: #If the target db is less than or equal to -50
			target.stop() #Stop the audio
			break #Leave the loop


