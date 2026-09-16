@tool
extends EditorPlugin

## Make Local
##
## Adds a small 3D editor toolbar button that applies the same basic operation
## as Godot's built-in Scene Tree > Make Local action to every selected scene
## instance that belongs to the currently edited scene.

var make_local_button: Button
var remove_static_bodies_button: Button
var remove_static_bodies_dialog: ConfirmationDialog
var pending_static_bodies: Array[Node] = []


func _enter_tree() -> void:
	make_local_button = Button.new()
	make_local_button.text = "Make Local"
	make_local_button.tooltip_text = (
		"Make all selected scene instances local to the current scene. "
		+ "Non-scene selections are skipped."
	)
	make_local_button.pressed.connect(_on_make_local_pressed)

	add_control_to_container(
		EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,
		make_local_button
	)

	remove_static_bodies_button = Button.new()
	remove_static_bodies_button.text = "Remove Static Bodies"
	remove_static_bodies_button.tooltip_text = (
		"Remove all StaticBody3D descendants from the selected nodes. "
		+ "Use with care: this removes collision/physics bodies."
	)
	remove_static_bodies_button.pressed.connect(_on_remove_static_bodies_pressed)

	add_control_to_container(
		EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,
		remove_static_bodies_button
	)

	remove_static_bodies_dialog = ConfirmationDialog.new()
	remove_static_bodies_dialog.title = "Remove Static Bodies"
	remove_static_bodies_dialog.ok_button_text = "Remove Static Bodies"
	remove_static_bodies_dialog.cancel_button_text = "Cancel"
	remove_static_bodies_dialog.confirmed.connect(_on_remove_static_bodies_confirmed)
	add_child(remove_static_bodies_dialog)


func _exit_tree() -> void:
	if is_instance_valid(make_local_button):
		remove_control_from_container(
			EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,
			make_local_button
		)
		make_local_button.queue_free()
		make_local_button = null

	if is_instance_valid(remove_static_bodies_button):
		remove_control_from_container(
			EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,
			remove_static_bodies_button
		)
		remove_static_bodies_button.queue_free()
		remove_static_bodies_button = null

	if is_instance_valid(remove_static_bodies_dialog):
		remove_static_bodies_dialog.queue_free()
		remove_static_bodies_dialog = null

	pending_static_bodies.clear()


func _on_remove_static_bodies_pressed() -> void:
	var edited_root := get_editor_interface().get_edited_scene_root()

	if edited_root == null:
		push_warning("Remove Static Bodies: no scene is currently open.")
		return

	var selected_nodes: Array[Node] = []
	for node in get_editor_interface().get_selection().get_selected_nodes():
		if is_instance_valid(node):
			selected_nodes.append(node)

	if selected_nodes.is_empty():
		push_warning("Remove Static Bodies: select one or more nodes first.")
		return

	var top_level_selection := _filter_top_level_selection(selected_nodes)
	var static_bodies := _collect_static_body_descendants(top_level_selection)

	if static_bodies.is_empty():
		push_warning(
			"Remove Static Bodies: no StaticBody3D descendants were found in the selection."
		)
		return

	pending_static_bodies.clear()
	pending_static_bodies.append_array(static_bodies)

	remove_static_bodies_dialog.dialog_text = (
		"This will remove %d StaticBody3D node(s) from the selected hierarchy.\n\n"
		+ "StaticBody3D nodes are commonly used for collision and physics. "
		+ "Removing them may make parts of your scene non-collidable or change physics behavior.\n\n"
		+ "The operation can be undone with Ctrl+Z.\n\n"
		+ "Are you sure you want to continue?"
	) % pending_static_bodies.size()

	remove_static_bodies_dialog.popup_centered()


