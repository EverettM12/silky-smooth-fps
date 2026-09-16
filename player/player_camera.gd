class_name PlayerCamera
extends Node

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
@export var camera_transition_speed: float = 12.0

@onready var player: Player = get_parent() as Player
@onready var head: Node3D = player.get_node("Head") as Node3D
@onready var camera: Camera3D = player.get_node("Head/Camera3D") as Camera3D
@onready var player_input: PlayerInput = player.get_node("PlayerInput") as PlayerInput
@onready var player_state: PlayerState = player.get_node("PlayerState") as PlayerState
@onready var player_movement: PlayerMovement = player.get_node("PlayerMovement") as PlayerMovement

var head_bob_time: float = 0.0
var landing_offset: float = 0.0
var camera_roll_offset: float = 0.0
var previous_grounded: bool = false
var base_head_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	if player == null or head == null or camera == null or player_input == null or player_state == null or player_movement == null:
		return
	camera.fov = camera_fov
	camera.current = true
	base_head_position = head.position
	previous_grounded = player.is_on_floor()

func _process(delta: float) -> void:
	if player == null or camera == null or head == null or player_movement == null or player_state == null or player_input == null:
		return
	process_camera(delta)

func process_camera(delta: float) -> void:
	var target_fov: float = camera_fov
	if player_input.sprint_pressed and not player_state.is_sliding():
		target_fov = sprint_fov
	camera.fov = move_toward(camera.fov, target_fov, fov_transition_speed * delta)
	var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	var is_bobbing: bool = player.is_on_floor() and horizontal_speed > 0.1 and not player_movement.is_dashing
	var target_head_offset: Vector3 = Vector3.ZERO
	if is_bobbing:
		head_bob_time += delta * head_bob_frequency * clamp(horizontal_speed / max(player_movement.sprint_speed, 0.01), 0.0, 2.0)
		target_head_offset.y = sin(head_bob_time * 2.0) * head_bob_strength
		target_head_offset.x = cos(head_bob_time) * head_bob_strength * 0.6
	else:
		head_bob_time = move_toward(head_bob_time, 0.0, delta * head_bob_frequency)
	if not previous_grounded and player.is_on_floor() and player.velocity.y < -landing_camera_movement:
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
	head.position = head.position.lerp(target_head_position, 1.0 - exp(-camera_transition_speed * delta))
	camera.rotation.z = deg_to_rad(camera_roll_offset)
	previous_grounded = player.is_on_floor()
