class_name PlayerGrapple
extends Node

@export_group("Grapple")
@export var grapple_max_distance: float = 60.0
@export var grapple_target_radius: float = 0.35
@export_range(0.0, 30.0, 0.1) var grapple_angle_tolerance: float = 8.0
@export var grapple_surface_tolerance: float = 0.22
@export var grapple_min_distance: float = 2.0
@export var grapple_max_vertical_difference: float = 60.0
@export_flags_3d_physics var grapple_target_collision_mask: int = 1

@export_group("Targeting")
@export var grapple_exclusion_group: StringName = &"grapple_excluded"
@export var grapple_path_validation: bool = true
@export_range(0.0, 1.0, 0.01) var grapple_target_center_bias: float = 0.7
@export_range(0.0, 1.0, 0.01) var grapple_target_distance_bias: float = 0.15
@export var target_indicator_distance: float = 14.0
@export var target_indicator_scale: float = 1.0
@export var target_indicator_smoothing: float = 18.0
@export var show_grapple_target: bool = true

@export_group("Pull Movement")
@export var grapple_acceleration: float = 125.0
@export var grapple_max_speed: float = 44.0
@export var grapple_pull_strength: float = 90.0
@export var grapple_arrival_speed: float = 4.5
@export var grapple_completion_distance: float = 0.85
@export_range(0.0, 1.0, 0.01) var grapple_velocity_preservation: float = 0.3
@export_range(0.0, 1.0, 0.01) var grapple_momentum_influence: float = 0.35
@export_range(0.0, 2.0, 0.01) var grapple_air_control: float = 0.12
@export_range(0.0, 2.0, 0.01) var grapple_ground_control: float = 0.16
@export var grapple_minimum_pull_speed: float = 5.0
@export var grapple_momentum_speed_bonus: float = 3.0

@export_group("Momentum")
@export var grapple_tangent_speed_limit: float = 10.0
@export var grapple_control_response: float = 8.0
@export_range(0.0, 1.0, 0.01) var grapple_vertical_momentum_preservation: float = 0.45

@export_group("Arrival")
@export_range(0.0, 2.0, 0.01) var grapple_arrival_velocity: float = 1.0
@export_range(0.0, 2.0, 0.01) var grapple_exit_momentum: float = 1.0
@export var grapple_exit_boost: float = 0.5
@export var grapple_arrival_braking: float = 20.0
@export var grapple_arrival_smoothing_distance: float = 1.0

@export_group("Cancellation")
@export var grapple_can_cancel: bool = true
@export var grapple_cancel_input: StringName = &"jump"
@export var grapple_cancel_preserves_velocity: bool = true
@export var grapple_cancel_boost: float = 1.5

@export_group("Cooldown")
@export var grapple_cooldown: float = 0.25
@export var grapple_recovery_time: float = 0.15

@export_group("Camera")
@export_range(0.0, 15.0, 0.1) var grapple_camera_pitch: float = 2.5
@export_range(0.0, 15.0, 0.1) var grapple_camera_roll: float = 1.8
@export_range(0.0, 0.1, 0.001) var grapple_camera_sway: float = 0.01
@export_range(0.1, 20.0, 0.1) var grapple_camera_inertia: float = 1.6
@export_range(0.0, 0.15, 0.001) var grapple_camera_launch_amount: float = 0.045
@export_range(0.0, 0.15, 0.001) var grapple_camera_arrival_amount: float = 0.06
@export_range(0.1, 40.0, 0.1) var grapple_camera_response_speed: float = 12.0
@export_range(0.1, 40.0, 0.1) var grapple_camera_return_speed: float = 18.0
@export_range(0.0, 1.0, 0.01) var grapple_camera_target_influence: float = 0.0
@export_range(0.0, 45.0, 0.1) var grapple_camera_target_max_angle: float = 12.0
@export_range(0.1, 40.0, 0.1) var grapple_camera_target_response: float = 14.0

