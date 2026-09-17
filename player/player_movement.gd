class_name PlayerMovement
extends Node

@onready var player: CharacterBody3D = $".."
@onready var input: PlayerInput = $"../PlayerInput"
@onready var state: PlayerState = $"../PlayerState"
@onready var grapple: PlayerGrapple = $"../Grapple"

@export_group("Ground Movement")
@export var walk_speed: float = 7.0
@export var sprint_speed: float = 12.0
@export var crouch_speed: float = 4.5
@export var ground_acceleration: float = 42.0
@export var ground_deceleration: float = 34.0
@export var ground_friction: float = 10.0
@export var direction_change_acceleration: float = 58.0
@export var minimum_movement_speed: float = 0.05

@export_group("Air Movement")
@export var air_acceleration: float = 18.0
@export var air_deceleration: float = 2.0
@export_range(0.0, 2.0, 0.01) var air_control: float = 0.85
@export var air_speed_limit: float = 13.0
@export var air_steering_responsiveness: float = 7.0

@export_group("Jumping")
@export var jump_velocity: float = 7.5
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.14
@export var gravity_while_rising: float = 21.0
@export var gravity_while_falling: float = 27.0
@export var fall_multiplier: float = 1.15
@export var maximum_fall_speed: float = 28.0
@export_range(0.0, 1.0, 0.01) var variable_jump_cutoff: float = 0.35

@export_group("Crouching")
@export var standing_height: float = 1.9
@export var crouching_height: float = 1.1
@export var crouch_transition_speed: float = 8.0
@export var standing_head_height: float = 1.65
@export var crouching_head_height: float = 0.95
@export var capsule_radius: float = 0.35

@export_group("Sliding")
@export var slide_minimum_speed: float = 7.0
@export var slide_duration: float = 0.85
@export var slide_friction: float = 2.5
@export var slide_steering: float = 3.0
@export var slide_acceleration: float = 7.0
@export var slide_deceleration: float = 5.0
@export var slide_slope_influence: float = 12.0
@export var slide_jump_multiplier: float = 1.0
@export var slide_cancel_on_release: bool = true
@export var slide_camera_roll_sign: float = 1.0

@export_group("Dashing")
@export var dash_speed: float = 24.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.65
@export var dash_distance: float = 8.0
@export var dash_acceleration: float = 130.0
@export var dash_braking: float = 18.0
@export var dash_gravity_scale: float = 0.0
@export var ground_dash_enabled: bool = true
@export var air_dash_enabled: bool = true
@export var dash_uses_movement_direction: bool = true
@export var dash_preserves_vertical_velocity: bool = false
@export var air_dash_count: int = 1

@export_group("Wall Running")
@export var wall_run_enabled: bool = true
@export var wall_run_speed: float = 13.0
@export var wall_run_acceleration: float = 30.0
@export var wall_run_gravity: float = 5.5
@export var wall_stick_force: float = 7.0
@export var wall_detection_distance: float = 0.8
@export var wall_run_duration: float = 1.4
@export var wall_jump_strength: float = 9.0
@export var wall_jump_direction: float = 0.75
@export var wall_jump_horizontal_influence: float = 0.7
@export var wall_run_steering: float = 0.7
@export var wall_run_entry_speed: float = 5.0
@export_flags_3d_physics var wall_collision_mask: int = 1

@export_group("Slope Handling")
@export_range(0.0, 89.0, 0.1) var maximum_walkable_slope_angle: float = 45.0
@export var slope_acceleration: float = 8.0
@export var slope_friction: float = 6.0
@export var downhill_behavior: float = 1.0
@export var uphill_behavior: float = 0.85
@export var slope_snap_length: float = 0.35

@export_group("Collision")
@export_flags_3d_physics var ceiling_collision_mask: int = 1
@export var safe_margin: float = 0.001

var collision_shape: CollisionShape3D
var capsule_shape: CapsuleShape3D
var shape_query: PhysicsShapeQueryParameters3D
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var slide_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var wall_run_timer: float = 0.0
var dash_distance_remaining: float = 0.0
var air_dashes_remaining: int = 0
var current_capsule_height: float = 1.9
var current_head_height: float = 1.65
var wall_normal: Vector3 = Vector3.ZERO
var wall_side: float = 0.0
var dash_vertical_velocity: float = 0.0
var is_dashing: bool = false
var is_wall_running: bool = false
var dash_direction: Vector3 = Vector3.ZERO
var jump_was_held: bool = false

