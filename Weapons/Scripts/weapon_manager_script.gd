extends Node3D

class_name WeaponManager

var weapon_stack : Array[int]
var weapon_list : Dictionary[int, WeaponSlot]
@export var start_weapons : Array[WeaponSlot]

var current_weapon : WeaponSlot = null 
var weapon_index : int = 0

var can_change_weapons : bool = true
var can_use_weapon : bool = true

@export var camera_recoil_holder: CameraRecoilHolder
@export var viewport_cam: Camera3D
@export var weapon_container : Node3D
@export var shoot_manager : Node3D 
@export var reload_manager : Node3D
@export var ammo_manager : Node3D
@export var anim_player : AnimationPlayer
@export var anim_manager : Node3D
@onready var audio_manager : PackedScene = preload("../../Misc/AudioManager/audio_manager_scene.tscn")
@onready var bullet_decal : PackedScene = preload("../../Weapons/Scenes/bullet_decal_scene.tscn")
@export var hud: HUD
@export var link_component: LinkComponent

signal weapon_stack_updated

@onready var head : Node3D = get_parent().get_node("Head")
const HEAD_TO_WEAPON_Y : float = -0.05
@export var weapon_follow_speed : float = 100.0


func _ready() -> void:
	await initialize()
	
func initialize() -> void:
	for weapon in weapon_container.get_children():
		weapon.model.hide()
		weapon_list[weapon.resources.weapon_id] = weapon
		
	for weapon in start_weapons:
		weapon_stack.append(weapon.resources.weapon_id)
		force_attack_point_transform_values(weapon.attack_point)
	weapon_stack_updated.emit()
	
	if weapon_stack.size() > 0:
		await enter_weapon(weapon_stack[0])
	else:
		push_error("Play har has no weapons in his inventory")
		
func exit_weapon(next_weapon : int) -> void:
	can_change_weapons = false
	can_use_weapon = false
	if current_weapon.resources.is_shooting: current_weapon.resources.is_shooting = false
	if current_weapon.resources.is_reloading: current_weapon.resources.is_reloading = false
		
	if current_weapon.resources.unequip_anim_name != "":
		anim_manager.play_animation("UnequipAnim%s" % current_weapon.resources.weapon_name, current_weapon.resources.unequip_anim_speed, false)
	await get_tree().create_timer(current_weapon.resources.unequip_time).timeout
		
	current_weapon.model.hide()
		
	await enter_weapon(next_weapon)
	
func enter_weapon(next_weapon : int) -> void:
	current_weapon = weapon_list[next_weapon]
	next_weapon = 0
	current_weapon.model.show()
	
	shoot_manager.get_current_weapon(current_weapon)
	reload_manager.get_current_weapon(current_weapon)
	anim_manager.get_current_weapon(current_weapon)
	
	await weapon_sound_management(current_weapon.resources.equip_sound, current_weapon.resources.equip_sound_speed)
	
	anim_player.playback_default_blend_time = current_weapon.resources.anim_blend_time
	
	if current_weapon.resources.equip_anim_name != "":
		anim_manager.play_animation("EquipAnim%s" % current_weapon.resources.weapon_name, current_weapon.resources.equip_anim_speed, false)
	await get_tree().create_timer(current_weapon.resources.equip_time).timeout
	
	if current_weapon.resources.is_shooting: current_weapon.resources.is_shooting = false
	if current_weapon.resources.is_reloading: current_weapon.resources.is_reloading = false
	can_use_weapon = true
	can_change_weapons = true
	
	weapon_stack_updated.emit()
	
func _process(delta : float) -> void:
	var target_y : float = head.position.y + HEAD_TO_WEAPON_Y
	position.y = lerpf(position.y, target_y, 1.0 - exp(-weapon_follow_speed * delta))
	if current_weapon and current_weapon.resources and can_use_weapon:
		await weapon_inputs()
		
		reload_manager.auto_reload()
		
	rotate_relative_to_viewport_camera()
		
func weapon_inputs() -> void:
	if Input.is_action_pressed("shoot_action"): shoot_manager.shoot()
			
	if Input.is_action_just_pressed("reload_action"): reload_manager.reload()
	
	if Input.is_action_just_pressed("weapon_wheel_up_action"):
		if can_change_weapons and !current_weapon.resources.is_shooting and !current_weapon.resources.is_reloading:
			weapon_index = min(weapon_index + 1, weapon_stack.size() - 1)
			await change_weapon(weapon_stack[weapon_index])
			
	if Input.is_action_just_pressed("weapon_wheel_down_action"):
		if can_change_weapons and !current_weapon.resources.is_shooting and !current_weapon.resources.is_reloading:
			weapon_index = max(weapon_index - 1, 0)
			await change_weapon(weapon_stack[weapon_index])
			
func change_weapon(next_weapon : int) -> void:
	if can_change_weapons and !current_weapon.resources.is_shooting and !current_weapon.resources.is_reloading:
		await exit_weapon(next_weapon)
	else:
		push_error("Can't change weapon now")
		return 
		
func rotate_relative_to_viewport_camera() -> void:
	global_rotation = viewport_cam.global_rotation
	
func display_muzzle_flash() -> void:
	if current_weapon.resources.muzzle_flash_ref:
		var muzzle_flash_ins : GPUParticles3D = current_weapon.resources.muzzle_flash_ref.instantiate()
		add_child(muzzle_flash_ins)
		muzzle_flash_ins.global_position = current_weapon.muzzle_flash_spawner.global_position
		muzzle_flash_ins.emitting = true
	else:
		push_error("%s doesn't have a muzzle flash reference" % current_weapon.resources.weapon_name)
		return
		
func display_bullet_hole(collider_point : Vector3, collider_normal : Vector3) -> void:
	var bullet_decal_instance : Node3D = bullet_decal.instantiate()
	get_tree().get_root().add_child(bullet_decal_instance)
	bullet_decal_instance.global_position = collider_point
	bullet_decal_instance.look_at(collider_point - collider_normal, Vector3.UP)
	bullet_decal_instance.rotate_object_local(Vector3(1.0, 0.0, 0.0), 90)
	
func weapon_sound_management(sound_name : AudioStream, sound_speed : float) -> void:
	var audio_ins : AudioStreamPlayer3D = audio_manager.instantiate()
	get_tree().get_root().add_child.call_deferred(audio_ins)
	await get_tree().process_frame
	if audio_ins.is_inside_tree():
		audio_ins.global_transform = current_weapon.attack_point.global_transform
		audio_ins.bus = "SFX"
		audio_ins.pitch_scale = sound_speed
		audio_ins.stream = sound_name
		audio_ins.play()
	else:
		print("The sound can't be played, AudioStreamPlayer3D instance is not in the scene tree")
	
func force_attack_point_transform_values(attack_point : Marker3D) -> void:
	if attack_point.rotation != Vector3.ZERO: attack_point.rotation = Vector3.ZERO