@export_group("FOV")
@export var grapple_fov_boost: float = 5.0
@export var grapple_fov_launch_speed: float = 18.0
@export var grapple_fov_return_speed: float = 16.0
@export var grapple_fov_maximum: float = 125.0
@export var grapple_fov_speed_influence: float = 8.0
@export var grapple_fov_distance_influence: float = 3.0

@export_group("Debug")
@export var debug_draw_grapple_target: bool = false
@export var debug_draw_grapple_path: bool = false
@export var debug_print_grapple_state: bool = false

@onready var player: Player = get_parent() as Player
@onready var player_input: PlayerInput = get_node("../PlayerInput") as PlayerInput
@onready var player_state: PlayerState = get_node("../PlayerState") as PlayerState
@onready var camera: Camera3D = get_node("../Head/CameraMotion/Camera3D") as Camera3D
@onready var camera_motion: Node3D = get_node("../Head/CameraMotion") as Node3D
@onready var player_collision_shape: CollisionShape3D = get_node("../CollisionShape3D") as CollisionShape3D
@onready var target_indicator: Node3D = get_node_or_null("TargetIndicator") as Node3D

var grapple_active: bool = false
var grapple_target_position: Vector3 = Vector3.ZERO
var grapple_target_normal: Vector3 = Vector3.UP
var grapple_target_collider: Node3D = null
var grapple_target_rid: RID = RID()
var grapple_start_position: Vector3 = Vector3.ZERO
var grapple_start_distance: float = 0.0
var grapple_velocity: Vector3 = Vector3.ZERO
var grapple_direction: Vector3 = Vector3.ZERO
var grapple_distance: float = 0.0
var grapple_target_speed: float = 0.0
var grapple_cooldown_timer: float = 0.0
var grapple_recovery_timer: float = 0.0
var grapple_exit_velocity: Vector3 = Vector3.ZERO
var grapple_exit_velocity_pending: bool = false
var grapple_camera_rotation_value: Vector3 = Vector3.ZERO
var grapple_camera_rotation_velocity: Vector3 = Vector3.ZERO
var grapple_camera_position_value: Vector3 = Vector3.ZERO
var grapple_camera_position_velocity: Vector3 = Vector3.ZERO
var grapple_camera_target_rotation: Vector3 = Vector3.ZERO
var grapple_fov_offset: float = 0.0
var grapple_camera_position_applied: Vector3 = Vector3.ZERO
var grapple_camera_rotation_applied: Vector3 = Vector3.ZERO
var grapple_fov_applied: float = 0.0
var grapple_launch_pulse: float = 0.0
var grapple_arrival_pulse: float = 0.0
var grapple_target_indicator_position: Vector3 = Vector3.ZERO
var grapple_target_indicator_scale_value: float = 1.0
var grapple_target_valid: bool = false
var grapple_last_debug_state: StringName = &""
var debug_mesh_instance: MeshInstance3D = null
var debug_immediate_mesh: ImmediateMesh = null
var debug_material: StandardMaterial3D = null

func _ready() -> void:
	if player == null or player_input == null or player_state == null or camera == null or camera_motion == null or player_collision_shape == null:
		return
	if target_indicator != null:
		target_indicator.visible = false
	configure_debug_geometry()

func process_physics_pre_movement(delta: float) -> void:
	grapple_cooldown_timer = max(grapple_cooldown_timer - delta, 0.0)
	grapple_recovery_timer = max(grapple_recovery_timer - delta, 0.0)
	if not grapple_active:
		update_target_preview()
		try_activate_grapple()
		if not grapple_active:
			return
	if grapple_active:
		if grapple_can_cancel and Input.is_action_just_pressed(grapple_cancel_input):
			cancel_grapple()
			return
		if not validate_active_grapple_target():
			cancel_grapple_without_boost()
			return
		update_grapple_motion(delta)

