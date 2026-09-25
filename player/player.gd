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
@export var heal_amount: float = 25.0
@export var heal_duration: float = 2.0
@export var heal_tick_interval: float = 0.1
var health: float = 100.0
var healing: bool = false
var healing_remaining: float = 0.0
var healing_amount_remaining: float = 0.0
var healing_tick_timer: float = 0.0

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
@onready var mp_transform_sync: MPTransformSync = get_node_or_null("MPTransformSync") as MPTransformSync
@onready var mp_head_transform_sync: MPTransformSync = get_node_or_null("Head/MPHeadTransformSync") as MPTransformSync

signal health_changed(current_health: float, current_max_health: float)

var target_pitch: float = 0.0
var smoothed_look_input: Vector2 = Vector2.ZERO
var networked: bool = false
var is_local_player: bool = true
var network_player_id: int = 0

func configure_networked(local: bool, player_id: int, authority_id: int) -> void:
	networked = true
	is_local_player = local
	network_player_id = player_id
	set_multiplayer_authority(authority_id)
	if multiplayer.has_multiplayer_peer():
		is_local_player = is_local_player or player_id == multiplayer.get_unique_id()
	if is_inside_tree():
		_apply_network_mode()
		_ensure_multiplay_sync_nodes.call_deferred()

func _ready() -> void:
	if mpp != null:
		networked = true
		is_local_player = mpp.is_local
		network_player_id = mpp.player_id
		if multiplayer.has_multiplayer_peer():
			is_local_player = is_local_player or mpp.player_id == multiplayer.get_unique_id()
	health = clampf(max_health, 0.0, max_health)
	health_changed.connect(_update_health_ui)
	_update_health_ui(health, max_health)
	if networked:
		_apply_network_mode()
		_ensure_multiplay_sync_nodes.call_deferred()
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


func _ensure_multiplay_sync_nodes() -> void:
	if mpp == null or MPIO.mpc == null:
		return

	if mp_transform_sync != null:
		mp_transform_sync.sync_position = true
		mp_transform_sync.sync_rotation = true
		mp_transform_sync.sync_scale = false
		mp_transform_sync.set_multiplayer_authority(get_multiplayer_authority(), true)

	if mp_head_transform_sync != null:
		mp_head_transform_sync.sync_position = false
		mp_head_transform_sync.sync_rotation = true
		mp_head_transform_sync.sync_scale = false
		mp_head_transform_sync.set_multiplayer_authority(get_multiplayer_authority(), true)

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

func _start_healing() -> void:
	if health >= max_health or healing:
		return
	if networked and multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		_request_heal.rpc_id(get_multiplayer_authority())
		return
	_start_healing_authority()

@rpc("any_peer", "reliable", "call_remote")
func _request_heal() -> void:
	if not is_multiplayer_authority():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id != get_multiplayer_authority():
		return
	_start_healing_authority()

func _start_healing_authority() -> void:
	if health >= max_health or healing:
		return
	healing = true
	healing_remaining = maxf(heal_duration, 0.0)
	healing_amount_remaining = minf(heal_amount, max_health - health)
	healing_tick_timer = 0.0

func _process_healing(delta: float) -> void:
	if not healing or not is_multiplayer_authority():
		return
	if health >= max_health or healing_remaining <= 0.0 or healing_amount_remaining <= 0.0:
		healing = false
		return
	healing_remaining = maxf(healing_remaining - delta, 0.0)
	healing_tick_timer -= delta
	if healing_tick_timer > 0.0:
		return
	var duration: float = maxf(heal_duration, 0.001)
	var tick_interval: float = maxf(heal_tick_interval, 0.01)
	var heal_per_second: float = healing_amount_remaining / maxf(healing_remaining + delta, tick_interval)
	var heal_this_tick: float = minf(
		healing_amount_remaining,
		minf(max_health - health, heal_per_second * tick_interval)
	)
	if heal_this_tick <= 0.0:
		healing = false
		return
	health += heal_this_tick
	healing_amount_remaining -= heal_this_tick
	healing_tick_timer = tick_interval
	health_changed.emit(health, max_health)
	if networked and multiplayer.has_multiplayer_peer():
		_receive_health.rpc(health)

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
	if player_input.heal_just_pressed:
		_start_healing()
	_process_healing(delta)
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
