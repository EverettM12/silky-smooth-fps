extends Node
## MultiplayerSessionManager
##
## Global autoload that watches the active MultiPlayCore node for any kind of
## session-ending event (host quit, host crash, being kicked, connection loss,
## voluntary leave, failed join, etc.) and makes sure the local player always
## ends up back at the lobby (Main.tscn) instead of being left in a broken,
## frozen, or disconnected state.
##
## This does not replace or duplicate MultiPlayCore logic. It only listens to
## MultiPlayCore's existing signals (disconnected_from_server, connection_error,
## server_started, server_stopped, connected_to_server) and calls its existing
## public API (close_server(), MPPlayer.disconnect_player()).
##
## Integration points:
##   - main.gd calls MultiplayerSessionManager.register_mpc(mpc) in _ready()
##     so this manager always knows which MultiPlayCore instance is active.
##   - ui_manager.gd's Quit button calls MultiplayerSessionManager.leave_session()
##     instead of get_tree().quit().
##   - ui_manager.gd asks request_return_to_lobby() for the host-only
##     non-disconnecting return-to-lobby path; main.gd handles the actual
##     lobby/game UI transition.

## Emitted the moment a session-ending event is detected, before any cleanup or
## scene transition happens. `reason` is the same string MultiPlayCore already
## uses, e.g. "SERVER_CLOSED", "Unknown", "TIMEOUT", "USER_REQUESTED_DISCONNECT",
## or a custom reason passed to MPPlayer.kick().
#signal session_ended(reason: String)
#
### Emitted right after session_ended, ONLY when the local player appears to have
### been actively kicked/rejected by the host (as opposed to a graceful leave,
### host shutdown, timeout, or failed connection). See _is_kick_reason().
#signal player_kicked(reason: String)
#
### Emitted once the lobby scene (Main.tscn) has finished reloading and is ready.
#signal returned_to_lobby()
#
### Emitted when the local host requests a return from gameplay to the active
### lobby without closing the multiplayer session.
#signal return_to_lobby_requested()
#
### Emitted after a still-connected multiplayer session has moved back to the
### lobby UI. Unlike returned_to_lobby(), this does not imply a scene reload.
#signal active_session_returned_to_lobby()
#
#const LOBBY_SCENE_PATH := "res://Main/Main.tscn"
#
### Reasons that mean "the host actively rejected/kicked you".
#const KICK_REASONS := [
	#"SERVER_FULL",
	#"AUTH_FAILED",
	#"INVALID_HANDSHAKE",
	#"VERSION_MISMATCH",
#]
#
### Reasons that are always a graceful/expected end of session, never a kick.
#const GRACEFUL_REASONS := [
	#"USER_REQUESTED_DISCONNECT",
	#"SERVER_CLOSED",
	#"HOST_ENDED_SESSION",
	#"Unknown",
	#"Connection Failure",
	#"TIMEOUT",
#]
#
#const REASON_MESSAGES := {
	#"SERVER_FULL": "The server is full.",
	#"AUTH_FAILED": "Authentication failed.",
	#"TIMEOUT": "The connection timed out.",
	#"CONNECTION_FAILURE": "Failed to connect to the host.",
	#"Connection Failure": "Failed to connect to the host.",
	#"INVALID_HANDSHAKE": "The server rejected your connection data.",
	#"VERSION_MISMATCH": "Your game version doesn't match the host's.",
	#"GAME_IN_PROGRESS": "That game is already in progress.",
	#"SERVER_CLOSED": "The host closed the server.",
	#"HOST_ENDED_SESSION": "You ended the session.",
	#"Unknown": "Lost connection to the host.",
	#"USER_REQUESTED_DISCONNECT": "You left the session.",