func process_physics_post_movement(_delta: float) -> void:
	if not grapple_active:
		return
	if player == null:
		return
	if player.global_position.distance_to(grapple_target_position) <= grapple_completion_distance:
		complete_grapple()
		return
	if player.get_slide_collision_count() > 0 and player.global_position.distance_to(grapple_start_position) > grapple_completion_distance:
		var current_distance: float = player.global_position.distance_to(grapple_target_position)
		if current_distance >= grapple_distance - 0.01:
			cancel_grapple_without_boost()

func _process(delta: float) -> void:
	if player == null or camera == null or camera_motion == null:
		return
	update_camera_feedback(delta)
	update_target_indicator(delta)
	update_debug_geometry()
	update_debug_state()

func try_activate_grapple() -> void:
	if not player_input.grapple_pressed:
		return
	if grapple_active or grapple_cooldown_timer > 0.0 or grapple_recovery_timer > 0.0:
		return
	var target_data: Dictionary = find_grapple_target(true)
	if target_data.is_empty():
		return
	grapple_target_position = target_data["position"] as Vector3
	grapple_target_normal = target_data["normal"] as Vector3
	grapple_target_collider = target_data["collider"] as Node3D
	grapple_target_rid = target_data["rid"] as RID
	grapple_start_position = player.global_position
	grapple_start_distance = max(player.global_position.distance_to(grapple_target_position), grapple_completion_distance)
	grapple_distance = grapple_start_distance
	grapple_direction = (grapple_target_position - player.global_position).normalized()
	var current_player_speed: float = player.velocity.length()
	grapple_target_speed = clamp(
		max(grapple_minimum_pull_speed, current_player_speed + grapple_momentum_speed_bonus),
		grapple_minimum_pull_speed,
		grapple_max_speed
	)
	var incoming_direction_speed: float = max(player.velocity.dot(grapple_direction), 0.0)
	var preserved_tangent_velocity: Vector3 = player.velocity.slide(grapple_direction)
	preserved_tangent_velocity *= grapple_velocity_preservation * grapple_momentum_influence
	if preserved_tangent_velocity.length() > grapple_tangent_speed_limit:
		preserved_tangent_velocity = preserved_tangent_velocity.normalized() * grapple_tangent_speed_limit
	grapple_velocity = grapple_direction * incoming_direction_speed + preserved_tangent_velocity
	grapple_active = true
	grapple_exit_velocity_pending = false
	grapple_launch_pulse = 1.0
	grapple_arrival_pulse = 0.0
	player_state.change_state(PlayerState.MovementState.GRAPPLING)

func find_grapple_target(allow_forgiving_probes: bool) -> Dictionary:
	if player == null or camera == null:
		return {}
	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var ray_origin: Vector3 = camera.global_position
	var camera_forward: Vector3 = -camera.global_transform.basis.z
	var camera_right: Vector3 = camera.global_transform.basis.x
	var camera_up: Vector3 = camera.global_transform.basis.y
	var best_target: Dictionary = {}
	var best_score: float = INF
	var center_result: Dictionary = perform_target_ray(space_state, ray_origin, camera_forward)
	if not center_result.is_empty():
		var center_target: Dictionary = build_valid_target(center_result, ray_origin, camera_forward)
		if not center_target.is_empty():
			best_target = center_target
			best_score = 0.0
	if allow_forgiving_probes and (best_target.is_empty() or best_score > 0.001):
		var angle_radians: float = deg_to_rad(grapple_angle_tolerance)
		var angle_offset: float = tan(angle_radians)
		var probe_offsets: Array[Vector2] = [Vector2(1.0, 0.0), Vector2(-1.0, 0.0), Vector2(0.0, 1.0), Vector2(0.0, -1.0)]
		for probe_offset: Vector2 in probe_offsets:
			var probe_direction: Vector3 = (camera_forward + camera_right * probe_offset.x * angle_offset + camera_up * probe_offset.y * angle_offset).normalized()
			var probe_result: Dictionary = perform_target_ray(space_state, ray_origin, probe_direction)
			if probe_result.is_empty():
				continue
			var probe_target: Dictionary = build_valid_target(probe_result, ray_origin, camera_forward)
			if probe_target.is_empty():
				continue
			var target_position: Vector3 = probe_target["position"] as Vector3
			var offset_distance: float = distance_from_ray(ray_origin, camera_forward, target_position)
			var angle_score: float = rad_to_deg(camera_forward.angle_to((target_position - ray_origin).normalized()))
			if offset_distance > grapple_target_radius * 2.5 and angle_score > grapple_angle_tolerance:
				continue
			var target_distance: float = player.global_position.distance_to(target_position)
			var distance_score: float = clamp(target_distance / max(grapple_max_distance, 0.001), 0.0, 1.0)
			var score: float = angle_score * grapple_target_center_bias + distance_score * grapple_target_distance_bias
			if score < best_score:
				best_score = score
				best_target = probe_target
	return best_target

