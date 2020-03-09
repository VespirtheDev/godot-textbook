extends Node

var input_device
var controller_preference = "PlayStation"

var master_audio_volume = 0.0
var sfx_audio_volume = 0.0
var music_audio_volume = 0.0

var currentCP = 0

func _input(event):
	#If the input was from a mouse
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		input_device = "Mouse" #Set the input to Mouse
	
	if event is InputEventKey: #If the input is a keyboard key
		input_device = "Keyboard" #Set the input to Keyboard
	
	#If the input is from a controller
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		input_device = "Controller" #Set the input to controller


