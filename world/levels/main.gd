class_name Main
extends Node3D

@onready var player: Player = get_node_or_null("Player") as Player
@onready var start_pos: Node3D = get_node_or_null("Start Pos") as Node3D
@onready var players_root: Node3D = get_node_or_null("Players") as Node3D

func _ready() -> void:
	if not is_instance_valid(start_pos):
		CloseGame.close("Start position missing!")
		return
	if players_root == null:
		players_root = Node3D.new()
		players_root.name = "Players"
		add_child(players_root)
	if MultiplayerSessionManager.session == null or not MultiplayerSessionManager.is_network_ready():
		CloseGame.close("Multiplayer session is not ready.")
		return

	var old_spawner: CMPlayerSpawnerBase = MultiplayerSessionManager.session.player.player_spawner
	if old_spawner != null and is_instance_valid(old_spawner):
		old_spawner.queue_free()

	var spawner: CMPlayerSpawner = CMPlayerSpawner.new()
	spawner.name = "PlayerSpawner"
	spawner.spawn_root = self
	MultiplayerSessionManager.session.player.add_child(spawner, true)
	MultiplayerSessionManager.session.player.player_spawner = spawner

	var local_player: CMPlayer = await MultiplayerSessionManager.ensure_local_player()
	if local_player == null:
		CloseGame.close("Local multiplayer player could not be created.")
		return

	for network_player in MultiplayerSessionManager.session.player.players:
		if network_player.player_node == null or not is_instance_valid(network_player.player_node):
			network_player._spawn_player_node()

	start_pos.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and player != null and player.is_local_player:
		player.global_position = start_pos.global_position