func _on_remove_static_bodies_confirmed() -> void:
	if pending_static_bodies.is_empty():
		return

	var bodies: Array[Node] = []
	for node in pending_static_bodies:
		if is_instance_valid(node):
			bodies.append(node)

	pending_static_bodies.clear()

	if bodies.is_empty():
		push_warning("Remove Static Bodies: the selected StaticBody3D nodes no longer exist.")
		return

	# Remove deepest nodes first so a nested StaticBody3D is never processed twice.
	bodies.sort_custom(
		func(a: Node, b: Node) -> bool:
			return a.get_path().get_name_count() > b.get_path().get_name_count()
	)

	var removal_entries: Array[Dictionary] = []
	for body in bodies:
		var parent := body.get_parent()
		if parent == null:
			continue

		removal_entries.append({
			"node": body,
			"parent": parent,
			"index": body.get_index(),
		})

	if removal_entries.is_empty():
		return

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Remove StaticBody3D Nodes")

	for entry in removal_entries:
		var body: Node = entry["node"]
		var parent: Node = entry["parent"]
		var index: int = entry["index"]

		undo_redo.add_do_method(
			self,
			"_remove_static_body_do",
			body,
			parent
		)
		undo_redo.add_undo_method(
			self,
			"_remove_static_body_undo",
			body,
			parent,
			index
		)
		undo_redo.add_do_reference(body)
		undo_redo.add_undo_reference(body)

	undo_redo.add_do_method(self, "_refresh_editor")
	undo_redo.add_undo_method(self, "_refresh_editor")
	undo_redo.commit_action()

	print(
		"Remove Static Bodies: removed %d StaticBody3D node(s)."
		% removal_entries.size()
	)


func _remove_static_body_do(body: Node, expected_parent: Node) -> void:
	if not is_instance_valid(body) or not is_instance_valid(expected_parent):
		return

	if body.get_parent() == expected_parent:
		expected_parent.remove_child(body)


func _remove_static_body_undo(body: Node, parent: Node, index: int) -> void:
	if not is_instance_valid(body) or not is_instance_valid(parent):
		return

	if body.get_parent() != null:
		body.get_parent().remove_child(body)

	parent.add_child(body)
	parent.move_child(body, min(index, parent.get_child_count() - 1))


func _collect_static_body_descendants(nodes: Array[Node]) -> Array[Node]:
	var result: Array[Node] = []

	for node in nodes:
		if not is_instance_valid(node):
			continue

		for child in node.get_children():
			_collect_static_bodies_recursive(child, result)

	return _filter_top_level_selection(result)


func _collect_static_bodies_recursive(current: Node, result: Array[Node]) -> void:
	if not is_instance_valid(current):
		return

	if current is StaticBody3D:
		if not result.has(current):
			result.append(current)
		return

	for child in current.get_children():
		_collect_static_bodies_recursive(child, result)


