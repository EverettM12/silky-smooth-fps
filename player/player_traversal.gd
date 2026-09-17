class_name PlayerTraversal
extends Node

signal hurdle_started(hurdle_target_position: Vector3)
signal mantle_started(mantle_target_position: Vector3)
signal scramble_started(scramble_wall_position: Vector3)
signal traversal_completed(traversal_type: TraversalType)
signal traversal_cancelled(traversal_type: TraversalType)
@warning_ignore("unused_signal")
signal traversal_failed(traversal_type: TraversalType)

enum TraversalType {
	NONE,
	HURDLE,
	MANTLE,
	WALL_SCRAMBLING
}

enum TraversalPhase {
	INACTIVE,
	ASCENDING,
	CROSSING,
	LANDING,
	EXITING
}

@export_group("Traversal")
@export var traversal_enabled: bool = true
@export var traversal_input_grace_time: float = 0.14
@export var traversal_min_speed: float = 2.0
@export_range(0.0, 89.0, 0.1) var traversal_max_angle: float = 55.0
@export var traversal_forward_detection_distance: float = 2.4
@export var traversal_forward_detection_height: float = 1.35
@export_range(0.0, 1.0, 0.01) var traversal_direction_threshold: float = 0.38
@export var traversal_height_tolerance: float = 0.08
@export var traversal_vertical_tolerance: float = 0.18
@export var traversal_speed_distance_influence: float = 0.05
@export var allow_airborne_mantle: bool = true
@export var airborne_mantle_max_vertical_velocity: float = 2.0

@export_group("Wall Scramble")
@export var scramble_enabled: bool = true
@export var scramble_min_speed: float = 2.5
@export var scramble_max_height_gain: float = 3.75
@export var scramble_max_duration: float = 0.65
@export var scramble_min_duration: float = 0.12
@export var scramble_max_distance: float = 4.5

@export_group("Detection")
@export_flags_3d_physics var traversal_collision_mask: int = 1
@export var hurdle_detection_distance: float = 2.4
@export var mantle_detection_distance: float = 2.6
@export var front_probe_lateral_offset: float = 0.22
@export var front_probe_low_height: float = 0.18
@export var front_probe_mid_height: float = 0.72
@export var top_surface_probe_height: float = 2.0
@export var top_surface_probe_forward_offset: float = 0.12
@export var top_surface_probe_spacing: float = 0.22
@export var top_surface_probe_count: int = 5
@export var landing_vertical_search_extra: float = 0.2
@export var obstacle_probe_count: int = 3
@export_range(0.0, 1.0, 0.01) var wall_normal_vertical_limit: float = 0.35
@export var surface_angle_tolerance: float = 1.5

@export_group("Obstacle Classification")
@export var hurdle_min_height: float = 0.3
@export var hurdle_max_height: float = 0.95
@export var mantle_min_height: float = 0.75
@export var mantle_max_height: float = 1.6
@export_range(0.0, 89.0, 0.1) var hurdle_min_surface_angle: float = 0.0
@export_range(0.0, 89.0, 0.1) var hurdle_max_surface_angle: float = 45.0
@export_range(0.0, 89.0, 0.1) var mantle_min_surface_angle: float = 0.0
@export_range(0.0, 89.0, 0.1) var mantle_max_surface_angle: float = 38.0

@export_group("Scramble Detection")
@export var scramble_detection_distance: float = 2.2
@export_range(0.0, 89.0, 0.1) var scramble_detection_angle: float = 38.0
@export_range(0.0, 1.0, 0.01) var scramble_front_dot_threshold: float = 0.75
@export var scramble_min_wall_distance: float = 0.2
@export var scramble_max_wall_distance: float = 2.2
@export var scramble_probe_count: int = 3
@export_range(1, 3, 1) var scramble_required_probe_hits: int = 2
@export var scramble_entry_velocity_dot_threshold: float = 0.25
@export var scramble_height_check_distance: float = 4.5
@export var scramble_height_search: float = 1.2
@export var scramble_height_tolerance: float = 0.18
@export var scramble_height_probe_spacing: float = 0.22

@export_group("Wall Validation")
@export_range(0.0, 89.0, 0.1) var scramble_min_wall_angle: float = 0.0
@export_range(0.0, 89.0, 0.1) var scramble_max_wall_angle: float = 18.0
@export_range(0.0, 89.0, 0.1) var scramble_wall_normal_tolerance: float = 22.0
@export var scramble_wall_revalidation_interval: float = 0.05
@export var scramble_wall_normal_response: float = 16.0
@export var scramble_path_validation_interval: float = 0.08
@export var scramble_path_prediction_time: float = 0.09

@export_group("Movement")
@export var scramble_speed: float = 6.0
@export var scramble_speed_multiplier: float = 1.0
@export var scramble_steering_strength: float = 0.55
@export var scramble_steering_response: float = 8.0
@export var scramble_steering_limit: float = 55.0
@export var scramble_horizontal_control: float = 0.4
@export var scramble_lateral_control: float = 0.45

@export_group("Vertical Movement")
@export var scramble_upward_speed: float = 6.8
@export var scramble_upward_acceleration: float = 45.0
@export var scramble_upward_deceleration: float = 50.0
@export var scramble_gravity_scale: float = 0.12
@export var scramble_max_vertical_speed: float = 10.5
@export_range(0.0, 1.0, 0.01) var scramble_vertical_control: float = 0.2
@export_range(0.0, 1.0, 0.01) var scramble_height_brake_start: float = 0.74

@export_group("Wall Adhesion")
@export var scramble_wall_distance: float = 0.43
@export var scramble_wall_stick_force: float = 12.0
@export_range(0.0, 1.0, 0.01) var scramble_wall_stick_strength: float = 0.9
@export var scramble_wall_distance_response: float = 18.0

@export_group("Momentum")
@export_range(0.0, 1.0, 0.01) var scramble_entry_momentum_preservation: float = 1.0
@export_range(0.0, 1.0, 0.01) var scramble_exit_momentum_preservation: float = 1.0
@export var scramble_exit_speed_multiplier: float = 1.05
@export_range(0.0, 1.0, 0.01) var scramble_exit_direction_influence: float = 0.35

@export_group("Ledge Transition")
@export var scramble_ledge_detection_distance: float = 1.35
@export var scramble_ledge_height_tolerance: float = 0.18
@export var scramble_ledge_transition_threshold: float = 1.55
@export var scramble_ledge_min_height: float = 0.7
@export var scramble_ledge_check_interval: float = 0.05

@export_group("Timing")
@export var traversal_completion_tolerance: float = 0.08
@export var traversal_cancel_velocity_multiplier: float = 0.92
@export var traversal_exit_blend_time: float = 0.05

@export_group("Hurdle")
@export var hurdle_min_distance: float = 0.35
@export var hurdle_max_distance: float = 3.4
@export var hurdle_min_speed: float = 2.5
@export var hurdle_min_duration: float = 0.08
@export var hurdle_max_duration: float = 0.38
@export var hurdle_speed_multiplier: float = 1.0
@export_range(0.0, 1.0, 0.01) var hurdle_speed_influence: float = 0.95
@export_range(0.0, 1.0, 0.01) var hurdle_momentum_preservation: float = 0.98
@export var hurdle_entry_speed_influence: float = 1.0
@export var hurdle_exit_speed_multiplier: float = 1.0
@export_range(0.0, 1.0, 0.01) var hurdle_exit_direction_influence: float = 0.2
@export var hurdle_clearance_height: float = 0.12
@export var hurdle_min_arc_height: float = 0.45
@export var hurdle_arc_height: float = 0.0
@export var hurdle_max_arc_height: float = 1.45
@export_range(1.0, 3.0, 0.01) var hurdle_arc_profile_exponent: float = 2.0
@export var hurdle_landing_clearance_distance: float = 0.75
@export var hurdle_landing_search_distance: float = 2.8
@export var hurdle_landing_probe_spacing: float = 0.2
@export var hurdle_landing_tolerance: float = 0.12
@export var hurdle_completion_tolerance: float = 0.14
@export_range(0.0, 1.0, 0.01) var hurdle_completion_progress: float = 0.94

@export_group("Hurdle Steering")
@export var hurdle_steering_strength: float = 0.7
@export var hurdle_steering_response: float = 9.0
@export_range(0.0, 89.0, 0.1) var hurdle_max_steering_angle: float = 22.0

@export_group("Hurdle Path")
@export var hurdle_path_samples: int = 10
@export var hurdle_clearance_margin: float = 0.04
@export var hurdle_path_validation: bool = true
@export var hurdle_path_validation_interval: float = 0.06

@export_group("Mantle")
@export var mantle_duration: float = 0.42
@export var mantle_height: float = 1.3
@export var mantle_forward_distance: float = 0.65
@export var mantle_pull_speed: float = 8.5
@export var mantle_vertical_speed: float = 6.0
@export var mantle_acceleration: float = 30.0
@export var mantle_exit_velocity: float = 8.5
@export_range(0.0, 1.0, 0.01) var mantle_momentum_preservation: float = 0.88
@export var mantle_wall_clearance: float = 0.08
@export var mantle_target_offset: float = 0.045
@export var mantle_surface_tolerance: float = 0.1
@export var mantle_clearance_height: float = 0.08
@export var mantle_top_search_distance: float = 1.1
@export var mantle_top_min_forward_distance: float = 0.2

@export_group("Clearance")
@export var clearance_segment_tolerance: float = 0.04
@export var standing_clearance_height_multiplier: float = 1.0

@export_group("Global Momentum")
@export_range(0.0, 1.0, 0.01) var traversal_momentum_preservation: float = 0.98
@export var traversal_exit_speed_multiplier: float = 1.0
@export var traversal_entry_speed_influence: float = 1.0

@export_group("Camera")
@export var hurdle_camera_pitch: float = 2.0
@export var hurdle_camera_roll: float = 1.1
@export var hurdle_camera_offset: float = 0.035
@export var hurdle_camera_response_speed: float = 18.0
@export var hurdle_camera_return_speed: float = 14.0
@export var mantle_camera_pitch: float = 3.2
@export var mantle_camera_roll: float = 0.8
@export var mantle_camera_offset: float = 0.055
@export var mantle_camera_response_speed: float = 13.0
@export var mantle_camera_return_speed: float = 11.0
@export var scramble_camera_pitch: float = 3.0
@export var scramble_camera_roll: float = 1.2
@export var scramble_camera_offset: float = 0.04
@export var scramble_camera_response_speed: float = 18.0
@export var scramble_camera_return_speed: float = 14.0
@export var scramble_camera_vertical_influence: float = 0.85

@export_group("Camera Smoothing")
@export var traversal_camera_spring_frequency: float = 18.0
@export var traversal_camera_return_frequency: float = 12.0
@export var traversal_camera_vertical_response: float = 14.0
@export var traversal_camera_lateral_response: float = 10.0

@export_group("FOV")
@export var traversal_fov_boost: float = 0.4
@export var hurdle_fov_boost: float = 2.0
@export var mantle_fov_boost: float = 1.2
@export var traversal_fov_response: float = 16.0
@export var traversal_fov_return: float = 12.0
@export var hurdle_fov_response: float = 18.0
@export var hurdle_fov_return: float = 13.0
@export var scramble_fov_boost: float = 3.5
@export var scramble_fov_response: float = 18.0
@export var scramble_fov_return: float = 14.0
@export var scramble_fov_speed_influence: float = 1.6

