extends Node

signal invite_received(from_who, party_code)
signal invite_sent(to_who, party_code)
signal invite_failed(to_who, reason)

var _rt_client : RealtimeClient
var _channel : RealtimeChannel
var _my_username : String = ""
var _seen_invite_ids := {}
var _polling := false
var _poll_request_active := false
var _poll_generation := 0
var _sent_invites := {}
var _is_quitting_after_cleanup := false

const POLL_INTERVAL_SECONDS := 3.0
const POLL_INVITE_LIMIT := 10
const INVITE_EXPIRATION_SECONDS := 60.0

func _ready() -> void:
	get_tree().auto_accept_quit = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_after_wiping_sent_invites()

func start_listening(my_username: String) -> void:
	var username := my_username.strip_edges()
	if username == "":
		push_warning("InviteManager: cannot listen for invites without a username.")
		return
	if _my_username == username and _channel != null:
		return

	_stop_listening()
	_my_username = username
	_seen_invite_ids.clear()

	_rt_client = Supabase.realtime.client()

	_rt_client.connected.connect(_on_client_connected)
	_rt_client.error.connect(_on_realtime_error)

	var err := _rt_client.connect_client()
	if err != OK:
		push_error("InviteManager: failed to connect realtime client. Error code: %s" % err)

	_polling = true
	_poll_generation += 1
	_poll_invites()
	_poll_invites_loop(_poll_generation)

func _on_client_connected():
	_channel = _rt_client.channel("public", "party_invites", "receiver_username=eq." + _my_username)

	_channel.insert.connect(_on_invite)
	_channel.subscribe()

@warning_ignore("shadowed_variable")
func _on_invite(payload, _channel):
	if payload.get("receiver_username", "") != _my_username:
		return

	_emit_invite_if_new(payload)

func send_invite(friend_name: String, my_code: String) -> void:
	var receiver := friend_name.strip_edges()
	var party_code := my_code.strip_edges()
	var my_name = UserProfile.current_username.strip_edges()

	if my_name == "":
		invite_failed.emit(receiver, "Your profile has not loaded yet.")
		return
	if receiver == "":
		invite_failed.emit(receiver, "Enter a friend's username before sending an invite.")
		return
	if party_code == "" or party_code == "*":
		invite_failed.emit(receiver, "Start hosting with a joinable address before sending an invite.")
		return

	var data = {
		"sender_username": my_name,
		"receiver_username": receiver,
		"party_code": party_code
	}

	var query = SupabaseQuery.new().from("party_invites").insert([data])
	var task := Supabase.database.query(query)
	task.completed.connect(_on_invite_insert_completed.bind(receiver, party_code))

func _on_invite_insert_completed(task: DatabaseTask, receiver: String, party_code: String) -> void:
	if task.error:
		var reason := str(task.error)
		push_error("InviteManager: failed to send invite to %s. %s" % [receiver, reason])
		invite_failed.emit(receiver, reason)
		return

	#print("Invite saved for %s: %s" % [receiver, task.data])
	var invite_id := _get_inserted_invite_id(task.data)
	if invite_id != "":
		_sent_invites[invite_id] = receiver
		_expire_invite_after_delay(invite_id, receiver)
	else:
		push_warning("InviteManager: invite was sent, but no invite id was returned for cleanup.")
	invite_sent.emit(receiver, party_code)

func _on_realtime_error(message: Dictionary) -> void:
	push_error("InviteManager realtime error: %s" % JSON.stringify(message))

func _poll_invites_loop(generation: int) -> void:
	while _polling and generation == _poll_generation:
		await get_tree().create_timer(POLL_INTERVAL_SECONDS).timeout
		if generation == _poll_generation:
			_poll_invites()

func _poll_invites() -> void:
	if _my_username == "" or _poll_request_active:
		return

	_poll_request_active = true
	var query = SupabaseQuery.new().from("party_invites")
	query.select(["id", "sender_username", "receiver_username", "party_code", "created_at"])
	query.eq("receiver_username", _my_username)
	query.order("created_at", SupabaseQuery.Directions.Descending)
	query.range(0, POLL_INVITE_LIMIT - 1)

	var task := Supabase.database.query(query)
	task.completed.connect(_on_poll_invites_completed)

