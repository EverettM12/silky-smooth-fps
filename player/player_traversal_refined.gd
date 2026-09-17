class_name PlayerTraversalRefined
extends PlayerTraversal
#
#var hurdle_runtime_duration: float = 0.0
#var hurdle_collision_exception_body: PhysicsBody3D = null
#
#func start_traversal(traversal_target_data: Dictionary) -> void:
	#super.start_traversal(traversal_target_data)
	#if traversal_type != TraversalType.HURDLE:
		#return
	#var entry_horizontal_velocity: Vector3 = Vector3(traversal_start_velocity.x, 0.0, traversal_start_velocity.z)
	#var target_horizontal: Vector3 = Vector3(
		#traversal_target_position.x - traversal_start_position.x,
		#0.0,
		#traversal_target_position.z - traversal_start_position.z
	#)
	#var target_distance: float = target_horizontal.length()
	#var movement_speed: float = max(entry_horizontal_velocity.length(), hurdle_forward_speed)
	#if entry_horizontal_velocity.length_squared() > 0.001 and target_horizontal.length_squared() > 0.001:
		#var entry_direction: Vector3 = entry_horizontal_velocity.normalized()
		#var target_direction: Vector3 = target_horizontal.normalized()
		#var blended_direction: Vector3 = entry_direction.slerp(target_direction, traversal_exit_direction_influence)
		#if blended_direction.length_squared() > 0.001:
			#entry_horizontal_velocity = blended_direction.normalized() * movement_speed
	#else:
		#entry_horizontal_velocity = traversal_entry_direction * movement_speed
	#if entry_horizontal_velocity.length_squared() <= 0.001:
		#entry_horizontal_velocity = -player.global_transform.basis.z * movement_speed
	#var effective_speed: float = max(entry_horizontal_velocity.length(), hurdle_forward_speed)
	#var minimum_duration: float = max(hurdle_duration * 0.35, 0.08)
	#var speed_duration: float = target_distance / max(effective_speed, 0.1)
	#hurdle_runtime_duration = max(minimum_duration, speed_duration)
	#traversal_start_velocity.x = entry_horizontal_velocity.x
	#traversal_start_velocity.z = entry_horizontal_velocity.z
	#player.velocity.x = entry_horizontal_velocity.x
	#player.velocity.z = entry_horizontal_velocity.z
	#var obstacle_height_for_arc: float = max(
		#hurdle_height,
		#obstacle_height + hurdle_obstacle_clearance + clearance_margin
	#)
	#var vertical_delta: float = hurdle_target_position.y - traversal_start_position.y
	#var initial_vertical_velocity: float = (
		#vertical_delta
		#+ PI * obstacle_height_for_arc
	#) / max(hurdle_runtime_duration, 0.001)
	#player.velocity.y = initial_vertical_velocity
	#setup_hurdle_collision_exception()
#
#func process_physics(delta: float) -> void:
	#if not traversal_active:
		#return
	#if traversal_type != TraversalType.HURDLE:
		#super.process_physics(delta)
		#return
	#traversal_elapsed += delta
	#var current_duration: float = get_current_duration()
	#traversal_progress = clamp(traversal_elapsed / max(current_duration, 0.001), 0.0, 1.0)
	#update_traversal_phase()
	#player.velocity = calculate_hurdle_velocity(traversal_progress, current_duration)
	#apply_hurdle_steering(delta)
	#traversal_path_direction = Vector3(player.velocity.x, 0.0, player.velocity.z)
	#if traversal_path_direction.length_squared() > 0.001:
		#traversal_path_direction = traversal_path_direction.normalized()
#
#func process_physics_post_movement(_delta: float) -> void:
	#if not traversal_active:
		#return
	#if player.is_on_ceiling():
		#cancel_traversal()
		#return
	#if traversal_type != TraversalType.HURDLE:
		#super.process_physics_post_movement(_delta)
		#return
	#var travel_from_start: Vector3 = player.global_position - traversal_start_position
	#var forward_distance: float = Vector2(travel_from_start.x, travel_from_start.z).dot(
		#Vector2(traversal_entry_direction.x, traversal_entry_direction.z)
	#)
	#var target_from_start: Vector3 = traversal_target_position - traversal_start_position
	#var target_forward_distance: float = Vector2(target_from_start.x, target_from_start.z).dot(
		#Vector2(traversal_entry_direction.x, traversal_entry_direction.z)
	#)
	#if player.is_on_floor() and forward_distance >= target_forward_distance - traversal_horizontal_tolerance:
		#complete_hurdle()
		#return
	#if traversal_progress >= 1.0:
		#release_hurdle()
