class_name CameraHolder
extends Node3D

@export_group("References")
var view_camera: Camera3D
@export var recoil_holder: CameraRecoilHolder

@export_group("Recoil")
@export var apply_recoil_to_view: bool = true

var mouse_input: Vector2 = Vector2.ZERO
var _mouse_moved_this_frame: bool = false


func _ready() -> void:
	view_camera = $"../Player".get_node("Head/CameraMotion/Camera3D")
	process_priority = -100
	if not is_instance_valid(view_camera) or not is_instance_valid(recoil_holder):
		push_error("CameraHolder: assign 'View Camera' and 'Recoil Holder' in the Inspector.")
		set_process(false)
		set_process_unhandled_input(false)

func _unhandled_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	mouse_input = motion.relative
	_mouse_moved_this_frame = true

func _process(_delta: float) -> void:
	if not _mouse_moved_this_frame:
		mouse_input = Vector2.ZERO
	_mouse_moved_this_frame = false

	if apply_recoil_to_view:
		view_camera.rotation = recoil_holder.current_rotation
