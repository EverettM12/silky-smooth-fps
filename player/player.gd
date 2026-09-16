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

@export_group("Camera")
@export var camera_fov: float = 90.0
@export var sprint_fov: float = 96.0
@export var fov_transition_speed: float = 12.0
@export var head_bob_strength: float = 0.025
@export var head_bob_frequency: float = 10.0
@export var landing_camera_movement: float = 0.08
@export var camera_roll: float = 2.5
@export var slide_camera_behavior: float = 0.15
@export var wall_run_camera_tilt: float = 6.0

@export_group("Cursor")
@export var capture_mouse_on_ready: bool = true

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var player_input: PlayerInput = $PlayerInput
@onready var player_state: PlayerState = $PlayerState
@onready var player_movement: PlayerMovement = $PlayerMovement

var target_pitch: float = 0.0
var smoothed_look_input: Vector2 = Vector2.ZERO
var head_bob_time: float = 0.0
var landing_offset: float = 0.0
var camera_roll_offset: float = 0.0
var previous_grounded: bool = false
var base_head_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	player_movement.player = self
	player_movement.input = player_input
	player_movement.state = player_state
	camera.fov = camera_fov
	camera.current = true
	base_head_position = head.position
	player_movement.current_head_height = base_head_position.y
	previous_grounded = is_on_floor()
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
	process_camera(delta)

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

func process_camera(delta: float) -> void:
	var target_fov: float = camera_fov
	if player_input.sprint_pressed and not player_state.is_sliding():
		target_fov = sprint_fov
	camera.fov = move_toward(camera.fov, target_fov, fov_transition_speed * delta)
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var is_bobbing: bool = is_on_floor() and horizontal_speed > 0.1 and not player_movement.is_dashing
	var target_head_offset: Vector3 = Vector3.ZERO
	if is_bobbing:
		head_bob_time += delta * head_bob_frequency * clamp(horizontal_speed / max(player_movement.sprint_speed, 0.01), 0.0, 2.0)
		target_head_offset.y = sin(head_bob_time * 2.0) * head_bob_strength
		target_head_offset.x = cos(head_bob_time) * head_bob_strength * 0.6
	else:
		head_bob_time = move_toward(head_bob_time, 0.0, delta * head_bob_frequency)
	if not previous_grounded and is_on_floor() and velocity.y < -landing_camera_movement:
		landing_offset = -landing_camera_movement
	landing_offset = move_toward(landing_offset, 0.0, delta * landing_camera_movement * 8.0)
	var target_roll_degrees: float = 0.0
	if player_movement.is_wall_running:
		target_roll_degrees = -player_movement.wall_side * wall_run_camera_tilt
	if player_state.is_sliding():
		target_roll_degrees += player_movement.slide_camera_roll_sign * camera_roll * slide_camera_behavior
	camera_roll_offset = move_toward(camera_roll_offset, target_roll_degrees, delta * 60.0)
	var target_head_position: Vector3 = Vector3(base_head_position.x, player_movement.current_head_height, base_head_position.z)
	target_head_position += target_head_offset + Vector3(0.0, landing_offset, 0.0)
	head.position = head.position.lerp(target_head_position, 1.0 - exp(-12.0 * delta))
	camera.rotation.z = deg_to_rad(camera_roll_offset)
	previous_grounded = is_on_floor()