func perform_target_ray(space_state: PhysicsDirectSpaceState3D, origin: Vector3, direction: Vector3) -> Dictionary:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction * grapple_max_distance,
		grapple_target_collision_mask,
		[player.get_rid()]
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return space_state.intersect_ray(query)

func build_valid_target(ray_result: Dictionary, ray_origin: Vector3, camera_forward: Vector3) -> Dictionary:
	if not ray_result.has("position") or not ray_result.has("normal") or not ray_result.has("collider") or not ray_result.has("rid"):
		return {}
	var collider: Object = ray_result["collider"] as Object
	var collider_node: Node3D = collider as Node3D
	if collider_node == null or not is_valid_grapple_collider(collider_node):
		return {}
	var hit_position: Vector3 = ray_result["position"] as Vector3
	var hit_normal: Vector3 = ray_result["normal"] as Vector3
	var target_position: Vector3 = calculate_attachment_position(hit_position, hit_normal)
	var player_distance: float = player.global_position.distance_to(target_position)
	if player_distance < grapple_min_distance or player_distance > grapple_max_distance:
		return {}
	if abs(target_position.y - player.global_position.y) > grapple_max_vertical_difference:
		return {}
	var aim_direction: Vector3 = (target_position - ray_origin).normalized()
	var aim_angle: float = rad_to_deg(camera_forward.angle_to(aim_direction))
	if aim_angle > grapple_angle_tolerance and distance_from_ray(ray_origin, camera_forward, target_position) > grapple_target_radius:
		return {}
	if grapple_path_validation and not validate_grapple_path(target_position, ray_result["rid"] as RID):
		return {}
	return {
		"position": target_position,
		"normal": hit_normal,
		"collider": collider_node,
		"rid": ray_result["rid"] as RID
	}

func calculate_attachment_position(hit_position: Vector3, hit_normal: Vector3) -> Vector3:
	var standoff_distance: float = grapple_surface_tolerance
	if player_collision_shape.shape is CapsuleShape3D:
		var capsule_shape: CapsuleShape3D = player_collision_shape.shape as CapsuleShape3D
		if hit_normal.y < -0.7:
			standoff_distance = max(standoff_distance, capsule_shape.height + grapple_completion_distance)
		elif abs(hit_normal.y) <= 0.7:
			standoff_distance = max(standoff_distance, capsule_shape.radius + grapple_completion_distance * 0.5)
	return hit_position + hit_normal * standoff_distance

func is_valid_grapple_collider(collider: Node3D) -> bool:
	if collider.is_in_group(grapple_exclusion_group):
		return false
	var current_node: Node = collider
	while current_node != null and current_node != self:
		if current_node.is_in_group(grapple_exclusion_group):
			return false
		current_node = current_node.get_parent()
	if collider is StaticBody3D:
		return true
	if collider is CSGShape3D:
		return true
	return false

func validate_grapple_path(target_position: Vector3, target_rid: RID) -> bool:
	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var path_origin: Vector3 = player.global_position + Vector3.UP * 0.8
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		path_origin,
		target_position,
		grapple_target_collision_mask,
		[player.get_rid()]
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var hit_rid: RID = hit.get("rid", RID()) as RID
	if hit_rid == target_rid:
		return true
	return false

