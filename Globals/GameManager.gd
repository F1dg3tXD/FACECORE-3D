extends Node
class_name GameManager

@export var player_scene: PackedScene

var spawn_points: Array[SpawnPoint] = []
var player_instance: Node3D


func _ready():
	get_spawn_points()

	if player_scene and spawn_points.size() > 0:
		spawn_player() # no argument
	else:
		push_error("No player scene or spawn points found!")


func get_spawn_points():
	spawn_points.clear()
	var nodes: Array[Node] = get_tree().get_nodes_in_group("spawn_points")

	for n in nodes:
		if n is SpawnPoint:
			spawn_points.append(n)


# 🎯 If no spawn point given, use a random one
func spawn_player(spawn_point: Node3D = null):
	if spawn_point == null:
		spawn_point = spawn_points.pick_random()

	player_instance = player_scene.instantiate()
	call_deferred("_finish_spawn", spawn_point)


func _finish_spawn(spawn_point: Node3D):
	get_tree().current_scene.add_child(player_instance)

	player_instance.global_position = spawn_point.global_position
	player_instance.global_rotation = spawn_point.global_rotation
