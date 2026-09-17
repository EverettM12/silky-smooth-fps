class_name PlayerTraversalCamera
extends Node

@export_group("Smoothing")
@export var position_spring_frequency: float = 18.0
@export var rotation_spring_frequency: float = 18.0
@export var fov_spring_frequency: float = 16.0
@export var return_frequency: float = 12.0

@export_group("FOV")
@export var traversal_fov_maximum: float = 150.0

@onready var traversal: PlayerTraversal = get_parent() as PlayerTraversal
@onready var camera_motion: Node3D = get_node("../../Head/CameraMotion") as Node3D
@onready var camera: Camera3D = get_node("../../Head/CameraMotion/Camera3D") as Camera3D

var applied_position_offset: Vector3 = Vector3.ZERO
var applied_rotation_offset: Vector3 = Vector3.ZERO
var applied_fov_offset: float = 0.0
var position_value: Vector3 = Vector3.ZERO
var position_velocity: Vector3 = Vector3.ZERO
var rotation_value: Vector3 = Vector3.ZERO
var rotation_velocity: Vector3 = Vector3.ZERO
var fov_value: float = 0.0
var fov_velocity: float = 0.0
var minimum_spring_distance: float = 0.0001
var minimum_spring_velocity: float = 0.0001

func _ready() -> void:
	process_priority = 10

func _process(delta: float) -> void:
	if traversal == null or camera_motion == null or camera == null:
		return
	camera_motion.position -= applied_position_offset
	camera_motion.rotation -= applied_rotation_offset
	camera.fov -= applied_fov_offset
	applied_position_offset = Vector3.ZERO
	applied_rotation_offset = Vector3.ZERO
	applied_fov_offset = 0.0
	var target_position: Vector3 = traversal.get_camera_position_offset()
	var target_rotation: Vector3 = Vector3(
		deg_to_rad(traversal.get_camera_pitch_offset()),
		0.0,
		deg_to_rad(traversal.get_camera_roll_offset())
	)
	var target_fov_offset: float = traversal.get_camera_fov_boost()
	var position_frequency: float = position_spring_frequency
	var rotation_frequency: float = rotation_spring_frequency
	var fov_frequency: float = fov_spring_frequency
	if not traversal.is_traversing():
		position_frequency = return_frequency
		rotation_frequency = return_frequency
		fov_frequency = return_frequency
	position_frequency = max(position_frequency, traversal.get_camera_spring_frequency())
	rotation_frequency = max(rotation_frequency, traversal.get_camera_spring_frequency())
	var position_spring: Dictionary = critical_damp_vector3(
		position_value,
		position_velocity,
		target_position,
		position_frequency,
		delta
	)
	position_value = position_spring["value"] as Vector3
	position_velocity = position_spring["velocity"] as Vector3
	var rotation_spring: Dictionary = critical_damp_vector3(
		rotation_value,
		rotation_velocity,
		target_rotation,
		rotation_frequency,
		delta
	)
	rotation_value = rotation_spring["value"] as Vector3
	rotation_velocity = rotation_spring["velocity"] as Vector3
	var fov_spring_target: float = target_fov_offset
	if fov_spring_target > 0.0:
		fov_frequency = max(fov_frequency, traversal.traversal_fov_response)
	else:
		fov_frequency = max(fov_frequency, traversal.traversal_fov_return)
	var fov_spring: Dictionary = critical_damp_scalar(
		fov_value,
		fov_velocity,
		fov_spring_target,
		fov_frequency,
		delta
	)
	fov_value = fov_spring["value"] as float
	fov_velocity = fov_spring["velocity"] as float
	var allowed_fov_offset: float = max(traversal_fov_maximum - camera.fov, 0.0)
	applied_position_offset = position_value
	applied_rotation_offset = rotation_value
	applied_fov_offset = min(fov_value, allowed_fov_offset)
	camera_motion.position += applied_position_offset
	camera_motion.rotation += applied_rotation_offset
	camera.fov += applied_fov_offset

func critical_damp_scalar(current_value: float, current_velocity: float, target_value: float, frequency: float, delta: float) -> Dictionary:
	var angular_frequency: float = max(frequency, 0.001)
	var offset: float = current_value - target_value
	var exponential_decay: float = exp(-angular_frequency * delta)
	var temporary_value: float = (current_velocity + angular_frequency * offset) * delta
	var new_offset: float = (offset + temporary_value) * exponential_decay
	var new_velocity: float = (current_velocity - angular_frequency * temporary_value) * exponential_decay
	var new_value: float = target_value + new_offset
	if abs(new_value - target_value) < minimum_spring_distance and abs(new_velocity) < minimum_spring_velocity:
		new_value = target_value
		new_velocity = 0.0
	return {
		"value": new_value,
		"velocity": new_velocity
	}

func critical_damp_vector3(current_value: Vector3, current_velocity: Vector3, target_value: Vector3, frequency: float, delta: float) -> Dictionary:
	var angular_frequency: float = max(frequency, 0.001)
	var offset: Vector3 = current_value - target_value
	var exponential_decay: float = exp(-angular_frequency * delta)
	var temporary_value: Vector3 = (current_velocity + offset * angular_frequency) * delta
	var new_offset: Vector3 = (offset + temporary_value) * exponential_decay
	var new_velocity: Vector3 = (current_velocity - temporary_value * angular_frequency) * exponential_decay
	var new_value: Vector3 = target_value + new_offset
	if new_value.distance_squared_to(target_value) < minimum_spring_distance * minimum_spring_distance and new_velocity.length_squared() < minimum_spring_velocity * minimum_spring_velocity:
		new_value = target_value
		new_velocity = Vector3.ZERO
	return {
		"value": new_value,
		"velocity": new_velocity
	}
