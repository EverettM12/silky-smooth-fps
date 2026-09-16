extends Node

func close(message: String) -> void:
	if message.is_empty():
		print("Error, empty message though.")
	
	print_rich("[color=red][b]" + message + "[/b][/color]")
	#await get_tree().process_frame
	get_tree().quit()
