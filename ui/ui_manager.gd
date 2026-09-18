extends Control

@export var cross_hair: Label
@export var fps: Label

func _process(_delta: float) -> void:
	if cross_hair == null:
		return
	cross_hair.position = (size - cross_hair.size) * 0.5

func _physics_process(_delta: float) -> void:
	fps.text = "FPS: " + str(Engine.get_frames_per_second())
