extends PlayerTraversal

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

func apply_scramble_horizontal_control(delta: float) -> void:
	var current_horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var current_tangent_velocity: Vector3 = current_horizontal_velocity.slide(scramble_wall_normal)
	var damping_weight: float = clamp(scramble_steering_response * delta, 0.0, 1.0)
	current_tangent_velocity = current_tangent_velocity.lerp(Vector3.ZERO, damping_weight)
	player.velocity.x = current_tangent_velocity.x
	player.velocity.z = current_tangent_velocity.z
