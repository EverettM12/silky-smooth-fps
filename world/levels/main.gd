class_name Main
extends Node3D

@onready var start_pos: Node3D = get_node_or_null("Start Pos") as Node3D
@onready var weapon_viewport_camera: Camera3D = get_node_or_null("SubViewportContainer/SubViewport/ViewportCam") as Camera3D
@onready var camera_holder: CameraHolder = get_node_or_null("CameraHolder") as CameraHolder
@onready var weapon_manager_template: WeaponManager = get_node_or_null("WeaponManager") as WeaponManager
@onready var hud: HUD = get_node_or_null("HUD") as HUD

var player: Player

func _ready() -> void:
	if not is_instance_valid(start_pos):
		push_error("Main: Start Pos is missing.")
		return

	var multiplayer_core: MultiPlayCore = await _wait_for_mpc()
	if multiplayer_core == null:
		push_error("Main: MultiPlay Core was not ready.")
		return

	if not multiplayer_core.player_connected.is_connected(_on_player_connected):
		multiplayer_core.player_connected.connect(_on_player_connected)
	if not multiplayer_core.player_disconnected.is_connected(_on_player_disconnected):
		multiplayer_core.player_disconnected.connect(_on_player_disconnected)

	for raw_player in multiplayer_core.players.get_players().values():
		if raw_player is MPPlayer and is_instance_valid(raw_player):
			_configure_player_items(raw_player as MPPlayer)

	var local_mpp: MPPlayer = await _wait_for_local_player(multiplayer_core)
	if local_mpp == null:
		push_error("Main: Local MPPlayer was not ready.")
		return

	var local_player: Player = await _wait_for_local_player_node(local_mpp)
	if local_player == null:
		push_error("Main: Local player node was not spawned.")
		return

	player = local_player
	await _wait_for_player_weapon_manager(player)

	var player_camera: PlayerCamera = player.get_node_or_null("PlayerCamera") as PlayerCamera
	var local_weapon_manager: WeaponManager = player.get_node_or_null("WeaponManager") as WeaponManager
	if player_camera != null:
		player_camera.weapon_viewport_camera = weapon_viewport_camera
		player_camera.weapon_manager = local_weapon_manager

	if hud != null:
		hud.set_weapon_manager(local_weapon_manager)

	if camera_holder != null:
		camera_holder.configure_player(player)

	player.global_position = start_pos.global_position
	start_pos.hide()
	if is_instance_valid(weapon_manager_template):
		weapon_manager_template.visible = false
		weapon_manager_template.process_mode = Node.PROCESS_MODE_DISABLED

func _configure_player_items(mp_player: MPPlayer) -> void:
	if mp_player == null or not is_instance_valid(mp_player):
		return
	var target_player: Player = mp_player.player_node as Player
	if target_player == null or not is_instance_valid(target_player):
		return
	if target_player.get_node_or_null("WeaponManager") != null:
		return
	if weapon_manager_template == null or not is_instance_valid(weapon_manager_template):
		push_error("Main: WeaponManager template is missing.")
		return

	var manager: WeaponManager = weapon_manager_template.duplicate() as WeaponManager
	if manager == null:
		push_error("Main: Failed to duplicate WeaponManager template.")
		return

	manager.name = "WeaponManager"
	manager.player = target_player
	manager.viewport_cam = target_player.camera
	if camera_holder != null:
		manager.camera_recoil_holder = camera_holder.recoil_holder
	manager.hud = hud
	manager.visible = mp_player.is_local
	if mp_player.is_local:
		manager.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		manager.process_mode = Node.PROCESS_MODE_DISABLED

	if manager.anim_manager != null:
		var animation_manager: AnimationManager = manager.anim_manager as AnimationManager
		if animation_manager != null:
			animation_manager.play_char = target_player
			animation_manager.camera_holder = camera_holder

	target_player.add_child(manager)

func _wait_for_player_weapon_manager(target_player: Player, max_frames: int = 180) -> void:
	for _index in range(max_frames):
		if target_player.get_node_or_null("WeaponManager") is WeaponManager:
			return
		await get_tree().process_frame

func _on_player_connected(mp_player: MPPlayer) -> void:
	_configure_player_items.call_deferred(mp_player)

func _on_player_disconnected(_mp_player: MPPlayer) -> void:
	return

func _wait_for_mpc(max_frames: int = 180) -> MultiPlayCore:
	for _index in range(max_frames):
		var multiplayer_core: MultiPlayCore = MultiplayerSessionManager.mpc
		if multiplayer_core != null and is_instance_valid(multiplayer_core):
			return multiplayer_core
		await get_tree().process_frame
	return null

func _wait_for_local_player(multiplayer_core: MultiPlayCore, max_frames: int = 180) -> MPPlayer:
	for _index in range(max_frames):
		if multiplayer_core.local_player != null and is_instance_valid(multiplayer_core.local_player):
			return multiplayer_core.local_player
		await get_tree().process_frame
	return null

func _wait_for_local_player_node(mp_player: MPPlayer, max_frames: int = 180) -> Player:
	for _index in range(max_frames):
		if mp_player.player_node is Player and is_instance_valid(mp_player.player_node):
			return mp_player.player_node as Player
		await get_tree().process_frame
	return null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and player != null and player.is_local_player:
		player.global_position = start_pos.global_position
