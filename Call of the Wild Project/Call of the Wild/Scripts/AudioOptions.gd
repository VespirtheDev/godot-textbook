extends Control

func _ready():
	pass

#These functions update the volumes in the Audio Settings
#We set the corresponding audio bus to the volume that's currently being used by the player
#Bus 0 = Master
#Bus 1 = SFX
#Bus 2 = Music
func update_master_volume(amount):
	AudioServer.set_bus_volume_db(0, amount)
	System.master_audio_volume = amount
func update_sfx_volume(amount):
	AudioServer.set_bus_volume_db(1, amount)
	System.sfx_audio_volume = amount
func update_music_volume(amount):
	AudioServer.set_bus_volume_db(2, amount)
	System.music_audio_volume = amount
