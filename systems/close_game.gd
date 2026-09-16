extends Node

func close(message:String):
	push_error(message)
	await get_tree().process_frame
	get_tree().quit()
