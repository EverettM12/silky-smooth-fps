class_name CameraHolder
extends Node3D

@export var player: Player

@export_group("References")
var view_camera: Camera3D
@export var recoil_holder: CameraRecoilHolder

@export_group("Recoil")
@export var apply_recoil_to_view: bool = true

var mouse_input: Vector2 = Vector2.ZERO
var _mouse_moved_this_frame: bool = false


func _ready() -> void:
	process_priority = -100
	if player == null:
		set_process(false)
		set_process_unhandled_input(false)
		return
	await player.ready
	configure_player(player)

func configure_player(target_player: Player) -> void:
	player = target_player
	view_camera = player.camera
	if recoil_holder == null:
		recoil_holder = get_node_or_null("CameraRecoilHolder") as CameraRecoilHolder
	if not is_instance_valid(view_camera) or not is_instance_valid(recoil_holder):
		push_error("CameraHolder could not initialize its camera references.")
		set_process(false)
		set_process_unhandled_input(false)
		return
	set_process(true)
	set_process_unhandled_input(true)

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