@export_group("Assistance")
@export var traversal_assist_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var traversal_assist_strength: float = 0.28
@export_range(0.0, 89.0, 0.1) var traversal_assist_angle: float = 16.0
@export var traversal_assist_distance: float = 0.5

@export_group("Debug")
@export var debug_draw_traversal_rays: bool = false
@export var debug_draw_traversal_shapes: bool = false
@export var debug_draw_traversal_target: bool = false
@export var debug_draw_hurdle_target: bool = false
@export var debug_draw_mantle_target: bool = false
@export var debug_draw_hurdle_path: bool = false
@export var debug_draw_scramble_wall_rays: bool = false
@export var debug_draw_scramble_wall_normal: bool = false
@export var debug_draw_scramble_ledge_target: bool = false
@export var debug_draw_scramble_clearance: bool = false
@export var debug_draw_scramble_capsule: bool = false
@export var debug_draw_scramble_path: bool = false
@export var debug_print_traversal_state: bool = false
@export var debug_print_scramble_state: bool = false

@onready var player: Player = get_parent() as Player
@onready var player_input: PlayerInput = get_node("../PlayerInput") as PlayerInput
@onready var player_state: PlayerState = get_node("../PlayerState") as PlayerState
@onready var player_movement: PlayerMovement = get_node("../PlayerMovement") as PlayerMovement
@onready var player_collision_shape: CollisionShape3D = get_node("../CollisionShape3D") as CollisionShape3D
@onready var camera: Camera3D = get_node("../Head/CameraMotion/Camera3D") as Camera3D

var standing_capsule_shape: CapsuleShape3D = null
var clearance_query: PhysicsShapeQueryParameters3D = null
var traversal_active: bool = false
var traversal_type: TraversalType = TraversalType.NONE
var traversal_phase: TraversalPhase = TraversalPhase.INACTIVE
var traversal_progress: float = 0.0
var traversal_elapsed: float = 0.0
var traversal_input_grace_timer: float = 0.0
var hurdle_path_validation_timer: float = 0.0
var scramble_wall_revalidation_timer: float = 0.0
var scramble_path_validation_timer: float = 0.0
var scramble_ledge_check_timer: float = 0.0
var scramble_elapsed_time: float = 0.0
var scramble_distance_traveled: float = 0.0
var traversal_start_position: Vector3 = Vector3.ZERO
var traversal_start_velocity: Vector3 = Vector3.ZERO
var traversal_target_position: Vector3 = Vector3.ZERO
var hurdle_target_position: Vector3 = Vector3.ZERO
var hurdle_landing_position: Vector3 = Vector3.ZERO
var hurdle_crossing_position: Vector3 = Vector3.ZERO
var hurdle_arc_height_value: float = 0.0
var hurdle_runtime_duration: float = 0.0
var mantle_target_position: Vector3 = Vector3.ZERO
var mantle_lift_position: Vector3 = Vector3.ZERO
var traversal_entry_direction: Vector3 = Vector3.ZERO
var traversal_path_direction: Vector3 = Vector3.ZERO
var traversal_target_distance: float = 0.0
var obstacle_front_position: Vector3 = Vector3.ZERO
var obstacle_normal: Vector3 = Vector3.ZERO
var obstacle_top_position: Vector3 = Vector3.ZERO
var obstacle_top_normal: Vector3 = Vector3.UP
var obstacle_height: float = 0.0
var landing_surface_normal: Vector3 = Vector3.UP
var scramble_start_position: Vector3 = Vector3.ZERO
var scramble_wall_normal: Vector3 = Vector3.ZERO
var scramble_wall_contact_position: Vector3 = Vector3.ZERO
var scramble_wall_rid: RID = RID()
var scramble_wall_distance_value: float = 0.0
var scramble_entry_tangent_velocity: Vector3 = Vector3.ZERO
var scramble_target_position: Vector3 = Vector3.ZERO
var scramble_ledge_target_position: Vector3 = Vector3.ZERO
var scramble_ledge_target_normal: Vector3 = Vector3.UP
var scramble_wall_top_position: Vector3 = Vector3.ZERO
var scramble_wall_top_normal: Vector3 = Vector3.UP
var last_debug_state: StringName = &"INACTIVE"
var debug_mesh_instance: MeshInstance3D = null
var debug_immediate_mesh: ImmediateMesh = null
var debug_material: StandardMaterial3D = null

func _ready() -> void:
	if player == null or player_input == null or player_state == null or player_movement == null or player_collision_shape == null or camera == null:
		return
	if not (player_collision_shape.shape is CapsuleShape3D):
		return
	var source_capsule_shape: CapsuleShape3D = player_collision_shape.shape as CapsuleShape3D
	standing_capsule_shape = source_capsule_shape.duplicate() as CapsuleShape3D
	standing_capsule_shape.height = max(
		player_movement.standing_height,
		standing_capsule_shape.radius * 2.0 * standing_clearance_height_multiplier
	)
	clearance_query = PhysicsShapeQueryParameters3D.new()
	clearance_query.shape = standing_capsule_shape
	clearance_query.collision_mask = traversal_collision_mask
	clearance_query.exclude = [player.get_rid()]
	clearance_query.collide_with_areas = false
	clearance_query.collide_with_bodies = true
	clearance_query.margin = 0.0
	ensure_debug_geometry()

func _physics_process(_delta: float) -> void:
	update_debug_state()

func _process(_delta: float) -> void:
	ensure_debug_geometry()
	update_debug_geometry()

func ensure_debug_geometry() -> void:
	if debug_immediate_mesh != null or not is_debug_geometry_enabled():
		return
	debug_mesh_instance = MeshInstance3D.new()
	debug_immediate_mesh = ImmediateMesh.new()
	debug_material = StandardMaterial3D.new()
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.no_depth_test = true
	debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	debug_material.albedo_color = Color(0.1, 0.9, 1.0, 0.85)
	debug_mesh_instance.mesh = debug_immediate_mesh
	add_child(debug_mesh_instance)

func is_debug_geometry_enabled() -> bool:
	return (
		debug_draw_traversal_rays
		or debug_draw_traversal_shapes
		or debug_draw_traversal_target
		or debug_draw_hurdle_target
		or debug_draw_mantle_target
		or debug_draw_hurdle_path
		or debug_draw_scramble_wall_rays
		or debug_draw_scramble_wall_normal
		or debug_draw_scramble_ledge_target
		or debug_draw_scramble_clearance
		or debug_draw_scramble_capsule
		or debug_draw_scramble_path
	)

func process_physics_pre_movement(delta: float) -> bool:
	if player == null or player_input == null or player_state == null or player_movement == null or standing_capsule_shape == null:
		return false
	traversal_input_grace_timer = max(traversal_input_grace_timer - delta, 0.0)
	if player_input.jump_just_pressed:
		traversal_input_grace_timer = traversal_input_grace_time
	if traversal_active:
		return true
	if not is_input_eligible():
		return false
	var traversal_target_data: Dictionary = find_traversal_target()
	if traversal_target_data.is_empty():
		return false
	start_traversal(traversal_target_data)
	return true

func process_physics(delta: float) -> void:
	if not traversal_active:
		return
	if traversal_type == TraversalType.HURDLE and not player_state.is_hurdling():
		cancel_traversal()
		return
	if traversal_type == TraversalType.MANTLE and not player_state.is_mantling():
		cancel_traversal()
		return
	if traversal_type == TraversalType.WALL_SCRAMBLING and not player_state.is_wall_scrambling():
		cancel_traversal()
		return
	traversal_elapsed += delta
	var current_duration: float = get_current_duration()
	traversal_progress = clamp(traversal_elapsed / max(current_duration, 0.001), 0.0, 1.0)
	update_traversal_phase()
	if traversal_type == TraversalType.HURDLE:
		player.velocity = calculate_hurdle_velocity(traversal_progress, current_duration)
		apply_hurdle_steering(delta)
		update_hurdle_path_validation(delta)
	elif traversal_type == TraversalType.MANTLE:
		process_mantle_physics(delta)
	elif traversal_type == TraversalType.WALL_SCRAMBLING:
		process_scramble_physics(delta)
	traversal_path_direction = Vector3(player.velocity.x, 0.0, player.velocity.z)
	if traversal_path_direction.length_squared() > 0.001:
		traversal_path_direction = traversal_path_direction.normalized()

func process_mantle_physics(delta: float) -> void:
	var desired_position: Vector3 = calculate_mantle_position(traversal_progress)
	var desired_motion: Vector3 = desired_position - player.global_position
	var desired_velocity: Vector3 = Vector3.ZERO
	if delta > 0.000001:
		desired_velocity = desired_motion / delta
	player.velocity = player.velocity.move_toward(
		desired_velocity,
		mantle_acceleration * delta
	)
	apply_traversal_steering(delta)

func process_scramble_physics(delta: float) -> void:
	scramble_elapsed_time = traversal_elapsed
	if not update_active_scramble_wall(delta):
		cancel_traversal()
		return
	if try_start_scramble_mantle(delta):
		return
	var scramble_height_gain: float = max(player.global_position.y - scramble_start_position.y, 0.0)
	var height_progress: float = clamp(
		scramble_height_gain / max(scramble_max_height_gain, 0.001),
		0.0,
		1.0
	)
	var duration_progress: float = clamp(
		scramble_elapsed_time / max(get_current_duration(), 0.001),
		0.0,
		1.0
	)
	var brake_progress: float = max(
		smoothstep(scramble_height_brake_start, 1.0, height_progress),
		duration_progress
	)
	var target_vertical_speed: float = scramble_upward_speed * scramble_speed_multiplier
	if player_input.jump_pressed:
		target_vertical_speed *= 1.0 + scramble_vertical_control
	target_vertical_speed = lerp(target_vertical_speed, 0.0, brake_progress)
	var vertical_acceleration: float = scramble_upward_acceleration
	if player.velocity.y > target_vertical_speed:
		vertical_acceleration = scramble_upward_deceleration
	player.velocity.y = move_toward(
		player.velocity.y,
		target_vertical_speed,
		vertical_acceleration * delta
	)
	player.velocity.y -= player_movement.gravity_while_rising * scramble_gravity_scale * delta
	player.velocity.y = clamp(
		player.velocity.y,
		-player_movement.maximum_fall_speed,
		scramble_max_vertical_speed
	)
	apply_scramble_horizontal_control(delta)
	apply_scramble_wall_adhesion(delta)
	update_scramble_path_validation(delta)
	if scramble_elapsed_time >= get_current_duration() and scramble_elapsed_time >= scramble_min_duration:
		if not try_start_scramble_mantle(delta):
			release_traversal()

func process_physics_post_movement(delta: float) -> void:
	if not traversal_active:
		return
	if player.is_on_ceiling():
		cancel_traversal()
		return
	if traversal_type == TraversalType.HURDLE:
		process_hurdle_post_movement()
		return
	if traversal_type == TraversalType.WALL_SCRAMBLING:
		if try_start_scramble_mantle(delta):
			return
		if should_release_scramble():
			release_traversal()
		return
	if traversal_progress < 1.0:
		return
	var target_distance: float = player.global_position.distance_to(traversal_target_position)
	if target_distance <= traversal_completion_tolerance or player.is_on_floor():
		complete_traversal()
		return
	if player.get_slide_collision_count() > 0:
		cancel_traversal()
		return
	release_traversal()