#}
#
### The MultiPlayCore instance currently active in the loaded scene, if any.
#var mpc: MultiPlayCore = null
#
### True once the local player has fully connected (client) or started (host).
#var is_in_session: bool = false
#
### Guards against handling the same session-ending event twice (e.g. several
### disconnect signals firing in the same frame, or a duplicate scene transition
### being triggered while one is already in flight).
#var is_handling_session_end: bool = false
#
### Info about the most recent disconnect, so the lobby UI can show a message
### after the scene reload finishes. Cleared via clear_last_disconnect_info().
#var last_disconnect_reason: String = ""
#var was_last_disconnect_a_kick: bool = false
#
### Last ConnectionError enum value MultiPlayCore reported, or -1 if none.
### Supplementary only — not used for kick detection, since MultiPlayCore
### doesn't emit it in a consistent order relative to disconnected_from_server
### on every code path.
#var last_connection_error: int = -1
#
#var _return_pending: bool = false
#
#
### Called by main.gd once its MultiPlayCore node is ready. Safe to call again
### whenever a new MultiPlayCore instance exists (e.g. after the lobby reloads).
#func register_mpc(new_mpc: MultiPlayCore) -> void:
	#if new_mpc == mpc:
		#return
#
	#_disconnect_mpc_signals()
	#mpc = new_mpc
	#is_handling_session_end = false
	#is_in_session = false
#
	#if mpc != null:
		#mpc.disconnected_from_server.connect(_on_disconnected_from_server)
		#mpc.connection_error.connect(_on_connection_error)
		#mpc.connected_to_server.connect(_on_connected_to_server)
		#mpc.server_started.connect(_on_server_started)
		#mpc.server_stopped.connect(_on_server_stopped)
#
	#if _return_pending:
		#_return_pending = false
		#returned_to_lobby.emit()
#
#
### True if the local player is currently the host/server of the active session.
### Also true in Solo/OneScreen/Swap modes, since MultiPlayCore hosts locally there.
#func is_local_host() -> bool:
	#return mpc != null and mpc.is_server
#
#
### Host-only entry point for returning from gameplay to the existing lobby
### while keeping the multiplayer peer and MPPlayer collection alive.
#func request_return_to_lobby() -> bool:
	#if not is_local_host():
		#return false
	#if mpc == null or not is_instance_valid(mpc):
		#return false
	#if is_handling_session_end:
		#return false
#
	#return_to_lobby_requested.emit()
	#return true
#
#
#func notify_active_session_returned_to_lobby() -> void:
	#active_session_returned_to_lobby.emit()
#
#
### Public entry point for "the local player wants to leave the current
### game/session" (e.g. the in-game Quit button). Decides whether that means
### shutting the server down (host) or just disconnecting (client), then
### returns to the lobby either way.
#func leave_session() -> void:
	#if mpc == null:
		#_begin_session_end("USER_REQUESTED_DISCONNECT")
		#return
#
	#if mpc.is_server:
		#end_session_as_host()
	#else:
		#leave_session_as_client()
#
#
### Host-only: notifies/kicks any connected clients (they each recover through
### their own disconnected_from_server -> this same manager, on their end),
### shuts the server down via MultiPlayCore's own close_server(), then returns
### the host to the lobby.
#func end_session_as_host() -> void:
	#if mpc == null or not mpc.is_server:
		#return
	#InviteManager.wipe_sent_invites()
	#if mpc.online_peer != null:
		#mpc.close_server() # kicks all peers with SERVER_CLOSED, closes the peer, emits server_stopped
	#else:
		#_begin_session_end("HOST_ENDED_SESSION")
#
#
### Client-only: cleanly disconnects from the host using MPPlayer's own
### disconnect API, then returns to the lobby.
#func leave_session_as_client() -> void:
	#if mpc == null or mpc.is_server:
		#return
	#if mpc.local_player != null:
		#mpc.local_player.disconnect_player() # emits disconnected_from_server locally
		#if mpc.local_player:
			#mpc.local_player.despawn_node()
	#else:
		#_begin_session_end("USER_REQUESTED_DISCONNECT")
#
#
#func clear_last_disconnect_info() -> void:
	#last_disconnect_reason = ""
	#was_last_disconnect_a_kick = false
	#last_connection_error = -1
