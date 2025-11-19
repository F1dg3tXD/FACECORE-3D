extends Node
class_name GameManager

@export var player_scene: PackedScene

# Explicitly typed, but start with an empty Array
var spawn_points: Array[SpawnPoint] = []

func _ready():
	get_spawn_points()
	if player_scene and spawn_points.size() > 0:
		spawn_player()
	else:
		push_error("No player scene or spawn points found!")

func get_spawn_points():
	spawn_points.clear()

	var nodes: Array[Node] = get_tree().get_nodes_in_group("spawn_points")

	# Filter only actual SpawnPoint objects
	for n in nodes:
		if n is SpawnPoint:
			spawn_points.append(n)

func spawn_player():
	var player := player_scene.instantiate()

	var sp: SpawnPoint = spawn_points[randi() % spawn_points.size()]
	player.global_transform = sp.global_transform

	get_tree().current_scene.add_child(player)