func _ready() -> void:
	if player == null or grapple == null:
		return
	collision_shape = player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		return
	if not (collision_shape.shape is CapsuleShape3D):
		return
	capsule_shape = collision_shape.shape.duplicate() as CapsuleShape3D
	collision_shape.shape = capsule_shape
	capsule_shape.radius = capsule_radius
	current_capsule_height = max(standing_height, capsule_radius * 2.0)
	current_head_height = standing_head_height
	capsule_shape.height = current_capsule_height
	collision_shape.position.y = current_capsule_height * 0.5
	shape_query = PhysicsShapeQueryParameters3D.new()
	shape_query.shape = capsule_shape
	shape_query.collision_mask = ceiling_collision_mask
	shape_query.exclude = [player.get_rid()]
	player.floor_max_angle = deg_to_rad(maximum_walkable_slope_angle)
	player.floor_snap_length = slope_snap_length
	player.safe_margin = safe_margin
	air_dashes_remaining = max(air_dash_count, 0)

func _physics_process(delta: float) -> void:
	if player == null or input == null or state == null or grapple == null or capsule_shape == null:
		return
	update_timers(delta)
	update_floor_tracking()
	grapple.process_physics_pre_movement(delta)
	var grapple_exit_consumed: bool = false
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
		apply_jump()
	if grapple.has_exit_velocity():
		player.velocity = grapple.consume_exit_velocity()
		grapple_exit_consumed = true
	player.move_and_slide()
	grapple.process_physics_post_movement(delta)
	if not grapple.is_grappling():
		update_wall_detection()
		update_movement_state()
	jump_was_held = input.jump_pressed
	if grapple_exit_consumed:
		jump_was_held = true

func update_timers(delta: float) -> void:
	coyote_timer = max(coyote_timer - delta, 0.0)
	jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)
	slide_timer = max(slide_timer - delta, 0.0)
	dash_timer = max(dash_timer - delta, 0.0)
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)
	wall_run_timer = max(wall_run_timer - delta, 0.0)

func update_floor_tracking() -> void:
	if player.is_on_floor():
		coyote_timer = coyote_time
		air_dashes_remaining = max(air_dash_count, 0)

func process_jump_buffer() -> void:
	if input.jump_just_pressed:
		jump_buffer_timer = jump_buffer_time

func process_dash_input() -> void:
	if not input.dash_pressed or dash_cooldown_timer > 0.0 or is_dashing:
		return
	var grounded: bool = player.is_on_floor()
	if grounded and not ground_dash_enabled:
		return
	if not grounded and not air_dash_enabled:
		return
	if not grounded and air_dashes_remaining <= 0:
		return
	start_dash()

func start_dash() -> void:
	var movement_direction: Vector3 = get_movement_direction()
	if movement_direction.length_squared() <= 0.001 or not dash_uses_movement_direction:
		movement_direction = -player.global_transform.basis.z
	dash_direction = movement_direction.normalized()
	var horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horizontal_velocity.length_squared() > 0.001 and dash_direction.dot(horizontal_velocity.normalized()) < 0.0:
		dash_direction = dash_direction.slerp(horizontal_velocity.normalized(), 0.35).normalized()
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_distance_remaining = max(dash_distance, 0.0)
	dash_vertical_velocity = player.velocity.y
	if not player.is_on_floor():
		air_dashes_remaining -= 1
	if dash_preserves_vertical_velocity:
		player.velocity = dash_direction * dash_speed + Vector3.UP * dash_vertical_velocity
	else:
		player.velocity = dash_direction * dash_speed