func process_hurdle_post_movement() -> void:
	var target_horizontal_offset: Vector3 = hurdle_landing_position - player.global_position
	target_horizontal_offset.y = 0.0
	var current_horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var exit_direction: Vector3 = current_horizontal_velocity.normalized()
	if current_horizontal_velocity.length_squared() <= 0.001:
		exit_direction = traversal_entry_direction
	var forward_distance: float = Vector2(
		player.global_position.x - traversal_start_position.x,
		player.global_position.z - traversal_start_position.z
	).dot(Vector2(exit_direction.x, exit_direction.z))
	var target_forward_distance: float = Vector2(
		hurdle_landing_position.x - traversal_start_position.x,
		hurdle_landing_position.z - traversal_start_position.z
	).dot(Vector2(exit_direction.x, exit_direction.z))
	var close_to_landing: bool = target_horizontal_offset.length() <= hurdle_completion_tolerance
	var passed_landing: bool = forward_distance >= target_forward_distance - hurdle_completion_tolerance
	if player.is_on_floor() and (close_to_landing or passed_landing):
		complete_traversal()
		return
	if traversal_progress < hurdle_completion_progress:
		return
	if player.is_on_floor() and close_to_landing:
		complete_traversal()
		return
	if traversal_progress < 1.0:
		return
	if close_to_landing or (player.is_on_floor() and passed_landing):
		complete_traversal()
		return
	release_traversal()

func update_hurdle_path_validation(delta: float) -> void:
	if not hurdle_path_validation or not traversal_active or traversal_type != TraversalType.HURDLE:
		return
	hurdle_path_validation_timer -= delta
	if hurdle_path_validation_timer > 0.0:
		return
	hurdle_path_validation_timer = max(hurdle_path_validation_interval, 0.001)
	var validation_progress: float = min(
		traversal_progress + max(delta, hurdle_path_validation_interval) / max(hurdle_runtime_duration, 0.001),
		1.0
	)
	var validation_position: Vector3 = calculate_hurdle_position(validation_progress)
	if not validate_capsule_motion(player.global_position, validation_position):
		cancel_traversal()

func update_scramble_path_validation(delta: float) -> void:
	if not traversal_active or traversal_type != TraversalType.WALL_SCRAMBLING:
		return
	scramble_path_validation_timer -= delta
	if scramble_path_validation_timer > 0.0:
		return
	scramble_path_validation_timer = max(scramble_path_validation_interval, 0.001)
	var prediction_motion: Vector3 = player.velocity * scramble_path_prediction_time
	var predicted_position: Vector3 = player.global_position + prediction_motion
	var maximum_height: float = scramble_start_position.y + scramble_max_height_gain
	predicted_position.y = min(predicted_position.y, maximum_height)
	if not validate_capsule_motion(player.global_position, predicted_position):
		cancel_traversal()

func is_input_eligible() -> bool:
	if not traversal_enabled or traversal_input_grace_timer <= 0.0:
		return false
	if traversal_active or player_state.is_grappling() or player_movement.is_dashing:
		return false
	if player_state.is_wall_running() or player_movement.can_start_wall_run():
		return false
	var horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horizontal_velocity.length() < traversal_min_speed:
		return false
	if player.is_on_floor() or player_state.is_sliding():
		return true
	return allow_airborne_mantle and player.velocity.y <= airborne_mantle_max_vertical_velocity

func find_traversal_target() -> Dictionary:
	var obstacle_data: Dictionary = detect_obstacle()
	if not obstacle_data.is_empty():
		obstacle_front_position = obstacle_data["front_position"] as Vector3
		obstacle_normal = obstacle_data["normal"] as Vector3
		obstacle_top_position = obstacle_data["top_position"] as Vector3
		obstacle_top_normal = obstacle_data["top_normal"] as Vector3
		obstacle_height = obstacle_data["obstacle_height"] as float
		landing_surface_normal = obstacle_data.get("landing_normal", Vector3.UP) as Vector3
		var hurdle_target: Vector3 = calculate_hurdle_target(obstacle_data)
		if not hurdle_target.is_zero_approx() and (player.is_on_floor() or player_state.is_sliding()):
			return {
				"type": TraversalType.HURDLE,
				"target_position": hurdle_target
			}
		var mantle_target: Vector3 = calculate_mantle_target(obstacle_data)
		if not mantle_target.is_zero_approx():
			return {
				"type": TraversalType.MANTLE,
				"target_position": mantle_target
			}
		if scramble_enabled:
			var scramble_target_data: Dictionary = calculate_scramble_target_from_wall_data(obstacle_data)
			if not scramble_target_data.is_empty():
				return scramble_target_data
		return {}
	if scramble_enabled:
		var scramble_wall_data: Dictionary = find_scramble_wall()
		if not scramble_wall_data.is_empty():
			var scramble_target_data: Dictionary = calculate_scramble_target_from_wall_data(scramble_wall_data)
			if not scramble_target_data.is_empty():
				return scramble_target_data
	return {}

func calculate_scramble_target_from_wall_data(wall_data: Dictionary) -> Dictionary:
	if wall_data.is_empty() or not scramble_enabled:
		return {}
	var wall_position: Vector3 = wall_data["position"] as Vector3
	var wall_normal_value: Vector3 = wall_data["normal"] as Vector3
	var wall_rid: RID = wall_data.get("rid", RID()) as RID
	var wall_distance: float = wall_data.get("distance", 0.0) as float
	var detection_direction: Vector3 = get_scramble_detection_direction()
	if detection_direction.length_squared() <= 0.001:
		return {}
	if not is_scramble_wall_surface_valid(wall_normal_value):
		return {}
	var facing_dot: float = detection_direction.dot(-wall_normal_value)
	var facing_angle: float = rad_to_deg(acos(clamp(facing_dot, -1.0, 1.0)))
	if facing_dot < scramble_front_dot_threshold or facing_angle > scramble_detection_angle:
		return {}
	if wall_distance < scramble_min_wall_distance or wall_distance > scramble_max_wall_distance:
		return {}
	var horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var horizontal_speed: float = horizontal_velocity.length()
	if horizontal_speed < scramble_min_speed:
		return {}
	if horizontal_velocity.length_squared() <= 0.001:
		return {}
	var entry_velocity_dot: float = horizontal_velocity.normalized().dot(-wall_normal_value)
	if entry_velocity_dot < scramble_entry_velocity_dot_threshold:
		return {}
	var top_data: Dictionary = find_scramble_wall_top(wall_position, wall_normal_value, wall_rid)
	if not top_data.is_empty():
		var top_position: Vector3 = top_data["position"] as Vector3
		var top_height_gain: float = top_position.y - player.global_position.y
		scramble_wall_top_position = top_position
		scramble_wall_top_normal = top_data["normal"] as Vector3
		if top_height_gain <= mantle_max_height + scramble_height_tolerance:
			return {}
	var scramble_target: Vector3 = player.global_position + Vector3.UP * scramble_max_height_gain
	return {
		"type": TraversalType.WALL_SCRAMBLING,
		"target_position": scramble_target,
		"wall_position": wall_position,
		"wall_normal": wall_normal_value,
		"wall_rid": wall_rid,
		"wall_distance": wall_distance
	}

func find_scramble_wall() -> Dictionary:
	var detection_direction: Vector3 = get_scramble_detection_direction()
	if detection_direction.length_squared() <= 0.001:
		return {}
	var horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horizontal_velocity.length_squared() <= 0.001:
		return {}
	if horizontal_velocity.length() < scramble_min_speed:
		return {}
	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var probe_heights: Array[float] = [
		front_probe_low_height,
		front_probe_mid_height,
		traversal_forward_detection_height
	]
	var probe_count: int = clamp(scramble_probe_count, 1, probe_heights.size())
	var candidates: Array[Dictionary] = []
	for probe_index: int in range(probe_count):
		var probe_height: float = probe_heights[probe_index]
		var probe_origin: Vector3 = player.global_position + Vector3.UP * probe_height
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			probe_origin,
			probe_origin + detection_direction * scramble_detection_distance,
			traversal_collision_mask,
			[player.get_rid()]
		)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit: Dictionary = space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		var hit_normal: Vector3 = hit.get("normal", Vector3.ZERO) as Vector3
		if not is_scramble_wall_surface_valid(hit_normal):
			continue
		var facing_dot: float = detection_direction.dot(-hit_normal)
		var facing_angle: float = rad_to_deg(acos(clamp(facing_dot, -1.0, 1.0)))
		if facing_dot < scramble_front_dot_threshold or facing_angle > scramble_detection_angle:
			continue
		var hit_position: Vector3 = hit.get("position", probe_origin) as Vector3
		var hit_distance: float = probe_origin.distance_to(hit_position)
		if hit_distance < scramble_min_wall_distance or hit_distance > scramble_max_wall_distance:
			continue
		var entry_velocity_dot: float = horizontal_velocity.normalized().dot(-hit_normal)
		if entry_velocity_dot < scramble_entry_velocity_dot_threshold:
			continue
		candidates.append({
			"position": hit_position,
			"normal": hit_normal,
			"rid": hit.get("rid", RID()),
			"distance": hit_distance,
			"score": hit_distance + (1.0 - facing_dot) * scramble_detection_distance
		})
	if candidates.is_empty():
		return {}
	var best_candidate: Dictionary = candidates[0]
	var best_score: float = best_candidate["score"] as float
	for candidate: Dictionary in candidates:
		var candidate_score: float = candidate["score"] as float
		if candidate_score < best_score:
			best_score = candidate_score
			best_candidate = candidate
	var best_rid: RID = best_candidate["rid"] as RID
	var matching_probe_count: int = 0
	for candidate: Dictionary in candidates:
		var candidate_rid: RID = candidate["rid"] as RID
		if candidate_rid == best_rid:
			matching_probe_count += 1
	if matching_probe_count < clamp(scramble_required_probe_hits, 1, probe_count):
		return {}
	return best_candidate

func find_scramble_wall_top(wall_position: Vector3, wall_normal_value: Vector3, wall_rid: RID) -> Dictionary:
	var inward_direction: Vector3 = -wall_normal_value
	inward_direction.y = 0.0
	if inward_direction.length_squared() <= 0.001:
		return {}
	inward_direction = inward_direction.normalized()
	var search_distance: float = max(scramble_height_search, clearance_segment_tolerance)
	var search_step: float = max(scramble_height_probe_spacing, clearance_segment_tolerance)
	var probe_distance: float = 0.0
	var highest_top_data: Dictionary = {}
	while probe_distance <= search_distance:
		var probe_point: Vector3 = wall_position + inward_direction * probe_distance
		var probe_origin: Vector3 = Vector3(
			probe_point.x,
			player.global_position.y + scramble_height_check_distance,
			probe_point.z
		)
		var probe_end: Vector3 = Vector3(
			probe_point.x,
			player.global_position.y - scramble_height_tolerance,
			probe_point.z
		)
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			probe_origin,
			probe_end,
			traversal_collision_mask,
			[player.get_rid()]
		)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var hit_rid: RID = hit.get("rid", RID()) as RID
			if wall_rid.is_valid() and hit_rid != wall_rid:
				probe_distance += search_step
				continue
			var hit_position: Vector3 = hit.get("position", probe_end) as Vector3
			var hit_normal: Vector3 = hit.get("normal", Vector3.ZERO) as Vector3
			if is_walkable_surface(hit_normal):
				if hit_position.y > player.global_position.y - scramble_height_tolerance:
					if highest_top_data.is_empty() or hit_position.y > (highest_top_data["position"] as Vector3).y:
						highest_top_data = {
							"position": hit_position,
							"normal": hit_normal
						}
		probe_distance += search_step
	return highest_top_data

