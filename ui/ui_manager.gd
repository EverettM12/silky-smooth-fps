extends Control

@export var cross_hair: Label

func _ready() -> void:
	cross_hair.text = "[]"

func _process(_delta: float) -> void:
	if cross_hair == null:
		return
	cross_hair.position = (size - cross_hair.size) * 0.5
