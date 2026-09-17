extends Control

@export var cross_hair: Label

var grapple: PlayerGrapple = null

func _ready() -> void:
	cross_hair.text = "[]"

func _process(_delta: float) -> void:
	if cross_hair == null:
		return
	var centered_cross_hair_position: Vector2 = (size - cross_hair.size) * 0.5
	if grapple == null or not is_instance_valid(grapple):
		grapple = get_tree().get_first_node_in_group("grapple_controller") as PlayerGrapple
	if grapple == null or not is_instance_valid(grapple) or grapple.camera == null:
		cross_hair.position = centered_cross_hair_position
		return
	if not grapple.is_target_valid() or grapple.is_grappling():
		cross_hair.position = centered_cross_hair_position
		return
	var target_position: Vector3 = grapple.get_target_position()
	if grapple.camera.is_position_behind(target_position):
		cross_hair.position = centered_cross_hair_position
		return
	var target_screen_position: Vector2 = grapple.camera.unproject_position(target_position)
	cross_hair.position = target_screen_position - cross_hair.size * 0.5
