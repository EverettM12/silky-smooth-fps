extends Control

enum AuthMode {
	LOGIN,
	REGISTER
}

@onready var account_chooser: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/AccountChooser
@onready var accounts_list: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/AccountChooser/AccountsList
@onready var add_account_button: Button = $CenterContainer/PanelContainer/VBoxContainer/AccountChooser/AddAccountButton
@onready var email_input: LineEdit = $CenterContainer/PanelContainer/VBoxContainer/EmailInput
@onready var username_input: LineEdit = $CenterContainer/PanelContainer/VBoxContainer/UsernameInput
@onready var password_input: LineEdit = $CenterContainer/PanelContainer/VBoxContainer/PasswordInput
@onready var login_mode_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ModeButtons/LoginMode
@onready var register_mode_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ModeButtons/RegisterMode
@onready var submit_button: Button = $CenterContainer/PanelContainer/VBoxContainer/SubmitButton
@onready var back_to_accounts_button: Button = $CenterContainer/PanelContainer/VBoxContainer/BackToAccountsButton
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
	add_account_button.pressed.connect(_show_login_form)
	back_to_accounts_button.pressed.connect(_show_account_picker)
	call_deferred("_show_initial_view")

func _show_initial_view() -> void:
	var accounts: Array[Dictionary] = SavedAccounts.get_accounts()
	if accounts.is_empty():
		_show_login_form()
	else:
		_show_account_picker()

func _show_account_picker() -> void:
	account_chooser.show()
	email_input.hide()
	username_input.hide()
	password_input.hide()
	login_mode_button.hide()
	register_mode_button.hide()
	submit_button.hide()
	back_to_accounts_button.hide()
	status_label.text = "Choose an account to sign in."
	_populate_accounts()

func _show_login_form() -> void:
	account_chooser.hide()
	email_input.show()
	password_input.show()
	login_mode_button.show()
	register_mode_button.show()
	submit_button.show()
	back_to_accounts_button.visible = not SavedAccounts.get_accounts().is_empty()
	_set_login_mode()

func _populate_accounts() -> void:
	for child in accounts_list.get_children():
		child.queue_free()
	await get_tree().process_frame
	for account in SavedAccounts.get_accounts():
		var email: String = str(account.get("email", "")).strip_edges()
		var username: String = str(account.get("username", "")).strip_edges()
		if email == "":
			continue
		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var account_button: Button = Button.new()
		account_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if username != "":
			account_button.text = "%s\n%s" % [username, email]
		else:
			account_button.text = email
		account_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		account_button.pressed.connect(_sign_in_saved_account.bind(email))
		var remove_button: Button = Button.new()
		remove_button.text = "Remove"
		remove_button.pressed.connect(_remove_saved_account.bind(email))
		row.add_child(account_button)
		row.add_child(remove_button)
		accounts_list.add_child(row)

func _remove_saved_account(email: String) -> void:
	if auth_in_progress:
		return
	SavedAccounts.remove_account(email)
	_populate_accounts()
	if SavedAccounts.get_accounts().is_empty():
		_show_login_form()

func _sign_in_saved_account(email: String) -> void:
	if auth_in_progress:
		return
	var account: Dictionary = SavedAccounts.get_account(email)
	var refresh_token: String = str(account.get("refresh_token", "")).strip_edges()
	if refresh_token == "":
		status_label.text = "That saved account needs to be added again."
		return
	auth_in_progress = true
	_set_account_buttons_disabled(true)
	add_account_button.disabled = true
	status_label.text = "Signing in as " + email + "..."
	var task: AuthTask = Supabase.auth.restore_session(refresh_token)
	var completed_task: AuthTask = await task.completed
	if completed_task.error != null:
		auth_in_progress = false
		_set_account_buttons_disabled(false)
		add_account_button.disabled = false
		status_label.text = "Saved sign-in failed. Use Add Account to sign in again."
		return
	await _finish_authenticated_session(false)

func _set_account_buttons_disabled(disabled: bool) -> void:
	for row in accounts_list.get_children():
		if row is HBoxContainer:
			for child in row.get_children():
				if child is Button:
					child.disabled = disabled

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
	back_to_accounts_button.disabled = true
	status_label.text = "Connecting to Supabase..."

func _on_auth_success(_user: SupabaseUser) -> void:
	if not auth_in_progress:
		return
	await _finish_authenticated_session(auth_mode == AuthMode.REGISTER)

func _finish_authenticated_session(is_registration: bool) -> void:
	status_label.text = "Loading profile..."
	var profile: Dictionary = await UserProfile.load_profile()
	if profile.is_empty():
		_on_auth_error_text("Your account is authenticated, but the profile could not be loaded.")
		return
	if is_registration:
		var saved: bool = await UserProfile.set_username(pending_username)
		if not saved:
			_on_auth_error_text("Your account was created, but your username could not be saved.")
			return
		await UserProfile.load_profile()
	if Supabase.auth.client != null:
		SavedAccounts.save_account(
			str(Supabase.auth.client.email),
			str(Supabase.auth.client.refresh_token),
			UserProfile.current_username
		)
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
	back_to_accounts_button.disabled = false
	status_label.text = message
