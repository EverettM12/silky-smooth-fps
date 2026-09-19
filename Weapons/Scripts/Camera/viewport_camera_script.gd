extends Camera3D

class_name ViewportCamera

@onready var cam : Camera3D = $"../../../Player/Head/CameraMotion/Camera3D"

func _process(_delta: float) -> void:
	global_transform = cam.global_transform
