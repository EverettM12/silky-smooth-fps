extends Control

@onready var username_label: Label = $CenterContainer/PanelContainer/VBoxContainer/UsernameLabel
@onready var status_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatusLabel
@onready var host_code_label: Label = $CenterContainer/PanelContainer/VBoxContainer/HostCode
@onready var join_input: LineEdit = $CenterContainer/PanelContainer/VBoxContainer/JoinInput
@onready var invite_username_input: LineEdit = $CenterContainer/PanelContainer/VBoxContainer/InviteRow/InviteUsername
@onready var host_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HostButton
@onready var join_button: Button = $CenterContainer/PanelContainer/VBoxContainer/JoinButton
@onready var invite_button: Button = $CenterContainer/PanelContainer/VBoxContainer/InviteRow/InviteButton
@onready var logout_button: Button = $CenterContainer/PanelContainer/VBoxContainer/LogoutButton

var transitioning: bool = false

func _ready() -> void:
	username_label.text = "Signed in as " + UserProfile.current_username
	MultiplayerSessionManager.network_ready.connect(_on_network_ready)
	MultiplayerSessionManager.network_failed.connect(_on_network_failed)
	InviteManager.invite_received.connect(_on_invite_received)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	invite_button.pressed.connect(_on_invite_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	InviteManager.start_listening(UserProfile.current_username)
	status_label.text = "Host a game or join one with an address."

func _on_host_pressed() -> void:
	if transitioning:
		return
	status_label.text = "Starting host..."
	MultiplayerSessionManager.start_host()
	host_code_label.text = "Host address: " + MultiplayerSessionManager.host_code

func _on_join_pressed() -> void:
	if transitioning:
		return
	var code: String = join_input.text.strip_edges()
	if code == "":
		status_label.text = "Enter a host address."
		return
	status_label.text = "Connecting to " + code + "..."
	MultiplayerSessionManager.start_client(code)

func _on_invite_pressed() -> void:
	var receiver: String = invite_username_input.text.strip_edges()
	var code: String = MultiplayerSessionManager.host_code
	if code == "":
		code = join_input.text.strip_edges()
	if code == "":
		status_label.text = "Host a game before sending an invite."
		return
	InviteManager.send_invite(receiver, code)
	status_label.text = "Invite sent to " + receiver + "."

func _on_invite_received(sender: String, code: String) -> void:
	join_input.text = code
	status_label.text = "Invite from %s. Press Join." % sender

func _on_network_ready() -> void:
	if transitioning:
		return
	transitioning = true
	status_label.text = "Connected. Loading the game..."
	call_deferred("_enter_game")

func _enter_game() -> void:
	get_tree().change_scene_to_file("res://world/levels/main.tscn")

func _on_network_failed(message: String) -> void:
	if transitioning:
		return
	status_label.text = message
	host_button.disabled = false
	join_button.disabled = false

func _on_logout_pressed() -> void:
	if transitioning:
		return
	transitioning = true
	MultiplayerSessionManager.stop_session()
	Supabase.auth.clear_local_session()
	InviteManager.wipe_sent_invites()
	UserProfile.clear_profile()
	get_tree().change_scene_to_file("res://ui/startup.tscn")
