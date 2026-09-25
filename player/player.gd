class_name Player
extends CharacterBody3D

@export_group("Look")
@export var mouse_sensitivity: float = 0.0025
@export var controller_sensitivity: float = 2.5
@export var vertical_look_sensitivity: float = 1.0
@export var horizontal_look_sensitivity: float = 1.0
@export var look_smoothing: float = 0.0
@export var minimum_pitch_degrees: float = -89.0
@export var maximum_pitch_degrees: float = 89.0

@export_group("Health")
@export var max_health: float = 100.0
var health: float = 100.0

@export_group("Cursor")
@export var capture_mouse_on_ready: bool = true
@export_group("")

@onready var head: Node3D = $Head
@onready var player_input: PlayerInput = $PlayerInput
@onready var player_movement: PlayerMovement = $PlayerMovement
@onready var camera: Camera3D = $Head/CameraMotion/Camera3D
@onready var health_ui: Control = $HealthUI/Root
@onready var health_bar: ProgressBar = $HealthUI/Root/MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $HealthUI/Root/MarginContainer/VBoxContainer/HealthLabel
@onready var mpp: MPPlayer = get_parent() as MPPlayer

signal health_changed(current_health: float, current_max_health: float)

var target_pitch: float = 0.0
var smoothed_look_input: Vector2 = Vector2.ZERO
var networked: bool = false
var is_local_player: bool = true
var network_player_id: int = 0
var network_target_position: Vector3 = Vector3.ZERO
var network_target_velocity: Vector3 = Vector3.ZERO
var network_target_yaw: float = 0.0
var network_target_pitch: float = 0.0
var network_tick_counter: int = 0

func configure_networked(local: bool, player_id: int, authority_id: int) -> void:
	networked = true
	is_local_player = local
	network_player_id = player_id
	set_multiplayer_authority(authority_id)
	if is_inside_tree():
		_apply_network_mode()

func _ready() -> void:
	if mpp != null:
		networked = true
		is_local_player = mpp.is_local
		network_player_id = mpp.player_id
		network_target_position = global_position
		network_target_velocity = velocity
		network_target_yaw = rotation.y
		network_target_pitch = head.rotation.x
	health = clampf(max_health, 0.0, max_health)
	health_changed.connect(_update_health_ui)
	_update_health_ui(health, max_health)
	if networked:
		_apply_network_mode()
	elif capture_mouse_on_ready:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _apply_network_mode() -> void:
	var player_camera_node: Node = get_node_or_null("PlayerCamera")
	var grapple_node: Node = get_node_or_null("Grapple")
	var traversal_node: Node = get_node_or_null("Traversal")
	if not is_local_player:
		player_input.process_mode = Node.PROCESS_MODE_DISABLED
		player_movement.process_mode = Node.PROCESS_MODE_DISABLED
		if player_camera_node != null:
			player_camera_node.process_mode = Node.PROCESS_MODE_DISABLED
		if grapple_node != null:
			grapple_node.process_mode = Node.PROCESS_MODE_DISABLED
		if traversal_node != null:
			traversal_node.process_mode = Node.PROCESS_MODE_DISABLED
		camera.current = false
		health_ui.visible = false
		return
	player_input.process_mode = Node.PROCESS_MODE_INHERIT
	player_movement.process_mode = Node.PROCESS_MODE_INHERIT
	if player_camera_node != null:
		player_camera_node.process_mode = Node.PROCESS_MODE_INHERIT
	if grapple_node != null:
		grapple_node.process_mode = Node.PROCESS_MODE_INHERIT
	if traversal_node != null:
		traversal_node.process_mode = Node.PROCESS_MODE_INHERIT
	camera.current = true
	health_ui.visible = true
	if capture_mouse_on_ready:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	network_target_position = global_position
	network_target_velocity = velocity
	network_target_yaw = rotation.y
	network_target_pitch = head.rotation.x

