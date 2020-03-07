extends Node2D

var player_health = 10
var player_max_health = 10
export (Array, PackedScene) var level_list

var current_level = 0
var menu_selection = 0
var player_weapons

onready var menu_selections = [$Title/VBoxContainer/PlayButton/Position, $Title/VBoxContainer/ShopButton/Position2, $Title/VBoxContainer/QuitButton/Position4]

var playing_game = false

func _process(delta):
	if Input.is_action_just_pressed("menu_select_up") and !playing_game:
		$Sounds/MenuCursor.play()
		menu_selection -= 1
	if Input.is_action_just_pressed("menu_select_down") and !playing_game:
		$Sounds/MenuCursor.play()
		menu_selection += 1

func start_game():
	$Sounds/TitleMusic.stop()
	playing_game = true
	$Title.hide()
	$Levels.show()
	player_health = player_max_health
	player_weapons = null
	next_level()

func next_level():
	if $Levels.get_child_count() > 0:
		$Level.get_child(0).call_deferred("free")
	
	var new_level = level_list[current_level].instance()
	$TransitionAnim.play("next_level")
	$Sounds/NewLevel.play()
	yield($TransitionAnim, "animation_finished")
	if $Levels.get_child_count() > 0:
		$Levels.get_child(0).queue_free()
	$Levels.add_child(new_level)
	current_level += 0

func game_over():
	#$Sounds/Game_Over.play()
	$Levels.get_child(0).queue_free()
	$Levels.hide()
	$Title.show()
	playing_game = false
	$Sounds/TitleMusic.play()

func quit():
	get_tree().quit()


