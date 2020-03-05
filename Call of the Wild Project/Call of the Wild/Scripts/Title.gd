extends Node

enum {TITLEtoSAVE,TITLEtoOPTIONS,OPTIONStoTITLE,SAVEtoTITLE,QUIT}

var menu_state = "Title" #This is the current menu being used which helps us manage menu flow
var sub_menu = "Title" #This is the current sub menu which helps us organize different sub-menus within a menu (The audio settings inside the Options menu)
var menu_option_current = 0 #This is the current menu option
onready var menu_option_max = $MenuOptions.numOptions #This is the menu option max

onready var root = get_parent() #This is the Main scene which allows us a shortcut to the main scene

var current_time = 0 #This is the current time of the title aesthetic

var can_input = true #This is an on or off switch for allowing inputs. We don't want players mashing a button to select multiple options at once. So we turn this off an on and avoid that.

#This function runs once the scene is initialized
func _ready():
	#update_input_device(true) 
	#SaveData.set_state("NotPlay") #Set the state in saved data to NotPlay
	SaveData.load_game() #Load the game data to update the save dictionary
#This function runs anytime an input is used
#A button press
#A mouse movement
func _input(_event):
	if Input.is_action_just_pressed("Decline"):
		$MenuNegativeSound.play() #Play the negative sound

	if $UIAnim.is_playing():
		yield($UIAnim, "animation_finished")
	set_process(true)

func _process(_delta):
	pass

func setMenu(old_to_new_menu):
	match old_to_new_menu:
		TITLEtoSAVE:
			menu_state = "Save"
			$UIAnim.play("Main_to_Save")
		TITLEtoOPTIONS:
			menu_state = "Options"
			$UIAnim.play("Title_to_Options")
		OPTIONStoTITLE:
			menu_state = "Title"
			$UIAnim.play_backwards("Title_to_Options")
		SAVEtoTITLE:
			menu_state = "Title"
			$UIAnim.play_backwards("Main_to_Save")
		QUIT:
			get_tree().quit()


func playSave(option):
	match option:
		0: #Selected Save 1
			SaveData.save_slot = 1
			SaveData.save_game()
			$UIAnim.play("Complete_Fade")
			yield($UIAnim, "animation_finished")
			root.set_game_state("Game")
		1: #Selected Save 2
			SaveData.save_slot = 2
			SaveData.save_game()
			$UIAnim.play("Complete_Fade")
			yield($UIAnim, "animation_finished")
			root.set_game_state("Game")
		2: #Selected Save 3
			SaveData.save_slot = 3
			SaveData.save_game()
			$UIAnim.play("Complete_Fade")
			yield($UIAnim, "animation_finished")
			root.set_game_state("Game")

#This will advance time a little bit and handle time moving
func advance_time_cycle():
	#When this runs we match our current time to a case below
	match current_time:
		0: #Morning
			#I have a 3 property tween setup
			#The Background will tween the color of the sky and mountains to fit the time of day better
			#Then the tween is started
			#This is the same for the other two cases
			$TimeTween.interpolate_property($Background/SkyBackground, "color", $Background/SkyBackground.color, Color("7c4c2f"), 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TimeTween.interpolate_property($Background/SkyAccent, "color", $Background/SkyAccent.color, Color("70b79147"), 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TimeTween.interpolate_property($Background/Mountains, "modulate", $Background/Mountains.modulate, Color("827455"), 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TimeTween.start()
		1: #Afternoon
			$TimeTween.interpolate_property($Background/SkyBackground, "color", $Background/SkyBackground.color, Color("b6edeb"), 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TimeTween.interpolate_property($Background/SkyAccent, "color", $Background/SkyAccent.color, Color("70eeff77"), 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TimeTween.interpolate_property($Background/Mountains, "modulate", $Background/Mountains.modulate, Color("dcccbc"), 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TimeTween.start()
		2: #Night
			$TimeTween.interpolate_property($Background/SkyBackground, "color", $Background/SkyBackground.color, Color("2f3d70"), 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TimeTween.interpolate_property($Background/SkyAccent, "color", $Background/SkyAccent.color, Color("70000000"), 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TimeTween.interpolate_property($Background/Mountains, "modulate", $Background/Mountains.modulate, Color("43454e"), 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$TimeTween.start()
	
	#Then we increase the current time by 1
	current_time += 1
	
	#If the current time is more than 2 then a new day begins and we reset the current time to 0
	if current_time > 2:
		current_time = 0

