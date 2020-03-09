extends Control

var saveForDeletion = 0
signal playSave
signal back

func _ready():
	SaveData.load_game()
	updateSaves()

func deletionConfirmed():
	if saveForDeletion != 0:
		$DeleteAnimation.play_backwards("DeleteMenu")
		SaveData.delete_save(saveForDeletion-1)
		updateSaves()
		saveForDeletion = 0

func deletionCanceled():
	$DeleteAnimation.play_backwards("DeleteMenu")
	saveForDeletion = 0

func startDelete(slot):
	saveForDeletion = slot
	$DeleteAnimation.play("DeleteMenu")

func saveSelect(slot):
	emit_signal("playSave", slot)

func updateSaves():
	$SaveOptions/SaveBox/Slot1/Slot1_Info/LevelNameLabel.text = str(SaveData.save_dict.Save1.LevelName)
	#$SaveSelect/Slot1_Info/TimeLabel.text = str(SaveData.save_dict.Save1.PlayTime)
	
	$SaveOptions/SaveBox/Slot2/Slot2_Info/LevelNameLabel.text = str(SaveData.save_dict.Save2.LevelName)
	#$SaveSelect/Slot2_Info/TimeLabel.text = str(SaveData.save_dict.Save2.PlayTime)
	
	$SaveOptions/SaveBox/Slot3/Slot3_Info/LevelNameLabel.text = str(SaveData.save_dict.Save3.LevelName)
	#$SaveSelect/Slot3_Info/TimeLabel.text = str(SaveData.save_dict.Save3.PlayTime)


func _on_Back_pressed():
	emit_signal("back")
