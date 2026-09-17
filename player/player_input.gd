class_name PlayerInput
extends Node

@export_group("Input Actions")
@export var move_forward_action: StringName = &"move_forward"
@export var move_backward_action: StringName = &"move_backward"
@export var move_left_action: StringName = &"move_left"
@export var move_right_action: StringName = &"move_right"
@export var jump_action: StringName = &"jump"
@export var crouch_action: StringName = &"crouch"
@export var sprint_action: StringName = &"sprint"
@export var dash_action: StringName = &"dash"
@export var grapple_action: StringName = &"grapple"

var movement_input: Vector2 = Vector2.ZERO
var look_input: Vector2 = Vector2.ZERO
var jump_pressed: bool = false
var jump_just_pressed: bool = false
var crouch_pressed: bool = false
var crouch_just_pressed: bool = false
var sprint_pressed: bool = false
var dash_pressed: bool = false
var grapple_pressed: bool = false

func _physics_process(_delta: float) -> void:
	movement_input = Input.get_vector(move_left_action, move_right_action, move_forward_action, move_backward_action)
	jump_just_pressed = Input.is_action_just_pressed(jump_action)
	jump_pressed = Input.is_action_pressed(jump_action)
	crouch_just_pressed = Input.is_action_just_pressed(crouch_action)
	crouch_pressed = Input.is_action_pressed(crouch_action)
	sprint_pressed = Input.is_action_pressed(sprint_action)
	dash_pressed = Input.is_action_just_pressed(dash_action)
	grapple_pressed = Input.is_action_just_pressed(grapple_action)
