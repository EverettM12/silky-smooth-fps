class_name PlayerCamera
extends Node

@export_group("Turning")
@export_range(0.0, 10.0, 0.01) var turn_tilt_amount: float = 2.25
@export_range(0.0, 30.0, 0.1) var turn_tilt_response: float = 13.0
@export_range(0.0, 30.0, 0.1) var turn_tilt_return_speed: float = 16.0
@export_range(0.0, 100.0, 0.1) var turn_tilt_acceleration: float = 22.0
@export_range(0.0, 100.0, 0.1) var turn_tilt_velocity_influence: float = 0.75
@export_range(0.0, 10.0, 0.01) var maximum_turn_tilt: float = 3.0
@export_range(0.1, 20.0, 0.1) var turn_reference_speed: float = 7.0

@export_group("Strafe Tilt")
@export_range(0.0, 10.0, 0.01) var strafe_tilt_amount: float = 1.35
@export_range(0.0, 30.0, 0.1) var strafe_response_speed: float = 11.0
@export_range(0.0, 30.0, 0.1) var strafe_return_speed: float = 14.0
@export_range(0.0, 2.0, 0.01) var strafe_velocity_influence: float = 0.9

@export_group("Movement Sway")
@export_range(0.0, 0.1, 0.001) var movement_sway_amount: float = 0.012
@export_range(0.0, 20.0, 0.1) var movement_sway_speed: float = 8.0
@export_range(0.0, 30.0, 0.1) var movement_sway_response: float = 10.0
@export_range(0.0, 30.0, 0.1) var movement_sway_return_speed: float = 13.0
@export_range(0.0, 2.0, 0.01) var movement_sway_speed_multiplier: float = 1.0

@export_group("Head Bob")
@export_range(0.0, 20.0, 0.1) var bob_frequency: float = 1.9
@export_range(0.0, 0.1, 0.001) var bob_amplitude: float = 0.045
@export_range(0.0, 2.0, 0.01) var bob_horizontal_amplitude: float = 0.55
@export_range(0.0, 2.0, 0.01) var bob_vertical_amplitude: float = 0.75
@export_range(0.0, 5.0, 0.01) var bob_roll_amplitude: float = 1.1
@export_range(0.0, 5.0, 0.01) var bob_pitch_amplitude: float = 1.35
@export_range(0.0, 2.0, 0.01) var walking_intensity: float = 0.55
@export_range(0.0, 2.0, 0.01) var sprinting_intensity: float = 1.0
@export_range(0.0, 2.0, 0.01) var crouching_intensity: float = 0.35
@export_range(0.0, 10.0, 0.01) var minimum_bob_speed: float = 0.2
@export_range(0.0, 30.0, 0.1) var bob_acceleration_response: float = 9.0
@export_range(0.0, 30.0, 0.1) var bob_fade_in_speed: float = 9.0
@export_range(0.0, 30.0, 0.1) var bob_fade_out_speed: float = 12.0
@export_range(0.0, 2.0, 0.01) var bob_backward_multiplier: float = 0.9

@export_group("Crouching")
@export_range(0.0, 3.0, 0.01) var standing_camera_height: float = 1.65
@export_range(0.0, 3.0, 0.01) var crouching_camera_height: float = 0.95
@export_range(0.0, 30.0, 0.1) var crouch_transition_speed: float = 12.0
@export_range(0.0, 30.0, 0.1) var crouch_transition_response: float = 17.0
@export_range(-10.0, 10.0, 0.1) var crouch_camera_tilt: float = 0.0
@export_range(0.0, 2.0, 0.01) var crouch_movement_sway_multiplier: float = 0.8
@export_range(0.0, 2.0, 0.01) var crouch_bob_multiplier: float = 0.45
@export_range(0.0, 2.0, 0.01) var crouching_bob_multiplier: float = 0.45

