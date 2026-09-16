class_name PlayerState
extends Node

enum MovementState {
	GROUNDED,
	AIRBORNE,
	SLIDING,
	WALL_RUNNING
}

var current_state: MovementState = MovementState.AIRBORNE
var previous_state: MovementState

func change_state(new_state: MovementState) -> void:
	if current_state == new_state:
		return

	previous_state = current_state
	current_state = new_state

func is_grounded() -> bool:
	return current_state == MovementState.GROUNDED
