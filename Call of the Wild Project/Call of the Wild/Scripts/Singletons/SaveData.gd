extends Node

const SAVE_PATH = "user://save.json" #This is the file path

#This is the save dictionary that holds all of the saved info
var save_dict = {
					"Save1": {"CurrentLevel": 0,"LevelName":"Forest of Light"},
					"Save2": {"CurrentLevel": 0,"LevelName":"Forest of Light"},
					"Save3": {"CurrentLevel": 0,"LevelName":"Forest of Light"}
				}

var blank_slot = {"CurrentLevel": 0,"LevelName":"Forest of Light"}

var current_level = 0
var save_slot = 1

#This writes the save file
func save_game():
	var save_file = File.new() #Creates a new file
	
	save_file.open(SAVE_PATH, File.WRITE)
	save_file.store_line(to_json(save_dict))
	save_file.close()

#This loads the save file
func load_game():
	var save_file = File.new()
	
	if not save_file.file_exists(SAVE_PATH):
		return
	
	save_file.open(SAVE_PATH, File.READ)
	
	var data = {}
	data = parse_json(save_file.get_as_text())
	
	save_dict = data
	
	save_file.close()


func delete_save(slot):
	save_dict["Save%s" % str(slot+1)] = blank_slot
	save_game()

