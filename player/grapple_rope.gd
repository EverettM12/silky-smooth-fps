@tool
class_name GrappleRope
extends MeshInstance3D

@export_group("Rope")
@export var rope_radius: float = 0.025
@export_range(3, 32, 1) var rope_section_resolution: int = 8
@export var rope_start_offset: Vector3 = Vector3.ZERO
@export var rope_end_offset: Vector3 = Vector3.ZERO
@export var rope_smoothing: float = 24.0
@export var rope_material: Material
@export var rope_visible_when_inactive: bool = false

var grapple: PlayerGrapple = null
var rope_mesh: ImmediateMesh = ImmediateMesh.new()
var smoothed_start_position: Vector3 = Vector3.ZERO
var smoothed_end_position: Vector3 = Vector3.ZERO
var rope_position_initialized: bool = false

func _ready() -> void:
	grapple = get_parent() as PlayerGrapple
	mesh = rope_mesh
	if rope_material != null:
		material_override = rope_material
	else:
		var default_material: StandardMaterial3D = StandardMaterial3D.new()
		default_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		default_material.albedo_color = Color(0.9, 0.9, 0.9, 1.0)
		material_override = default_material
	visible = rope_visible_when_inactive

func _process(delta: float) -> void:
	if grapple == null:
		grapple = get_parent() as PlayerGrapple
	if grapple == null or not grapple.is_grappling():
		visible = rope_visible_when_inactive
		rope_mesh.clear_surfaces()
		return
	var target_position: Vector3 = grapple.get_target_position() + rope_end_offset
	var start_position: Vector3 = get_rope_start_position() + rope_start_offset
	var smoothing_weight: float = 1.0 - exp(-max(rope_smoothing, 0.1) * delta)
	if not rope_position_initialized:
		smoothed_start_position = start_position
		smoothed_end_position = target_position
		rope_position_initialized = true
	else:
		smoothed_start_position = smoothed_start_position.lerp(start_position, smoothing_weight)
		smoothed_end_position = smoothed_end_position.lerp(target_position, smoothing_weight)
	_update_rope_mesh()
	visible = true

func get_rope_start_position() -> Vector3:
	if grapple.camera == null:
		return grapple.player.global_position
	return grapple.camera.global_position

func _update_rope_mesh() -> void:
	var rope_direction: Vector3 = smoothed_end_position - smoothed_start_position
	var rope_length: float = rope_direction.length()
	if rope_length <= 0.001:
		rope_mesh.clear_surfaces()
		return
	var direction: Vector3 = rope_direction / rope_length
	var reference_axis: Vector3 = Vector3.UP
	if abs(direction.dot(reference_axis)) > 0.98:
		reference_axis = Vector3.RIGHT
	var right_axis: Vector3 = direction.cross(reference_axis).normalized()
	var up_axis: Vector3 = right_axis.cross(direction).normalized()
	var start_circle: PackedVector3Array = _generate_cross_section(smoothed_start_position, right_axis, up_axis)
	var end_circle: PackedVector3Array = _generate_cross_section(smoothed_end_position, right_axis, up_axis)
	rope_mesh.clear_surfaces()
	rope_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_draw_rope_surface(start_circle, end_circle)
	_draw_rope_cap(start_circle, -direction)
	_draw_rope_cap(end_circle, direction)
	rope_mesh.surface_end()

func _generate_cross_section(center: Vector3, right_axis: Vector3, up_axis: Vector3) -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	for index: int in rope_section_resolution:
		var angle: float = TAU * float(index) / float(rope_section_resolution)
		var offset: Vector3 = right_axis * cos(angle) * rope_radius + up_axis * sin(angle) * rope_radius
		points.push_back(center + offset)
	return points

func _draw_rope_surface(start_circle: PackedVector3Array, end_circle: PackedVector3Array) -> void:
	for index: int in rope_section_resolution:
		var next_index: int = (index + 1) % rope_section_resolution
		var start_a: Vector3 = start_circle[index]
		var start_b: Vector3 = start_circle[next_index]
		var end_a: Vector3 = end_circle[index]
		var end_b: Vector3 = end_circle[next_index]
		var start_normal_a: Vector3 = (start_a - smoothed_start_position).normalized()
		var start_normal_b: Vector3 = (start_b - smoothed_start_position).normalized()
		var end_normal_a: Vector3 = (end_a - smoothed_end_position).normalized()
		var end_normal_b: Vector3 = (end_b - smoothed_end_position).normalized()
		rope_mesh.surface_set_normal(start_normal_a)
		rope_mesh.surface_add_vertex(start_a)
		rope_mesh.surface_set_normal(end_normal_a)
		rope_mesh.surface_add_vertex(end_a)
		rope_mesh.surface_set_normal(end_normal_b)
		rope_mesh.surface_add_vertex(end_b)
		rope_mesh.surface_set_normal(start_normal_a)
		rope_mesh.surface_add_vertex(start_a)
		rope_mesh.surface_set_normal(end_normal_b)
		rope_mesh.surface_add_vertex(end_b)
		rope_mesh.surface_set_normal(start_normal_b)
		rope_mesh.surface_add_vertex(start_b)

func _draw_rope_cap(circle: PackedVector3Array, normal: Vector3) -> void:
	var center: Vector3 = smoothed_start_position
	if normal.dot(smoothed_end_position - smoothed_start_position) > 0.0:
		center = smoothed_end_position
	for index: int in rope_section_resolution:
		var next_index: int = (index + 1) % rope_section_resolution
		rope_mesh.surface_set_normal(normal)
		rope_mesh.surface_add_vertex(center)
		rope_mesh.surface_add_vertex(circle[next_index])
		rope_mesh.surface_add_vertex(circle[index])
