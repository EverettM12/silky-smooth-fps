extends CenterContainer

@export_group("Auth UI")
@export var email_input: LineEdit
@export var password_input: LineEdit
@export var status_label: Label
@export var login_btn: Button
@export var register_btn: Button
@export var username_input: LineEdit

@export_group("Saved Info UI")
@export var info_saved_label: Label
@export var saved_info_email: LineEdit
@export var saved_info_password: LineEdit
@export var insert_info: Button
@export var saved_info_username: LineEdit

@export var info_saved_label_2: Label
@export var saved_info_email_2: LineEdit
@export var saved_info_password_2: LineEdit
@export var insert_info_2: Button
@export var saved_info_username_2: LineEdit

const SAVE_PATH := "user://field_data.cfg"
const SECTION := "user_data"

var pending_username: String = ""

func _ready():
	Supabase.auth.signed_in.connect(_on_auth_success)
	Supabase.auth.signed_up.connect(_on_auth_success)
	Supabase.auth.error.connect(_on_auth_error)
	load_data()
	$VBoxContainer2/VBoxContainer/LoginSelected.show()
	$VBoxContainer2/VBoxContainer/RegisterSelected.show()
	$VBoxContainer2/HBoxContainer/VBoxContainer2.hide()
	$VBoxContainer2/HBoxContainer/VBoxContainer3.hide()
	$VBoxContainer2/HBoxContainer/VBoxContainer/UsernameInput.hide()
	$VBoxContainer2/HBoxContainer/VBoxContainer.hide()
	$VBoxContainer2/VBoxContainer/Return.hide()

func _on_login_pressed():
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	if email == "" or password == "":
		status_label.text = "Please enter email and password."
		return
		
	status_label.text = "Logging in..."
	disable_buttons(true)
	# Store typed username before authentication call
	pending_username = username_input.text.strip_edges()
	Supabase.auth.sign_in(email, password)

func _on_register_pressed():
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	var username = username_input.text.strip_edges()

	if email == "" or password == "":
		status_label.text = "Please enter email and password."
		return

	if username == "":
		status_label.text = "Please enter a username."
		return

	if len(password) < 6:
		status_label.text = "Password must be 6+ chars."
		return
		
	status_label.text = "Signing up..."
	disable_buttons(true)
	pending_username = username
	Supabase.auth.sign_up(email, password)

func _on_auth_success(user):
	var user_id = ""
	if user and "id" in user:
		user_id = str(user.id)

	var final_username = pending_username

	if user_id != "" and final_username != "":
		var profile_data = {
			"username": final_username,
			"score": 1
		}
		
		# Perform the update
		var query = SupabaseQuery.new().from("profiles").update(profile_data).eq("id", user_id)
		var result = await Supabase.database.query(query).completed
		print("Profile update result: ", result)

	# Update UserProfile Autoload
	if typeof(UserProfile) != TYPE_NIL:
		if "current_username" in UserProfile:
			UserProfile.current_username = final_username
		if UserProfile.has_method("save_profile"):
			UserProfile.save_profile()

	status_label.text = "Success! Logged in as: " + final_username
	pending_username = ""

	disable_buttons(false)
	get_tree().change_scene_to_file("res://Main/Main.tscn")

func _on_auth_error(err):
	disable_buttons(false)
	var msg = err.message if err and "message" in err else str(err)
	status_label.text = "Error: " + msg
	print("Auth Error: ", err)

func disable_buttons(disabled: bool):
	login_btn.disabled = disabled
	register_btn.disabled = disabled

func save_data() -> void:
	var config := ConfigFile.new()
	
	# Account 1
	config.set_value(SECTION, "email", saved_info_email.text)
	config.set_value(SECTION, "password", saved_info_password.text)
	if saved_info_username:
		config.set_value(SECTION, "username", saved_info_username.text)
	
	# Account 2
	config.set_value(SECTION, "email_2", saved_info_email_2.text)
	config.set_value(SECTION, "password_2", saved_info_password_2.text)
	if saved_info_username_2:
		config.set_value(SECTION, "username_2", saved_info_username_2.text)
	
	var err := config.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save data: %s" % err)

func load_data() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return
		
	# Account 1
	saved_info_email.text = config.get_value(SECTION, "email", "")
	saved_info_password.text = config.get_value(SECTION, "password", "")
	if saved_info_username:
		saved_info_username.text = config.get_value(SECTION, "username", "")
	
	# Account 2
	saved_info_email_2.text = config.get_value(SECTION, "email_2", "")
	saved_info_password_2.text = config.get_value(SECTION, "password_2", "")
	if saved_info_username_2:
		saved_info_username_2.text = config.get_value(SECTION, "username_2", "")

func _on_insert_info_pressed() -> void:
	save_data()
	email_input.text = saved_info_email.text
	password_input.text = saved_info_password.text
	if saved_info_username and username_input:
		username_input.text = saved_info_username.text

func _on_insert_info_2_pressed() -> void:
	save_data()
	email_input.text = saved_info_email_2.text
	password_input.text = saved_info_password_2.text
	if saved_info_username_2 and username_input:
		username_input.text = saved_info_username_2.text


func _on_login_selected_pressed() -> void:
	$VBoxContainer2/VBoxContainer/Return.show()
	$VBoxContainer2/VBoxContainer/LoginSelected.hide()
	$VBoxContainer2/VBoxContainer/RegisterSelected.hide()
	$VBoxContainer2/HBoxContainer/VBoxContainer2.show()
	$VBoxContainer2/HBoxContainer/VBoxContainer3.show()
	$VBoxContainer2/HBoxContainer/VBoxContainer/UsernameInput.hide()
	$VBoxContainer2/HBoxContainer/VBoxContainer.show()
	$VBoxContainer2/HBoxContainer/VBoxContainer/RegisterButton.hide()
	$VBoxContainer2/HBoxContainer/VBoxContainer/LoginButton.show()


func _on_register_selected_pressed() -> void:
	$VBoxContainer2/VBoxContainer/Return.show()
	$VBoxContainer2/VBoxContainer/LoginSelected.hide()
	$VBoxContainer2/VBoxContainer/RegisterSelected.hide()
	$VBoxContainer2/HBoxContainer/VBoxContainer2.show()
	$VBoxContainer2/HBoxContainer/VBoxContainer3.show()
	$VBoxContainer2/HBoxContainer/VBoxContainer/UsernameInput.show()
	$VBoxContainer2/HBoxContainer/VBoxContainer.show()
	$VBoxContainer2/HBoxContainer/VBoxContainer/RegisterButton.show()
	$VBoxContainer2/HBoxContainer/VBoxContainer/LoginButton.hide()


func _on_return_pressed() -> void:
	$VBoxContainer2/VBoxContainer/Return.hide()
	$VBoxContainer2/VBoxContainer/LoginSelected.show()
	$VBoxContainer2/VBoxContainer/RegisterSelected.show()
	$VBoxContainer2/HBoxContainer/VBoxContainer2.hide()
	$VBoxContainer2/HBoxContainer/VBoxContainer3.hide()
	$VBoxContainer2/HBoxContainer/VBoxContainer/UsernameInput.hide()
	$VBoxContainer2/HBoxContainer/VBoxContainer.hide()
	$VBoxContainer2/HBoxContainer/VBoxContainer/RegisterButton.hide()
	$VBoxContainer2/HBoxContainer/VBoxContainer/LoginButton.hide()
