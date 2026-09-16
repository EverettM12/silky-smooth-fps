class_name PlayerMovement
extends Node

@export_group("Exports")
@export var player: CharacterBody3D
@export var input: PlayerInput
@export var state: PlayerState
@export_group("")

#func _physics_process(delta: float) -> void:
	#update_state()
#
	#match state.current_state:
		#PlayerState.MovementState.GROUNDED:
			#process_grounded(delta)
#
		#PlayerState.MovementState.AIRBORNE:
			#process_airborne(delta)
#
		#PlayerState.MovementState.SLIDING:
			#process_sliding(delta)
#
		#PlayerState.MovementState.WALL_RUNNING:
			#process_wall_running(delta)
#
	#player.move_and_slide()