@export_group("Sliding")
@export_range(0.0, 3.0, 0.01) var slide_camera_height: float = 0.82
@export_range(0.0, 30.0, 0.1) var slide_transition_speed: float = 18.0
@export_range(-15.0, 15.0, 0.1) var slide_tilt: float = -4.0
@export_range(-15.0, 15.0, 0.1) var slide_roll: float = 3.0
@export_range(0.0, 30.0, 0.1) var slide_fov_increase: float = 3.0
@export_range(0.0, 2.0, 0.01) var slide_motion_intensity: float = 1.0
@export_range(0.0, 2.0, 0.01) var slide_sway: float = 1.2
@export_range(0.0, 30.0, 0.1) var slide_return_speed: float = 16.0

@export_group("Acceleration")
@export_range(0.0, 10.0, 0.01) var acceleration_tilt: float = 0.8
@export_range(0.0, 0.1, 0.001) var acceleration_positional_offset: float = 0.018
@export_range(0.0, 0.1, 0.001) var deceleration_offset: float = 0.022
@export_range(0.0, 5.0, 0.01) var direction_change_tilt: float = 1.25
@export_range(0.0, 30.0, 0.1) var acceleration_response_speed: float = 11.0
@export_range(0.0, 30.0, 0.1) var acceleration_return_speed: float = 16.0
@export_range(0.0, 100.0, 0.1) var maximum_acceleration_effect: float = 55.0
@export_range(0.1, 100.0, 0.1) var acceleration_reference: float = 35.0

@export_group("Landing")
@export_range(0.0, 0.2, 0.001) var landing_displacement: float = 0.055
@export_range(0.0, 10.0, 0.01) var landing_tilt: float = 2.3
@export_range(0.0, 1.0, 0.01) var landing_duration: float = 0.12
@export_range(0.0, 30.0, 0.1) var landing_recovery_speed: float = 18.0
@export_range(0.0, 30.0, 0.1) var landing_velocity_threshold: float = 4.0
@export_range(0.0, 4.0, 0.01) var landing_intensity_multiplier: float = 0.8
@export_range(0.0, 4.0, 0.01) var maximum_landing_effect: float = 2.0

@export_group("Jumping")
@export_range(0.0, 0.2, 0.001) var jump_camera_impulse: float = 0.018
@export_range(0.0, 1.0, 0.01) var jump_camera_duration: float = 0.12
@export_range(-10.0, 10.0, 0.1) var fall_camera_behavior: float = -0.45
@export_range(0.0, 2.0, 0.01) var airborne_sway: float = 0.35
@export_range(0.0, 2.0, 0.01) var airborne_bob_multiplier: float = 0.0

@export_group("Aiming")
@export_range(45.0, 90.0, 0.1) var aim_fov: float = 65.0
@export_range(0.0, 30.0, 0.1) var aim_fov_transition_speed: float = 18.0
@export_range(0.0, 30.0, 0.1) var aim_fov_return_speed: float = 14.0

@export_group("FOV")
@export_range(45.0, 150.0, 0.1) var base_fov: float = 90.0
@export_range(0.0, 30.0, 0.1) var maximum_movement_fov: float = 4.0
@export_range(0.0, 30.0, 0.1) var sprint_fov_increase: float = 3.5
@export_range(0.0, 40.0, 0.1) var dash_fov_increase: float = 8.0
@export_range(0.0, 30.0, 0.1) var wall_run_fov: float = 2.0
@export_range(0.0, 30.0, 0.1) var fov_transition_speed: float = 12.0
@export_range(0.0, 30.0, 0.1) var fov_return_speed: float = 15.0
@export_range(0.0, 3.0, 0.01) var fov_speed_multiplier: float = 1.0
@export_range(45.0, 170.0, 0.1) var maximum_final_fov: float = 110.0

@export_group("Wall Running")
@export_range(0.0, 15.0, 0.1) var wall_run_tilt: float = 3.0
@export_range(0.0, 15.0, 0.1) var wall_run_roll: float = 4.5
@export_range(0.0, 2.0, 0.01) var wall_run_sway: float = 0.7
@export_range(0.0, 30.0, 0.1) var wall_run_transition_speed: float = 10.0
@export_range(0.0, 10.0, 0.1) var wall_jump_camera_response: float = 2.0

