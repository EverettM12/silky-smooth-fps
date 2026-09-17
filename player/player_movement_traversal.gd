class_name PlayerMovementTraversal
extends PlayerMovement

@onready var traversal: PlayerTraversal = get_node("../Traversal") as PlayerTraversal

func _physics_process(delta: float) -> void:
	if player == null or input == null or state == null or grapple == null or capsule_shape == null or traversal == null:
		return
	update_timers(delta)
	update_floor_tracking()
	if traversal.is_traversing():
		process_traversal_only(delta)
		return
	grapple.process_physics_pre_movement(delta)
	var grapple_exit_consumed: bool = false
	var grapple_exit_pending: bool = grapple.has_exit_velocity()
	if grapple.is_grappling():
		is_dashing = false
		dash_timer = 0.0
		dash_distance_remaining = 0.0
		is_wall_running = false
		wall_run_timer = 0.0
		if state.is_sliding():
			slide_timer = 0.0
		process_stance(delta)
		player.velocity = grapple.get_requested_velocity()
	else:
		process_jump_buffer()
		if not grapple_exit_pending and traversal.process_physics_pre_movement(delta):
			traversal.process_physics(delta)
			if traversal.is_traversing() and traversal.is_hurdling():
				process_air_movement(delta)
				process_gravity(delta)
				process_stance(delta)
		player.move_and_slide()
			traversal.process_physics_post_movement(delta)
			jump_was_held = input.jump_pressed
			return
		process_dash_input()
		update_wall_detection()
		update_movement_state()
		process_dash(delta)
		if not is_dashing:
			process_slide(delta)
			process_ground_movement(delta)
			process_air_movement(delta)
			process_wall_run(delta)
			process_gravity(delta)
			process_stance(delta)
		if not grapple_exit_pending:
			apply_jump()
	if grapple.has_exit_velocity():
		player.velocity = grapple.consume_exit_velocity()
		grapple_exit_consumed = true
	player.move_and_slide()
	grapple.process_physics_post_movement(delta)
	if not grapple.is_grappling() and not grapple_exit_consumed and not traversal.is_traversing():
		update_wall_detection()
		update_movement_state()
	jump_was_held = input.jump_pressed
	if grapple_exit_consumed:
		jump_was_held = true

func process_traversal_only(delta: float) -> void:
	var hurdling: bool = traversal.is_hurdling()
	traversal.process_physics(delta)
	if hurdling and traversal.is_traversing():
		process_air_movement(delta)
		process_gravity(delta)
		process_stance(delta)
	player.move_and_slide()
	traversal.process_physics_post_movement(delta)
	if traversal.is_traversing():
		if traversal.is_hurdling():
			state.change_state(PlayerState.MovementState.HURDLING)
		else:
			state.change_state(PlayerState.MovementState.MANTLING)
	jump_was_held = input.jump_pressed