func distance_from_ray(origin: Vector3, direction: Vector3, point: Vector3) -> float:
	var offset: Vector3 = point - origin
	var projected_distance: float = offset.dot(direction)
	if projected_distance <= 0.0:
		return offset.length()
	var closest_point: Vector3 = origin + direction * projected_distance
	return point.distance_to(closest_point)

func update_target_preview() -> void:
	var target_data: Dictionary = find_grapple_target(true)
	if target_data.is_empty():
		grapple_target_valid = false
		return
	grapple_target_valid = true
	var target_position: Vector3 = target_data["position"] as Vector3
	var target_distance: float = player.global_position.distance_to(target_position)
	grapple_target_indicator_position = target_position
	grapple_target_indicator_scale_value = target_indicator_scale * clamp(target_distance / max(target_indicator_distance, 0.001), 0.55, 1.5)

func validate_active_grapple_target() -> bool:
	if not is_instance_valid(grapple_target_collider):
		return false
	if not is_valid_grapple_collider(grapple_target_collider):
		return false
	if player.global_position.distance_to(grapple_target_position) > grapple_max_distance + grapple_completion_distance:
		return false
	if grapple_path_validation and not validate_grapple_path(grapple_target_position, grapple_target_rid):
		return false
	return true

func update_grapple_motion(delta: float) -> void:
	grapple_distance = player.global_position.distance_to(grapple_target_position)
	if grapple_distance <= grapple_completion_distance:
		return
	grapple_direction = (grapple_target_position - player.global_position).normalized()
	var tangent_velocity: Vector3 = grapple_velocity.slide(grapple_direction)
	var momentum_factor: float = grapple_velocity_preservation * grapple_momentum_influence
	var tangent_distance_fade: float = clamp(grapple_distance / max(grapple_start_distance, 0.001), 0.0, 1.0)
	tangent_velocity *= momentum_factor * tangent_distance_fade
	var control_factor: float = grapple_ground_control
	if not player.is_on_floor():
		control_factor = grapple_air_control
	var input_direction: Vector3 = get_grapple_control_direction()
	if input_direction.length_squared() > 0.001:
		var input_tangent: Vector3 = input_direction.slide(grapple_direction)
		if input_tangent.length_squared() > 0.001:
			input_tangent = input_tangent.normalized()
			var tangent_speed: float = min(max(tangent_velocity.length(), grapple_arrival_speed), grapple_tangent_speed_limit)
			var tangent_target: Vector3 = input_tangent * tangent_speed
			tangent_velocity = tangent_velocity.lerp(tangent_target, clamp(grapple_control_response * control_factor * delta, 0.0, 1.0))
	if tangent_velocity.length() > grapple_tangent_speed_limit:
		tangent_velocity = tangent_velocity.normalized() * grapple_tangent_speed_limit
	var desired_velocity: Vector3 = grapple_direction * grapple_target_speed + tangent_velocity
	if desired_velocity.length() > grapple_target_speed:
		desired_velocity = desired_velocity.normalized() * grapple_target_speed
	grapple_velocity = grapple_velocity.move_toward(desired_velocity, (grapple_acceleration + grapple_pull_strength) * delta)
	if grapple_velocity.length() > grapple_target_speed:
		grapple_velocity = grapple_velocity.move_toward(grapple_velocity.normalized() * grapple_target_speed, grapple_arrival_braking * delta)

func get_grapple_control_direction() -> Vector3:
	var movement_input: Vector2 = player_input.movement_input
	if movement_input.length_squared() <= 0.001:
		return Vector3.ZERO
	var forward: Vector3 = -player.global_transform.basis.z
	var right: Vector3 = player.global_transform.basis.x
	var control_direction: Vector3 = right * movement_input.x + forward * -movement_input.y
	return control_direction.normalized()

