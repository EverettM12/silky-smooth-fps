extends Node3D

var current_weapon : WeaponSlot
var point_of_collision : Vector3 = Vector3.ZERO
var rng : RandomNumberGenerator

@onready var weapon_manager : Node3D = %WeaponManager

func get_current_weapon(current_weapon_ref : WeaponSlot) -> void:
	#get current weapon resources
	current_weapon = current_weapon_ref
	
func shoot() -> void:
	if !current_weapon.resources.is_shooting and (
	#magazine isn't empty, and has >= ammo than the number of projectiles required for a shot
	(current_weapon.resources.total_ammo_in_mag > 0 and current_weapon.resources.total_ammo_in_mag >= current_weapon.resources.nb_proj_shots_at_same_time)
	or 
	#has all ammos in the magazine, and number of ammo is positive
	(current_weapon.resources.all_ammo_in_mag and weapon_manager.ammo_manager.ammo_dict[current_weapon.resources.ammo_type] > 0 and \
	#has >= ammo than the number of projectiles required for a shot
	weapon_manager.ammo_manager.amm_dict[current_weapon.resources.ammo_type] >= current_weapon.resources.nb_proj_shots_at_same_time)
	) and !current_weapon.resources.is_reloading:
		current_weapon.resources.is_shooting = true
		
		#number of successive shots (for example if 3, the weapon will shot 3 times in a row)
		for i in range(current_weapon.resources.nb_proj_shots):
			#same conditions has before, are checked before every shot
			if ((current_weapon.resources.total_ammo_in_mag > 0 and current_weapon.resources.total_ammo_in_mag >= current_weapon.resources.nb_proj_shots_at_same_time) 
			or (current_weapon.resources.all_ammo_in_mag and weapon_manager.ammo_manager.ammo_dict[current_weapon.resources.ammo_type] > 0) and \
			weapon_manager.ammo_manager.ammo_dict[current_weapon.resources.ammo_type] >= current_weapon.resources.nb_proj_shots_at_same_time):
				
				weapon_manager.weapon_sound_management(current_weapon.resources.shoot_sound, current_weapon.resources.shoot_sound_speed)
				
				if current_weapon.resources.shoot_anim_name != "":
					weapon_manager.anim_manager.play_animation("ShootAnim%s" % current_weapon.resources.weapon_name, current_weapon.resources.shoot_anim_speed, true)
				else:
					print("%s doesn't have a shoot animation" % current_weapon.resources.weapon_name)
					
				#number projectiles shots at the same time (for example, 
				#a shotgun shell is constituted of ~ 20 pellets that are spread across the target, 
				#so 20 projectiles shots at the same time)
				for j in range(0, current_weapon.resources.nb_proj_shots_at_same_time):
					if current_weapon.resources.all_ammo_in_mag: weapon_manager.ammo_manager.ammo_dict[current_weapon.resources.ammo_type] -= 1
					else: current_weapon.resources.total_ammo_in_mag -= 1
					
					#get the collision point
					point_of_collision = get_camera_fov()
					
					#call the fonction corresponding to the selected type
					if current_weapon.resources.type == current_weapon.resources.TYPES.HITSCAN: hitscan_shot(point_of_collision)
					elif current_weapon.resources.type == current_weapon.resources.TYPES.PROJECTILE: projectile_shot(point_of_collision)
					
				if current_weapon.resources.show_muzzle_flash: weapon_manager.display_muzzle_flash()
				
				weapon_manager.camera_recoil_holder.set_recoil_values(current_weapon.resources.base_rot_speed, current_weapon.resources.target_rot_speed)
				weapon_manager.camera_recoil_holder.add_recoil(current_weapon.resources.recoil_val)
				
				await get_tree().create_timer(current_weapon.resources.time_between_shots).timeout
				
			else:
				print("Not enought ammunitions to shoot")
				
		current_weapon.resources.is_shooting = false
		
func get_camera_fov() -> Vector3:
	var viewport : Viewport = get_viewport()
	var camera : Camera3D = viewport.get_camera_3d()
	var center : Vector2 = viewport.get_visible_rect().size / 2.0

	var origin : Vector3 = camera.project_ray_origin(center)
	var direction : Vector3 = camera.project_ray_normal(center)
	var ray_length : float = 280.0
	if current_weapon.resources.type == current_weapon.resources.TYPES.HITSCAN:
		ray_length = current_weapon.resources.max_range

	var end : Vector3 = origin + direction * ray_length
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
	var hit : Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if !hit.is_empty() else end