func update_active_scramble_wall(delta: float) -> bool:
	scramble_wall_revalidation_timer -= delta
	if scramble_wall_revalidation_timer > 0.0:
		return true
	scramble_wall_revalidation_timer = max(scramble_wall_revalidation_interval, 0.001)
	var wall_data: Dictionary = find_active_scramble_wall()
	if wall_data.is_empty():
		return false
	var current_normal: Vector3 = wall_data["normal"] as Vector3
	var normal_blend: float = clamp(scramble_wall_normal_response * delta, 0.0, 1.0)
	scramble_wall_normal = scramble_wall_normal.slerp(current_normal, normal_blend).normalized()
	scramble_wall_contact_position = wall_data["position"] as Vector3
	scramble_wall_distance_value = wall_data["distance"] as float
	return true

func find_active_scramble_wall() -> Dictionary:
	if scramble_wall_normal.length_squared() <= 0.001:
		return {}
	var wall_direction: Vector3 = -scramble_wall_normal
	wall_direction.y = 0.0
	if wall_direction.length_squared() <= 0.001:
		return {}
	wall_direction = wall_direction.normalized()
	var probe_heights: Array[float] = [
		front_probe_low_height,
		front_probe_mid_height,
		traversal_forward_detection_height
	]
	var probe_count: int = clamp(scramble_probe_count, 1, probe_heights.size())
	var best_wall_data: Dictionary = {}
	var best_distance: float = INF
	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	for probe_index: int in range(probe_count):
		var probe_height: float = probe_heights[probe_index]
		var probe_origin: Vector3 = player.global_position + Vector3.UP * probe_height
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			probe_origin,
			probe_origin + wall_direction * scramble_max_wall_distance,
			traversal_collision_mask,
			[player.get_rid()]
		)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit: Dictionary = space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		var hit_rid: RID = hit.get("rid", RID()) as RID
		if scramble_wall_rid.is_valid() and hit_rid != scramble_wall_rid:
			continue
		var hit_normal: Vector3 = hit.get("normal", Vector3.ZERO) as Vector3
		if not is_scramble_wall_surface_valid(hit_normal):
			continue
		var normal_difference: float = rad_to_deg(acos(clamp(scramble_wall_normal.dot(hit_normal), -1.0, 1.0)))
		if normal_difference > scramble_wall_normal_tolerance:
			continue
		var hit_position: Vector3 = hit.get("position", probe_origin) as Vector3
		var hit_distance: float = probe_origin.distance_to(hit_position)
		if hit_distance > scramble_max_wall_distance:
			continue
		if hit_distance < best_distance:
			best_distance = hit_distance
			best_wall_data = {
				"position": hit_position,
				"normal": hit_normal,
				"rid": hit_rid,
				"distance": hit_distance
			}
	if best_wall_data.is_empty():
		return {}
	if best_distance < max(capsule_radius_from_shape() * 0.5, scramble_min_wall_distance * 0.5):
		return {}
	return best_wall_data

func try_start_scramble_mantle(delta: float) -> bool:
	if not traversal_active or traversal_type != TraversalType.WALL_SCRAMBLING:
		return false
	scramble_ledge_check_timer -= delta
	if scramble_ledge_check_timer > 0.0:
		return false
	scramble_ledge_check_timer = max(scramble_ledge_check_interval, 0.001)
	var ledge_data: Dictionary = find_scramble_ledge_target()
	if ledge_data.is_empty():
		return false
	scramble_ledge_target_position = ledge_data["target_position"] as Vector3
	scramble_ledge_target_normal = ledge_data["normal"] as Vector3
	var ledge_lift_position: Vector3 = ledge_data["lift_position"] as Vector3
	start_traversal({
		"type": TraversalType.MANTLE,
		"target_position": scramble_ledge_target_position,
		"mantle_lift_position": ledge_lift_position
	})
	return true

func find_scramble_ledge_target() -> Dictionary:
	if scramble_wall_contact_position == Vector3.ZERO or scramble_wall_normal.length_squared() <= 0.001:
		return {}
	var inward_direction: Vector3 = -scramble_wall_normal
	inward_direction.y = 0.0
	if inward_direction.length_squared() <= 0.001:
		return {}
	inward_direction = inward_direction.normalized()
	var search_distance: float = max(scramble_ledge_detection_distance, mantle_top_min_forward_distance)
	var search_step: float = max(top_surface_probe_spacing, clearance_segment_tolerance)
	var probe_distance: float = max(mantle_top_min_forward_distance, clearance_segment_tolerance)
	while probe_distance <= search_distance:
		var probe_point: Vector3 = scramble_wall_contact_position + inward_direction * probe_distance
		var probe_origin: Vector3 = Vector3(
			probe_point.x,
			player.global_position.y + mantle_max_height + scramble_ledge_height_tolerance,
			probe_point.z
		)
		var minimum_height: float = max(
			scramble_ledge_min_height - scramble_ledge_height_tolerance,
			clearance_segment_tolerance
		)
		var probe_end: Vector3 = Vector3(
			probe_point.x,
			player.global_position.y + minimum_height,
			probe_point.z
		)
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			probe_origin,
			probe_end,
			traversal_collision_mask,
			[player.get_rid()]
		)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var hit_position: Vector3 = hit.get("position", probe_end) as Vector3
			var hit_normal: Vector3 = hit.get("normal", Vector3.UP) as Vector3
			var ledge_height_gain: float = hit_position.y - player.global_position.y
			var ledge_height_limit: float = min(
				scramble_ledge_transition_threshold,
				mantle_max_height
			)
			if ledge_height_gain >= scramble_ledge_min_height - scramble_ledge_height_tolerance and ledge_height_gain <= ledge_height_limit + scramble_ledge_height_tolerance:
				if is_walkable_surface(hit_normal):
					var target_position: Vector3 = hit_position + hit_normal * mantle_target_offset
					if is_capsule_position_clear(target_position):
						var lift_position: Vector3 = player.global_position + scramble_wall_normal * (
							standing_capsule_shape.radius + mantle_wall_clearance
						)
						lift_position.y = hit_position.y + max(
							mantle_clearance_height,
							mantle_height * 0.04
						)
						if validate_mantle_path(player.global_position, lift_position, target_position):
							return {
								"target_position": target_position,
								"lift_position": lift_position,
								"normal": hit_normal
							}
		probe_distance += search_step
	return {}

func should_release_scramble() -> bool:
	if traversal_elapsed < scramble_min_duration:
		return false
	var reached_height_limit: bool = false
	if scramble_max_height_gain > 0.0:
		reached_height_limit = player.global_position.y - scramble_start_position.y >= scramble_max_height_gain
	var reached_distance_limit: bool = false
	if scramble_max_distance > 0.0:
		var wall_plane_motion: Vector3 = player.global_position - scramble_start_position
		wall_plane_motion = wall_plane_motion.slide(scramble_wall_normal)
		scramble_distance_traveled = wall_plane_motion.length()
		reached_distance_limit = scramble_distance_traveled >= scramble_max_distance
	var reached_time_limit: bool = traversal_elapsed >= max(scramble_max_duration, scramble_min_duration)
	return reached_height_limit or reached_distance_limit or reached_time_limit

func apply_scramble_horizontal_control(delta: float) -> void:
	var current_horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var current_tangent_velocity: Vector3 = current_horizontal_velocity.slide(scramble_wall_normal)
	var preserved_entry_velocity: Vector3 = scramble_entry_tangent_velocity
	var input_direction: Vector3 = player_movement.get_movement_direction()
	var input_tangent_direction: Vector3 = input_direction.slide(scramble_wall_normal)
	if input_tangent_direction.length_squared() > 0.001:
		input_tangent_direction = input_tangent_direction.normalized()
		var reference_direction: Vector3 = current_tangent_velocity.normalized()
		if reference_direction.length_squared() <= 0.001:
			reference_direction = preserved_entry_velocity.normalized()
		var allowed_direction: Vector3 = input_tangent_direction
		if reference_direction.length_squared() > 0.001:
			var steering_angle: float = rad_to_deg(reference_direction.angle_to(input_tangent_direction))
			if steering_angle > scramble_steering_limit:
				var steering_blend: float = clamp(
					scramble_steering_limit / max(steering_angle, 0.001),
					0.0,
					1.0
				)
				allowed_direction = reference_direction.slerp(
					input_tangent_direction,
					steering_blend
				).normalized()
		var target_lateral_speed: float = scramble_speed * scramble_speed_multiplier * scramble_lateral_control
		var target_speed: float = max(current_tangent_velocity.length(), target_lateral_speed)
		var desired_velocity: Vector3 = allowed_direction * target_speed
		var steering_weight: float = clamp(
			scramble_steering_strength * scramble_horizontal_control * scramble_steering_response * delta,
			0.0,
			1.0
		)
		current_tangent_velocity = current_tangent_velocity.lerp(desired_velocity, steering_weight)
	else:
		var preserve_weight: float = clamp(scramble_entry_momentum_preservation * scramble_steering_response * delta, 0.0, 1.0)
		current_tangent_velocity = current_tangent_velocity.lerp(preserved_entry_velocity, preserve_weight)
	player.velocity.x = current_tangent_velocity.x
	player.velocity.z = current_tangent_velocity.z

func apply_scramble_wall_adhesion(delta: float) -> void:
	var target_wall_distance: float = max(
		scramble_wall_distance,
		capsule_radius_from_shape() + clearance_segment_tolerance
	)
	var distance_error: float = scramble_wall_distance_value - target_wall_distance
	var target_normal_velocity: float = clamp(
		-distance_error * scramble_wall_distance_response,
		-scramble_wall_stick_force,
		scramble_wall_stick_force
	) * scramble_wall_stick_strength
	var current_normal_velocity: float = player.velocity.dot(scramble_wall_normal)
	var normal_velocity_response: float = max(scramble_wall_distance_response, scramble_wall_normal_response)
	var blended_normal_velocity: float = move_toward(
		current_normal_velocity,
		target_normal_velocity,
		normal_velocity_response * delta
	)
	var tangent_velocity: Vector3 = player.velocity - scramble_wall_normal * current_normal_velocity
	player.velocity = tangent_velocity + scramble_wall_normal * blended_normal_velocity

func is_scramble_wall_surface_valid(surface_normal: Vector3) -> bool:
	if surface_normal.length_squared() <= 0.001:
		return false
	var wall_angle: float = scramble_wall_angle_degrees(surface_normal)
	if wall_angle < scramble_min_wall_angle or wall_angle > scramble_max_wall_angle:
		return false
	return true

