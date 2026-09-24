extends Control

@onready var party_code_label: Label = $PartyCode
@onready var status_label: Label = $BottomPanel/VBoxContainer/StatusLabel
@onready var join_input: LineEdit = $BottomPanel/VBoxContainer/ConnectionRow/JoinInput
@onready var host_button: Button = $BottomPanel/VBoxContainer/ConnectionRow/HostButton
@onready var join_button: Button = $BottomPanel/VBoxContainer/ConnectionRow/JoinButton
@onready var invite_username_input: LineEdit = $BottomPanel/VBoxContainer/InviteRow/InviteUsername
@onready var invite_button: Button = $BottomPanel/VBoxContainer/InviteRow/InviteButton
@onready var pending_invite_label: Label = $BottomPanel/VBoxContainer/PendingInviteLabel
@onready var accept_invite_button: Button = $BottomPanel/VBoxContainer/AcceptInviteButton
@onready var start_game_button: Button = $BottomPanel/VBoxContainer/StartGameButton
@onready var switch_account_button: Button = $BottomPanel/VBoxContainer/SwitchAccountButton

@onready var party_slot_labels: Array[Label] = [
	$PartyStage/Slot1/Username,
	$PartyStage/Slot2/Username,
	$PartyStage/Slot3/Username,
	$PartyStage/Slot4/Username
]

var transitioning: bool = false
var party_initialized: bool = false
var pending_invite_sender: String = ""
var pending_invite_code: String = ""

func _ready() -> void:
	MultiplayerSessionManager.network_ready.connect(_on_network_ready)
	MultiplayerSessionManager.network_failed.connect(_on_network_failed)
	MultiplayerSessionManager.network_stopped.connect(_on_network_stopped)
	InviteManager.invite_received.connect(_on_invite_received)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	invite_button.pressed.connect(_on_invite_pressed)
	accept_invite_button.pressed.connect(_on_accept_invite_pressed)
	start_game_button.pressed.connect(_on_start_game_pressed)
	switch_account_button.pressed.connect(_on_switch_account_pressed)
	pending_invite_label.hide()
	accept_invite_button.hide()
	_set_party_ui(false)
	status_label.text = "Host a party or join a friend's party."

func _on_host_pressed() -> void:
	if transitioning or party_initialized:
		return
	status_label.text = "Starting party..."
	MultiplayerSessionManager.start_host()
	host_button.disabled = true
	join_button.disabled = true

func _on_join_pressed() -> void:
	if transitioning or party_initialized:
		return
	var code: String = join_input.text.strip_edges()
	if code == "":
		status_label.text = "Enter the host address."
		return
	status_label.text = "Joining party..."
	MultiplayerSessionManager.start_client(code)
	host_button.disabled = true
	join_button.disabled = true

func _on_network_ready() -> void:
	if transitioning or party_initialized:
		return
	party_initialized = true
	var local_player: CMPlayer = await MultiplayerSessionManager.ensure_local_player()
	if local_player == null:
		party_initialized = false
		MultiplayerSessionManager.stop_session()
		status_label.text = "Could not create your party player."
		host_button.disabled = false
		join_button.disabled = false
		return
	local_player.set_username(UserProfile.current_username)
	var player_manager: CMPlayerManager = MultiplayerSessionManager.session.player
	if not player_manager.player_joined.is_connected(_on_player_joined):
		player_manager.player_joined.connect(_on_player_joined)
	if not player_manager.player_left.is_connected(_on_player_left):
		player_manager.player_left.connect(_on_player_left)
	for player in player_manager.players:
		_connect_username_signal(player)
	_set_party_ui(true)
	_refresh_party_slots()
	status_label.text = "Party ready." if multiplayer.is_server() else "Waiting for the party leader to start the game."

func _on_player_joined(player: CMPlayer) -> void:
	_connect_username_signal(player)
	_refresh_party_slots()
	if multiplayer.is_server():
		status_label.text = "Party updated. Ready to start."

func _on_player_left(_player: CMPlayer) -> void:
	_refresh_party_slots()
	if multiplayer.is_server():
		status_label.text = "Party updated. Ready to start."

