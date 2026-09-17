class_name PlayerTraversal
extends Node

signal hurdle_started(hurdle_target_position: Vector3)
signal mantle_started(mantle_target_position: Vector3)
signal traversal_completed(traversal_type: TraversalType)
signal traversal_cancelled(traversal_type: TraversalType)
signal traversal_failed(traversal_type: TraversalType)

enum TraversalType {
	NONE,
	HURDLE,
	MANTLE
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
@export var traversal_forward_detection_distance: float = 2.0
@export var traversal_forward_detection_height: float = 1.35
@export_range(0.0, 1.0, 0.01) var traversal_direction_threshold: float = 0.38
@export var minimum_traversal_distance: float = 0.35
@export var maximum_traversal_distance: float = 3.4
@export var traversal_height_tolerance: float = 0.08
@export var traversal_target_forgiveness: float = 0.12
@export var traversal_horizontal_tolerance: float = 0.35
@export var traversal_vertical_tolerance: float = 0.18
@export var traversal_speed_distance_influence: float = 0.06
@export var allow_airborne_mantle: bool = true
@export var airborne_mantle_max_vertical_velocity: float = 2.0

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

@export_group("Hurdling")
@export var hurdle_duration: float = 0.28
@export var hurdle_height: float = 1.05
@export var hurdle_forward_distance: float = 0.9
@export var hurdle_forward_speed: float = 10.5
@export var hurdle_vertical_speed: float = 4.5
@export var hurdle_acceleration: float = 36.0
@export var hurdle_exit_velocity: float = 10.0
@export_range(0.0, 1.0, 0.01) var hurdle_momentum_preservation: float = 0.9
@export var hurdle_momentum_multiplier: float = 1.0
@export var hurdle_exit_momentum_multiplier: float = 1.0
@export var hurdle_speed_influence: float = 0.9
@export var hurdle_entry_speed_influence: float = 1.0
@export var hurdle_air_control: float = 0.45
@export var hurdle_steering_strength: float = 1.5
@export var hurdle_steering_response: float = 7.0
@export_range(0.0, 89.0, 0.1) var hurdle_max_steering_angle: float = 28.0
@export var hurdle_landing_search_distance: float = 2.5
@export var hurdle_landing_probe_spacing: float = 0.25
@export var hurdle_obstacle_clearance: float = 0.12
@export var hurdle_landing_height_tolerance: float = 0.12

@export_group("Mantling")
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
@export var clearance_margin: float = 0.015
@export var clearance_path_samples: int = 6
@export var clearance_segment_tolerance: float = 0.04
@export var traversal_target_revalidation_interval: float = 0.08
@export var standing_clearance_height_multiplier: float = 1.0

@export_group("Momentum")
@export_range(0.0, 1.0, 0.01) var traversal_momentum_preservation: float = 0.9
@export var traversal_exit_speed_multiplier: float = 1.0
@export_range(0.0, 1.0, 0.01) var traversal_exit_direction_influence: float = 0.35
@export var traversal_entry_speed_influence: float = 1.0

@export_group("Timing")
@export var traversal_completion_tolerance: float = 0.08
@export var traversal_cancel_velocity_multiplier: float = 0.92
@export var traversal_exit_blend_time: float = 0.08
@export var traversal_early_exit_progress: float = 0.94

@export_group("Camera")
@export var hurdle_camera_pitch: float = 2.0
@export var hurdle_camera_roll: float = 1.1
@export var hurdle_camera_offset: float = 0.035
@export var hurdle_camera_fov: float = 2.5
@export var hurdle_camera_response_speed: float = 18.0
@export var hurdle_camera_return_speed: float = 14.0
@export var mantle_camera_pitch: float = 3.2
@export var mantle_camera_roll: float = 0.8
@export var mantle_camera_offset: float = 0.055
@export var mantle_camera_fov: float = 1.7
@export var mantle_camera_response_speed: float = 13.0
@export var mantle_camera_return_speed: float = 11.0

@export_group("Camera Smoothing")
@export var traversal_camera_spring_frequency: float = 18.0
@export var traversal_camera_return_frequency: float = 12.0
@export var traversal_camera_vertical_response: float = 14.0
@export var traversal_camera_lateral_response: float = 10.0

@export_group("FOV")
@export var traversal_fov_boost: float = 0.5
@export var hurdle_fov_boost: float = 2.0
@export var mantle_fov_boost: float = 1.2
@export var traversal_fov_response: float = 16.0
@export var traversal_fov_return: float = 12.0

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
@export var debug_print_traversal_state: bool = false

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
var traversal_target_revalidation_timer: float = 0.0
var traversal_start_position: Vector3 = Vector3.ZERO
var traversal_start_velocity: Vector3 = Vector3.ZERO
var traversal_target_position: Vector3 = Vector3.ZERO
var hurdle_target_position: Vector3 = Vector3.ZERO
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
	if debug_draw_traversal_rays or debug_draw_traversal_shapes or debug_draw_traversal_target or debug_draw_hurdle_target or debug_draw_mantle_target:
		debug_mesh_instance = MeshInstance3D.new()
		debug_immediate_mesh = ImmediateMesh.new()
		debug_material = StandardMaterial3D.new()
		debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		debug_material.no_depth_test = true
		debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		debug_material.albedo_color = Color(0.1, 0.9, 1.0, 0.85)
		debug_mesh_instance.mesh = debug_immediate_mesh
		add_child(debug_mesh_instance)

func _physics_process(_delta: float) -> void:
	update_debug_state()

func _process(_delta: float) -> void:
	update_debug_geometry()

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
	traversal_elapsed += delta
	var current_duration: float = get_current_duration()
	traversal_progress = clamp(traversal_elapsed / max(current_duration, 0.001), 0.0, 1.0)
	update_traversal_phase()
	var desired_position: Vector3 = calculate_traversal_position(traversal_progress)
	var desired_motion: Vector3 = desired_position - player.global_position
	var desired_velocity: Vector3 = Vector3.ZERO
	if delta > 0.000001:
		desired_velocity = desired_motion / delta
	var traversal_acceleration: float = hurdle_acceleration
	if traversal_type == TraversalType.MANTLE:
		traversal_acceleration = mantle_acceleration
	var entry_horizontal_velocity: Vector3 = Vector3(traversal_start_velocity.x, 0.0, traversal_start_velocity.z)
	var momentum_speed: float = entry_horizontal_velocity.length() * traversal_entry_speed_influence
	var momentum_direction: Vector3 = traversal_entry_direction
	if entry_horizontal_velocity.length_squared() > 0.001:
		momentum_direction = entry_horizontal_velocity.normalized()
	var desired_horizontal: Vector3 = Vector3(desired_velocity.x, 0.0, desired_velocity.z)
	if momentum_speed > desired_horizontal.length() and momentum_direction.length_squared() > 0.001:
		desired_horizontal = momentum_direction * momentum_speed
	var blended_velocity: Vector3 = Vector3(desired_horizontal.x, desired_velocity.y, desired_horizontal.z)
	player.velocity = player.velocity.move_toward(blended_velocity, traversal_acceleration * delta)
	apply_traversal_steering(delta)
	if traversal_progress >= traversal_early_exit_progress:
		player.velocity = Vector3(
			desired_velocity.x,
			desired_velocity.y,
			desired_velocity.z
		)
	traversal_path_direction = Vector3(player.velocity.x, 0.0, player.velocity.z)
	if traversal_path_direction.length_squared() > 0.001:
		traversal_path_direction = traversal_path_direction.normalized()
	traversal_target_revalidation_timer = max(traversal_target_revalidation_timer - delta, 0.0)
	if traversal_target_revalidation_timer <= 0.0:
		traversal_target_revalidation_timer = max(traversal_target_revalidation_interval, 0.001)
		if not is_capsule_position_clear(traversal_target_position):
			cancel_traversal()

func process_physics_post_movement(_delta: float) -> void:
	if not traversal_active:
		return
	if player.is_on_ceiling():
		cancel_traversal()
		return
	if traversal_progress < 1.0:
		return
	var target_distance: float = player.global_position.distance_to(traversal_target_position)
	if target_distance > traversal_completion_tolerance:
		if player.get_slide_collision_count() > 0:
			cancel_traversal()
		return
	complete_traversal()

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
	if obstacle_data.is_empty():
		return {}
	obstacle_front_position = obstacle_data["front_position"] as Vector3
	obstacle_normal = obstacle_data["normal"] as Vector3
	obstacle_top_position = obstacle_data["top_position"] as Vector3
	obstacle_top_normal = obstacle_data["top_normal"] as Vector3
	obstacle_height = obstacle_data["obstacle_height"] as float
	landing_surface_normal = obstacle_data["landing_normal"] as Vector3
	if player.is_on_floor() or player_state.is_sliding():
		var hurdle_target_position: Vector3 = calculate_hurdle_target(obstacle_data)
		if not hurdle_target_position.is_zero_approx():
			return {
				"type": TraversalType.HURDLE,
				"target_position": hurdle_target_position
			}
	var mantle_target_position: Vector3 = calculate_mantle_target(obstacle_data)
	if not mantle_target_position.is_zero_approx():
		return {
			"type": TraversalType.MANTLE,
			"target_position": mantle_target_position
		}
	return {}

func detect_obstacle() -> Dictionary:
	var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	var detection_distance: float = clamp(
		traversal_forward_detection_distance + horizontal_speed * traversal_speed_distance_influence,
		minimum_traversal_distance,
		maximum_traversal_distance
	)
	var traversal_direction: Vector3 = get_traversal_direction()
	if traversal_direction.length_squared() <= 0.001:
		return {}
	var camera_forward: Vector3 = get_camera_forward()
	var best_front_hit: Dictionary = {}
	var best_score: float = INF
	var probe_heights: Array[float] = [
		front_probe_low_height,
		front_probe_mid_height,
		traversal_forward_detection_height
	]
	var probe_count: int = clamp(obstacle_probe_count, 1, probe_heights.size())
	var lateral_offset: float = min(front_probe_lateral_offset, max(traversal_horizontal_tolerance, 0.0))
	for probe_index: int in range(probe_count):
		var probe_height: float = probe_heights[probe_index]
		var lateral_offsets: Array[float] = [0.0]
		if probe_index < 2 and lateral_offset > 0.0:
			lateral_offsets = [0.0, lateral_offset, -lateral_offset]
		for lateral_probe_offset: float in lateral_offsets:
			var probe_origin: Vector3 = (
				player.global_position
				+ Vector3.UP * probe_height
				+ player.global_transform.basis.x * lateral_probe_offset
			)
			var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
				probe_origin,
				probe_origin + traversal_direction * detection_distance,
				traversal_collision_mask,
				[player.get_rid()]
			)
			query.collide_with_areas = false
			query.collide_with_bodies = true
			var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty():
				continue
			var hit_normal: Vector3 = hit.get("normal", Vector3.ZERO) as Vector3
			if abs(hit_normal.y) > wall_normal_vertical_limit:
				continue
			var hit_position: Vector3 = hit.get("position", probe_origin) as Vector3
			var approach_dot: float = traversal_direction.dot(-hit_normal)
			var angle_to_wall: float = rad_to_deg(acos(clamp(approach_dot, -1.0, 1.0)))
			if approach_dot < traversal_direction_threshold or angle_to_wall > traversal_max_angle:
				continue
			var front_distance: float = player.global_position.distance_to(hit_position)
			var camera_dot: float = camera_forward.dot(-hit_normal)
			var camera_assist: float = 0.0
			if traversal_assist_enabled and camera_dot >= cos(deg_to_rad(traversal_assist_angle)) and front_distance <= detection_distance + traversal_assist_distance:
				camera_assist = traversal_assist_strength
			var score: float = front_distance - camera_assist
			if score < best_score:
				best_score = score
				best_front_hit = {
					"position": hit_position,
					"normal": hit_normal
				}
	if best_front_hit.is_empty():
		return {}
	var front_position: Vector3 = best_front_hit["position"] as Vector3
	var front_normal: Vector3 = best_front_hit["normal"] as Vector3
	var top_data: Dictionary = find_top_surface(front_position, front_normal)
	if top_data.is_empty():
		return {}
	var top_position: Vector3 = top_data["position"] as Vector3
	var top_normal: Vector3 = top_data["normal"] as Vector3
	var obstacle_height_value: float = top_position.y - player.global_position.y
	var top_surface_angle: float = surface_angle_degrees(top_normal)
	if obstacle_height_value < hurdle_min_height - traversal_height_tolerance:
		return {}
	if obstacle_height_value > mantle_max_height + traversal_height_tolerance:
		return {}
	if top_surface_angle > max(mantle_max_surface_angle, hurdle_max_surface_angle) + surface_angle_tolerance:
		return {}
	var target_distance: float = player.global_position.distance_to(top_position)
	if target_distance < minimum_traversal_distance - traversal_target_forgiveness:
		return {}
	if target_distance > maximum_traversal_distance + traversal_target_forgiveness:
		return {}
	var landing_data: Dictionary = find_landing_surface(front_position, front_normal, top_position.y)
	var landing_normal: Vector3 = Vector3.UP
	if not landing_data.is_empty():
		landing_normal = landing_data["normal"] as Vector3
	return {
		"front_position": front_position,
		"normal": front_normal,
		"top_position": top_position,
		"top_normal": top_normal,
		"obstacle_height": obstacle_height_value,
		"landing_normal": landing_normal
	}