#
#
### Human-readable message for last_disconnect_reason, for lobby UI to display.
#func get_last_disconnect_message() -> String:
	#if last_disconnect_reason == "":
		#return ""
	#if REASON_MESSAGES.has(last_disconnect_reason):
		#return REASON_MESSAGES[last_disconnect_reason]
	#return "Disconnected: %s" % last_disconnect_reason
#
#
## ---------------------------------------------------------------------------
## MultiPlayCore signal handlers
## ---------------------------------------------------------------------------
#
#func _on_server_started() -> void:
	#is_in_session = true
#
#func _on_connected_to_server(_local_player: MPPlayer) -> void:
	#is_in_session = true
#
#func _on_server_stopped() -> void:
	#_begin_session_end("HOST_ENDED_SESSION")
#
#func _on_connection_error(reason: int) -> void:
	#last_connection_error = reason
#
#func _on_disconnected_from_server(reason: String) -> void:
	## MultiPlayCore's single-target/broadcast kick RPC (_request_disconnect_peer,
	## used for TIMEOUT kicks and for SERVER_FULL/AUTH_FAILED/INVALID_HANDSHAKE/
	## VERSION_MISMATCH join rejections) is configured with "call_local" and has
	## no sender-id guard, so the HOST also runs it locally every time it kicks
	## or rejects someone else. That's an addon quirk, not the host actually
	## being disconnected - ignore it unless it's a reason we used ourselves to
	## intentionally end our own session.
	#if mpc != null and mpc.is_server and reason not in ["SERVER_CLOSED", "HOST_ENDED_SESSION"]:
		#return
	#_begin_session_end(reason)
#
#
## ---------------------------------------------------------------------------
## Internal
## ---------------------------------------------------------------------------
#
#func _is_kick_reason(reason: String) -> bool:
	#if reason in KICK_REASONS:
		#return true
	#if reason in GRACEFUL_REASONS:
		#return false
	## Any other reason reaching a client is almost certainly a custom message
	## passed to MPPlayer.kick(reason) by the host.
	#return true
#
#func _begin_session_end(reason: String) -> void:
	#if is_handling_session_end:
		#return
	#is_handling_session_end = true
	#is_in_session = false
#
	#var kicked := _is_kick_reason(reason)
	#last_disconnect_reason = reason
	#was_last_disconnect_a_kick = kicked
#
	#session_ended.emit(reason)
	#if kicked:
		#player_kicked.emit(reason)
#
	#_return_pending = true
	#_do_return_to_lobby.call_deferred()
#
#func _do_return_to_lobby() -> void:
	#mpc = null
#
	## Make sure no stale MultiplayerPeer lingers into the lobby or next session.
	#if multiplayer.multiplayer_peer != null:
		#multiplayer.multiplayer_peer.close()
		#multiplayer.multiplayer_peer = null
#
	#var err := get_tree().change_scene_to_file(LOBBY_SCENE_PATH)
	#if err != OK:
		#push_error("MultiplayerSessionManager: failed to reload lobby scene at %s (error %d)" % [LOBBY_SCENE_PATH, err])
#
#func _disconnect_mpc_signals() -> void:
	#if mpc == null or not is_instance_valid(mpc):
		#return
	#if mpc.disconnected_from_server.is_connected(_on_disconnected_from_server):
		#mpc.disconnected_from_server.disconnect(_on_disconnected_from_server)
	#if mpc.connection_error.is_connected(_on_connection_error):
		#mpc.connection_error.disconnect(_on_connection_error)
	#if mpc.connected_to_server.is_connected(_on_connected_to_server):
		#mpc.connected_to_server.disconnect(_on_connected_to_server)
	#if mpc.server_started.is_connected(_on_server_started):
		#mpc.server_started.disconnect(_on_server_started)
	#if mpc.server_stopped.is_connected(_on_server_stopped):
		#mpc.server_stopped.disconnect(_on_server_stopped)
