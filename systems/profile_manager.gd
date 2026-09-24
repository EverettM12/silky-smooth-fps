extends Node

signal profile_loaded(username: String, score: int)

var current_username: String = ""

func get_my_id() -> String:
	if Supabase.auth.client != null:
		return str(Supabase.auth.client.id)
	return ""

func load_profile() -> Dictionary:
	var my_id: String = get_my_id()
	if my_id == "":
		return {}
	var query: SupabaseQuery = SupabaseQuery.new().from("profiles").select(["username", "score"]).eq("id", my_id)
	var task: DatabaseTask = Supabase.database.query(query)
	var completed_task: DatabaseTask = await task.completed
	if completed_task.error or completed_task.data == null:
		return {}
	if completed_task.data.size() == 0:
		return {}
	var profile: Dictionary = completed_task.data[0]
	current_username = str(profile.get("username", "")).strip_edges()
	var score: int = int(profile.get("score", 0))
	profile_loaded.emit(current_username, score)
	return profile

func set_username(username: String) -> bool:
	var my_id: String = get_my_id()
	var clean_username: String = username.strip_edges()
	if my_id == "" or clean_username == "":
		return false
	var query: SupabaseQuery = SupabaseQuery.new().from("profiles").update({"username": clean_username}).eq("id", my_id)
	var task: DatabaseTask = Supabase.database.query(query)
	var completed_task: DatabaseTask = await task.completed
	if completed_task.error:
		return false
	current_username = clean_username
	return true

func update_score(new_score_value: int) -> bool:
	var my_id: String = get_my_id()
	if my_id == "":
		return false
	var query: SupabaseQuery = SupabaseQuery.new().from("profiles").update({"score": new_score_value}).eq("id", my_id)
	var task: DatabaseTask = Supabase.database.query(query)
	var completed_task: DatabaseTask = await task.completed
	return not completed_task.error

func clear_profile() -> void:
	current_username = ""
