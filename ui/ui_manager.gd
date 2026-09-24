extends Control

@onready var pause_panel: PanelContainer = $PausePanel
@onready var lobby_button: Button = $PausePanel/VBoxContainer/LobbyButton

func _ready() -> void:
	pause_panel.hide()
	lobby_button.pressed.connect(_on_lobby_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if pause_panel.visible:
			_close_pause()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()

func _open_pause() -> void:
	pause_panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_pause() -> void:
	pause_panel.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_lobby_button_pressed() -> void:
	MultiplayerSessionManager.stop_session()
	get_tree().change_scene_to_file("res://ui/lobby.tscn")
