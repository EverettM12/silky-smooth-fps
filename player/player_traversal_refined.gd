class_name PlayerTraversalRefined
extends PlayerTraversal

func process_physics(delta: float) -> void:
	if not traversal_active:
		return
	traversal_elapsed += delta
	var current_duration: float = get_current_duration()
	traversal_progress = clamp(traversal_elapsed / max(current_duration, 0.001), 0.0, 1.0)
	update_traversal_phase()
	var path_velocity: Vector3 = calculate_path_velocity(traversal_progress, current_duration)
	var desired_velocity: Vector3 = path_velocity
	var entry_horizontal_velocity: Vector3 = Vector3(traversal_start_velocity.x, 0.0, traversal_start_velocity.z)
	var entry_speed: float = entry_horizontal_velocity.length() * traversal_entry_speed_influence
	var entry_direction: Vector3 = traversal_entry_direction
	if entry_horizontal_velocity.length_squared() > 0.001:
		entry_direction = entry_horizontal_velocity.normalized()
	var desired_horizontal: Vector3 = Vector3(path_velocity.x, 0.0, path_velocity.z)
	if entry_speed > desired_horizontal.length() and entry_direction.length_squared() > 0.001:
		desired_horizontal = entry_direction * entry_speed
	var entry_influence: float = 1.0 - smoothstep(0.0, 0.16, traversal_progress)
	var entry_horizontal_velocity_target: Vector3 = Vector3(
		entry_direction.x * entry_speed,
		0.0,
		entry_direction.z * entry_speed
	)
	desired_horizontal = desired_horizontal.lerp(entry_horizontal_velocity_target, entry_influence)
	var exit_velocity: Vector3 = calculate_exit_velocity()
	var exit_influence: float = smoothstep(0.78, 1.0, traversal_progress)
	var blended_horizontal: Vector3 = desired_horizontal.lerp(
		Vector3(exit_velocity.x, 0.0, exit_velocity.z),
		exit_influence
	)
	var blended_vertical: float = path_velocity.y
	if traversal_type == TraversalType.HURDLE and exit_influence > 0.0:
		blended_vertical = lerp(blended_vertical, exit_velocity.y, exit_influence)
	desired_velocity = Vector3(blended_horizontal.x, blended_vertical, blended_horizontal.z)
	var traversal_acceleration: float = hurdle_acceleration
	if traversal_type == TraversalType.MANTLE:
		traversal_acceleration = mantle_acceleration
	player.velocity = player.velocity.move_toward(desired_velocity, traversal_acceleration * delta)
	apply_traversal_steering(delta)
	traversal_path_direction = Vector3(player.velocity.x, 0.0, player.velocity.z)
	if traversal_path_direction.length_squared() > 0.001:
		traversal_path_direction = traversal_path_direction.normalized()
	traversal_target_revalidation_timer = max(traversal_target_revalidation_timer - delta, 0.0)
	if traversal_target_revalidation_timer <= 0.0:
		traversal_target_revalidation_timer = max(traversal_target_revalidation_interval, 0.001)
		if not is_capsule_position_clear(traversal_target_position):
			cancel_traversal()

func calculate_path_velocity(progress: float, duration: float) -> Vector3:
	var safe_duration: float = max(duration, 0.001)
	var sample_width: float = 0.01
	var previous_progress: float = max(progress - sample_width, 0.0)
	var next_progress: float = min(progress + sample_width, 1.0)
	var progress_span: float = next_progress - previous_progress
	if progress_span <= 0.000001:
		return Vector3.ZERO
	var previous_position: Vector3 = calculate_traversal_position(previous_progress)
	var next_position: Vector3 = calculate_traversal_position(next_progress)
	return (next_position - previous_position) / (progress_span * safe_duration)
