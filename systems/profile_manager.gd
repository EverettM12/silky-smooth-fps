extends Node

signal profile_loaded(username, score)

var current_username = ""

func get_my_id():
	if Supabase.auth.client:
		return Supabase.auth.client.id
	return null

func load_profile():
	var my_id = get_my_id()
	if not my_id:
		print("Error: Not logged in.")
		return

	var query = SupabaseQuery.new().from("profiles").select(["username", "score"]).eq("id", my_id)
	
	var task = Supabase.database.query(query)
	task.completed.connect(_on_load_completed)

func _on_load_completed(task):
	if task.error:
		print("Error loading profile: ", task.error)
	else:
		if task.data.size() > 0:
			var profile = task.data[0]
			print("Profile Loaded: ", profile)
			
			var username = profile.get("username", "Unknown")
			var score = profile.get("score", 0)
			current_username = username
			
			emit_signal("profile_loaded", username, score)
		else:
			print("No profile found for this user.")

func update_score(new_score_value: int):
	var my_id = get_my_id()
	var query = SupabaseQuery.new().from("profiles").update({"score": new_score_value}).eq("id", my_id)
	
	var task = Supabase.database.query(query)
	task.completed.connect(_on_save_completed)

func _on_save_completed(task):
	if task.error:
		print("Error saving data: ", task.error)
	else:
		print("Save successful!")