@export_group("Dashing")
@export_range(0.0, 0.2, 0.001) var dash_directional_offset: float = 0.035
@export_range(0.0, 15.0, 0.1) var dash_tilt: float = 1.4
@export_range(0.0, 30.0, 0.1) var dash_transition_speed: float = 24.0
@export_range(0.0, 30.0, 0.1) var dash_return_speed: float = 20.0
@export_range(0.0, 2.0, 0.01) var dash_motion_intensity: float = 1.0

@export_group("Smoothing")
@export_range(1.0, 40.0, 0.1) var position_spring_frequency: float = 15.0
@export_range(1.0, 40.0, 0.1) var rotation_spring_frequency: float = 18.0
@export_range(1.0, 40.0, 0.1) var fov_spring_frequency: float = 12.0
@export_range(0.0, 1.0, 0.01) var minimum_spring_distance: float = 0.0001
@export_range(0.0, 1.0, 0.01) var minimum_spring_velocity: float = 0.0001

@export_group("Limits")
@export_range(0.0, 20.0, 0.1) var maximum_camera_roll: float = 5.0
@export_range(0.0, 20.0, 0.1) var maximum_camera_pitch: float = 8.0
@export_range(0.0, 1.0, 0.01) var maximum_position_offset: float = 0.18
@export_range(0.0, 170.0, 0.1) var minimum_fov: float = 45.0
@export_range(45.0, 170.0, 0.1) var maximum_fov: float = 120.0

@onready var player: Player = get_parent() as Player
@onready var head: Node3D = player.get_node("Head") as Node3D
@onready var camera_motion: Node3D = player.get_node("Head/CameraMotion") as Node3D
@onready var camera: Camera3D = player.get_node("Head/CameraMotion/Camera3D") as Camera3D
@onready var player_input: PlayerInput = player.get_node("PlayerInput") as PlayerInput
@onready var player_state: PlayerState = player.get_node("PlayerState") as PlayerState
@onready var player_movement: PlayerMovement = player.get_node("PlayerMovement") as PlayerMovement

var weapon_viewport_camera: Camera3D

var base_head_position: Vector3 = Vector3.ZERO
var previous_player_yaw: float = 0.0
var previous_velocity: Vector3 = Vector3.ZERO
var acceleration_velocity: Vector3 = Vector3.ZERO
var bob_phase: float = 0.0
var bob_motion_intensity: float = 0.0
var bob_weight: float = 0.0
var movement_sway_offset: Vector3 = Vector3.ZERO
var head_bob_offset: Vector3 = Vector3.ZERO
var acceleration_offset: Vector3 = Vector3.ZERO
var turn_tilt_current: float = 0.0
var strafe_tilt_current: float = 0.0
var airborne_fall_velocity: float = 0.0
var landing_timer: float = 0.0
var landing_amount: float = 0.0
var jump_timer: float = 0.0
var jump_amount: float = 0.0
var dash_was_active: bool = false
var slide_weight: float = 0.0
var wall_run_weight: float = 0.0
var dash_weight: float = 0.0
var camera_position_value: Vector3 = Vector3.ZERO
var camera_position_velocity: Vector3 = Vector3.ZERO
var camera_rotation_value: Vector3 = Vector3.ZERO
var camera_rotation_velocity: Vector3 = Vector3.ZERO
var fov_value: float = 90.0
var fov_velocity: float = 0.0

func _ready() -> void:
	if player == null or head == null or camera_motion == null or camera == null or player_input == null or player_state == null or player_movement == null:
		return
	base_head_position = head.position
	previous_player_yaw = player.rotation.y
	previous_velocity = player.velocity
	camera_position_value = Vector3.ZERO
	camera_rotation_value = Vector3.ZERO
	fov_value = clamp(base_fov, minimum_fov, min(maximum_fov, maximum_final_fov))
	camera.fov = fov_value
	camera.current = true