func _physics_process(delta: float) -> void:
	if not networked:
		return
	if is_local_player:
		network_tick_counter += 1
		if network_tick_counter % 2 == 0 and multiplayer.has_multiplayer_peer():
			_send_network_state()
		return
	global_position = global_position.lerp(network_target_position, 1.0 - exp(-20.0 * delta))
	rotation.y = lerp_angle(rotation.y, network_target_yaw, 1.0 - exp(-20.0 * delta))
	head.rotation.x = lerp_angle(head.rotation.x, network_target_pitch, 1.0 - exp(-20.0 * delta))

@rpc("authority", "unreliable_ordered", "call_remote")
@warning_ignore("shadowed_variable")
func _receive_network_state(target_position: Vector3, target_velocity: Vector3, target_yaw: float, target_pitch: float) -> void:
	if not networked or is_local_player:
		return
	network_target_position = target_position
	network_target_velocity = target_velocity
	network_target_yaw = target_yaw
	network_target_pitch = target_pitch

func _send_network_state() -> void:
	_receive_network_state.rpc(global_position, velocity, rotation.y, head.rotation.x)

func hitscan_hit(damage_val: float, _hitscan_dir: Vector3, _hitscan_pos: Vector3) -> void:
	apply_weapon_damage(damage_val)

func projectile_hit(damage_val: float, _projectile_dir: Vector3) -> void:
	apply_weapon_damage(damage_val)

func apply_weapon_damage(damage: float) -> void:
	if damage <= 0.0 or health <= 0.0:
		return
	if networked and multiplayer.has_multiplayer_peer():
		if is_multiplayer_authority():
			_apply_damage_authority(damage)
		else:
			_request_damage.rpc_id(get_multiplayer_authority(), damage)
		return
	_apply_damage_authority(damage)

@rpc("any_peer", "reliable", "call_remote")
func _request_damage(damage: float) -> void:
	if not is_multiplayer_authority():
		return
	_apply_damage_authority(damage)

func _apply_damage_authority(damage: float) -> void:
	if damage <= 0.0 or health <= 0.0:
		return
	health = maxf(health - damage, 0.0)
	health_changed.emit(health, max_health)
	if networked and multiplayer.has_multiplayer_peer():
		_receive_health.rpc(health)

@rpc("authority", "reliable", "call_remote")
func _receive_health(current_health: float) -> void:
	health = clampf(current_health, 0.0, max_health)
	health_changed.emit(health, max_health)

func _update_health_ui(current_health: float, current_max_health: float) -> void:
	if health_bar == null or health_label == null:
		return
	health_bar.max_value = current_max_health
	health_bar.value = current_health
	health_label.text = "%d / %d" % [roundi(current_health), roundi(current_max_health)]

func _unhandled_input(event: InputEvent) -> void:
	if networked and not is_local_player:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player_input.look_input += event.relative
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	if networked and not is_local_player:
		return
	process_look(delta)

func process_look(delta: float) -> void:
	var raw_look_input: Vector2 = player_input.look_input
	player_input.look_input = Vector2.ZERO
	var controller_look_input: Vector2 = Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	raw_look_input += controller_look_input * controller_sensitivity
	var look_delta: Vector2 = Vector2(
		raw_look_input.x * mouse_sensitivity * horizontal_look_sensitivity,
		raw_look_input.y * mouse_sensitivity * vertical_look_sensitivity
	)
	if look_smoothing > 0.0:
		smoothed_look_input = smoothed_look_input.lerp(look_delta, 1.0 - exp(-look_smoothing * delta))
	else:
		smoothed_look_input = look_delta
	rotate_y(-smoothed_look_input.x)
	target_pitch = clamp(
		target_pitch - smoothed_look_input.y,
		deg_to_rad(minimum_pitch_degrees),
		deg_to_rad(maximum_pitch_degrees)
	)
	head.rotation.x = target_pitch