func scramble_wall_angle_degrees(surface_normal: Vector3) -> float:
	var normalized_normal: Vector3 = surface_normal.normalized()
	return rad_to_deg(asin(clamp(abs(normalized_normal.y), 0.0, 1.0)))

func get_scramble_detection_direction() -> Vector3:
	var camera_direction: Vector3 = get_camera_forward()
	if camera_direction.length_squared() <= 0.001:
		return Vector3.ZERO
	return camera_direction.normalized()

func validate_hurdle_path(start_position: Vector3, target_position: Vector3, arc_height: float) -> bool:
	var sample_count: int = max(hurdle_path_samples, 4)
	var previous_position: Vector3 = start_position
	if not is_capsule_position_clear(start_position):
		return false
	for sample_index: int in range(1, sample_count + 1):
		var progress: float = float(sample_index) / float(sample_count)
		var sample_position: Vector3 = calculate_hurdle_position_from_data(
			start_position,
			target_position,
			progress,
			arc_height
		)
		if not is_capsule_position_clear(sample_position):
			return false
		if not validate_capsule_motion(previous_position, sample_position):
			return false
		previous_position = sample_position
	return true

func validate_mantle_path(start_position: Vector3, lift_position: Vector3, target_position: Vector3) -> bool:
	if not is_capsule_position_clear(start_position):
		return false
	if not validate_capsule_motion(start_position, lift_position):
		return false
	var sample_count: int = max(hurdle_path_samples, 4)
	var previous_position: Vector3 = lift_position
	if not is_capsule_position_clear(lift_position):
		return false
	for sample_index: int in range(1, sample_count + 1):
		var progress: float = float(sample_index) / float(sample_count)
		var eased_progress: float = smoothstep(0.0, 1.0, progress)
		var sample_position: Vector3 = lift_position.lerp(target_position, eased_progress)
		if not is_capsule_position_clear(sample_position):
			return false
		if not validate_capsule_motion(previous_position, sample_position):
			return false
		previous_position = sample_position
	return true

func validate_capsule_motion(start_position: Vector3, end_position: Vector3) -> bool:
	if not is_capsule_position_clear(start_position) or not is_capsule_position_clear(end_position):
		return false
	var motion: Vector3 = end_position - start_position
	if motion.length_squared() <= clearance_segment_tolerance * clearance_segment_tolerance:
		return true
	clearance_query.motion = motion
	clearance_query.transform = get_capsule_transform(start_position)
	clearance_query.margin = 0.0
	var cast_result: PackedFloat32Array = player.get_world_3d().direct_space_state.cast_motion(clearance_query)
	clearance_query.motion = Vector3.ZERO
	if cast_result.size() < 1:
		return false
	return cast_result[0] >= 0.999

func is_capsule_position_clear(test_position: Vector3) -> bool:
	clearance_query.transform = get_capsule_transform(test_position)
	clearance_query.motion = Vector3.ZERO
	clearance_query.margin = 0.0
	var hits: Array[Dictionary] = player.get_world_3d().direct_space_state.intersect_shape(
		clearance_query,
		1
	)
	return hits.is_empty()

func get_capsule_transform(player_position: Vector3) -> Transform3D:
	return Transform3D(
		Basis.IDENTITY,
		player_position + Vector3.UP * standing_capsule_shape.height * 0.5
	)

func capsule_radius_from_shape() -> float:
	return standing_capsule_shape.radius

func calculate_hurdle_target(obstacle_data: Dictionary) -> Vector3:
	var obstacle_height_value: float = obstacle_data["obstacle_height"] as float
	var front_position: Vector3 = obstacle_data["front_position"] as Vector3
	var top_position: Vector3 = obstacle_data["top_position"] as Vector3
	var top_normal: Vector3 = obstacle_data["top_normal"] as Vector3
	var landing_data: Dictionary = {}
	var detected_landing_position: Vector3 = obstacle_data.get("landing_position", Vector3.ZERO) as Vector3
	var detected_landing_normal: Vector3 = obstacle_data.get("landing_normal", Vector3.UP) as Vector3
	if not detected_landing_position.is_zero_approx():
		landing_data = {
			"position": detected_landing_position,
			"normal": detected_landing_normal
		}
	else:
		landing_data = find_landing_surface(front_position, obstacle_data["normal"] as Vector3, top_position.y)
	if obstacle_height_value < hurdle_min_height or obstacle_height_value > hurdle_max_height:
		return Vector3.ZERO
	if not is_surface_angle_valid(top_normal, hurdle_min_surface_angle, hurdle_max_surface_angle):
		return Vector3.ZERO
	if landing_data.is_empty():
		return Vector3.ZERO
	var landing_position: Vector3 = landing_data["position"] as Vector3
	var target_position: Vector3 = landing_position
	var total_horizontal_offset: Vector3 = target_position - player.global_position
	total_horizontal_offset.y = 0.0
	var total_horizontal_distance: float = total_horizontal_offset.length()
	if total_horizontal_distance < hurdle_min_distance or total_horizontal_distance > hurdle_max_distance:
		return Vector3.ZERO
	var entry_horizontal: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var entry_direction: Vector3 = entry_horizontal.normalized()
	if entry_horizontal.length_squared() <= 0.001:
		entry_direction = get_traversal_direction()
	if entry_direction.length_squared() <= 0.001:
		return Vector3.ZERO
	var landing_position_offset: Vector3 = target_position - player.global_position
	landing_position_offset.y = 0.0
	var forward_distance: float = landing_position_offset.dot(entry_direction)
	if forward_distance <= 0.0:
		return Vector3.ZERO
	var influenced_entry_speed: float = entry_horizontal.length() * hurdle_entry_speed_influence
	var landing_speed: float = max(
		influenced_entry_speed,
		hurdle_min_speed
	)
	landing_speed = lerp(
		hurdle_min_speed,
		landing_speed,
		hurdle_speed_influence
	) * hurdle_speed_multiplier
	landing_speed = max(landing_speed, hurdle_min_speed)
	var runtime_duration: float = clamp(
		total_horizontal_distance / max(landing_speed, 0.001),
		hurdle_min_duration,
		hurdle_max_duration
	)
	var capsule_clearance_distance: float = capsule_radius_from_shape() + hurdle_clearance_margin
	var front_progress_distance: float = (
		max((front_position - player.global_position).dot(entry_direction), 0.0)
		+ capsule_clearance_distance
	)
	var top_progress_distance: float = (
		max((top_position - player.global_position).dot(entry_direction), 0.0)
		+ capsule_clearance_distance
	)
	var front_progress: float = clamp(
		front_progress_distance / max(total_horizontal_distance, 0.001),
		0.05,
		0.95
	)
	var top_progress: float = clamp(
		top_progress_distance / max(total_horizontal_distance, 0.001),
		0.05,
		0.95
	)
	var peak_progress: float = 0.5
	var path_floor_y: float = lerp(player.global_position.y, target_position.y, peak_progress)
	var obstacle_clearance_world_y: float = (
		player.global_position.y
		+ obstacle_height_value
		+ hurdle_clearance_height
		+ hurdle_clearance_margin
	)
	var required_peak_height: float = obstacle_clearance_world_y - path_floor_y
	var front_baseline_y: float = lerp(player.global_position.y, target_position.y, front_progress)
	var front_required_height: float = obstacle_clearance_world_y - front_baseline_y
	var top_baseline_y: float = lerp(player.global_position.y, target_position.y, top_progress)
	var top_required_height: float = obstacle_clearance_world_y - top_baseline_y
	var required_arc_height: float = max(
		required_peak_height,
		front_required_height / max(hurdle_arc_profile(front_progress), 0.001),
		top_required_height / max(hurdle_arc_profile(top_progress), 0.001)
	)
	var arc_height: float = clamp(
		max(hurdle_min_arc_height, hurdle_arc_height, required_arc_height),
		hurdle_min_arc_height,
		hurdle_max_arc_height
	)
	if arc_height + 0.001 < required_arc_height:
		return Vector3.ZERO
	var desired_crossing_position: Vector3 = top_position + Vector3.UP * hurdle_clearance_height
	if not is_capsule_position_clear(target_position):
		return Vector3.ZERO
	if hurdle_path_validation:
		if not validate_hurdle_path(player.global_position, target_position, arc_height):
			return Vector3.ZERO
	hurdle_target_position = target_position
	hurdle_landing_position = target_position
	hurdle_crossing_position = desired_crossing_position
	hurdle_arc_height_value = arc_height
	hurdle_runtime_duration = runtime_duration
	return target_position

func calculate_mantle_target(obstacle_data: Dictionary) -> Vector3:
	var obstacle_height_value: float = obstacle_data["obstacle_height"] as float
	var top_position: Vector3 = obstacle_data["top_position"] as Vector3
	var top_normal: Vector3 = obstacle_data["top_normal"] as Vector3
	var wall_normal_value: Vector3 = obstacle_data["normal"] as Vector3
	if obstacle_height_value < mantle_min_height or obstacle_height_value > mantle_max_height:
		return Vector3.ZERO
	if not is_surface_angle_valid(top_normal, mantle_min_surface_angle, mantle_max_surface_angle):
		return Vector3.ZERO
	var top_target_data: Dictionary = find_mantle_top_target(
		obstacle_data["front_position"] as Vector3,
		wall_normal_value,
		top_position.y
	)
	if top_target_data.is_empty():
		return Vector3.ZERO
	var safe_top_position: Vector3 = top_target_data["position"] as Vector3
	var safe_top_normal: Vector3 = top_target_data["normal"] as Vector3
	var target_position: Vector3 = safe_top_position + safe_top_normal * mantle_target_offset
	if abs(target_position.y - player.global_position.y - obstacle_height_value) > mantle_surface_tolerance:
		target_position.y = player.global_position.y + obstacle_height_value + mantle_target_offset
	if not is_capsule_position_clear(target_position):
		return Vector3.ZERO
	var lift_direction: Vector3 = wall_normal_value
	lift_direction.y = 0.0
	if lift_direction.length_squared() <= 0.001:
		lift_direction = -get_traversal_direction()
		lift_direction.y = 0.0
	if lift_direction.length_squared() <= 0.001:
		return Vector3.ZERO
	lift_direction = lift_direction.normalized()
	var lift_position: Vector3 = player.global_position + lift_direction * (
		standing_capsule_shape.radius + mantle_wall_clearance
	)
	lift_position.y = safe_top_position.y + max(mantle_clearance_height, mantle_height * 0.04)
	if not validate_mantle_path(player.global_position, lift_position, target_position):
		return Vector3.ZERO
	mantle_lift_position = lift_position
	mantle_target_position = target_position
	return target_position

