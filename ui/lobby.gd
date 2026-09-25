extends Control

@onready var party_code_label: Label = $PartyCode
@onready var status_label: Label = $BottomPanel/VBoxContainer/MarginContainer3/HBoxContainer/StatusLabel
@onready var join_input: LineEdit = $BottomPanel/VBoxContainer/MarginContainer/ConnectionRow/JoinInput
@onready var host_button: Button = $BottomPanel/VBoxContainer/MarginContainer/ConnectionRow/HostButton
@onready var join_button: Button = $BottomPanel/VBoxContainer/MarginContainer/ConnectionRow/JoinButton
@onready var invite_username_input: LineEdit = $BottomPanel/VBoxContainer/MarginContainer2/InviteRow/InviteUsername
@onready var invite_button: Button = $BottomPanel/VBoxContainer/MarginContainer2/InviteRow/InviteButton
@onready var pending_invite_label: Label = $BottomPanel/VBoxContainer/MarginContainer3/HBoxContainer/PendingInviteLabel
@onready var accept_invite_button: Button = $BottomPanel/VBoxContainer/MarginContainer6/AcceptInviteButton
@onready var start_game_button: Button = $BottomPanel/VBoxContainer/MarginContainer4/StartGameButton
@onready var switch_account_button: Button = $BottomPanel/VBoxContainer/MarginContainer5/SwitchAccountButton
@onready var party_slot_labels: Array[Label] = [
	$PartyStage/HBoxContainer/Slot1/Username,
	$PartyStage/HBoxContainer/Slot2/Username,
	$PartyStage/HBoxContainer/Slot3/Username,
	$PartyStage/HBoxContainer/Slot4/Username
]

var transitioning: bool = false
var party_initialized: bool = false
var pending_invite_sender: String = ""
var pending_invite_code: String = ""

func _process(_delta: float) -> void:
	if party_initialized:
		_refresh_party_slots()

func _ready() -> void:
	if not MultiplayerSessionManager.network_ready.is_connected(_on_network_ready):
		MultiplayerSessionManager.network_ready.connect(_on_network_ready)
	if not MultiplayerSessionManager.network_failed.is_connected(_on_network_failed):
		MultiplayerSessionManager.network_failed.connect(_on_network_failed)
	if not MultiplayerSessionManager.network_stopped.is_connected(_on_network_stopped):
		MultiplayerSessionManager.network_stopped.connect(_on_network_stopped)
	if not MultiplayerSessionManager.party_updated.is_connected(_on_party_updated):
		MultiplayerSessionManager.party_updated.connect(_on_party_updated)
	if not InviteManager.invite_received.is_connected(_on_invite_received):
		InviteManager.invite_received.connect(_on_invite_received)

	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	invite_button.pressed.connect(_on_invite_pressed)
	accept_invite_button.pressed.connect(_on_accept_invite_pressed)
	start_game_button.pressed.connect(_on_start_game_pressed)
	switch_account_button.pressed.connect(_on_switch_account_pressed)

	pending_invite_label.hide()
	accept_invite_button.hide()
	_clear_party_slots()
	_set_party_ui(false)
	status_label.text = "Host a party or join a friend's party."

func _on_host_pressed() -> void:
	if transitioning or party_initialized:
		return
	status_label.text = "Starting party..."
	host_button.disabled = true
	join_button.disabled = true
	MultiplayerSessionManager.start_host()

func _on_join_pressed() -> void:
	if transitioning or party_initialized:
		return
	var code: String = join_input.text.strip_edges()
	if code == "":
		status_label.text = "Enter the party code."
		return
	status_label.text = "Joining party..."
	host_button.disabled = true
	join_button.disabled = true
	MultiplayerSessionManager.start_client(code)

func _on_network_ready() -> void:
	if transitioning or party_initialized:
		return
	party_initialized = true
	_set_party_ui(true)
	_refresh_party_slots()

func _on_party_updated() -> void:
	if not party_initialized:
		return
	_refresh_party_slots()

