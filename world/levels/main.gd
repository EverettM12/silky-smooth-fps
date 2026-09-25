class_name Main
extends Node3D

@onready var start_pos: Node3D = get_node_or_null("Start Pos") as Node3D
@onready var weapon_viewport_camera: Camera3D = get_node_or_null("SubViewportContainer/SubViewport/ViewportCam") as Camera3D
@onready var camera_holder: CameraHolder = get_node_or_null("CameraHolder") as CameraHolder
@onready var weapon_manager: WeaponManager = get_node_or_null("WeaponManager") as WeaponManager

var player: Player

func _ready() -> void:
	if not is_instance_valid(start_pos):
		push_error("Main: Start Pos is missing.")
		return

	var multiplayer_core: MultiPlayCore = await _wait_for_mpc()
	if multiplayer_core == null:
		push_error("Main: MultiPlay Core was not ready.")
		return

	var local_mpp: MPPlayer = await _wait_for_local_player(multiplayer_core)
	if local_mpp == null:
		push_error("Main: Local MPPlayer was not ready.")
		return

	var local_player: Player = await _wait_for_local_player_node(local_mpp)
	if local_player == null:
		push_error("Main: Local player node was not spawned.")
		return

	player = local_player
	var player_camera: PlayerCamera = player.get_node_or_null("PlayerCamera") as PlayerCamera
	if player_camera != null:
		player_camera.weapon_viewport_camera = weapon_viewport_camera
		player_camera.weapon_manager = weapon_manager

	if camera_holder != null:
		camera_holder.configure_player(player)

	start_pos.hide()

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
