extends Control

signal playPressed
signal optionspressed
signal quitPressed
var numOptions

func _ready():
	numOptions = $OptionBox.get_child_count() - 1


func _on_PlayButton_pressed():
	emit_signal("playPressed")


func _on_OptionsButton_pressed():
	emit_signal("optionspressed")


func _on_QuitButton_pressed():
	emit_signal("quitPressed")