func hitscan_shot(point_of_collision_hitscan : Vector3) -> void:
	rng = RandomNumberGenerator.new()
	
	#set up weapon shot sprad 
	var spread : Vector3 = Vector3(rng.randf_range(current_weapon.resources.min_spread, current_weapon.resources.max_spread), rng.randf_range(current_weapon.resources.min_spread, current_weapon.resources.max_spread), rng.randf_range(current_weapon.resources.min_spread, current_weapon.resources.max_spread))
	
	#calculate direction of the hitscan bullet 
	var hitscan_bullet_direction : Vector3 = (point_of_collision_hitscan - current_weapon.attack_point.get_global_transform().origin).normalized()
	
	#create new intersection space to contain possibe collisions 
	var new_intersection : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(current_weapon.attack_point.get_global_transform().origin, point_of_collision_hitscan + spread + hitscan_bullet_direction * 2)
	new_intersection.collide_with_areas = true
	new_intersection.collide_with_bodies = true 
	var hitscan_bullet_collision : Dictionary = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	
	#if the raycast has collide
	if hitscan_bullet_collision: 
		var collider = hitscan_bullet_collision.collider
		var collider_point : Vector3 = hitscan_bullet_collision.position
		var collider_normal : Vector3 = hitscan_bullet_collision.normal 
		var final_damage : int = 0
		
		if collider.is_in_group("Enemies") and collider.has_method("hitscan_hit"):
			@warning_ignore("narrowing_conversion")
			final_damage = current_weapon.resources.damage_per_proj * current_weapon.resources.damage_dropoff.sample(point_of_collision_hitscan.distance_to(global_position) / current_weapon.resources.max_range)
			collider.hitscan_hit(final_damage, hitscan_bullet_direction, hitscan_bullet_collision.position)
		
		elif collider.is_in_group("EnemiesHead") and collider.has_method("hitscan_hit"):
				@warning_ignore("narrowing_conversion")
				final_damage = current_weapon.resources.damage_per_proj * current_weapon.resources.headshot_damage_mult * current_weapon.resources.damage_dropoff.sample(point_of_collision_hitscan.distance_to(global_position) / current_weapon.resources.max_range)
				collider.hitscan_hit(final_damage, hitscan_bullet_direction, hitscan_bullet_collision.position)
		
		elif collider.is_in_group("HitableObjects") and collider.has_method("hitscan_hit"): 
			@warning_ignore("narrowing_conversion")
			final_damage = current_weapon.resources.damage_per_proj * current_weapon.resources.damage_dropoff.sample(point_of_collision_hitscan.distance_to(global_position) / current_weapon.resources.max_range)
			collider.hitscan_hit(final_damage/6.0, hitscan_bullet_direction, hitscan_bullet_collision.position)
			weapon_manager.display_bullet_hole(collider_point, collider_normal)
			
		else:
			weapon_manager.display_bullet_hole(collider_point, collider_normal)
			
func projectile_shot(point_of_collision_projectile : Vector3) -> void:
	rng = RandomNumberGenerator.new()
	
	#set up weapon shot sprad 
	var spread : Vector3 = Vector3(rng.randf_range(current_weapon.resources.min_spread, current_weapon.resources.max_spread), rng.randf_range(current_weapon.resources.min_spread, current_weapon.resources.max_spread), rng.randf_range(current_weapon.resources.min_spread, current_weapon.resources.max_spread))
	
	#Calculate direction of the projectile
	var projectile_direction : Vector3 = ((point_of_collision_projectile - current_weapon.attack_point.get_global_transform().origin).normalized() + spread)
	
	#Instantiate projectile
	var proj_ins : Projectile = current_weapon.resources.proj_ref.instantiate()
	
	#set projectile properties
	proj_ins.global_transform = current_weapon.attack_point.global_transform
	proj_ins.direction = projectile_direction
	proj_ins.damage = current_weapon.resources.damage_per_proj
	proj_ins.time_before_vanish = current_weapon.resources.proj_time_before_vanish
	proj_ins.gravity_scale = current_weapon.resources.proj_gravity_val
	proj_ins.is_explosive = current_weapon.resources.is_proj_explosive
	
	get_tree().get_root().add_child(proj_ins)
	
	proj_ins.set_linear_velocity(projectile_direction * current_weapon.resources.proj_move_speed)
