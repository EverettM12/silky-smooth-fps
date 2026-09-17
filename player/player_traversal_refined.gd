class_name PlayerTraversalRefined
extends PlayerTraversal

@export_group("Refined Hurdle")
@export_range(0.0, 0.5, 0.01) var hurdle_lift_phase: float = 0.28
@export_range(0.0, 0.5, 0.01) var hurdle_crossing_end_phase: float = 0.76
@export var hurdle_lift_horizontal_fraction: float = 0.04

func process_physics(delta: float) -> void:
	if not traversal_active:
		return
	traversal_elapsed += delta
	var current_duration: float = get_current_duration()
	traversal_progress = clamp(traversal_elapsed / max(current_duration, 0.001), 0.0, 1.0)
	update_traversal_phase()
	var path_velocity: Vector3 = calculate_path_velocity(traversal_progress, current_duration)
	var desired_horizontal: Vector3 = Vector3(path_velocity.x, 0.0, path_velocity.z)
	var entry_horizontal_velocity: Vector3 = Vector3(traversal_start_velocity.x, 0.0, traversal_start_velocity.z)
	var entry_speed: float = entry_horizontal_velocity.length() * traversal_entry_speed_influence
	var entry_direction: Vector3 = traversal_entry_direction
	if entry_horizontal_velocity.length_squared() > 0.001:
		entry_direction = entry_horizontal_velocity.normalized()
	if entry_speed > desired_horizontal.length() and entry_direction.length_squared() > 0.001:
		desired_horizontal = entry_direction * entry_speed
	var entry_influence: float = 1.0 - smoothstep(0.0, 0.16, traversal_progress)
	var entry_horizontal_velocity_target: Vector3 = Vector3(
		entry_direction.x * entry_speed,
		0.0,
		entry_direction.z * entry_speed
	)
	if traversal_type == TraversalType.HURDLE and traversal_progress < hurdle_lift_phase:
		desired_horizontal = desired_horizontal.lerp(
			entry_horizontal_velocity_target * hurdle_lift_horizontal_fraction,
			1.0 - smoothstep(0.0, hurdle_lift_phase, traversal_progress)
		)
	else:
		desired_horizontal = desired_horizontal.lerp(entry_horizontal_velocity_target, entry_influence)
	var exit_velocity: Vector3 = calculate_exit_velocity()
	var exit_influence: float = smoothstep(0.82, 1.0, traversal_progress)
	var blended_horizontal: Vector3 = desired_horizontal.lerp(
		Vector3(exit_velocity.x, 0.0, exit_velocity.z),
		exit_influence
	)
	var horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var traversal_acceleration: float = hurdle_acceleration
	if traversal_type == TraversalType.MANTLE:
		traversal_acceleration = mantle_acceleration
	horizontal_velocity = horizontal_velocity.move_toward(blended_horizontal, traversal_acceleration * delta)
	player.velocity.x = horizontal_velocity.x
	player.velocity.z = horizontal_velocity.z
	if traversal_type == TraversalType.HURDLE:
		player.velocity.y = path_velocity.y
	else:
		var mantle_velocity: Vector3 = player.velocity.move_toward(
			Vector3(player.velocity.x, path_velocity.y, player.velocity.z),
			mantle_acceleration * delta
		)
		player.velocity.y = mantle_velocity.y
	apply_traversal_steering(delta)
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
	var horizontal_target_distance: float = Vector2(
		player.global_position.x - traversal_target_position.x,
		player.global_position.z - traversal_target_position.z
	).length()
	var target_vertical_distance: float = abs(player.global_position.y - traversal_target_position.y)
	if player.is_on_floor() and horizontal_target_distance <= traversal_completion_tolerance:
		complete_traversal()
		return
	if horizontal_target_distance <= traversal_completion_tolerance and target_vertical_distance <= traversal_vertical_tolerance:
		complete_traversal()
		return
	if traversal_type == TraversalType.HURDLE and traversal_progress >= 1.0:
		cancel_traversal()
		return
	if player.get_slide_collision_count() > 0 and player.is_on_floor() and horizontal_target_distance <= traversal_horizontal_tolerance:
		complete_traversal()

func calculate_path_velocity(progress: float, duration: float) -> Vector3:
	var safe_duration: float = max(duration, 0.001)
	var sample_width: float = 0.005
	var previous_progress: float = max(progress - sample_width, 0.0)
	var next_progress: float = min(progress + sample_width, 1.0)
	var progress_span: float = next_progress - previous_progress
	if progress_span <= 0.000001:
		return Vector3.ZERO
	var previous_position: Vector3 = calculate_traversal_position(previous_progress)
	var next_position: Vector3 = calculate_traversal_position(next_progress)
	return (next_position - previous_position) / (progress_span * safe_duration)

func calculate_hurdle_position(progress: float) -> Vector3:
	var clamped_progress: float = clamp(progress, 0.0, 1.0)
	var horizontal_progress: float = 0.0
	var lift_phase: float = clamp(hurdle_lift_phase, 0.05, 0.5)
	var crossing_end: float = clamp(max(hurdle_crossing_end_phase, lift_phase + 0.05), lift_phase + 0.05, 0.95)
	if clamped_progress < lift_phase:
		var lift_progress: float = smoothstep(0.0, 1.0, clamped_progress / lift_phase)
		horizontal_progress = lerp(0.0, clamp(hurdle_lift_horizontal_fraction, 0.0, 0.2), lift_progress)
	elif clamped_progress < crossing_end:
		var crossing_progress: float = smoothstep(
			0.0,
			1.0,
			(clamped_progress - lift_phase) / (crossing_end - lift_phase)
		)
		horizontal_progress = lerp(
			clamp(hurdle_lift_horizontal_fraction, 0.0, 0.2),
			0.88,
			crossing_progress
		)
	else:
		var landing_progress: float = smoothstep(
			0.0,
			1.0,
			(clamped_progress - crossing_end) / max(1.0 - crossing_end, 0.001)
		)
		horizontal_progress = lerp(0.88, 1.0, landing_progress)
	var horizontal_position: Vector3 = traversal_start_position.lerp(hurdle_target_position, horizontal_progress)
	var clear_peak_height: float = max(
		hurdle_height,
		obstacle_height + hurdle_obstacle_clearance + standing_capsule_shape.radius
	)
	var vertical_speed_height: float = hurdle_vertical_speed * get_hurdle_duration()
	clear_peak_height = max(clear_peak_height, vertical_speed_height * 0.5)
	var vertical_arc: float = sin(clamped_progress * PI) * clear_peak_height
	return Vector3(
		horizontal_position.x,
		lerp(traversal_start_position.y, hurdle_target_position.y, smoothstep(0.0, 1.0, clamped_progress)) + vertical_arc,
		horizontal_position.z
	)