func _connect_username_signal(player: CMPlayer) -> void:
	if not player.username_changed.is_connected(_on_player_username_changed):
		player.username_changed.connect(_on_player_username_changed)
	_refresh_party_slots()

func _on_player_username_changed(_username: String) -> void:
	_refresh_party_slots()

func _refresh_party_slots() -> void:
	if not party_initialized or MultiplayerSessionManager.session == null:
		return
	var players: Array[CMPlayer] = []
	for player in MultiplayerSessionManager.session.player.players:
		if is_instance_valid(player):
			players.append(player)
	players.sort_custom(_sort_players)

	var local_player: CMPlayer = null
	var ordered_players: Array[CMPlayer] = []
	for player in players:
		if player.is_local:
			local_player = player
			break

	if local_player != null:
		ordered_players.append(local_player)

	for player in players:
		if player != local_player:
			ordered_players.append(player)

	for label in party_slot_labels:
		label.text = "EMPTY"

	for index in range(min(ordered_players.size(), party_slot_labels.size())):
		var player: CMPlayer = ordered_players[index]
		var username: String = player.username.strip_edges()
		if username == "":
			username = "Player %d" % (player.player_id + 1)
		party_slot_labels[index].text = username

	if multiplayer.is_server():
		start_game_button.disabled = players.is_empty()
	party_code_label.text = "Party Code: " + MultiplayerSessionManager.get_party_code()

func _sort_players(a: CMPlayer, b: CMPlayer) -> bool:
	return a.player_id < b.player_id

func _set_party_ui(connected: bool) -> void:
	party_code_label.visible = connected
	invite_username_input.editable = connected
	invite_button.disabled = not connected
	start_game_button.visible = connected
	join_input.editable = not connected
	host_button.visible = not connected
	join_button.visible = not connected
	if connected:
		start_game_button.disabled = not multiplayer.is_server()
		join_input.text = ""
		if multiplayer.is_server():
			status_label.text = "Party ready. Invite players or start the game."
		else:
			status_label.text = "Waiting for the party leader to start the game."
	else:
		start_game_button.disabled = true
		party_code_label.text = "Party Code: --"

func _on_invite_pressed() -> void:
	var receiver: String = invite_username_input.text.strip_edges()
	var code: String = MultiplayerSessionManager.get_party_code()
	if code == "":
		status_label.text = "Join or host a party before inviting players."
		return
	if receiver == "":
		status_label.text = "Enter a player's username."
		return
	InviteManager.send_invite(receiver, code)
	status_label.text = "Invite sent to " + receiver + "."
	invite_username_input.clear()

func _on_invite_received(sender: String, code: String) -> void:
	pending_invite_sender = sender
	pending_invite_code = code
	pending_invite_label.text = "Party invite from %s" % sender
	pending_invite_label.show()
	accept_invite_button.show()
	status_label.text = "You received a party invite."

func _on_accept_invite_pressed() -> void:
	if transitioning or party_initialized or pending_invite_code == "":
		return
	join_input.text = pending_invite_code
	pending_invite_label.hide()
	accept_invite_button.hide()
	_on_join_pressed()

func _on_start_game_pressed() -> void:
	if transitioning or not party_initialized or not multiplayer.is_server():
		return
	_start_game.rpc()

@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	if transitioning:
		return
	transitioning = true
	status_label.text = "Starting game..."
	get_tree().change_scene_to_file("res://world/levels/main.tscn")

func _on_network_failed(message: String) -> void:
	if transitioning:
		return
	party_initialized = false
	_set_party_ui(false)
	host_button.disabled = false
	join_button.disabled = false
	status_label.text = message

func _on_network_stopped() -> void:
	if transitioning:
		return
	party_initialized = false
	_set_party_ui(false)

func _on_switch_account_pressed() -> void:
	if transitioning:
		return
	transitioning = true
	MultiplayerSessionManager.stop_session()
	Supabase.auth.clear_local_session()
	InviteManager.wipe_sent_invites()
	UserProfile.clear_profile()
	get_tree().change_scene_to_file("res://ui/startup.tscn")