#
#func get_current_duration() -> float:
	#if traversal_type == TraversalType.HURDLE:
		#return max(hurdle_runtime_duration, 0.08)
	#return super.get_current_duration()
#
#func calculate_hurdle_velocity(progress: float, duration: float) -> Vector3:
	#var safe_duration: float = max(duration, 0.001)
	#var clamped_progress: float = clamp(progress, 0.0, 1.0)
	#var target_delta: Vector3 = hurdle_target_position - traversal_start_position
	#var horizontal_velocity: Vector3 = Vector3(
		#target_delta.x / safe_duration,
		#0.0,
		#target_delta.z / safe_duration
	#)
	#var peak_height: float = max(
		#hurdle_height,
		#obstacle_height + hurdle_obstacle_clearance + clearance_margin
	#)
	#var vertical_delta: float = hurdle_target_position.y - traversal_start_position.y
	#var vertical_velocity: float = (
		#vertical_delta
		#+ cos(clamped_progress * PI) * PI * peak_height
	#) / safe_duration
	#return Vector3(horizontal_velocity.x, vertical_velocity, horizontal_velocity.z)
#
#func apply_hurdle_steering(delta: float) -> void:
	#var input_direction: Vector3 = player_movement.get_movement_direction()
	#if input_direction.length_squared() <= 0.001:
		#return
	#var current_horizontal: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	#var speed: float = current_horizontal.length()
	#if speed <= 0.001:
		#return
	#var current_direction: Vector3 = current_horizontal.normalized()
	#var steering_amount: float = clamp(hurdle_air_control * hurdle_steering_response * delta, 0.0, 1.0)
	#var steered_direction: Vector3 = current_direction.slerp(input_direction.normalized(), steering_amount)
	#if steered_direction.length_squared() > 0.001:
		#steered_direction = steered_direction.normalized()
		#player.velocity.x = steered_direction.x * speed
		#player.velocity.z = steered_direction.z * speed
#
#func setup_hurdle_collision_exception() -> void:
	#clear_hurdle_collision_exception()
	#var origin: Vector3 = traversal_start_position + Vector3.UP * front_probe_mid_height
	#var end_position: Vector3 = obstacle_front_position + traversal_entry_direction * 0.01
	#var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		#origin,
		#end_position,
		#traversal_collision_mask,
		#[player.get_rid()]
	#)
	#query.collide_with_areas = false
	#query.collide_with_bodies = true
	#var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	#if hit.is_empty():
		#return
	#var collider_object: Object = hit.get("collider", null) as Object
	#var physics_body: PhysicsBody3D = collider_object as PhysicsBody3D
	#if physics_body == null or physics_body == player:
		#return
	#hurdle_collision_exception_body = physics_body
	#player.add_collision_exception_with(hurdle_collision_exception_body)
#
#func clear_hurdle_collision_exception() -> void:
	#if hurdle_collision_exception_body == null:
		#return
	#player.remove_collision_exception_with(hurdle_collision_exception_body)
	#hurdle_collision_exception_body = null
#
#func complete_hurdle() -> void:
	#if not traversal_active:
		#return
	#var completed_type: TraversalType = traversal_type
	#clear_hurdle_collision_exception()
	#player.velocity.y = 0.0
	#traversal_active = false
	#traversal_progress = 1.0
	#traversal_phase = TraversalPhase.INACTIVE
	#traversal_type = TraversalType.NONE
	#traversal_target_position = Vector3.ZERO
	#player_state.change_state(PlayerState.MovementState.GROUNDED)
	#traversal_completed.emit(completed_type)
#
#func release_hurdle() -> void:
	#if not traversal_active:
		#return
	#var released_type: TraversalType = traversal_type
	#clear_hurdle_collision_exception()
	#traversal_active = false
	#traversal_progress = 1.0
	#traversal_phase = TraversalPhase.INACTIVE
	#traversal_type = TraversalType.NONE
	#traversal_target_position = Vector3.ZERO
	#if player.is_on_floor():
		#player_state.change_state(PlayerState.MovementState.GROUNDED)
	#else:
		#player_state.change_state(PlayerState.MovementState.AIRBORNE)
	#traversal_completed.emit(released_type)
#
#func cancel_traversal() -> void:
	#var was_hurdling: bool = traversal_active and traversal_type == TraversalType.HURDLE
	#if was_hurdling:
		#clear_hurdle_collision_exception()
	#super.cancel_traversal()
