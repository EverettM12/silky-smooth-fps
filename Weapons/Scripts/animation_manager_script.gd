extends Node3D

class_name AnimationManager

var current_weapon : WeaponSlot
var current_tilt_val : Vector3 = Vector3.ZERO
var current_sway_pos_val : Vector3 = Vector3.ZERO
var current_sway_rot_val : Vector3 = Vector3.ZERO
var current_bob_val : Vector3 = Vector3.ZERO

@export var camera_holder : CameraHolder
@export var play_char : Node3D
@export var anim_player : AnimationPlayer
@export var weapon_manager : Node3D

func get_current_weapon(current_weapon_ref : WeaponSlot) -> void:
	current_weapon = current_weapon_ref

func _process(delta : float) -> void:
	if current_weapon and current_weapon.model:
		var tilt_values : Vector3 = weapon_tilt_calculus(play_char.player_movement.input_direction, delta) #rot
		var sway_values : Array[Vector3] = weapon_sway_calculus(camera_holder.mouse_input, delta) #pos and rot
		var bob_values : Vector3 = weapon_bob_calculus(play_char.velocity.length(),delta) #pos
		
		weapon_model_positioning(tilt_values, sway_values, bob_values)

func weapon_tilt_calculus(play_char_input : Vector2, delta : float) -> Vector3:
	var tilt_target : Vector3 = Vector3.ZERO

	if current_weapon.resources.axis_to_tilt == current_weapon.resources.AXIS_TO_TILT_TYPES.X:
		if play_char_input.x == 0.0:
			tilt_target.x = 0.0
		else:
			tilt_target.x = play_char_input.x * current_weapon.resources.tilt_rot_amount
			
	elif current_weapon.resources.axis_to_tilt == current_weapon.resources.AXIS_TO_TILT_TYPES.Y:
		if play_char_input.x == 0.0:
			tilt_target.y = 0.0
		else:
			tilt_target.y = play_char_input.x * current_weapon.resources.tilt_rot_amount
			
	elif current_weapon.resources.axis_to_tilt == current_weapon.resources.AXIS_TO_TILT_TYPES.Z:
		if play_char_input.x == 0.0:
			tilt_target.z = 0.0
		else:
			tilt_target.z = play_char_input.x * current_weapon.resources.tilt_rot_amount
	
	current_tilt_val = lerp(current_tilt_val, tilt_target, current_weapon.resources.tilt_rot_speed * delta)
	
	return current_tilt_val

func weapon_sway_calculus(mouse_input : Vector2, delta : float) -> Array[Vector3]:
	if mouse_input.length() <= 4.0:
		current_sway_pos_val.x = move_toward(current_sway_pos_val.x, 0.0, delta * current_weapon.resources.back_to_origin_pos_speed)
		current_sway_pos_val.y = move_toward(current_sway_pos_val.y, 0.0, delta * current_weapon.resources.back_to_origin_pos_speed)
		current_sway_pos_val.z = move_toward(current_sway_pos_val.z, 0.0, delta * current_weapon.resources.back_to_origin_pos_speed)
		
		current_sway_rot_val.x = move_toward(current_sway_rot_val.x, 0.0, delta * current_weapon.resources.back_to_origin_pos_speed)
		current_sway_rot_val.y = move_toward(current_sway_rot_val.y, 0.0, delta * current_weapon.resources.back_to_origin_pos_speed)
		current_sway_rot_val.z = move_toward(current_sway_rot_val.z, 0.0, delta * current_weapon.resources.back_to_origin_pos_speed)
	else:
		mouse_input.x = clamp(mouse_input.x, current_weapon.resources.min_sway_val.x, current_weapon.resources.max_sway_val.x)
		mouse_input.y = clamp(mouse_input.y, current_weapon.resources.min_sway_val.y, current_weapon.resources.max_sway_val.y)

		var sway_pos_target : Vector3 = Vector3.ZERO
		var sway_rot_target : Vector3 = Vector3.ZERO
		
		sway_pos_target.x = mouse_input.x * current_weapon.resources.sway_amount_pos
		sway_pos_target.y = -mouse_input.y * current_weapon.resources.sway_amount_pos
		current_sway_pos_val = lerp(current_sway_pos_val, sway_pos_target, current_weapon.resources.sway_speed_pos * delta)
		
		sway_rot_target.y = -deg_to_rad(mouse_input.x * current_weapon.resources.sway_amount_rot)
		sway_rot_target.x = deg_to_rad(mouse_input.y * current_weapon.resources.sway_amount_rot)
		current_sway_rot_val = lerp(current_sway_rot_val, sway_rot_target, current_weapon.resources.sway_speed_rot * delta)
	
	return [current_sway_pos_val, current_sway_rot_val]

func weapon_bob_calculus(vel : float, delta : float) -> Vector3:
	var bob_pos_target : Vector3 = Vector3.ZERO
	bob_pos_target.y = sin(Time.get_ticks_msec() * (current_weapon.resources.bob_freq / 100.0)) * (current_weapon.resources.bob_amount / 100.0) * vel
	bob_pos_target.x = sin(Time.get_ticks_msec() * (current_weapon.resources.bob_freq / 100.0) * 0.5) * (current_weapon.resources.bob_amount / 100.0) * vel
	
	current_bob_val = lerp(current_bob_val, bob_pos_target, current_weapon.resources.bob_speed * delta)
	
	return current_bob_val

func weapon_model_positioning(tilt_values : Vector3, sway_values : Array[Vector3], bob_values : Vector3) -> void:
	current_weapon.model.position = current_weapon.resources.pos_val[0] + sway_values[0] + bob_values
	current_weapon.model.rotation = current_weapon.resources.pos_val[1] + sway_values[1] + tilt_values

func play_animation(anim_name : String, anim_speed : float, has_to_restart_anim : bool) -> void:
	if current_weapon.resources and anim_player:
		if has_to_restart_anim and anim_player.current_animation == anim_name:
			anim_player.seek(0, true)
		anim_player.play("%s" % anim_name, -1, anim_speed)
