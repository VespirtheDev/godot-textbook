extends Control

signal confirm
signal cancel
func _ready():
	pass


func _on_Confirm_pressed():
	emit_signal("confirm")


func _on_Cancel_pressed():
	emit_signal("cancel")
