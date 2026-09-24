extends Control

enum AuthMode {
	LOGIN,
	REGISTER
}

@onready var email_input: LineEdit = $CenterContainer/PanelContainer/VBoxContainer/EmailInput
@onready var username_input: LineEdit = $CenterContainer/PanelContainer/VBoxContainer/UsernameInput
@onready var password_input: LineEdit = $CenterContainer/PanelContainer/VBoxContainer/PasswordInput
@onready var login_mode_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ModeButtons/LoginMode
@onready var register_mode_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ModeButtons/RegisterMode
@onready var submit_button: Button = $CenterContainer/PanelContainer/VBoxContainer/SubmitButton
@onready var status_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatusLabel

var auth_mode: AuthMode = AuthMode.LOGIN
var pending_username: String = ""
var auth_in_progress: bool = false

func _ready() -> void:
	Supabase.auth.signed_in.connect(_on_auth_success)
	Supabase.auth.signed_up.connect(_on_auth_success)
	Supabase.auth.error.connect(_on_auth_error)
	login_mode_button.pressed.connect(_set_login_mode)
	register_mode_button.pressed.connect(_set_register_mode)
	submit_button.pressed.connect(_submit_auth)
	_set_login_mode()

func _set_login_mode() -> void:
	auth_mode = AuthMode.LOGIN
	username_input.hide()
	submit_button.text = "Sign In"
	login_mode_button.disabled = true
	register_mode_button.disabled = false
	status_label.text = "Sign in to continue."

func _set_register_mode() -> void:
	auth_mode = AuthMode.REGISTER
	username_input.show()
	submit_button.text = "Create Account"
	login_mode_button.disabled = false
	register_mode_button.disabled = true
	status_label.text = "Create an account to enter the lobby."

func _submit_auth() -> void:
	if auth_in_progress:
		return
	var email: String = email_input.text.strip_edges()
	var password: String = password_input.text
	if email == "" or password == "":
		status_label.text = "Enter your email and password."
		return
	if auth_mode == AuthMode.REGISTER:
		pending_username = username_input.text.strip_edges()
		if pending_username == "":
			status_label.text = "Enter a username."
			return
		if password.length() < 6:
			status_label.text = "Password must be at least 6 characters."
			return
		_begin_auth()
		Supabase.auth.sign_up(email, password)
		return
	pending_username = ""
	_begin_auth()
	Supabase.auth.sign_in(email, password)

func _begin_auth() -> void:
	auth_in_progress = true
	submit_button.disabled = true
	login_mode_button.disabled = true
	register_mode_button.disabled = true
	status_label.text = "Connecting to Supabase..."

func _on_auth_success(_user: SupabaseUser) -> void:
	if not auth_in_progress:
		return
	status_label.text = "Loading profile..."
	var profile: Dictionary = await UserProfile.load_profile()
	if profile.is_empty():
		_on_auth_error_text("Your account is authenticated, but the profile could not be loaded.")
		return
	if auth_mode == AuthMode.REGISTER:
		var saved: bool = await UserProfile.set_username(pending_username)
		if not saved:
			_on_auth_error_text("Your account was created, but your username could not be saved.")
			return
		await UserProfile.load_profile()
	pending_username = ""
	InviteManager.start_listening(UserProfile.current_username)
	get_tree().change_scene_to_file("res://ui/lobby.tscn")

func _on_auth_error(error: SupabaseAuthError) -> void:
	_on_auth_error_text(str(error.message))

func _on_auth_error_text(message: String) -> void:
	auth_in_progress = false
	submit_button.disabled = false
	login_mode_button.disabled = auth_mode == AuthMode.LOGIN
	register_mode_button.disabled = auth_mode == AuthMode.REGISTER
	status_label.text = message