func find_mantle_top_target(front_position: Vector3, front_normal: Vector3, top_height: float) -> Dictionary:
	var search_distance: float = min(
		max(mantle_forward_distance, mantle_top_min_forward_distance),
		max(mantle_top_search_distance, mantle_top_min_forward_distance)
	)
	var minimum_distance: float = max(mantle_top_min_forward_distance, clearance_segment_tolerance)
	var search_step: float = max(top_surface_probe_spacing, clearance_segment_tolerance)
	var horizontal_direction: Vector3 = -front_normal
	horizontal_direction.y = 0.0
	if horizontal_direction.length_squared() <= 0.001:
		return {}
	horizontal_direction = horizontal_direction.normalized()
	while search_distance >= minimum_distance:
		var probe_point: Vector3 = front_position + horizontal_direction * search_distance
		var probe_origin: Vector3 = Vector3(
			probe_point.x,
			player.global_position.y + mantle_max_height + top_surface_probe_height,
			probe_point.z
		)
		var probe_end: Vector3 = Vector3(
			probe_point.x,
			player.global_position.y - traversal_vertical_tolerance,
			probe_point.z
		)
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			probe_origin,
			probe_end,
			traversal_collision_mask,
			[player.get_rid()]
		)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var hit_position: Vector3 = hit.get("position", probe_end) as Vector3
			var hit_normal: Vector3 = hit.get("normal", Vector3.ZERO) as Vector3
			var hit_height: float = hit_position.y - player.global_position.y
			if abs(hit_height - (top_height - player.global_position.y)) <= mantle_surface_tolerance + traversal_vertical_tolerance:
				if is_surface_angle_valid(hit_normal, mantle_min_surface_angle, mantle_max_surface_angle):
					return {
						"position": hit_position,
						"normal": hit_normal
					}
		search_distance -= search_step
	return {}

func find_landing_surface(front_position: Vector3, front_normal: Vector3, top_height: float) -> Dictionary:
	var landing_direction: Vector3 = -front_normal
	landing_direction.y = 0.0
	if landing_direction.length_squared() <= 0.001:
		return {}
	landing_direction = landing_direction.normalized()
	var minimum_probe_distance: float = max(
		hurdle_landing_clearance_distance,
		standing_capsule_shape.radius + hurdle_clearance_margin
	)
	var probe_distance: float = minimum_probe_distance
	var search_distance: float = max(hurdle_landing_search_distance, probe_distance)
	var vertical_search_distance: float = max(
		mantle_max_height + top_surface_probe_height,
		landing_vertical_search_extra + mantle_max_height
	)
	while probe_distance <= search_distance:
		var probe_point: Vector3 = front_position + landing_direction * probe_distance
		var probe_origin: Vector3 = probe_point + Vector3.UP * vertical_search_distance
		var probe_end: Vector3 = probe_point - Vector3.UP * traversal_vertical_search_distance()
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			probe_origin,
			probe_end,
			traversal_collision_mask,
			[player.get_rid()]
		)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var hit_position: Vector3 = hit.get("position", probe_end) as Vector3
			var hit_normal: Vector3 = hit.get("normal", Vector3.UP) as Vector3
			if hit_position.y <= top_height - hurdle_landing_tolerance and is_walkable_surface(hit_normal):
				return {
					"position": hit_position + Vector3.UP * hurdle_clearance_margin,
					"normal": hit_normal
				}
		probe_distance += max(hurdle_landing_probe_spacing, clearance_segment_tolerance)
	return {}

func traversal_vertical_search_distance() -> float:
	return max(traversal_vertical_tolerance, landing_vertical_search_extra)

func calculate_hurdle_velocity(progress: float, duration: float) -> Vector3:
	var clamped_progress: float = clamp(progress, 0.0, 1.0)
	var safe_duration: float = max(duration, 0.001)
	var horizontal_delta: Vector3 = hurdle_landing_position - traversal_start_position
	horizontal_delta.y = 0.0
	var horizontal_velocity: Vector3 = horizontal_delta / safe_duration
	var baseline_vertical_velocity: float = (
		hurdle_landing_position.y - traversal_start_position.y
	) / safe_duration
	var profile_derivative: float = hurdle_arc_profile_derivative(clamped_progress)
	var vertical_velocity: float = (
		baseline_vertical_velocity
		+ hurdle_arc_height_value * profile_derivative / safe_duration
	)
	return Vector3(
		horizontal_velocity.x,
		vertical_velocity,
		horizontal_velocity.z
	)

func calculate_hurdle_position(progress: float) -> Vector3:
	return calculate_hurdle_position_from_data(
		traversal_start_position,
		hurdle_landing_position,
		progress,
		hurdle_arc_height_value
	)

func calculate_hurdle_position_from_data(
	start_position: Vector3,
	target_position: Vector3,
	progress: float,
	arc_height: float
) -> Vector3:
	var clamped_progress: float = clamp(progress, 0.0, 1.0)
	var horizontal_position: Vector3 = start_position.lerp(target_position, clamped_progress)
	var baseline_height: float = lerp(
		start_position.y,
		target_position.y,
		clamped_progress
	)
	var vertical_offset: float = arc_height * hurdle_arc_profile(clamped_progress)
	return Vector3(
		horizontal_position.x,
		baseline_height + vertical_offset,
		horizontal_position.z
	)

func hurdle_arc_profile(progress: float) -> float:
	var clamped_progress: float = clamp(progress, 0.0, 1.0)
	var base_value: float = 4.0 * clamped_progress * (1.0 - clamped_progress)
	if base_value <= 0.0:
		return 0.0
	return pow(base_value, hurdle_arc_profile_exponent)

func hurdle_arc_profile_derivative(progress: float) -> float:
	var clamped_progress: float = clamp(progress, 0.0, 1.0)
	var base_value: float = 4.0 * clamped_progress * (1.0 - clamped_progress)
	if base_value <= 0.0:
		return 0.0
	var base_derivative: float = 4.0 - 8.0 * clamped_progress
	return hurdle_arc_profile_exponent * pow(
		base_value,
		hurdle_arc_profile_exponent - 1.0
	) * base_derivative

func start_traversal(traversal_target_data: Dictionary) -> void:
	@warning_ignore("int_as_enum_without_cast")
	traversal_type = int(traversal_target_data["type"])
	traversal_target_position = traversal_target_data["target_position"] as Vector3
	traversal_start_position = player.global_position
	traversal_start_velocity = player.velocity
	var horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	traversal_entry_direction = horizontal_velocity.normalized()
	if horizontal_velocity.length_squared() <= 0.001:
		traversal_entry_direction = get_traversal_direction()
	if traversal_entry_direction.length_squared() <= 0.001:
		traversal_entry_direction = -player.global_transform.basis.z
		traversal_entry_direction.y = 0.0
		traversal_entry_direction = traversal_entry_direction.normalized()
	traversal_target_distance = traversal_start_position.distance_to(traversal_target_position)
	traversal_elapsed = 0.0
	traversal_progress = 0.0
	traversal_phase = TraversalPhase.ASCENDING
	traversal_active = true
	hurdle_path_validation_timer = max(hurdle_path_validation_interval, 0.001)
	scramble_wall_revalidation_timer = 0.0
	scramble_path_validation_timer = max(scramble_path_validation_interval, 0.001)
	scramble_ledge_check_timer = 0.0
	scramble_elapsed_time = 0.0
	scramble_distance_traveled = 0.0
	traversal_path_direction = traversal_entry_direction
	player_movement.jump_buffer_timer = 0.0
	if traversal_type == TraversalType.HURDLE:
		hurdle_target_position = traversal_target_position
		player_state.change_state(PlayerState.MovementState.HURDLING)
		hurdle_started.emit(traversal_target_position)
	elif traversal_type == TraversalType.MANTLE:
		mantle_target_position = traversal_target_position
		if traversal_target_data.has("mantle_lift_position"):
			mantle_lift_position = traversal_target_data["mantle_lift_position"] as Vector3
		player_state.change_state(PlayerState.MovementState.MANTLING)
		mantle_started.emit(traversal_target_position)
	elif traversal_type == TraversalType.WALL_SCRAMBLING:
		scramble_start_position = traversal_start_position
		scramble_wall_normal = traversal_target_data.get("wall_normal", Vector3.ZERO) as Vector3
		scramble_wall_contact_position = traversal_target_data.get("wall_position", Vector3.ZERO) as Vector3
		scramble_wall_rid = traversal_target_data.get("wall_rid", RID()) as RID
		scramble_wall_distance_value = traversal_target_data.get("wall_distance", 0.0) as float
		scramble_entry_tangent_velocity = horizontal_velocity.slide(scramble_wall_normal) * scramble_entry_momentum_preservation
		scramble_target_position = traversal_target_position
	if scramble_wall_normal.length_squared() <= 0.001:
		cancel_traversal()
		return
		player.velocity.y = max(
			player.velocity.y,
			min(scramble_upward_speed, scramble_max_vertical_speed)
		)
		player_state.change_state(PlayerState.MovementState.WALL_SCRAMBLING)
		scramble_started.emit(scramble_wall_contact_position)

func get_current_duration() -> float:
	if traversal_type == TraversalType.HURDLE:
		return max(hurdle_runtime_duration, hurdle_min_duration)
	if traversal_type == TraversalType.MANTLE:
		var horizontal_duration: float = traversal_target_distance / max(mantle_pull_speed, 0.1)
		var vertical_duration: float = max(obstacle_height, mantle_height) / max(mantle_vertical_speed, 0.1)
		return max(mantle_duration, horizontal_duration, vertical_duration)
	if traversal_type == TraversalType.WALL_SCRAMBLING:
		return max(scramble_max_duration, scramble_min_duration)
	return 0.001

func calculate_mantle_position(progress: float) -> Vector3:
	if progress < 0.48:
		var lift_progress: float = smoothstep(0.0, 1.0, progress / 0.48)
		return traversal_start_position.lerp(mantle_lift_position, lift_progress)
	var cross_progress: float = smoothstep(0.0, 1.0, (progress - 0.48) / 0.52)
	return mantle_lift_position.lerp(mantle_target_position, cross_progress)

func apply_hurdle_steering(delta: float) -> void:
	var input_direction: Vector3 = player_movement.get_movement_direction()
	if input_direction.length_squared() <= 0.001:
		return
	var current_horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var current_speed: float = current_horizontal_velocity.length()
	if current_speed <= 0.001:
		return
	var current_direction: Vector3 = current_horizontal_velocity.normalized()
	var steering_weight: float = clamp(
		hurdle_steering_strength * hurdle_steering_response * delta,
		0.0,
		1.0
	)
	var steered_direction: Vector3 = current_direction.slerp(
		input_direction.normalized(),
		steering_weight
	)
	if steered_direction.length_squared() <= 0.001:
		return
	steered_direction = steered_direction.normalized()
	var allowed_direction: Vector3 = traversal_entry_direction
	var steering_angle: float = rad_to_deg(
		traversal_entry_direction.angle_to(steered_direction)
	)
	if steering_angle > hurdle_max_steering_angle:
		var steering_blend: float = clamp(
			hurdle_max_steering_angle / max(steering_angle, 0.001),
			0.0,
			1.0
		)
		allowed_direction = traversal_entry_direction.slerp(
			steered_direction,
			steering_blend
		).normalized()
	else:
		allowed_direction = steered_direction
	player.velocity.x = allowed_direction.x * current_speed
	player.velocity.z = allowed_direction.z * current_speed