func _on_make_local_pressed() -> void:
	var editor_interface := get_editor_interface()
	var edited_root := editor_interface.get_edited_scene_root()

	if edited_root == null:
		push_warning("Make Local: no scene is currently open.")
		return

	var selected_nodes: Array[Node] = []
	for node in editor_interface.get_selection().get_selected_nodes():
		if is_instance_valid(node):
			selected_nodes.append(node)

	if selected_nodes.is_empty():
		push_warning("Make Local: select one or more scene instances first.")
		return

	# Match SceneTreeDock behavior by only operating on top-level selected nodes.
	var top_level_selection := _filter_top_level_selection(selected_nodes)
	var instances_to_localize: Array[Node] = []
	var skipped_not_scene := 0
	var skipped_foreign := 0

	for node in top_level_selection:
		if node == edited_root:
			skipped_not_scene += 1
			continue

		var scene_path := node.get_scene_file_path()
		if scene_path.is_empty():
			skipped_not_scene += 1
			continue

		# A normal top-level instance is owned by the edited scene root.
		# Do not reach into a foreign/locked instance accidentally.
		if node.owner != edited_root:
			skipped_foreign += 1
			continue

		instances_to_localize.append(node)

	if instances_to_localize.is_empty():
		push_warning(
			"Make Local: no valid scene instances were selected."
		)
		if skipped_not_scene > 0 or skipped_foreign > 0:
			print(
				"Make Local: skipped %d non-scene nodes and %d foreign/locked nodes."
				% [skipped_not_scene, skipped_foreign]
			)
		return

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Make Local")

	var localized_count := 0

	for node in instances_to_localize:
		var original_scene_path := node.get_scene_file_path()
		var owned_by_instance: Array[Node] = _collect_nodes_owned_by(node, node)
		var unique_names_to_restore: Array[Node] = []

		# The operation Godot itself performs is to clear the instance's
		# scene_file_path and move nodes owned by the instance to the edited
		# scene root.
		undo_redo.add_do_method(
			self,
			"_make_local_do",
			node,
			edited_root,
			owned_by_instance,
			unique_names_to_restore
		)

		undo_redo.add_undo_method(
			self,
			"_make_local_undo",
			node,
			original_scene_path,
			owned_by_instance,
			unique_names_to_restore
		)

		undo_redo.add_do_reference(node)
		localized_count += 1

	undo_redo.add_do_method(self, "_refresh_editor")
	undo_redo.add_undo_method(self, "_refresh_editor")
	undo_redo.commit_action()

	print(
		"Make Local: localized %d scene instance(s)."
		% localized_count
	)

	if skipped_not_scene > 0:
		print(
			"Make Local: skipped %d selected node(s) that are not scene instances."
			% skipped_not_scene
		)

	if skipped_foreign > 0:
		print(
			"Make Local: skipped %d foreign/locked scene instance(s)."
			% skipped_foreign
		)


func _make_local_do(
	node: Node,
	edited_root: Node,
	owned_by_instance: Array[Node],
	unique_names_to_restore: Array[Node]
) -> void:
	if not is_instance_valid(node) or not is_instance_valid(edited_root):
		return

	if node.get_scene_file_path().is_empty():
		return

	# Keep unique-name nodes from temporarily colliding under the new owner.
	for child in owned_by_instance:
		if not is_instance_valid(child):
			continue

		if child.is_unique_name_in_owner():
			var unique_path := NodePath("%" + str(child.name))
			var existing := edited_root.get_node_or_null(unique_path)
			if existing != null and existing != child:
				child.set_unique_name_in_owner(false)
				if not unique_names_to_restore.has(child):
					unique_names_to_restore.append(child)

	node.set_scene_file_path("")

	for child in owned_by_instance:
		if is_instance_valid(child):
			child.owner = edited_root


func _make_local_undo(
	node: Node,
	original_scene_path: String,
	owned_by_instance: Array[Node],
	unique_names_to_restore: Array[Node]
) -> void:
	if not is_instance_valid(node):
		return

	# Restore ownership first, then restore the scene instance link.
	for child in owned_by_instance:
		if is_instance_valid(child):
			child.owner = node

	for child in unique_names_to_restore:
		if is_instance_valid(child):
			child.set_unique_name_in_owner(true)

	node.set_scene_file_path(original_scene_path)


func _collect_nodes_owned_by(
	instance_root: Node,
	current: Node
) -> Array[Node]:
	var result: Array[Node] = []

	if current != instance_root and current.owner == instance_root:
		result.append(current)

	for child in current.get_children():
		result.append_array(_collect_nodes_owned_by(instance_root, child))

	return result


func _filter_top_level_selection(nodes: Array[Node]) -> Array[Node]:
	var result: Array[Node] = []

	for node in nodes:
		if not is_instance_valid(node):
			continue

		var has_selected_ancestor := false
		var parent := node.get_parent()

		while parent != null:
			if nodes.has(parent):
				has_selected_ancestor = true
				break
			parent = parent.get_parent()

		if not has_selected_ancestor:
			result.append(node)

	return result


func _refresh_editor() -> void:
	var selection := get_editor_interface().get_selection()
	selection.changed.emit()

	var edited_root := get_editor_interface().get_edited_scene_root()
	if edited_root != null:
		edited_root.notify_property_list_changed()