func _process(delta: float) -> void:
	if player == null or head == null or camera_motion == null or camera == null or player_input == null or player_state == null or player_movement == null:
		return
	var safe_delta: float = max(delta, 0.000001)
	var movement_data: Dictionary = calculate_movement_data(safe_delta)
	update_motion_state(safe_delta, movement_data)
	update_head_bob(safe_delta, movement_data)
	update_movement_sway(safe_delta, movement_data)
	update_directional_rotation(safe_delta, movement_data)
	update_impulses(safe_delta, movement_data)
	apply_camera_motion(safe_delta, movement_data)
	previous_velocity = player.velocity
	previous_player_yaw = player.rotation.y
	dash_was_active = player_movement.is_dashing
	if weapon_viewport_camera != null:
		weapon_viewport_camera.global_transform = camera.global_transform

func calculate_movement_data(delta: float) -> Dictionary:
	var horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var movement_speed: float = horizontal_velocity.length()
	var maximum_movement_speed: float = max(player_movement.sprint_speed, player_movement.walk_speed)
	var speed_ratio: float = clamp(movement_speed / max(maximum_movement_speed, 0.001), 0.0, 1.5)
	var player_basis: Basis = player.global_transform.basis
	var local_velocity: Vector3 = player_basis.inverse() * player.velocity
	var local_acceleration: Vector3 = player_basis.inverse() * ((player.velocity - previous_velocity) / delta)
	acceleration_velocity = acceleration_velocity.lerp(local_acceleration, 1.0 - exp(-acceleration_response_speed * delta))
	var turn_velocity: float = angle_difference(previous_player_yaw, player.rotation.y) / delta
	var lateral_velocity_ratio: float = clamp(local_velocity.x / max(maximum_movement_speed, 0.001), -1.0, 1.0)
	var forward_velocity_ratio: float = clamp(-local_velocity.z / max(maximum_movement_speed, 0.001), -1.0, 1.0)
	return {
		"movement_speed": movement_speed,
		"speed_ratio": speed_ratio,
		"local_velocity": local_velocity,
		"local_acceleration": acceleration_velocity,
		"acceleration_magnitude": min(acceleration_velocity.length(), maximum_acceleration_effect),
		"turn_velocity": turn_velocity,
		"lateral_velocity_ratio": lateral_velocity_ratio,
		"forward_velocity_ratio": forward_velocity_ratio,
		"maximum_movement_speed": maximum_movement_speed
	}