func apply_traversal_steering(delta: float) -> void:
	if traversal_type == TraversalType.HURDLE:
		apply_hurdle_steering(delta)
		return
	var input_direction: Vector3 = player_movement.get_movement_direction()
	if input_direction.length_squared() <= 0.001:
		return
	var current_horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var speed: float = current_horizontal_velocity.length()
	if speed <= 0.001:
		return
	var steering_amount: float = clamp(
		traversal_camera_lateral_response * delta,
		0.0,
		1.0
	)
	var steered_direction: Vector3 = current_horizontal_velocity.normalized().slerp(
		input_direction.normalized(),
		steering_amount * 0.4
	).normalized()
	player.velocity.x = steered_direction.x * speed
	player.velocity.z = steered_direction.z * speed

func calculate_exit_velocity() -> Vector3:
	var incoming_horizontal_velocity: Vector3 = Vector3(
		traversal_start_velocity.x,
		0.0,
		traversal_start_velocity.z
	)
	var incoming_speed: float = incoming_horizontal_velocity.length()
	var current_horizontal_velocity: Vector3 = Vector3(
		player.velocity.x,
		0.0,
		player.velocity.z
	)
	var current_speed: float = current_horizontal_velocity.length()
	var current_direction: Vector3 = current_horizontal_velocity.normalized()
	if current_speed <= 0.001:
		current_direction = traversal_entry_direction
	if traversal_type == TraversalType.WALL_SCRAMBLING:
		var scramble_exit_direction: Vector3 = current_direction
		if scramble_exit_direction.length_squared() <= 0.001:
			scramble_exit_direction = traversal_entry_direction
		var scramble_push_direction: Vector3 = scramble_wall_normal
		if scramble_push_direction.length_squared() <= 0.001:
			scramble_push_direction = traversal_entry_direction
		var scramble_exit_direction_blend: float = clamp(scramble_exit_direction_influence, 0.0, 1.0)
		scramble_exit_direction = scramble_exit_direction.slerp(
			scramble_push_direction.normalized(),
			scramble_exit_direction_blend
		).normalized()
		var preserved_scramble_speed: float = max(
			current_speed * scramble_exit_momentum_preservation,
			incoming_speed * scramble_entry_momentum_preservation * scramble_exit_momentum_preservation
		)
		var scramble_exit_speed: float = preserved_scramble_speed * scramble_exit_speed_multiplier
		return Vector3(
			scramble_exit_direction.x * scramble_exit_speed,
			0.0,
			scramble_exit_direction.z * scramble_exit_speed
		)
	var target_direction: Vector3 = Vector3(
		traversal_target_position.x - traversal_start_position.x,
		0.0,
		traversal_target_position.z - traversal_start_position.z
	)
	if target_direction.length_squared() <= 0.001:
		target_direction = traversal_entry_direction
	else:
		target_direction = target_direction.normalized()
	var exit_direction_influence: float = 0.35
	if traversal_type == TraversalType.HURDLE:
		exit_direction_influence = hurdle_exit_direction_influence
	var exit_direction: Vector3 = current_direction.slerp(
		target_direction,
		exit_direction_influence
	)
	if exit_direction.length_squared() <= 0.001:
		exit_direction = target_direction
	else:
		exit_direction = exit_direction.normalized()
	var exit_speed: float = current_speed
	if traversal_type == TraversalType.HURDLE:
		var preserved_incoming_speed: float = incoming_speed * hurdle_entry_speed_influence * hurdle_momentum_preservation
		exit_speed = max(exit_speed * hurdle_momentum_preservation, preserved_incoming_speed)
		exit_speed *= hurdle_exit_speed_multiplier
		exit_speed = max(exit_speed, hurdle_min_speed)
	else:
		var preserved_mantle_speed: float = incoming_speed * mantle_momentum_preservation * traversal_entry_speed_influence
		exit_speed = max(exit_speed * mantle_momentum_preservation, preserved_mantle_speed)
		exit_speed *= traversal_momentum_preservation
		exit_speed = max(exit_speed, mantle_exit_velocity)
		exit_speed *= traversal_exit_speed_multiplier
	return Vector3(
		exit_direction.x * exit_speed,
		0.0,
		exit_direction.z * exit_speed
	)

func complete_traversal() -> void:
	if not traversal_active:
		return
	var completed_type: TraversalType = traversal_type
	var exit_velocity: Vector3 = calculate_exit_velocity()
	var blend_weight: float = clamp(
		traversal_exit_blend_time / max(get_current_duration(), 0.001),
		0.0,
		1.0
	)
	player.velocity.x = lerp(player.velocity.x, exit_velocity.x, blend_weight)
	player.velocity.z = lerp(player.velocity.z, exit_velocity.z, blend_weight)
	if player.is_on_floor():
		player.velocity.y = 0.0
	reset_traversal_runtime()
	if player.is_on_floor():
		player_state.change_state(PlayerState.MovementState.GROUNDED)
	else:
		player_state.change_state(PlayerState.MovementState.AIRBORNE)
	traversal_completed.emit(completed_type)

func cancel_traversal() -> void:
	if not traversal_active:
		return
	var cancelled_type: TraversalType = traversal_type
	player.velocity.x *= traversal_cancel_velocity_multiplier
	player.velocity.z *= traversal_cancel_velocity_multiplier
	if player.is_on_ceiling() and player.velocity.y > 0.0:
		player.velocity.y = 0.0
	reset_traversal_runtime()
	if player.is_on_floor():
		player_state.change_state(PlayerState.MovementState.GROUNDED)
	else:
		player_state.change_state(PlayerState.MovementState.AIRBORNE)
	traversal_cancelled.emit(cancelled_type)

func release_traversal() -> void:
	if not traversal_active:
		return
	var released_type: TraversalType = traversal_type
	var exit_velocity: Vector3 = calculate_exit_velocity()
	player.velocity.x = exit_velocity.x
	player.velocity.z = exit_velocity.z
	if player.velocity.y > 0.0:
		player.velocity.y = 0.0
	reset_traversal_runtime()
	if player.is_on_floor():
		player_state.change_state(PlayerState.MovementState.GROUNDED)
	else:
		player_state.change_state(PlayerState.MovementState.AIRBORNE)
	traversal_completed.emit(released_type)

func reset_traversal_runtime() -> void:
	traversal_active = false
	traversal_progress = 0.0
	traversal_elapsed = 0.0
	traversal_phase = TraversalPhase.INACTIVE
	traversal_type = TraversalType.NONE
	traversal_target_position = Vector3.ZERO
	hurdle_target_position = Vector3.ZERO
	hurdle_landing_position = Vector3.ZERO
	hurdle_crossing_position = Vector3.ZERO
	hurdle_arc_height_value = 0.0
	hurdle_runtime_duration = 0.0
	mantle_target_position = Vector3.ZERO
	mantle_lift_position = Vector3.ZERO
	scramble_start_position = Vector3.ZERO
	scramble_wall_normal = Vector3.ZERO
	scramble_wall_contact_position = Vector3.ZERO
	scramble_wall_rid = RID()
	scramble_wall_distance_value = 0.0
	scramble_entry_tangent_velocity = Vector3.ZERO
	scramble_target_position = Vector3.ZERO
	scramble_ledge_target_position = Vector3.ZERO
	scramble_ledge_target_normal = Vector3.UP
	scramble_wall_top_position = Vector3.ZERO
	scramble_wall_top_normal = Vector3.UP
	scramble_elapsed_time = 0.0
	scramble_distance_traveled = 0.0

func update_traversal_phase() -> void:
	if traversal_progress < 0.35:
		traversal_phase = TraversalPhase.ASCENDING
	elif traversal_progress < 0.72:
		traversal_phase = TraversalPhase.CROSSING
	elif traversal_progress < 0.94:
		traversal_phase = TraversalPhase.LANDING
	else:
		traversal_phase = TraversalPhase.EXITING

func is_traversing() -> bool:
	return traversal_active

func is_hurdling() -> bool:
	return traversal_active and traversal_type == TraversalType.HURDLE

func is_mantling() -> bool:
	return traversal_active and traversal_type == TraversalType.MANTLE

func is_wall_scrambling() -> bool:
	return traversal_active and traversal_type == TraversalType.WALL_SCRAMBLING

func get_traversal_direction() -> Vector3:
	var camera_direction: Vector3 = get_camera_forward()
	var movement_direction: Vector3 = player_movement.get_movement_direction()
	var velocity_direction: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	if velocity_direction.length_squared() > 0.001:
		velocity_direction = velocity_direction.normalized()
	var traversal_direction: Vector3 = camera_direction * 0.35
	if movement_direction.length_squared() > 0.001:
		traversal_direction += movement_direction * 0.35
	if velocity_direction.length_squared() > 0.001:
		traversal_direction += velocity_direction * 0.3
	traversal_direction.y = 0.0
	if traversal_direction.length_squared() <= 0.001:
		return Vector3.ZERO
	return traversal_direction.normalized()

func get_camera_forward() -> Vector3:
	var camera_forward: Vector3 = -camera.global_transform.basis.z
	camera_forward.y = 0.0
	if camera_forward.length_squared() <= 0.001:
		camera_forward = -player.global_transform.basis.z
		camera_forward.y = 0.0
	if camera_forward.length_squared() <= 0.001:
		return Vector3.ZERO
	return camera_forward.normalized()

func is_walkable_surface(surface_normal: Vector3) -> bool:
	return surface_angle_degrees(surface_normal) <= player_movement.maximum_walkable_slope_angle

func is_surface_angle_valid(surface_normal: Vector3, minimum_angle: float, maximum_angle: float) -> bool:
	var surface_angle: float = surface_angle_degrees(surface_normal)
	return surface_angle >= minimum_angle and surface_angle <= maximum_angle

func surface_angle_degrees(surface_normal: Vector3) -> float:
	if surface_normal.length_squared() <= 0.001:
		return 90.0
	return rad_to_deg(
		acos(
			clamp(
				surface_normal.normalized().dot(Vector3.UP),
				-1.0,
				1.0
			)
		)
	)

func update_debug_state() -> void:
	if not debug_print_traversal_state and not debug_print_scramble_state:
		return
	var state_name: StringName = get_traversal_state_name()
	if state_name == last_debug_state:
		return
	last_debug_state = state_name
	print("Traversal: ", state_name)

func get_traversal_state_name() -> StringName:
	if not traversal_active:
		return &"INACTIVE"
	if traversal_type == TraversalType.HURDLE:
		return StringName("HURDLING_" + str(traversal_phase))
	if traversal_type == TraversalType.MANTLE:
		return StringName("MANTLING_" + str(traversal_phase))
	if traversal_type == TraversalType.WALL_SCRAMBLING:
		return StringName("SCRAMBLING_" + str(traversal_phase))
	return &"UNKNOWN"

func get_camera_position_offset() -> Vector3:
	if not traversal_active:
		return Vector3.ZERO
	if traversal_type == TraversalType.HURDLE:
		var height_weight: float = clamp(
			obstacle_height / max(hurdle_max_height, 0.001),
			0.0,
			1.0
		)
		var envelope: float = hurdle_arc_profile(traversal_progress) * height_weight
		return Vector3(
			0.0,
			envelope * hurdle_camera_offset,
			-envelope * hurdle_camera_offset * 0.4
		)
	if traversal_type == TraversalType.WALL_SCRAMBLING:
		var vertical_speed_ratio: float = clamp(
			max(player.velocity.y, 0.0) / max(scramble_max_vertical_speed, 0.001),
			0.0,
			1.0
		)
		var scramble_envelope: float = smoothstep(0.0, 1.0, traversal_progress)
		var scramble_amount: float = scramble_envelope * vertical_speed_ratio * scramble_camera_vertical_influence
		return Vector3(
			0.0,
			scramble_amount * scramble_camera_offset,
			0.0
		)
	var mantle_envelope: float = smoothstep(0.0, 1.0, traversal_progress)
	return Vector3(
		0.0,
		mantle_envelope * mantle_camera_offset,
		-mantle_envelope * mantle_camera_offset * 0.35
	)