func _refresh_party_slots() -> void:
	if not party_initialized or MultiplayerSessionManager.mpc == null:
		return

	var players: Array[MPPlayer] = MultiplayerSessionManager.get_players()
	players.sort_custom(_sort_players)

	var local_player: MPPlayer = MultiplayerSessionManager.get_local_player()
	var ordered_players: Array[MPPlayer] = []

	if local_player != null and is_instance_valid(local_player):
		ordered_players.append(local_player)

	for player in players:
		if player != local_player:
			ordered_players.append(player)

	_clear_party_slots()

	for index in range(min(ordered_players.size(), party_slot_labels.size())):
		var player: MPPlayer = ordered_players[index]
		party_slot_labels[index].text = _get_player_username(player)

	party_code_label.text = "Party Code: " + MultiplayerSessionManager.get_party_code()

	var is_host: bool = MultiplayerSessionManager.mpc.is_server
	start_game_button.disabled = not is_host or not MultiplayerSessionManager.is_party_ready_to_start()

	if is_host and ordered_players.size() < 1:
		status_label.text = "Waiting for the host player to finish joining."
	elif not is_host:
		status_label.text = "Waiting for the party leader to start the game."
	else:
		status_label.text = "Party ready. Invite players or start the game."

func _get_player_username(player: MPPlayer) -> String:
	if player == null or not is_instance_valid(player):
		return "EMPTY"

	var username: String = str(player.handshake_data.get("username", "")).strip_edges()
	if username == "":
		username = "Player %d" % (player.player_index + 1)
	return username

func _clear_party_slots() -> void:
	for label in party_slot_labels:
		label.text = "EMPTY"

func _sort_players(a: MPPlayer, b: MPPlayer) -> bool:
	return a.player_index < b.player_index

func _set_party_ui(connected: bool) -> void:
	var is_host: bool = connected and MultiplayerSessionManager.mpc != null and MultiplayerSessionManager.mpc.is_server

	party_code_label.visible = connected
	invite_username_input.editable = is_host
	invite_button.disabled = not is_host
	start_game_button.visible = connected
	join_input.editable = not connected
	host_button.visible = not connected
	join_button.visible = not connected

	if connected:
		join_input.text = ""
	start_game_button.disabled = not is_host or not MultiplayerSessionManager.is_party_ready_to_start()
		if is_host:
			status_label.text = "Party ready. Invite players or start the game."
		else:
			status_label.text = "Waiting for the party leader to start the game."
	else:
		start_game_button.disabled = true
		party_code_label.text = "Party Code: --"
		invite_username_input.clear()

func _on_invite_pressed() -> void:
	if not party_initialized or MultiplayerSessionManager.mpc == null or not MultiplayerSessionManager.mpc.is_server:
		return

	var receiver: String = invite_username_input.text.strip_edges()
	var code: String = MultiplayerSessionManager.get_party_code()

	if code == "":
		status_label.text = "Host a party before inviting players."
		return
	if receiver == "":
		status_label.text = "Enter a player's username."
		return

	InviteManager.send_invite(receiver, code)
	status_label.text = "Invite sent to " + receiver + "."
	invite_username_input.clear()

func _on_invite_received(sender: String, code: String) -> void:
	if party_initialized:
		return

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
	pending_invite_sender = ""
	pending_invite_code = ""
	pending_invite_label.hide()
	accept_invite_button.hide()
	_on_join_pressed()

func _on_start_game_pressed() -> void:
	if transitioning or not party_initialized or MultiplayerSessionManager.mpc == null:
		return
	if not MultiplayerSessionManager.mpc.is_server:
		return
	if not MultiplayerSessionManager.is_party_ready_to_start():
		return

	transitioning = true
	start_game_button.disabled = true
	status_label.text = "Starting game..."
	MultiplayerSessionManager.start_game_scene("res://world/levels/main.tscn")
	_hide_lobby()

func _hide_lobby() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_DISABLED

func _on_network_failed(message: String) -> void:
	if transitioning:
		return

	party_initialized = false
	pending_invite_sender = ""
	pending_invite_code = ""
	pending_invite_label.hide()
	accept_invite_button.hide()
	_clear_party_slots()
	_set_party_ui(false)
	host_button.disabled = false
	join_button.disabled = false
	status_label.text = message

func _on_network_stopped() -> void:
	party_initialized = false
	transitioning = false
	pending_invite_sender = ""
	pending_invite_code = ""
	pending_invite_label.hide()
	accept_invite_button.hide()
	_clear_party_slots()
	_set_party_ui(false)
	host_button.disabled = false
	join_button.disabled = false
	status_label.text = "Host a party or join a friend's party."

func _on_switch_account_pressed() -> void:
	if transitioning:
		return

	transitioning = true
	MultiplayerSessionManager.stop_session()
	Supabase.auth.clear_local_session()
	InviteManager.wipe_sent_invites()
	UserProfile.clear_profile()
	get_tree().change_scene_to_file("res://ui/startup.tscn")