func find_top_surface(front_position: Vector3, front_normal: Vector3) -> Dictionary:
	var probe_count: int = max(top_surface_probe_count, 1)
	for probe_index: int in range(probe_count):
		var probe_offset: float = top_surface_probe_forward_offset + probe_index * top_surface_probe_spacing
		var probe_point: Vector3 = front_position - front_normal * probe_offset
		var probe_origin: Vector3 = Vector3(
			probe_point.x,
			player.global_position.y + mantle_max_height + top_surface_probe_height,
			probe_point.z
		)
		var probe_end: Vector3 = probe_origin - Vector3.UP * (
			mantle_max_height + top_surface_probe_height + traversal_height_tolerance
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
		if hit.is_empty():
			continue
		var hit_position: Vector3 = hit.get("position", probe_end) as Vector3
		var hit_normal: Vector3 = hit.get("normal", Vector3.ZERO) as Vector3
		var hit_height: float = hit_position.y - player.global_position.y
		var surface_angle: float = surface_angle_degrees(hit_normal)
		if hit_height < hurdle_min_height - traversal_height_tolerance or hit_height > mantle_max_height + traversal_height_tolerance:
			continue
		if surface_angle > max(mantle_max_surface_angle, hurdle_max_surface_angle) + surface_angle_tolerance:
			continue
		return {
			"position": hit_position,
			"normal": hit_normal
		}
	return {}

func find_landing_surface(front_position: Vector3, front_normal: Vector3, top_height: float) -> Dictionary:
	var start_distance: float = max(hurdle_forward_distance, capsule_radius_from_shape() + clearance_margin)
	var search_distance: float = max(hurdle_landing_search_distance, start_distance)
	var probe_distance: float = start_distance
	var floor_height_limit: float = top_height - hurdle_landing_height_tolerance
	while probe_distance <= search_distance:
		var probe_point: Vector3 = front_position - front_normal * probe_distance
		var probe_origin: Vector3 = probe_point + Vector3.UP * (mantle_max_height + top_surface_probe_height)
		var probe_end: Vector3 = probe_origin - Vector3.UP * (
			mantle_max_height + top_surface_probe_height + traversal_vertical_search_distance()
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
			if hit_position.y <= floor_height_limit and is_walkable_surface(hit_normal):
				return {
					"position": hit_position,
					"normal": hit_normal
				}
		probe_distance += max(hurdle_landing_probe_spacing, clearance_segment_tolerance)
	return {}

func traversal_vertical_search_distance() -> float:
	return max(traversal_vertical_tolerance, landing_vertical_search_extra)

func calculate_hurdle_target(obstacle_data: Dictionary) -> Vector3:
	var obstacle_height_value: float = obstacle_data["obstacle_height"] as float
	var top_normal: Vector3 = obstacle_data["top_normal"] as Vector3
	if obstacle_height_value < hurdle_min_height or obstacle_height_value > hurdle_max_height:
		return Vector3.ZERO
	if not is_surface_angle_valid(top_normal, hurdle_min_surface_angle, hurdle_max_surface_angle):
		return Vector3.ZERO
	var landing_data: Dictionary = find_landing_surface(
		obstacle_data["front_position"] as Vector3,
		obstacle_data["normal"] as Vector3,
		obstacle_data["top_position"].y
	)
	if landing_data.is_empty():
		return Vector3.ZERO
	var landing_position: Vector3 = landing_data["position"] as Vector3
	var landing_normal_value: Vector3 = landing_data["normal"] as Vector3
	var target_position: Vector3 = landing_position + landing_normal_value * mantle_target_offset
	if not is_capsule_position_clear(target_position):
		return Vector3.ZERO
	var clear_peak_height: float = max(
		hurdle_height,
		obstacle_height_value + hurdle_obstacle_clearance + standing_capsule_shape.radius
	)
	var vertical_speed_height: float = hurdle_vertical_speed * get_hurdle_duration()
	clear_peak_height = max(clear_peak_height, vertical_speed_height * 0.5)
	if not validate_hurdle_path(player.global_position, target_position, clear_peak_height):
		return Vector3.ZERO
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
	var lift_position: Vector3 = player.global_position + wall_normal_value * (
		capsule_radius_from_shape() + mantle_wall_clearance
	)
	lift_position.y = safe_top_position.y + max(mantle_clearance_height, mantle_height * 0.04)
	if not validate_mantle_path(player.global_position, lift_position, target_position):
		return Vector3.ZERO
	mantle_lift_position = lift_position
	return target_position

func find_mantle_top_target(front_position: Vector3, front_normal: Vector3, top_height: float) -> Dictionary:
	var search_distance: float = min(
		max(mantle_forward_distance, mantle_top_min_forward_distance),
		max(mantle_top_search_distance, mantle_top_min_forward_distance)
	)
	var minimum_distance: float = max(mantle_top_min_forward_distance, clearance_margin)
	var search_step: float = max(top_surface_probe_spacing, clearance_segment_tolerance)
	while search_distance >= minimum_distance:
		var probe_point: Vector3 = front_position - front_normal * search_distance
		var probe_origin: Vector3 = Vector3(
			probe_point.x,
			player.global_position.y + mantle_max_height + top_surface_probe_height,
			probe_point.z
		)
		var probe_end: Vector3 = probe_origin - Vector3.UP * (
			mantle_max_height + top_surface_probe_height + traversal_height_tolerance
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
			var hit_height: float = hit_position.y - player.global_position.y
			if abs(hit_height - (top_height - player.global_position.y)) <= mantle_surface_tolerance + traversal_vertical_tolerance:
				if is_surface_angle_valid(hit_normal, mantle_min_surface_angle, mantle_max_surface_angle):
					return {
						"position": hit_position,
						"normal": hit_normal
					}
		search_distance -= search_step
	return {}

func validate_hurdle_path(start_position: Vector3, target_position: Vector3, peak_height: float) -> bool:
	var sample_count: int = max(clearance_path_samples, 3)
	var previous_position: Vector3 = start_position
	for sample_index: int in range(1, sample_count + 1):
		var progress: float = float(sample_index) / float(sample_count)
		var eased_progress: float = smoothstep(0.0, 1.0, progress)
		var horizontal_position: Vector3 = start_position.lerp(target_position, eased_progress)
		var vertical_arc: float = sin(progress * PI) * peak_height
		var sample_position: Vector3 = Vector3(
			horizontal_position.x,
			lerp(start_position.y, target_position.y, eased_progress) + vertical_arc,
			horizontal_position.z
		)
		if not validate_capsule_motion(previous_position, sample_position):
			return false
		previous_position = sample_position
	return true

func validate_mantle_path(start_position: Vector3, lift_position: Vector3, target_position: Vector3) -> bool:
	if not validate_capsule_motion(start_position, lift_position):
		return false
	var sample_count: int = max(clearance_path_samples, 3)
	var previous_position: Vector3 = lift_position
	for sample_index: int in range(1, sample_count + 1):
		var progress: float = float(sample_index) / float(sample_count)
		var eased_progress: float = smoothstep(0.0, 1.0, progress)
		var sample_position: Vector3 = lift_position.lerp(target_position, eased_progress)
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
	var cast_result: PackedFloat32Array = player.get_world_3d().direct_space_state.cast_motion(clearance_query)
	clearance_query.motion = Vector3.ZERO
	if cast_result.size() < 1:
		return false
	return cast_result[0] >= 0.999

func is_capsule_position_clear(test_position: Vector3) -> bool:
	clearance_query.transform = get_capsule_transform(test_position)
	clearance_query.motion = Vector3.ZERO
	var hits: Array[Dictionary] = player.get_world_3d().direct_space_state.intersect_shape(clearance_query, 1)
	return hits.is_empty()

func get_capsule_transform(player_position: Vector3) -> Transform3D:
	return Transform3D(
		Basis.IDENTITY,
		player_position + Vector3.UP * standing_capsule_shape.height * 0.5
	)

func capsule_radius_from_shape() -> float:
	return standing_capsule_shape.radius

func get_traversal_direction() -> Vector3:
	var camera_direction: Vector3 = get_camera_forward()
	var movement_direction: Vector3 = player_movement.get_movement_direction()
	var velocity_direction: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	if velocity_direction.length_squared() > 0.001:
		velocity_direction = velocity_direction.normalized()
	var traversal_direction: Vector3 = camera_direction * 0.4
	if movement_direction.length_squared() > 0.001:
		traversal_direction += movement_direction * 0.35
	if velocity_direction.length_squared() > 0.001:
		traversal_direction += velocity_direction * 0.25
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
	return camera_forward.normalized()

func start_traversal(traversal_target_data: Dictionary) -> void:
	traversal_type = int(traversal_target_data["type"])
	traversal_target_position = traversal_target_data["target_position"] as Vector3
	traversal_start_position = player.global_position
	traversal_start_velocity = player.velocity
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
	traversal_target_revalidation_timer = max(traversal_target_revalidation_interval, 0.001)
	traversal_path_direction = traversal_entry_direction
	player_movement.consume_jump_for_traversal()
	if traversal_type == TraversalType.HURDLE:
		hurdle_target_position = traversal_target_position
		player_state.change_state(PlayerState.MovementState.HURDLING)
		hurdle_started.emit(traversal_target_position)
	else:
		mantle_target_position = traversal_target_position
		player_state.change_state(PlayerState.MovementState.MANTLING)
		mantle_started.emit(traversal_target_position)

func update_traversal_phase() -> void:
	if traversal_progress < 0.38:
		traversal_phase = TraversalPhase.ASCENDING
	elif traversal_progress < 0.8:
		traversal_phase = TraversalPhase.CROSSING
	else:
		traversal_phase = TraversalPhase.LANDING

func get_current_duration() -> float:
	if traversal_type == TraversalType.HURDLE:
		return get_hurdle_duration()
	if traversal_type == TraversalType.MANTLE:
		var horizontal_duration: float = traversal_target_distance / max(mantle_pull_speed, 0.1)
		var vertical_duration: float = max(obstacle_height, mantle_height) / max(mantle_vertical_speed, 0.1)
		return max(mantle_duration, horizontal_duration, vertical_duration)
	return 0.001

func get_hurdle_duration() -> float:
	var speed_duration: float = traversal_target_distance / max(hurdle_forward_speed, 0.1)
	return max(hurdle_duration, speed_duration)

func calculate_traversal_position(progress: float) -> Vector3:
	if traversal_type == TraversalType.HURDLE:
		return calculate_hurdle_position(progress)
	if traversal_type == TraversalType.MANTLE:
		return calculate_mantle_position(progress)
	return player.global_position

func calculate_hurdle_position(progress: float) -> Vector3:
	var eased_progress: float = smoothstep(0.0, 1.0, progress)
	var horizontal_position: Vector3 = traversal_start_position.lerp(hurdle_target_position, eased_progress)
	var clear_peak_height: float = max(
		hurdle_height,
		obstacle_height + hurdle_obstacle_clearance + standing_capsule_shape.radius
	)
	var vertical_speed_height: float = hurdle_vertical_speed * get_hurdle_duration()
	clear_peak_height = max(clear_peak_height, vertical_speed_height * 0.5)
	return Vector3(
		horizontal_position.x,
		lerp(traversal_start_position.y, hurdle_target_position.y, eased_progress) + sin(progress * PI) * clear_peak_height,
		horizontal_position.z
	)

func calculate_mantle_position(progress: float) -> Vector3:
	if progress < 0.48:
		var lift_progress: float = smoothstep(0.0, 1.0, progress / 0.48)
		return traversal_start_position.lerp(mantle_lift_position, lift_progress)
	var cross_progress: float = smoothstep(0.0, 1.0, (progress - 0.48) / 0.52)
	return mantle_lift_position.lerp(mantle_target_position, cross_progress)

func apply_traversal_steering(delta: float) -> void:
	var input_direction: Vector3 = player_movement.get_movement_direction()
	if input_direction.length_squared() <= 0.001:
		return
	var path_direction: Vector3 = traversal_path_direction
	if path_direction.length_squared() <= 0.001:
		path_direction = traversal_entry_direction
	var projected_input: Vector3 = input_direction.slide(Vector3.UP)
	var steering_axis: Vector3 = projected_input.slide(path_direction)
	if steering_axis.length_squared() <= 0.001:
		return
	steering_axis = steering_axis.normalized()
	var steering_strength: float = hurdle_steering_strength * hurdle_air_control
	var steering_response: float = hurdle_steering_response
	var maximum_angle: float = hurdle_max_steering_angle
	if traversal_type == TraversalType.MANTLE:
		steering_strength *= 0.55
		steering_response = traversal_camera_lateral_response
		maximum_angle *= 0.6
	var current_horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var speed: float = max(current_horizontal_velocity.length(), traversal_min_speed)
	var steering_target: Vector3 = path_direction
	if current_horizontal_velocity.length_squared() > 0.001:
		steering_target = current_horizontal_velocity.normalized()
	steering_target = steering_target + steering_axis * steering_strength
	if steering_target.length_squared() <= 0.001:
		return
	steering_target = steering_target.normalized()
	var angle_to_path: float = rad_to_deg(path_direction.angle_to(steering_target))
	if angle_to_path > maximum_angle:
		var blend_amount: float = clamp(maximum_angle / max(angle_to_path, 0.001), 0.0, 1.0)
		steering_target = path_direction.slerp(steering_target, blend_amount).normalized()
	var target_horizontal_velocity: Vector3 = steering_target * speed
	player.velocity.x = move_toward(player.velocity.x, target_horizontal_velocity.x, steering_response * delta)
	player.velocity.z = move_toward(player.velocity.z, target_horizontal_velocity.z, steering_response * delta)

func calculate_exit_velocity() -> Vector3:
	var incoming_horizontal_velocity: Vector3 = Vector3(traversal_start_velocity.x, 0.0, traversal_start_velocity.z)
	var incoming_speed: float = incoming_horizontal_velocity.length() * traversal_entry_speed_influence
	var target_direction: Vector3 = Vector3(
		traversal_target_position.x - traversal_start_position.x,
		0.0,
		traversal_target_position.z - traversal_start_position.z
	)
	if target_direction.length_squared() <= 0.001:
		target_direction = traversal_entry_direction
	else:
		target_direction = target_direction.normalized()
	var exit_speed: float = traversal_exit_speed_multiplier
	if traversal_type == TraversalType.HURDLE:
		exit_speed *= hurdle_exit_velocity * hurdle_exit_momentum_multiplier
		incoming_speed *= hurdle_momentum_multiplier * hurdle_speed_influence
		incoming_speed *= hurdle_entry_speed_influence * hurdle_momentum_preservation
	else:
		exit_speed *= mantle_exit_velocity
		incoming_speed *= mantle_momentum_preservation
	var exit_direction: Vector3 = traversal_entry_direction.lerp(target_direction, traversal_exit_direction_influence)
	if exit_direction.length_squared() <= 0.001:
		exit_direction = target_direction
	else:
		exit_direction = exit_direction.normalized()
	var exit_speed_value: float = max(exit_speed, incoming_speed)
	return Vector3(
		exit_direction.x * exit_speed_value,
		0.0,
		exit_direction.z * exit_speed_value
	)

func complete_traversal() -> void:
	if not traversal_active:
		return
	var completed_type: TraversalType = traversal_type
	var exit_velocity: Vector3 = calculate_exit_velocity()
	var current_duration: float = get_current_duration()
	var blend_weight: float = clamp(traversal_exit_blend_time / max(current_duration, 0.001), 0.0, 1.0)
	player.velocity = player.velocity.lerp(exit_velocity, blend_weight)
	player.velocity.x *= traversal_momentum_preservation
	player.velocity.z *= traversal_momentum_preservation
	traversal_active = false
	traversal_progress = 1.0
	traversal_phase = TraversalPhase.EXITING
	traversal_type = TraversalType.NONE
	traversal_target_position = Vector3.ZERO
	if player.is_on_floor():
		player_state.change_state(PlayerState.MovementState.GROUNDED)
	else:
		player_state.change_state(PlayerState.MovementState.AIRBORNE)
	traversal_phase = TraversalPhase.INACTIVE
	traversal_completed.emit(completed_type)

func cancel_traversal() -> void:
	if not traversal_active:
		return
	var cancelled_type: TraversalType = traversal_type
	player.velocity.x *= traversal_cancel_velocity_multiplier
	player.velocity.z *= traversal_cancel_velocity_multiplier
	if player.is_on_ceiling() and player.velocity.y > 0.0:
		player.velocity.y = 0.0
	traversal_active = false
	traversal_progress = 0.0
	traversal_phase = TraversalPhase.INACTIVE
	traversal_type = TraversalType.NONE
	traversal_target_position = Vector3.ZERO
	if player.is_on_floor():
		player_state.change_state(PlayerState.MovementState.GROUNDED)
	else:
		player_state.change_state(PlayerState.MovementState.AIRBORNE)
	traversal_cancelled.emit(cancelled_type)

func is_traversing() -> bool:
	return traversal_active

func is_hurdling() -> bool:
	return traversal_active and traversal_type == TraversalType.HURDLE

func is_mantling() -> bool:
	return traversal_active and traversal_type == TraversalType.MANTLE

func get_camera_position_offset() -> Vector3:
	if not traversal_active:
		return Vector3.ZERO
	if traversal_type == TraversalType.HURDLE:
		var envelope: float = sin(traversal_progress * PI)
		var response: float = 1.0 - exp(-hurdle_camera_response_speed * traversal_progress)
		return Vector3(0.0, envelope * hurdle_camera_offset * response, -envelope * hurdle_camera_offset * 0.4)
	var mantle_envelope: float = smoothstep(0.0, 1.0, traversal_progress)
	var mantle_response: float = 1.0 - exp(-mantle_camera_response_speed * traversal_progress)
	return Vector3(0.0, mantle_envelope * mantle_camera_offset * mantle_response, -mantle_envelope * mantle_camera_offset * 0.35)

func get_camera_pitch_offset() -> float:
	if not traversal_active:
		return 0.0
	if traversal_type == TraversalType.HURDLE:
		return -sin(traversal_progress * PI) * hurdle_camera_pitch
	return -smoothstep(0.0, 1.0, traversal_progress) * mantle_camera_pitch

func get_camera_roll_offset() -> float:
	if not traversal_active:
		return 0.0
	var lateral_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var lateral_amount: float = lateral_velocity.dot(player.global_transform.basis.x)
	var maximum_roll: float = hurdle_camera_roll
	var roll_multiplier: float = 0.02
	if traversal_type == TraversalType.MANTLE:
		maximum_roll = mantle_camera_roll
		roll_multiplier = 0.012
	return clamp(lateral_amount * roll_multiplier, -maximum_roll, maximum_roll)

func get_camera_fov_boost() -> float:
	if not traversal_active:
		return 0.0
	var type_boost: float = hurdle_camera_fov + hurdle_fov_boost
	if traversal_type == TraversalType.MANTLE:
		type_boost = mantle_camera_fov + mantle_fov_boost
	var envelope: float = sin(traversal_progress * PI)
	var response_weight: float = 1.0 - exp(-traversal_fov_response * traversal_progress)
	var return_weight: float = 1.0 - exp(-traversal_fov_return * (1.0 - traversal_progress))
	return traversal_fov_boost + type_boost * envelope * response_weight * return_weight

func get_camera_spring_frequency() -> float:
	if not traversal_active:
		return traversal_camera_return_frequency
	if traversal_type == TraversalType.HURDLE:
		return max(traversal_camera_spring_frequency, hurdle_camera_response_speed)
	return max(traversal_camera_spring_frequency, mantle_camera_response_speed)

func get_camera_position_response() -> float:
	if not traversal_active:
		return traversal_camera_return_frequency
	if traversal_type == TraversalType.HURDLE:
		return traversal_camera_vertical_response
	return traversal_camera_lateral_response

func is_walkable_surface(surface_normal: Vector3) -> bool:
	return surface_angle_degrees(surface_normal) <= player_movement.maximum_walkable_slope_angle

func is_surface_angle_valid(surface_normal: Vector3, minimum_angle: float, maximum_angle: float) -> bool:
	var surface_angle: float = surface_angle_degrees(surface_normal)
	return surface_angle >= minimum_angle and surface_angle <= maximum_angle

func surface_angle_degrees(surface_normal: Vector3) -> float:
	if surface_normal.length_squared() <= 0.001:
		return 90.0
	return rad_to_deg(acos(clamp(surface_normal.normalized().dot(Vector3.UP), -1.0, 1.0)))

func update_debug_state() -> void:
	if not debug_print_traversal_state:
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
	return &"UNKNOWN"

func update_debug_geometry() -> void:
	if debug_immediate_mesh == null or debug_material == null:
		return
	if not debug_draw_traversal_rays and not debug_draw_traversal_shapes and not debug_draw_traversal_target and not debug_draw_hurdle_target and not debug_draw_mantle_target:
		debug_immediate_mesh.clear_surfaces()
		return
	debug_immediate_mesh.clear_surfaces()
	debug_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, debug_material)
	if debug_draw_traversal_rays:
		draw_debug_rays()
	if debug_draw_traversal_target:
		draw_debug_segment(player.global_position, traversal_target_position)
	if debug_draw_hurdle_target and not hurdle_target_position.is_zero_approx():
		draw_debug_cross(hurdle_target_position, hurdle_obstacle_clearance + clearance_margin)
	if debug_draw_mantle_target and not mantle_target_position.is_zero_approx():
		draw_debug_cross(mantle_target_position, mantle_obstacle_size())
	if debug_draw_traversal_shapes and not traversal_target_position.is_zero_approx():
		draw_debug_capsule(traversal_target_position)
	debug_immediate_mesh.surface_end()

func draw_debug_rays() -> void:
	var traversal_direction: Vector3 = get_traversal_direction()
	if traversal_direction.length_squared() <= 0.001:
		return
	var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	var detection_distance: float = clamp(
		traversal_forward_detection_distance + horizontal_speed * traversal_speed_distance_influence,
		minimum_traversal_distance,
		maximum_traversal_distance
	)
	var center_origin: Vector3 = player.global_position + Vector3.UP * traversal_forward_detection_height
	draw_debug_segment(center_origin, center_origin + traversal_direction * detection_distance)
	if obstacle_front_position != Vector3.ZERO:
		draw_debug_segment(obstacle_front_position, obstacle_front_position + obstacle_normal * capsule_radius_from_shape())
	if obstacle_top_position != Vector3.ZERO:
		draw_debug_segment(obstacle_top_position, obstacle_top_position + obstacle_top_normal * capsule_radius_from_shape())

func draw_debug_segment(start_position: Vector3, end_position: Vector3) -> void:
	debug_immediate_mesh.surface_set_color(debug_material.albedo_color)
	debug_immediate_mesh.surface_add_vertex(debug_mesh_instance.to_local(start_position))
	debug_immediate_mesh.surface_add_vertex(debug_mesh_instance.to_local(end_position))

func draw_debug_cross(center_position: Vector3, size: float) -> void:
	var safe_size: float = max(size, clearance_margin)
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
		if segment_index % 3 == 0:
			draw_debug_segment(bottom_center + offset_a, top_center + offset_a)

func mantle_obstacle_size() -> float:
	return max(mantle_target_offset + mantle_clearance_height, clearance_margin)
