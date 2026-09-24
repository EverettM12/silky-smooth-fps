extends Node

const SAVE_PATH: String = "user://saved_accounts.json"

var accounts: Dictionary = {}

func _ready() -> void:
	_load_accounts()
	if not Supabase.auth.token_refreshed.is_connected(_on_token_refreshed):
		Supabase.auth.token_refreshed.connect(_on_token_refreshed)

func get_accounts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for email in accounts:
		var account: Dictionary = accounts[email]
		if account is Dictionary:
			result.append(account.duplicate(true))
	result.sort_custom(_sort_accounts)
	return result

func save_account(email: String, refresh_token: String, username: String) -> bool:
	var clean_email: String = email.strip_edges().to_lower()
	var clean_refresh_token: String = refresh_token.strip_edges()
	var clean_username: String = username.strip_edges()
	if clean_email == "" or clean_refresh_token == "":
		return false
	accounts[clean_email] = {
		"email": clean_email,
		"refresh_token": clean_refresh_token,
		"username": clean_username
	}
	return _save_accounts()

func remove_account(email: String) -> bool:
	var clean_email: String = email.strip_edges().to_lower()
	if not accounts.has(clean_email):
		return false
	accounts.erase(clean_email)
	return _save_accounts()

func get_account(email: String) -> Dictionary:
	var clean_email: String = email.strip_edges().to_lower()
	var account: Variant = accounts.get(clean_email, {})
	if account is Dictionary:
		return account.duplicate(true)
	return {}

func _on_token_refreshed(refreshed_user: SupabaseUser) -> void:
	if refreshed_user == null:
		return
	var clean_email: String = str(refreshed_user.email).strip_edges().to_lower()
	if clean_email == "" or not accounts.has(clean_email):
		return
	var account: Dictionary = accounts[clean_email]
	account["refresh_token"] = refreshed_user.refresh_token
	accounts[clean_email] = account
	_save_accounts()

func _save_accounts() -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(accounts))
	file.close()
	return true

func _load_accounts() -> void:
	accounts.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var raw: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		accounts = parsed

func _sort_accounts(a: Dictionary, b: Dictionary) -> bool:
	var a_name: String = str(a.get("username", "")).strip_edges()
	var b_name: String = str(b.get("username", "")).strip_edges()
	if a_name == "" and b_name != "":
		return false
	if a_name != "" and b_name == "":
		return true
	return str(a.get("email", "")).nocasecmp_to(str(b.get("email", ""))) < 0
