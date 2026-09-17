class_name PlayerTraversalRefined
extends PlayerTraversal

func start_traversal(traversal_target_data: Dictionary) -> void:
	super.start_traversal(traversal_target_data)
	if traversal_type != TraversalType.HURDLE:
		return
	var required_height: float = max(
		hurdle_height,
		obstacle_height + hurdle_obstacle_clearance + clearance_margin
	)
	var rising_gravity: float = max(player_movement.gravity_while_rising, 0.001)
	var required_launch_velocity: float = sqrt(2.0 * rising_gravity * required_height)
	player.velocity.y = max(player.velocity.y, required_launch_velocity)

func process_physics(delta: float) -> void:
	if not traversal_active:
		return
	if traversal_type != TraversalType.HURDLE:
		super.process_physics(delta)
		return
	traversal_elapsed += delta
	var current_duration: float = get_current_duration()
	traversal_progress = clamp(traversal_elapsed / max(current_duration, 0.001), 0.0, 1.0)
	update_traversal_phase()
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
	if traversal_type != TraversalType.HURDLE:
		super.process_physics_post_movement(_delta)
		return
	if player.is_on_ceiling():
		cancel_traversal()
		return
	var travel_from_start: Vector3 = player.global_position - traversal_start_position
	var forward_distance: float = Vector2(travel_from_start.x, travel_from_start.z).dot(
		Vector2(traversal_entry_direction.x, traversal_entry_direction.z)
	)
	var target_from_start: Vector3 = traversal_target_position - traversal_start_position
	var target_forward_distance: float = Vector2(target_from_start.x, target_from_start.z).dot(
		Vector2(traversal_entry_direction.x, traversal_entry_direction.z)
	)
	if player.is_on_floor() and forward_distance >= target_forward_distance - traversal_horizontal_tolerance:
		complete_traversal()
		return
	if traversal_progress >= 1.0 and forward_distance >= target_forward_distance + traversal_horizontal_tolerance:
		cancel_traversal()

func get_current_duration() -> float:
	if traversal_type == TraversalType.HURDLE:
		var vertical_speed: float = max(player.velocity.y, 0.0)
		var falling_gravity: float = max(player_movement.gravity_while_falling * player_movement.fall_multiplier, 0.001)
		var rising_gravity: float = max(player_movement.gravity_while_rising, 0.001)
		var apex_time: float = vertical_speed / rising_gravity
		var apex_height: float = (vertical_speed * vertical_speed) / (2.0 * rising_gravity)
		var landing_time: float = sqrt(max(0.0, 2.0 * apex_height / falling_gravity))
		return max(hurdle_duration, apex_time + landing_time)
	return super.get_current_duration()
