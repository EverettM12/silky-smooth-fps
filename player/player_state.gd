class_name PlayerState
extends Node

enum MovementState {
	GROUNDED,
	AIRBORNE,
	SLIDING,
	WALL_RUNNING,
	GRAPPLING
}

var current_state: MovementState = MovementState.AIRBORNE
var previous_state: MovementState = MovementState.AIRBORNE

func change_state(new_state: MovementState) -> void:
	if current_state == new_state:
		return
	previous_state = current_state
	current_state = new_state

func is_grounded() -> bool:
	return current_state == MovementState.GROUNDED

func is_airborne() -> bool:
	return current_state == MovementState.AIRBORNE

func is_sliding() -> bool:
	return current_state == MovementState.SLIDING

func is_wall_running() -> bool:
	return current_state == MovementState.WALL_RUNNING

func is_grappling() -> bool:
	return current_state == MovementState.GRAPPLING
