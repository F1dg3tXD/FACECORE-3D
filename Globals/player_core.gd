extends CharacterBody3D
class_name PlayerCore

@export var move_speed := 5.0
@export var acceleration := 12.0
@export var mouse_sensitivity := 0.15
@export var visual_scene: PackedScene

@onready var head: Node3D = $Head
@onready var visual_root: Node3D = $VisualRoot
@onready var ground: RayCast3D = $ground
@onready var aim: RayCast3D = $Head/aim
@onready var weapon_socket: Node3D = $"Head/weapon socket"

var visual: Node3D
var gravity := ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity_vec := Vector3.ZERO
var look_x := 0.0
var look_y := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if visual_scene:
		visual = visual_scene.instantiate()
		visual_root.add_child(visual)

func _physics_process(delta):
	player_movement(delta)
	move_and_slide()

func player_movement(delta):
	# -------- Movement Input --------
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# -------- Horizontal Movement --------
	var target_velocity = direction * move_speed
	velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)

	# -------- Gravity --------
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

func _input(event):
	if event is InputEventMouseMotion:
		look_x -= event.relative.y * mouse_sensitivity
		look_y -= event.relative.x * mouse_sensitivity

		look_x = clamp(look_x, -75, 75)

		head.rotation_degrees.x = look_x
		rotation_degrees.y = look_y
