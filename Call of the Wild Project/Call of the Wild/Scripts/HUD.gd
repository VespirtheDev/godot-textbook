extends Control

var menu_option_current = 0 #This is the current option in the menu the player is looking at

var menu_current = "HUD" #This is the current UI being shown

#These are TextureButton textures
export (Texture) var normal_button_tex
export (Texture) var hover_button_tex
export (Texture) var pressed_button_tex

var can_pause = false

func _input(_event):
	#If the Pause input is being pressed
	if not can_pause:
		return
	
	if Input.is_action_just_pressed("Pause"):
		if get_tree().paused == false: #If the game isn't paused
			can_pause = false
			get_tree().paused = true #Pause it
			yield(set_menu("Pause"), "completed") #Set the new menu to Pause
			can_pause = true
			set_process(true)
			return #Leave the function
		
		if get_tree().paused == true: #If the game is paused
			can_pause = false
			get_tree().paused = false #Unpause it
			yield(set_menu("HUD"), "completed") #Set the new menu to HUD
			can_pause = true
			set_process(false)
			return #Leave the function

func _process(_delta):
	#If the game is paused then run the pause control process
	if menu_current == "Pause":
		pause_control_process()

#This function handles the pause menu controls
func pause_control_process():
	var up = Input.is_action_just_pressed("Up")
	var down = Input.is_action_just_pressed("Down")
	var accept = Input.is_action_just_pressed("Accept")
	var menu_option_previous = menu_option_current
	
	
	if up:
		menu_option_current -= 1
	if down:
		menu_option_current += 1
	
	#Makes sure that the option current never goes above the max or below 0
	if menu_option_current > 1: #If the option is above the max which is 1
		menu_option_current = 0 #Then set it to 0
	if menu_option_current < 0: #If the option is below the minimum which is 0
		menu_option_current = 1 #Then set it to 1
	
	if menu_option_current != menu_option_previous:
		update_pause_option()
	
	#If the player uses the accept action then run the select pause option
	if accept:
		select_pause_option()

#This function sets the menu to the new one
func set_menu(new_menu):
	#Match the current menu to fade it out
	#I use tweens to fade out the menus
	match menu_current: 
		"HUD":
			yield(tween_it($HUD, "modulate", $HUD.modulate, Color($HUD.modulate.r, $HUD.modulate.g, $HUD.modulate.b, 0), 0.5), "completed")
		"Pause":
			yield(tween_it($PauseMenu, "modulate", $PauseMenu.modulate, Color($PauseMenu.modulate.r, $PauseMenu.modulate.g, $PauseMenu.modulate.b, 0), 0.5), "completed")
	
	#Match the new menu to fade it in
	match new_menu:
		"HUD":
			yield(tween_it($HUD, "modulate", $HUD.modulate, Color($HUD.modulate.r, $HUD.modulate.g, $HUD.modulate.b, 1), 0.5), "completed")
		"Pause":
			yield(tween_it($PauseMenu, "modulate", $PauseMenu.modulate, Color($PauseMenu.modulate.r, $PauseMenu.modulate.g, $PauseMenu.modulate.b, 1), 0.5), "completed")
	
	menu_current = new_menu #Set the current menu to the new menu

#This function updates the Health bar
func update_health(current, total):
	var percent = (current * 100) / total #Equation to get health percent
	#A tween to procedurally animate the health bar update
	tween_it($HUD/Health/HealthBar, "value", $HUD/Health/HealthBar.value, percent, 0.3)

#This function updates the Stamina bar
func update_stamina(current, total):
	var percent = (current * 100) / total #Equation to get stamina percent
	#A tween to procedurally animate the stamina bar update
	tween_it($HUD/Stamina/StaminaBar, "value", $HUD/Stamina/StaminaBar.value, percent, 0.3)

#This function updates the gold amount
func update_gold(amount):
	$HUD/Gold/GoldLabel.text = str(amount) #str() turns whatever is inside the parantheses into a String data type

#This function handles tweening in this scene
func tween_it(target, property, initial_value, final_value, speed):
	#A tween is setup and started
	$Tween.interpolate_property(target, property, initial_value, final_value, speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	yield($Tween, "tween_completed") #The code is held until the tween is finished

#This function will return the player to the title screen
func return_to_title():
	var anim_player = get_parent().get_parent().get_parent().get_parent().get_node("TransitionAnim")
	anim_player.play("CompleteFade") #Play fade animation
	
	yield(anim_player, "animation_finished") #Wait for animation to end
	get_tree().reload_current_scene() #Reload scene
	get_tree().paused = false #Unpauses the game

#This will update the button visuals for the current menu option
#This is called when a mouse enters a button as well
func update_pause_option():
	
	$Sounds/MenuNavigationSound.play()
	
	#Find which menu option is currently being looked at
	#Change the unselected one to the normal texture
	#And set the selected one to the hover texture
	match menu_option_current:
		0:
			$PauseMenu/ResumeButton.texture_normal = hover_button_tex
			$PauseMenu/QuitButton.texture_normal = normal_button_tex
		1:
			$PauseMenu/ResumeButton.texture_normal = normal_button_tex
			$PauseMenu/QuitButton.texture_normal = hover_button_tex

#This will handle the result of an option being selected
#When a mouse clicks on a button this function is called
func select_pause_option():
	$Sounds/PositiveMenuSound.play()
	match menu_option_current:
		0:
			set_menu("HUD")
		1:
			return_to_title()
			set_process(false)


