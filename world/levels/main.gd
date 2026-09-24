class_name Main
extends Node3D

@onready var player: Player = get_node_or_null("Player") as Player
@onready var start_pos: Node3D = get_node_or_null("Start Pos") as Node3D
@onready var players_root: Node3D = get_node_or_null("Players") as Node3D
@onready var weapon_viewport_camera: Camera3D = get_node_or_null("SubViewportContainer/SubViewport/ViewportCam") as Camera3D
@onready var camera_holder: CameraHolder = get_node_or_null("CameraHolder") as CameraHolder
@onready var weapon_manager: WeaponManager = get_node_or_null("WeaponManager") as WeaponManager

func _ready() -> void:
	if not is_instance_valid(start_pos):
		push_error("Main: Start Pos is missing.")
		return
	if players_root == null:
		players_root = Node3D.new()
		players_root.name = "Players"
		add_child(players_root)
	if not await _wait_for_network():
		push_error("Main: Multiplayer session was not ready after waiting.")
		return

	var session: CMSession = MultiplayerSessionManager.session
	if session == null or session.player == null:
		push_error("Main: CM.gd player manager is unavailable.")
		return

	var old_spawner: CMPlayerSpawnerBase = session.player.player_spawner
	if old_spawner != null and is_instance_valid(old_spawner):
		old_spawner.queue_free()
		await get_tree().process_frame

	var spawner: CMPlayerSpawner = CMPlayerSpawner.new()
	spawner.name = "PlayerSpawner"
	spawner.spawn_root = self
	session.player.add_child(spawner, true)
	session.player.player_spawner = spawner

	var local_player: CMPlayer = await _wait_for_local_player()
	if local_player == null:
		push_error("Main: Local CM.gd player could not be created.")
		return

	for network_player in session.player.players:
		if network_player.player_node == null or not is_instance_valid(network_player.player_node):
			network_player._spawn_player_node()

	await get_tree().process_frame

	if local_player.player_node == null or not is_instance_valid(local_player.player_node):
		local_player._spawn_player_node()
		await get_tree().process_frame

	var local_player_node: Player = local_player.player_node as Player
	if local_player_node == null:
		push_error("Main: Local player node could not be resolved.")
		return
	player = local_player_node

func _wait_for_network(max_frames: int = 120) -> bool:
	for _index in range(max_frames):
		if MultiplayerSessionManager.session != null and MultiplayerSessionManager.is_network_ready():
			return true
		await get_tree().process_frame
	return false

func _wait_for_local_player(max_frames: int = 120) -> CMPlayer:
	for _index in range(max_frames):
		var local_player: CMPlayer = await MultiplayerSessionManager.ensure_local_player()
		if local_player != null:
			return local_player
		await get_tree().process_frame
	return null
	var player_camera: PlayerCamera = player.get_node_or_null("PlayerCamera") as PlayerCamera
	if player_camera != null:
		player_camera.weapon_viewport_camera = weapon_viewport_camera
		player_camera.weapon_manager = weapon_manager
	if camera_holder != null:
		camera_holder.configure_player(player)
	start_pos.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and player != null and player.is_local_player:
		player.global_position = start_pos.global_position
