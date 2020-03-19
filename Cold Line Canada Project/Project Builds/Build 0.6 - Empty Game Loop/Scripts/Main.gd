extends Node2D

#List of levels in the game must be in order
export (Array, PackedScene) var level_list
var current_level = 0 #The current level the player is on

#This is just for testing to make sure the loop runs without enemies
func _ready():
	yield(get_tree().create_timer(1), "timeout")
	start_game()

#This function starts the game up
func start_game():
	$MainMenu.hide() #Hide the main menu since it's not being used
	load_level() #Load the next level

#This function loads the level up
func load_level():
	#We get the current level and make an instance of it
	var level = level_list[current_level].instance()
	
	#f there's a level loaded in the game
	if $LevelContainer.get_child(0) != null:
		$LevelContainer.get_child(0).queue_free() #Free the level
	#We wait a short time to ensure the level was freed
	yield(get_tree().create_timer(0.2), "timeout")
	
	#Connect the level's finished signal
	level.connect("level_finished", self, "level_finished")
	$LevelContainer.add_child(level) #Add the level to the level container node as a child

#This function ends the game
func level_finished():
	current_level += 1 #The current level is increased
	
	#The level amount has to be reduced by 1 since the level array starts at 0
	var level_amount = level_list.size()-1
	#In case there's only 1 level we clamp the level amount to at least 1
	level_amount = clamp(level_amount, 1, level_list.size())
	
	#If the current level equals the level list size
	if current_level == level_amount:
		
		$LevelContainer.get_child(0).queue_free() #The current level is freed
		game_finished() #The game is finished
	else: #Otherwise load the next level
		load_level()

#This function ends the game
func game_finished():
	current_level = 0 #Set the current level back to 0
	$MainMenu.show() #Show the main menu again