func update_motion_state(delta: float, movement_data: Dictionary) -> void:
	var slide_target_weight: float = 0.0
	if player_state.is_sliding():
		slide_target_weight = 1.0
	var wall_run_target_weight: float = 0.0
	if player_state.is_wall_running():
		wall_run_target_weight = 1.0
	var dash_target_weight: float = 0.0
	if player_movement.is_dashing:
		dash_target_weight = 1.0
	var slide_weight_speed: float = slide_return_speed
	if slide_target_weight > slide_weight:
		slide_weight_speed = slide_transition_speed
	slide_weight = move_toward(slide_weight, slide_target_weight, slide_weight_speed * delta)
	wall_run_weight = move_toward(wall_run_weight, wall_run_target_weight, wall_run_transition_speed * delta)
	var dash_weight_speed: float = dash_return_speed
	if dash_target_weight > dash_weight:
		dash_weight_speed = dash_transition_speed
	dash_weight = move_toward(dash_weight, dash_target_weight, dash_weight_speed * delta)
	var grounded: bool = player_state.is_grounded()
	var crouched: bool = player_state.is_sliding() or player_input.crouch_pressed
	var bob_target: float = 0.0
	if grounded and movement_data["movement_speed"] > minimum_bob_speed:
		bob_target = 1.0
	elif player_state.is_airborne() and airborne_bob_multiplier > 0.0:
		bob_target = airborne_bob_multiplier
	var bob_response: float = bob_fade_out_speed
	if bob_target > bob_weight:
		bob_response = bob_fade_in_speed
	bob_weight = move_toward(bob_weight, bob_target, bob_response * delta)
	var target_head_height: float = standing_camera_height
	if player_state.is_sliding():
		target_head_height = slide_camera_height
	elif crouched:
		target_head_height = crouching_camera_height
	var target_head_position: Vector3 = Vector3(base_head_position.x, target_head_height, base_head_position.z)
	var head_response: float = max(crouch_transition_response, crouch_transition_speed)
	if player_state.is_sliding():
		head_response = slide_transition_speed
	head.position = head.position.lerp(target_head_position, 1.0 - exp(-head_response * delta))
	if grounded:
		if player_state.previous_state == PlayerState.MovementState.AIRBORNE:
			if abs(airborne_fall_velocity) >= landing_velocity_threshold:
				trigger_landing(abs(airborne_fall_velocity))
			airborne_fall_velocity = 0.0
	else:
		airborne_fall_velocity = min(airborne_fall_velocity, player.velocity.y)
	if player_state.previous_state == PlayerState.MovementState.GROUNDED and player_state.is_airborne():
		jump_timer = jump_camera_duration
		jump_amount = jump_camera_impulse
	jump_timer = max(jump_timer - delta, 0.0)
	landing_timer = max(landing_timer - delta, 0.0)

func update_head_bob(delta: float, movement_data: Dictionary) -> void:
	var intensity: float = walking_intensity
	if player_input.sprint_pressed and not player_state.is_sliding():
		intensity = sprinting_intensity
	if player_state.is_sliding() or player_input.crouch_pressed:
		intensity *= crouching_intensity * crouching_bob_multiplier
	if player_state.is_airborne():
		intensity *= airborne_bob_multiplier
	var speed_ratio: float = movement_data["speed_ratio"]
	var backward_scale: float = 1.0
	if movement_data["forward_velocity_ratio"] < 0.0:
		backward_scale = bob_backward_multiplier
	var target_intensity: float = bob_weight * intensity * clamp(speed_ratio, 0.0, 1.0) * backward_scale
	bob_motion_intensity = move_toward(bob_motion_intensity, target_intensity, bob_acceleration_response * delta)
	target_intensity = bob_motion_intensity
	if target_intensity > 0.0:
		var phase_speed: float = bob_frequency * TAU * (0.65 + speed_ratio * 0.75)
		bob_phase = fmod(bob_phase + phase_speed * delta, TAU)
	else:
		bob_phase = fmod(bob_phase + bob_frequency * TAU * 0.25 * delta, TAU)
	var speed_sculpt: float = smoothstep(0.0, 1.0, clamp(speed_ratio, 0.0, 1.0))
	var horizontal_motion: float = cos(bob_phase) * bob_amplitude * bob_horizontal_amplitude * speed_sculpt * target_intensity
	var vertical_motion: float = sin(bob_phase * 2.0) * bob_amplitude * bob_vertical_amplitude * speed_sculpt * target_intensity
	head_bob_offset.x = horizontal_motion
	head_bob_offset.y = vertical_motion

func update_movement_sway(delta: float, movement_data: Dictionary) -> void:
	var local_velocity: Vector3 = movement_data["local_velocity"]
	var speed_ratio: float = movement_data["speed_ratio"]
	var sway_speed_ratio: float = clamp(movement_data["movement_speed"] / max(movement_sway_speed, 0.001), 0.0, 1.0)
	var sway_multiplier: float = movement_sway_speed_multiplier
	if player_state.is_sliding():
		sway_multiplier *= slide_sway
	elif player_input.crouch_pressed:
		sway_multiplier *= crouch_movement_sway_multiplier
	if player_state.is_wall_running():
		sway_multiplier *= wall_run_sway
	if player_state.is_airborne():
		sway_multiplier *= airborne_sway
	var target_sway: Vector3 = Vector3(
		-local_velocity.x * movement_sway_amount * sway_multiplier,
		0.0,
		-local_velocity.z * movement_sway_amount * 0.35 * sway_multiplier
	) * clamp(speed_ratio, 0.0, 1.5) * sway_speed_ratio
	var sway_response: float = movement_sway_response
	if target_sway.length_squared() < 0.000001:
		sway_response = movement_sway_return_speed
	movement_sway_offset = movement_sway_offset.lerp(target_sway, 1.0 - exp(-sway_response * delta))

