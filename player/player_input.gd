class_name PlayerInput
extends Node

var move_input: Vector2
var look_input: Vector2

var jump_pressed: bool
var crouch_pressed: bool
var sprint_pressed: bool
var dash_pressed: bool

func _process(_delta: float) -> void:
	move_input = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_backward"
	)

	jump_pressed = Input.is_action_just_pressed("jump")
	crouch_pressed = Input.is_action_pressed("crouch")
	sprint_pressed = Input.is_action_pressed("sprint")
	dash_pressed = Input.is_action_just_pressed("dash")
