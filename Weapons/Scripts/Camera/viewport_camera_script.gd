extends Camera3D

class_name ViewportCamera

@onready var cam : Camera3D = $"../../../Head/CameraMotion/Camera3D"

func _physics_process(_delta: float) -> void:
	global_transform = cam.global_transform