func process_dash(delta: float) -> void:
	if not is_dashing:
		return
	var target_velocity: Vector3 = dash_direction * dash_speed
	player.velocity.x = move_toward(player.velocity.x, target_velocity.x, dash_acceleration * delta)
	player.velocity.z = move_toward(player.velocity.z, target_velocity.z, dash_acceleration * delta)
	var moved_distance: float = Vector2(player.velocity.x, player.velocity.z).length() * delta
	dash_distance_remaining = max(dash_distance_remaining - moved_distance, 0.0)
	if dash_preserves_vertical_velocity:
		player.velocity.y = move_toward(player.velocity.y, dash_vertical_velocity, dash_braking * delta)
	else:
		player.velocity.y = move_toward(player.velocity.y, 0.0, max(dash_gravity_scale, 0.0) * delta)
	if dash_timer <= 0.0 or dash_distance_remaining <= 0.0:
		is_dashing = false
		var ending_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
		if ending_velocity.length() > dash_speed:
			ending_velocity = ending_velocity.normalized() * move_toward(dash_speed, ending_velocity.length(), dash_braking * delta)
		player.velocity.x = ending_velocity.x
		player.velocity.z = ending_velocity.z

func get_movement_direction() -> Vector3:
	if input.movement_input.length_squared() <= 0.001:
		return Vector3.ZERO
	var forward: Vector3 = -player.global_transform.basis.z
	var right: Vector3 = player.global_transform.basis.x
	var movement_direction: Vector3 = right * input.movement_input.x + forward * -input.movement_input.y
	movement_direction.y = 0.0
	return movement_direction.normalized()

func get_wish_direction() -> Vector3:
	var movement_direction: Vector3 = get_movement_direction()
	if player.is_on_floor():
		movement_direction = movement_direction.slide(player.get_floor_normal())
		if movement_direction.length_squared() > 0.001:
			movement_direction = movement_direction.normalized()
	return movement_direction

func get_target_speed() -> float:
	if state.is_sliding() or input.crouch_pressed:
		return crouch_speed
	if input.sprint_pressed:
		return sprint_speed
	return walk_speed

func process_ground_movement(delta: float) -> void:
	if not player.is_on_floor() or is_wall_running or state.is_sliding() or state.is_grappling():
		return
	var wish_direction: Vector3 = get_wish_direction()
	var horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	if wish_direction.length_squared() <= 0.001:
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, (ground_friction + ground_deceleration) * delta)
	else:
		var target_velocity: Vector3 = wish_direction * get_target_speed()
		var acceleration: float = ground_acceleration
		if horizontal_velocity.length_squared() > 0.001:
			var direction_alignment: float = horizontal_velocity.normalized().dot(target_velocity.normalized())
			if direction_alignment < 0.25:
				acceleration = direction_change_acceleration
			elif horizontal_velocity.length() > target_velocity.length():
				acceleration = ground_deceleration
		horizontal_velocity = horizontal_velocity.move_toward(target_velocity, acceleration * delta)
	apply_slope_behavior(horizontal_velocity, delta)
	if horizontal_velocity.length() < minimum_movement_speed and wish_direction.length_squared() <= 0.001:
		horizontal_velocity = Vector3.ZERO
	player.velocity.x = horizontal_velocity.x
	player.velocity.z = horizontal_velocity.z

func apply_slope_behavior(horizontal_velocity: Vector3, delta: float) -> void:
	if not player.is_on_floor():
		return
	var floor_normal: Vector3 = player.get_floor_normal()
	var downhill_direction: Vector3 = Vector3.DOWN.slide(floor_normal)
	if downhill_direction.length_squared() <= 0.001:
		return
	var slope_direction: Vector3 = downhill_direction.normalized()
	var movement_alignment: float = 0.0
	if horizontal_velocity.length_squared() > 0.001:
		movement_alignment = slope_direction.dot(horizontal_velocity.normalized())
	if movement_alignment > 0.0:
		player.velocity += slope_direction * slope_acceleration * downhill_behavior * delta
	elif movement_alignment < 0.0:
		player.velocity += slope_direction * slope_acceleration * (uphill_behavior - 1.0) * delta
	elif slope_friction > 0.0:
		player.velocity += slope_direction * slope_friction * delta

func process_air_movement(delta: float) -> void:
	if player.is_on_floor() or is_wall_running or state.is_grappling():
		return
	var wish_direction: Vector3 = get_movement_direction()
	var horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	if wish_direction.length_squared() <= 0.001:
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, air_deceleration * delta)
	else:
		var speed_along_wish: float = horizontal_velocity.dot(wish_direction)
		if speed_along_wish < air_speed_limit:
			horizontal_velocity += wish_direction * air_acceleration * air_control * delta
		else:
			var steering_target: Vector3 = wish_direction * horizontal_velocity.length()
			horizontal_velocity = horizontal_velocity.lerp(steering_target, clamp(air_steering_responsiveness * air_control * delta, 0.0, 1.0))
	player.velocity.x = horizontal_velocity.x
	player.velocity.z = horizontal_velocity.z

