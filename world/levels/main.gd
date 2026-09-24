class_name Main
extends Node3D

@onready var start_pos: Node3D = get_node_or_null("Start Pos") as Node3D
@onready var weapon_viewport_camera: Camera3D = get_node_or_null("SubViewportContainer/SubViewport/ViewportCam") as Camera3D
@onready var camera_holder: CameraHolder = get_node_or_null("CameraHolder") as CameraHolder
@onready var weapon_manager: WeaponManager = get_node_or_null("WeaponManager") as WeaponManager

var player: Player

func _ready() -> void:
	if not is_instance_valid(start_pos):
		CloseGame.close("Start position missing!")
		return
	if not is_instance_valid(MultiplayerSessionManager.mpc):
		CloseGame.close("Multiplayer session is not ready.")
		return

	var local_player: MPPlayer = await _wait_for_local_player()
	if local_player == null:
		CloseGame.close("Local multiplayer player could not be resolved.")
		return

	var local_player_node: Player = local_player.player_node as Player
	if local_player_node == null:
		CloseGame.close("Local player node could not be resolved.")
		return

	player = local_player_node
	var player_camera: PlayerCamera = player.get_node_or_null("PlayerCamera") as PlayerCamera
	if player_camera != null:
		player_camera.weapon_viewport_camera = weapon_viewport_camera
		player_camera.weapon_manager = weapon_manager

	if camera_holder != null:
		camera_holder.configure_player(player)

	start_pos.hide()

func _wait_for_local_player() -> MPPlayer:
	for attempt in range(120):
		var local_player: MPPlayer = MultiplayerSessionManager.ensure_local_player()
		if local_player != null and local_player.player_node != null and is_instance_valid(local_player.player_node):
			return local_player
		await get_tree().process_frame
	return MultiplayerSessionManager.ensure_local_player()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and player != null and player.is_local_player:
		player.global_position = start_pos.global_position