func get_requested_velocity() -> Vector3:
	return grapple_velocity

func has_exit_velocity() -> bool:
	return grapple_exit_velocity_pending

func consume_exit_velocity() -> Vector3:
	var exit_velocity: Vector3 = grapple_exit_velocity
	grapple_exit_velocity = Vector3.ZERO
	grapple_exit_velocity_pending = false
	return exit_velocity

func cancel_grapple() -> void:
	if not grapple_active:
		return
	var exit_velocity: Vector3 = grapple_velocity
	if not grapple_cancel_preserves_velocity:
		exit_velocity = Vector3.ZERO
	else:
		exit_velocity *= grapple_velocity_preservation
	exit_velocity += grapple_direction * grapple_cancel_boost
	finish_grapple(exit_velocity)

func cancel_grapple_without_boost() -> void:
	if not grapple_active:
		return
	var exit_velocity: Vector3 = grapple_velocity * grapple_velocity_preservation
	finish_grapple(exit_velocity)

func complete_grapple() -> void:
	if not grapple_active:
		return
	var actual_velocity: Vector3 = player.velocity
	var forward_speed: float = max(actual_velocity.dot(grapple_direction), 0.0) * grapple_arrival_velocity
	var tangent_velocity: Vector3 = actual_velocity.slide(grapple_direction) * grapple_exit_momentum
	var exit_velocity: Vector3 = grapple_direction * forward_speed + tangent_velocity + grapple_direction * grapple_exit_boost
	finish_grapple(exit_velocity)
	grapple_arrival_pulse = 1.0

func finish_grapple(exit_velocity: Vector3) -> void:
	grapple_active = false
	grapple_cooldown_timer = max(grapple_cooldown, 0.0)
	grapple_recovery_timer = max(grapple_recovery_time, 0.0)
	grapple_exit_velocity = exit_velocity
	grapple_exit_velocity_pending = true
	grapple_velocity = exit_velocity
	grapple_arrival_pulse = max(grapple_arrival_pulse, 0.65)
	if player.is_on_floor():
		player_state.change_state(PlayerState.MovementState.GROUNDED)
	else:
		player_state.change_state(PlayerState.MovementState.AIRBORNE)
	grapple_target_collider = null
	grapple_target_rid = RID()

