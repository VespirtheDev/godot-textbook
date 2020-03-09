extends Area2D

var climb_ready = true #This will tell the ladder when it's ready to be climbed
var player #This will hold the player scene instance

func _ready():
	set_process(false) #The process function is set to inactive by default

func _process(_delta):
	if not climb_ready: #If the ladder cannot be climbed
		enable_triggers() #Enable the body collisions
		player.set_sub_state("Default") #Set the player sub state back to Default
		player.set_state("Idle") #Set the player state to Idle
		return #Leave function
	
	var climb_up = Input.is_action_pressed("ClimbUp")
	var climb_down = Input.is_action_pressed("ClimbDown")
	
	if climb_up or climb_down: #If the player is climbing up or down
		player.set_sub_state("Default") #Set their sub state to Default
		player.set_state("Climb") #Set their state to Climb
	
	if climb_up: #If the player is climbing up the body collisions can be active
		enable_triggers()
	if climb_down: #If the player is climbing down the collisions have be inactive
		disable_triggers()

#This function handles when the player is detected
func player_detected(body):
	if not body.is_in_group("Player"): #If it's not the player then leave the function
		return
	
	player = body #player is assigned to the player body
	set_process(true) #Process is enabled

#This function handles when the player leaves the climb area
func player_left(body):
	if not body.is_in_group("Player"): #If it's not the player then leave the function
		return
	
	body.collision_check() #Force a collision check in the body
	
	set_process(false) #The process function is turned off
	
	enable_triggers() #Body collisions are enabled

#This function turns on body collisions
func enable_triggers():
	$StepBody/TopCollider.set_deferred("disabled", false)
	$StepBody/MiddleCollider.set_deferred("disabled", false)

#This function turns off body collisions
func disable_triggers():
	$StepBody/TopCollider.set_deferred("disabled", true)
	$StepBody/MiddleCollider.set_deferred("disabled", true)


