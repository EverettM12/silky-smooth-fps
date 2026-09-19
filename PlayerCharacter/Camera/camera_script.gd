class_name CameraHolder
extends Node3D
## Feeds the player's view camera with weapon recoil and exposes mouse motion for weapon sway.
##
## Look rotation is owned by player.gd. This node never rotates from mouse input, so the
## camera you look through and the camera the guns aim from can no longer drift apart.

@export_group("References")
## The camera the player actually looks through (Player/Head/CameraMotion/Camera3D).
@export var view_camera: Camera3D
## Child node that smooths the recoil kick.
@export var recoil_holder: CameraRecoilHolder

@export_group("Recoil")
## Kick the view camera with the recoil rotation. Turn off to disable visible recoil.
@export var apply_recoil_to_view: bool = true

## Latest mouse delta in pixels, zero while the mouse is still. Read by AnimationManager for weapon sway.
var mouse_input: Vector2 = Vector2.ZERO

var _mouse_moved_this_frame: bool = false


func _ready() -> void:
	# Run before the weapon scripts: they read a fresh mouse_input, and ViewportCam
	# copies the view camera after the recoil has already been applied to it.
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
	# mouse_input is only set by motion events, so clear it on frames without one.
	if not _mouse_moved_this_frame:
		mouse_input = Vector2.ZERO
	_mouse_moved_this_frame = false

	if apply_recoil_to_view:
		view_camera.rotation = recoil_holder.current_rotation
