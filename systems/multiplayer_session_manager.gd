extends Node

signal network_ready
signal network_failed(message: String)
signal network_stopped
signal party_updated

const DEFAULT_PORT: int = 6769
const MAX_PLAYERS: int = 4

var mpc: MultiPlayCore
var transport: ENetProtocol
var host_code: String = ""
var party_code: String = ""
var game_started: bool = false

func _ready() -> void:
	_create_mpc()

func _create_mpc() -> void:
	if is_instance_valid(mpc):
		return
	mpc = MultiPlayCore.new()
	mpc.name = "MultiPlayCore"
	mpc.bind_address = "*"
	mpc.port = DEFAULT_PORT
	mpc.max_players = MAX_PLAYERS
	mpc.player_scene = preload("res://world/levels/player.tscn")
	mpc.assign_client_authority = true
	mpc.auto_spawn_player_scene = true
	mpc.debug_gui_enabled = false

	transport = ENetProtocol.new()
	transport.name = "ENetProtocol"
	mpc.add_child(transport)

	mpc.connected_to_server.connect(_on_connected_to_server)
	mpc.player_connected.connect(_on_player_connected)
	mpc.player_disconnected.connect(_on_player_disconnected)
	mpc.server_stopped.connect(_on_server_stopped)
	mpc.disconnected_from_server.connect(_on_disconnected_from_server)

	get_tree().root.add_child(mpc)

func start_host() -> void:
	_create_mpc()
	if mpc.online_connected or mpc.is_server:
		return
	game_started = false
	host_code = get_local_join_code()
	party_code = host_code
	mpc.bind_address = "*"
	mpc.port = DEFAULT_PORT
	mpc.start_online_host(true, {"username": UserProfile.current_username})

func start_client(join_code: String) -> void:
	_create_mpc()
	var address: String = join_code.strip_edges()
	if address == "":
		network_failed.emit("Enter the host address.")
		return
	var parts: PackedStringArray = address.split(":")
	var host: String = address
	var port: int = DEFAULT_PORT
	if parts.size() == 2:
		host = parts[0]
		port = int(parts[1])
	if host == "":
		host = "127.0.0.1"
	if port < 1 or port > 65535:
		network_failed.emit("The join address has an invalid port.")
		return
	host_code = ""
	party_code = address
	mpc.port = port
	mpc.start_online_join(host, {"username": UserProfile.current_username})

func ensure_local_player() -> MPPlayer:
	if not is_instance_valid(mpc):
		return null
	if mpc.local_player == null or not is_instance_valid(mpc.local_player):
		return null
	return mpc.local_player

func get_players() -> Array[MPPlayer]:
	var result: Array[MPPlayer] = []
	if not is_instance_valid(mpc) or mpc.players == null:
		return result
	for player in mpc.players.get_players().values():
		if player is MPPlayer and is_instance_valid(player):
			result.append(player)
	return result

func prepare_game_start() -> void:
	if not is_instance_valid(mpc) or not mpc.is_server:
		return
	game_started = true
	mpc.players.spawn_node_all()
	party_updated.emit()

func mark_game_started() -> void:
	game_started = true

func get_party_code() -> String:
	return party_code.strip_edges()

func get_local_join_code() -> String:
	var addresses: PackedStringArray = IP.get_local_addresses()
	for address in addresses:
		if address.begins_with("192.168."):
			return "%s:%d" % [address, DEFAULT_PORT]
		if address.begins_with("10."):
			return "%s:%d" % [address, DEFAULT_PORT]
		if address.begins_with("172.16.") or address.begins_with("172.17.") or address.begins_with("172.18.") or address.begins_with("172.19.") or address.begins_with("172.20.") or address.begins_with("172.21.") or address.begins_with("172.22.") or address.begins_with("172.23.") or address.begins_with("172.24.") or address.begins_with("172.25.") or address.begins_with("172.26.") or address.begins_with("172.27.") or address.begins_with("172.28.") or address.begins_with("172.29.") or address.begins_with("172.30.") or address.begins_with("172.31."):
			return "%s:%d" % [address, DEFAULT_PORT]
	return "127.0.0.1:%d" % DEFAULT_PORT

func stop_session() -> void:
	var active_mpc: MultiPlayCore = mpc
	if not is_instance_valid(active_mpc):
		return

	mpc = null
	transport = null
	party_code = ""
	host_code = ""
	game_started = false

	if active_mpc.connected_to_server.is_connected(_on_connected_to_server):
		active_mpc.connected_to_server.disconnect(_on_connected_to_server)
	if active_mpc.player_connected.is_connected(_on_player_connected):
		active_mpc.player_connected.disconnect(_on_player_connected)
	if active_mpc.player_disconnected.is_connected(_on_player_disconnected):
		active_mpc.player_disconnected.disconnect(_on_player_disconnected)
	if active_mpc.server_stopped.is_connected(_on_server_stopped):
		active_mpc.server_stopped.disconnect(_on_server_stopped)
	if active_mpc.disconnected_from_server.is_connected(_on_disconnected_from_server):
		active_mpc.disconnected_from_server.disconnect(_on_disconnected_from_server)

	if active_mpc.is_server:
		active_mpc.close_server()
	elif active_mpc.local_player != null:
		active_mpc.local_player.disconnect_player()
	elif active_mpc.online_peer != null:
		active_mpc.online_peer.close()

	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null

	active_mpc.queue_free()
	_create_mpc()
	network_stopped.emit()

func leave_session() -> void:
	stop_session()

func _on_connected_to_server(_local_player: MPPlayer) -> void:
	if not is_instance_valid(mpc):
		return
	if not game_started and mpc.is_server:
		mpc.players.despawn_node_all()
	party_updated.emit()
	network_ready.emit()

func _on_player_connected(player: MPPlayer) -> void:
	if not is_instance_valid(mpc):
		return
	if not game_started and mpc.is_server and is_instance_valid(player):
		player.despawn_node()
	party_updated.emit()

func _on_player_disconnected(_player: MPPlayer) -> void:
	party_updated.emit()

func _on_server_stopped() -> void:
	party_updated.emit()

func _on_disconnected_from_server(reason: String) -> void:
	if game_started:
		return
	party_code = ""
	host_code = ""
	party_updated.emit()
	network_failed.emit("Disconnected: " + reason)