func _on_poll_invites_completed(task: DatabaseTask) -> void:
	_poll_request_active = false
	if task.error:
		push_warning("InviteManager: failed to poll invites. %s" % str(task.error))
		return
	if task.data == null:
		return

	for invite in task.data:
		if invite is Dictionary:
			_emit_invite_if_new(invite)

func _emit_invite_if_new(invite: Dictionary) -> void:
	if invite.get("receiver_username", "") != _my_username:
		return

	var invite_id := str(invite.get("id", ""))
	if invite_id != "":
		if _seen_invite_ids.has(invite_id):
			return
		_seen_invite_ids[invite_id] = true

	var sender := str(invite.get("sender_username", "")).strip_edges()
	var code := str(invite.get("party_code", "")).strip_edges()
	if sender == "" or code == "":
		push_warning("InviteManager: received an invite with missing sender or party code.")
		return

	#print("Invite delivered to %s from %s with party code %s" % [_my_username, sender, code])
	emit_signal("invite_received", sender, code)

func _get_inserted_invite_id(data) -> String:
	if data is Array and not data.is_empty() and data[0] is Dictionary:
		return str(data[0].get("id", ""))
	if data is Dictionary:
		return str(data.get("id", ""))
	return ""

func _expire_invite_after_delay(invite_id: String, receiver: String) -> void:
	await get_tree().create_timer(INVITE_EXPIRATION_SECONDS).timeout
	if not _sent_invites.has(invite_id):
		return

	_delete_sent_invite(invite_id, receiver, "expired")

func wipe_sent_invites() -> void:
	var invite_ids := _sent_invites.keys()
	for invite_id in invite_ids:
		var id := str(invite_id)
		_delete_sent_invite(id, str(_sent_invites[id]), "host closed")

func wipe_sent_invites_and_wait() -> void:
	var invite_snapshot := _sent_invites.duplicate()
	_sent_invites.clear()
	for invite_id in invite_snapshot.keys():
		await _delete_sent_invite_and_wait(str(invite_id), str(invite_snapshot[invite_id]), "game closed")

func _quit_after_wiping_sent_invites() -> void:
	if _is_quitting_after_cleanup:
		return
	_is_quitting_after_cleanup = true
	_quit_after_wiping_sent_invites_async()

func _quit_after_wiping_sent_invites_async() -> void:
	await wipe_sent_invites_and_wait()
	get_tree().quit()

func _delete_sent_invite(invite_id: String, receiver: String, reason: String) -> void:
	if not _sent_invites.has(invite_id):
		return
	_sent_invites.erase(invite_id)

	var query = SupabaseQuery.new().from("party_invites")
	query.delete()
	query.eq("id", invite_id)

	var task := Supabase.database.query(query)
	task.completed.connect(_on_sent_invite_deleted.bind(invite_id, receiver, reason))

func _delete_sent_invite_and_wait(invite_id: String, receiver: String, reason: String) -> void:
	var query = SupabaseQuery.new().from("party_invites")
	query.delete()
	query.eq("id", invite_id)

	var task := Supabase.database.query(query)
	var completed_task: DatabaseTask = await task.completed
	_on_sent_invite_deleted(completed_task, invite_id, receiver, reason)

func _on_sent_invite_deleted(task: DatabaseTask, invite_id: String, receiver: String, reason: String) -> void:
	if task.error:
		push_warning("InviteManager: failed to delete %s invite %s for %s. %s" % [reason, invite_id, receiver, str(task.error)])
		return

	#print("Invite %s for %s was removed from Supabase because it %s." % [invite_id, receiver, reason])

func _stop_listening() -> void:
	_polling = false
	_poll_request_active = false
	_poll_generation += 1
	if _channel != null:
		_channel.close()
		_channel = null
	if _rt_client != null and is_instance_valid(_rt_client):
		_rt_client.disconnect_client()
		_rt_client.queue_free()
		_rt_client = null