func update_directional_rotation(delta: float, movement_data: Dictionary) -> void:
	var turn_velocity: float = movement_data["turn_velocity"]
	var normalized_turn_velocity: float = clamp(turn_velocity / max(turn_reference_speed, 0.001), -1.0, 1.0)
	var turn_target: float = -normalized_turn_velocity * turn_tilt_amount * turn_tilt_velocity_influence
	turn_target = clamp(turn_target, -maximum_turn_tilt, maximum_turn_tilt)
	var turn_response: float = turn_tilt_response + min(abs(turn_velocity), turn_tilt_acceleration)
	if abs(turn_velocity) < 0.1:
		turn_response = turn_tilt_return_speed
	turn_tilt_current = move_toward(turn_tilt_current, turn_target, turn_response * delta)
	var lateral_ratio: float = movement_data["lateral_velocity_ratio"]
	var strafe_target: float = lateral_ratio * strafe_tilt_amount * strafe_velocity_influence
	var strafe_response: float = strafe_response_speed
	if abs(lateral_ratio) < 0.01:
		strafe_response = strafe_return_speed
	strafe_tilt_current = move_toward(strafe_tilt_current, strafe_target, strafe_response * delta)

func update_impulses(delta: float, movement_data: Dictionary) -> void:
	acceleration_offset = acceleration_offset.lerp(Vector3.ZERO, 1.0 - exp(-acceleration_return_speed * delta))
	if landing_timer > 0.0:
		landing_amount = move_toward(landing_amount, 0.0, landing_recovery_speed * delta)
	else:
		landing_amount = move_toward(landing_amount, 0.0, landing_recovery_speed * delta * 0.75)
	if jump_timer > 0.0:
		jump_amount = move_toward(jump_amount, 0.0, jump_camera_impulse / max(jump_camera_duration, 0.001) * delta)
	else:
		jump_amount = move_toward(jump_amount, 0.0, jump_camera_impulse * 10.0 * delta)
	if movement_data["acceleration_magnitude"] > 0.1:
		var acceleration_ratio: float = clamp(movement_data["acceleration_magnitude"] / max(acceleration_reference, 0.001), 0.0, 1.0)
		var local_acceleration: Vector3 = movement_data["local_acceleration"]
		acceleration_offset += Vector3(
			-local_acceleration.x * deceleration_offset * acceleration_ratio * delta,
			-local_acceleration.y * acceleration_positional_offset * acceleration_ratio * delta,
			local_acceleration.z * acceleration_positional_offset * acceleration_ratio * delta
		)

func trigger_landing(vertical_speed: float) -> void:
	var impact_speed: float = max(vertical_speed, landing_velocity_threshold)
	var landing_ratio: float = clamp((impact_speed - landing_velocity_threshold) / max(landing_velocity_threshold * 2.0, 0.001), 0.0, 1.0)
	landing_amount = min(
		landing_displacement * (1.0 + landing_ratio * landing_intensity_multiplier),
		landing_displacement * maximum_landing_effect
	)
	landing_timer = landing_duration
	airborne_fall_velocity = 0.0