func process_gravity(delta: float) -> void:
	if state.is_grappling():
		return
	if player.is_on_floor():
		if player.velocity.y < 0.0:
			player.velocity.y = 0.0
		return
	if is_wall_running:
		player.velocity.y = move_toward(player.velocity.y, -wall_run_gravity, wall_run_gravity * delta)
		return
	var gravity: float = gravity_while_rising
	if player.velocity.y <= 0.0:
		gravity = gravity_while_falling * fall_multiplier
	player.velocity.y = move_toward(player.velocity.y, -maximum_fall_speed, gravity * delta)

func apply_jump() -> void:
	if state.is_grappling():
		return
	if jump_buffer_timer > 0.0 and not is_dashing:
		if is_wall_running:
			wall_jump()
			jump_buffer_timer = 0.0
		elif player.is_on_floor() or coyote_timer > 0.0:
			var applied_jump_velocity: float = jump_velocity
			if state.is_sliding():
				applied_jump_velocity *= slide_jump_multiplier
			player.velocity.y = applied_jump_velocity
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			if state.is_sliding():
				end_slide()
	if not input.jump_pressed and jump_was_held and player.velocity.y > 0.0:
		player.velocity.y *= variable_jump_cutoff

func process_stance(delta: float) -> void:
	var target_crouched: bool = input.crouch_pressed or state.is_sliding()
	var target_height: float = standing_height
	var target_head_height: float = standing_head_height
	if target_crouched:
		target_height = crouching_height
		target_head_height = crouching_head_height
	var clamped_target_height: float = max(target_height, capsule_radius * 2.0)
	var new_height: float = move_toward(current_capsule_height, clamped_target_height, crouch_transition_speed * delta)
	if not target_crouched and not can_stand(new_height):
		new_height = current_capsule_height
	set_capsule_height(new_height)
	current_head_height = move_toward(current_head_height, target_head_height, crouch_transition_speed * delta)

func set_capsule_height(height: float) -> void:
	current_capsule_height = max(height, capsule_radius * 2.0)
	capsule_shape.height = current_capsule_height
	collision_shape.position.y = current_capsule_height * 0.5

func can_stand(target_height: float) -> bool:
	if target_height <= current_capsule_height:
		return true
	var previous_height: float = capsule_shape.height
	capsule_shape.height = max(target_height, capsule_radius * 2.0)
	shape_query.shape = capsule_shape
	var test_transform: Transform3D = player.global_transform
	test_transform.origin.y += (target_height - current_capsule_height) * 0.5
	shape_query.transform = test_transform
	var hits: Array[Dictionary] = player.get_world_3d().direct_space_state.intersect_shape(shape_query, 1)
	capsule_shape.height = previous_height
	return hits.is_empty()

func begin_slide() -> void:
	if not player.is_on_floor() or is_dashing or state.is_sliding() or state.is_grappling():
		return
	var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	if horizontal_speed < slide_minimum_speed:
		return
	slide_timer = slide_duration
	state.change_state(PlayerState.MovementState.SLIDING)
	slide_camera_roll_sign = sign(player.velocity.dot(player.global_transform.basis.x))
	if abs(slide_camera_roll_sign) < 0.1:
		slide_camera_roll_sign = 1.0

func process_slide(delta: float) -> void:
	if state.is_sliding():
		if input.jump_just_pressed:
			jump_buffer_timer = jump_buffer_time
			return
		if slide_timer <= 0.0 or (slide_cancel_on_release and not input.crouch_pressed):
			end_slide()
			return
		var horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
		var movement_direction: Vector3 = get_movement_direction()
		if movement_direction.length_squared() > 0.001:
			horizontal_velocity = horizontal_velocity.move_toward(
				movement_direction * max(horizontal_velocity.length(), slide_minimum_speed),
				slide_steering * delta
			)
		else:
			horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, slide_deceleration * delta)
		var downhill_direction: Vector3 = Vector3.DOWN.slide(player.get_floor_normal())
		if downhill_direction.length_squared() > 0.001:
			horizontal_velocity += downhill_direction.normalized() * slide_slope_influence * delta
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, slide_friction * delta)
		if horizontal_velocity.length_squared() > 0.001:
			var slide_speed: float = horizontal_velocity.length()
			slide_speed = move_toward(slide_speed, slide_minimum_speed, slide_acceleration * delta)
			horizontal_velocity = horizontal_velocity.normalized() * slide_speed
		player.velocity.x = horizontal_velocity.x
		player.velocity.z = horizontal_velocity.z
		return
	if input.crouch_just_pressed and input.sprint_pressed:
		begin_slide()

