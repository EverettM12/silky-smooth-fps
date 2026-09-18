class_name Main
extends Node3D

#@onready var player: Player = $Player
@onready var start_pos: MeshInstance3D = $"Start Pos"

func _ready() -> void:
	#if !is_instance_valid(player):
		#CloseGame.close("Player missing!")
		#return
	if !is_instance_valid(start_pos):
		CloseGame.close("Start position missing!")
		return

	#player.global_position = start_pos.global_position
	start_pos.hide()

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("restart"):
		#player.global_position = start_pos.global_position