func apply_camera_motion(delta: float, movement_data: Dictionary) -> void:
	var speed_ratio: float = movement_data["speed_ratio"]
	var local_velocity: Vector3 = movement_data["local_velocity"]
	var local_acceleration: Vector3 = movement_data["local_acceleration"]
	var position_target: Vector3 = movement_sway_offset + head_bob_offset + acceleration_offset
	position_target.y += -landing_amount + jump_amount
	var acceleration_ratio: float = clamp(movement_data["acceleration_magnitude"] / max(acceleration_reference, 0.001), 0.0, 1.0)
	position_target += Vector3(
		-local_acceleration.x * acceleration_positional_offset * acceleration_ratio,
		-local_acceleration.y * acceleration_positional_offset * acceleration_ratio,
		local_acceleration.z * acceleration_positional_offset * acceleration_ratio
	)
	if slide_weight > 0.0:
		position_target *= slide_motion_intensity * slide_weight + (1.0 - slide_weight)
	var dash_direction: Vector3 = player_movement.dash_direction
	if dash_weight > 0.0 and dash_direction.length_squared() > 0.001:
		var local_dash_direction: Vector3 = player.global_transform.basis.inverse() * dash_direction
		position_target += Vector3(-local_dash_direction.x, -local_dash_direction.y, local_dash_direction.z) * dash_directional_offset * dash_motion_intensity * dash_weight
	var position_limit: float = maximum_position_offset
	position_target = position_target.clamp(Vector3(-position_limit, -position_limit, -position_limit), Vector3(position_limit, position_limit, position_limit))
	var position_spring: Dictionary = critical_damp_vector3(camera_position_value, camera_position_velocity, position_target, position_spring_frequency, delta)
	camera_position_value = position_spring["value"]
	camera_position_velocity = position_spring["velocity"]
	var target_pitch: float = 0.0
	var target_roll: float = turn_tilt_current + strafe_tilt_current
	target_pitch += cos(bob_phase * 2.0) * bob_pitch_amplitude * bob_weight * speed_ratio
	target_roll += sin(bob_phase) * bob_roll_amplitude * bob_weight * speed_ratio
	target_pitch += crouch_camera_tilt * (1.0 - slide_weight)
	if player_state.is_airborne():
		target_pitch += clamp(player.velocity.y / max(player_movement.maximum_fall_speed, 0.001), -1.0, 0.0) * fall_camera_behavior
	if landing_timer > 0.0:
		var landing_rotation_ratio: float = clamp(landing_amount / max(landing_displacement, 0.001), 0.0, maximum_landing_effect)
		target_pitch -= landing_rotation_ratio * landing_tilt
	if slide_weight > 0.0:
		target_pitch += slide_tilt * slide_motion_intensity * slide_weight
		target_roll += slide_roll * player_movement.slide_camera_roll_sign * slide_motion_intensity * slide_weight
	if wall_run_weight > 0.0:
		target_pitch += wall_run_tilt * player_movement.wall_side * wall_run_weight
		target_roll += wall_run_roll * player_movement.wall_side * wall_run_weight
	if dash_weight > 0.0:
		var dash_roll_direction: float = 1.0
		if abs(local_velocity.x) > 0.01:
			dash_roll_direction = sign(local_velocity.x)
		target_roll += dash_tilt * dash_roll_direction * dash_motion_intensity * dash_weight
	target_pitch += clamp(-local_acceleration.z / max(acceleration_reference, 0.001), -1.0, 1.0) * acceleration_tilt
	if acceleration_ratio > 0.0 and local_acceleration.length() > acceleration_reference * 0.5:
		var direction_change_ratio: float = 0.0
		if local_velocity.length_squared() > 0.001:
			direction_change_ratio = clamp((1.0 - local_velocity.normalized().dot(local_acceleration.normalized())) * 0.5, 0.0, 1.0)
		var direction_change_sign: float = 1.0
		if abs(local_acceleration.x) > 0.01:
			direction_change_sign = sign(local_acceleration.x)
		target_roll += direction_change_ratio * direction_change_tilt * direction_change_sign
	if player_movement.is_dashing and not dash_was_active:
		target_pitch -= dash_tilt * 0.5
	if player_state.previous_state == PlayerState.MovementState.WALL_RUNNING and player_state.is_airborne():
		target_roll += wall_jump_camera_response * -player_movement.wall_side
	target_pitch = clamp(target_pitch, -maximum_camera_pitch, maximum_camera_pitch)
	target_roll = clamp(target_roll, -maximum_camera_roll, maximum_camera_roll)
	var rotation_target: Vector3 = Vector3(deg_to_rad(target_pitch), 0.0, deg_to_rad(target_roll))
	var rotation_spring: Dictionary = critical_damp_vector3(camera_rotation_value, camera_rotation_velocity, rotation_target, rotation_spring_frequency, delta)
	camera_rotation_value = rotation_spring["value"]
	camera_rotation_velocity = rotation_spring["velocity"]
	var movement_fov_ratio: float = clamp(speed_ratio * fov_speed_multiplier, 0.0, 1.0)
	var target_fov: float = base_fov + movement_fov_ratio * maximum_movement_fov
	if player_input.sprint_pressed and not player_state.is_sliding():
		target_fov += sprint_fov_increase
	target_fov += slide_fov_increase * slide_weight
	target_fov += dash_fov_increase * dash_weight
	target_fov += wall_run_fov * wall_run_weight
	target_fov = clamp(target_fov, minimum_fov, min(maximum_fov, maximum_final_fov))
	if player_input.aim_pressed:
		target_fov = min(target_fov, aim_fov)
	var fov_response_speed: float = fov_return_speed
	if player_input.aim_pressed and target_fov < fov_value:
		fov_response_speed = aim_fov_transition_speed
	elif target_fov > fov_value:
		fov_response_speed = fov_transition_speed
	elif target_fov < fov_value:
		fov_response_speed = aim_fov_return_speed
	fov_response_speed = max(fov_response_speed, fov_spring_frequency)
	var fov_spring: Dictionary = critical_damp_scalar(fov_value, fov_velocity, target_fov, fov_response_speed, delta)
	fov_value = fov_spring["value"]
	fov_velocity = fov_spring["velocity"]
	camera_motion.position = camera_position_value
	camera_motion.rotation = camera_rotation_value
	camera.fov = fov_value