func end_slide() -> void:
	slide_timer = 0.0
	state.change_state(PlayerState.MovementState.GROUNDED)

func update_wall_detection() -> void:
	wall_normal = Vector3.ZERO
	wall_side = 0.0
	if not wall_run_enabled or player.is_on_floor() or state.is_grappling():
		return
	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var origin: Vector3 = player.global_position + Vector3.UP * max(current_capsule_height * 0.55, 0.9)
	var right: Vector3 = player.global_transform.basis.x
	var candidate_directions: Array[Vector3] = [right, -right]
	var closest_distance: float = wall_detection_distance
	for candidate_direction: Vector3 in candidate_directions:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			origin,
			origin + candidate_direction * wall_detection_distance,
			wall_collision_mask,
			[player.get_rid()]
		)
		var hit: Dictionary = space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		var hit_position: Vector3 = hit.get("position", origin)
		var hit_normal: Vector3 = hit.get("normal", Vector3.ZERO)
		var hit_distance: float = origin.distance_to(hit_position)
		if hit_distance < closest_distance:
			closest_distance = hit_distance
			wall_normal = hit_normal
			wall_side = sign(candidate_direction.dot(right))

func can_start_wall_run() -> bool:
	if not wall_run_enabled or player.is_on_floor() or is_dashing or state.is_grappling() or wall_normal == Vector3.ZERO:
		return false
	if Vector2(player.velocity.x, player.velocity.z).length() < wall_run_entry_speed:
		return false
	return input.movement_input.length_squared() > 0.001

func start_wall_run() -> void:
	is_wall_running = true
	wall_run_timer = wall_run_duration
	state.change_state(PlayerState.MovementState.WALL_RUNNING)

func process_wall_run(delta: float) -> void:
	if state.is_grappling():
		return
	if is_wall_running:
		if wall_normal == Vector3.ZERO or wall_run_timer <= 0.0 or player.is_on_floor():
			is_wall_running = false
			return
		var along_wall: Vector3 = Vector3.UP.cross(wall_normal).normalized()
		if along_wall.dot(-player.global_transform.basis.z) < 0.0:
			along_wall = -along_wall
		var target_velocity: Vector3 = along_wall * wall_run_speed
		var current_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
		current_velocity = current_velocity.move_toward(target_velocity, wall_run_acceleration * delta)
		var steering_direction: Vector3 = get_movement_direction().slide(wall_normal)
		if steering_direction.length_squared() > 0.001:
			var steering_target: Vector3 = steering_direction.normalized() * max(current_velocity.length(), wall_run_speed)
			current_velocity = current_velocity.lerp(steering_target, clamp(wall_run_steering * delta * 6.0, 0.0, 1.0))
		player.velocity.x = current_velocity.x
		player.velocity.z = current_velocity.z
		player.velocity += -wall_normal * wall_stick_force * delta
		return
	if can_start_wall_run():
		start_wall_run()

func wall_jump() -> void:
	var jump_direction: Vector3 = (wall_normal * wall_jump_direction + Vector3.UP).normalized()
	var horizontal_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var preserved_velocity: Vector3 = horizontal_velocity * wall_jump_horizontal_influence
	player.velocity = jump_direction * wall_jump_strength + preserved_velocity
	is_wall_running = false
	wall_run_timer = 0.0
	coyote_timer = 0.0
	state.change_state(PlayerState.MovementState.AIRBORNE)

func update_movement_state() -> void:
	if state.is_grappling():
		return
	if is_wall_running:
		state.change_state(PlayerState.MovementState.WALL_RUNNING)
		return
	if state.is_sliding() and slide_timer > 0.0:
		return
	if player.is_on_floor():
		state.change_state(PlayerState.MovementState.GROUNDED)
		return
	state.change_state(PlayerState.MovementState.AIRBORNE)