func get_camera_pitch_offset() -> float:
	if not traversal_active:
		return 0.0
	if traversal_type == TraversalType.HURDLE:
		var height_weight: float = clamp(
			obstacle_height / max(hurdle_max_height, 0.001),
			0.0,
			1.0
		)
		var reference_velocity: float = max(
			hurdle_arc_height_value / max(hurdle_runtime_duration, 0.001),
			0.1
		)
		var vertical_ratio: float = clamp(
			player.velocity.y / reference_velocity,
			-1.0,
			1.0
		)
		return -vertical_ratio * hurdle_camera_pitch * height_weight
	if traversal_type == TraversalType.WALL_SCRAMBLING:
		var vertical_ratio: float = clamp(
			player.velocity.y / max(scramble_max_vertical_speed, 0.001),
			-1.0,
			1.0
		)
		return -vertical_ratio * scramble_camera_pitch
	return -smoothstep(0.0, 1.0, traversal_progress) * mantle_camera_pitch

func get_camera_roll_offset() -> float:
	if not traversal_active:
		return 0.0
	var lateral_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var lateral_amount: float = lateral_velocity.dot(player.global_transform.basis.x)
	if traversal_type == TraversalType.WALL_SCRAMBLING:
		var wall_lateral_amount: float = scramble_wall_normal.dot(player.global_transform.basis.x)
		return clamp(
			wall_lateral_amount * scramble_camera_roll + lateral_amount * 0.01,
			-scramble_camera_roll,
			scramble_camera_roll
		)
	var maximum_roll: float = hurdle_camera_roll
	var roll_multiplier: float = 0.02
	if traversal_type == TraversalType.MANTLE:
		maximum_roll = mantle_camera_roll
		roll_multiplier = 0.012
	return clamp(lateral_amount * roll_multiplier, -maximum_roll, maximum_roll)

func get_camera_fov_boost() -> float:
	if not traversal_active:
		return 0.0
	if traversal_type == TraversalType.HURDLE:
		var height_weight: float = clamp(
			obstacle_height / max(hurdle_max_height, 0.001),
			0.0,
			1.0
		)
		var envelope: float = hurdle_arc_profile(traversal_progress) * height_weight
		var response_weight: float = 1.0 - exp(-hurdle_fov_response * traversal_progress)
		var return_weight: float = 1.0 - exp(-hurdle_fov_return * (1.0 - traversal_progress))
		return traversal_fov_boost + hurdle_fov_boost * envelope * response_weight * return_weight
	if traversal_type == TraversalType.WALL_SCRAMBLING:
		var vertical_speed_ratio: float = clamp(
			max(player.velocity.y, 0.0) / max(scramble_max_vertical_speed, 0.001),
			0.0,
			1.0
		)
		var speed_weight: float = clamp(
			vertical_speed_ratio * scramble_fov_speed_influence,
			0.0,
			1.0
		)
		var response_weight: float = 1.0 - exp(-scramble_fov_response * traversal_progress)
		var return_weight: float = 1.0 - exp(-scramble_fov_return * (1.0 - traversal_progress))
		return traversal_fov_boost + scramble_fov_boost * speed_weight * response_weight * return_weight
	var mantle_envelope: float = smoothstep(0.0, 1.0, traversal_progress)
	return traversal_fov_boost + mantle_fov_boost * mantle_envelope

func get_camera_spring_frequency() -> float:
	if not traversal_active:
		var return_frequency: float = max(
			traversal_camera_return_frequency,
			hurdle_camera_return_speed
		)
		return max(
			max(return_frequency, mantle_camera_return_speed),
			scramble_camera_return_speed
		)
	if traversal_type == TraversalType.HURDLE:
		return max(traversal_camera_spring_frequency, hurdle_camera_response_speed)
	if traversal_type == TraversalType.WALL_SCRAMBLING:
		return max(traversal_camera_spring_frequency, scramble_camera_response_speed)
	return max(traversal_camera_spring_frequency, mantle_camera_response_speed)

func get_camera_position_response() -> float:
	if not traversal_active:
		return traversal_camera_return_frequency
	if traversal_type == TraversalType.HURDLE:
		return traversal_camera_vertical_response
	if traversal_type == TraversalType.WALL_SCRAMBLING:
		return scramble_camera_response_speed
	return traversal_camera_lateral_response

func update_debug_geometry() -> void:
	if debug_immediate_mesh == null or debug_material == null:
		return
	var debug_enabled: bool = is_debug_geometry_enabled()
	if not debug_enabled:
		debug_immediate_mesh.clear_surfaces()
		return
	debug_immediate_mesh.clear_surfaces()
	debug_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, debug_material)
	if debug_draw_traversal_rays:
		draw_debug_rays()
	if debug_draw_traversal_target and traversal_target_position != Vector3.ZERO:
		draw_debug_segment(player.global_position, traversal_target_position)
	if debug_draw_hurdle_target and hurdle_landing_position != Vector3.ZERO:
		draw_debug_cross(hurdle_landing_position, hurdle_landing_tolerance)
	if debug_draw_mantle_target and mantle_target_position != Vector3.ZERO:
		draw_debug_cross(mantle_target_position, mantle_target_offset + clearance_segment_tolerance)
	if debug_draw_hurdle_path and traversal_active and traversal_type == TraversalType.HURDLE:
		draw_debug_hurdle_path()
	if debug_draw_scramble_wall_rays:
		draw_debug_scramble_wall_rays()
	if debug_draw_scramble_wall_normal and scramble_wall_contact_position != Vector3.ZERO:
		draw_debug_segment(
			scramble_wall_contact_position,
			scramble_wall_contact_position + scramble_wall_normal * scramble_wall_stick_force * 0.04
		)
	if debug_draw_scramble_ledge_target and scramble_ledge_target_position != Vector3.ZERO:
		draw_debug_cross(scramble_ledge_target_position, mantle_target_offset + clearance_segment_tolerance)
	if debug_draw_scramble_clearance:
		if scramble_ledge_target_position != Vector3.ZERO:
			draw_debug_capsule(scramble_ledge_target_position)
		if mantle_lift_position != Vector3.ZERO:
			draw_debug_capsule(mantle_lift_position)
	if debug_draw_scramble_capsule:
		draw_debug_capsule(player.global_position)
	if debug_draw_scramble_path and scramble_start_position != Vector3.ZERO:
		draw_debug_segment(scramble_start_position, player.global_position)
		if scramble_target_position != Vector3.ZERO:
			draw_debug_segment(player.global_position, scramble_target_position)
	debug_immediate_mesh.surface_end()

func draw_debug_rays() -> void:
	var traversal_direction: Vector3 = get_traversal_direction()
	if traversal_direction.length_squared() <= 0.001:
		return
	var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	var detection_distance: float = clamp(
		traversal_forward_detection_distance + horizontal_speed * traversal_speed_distance_influence,
		0.5,
		max(hurdle_max_distance, mantle_detection_distance)
	)
	var center_origin: Vector3 = player.global_position + Vector3.UP * traversal_forward_detection_height
	draw_debug_segment(center_origin, center_origin + traversal_direction * detection_distance)
	if obstacle_front_position != Vector3.ZERO:
		draw_debug_segment(
			obstacle_front_position,
			obstacle_front_position + obstacle_normal * capsule_radius_from_shape()
		)
	if obstacle_top_position != Vector3.ZERO:
		draw_debug_segment(
			obstacle_top_position,
			obstacle_top_position + obstacle_top_normal * capsule_radius_from_shape()
		)
	if hurdle_landing_position != Vector3.ZERO:
		draw_debug_segment(
			hurdle_landing_position,
			hurdle_landing_position + landing_surface_normal * capsule_radius_from_shape()
		)

func draw_debug_scramble_wall_rays() -> void:
	var detection_direction: Vector3 = get_scramble_detection_direction()
	if detection_direction.length_squared() <= 0.001:
		return
	var probe_heights: Array[float] = [
		front_probe_low_height,
		front_probe_mid_height,
		traversal_forward_detection_height
	]
	var probe_count: int = clamp(scramble_probe_count, 1, probe_heights.size())
	for probe_index: int in range(probe_count):
		var probe_origin: Vector3 = player.global_position + Vector3.UP * probe_heights[probe_index]
		draw_debug_segment(
			probe_origin,
			probe_origin + detection_direction * scramble_detection_distance
		)

func draw_debug_hurdle_path() -> void:
	var sample_count: int = max(hurdle_path_samples, 2)
	var previous_position: Vector3 = calculate_hurdle_position(0.0)
	for sample_index: int in range(1, sample_count + 1):
		var progress: float = float(sample_index) / float(sample_count)
		var sample_position: Vector3 = calculate_hurdle_position(progress)
		draw_debug_segment(previous_position, sample_position)
		previous_position = sample_position
	draw_debug_cross(hurdle_crossing_position, hurdle_clearance_height)

func draw_debug_segment(start_position: Vector3, end_position: Vector3) -> void:
	debug_immediate_mesh.surface_add_vertex(debug_mesh_instance.to_local(start_position))
	debug_immediate_mesh.surface_add_vertex(debug_mesh_instance.to_local(end_position))

func draw_debug_cross(center_position: Vector3, size: float) -> void:
	var safe_size: float = max(size, clearance_segment_tolerance)
	draw_debug_segment(center_position - Vector3.RIGHT * safe_size, center_position + Vector3.RIGHT * safe_size)
	draw_debug_segment(center_position - Vector3.UP * safe_size, center_position + Vector3.UP * safe_size)
	draw_debug_segment(center_position - Vector3.FORWARD * safe_size, center_position + Vector3.FORWARD * safe_size)

func draw_debug_capsule(player_position: Vector3) -> void:
	var radius: float = standing_capsule_shape.radius
	var cylinder_height: float = max(standing_capsule_shape.height - radius * 2.0, 0.0)
	var bottom_center: Vector3 = player_position + Vector3.UP * radius
	var top_center: Vector3 = player_position + Vector3.UP * (radius + cylinder_height)
	var segment_count: int = 12
	for segment_index: int in range(segment_count):
		var angle_a: float = TAU * float(segment_index) / float(segment_count)
		var angle_b: float = TAU * float(segment_index + 1) / float(segment_count)
		var offset_a: Vector3 = Vector3(cos(angle_a) * radius, 0.0, sin(angle_a) * radius)
		var offset_b: Vector3 = Vector3(cos(angle_b) * radius, 0.0, sin(angle_b) * radius)
		draw_debug_segment(bottom_center + offset_a, bottom_center + offset_b)
		draw_debug_segment(top_center + offset_a, top_center + offset_b)
		draw_debug_segment(bottom_center + offset_a, top_center + offset_a)
