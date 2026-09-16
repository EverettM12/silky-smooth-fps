extends Node

func close(message: String = "") -> void:
	if !message.is_empty():
		print(message)
	get_tree().quit()