func update_camera_feedback(delta: float) -> void:
	camera_motion.position -= grapple_camera_position_applied
	camera_motion.rotation -= grapple_camera_rotation_applied
	camera.fov -= grapple_fov_applied
	grapple_camera_position_applied = Vector3.ZERO
	grapple_camera_rotation_applied = Vector3.ZERO
	grapple_fov_applied = 0.0
	grapple_launch_pulse = move_toward(grapple_launch_pulse, 0.0, max(grapple_fov_launch_speed, 0.1) * delta)
	grapple_arrival_pulse = move_toward(grapple_arrival_pulse, 0.0, max(grapple_fov_return_speed, 0.1) * delta)
	var target_rotation: Vector3 = Vector3.ZERO
	var target_position: Vector3 = Vector3.ZERO
	if grapple_active:
		var local_velocity: Vector3 = camera.global_transform.basis.inverse() * grapple_velocity
		var speed_ratio: float = clamp(grapple_velocity.length() / max(grapple_max_speed, 0.001), 0.0, 1.0)
		var vertical_ratio: float = clamp(local_velocity.y / max(grapple_max_speed, 0.001), -1.0, 1.0)
		var lateral_ratio: float = clamp(local_velocity.x / max(grapple_max_speed, 0.001), -1.0, 1.0)
		target_rotation.x = -deg_to_rad(vertical_ratio * grapple_camera_pitch)
		target_rotation.z = -deg_to_rad(lateral_ratio * grapple_camera_roll)
		var target_local_direction: Vector3 = camera.global_transform.basis.inverse() * grapple_direction
		var target_pitch: float = atan2(target_local_direction.y, max(Vector2(target_local_direction.x, target_local_direction.z).length(), 0.001))
		var target_angle_limit: float = deg_to_rad(grapple_camera_target_max_angle)
		target_pitch = clamp(target_pitch, -target_angle_limit, target_angle_limit)
		grapple_camera_target_rotation.x = move_toward(grapple_camera_target_rotation.x, target_pitch * grapple_camera_target_influence, grapple_camera_target_response * delta)
		grapple_camera_target_rotation.y = 0.0
		target_rotation += grapple_camera_target_rotation
		target_position.x = -lateral_ratio * grapple_camera_sway
		target_position.y = -vertical_ratio * grapple_camera_sway * 0.35
		target_position.z = speed_ratio * grapple_camera_sway * 0.5
		target_position.z += grapple_camera_launch_amount * grapple_launch_pulse
		target_position.y -= grapple_camera_arrival_amount * grapple_arrival_pulse
	else:
		grapple_camera_target_rotation = grapple_camera_target_rotation.move_toward(Vector3.ZERO, grapple_camera_target_response * delta)
	var rotation_frequency: float = grapple_camera_response_speed
	if not grapple_active:
		rotation_frequency = grapple_camera_return_speed
	rotation_frequency /= max(grapple_camera_inertia, 0.1)
	var rotation_spring: Dictionary = critical_damp_vector3(
		grapple_camera_rotation_value,
		grapple_camera_rotation_velocity,
		target_rotation,
		rotation_frequency,
		delta
	)
	grapple_camera_rotation_value = rotation_spring["value"] as Vector3
	grapple_camera_rotation_velocity = rotation_spring["velocity"] as Vector3
	var position_frequency: float = rotation_frequency
	var position_spring: Dictionary = critical_damp_vector3(
		grapple_camera_position_value,
		grapple_camera_position_velocity,
		target_position,
		position_frequency,
		delta
	)
	grapple_camera_position_value = position_spring["value"] as Vector3
	grapple_camera_position_velocity = position_spring["velocity"] as Vector3
	var target_fov_offset: float = 0.0
	if grapple_active:
		var grapple_speed_ratio: float = clamp(grapple_velocity.length() / max(grapple_max_speed, 0.001), 0.0, 1.0)
		var distance_ratio: float = clamp(grapple_distance / max(grapple_start_distance, 0.001), 0.0, 1.0)
		target_fov_offset = grapple_fov_boost + grapple_speed_ratio * grapple_fov_speed_influence + distance_ratio * grapple_fov_distance_influence
		target_fov_offset += grapple_fov_boost * 0.35 * grapple_launch_pulse
	var fov_speed: float = grapple_fov_return_speed
	if target_fov_offset > grapple_fov_offset:
		fov_speed = grapple_fov_launch_speed
	grapple_fov_offset = move_toward(grapple_fov_offset, target_fov_offset, max(fov_speed, 0.1) * delta)
	var max_offset: float = max(grapple_fov_maximum - camera.fov, 0.0)
	grapple_fov_offset = min(grapple_fov_offset, max_offset)
	camera_motion.position += grapple_camera_position_value
	camera_motion.rotation += grapple_camera_rotation_value
	camera.fov += grapple_fov_offset
	grapple_camera_position_applied = grapple_camera_position_value
	grapple_camera_rotation_applied = grapple_camera_rotation_value
	grapple_fov_applied = grapple_fov_offset

func get_camera_rotation_offset() -> Vector3:
	return grapple_camera_rotation_value

func get_camera_position_offset() -> Vector3:
	return grapple_camera_position_value

func get_fov_offset() -> float:
	return grapple_fov_offset

func is_grappling() -> bool:
	return grapple_active

func get_target_position() -> Vector3:
	return grapple_target_position

func is_target_valid() -> bool:
	return grapple_target_valid

func get_target_indicator_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * grapple_target_indicator_scale_value), grapple_target_indicator_position)

