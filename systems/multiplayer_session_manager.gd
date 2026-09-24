extends Node
#class_name MultiplayerSessionManager

signal network_ready
signal network_failed(message: String)
signal network_stopped

const DEFAULT_PORT: int = 6769
const MAX_PLAYERS: int = 8

var session: CMSession
var transport: CMNetTransportENet
var host_code: String = ""

func _ready() -> void:
	_create_session()

func _create_session() -> void:
	if session != null:
		return
	session = CMSession.new()
	session.name = "CMSession"
	get_tree().root.add_child(session)
	transport = CMNetTransportENet.new()
	transport.port = DEFAULT_PORT
	transport.max_clients = MAX_PLAYERS
	session.net.transport = transport
	session.net.max_players_per_peer = 1
	session.player.max_players = MAX_PLAYERS
	session.net.net_activated.connect(_on_net_activated)
	session.net.server_connection_failure.connect(_on_connection_failure)
	session.net.server_disconnected.connect(_on_server_disconnected)
	session.net.net_stopped.connect(_on_net_stopped)

func start_host() -> void:
	_create_session()
	if session.net.is_net_active:
		return
	host_code = get_local_join_code()
	transport.port = DEFAULT_PORT
	transport.host_bind_ip = "*"
	session.net.start_server()

func start_client(join_code: String) -> void:
	_create_session()
	var address: String = join_code.strip_edges()
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
	transport.port = port
	transport.connect_address = host
	session.net.start_client()

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
	return session != null and session.net.is_net_active

func ensure_local_player() -> CMPlayer:
	if session == null or not session.net.is_net_active:
		return null
	for player in session.player.players:
		if player.is_local:
			return player
	var player: CMPlayer = await session.player.add_player_async()
	return player

func stop_session() -> void:
	if session == null:
		return
	session.net.stop_net()

func _on_net_activated() -> void:
	network_ready.emit()

func _on_connection_failure() -> void:
	network_failed.emit("The connection to the host failed.")

func _on_server_disconnected() -> void:
	network_failed.emit("The host disconnected.")

func _on_net_stopped() -> void:
	network_stopped.emit()
