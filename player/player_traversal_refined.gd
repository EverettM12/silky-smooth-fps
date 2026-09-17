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
	if traversal_type == TraversalType.HURDLE:
		path_velocity = calculate_hurdle_velocity(traversal_progress, current_duration)
	var desired_horizontal: Vector3 = Vector3(path_velocity.x, 0.0, path_velocity.z)
	var entry_horizontal_velocity: Vector3 = Vector3(traversal_start_velocity.x, 0.0, traversal_start_velocity.z)
	var entry_speed: float = entry_horizontal_velocity.length() * traversal_entry_speed_influence
	var entry_direction: Vector3 = traversal_entry_direction
	if entry_horizontal_velocity.length_squared() > 0.001:
		entry_direction = entry_horizontal_velocity.normalized()
	var entry_velocity_target: Vector3 = entry_direction * entry_speed
	var entry_blend: float = 1.0 - smoothstep(0.0, 0.2, traversal_progress)
	if entry_speed > desired_horizontal.length() and entry_direction.length_squared() > 0.001:
		desired_horizontal = entry_velocity_target
	desired_horizontal = desired_horizontal.lerp(entry_velocity_target, entry_blend)
	var horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var traversal_acceleration: float = hurdle_acceleration
	if traversal_type == TraversalType.MANTLE:
		traversal_acceleration = mantle_acceleration
	horizontal_velocity = horizontal_velocity.move_toward(desired_horizontal, traversal_acceleration * delta)
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
	if traversal_type == TraversalType.HURDLE:
		var input_direction: Vector3 = player_movement.get_movement_direction()
		if input_direction.length_squared() > 0.001:
			var current_horizontal_direction: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
			if current_horizontal_direction.length_squared() > 0.001:
				current_horizontal_direction = current_horizontal_direction.normalized()
				var steering_direction: Vector3 = current_horizontal_direction.lerp(
					input_direction,
					hurdle_air_control * delta * hurdle_steering_response
				)
				if steering_direction.length_squared() > 0.001:
					steering_direction = steering_direction.normalized()
					var speed: float = Vector2(player.velocity.x, player.velocity.z).length()
					player.velocity.x = steering_direction.x * speed
					player.velocity.z = steering_direction.z * speed
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
	var horizontal_target_distance: float = Vector2(
		player.global_position.x - traversal_target_position.x,
		player.global_position.z - traversal_target_position.z
	).length()
	if traversal_type == TraversalType.HURDLE and player.is_on_floor() and horizontal_target_distance <= traversal_horizontal_tolerance:
		complete_traversal()
		return
	if traversal_progress < 1.0:
		return
	var target_vertical_distance: float = abs(player.global_position.y - traversal_target_position.y)
	if horizontal_target_distance <= traversal_completion_tolerance and target_vertical_distance <= traversal_vertical_tolerance:
		complete_traversal()
		return
	if traversal_type == TraversalType.HURDLE:
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

func calculate_hurdle_velocity(progress: float, duration: float) -> Vector3:
	var safe_duration: float = max(duration, 0.001)
	var clamped_progress: float = clamp(progress, 0.0, 1.0)
	var horizontal_derivative: float = 6.0 * clamped_progress * (1.0 - clamped_progress)
	var horizontal_displacement: Vector3 = hurdle_target_position - traversal_start_position
	var horizontal_velocity: Vector3 = horizontal_displacement * (horizontal_derivative / safe_duration)
	var clear_peak_height: float = max(
		hurdle_height,
		obstacle_height + hurdle_obstacle_clearance + clearance_margin,
		hurdle_vertical_speed * safe_duration * 0.5
	)
	var vertical_delta: float = hurdle_target_position.y - traversal_start_position.y
	var vertical_velocity: float = (
		vertical_delta
		+ cos(clamped_progress * PI) * PI * clear_peak_height
	) / safe_duration
	return Vector3(horizontal_velocity.x, vertical_velocity, horizontal_velocity.z)

func calculate_hurdle_position(progress: float) -> Vector3:
	var clamped_progress: float = clamp(progress, 0.0, 1.0)
	var eased_progress: float = smoothstep(0.0, 1.0, clamped_progress)
	var horizontal_position: Vector3 = traversal_start_position.lerp(hurdle_target_position, eased_progress)
	var clear_peak_height: float = max(
		hurdle_height,
		obstacle_height + hurdle_obstacle_clearance + clearance_margin,
		hurdle_vertical_speed * get_hurdle_duration() * 0.5
	)
	var vertical_position: float = lerp(
		traversal_start_position.y,
		hurdle_target_position.y,
		eased_progress
	) + sin(clamped_progress * PI) * clear_peak_height
	return Vector3(horizontal_position.x, vertical_position, horizontal_position.z)
