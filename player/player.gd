class_name Player
extends CharacterBody3D

@export_group("Look")
@export var mouse_sensitivity: float = 0.0025
@export var controller_sensitivity: float = 2.5
@export var vertical_look_sensitivity: float = 1.0
@export var horizontal_look_sensitivity: float = 1.0
@export var look_smoothing: float = 0.0
@export var minimum_pitch_degrees: float = -89.0
@export var maximum_pitch_degrees: float = 89.0

@export_group("Cursor")
@export var capture_mouse_on_ready: bool = true

@onready var head: Node3D = $Head
@onready var player_input: PlayerInput = $PlayerInput
@onready var player_movement: PlayerMovement = $PlayerMovement

var target_pitch: float = 0.0
var smoothed_look_input: Vector2 = Vector2.ZERO

func _ready() -> void:
	if capture_mouse_on_ready:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player_input.look_input += event.relative
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	process_look(delta)

func process_look(delta: float) -> void:
	var raw_look_input: Vector2 = player_input.look_input
	player_input.look_input = Vector2.ZERO
	var controller_look_input: Vector2 = Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	raw_look_input += controller_look_input * controller_sensitivity
	var look_delta: Vector2 = Vector2(
		raw_look_input.x * mouse_sensitivity * horizontal_look_sensitivity,
		raw_look_input.y * mouse_sensitivity * vertical_look_sensitivity
	)
	if look_smoothing > 0.0:
		smoothed_look_input = smoothed_look_input.lerp(look_delta, 1.0 - exp(-look_smoothing * delta))
	else:
		smoothed_look_input = look_delta
	rotate_y(-smoothed_look_input.x)
	target_pitch = clamp(
		target_pitch - smoothed_look_input.y,
		deg_to_rad(minimum_pitch_degrees),
		deg_to_rad(maximum_pitch_degrees)
	)
	head.rotation.x = target_pitch
