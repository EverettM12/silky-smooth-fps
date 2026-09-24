extends CMPlayerSpawnerBase
class_name CMPlayerSpawner

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")

var spawn_root: Node3D

func spawn_player(cm_player: CMPlayer) -> Node:
	if spawn_root == null:
		return null
	var player_parent: Node3D = spawn_root.get_node_or_null("Players") as Node3D
	if player_parent == null:
		player_parent = Node3D.new()
		player_parent.name = "Players"
		spawn_root.add_child(player_parent)

	var player: Player = null
	var existing_player: Player = spawn_root.get_node_or_null("Player") as Player
	if cm_player.is_local and existing_player != null and not existing_player.networked:
		player = existing_player
		player.reparent(player_parent, false)
	else:
		player = PLAYER_SCENE.instantiate() as Player
		player_parent.add_child(player)

	player.name = "Player_%d" % cm_player.player_id
	var authority_id: int = cm_player.net_peer.peer_id
	player.configure_networked(cm_player.is_local, cm_player.player_id, authority_id)
	player.global_position = _get_spawn_position(cm_player.player_id)
	return player

func despawn_player(cm_player: CMPlayer) -> void:
	if cm_player.player_node is Player and is_instance_valid(cm_player.player_node):
		cm_player.player_node.queue_free()

func _get_spawn_position(player_id: int) -> Vector3:
	var start_pos: Node3D = spawn_root.get_node_or_null("Start Pos") as Node3D
	var position: Vector3 = Vector3.ZERO
	if start_pos != null:
		position = start_pos.global_position
	position += Vector3(float(player_id - 1) * 2.5, 0.0, 0.0)
	return position