func critical_damp_scalar(current_value: float, current_velocity: float, target_value: float, frequency: float, delta: float) -> Dictionary:
	var angular_frequency: float = max(frequency, 0.001)
	var offset: float = current_value - target_value
	var exponential_decay: float = exp(-angular_frequency * delta)
	var temporary_value: float = (current_velocity + angular_frequency * offset) * delta
	var new_offset: float = (offset + temporary_value) * exponential_decay
	var new_velocity: float = (current_velocity - angular_frequency * temporary_value) * exponential_decay
	var new_value: float = target_value + new_offset
	if abs(new_value - target_value) < minimum_spring_distance and abs(new_velocity) < minimum_spring_velocity:
		new_value = target_value
		new_velocity = 0.0
	return {
		"value": new_value,
		"velocity": new_velocity
	}

func critical_damp_vector3(current_value: Vector3, current_velocity: Vector3, target_value: Vector3, frequency: float, delta: float) -> Dictionary:
	var angular_frequency: float = max(frequency, 0.001)
	var offset: Vector3 = current_value - target_value
	var exponential_decay: float = exp(-angular_frequency * delta)
	var temporary_value: Vector3 = (current_velocity + offset * angular_frequency) * delta
	var new_offset: Vector3 = (offset + temporary_value) * exponential_decay
	var new_velocity: Vector3 = (current_velocity - temporary_value * angular_frequency) * exponential_decay
	var new_value: Vector3 = target_value + new_offset
	if new_value.distance_squared_to(target_value) < minimum_spring_distance * minimum_spring_distance and new_velocity.length_squared() < minimum_spring_velocity * minimum_spring_velocity:
		new_value = target_value
		new_velocity = Vector3.ZERO
	return {
		"value": new_value,
		"velocity": new_velocity
	}