func critical_damp_vector3(current_value: Vector3, current_velocity: Vector3, target_value: Vector3, frequency: float, delta: float) -> Dictionary:
	var angular_frequency: float = max(frequency, 0.001)
	var offset: Vector3 = current_value - target_value
	var exponential_decay: float = exp(-angular_frequency * delta)
	var temporary_value: Vector3 = (current_velocity + offset * angular_frequency) * delta
	var new_offset: Vector3 = (offset + temporary_value) * exponential_decay
	var new_velocity: Vector3 = (current_velocity - temporary_value * angular_frequency) * exponential_decay
	var new_value: Vector3 = target_value + new_offset
	if new_value.length_squared() < 0.000001 and new_velocity.length_squared() < 0.000001 and target_value.length_squared() < 0.000001:
		new_value = target_value
		new_velocity = Vector3.ZERO
	return {
		"value": new_value,
		"velocity": new_velocity
	}

func update_target_indicator(delta: float) -> void:
	if target_indicator == null:
		return
	var desired_position: Vector3 = grapple_target_indicator_position
	var current_global_position: Vector3 = target_indicator.global_position
	var smoothing: float = 1.0 - exp(-max(target_indicator_smoothing, 0.1) * delta)
	target_indicator.global_position = current_global_position.lerp(desired_position, smoothing)
	target_indicator.scale = Vector3.ONE * grapple_target_indicator_scale_value
	target_indicator.visible = show_grapple_target and grapple_target_valid and not grapple_active

func configure_debug_geometry() -> void:
	if not debug_draw_grapple_target and not debug_draw_grapple_path:
		return
	debug_mesh_instance = MeshInstance3D.new()
	debug_immediate_mesh = ImmediateMesh.new()
	debug_material = StandardMaterial3D.new()
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.vertex_color_use_as_albedo = true
	debug_mesh_instance.mesh = debug_immediate_mesh
	debug_mesh_instance.material_override = debug_material
	add_child(debug_mesh_instance)

func update_debug_geometry() -> void:
	if debug_immediate_mesh == null:
		return
	if not debug_draw_grapple_target and not debug_draw_grapple_path:
		debug_immediate_mesh.clear_surfaces()
		return
	debug_immediate_mesh.clear_surfaces()
	debug_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	if debug_draw_grapple_path and (grapple_active or grapple_target_valid):
		var path_start: Vector3 = player.global_position
		var path_end: Vector3 = grapple_target_position
		debug_immediate_mesh.surface_set_color(Color(0.2, 0.85, 1.0, 1.0))
		debug_immediate_mesh.surface_add_vertex(debug_mesh_instance.to_local(path_start))
		debug_immediate_mesh.surface_add_vertex(debug_mesh_instance.to_local(path_end))
	if debug_draw_grapple_target and grapple_target_valid:
		var center: Vector3 = debug_mesh_instance.to_local(grapple_target_position)
		var size: float = 0.3
		var right: Vector3 = Vector3.RIGHT * size
		var up: Vector3 = Vector3.UP * size
		var forward: Vector3 = Vector3.FORWARD * size
		debug_mesh_instance.material_override = debug_material
		debug_mesh_instance.mesh = debug_immediate_mesh
		debug_immediate_mesh.surface_set_color(Color(0.25, 1.0, 0.55, 1.0))
		debug_immediate_mesh.surface_add_vertex(center - right)
		debug_immediate_mesh.surface_add_vertex(center + right)
		debug_immediate_mesh.surface_add_vertex(center - up)
		debug_immediate_mesh.surface_add_vertex(center + up)
		debug_immediate_mesh.surface_add_vertex(center - forward)
		debug_immediate_mesh.surface_add_vertex(center + forward)
	debug_immediate_mesh.surface_end()

func update_debug_state() -> void:
	if not debug_print_grapple_state:
		return
	var current_state: StringName = &"grappling"
	if not grapple_active:
		current_state = &"inactive"
	if current_state == grapple_last_debug_state:
		return
	grapple_last_debug_state = current_state
	print("Grapple state: ", current_state)
