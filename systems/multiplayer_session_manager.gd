extends Node

signal network_ready
signal network_failed(message: String)
signal network_stopped
signal party_updated

const DEFAULT_PORT: int = 6769
const MAX_PLAYERS: int = 4

var mpc: MultiPlayCore
var enet_protocol: ENetProtocol
var host_code: String = ""
var party_code: String = ""
var _creating_mpc: bool = false
var _stopping: bool = false

func _ready() -> void:
	_create_mpc.call_deferred()

func _create_mpc() -> void:
	if mpc != null or _creating_mpc:
		return
	_creating_mpc = true
	mpc = MultiPlayCore.new()
	mpc.name = "MultiPlayCore"
	mpc.bind_address = "*"
	mpc.port = DEFAULT_PORT
	mpc.max_players = MAX_PLAYERS
	mpc.player_scene = preload("res://world/levels/player.tscn")
	mpc.first_scene = null
	mpc.assign_client_authority = true
	mpc.auto_spawn_player_scene = false
	mpc.debug_gui_enabled = false

	enet_protocol = ENetProtocol.new()
	enet_protocol.name = "ENetProtocol"
	mpc.add_child(enet_protocol, true)

	mpc.connected_to_server.connect(_on_connected_to_server)
	mpc.disconnected_from_server.connect(_on_disconnected_from_server)
	mpc.connection_error.connect(_on_connection_error)
	mpc.player_connected.connect(_on_player_connected)
	mpc.player_disconnected.connect(_on_player_disconnected)

	get_tree().root.add_child(mpc, true)
	_creating_mpc = false

func _ensure_mpc() -> MultiPlayCore:
	if mpc != null and is_instance_valid(mpc):
		return mpc
	if not _creating_mpc:
		_create_mpc()
	while _creating_mpc:
		await get_tree().process_frame
	return mpc

func start_host() -> void:
	var multiplayer_core: MultiPlayCore = await _ensure_mpc()
	if multiplayer_core == null:
		network_failed.emit("MultiPlay Core is not ready.")
		return
	if multiplayer_core.online_connected or multiplayer_core.is_server:
		return

	_stopping = false
	host_code = get_local_join_code()
	party_code = host_code
	multiplayer_core.bind_address = "*"
	multiplayer_core.port = DEFAULT_PORT
	multiplayer_core.max_players = MAX_PLAYERS

	var username: String = UserProfile.current_username.strip_edges()
	var handshake_data: Dictionary = {"username": username}
	multiplayer_core.start_online_host(true, handshake_data)

func start_client(join_code: String) -> void:
	var multiplayer_core: MultiPlayCore = await _ensure_mpc()
	if multiplayer_core == null:
		network_failed.emit("MultiPlay Core is not ready.")
		return

	var address: String = join_code.strip_edges()
	if address == "":
		network_failed.emit("Enter the party code.")
		return

	var parts: PackedStringArray = address.split(":")
	var host: String = address
	var port: int = DEFAULT_PORT
	if parts.size() == 2:
		host = parts[0].strip_edges()
		port = int(parts[1])

	if host == "":
		host = "127.0.0.1"
	if port < 1 or port > 65535:
		network_failed.emit("The party code has an invalid port.")
		return

	_stopping = false
	host_code = ""
	party_code = "%s:%d" % [host, port]
	multiplayer_core.port = port
	multiplayer_core.max_players = MAX_PLAYERS

	var username: String = UserProfile.current_username.strip_edges()
	var handshake_data: Dictionary = {"username": username}
	multiplayer_core.start_online_join(party_code, handshake_data)

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

func is_network_ready() -> bool:
	return mpc != null and is_instance_valid(mpc) and mpc.online_connected and mpc.local_player != null

func get_players() -> Array[MPPlayer]:
	var result: Array[MPPlayer] = []
	if mpc == null or not is_instance_valid(mpc) or mpc.players == null:
		return result
	for player in mpc.players.get_players().values():
		if player is MPPlayer and is_instance_valid(player):
			result.append(player)
	return result

func get_local_player() -> MPPlayer:
	if mpc == null or not is_instance_valid(mpc):
		return null
	return mpc.local_player

func stop_session() -> void:
	if mpc == null or not is_instance_valid(mpc):
		return

	_stopping = true
	if mpc.is_server:
		mpc.close_server()
	elif mpc.local_player != null:
		mpc.local_player.disconnect_player()
	elif mpc.online_peer != null:
		mpc.online_peer.close()

	_reset_mpc.call_deferred()

func start_game_scene(scene_path: String) -> void:
	if mpc == null or not is_instance_valid(mpc):
		return
	if not mpc.is_server:
		return
	if not mpc.online_connected:
		return
	mpc.load_scene(scene_path, true)

func is_party_ready_to_start() -> bool:
	if mpc == null or not is_instance_valid(mpc):
		return false
	if not mpc.is_server or not mpc.online_connected:
		return false
	return mpc.local_player != null and mpc.player_count > 0

func _on_connected_to_server(_local_player: MPPlayer) -> void:
	_stopping = false
	network_ready.emit()
	party_updated.emit()

func _on_player_connected(_player: MPPlayer) -> void:
	party_updated.emit()

func _on_player_disconnected(_player: MPPlayer) -> void:
	party_updated.emit()

func _on_connection_error(reason: MultiPlayCore.ConnectionError) -> void:
	if _stopping:
		return
	var reason_name: String = str(reason)
	network_failed.emit("Multiplayer connection failed: " + reason_name)
	_reset_mpc.call_deferred()

func _on_disconnected_from_server(reason: String) -> void:
	if _stopping:
		return
	network_failed.emit("Disconnected: " + reason)
	_reset_mpc.call_deferred()

func _reset_mpc() -> void:
	if mpc != null and is_instance_valid(mpc):
		mpc.queue_free()
	mpc = null
	enet_protocol = null
	party_code = ""
	host_code = ""
	network_stopped.emit()
	_stopping = false
