extends Node

func update_controls():
	match System.input_device:
		"Keyboard":
			get_parent().get_node("TutorialPrompts/JumpPrompt/Keyboard").show()
			get_parent().get_node("TutorialPrompts/JumpPrompt/PlayStation").hide()
			get_parent().get_node("TutorialPrompts/JumpPrompt/Xbox").hide()
			get_parent().get_node("TutorialPrompts/SprintPrompt/Keyboard").show()
			get_parent().get_node("TutorialPrompts/SprintPrompt/PlayStation").hide()
			get_parent().get_node("TutorialPrompts/SprintPrompt/Xbox").hide()
		"Controller":
			match System.controller_preference:
				"PlayStation":
					get_parent().get_node("TutorialPrompts/JumpPrompt/Keyboard").hide()
					get_parent().get_node("TutorialPrompts/JumpPrompt/PlayStation").show()
					get_parent().get_node("TutorialPrompts/JumpPrompt/Xbox").hide()
					get_parent().get_node("TutorialPrompts/SprintPrompt/Keyboard").hide()
					get_parent().get_node("TutorialPrompts/SprintPrompt/PlayStation").show()
					get_parent().get_node("TutorialPrompts/SprintPrompt/Xbox").hide()
				"Xbox":
					get_parent().get_node("TutorialPrompts/JumpPrompt/Keyboard").hide()
					get_parent().get_node("TutorialPrompts/JumpPrompt/PlayStation").hide()
					get_parent().get_node("TutorialPrompts/JumpPrompt/Xbox").show()
					get_parent().get_node("TutorialPrompts/SprintPrompt/Keyboard").hide()
					get_parent().get_node("TutorialPrompts/SprintPrompt/PlayStation").hide()
					get_parent().get_node("TutorialPrompts/SprintPrompt/Xbox").show()
