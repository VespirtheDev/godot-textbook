extends Control

signal back

func _ready():
	pass


func _on_ControllerPref_pressed():
	$ControllerOptions.show()
	$AudioOptions.hide()


func _on_Audio_pressed():
	$ControllerOptions.hide()
	$AudioOptions.show()


func _on_Back_pressed():
	$ControllerOptions.hide()
	$AudioOptions.hide()
	emit_signal("back")
