extends CharacterBody3D
class_name PlayerCore

# ───── MOVEMENT SETTINGS ─────
@export var walk_speed := 5.0
@export var sprint_speed := 9.0
@export var crouch_speed := 3.0

@export var acceleration := 20.0
@export var air_acceleration := 6.0
@export var friction := 10.0
@export var air_friction := 1.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# ───── CROUCH SETTINGS ─────
@export var standing_height := 2.0
@export var crouching_height := 1.0
@export var crouch_speed_lerp := 7.0

@onready var collider: CollisionShape3D = $Collider
@onready var head: Node3D = $Head
@onready var visual_root: Node3D = $Head/VisualRoot

var current_height := 2.0
var crouched := false

# ───── CAMERA & FACING ─────
var yaw := 0.0  # horizontal rotation (left/right)
var pitch := 0.0 # up/down
@export var mouse_sensitivity := 0.08

# ───── VISUAL SCENE ─────
@export var visual_scene: PackedScene
var visual: Node3D = null

func _ready():
	if visual_scene:
		visual = visual_scene.instantiate()
		visual_root.add_child(visual)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -89, 89)

		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotation_degrees.x = pitch


func _process(delta):
	handle_crouch(delta)


func _physics_process(delta):
	var input_dir = get_input_direction()

	var target_speed = get_target_speed()
	var accel = acceleration if is_on_floor() else air_acceleration
	var fric = friction if is_on_floor() else air_friction

	var desired_velocity = (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * target_speed

	# Apply friction (Jolt-friendly)
	velocity.x = lerp(velocity.x, desired_velocity.x, accel * delta)
	velocity.z = lerp(velocity.z, desired_velocity.z, accel * delta)

	if input_dir.length() == 0:
		velocity.x = lerp(velocity.x, 0.0, fric * delta)
		velocity.z = lerp(velocity.z, 0.0, fric * delta)

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = 4.5  # modify as needed

	move_and_slide()

func get_input_direction() -> Vector2:
	var dir = Vector2.ZERO

	if Input.is_action_pressed("move_forward"):
		dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		dir.y += 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1

	return dir.normalized()

func get_target_speed() -> float:
	if crouched:
		return crouch_speed
	if Input.is_action_pressed("sprint"):
		return sprint_speed
	return walk_speed

func handle_crouch(delta):
	var target_height = crouching_height if Input.is_action_pressed("crouch") else standing_height
	crouched = Input.is_action_pressed("crouch")

	# Smooth collider scaling
	current_height = lerp(current_height, target_height, crouch_speed_lerp * delta)

	var shape = collider.shape
	if shape is CapsuleShape3D:
		shape.height = current_height

	# Lower the head / visuals smoothly
	var head_target_y = current_height * 0.5
	head.position.y = lerp(head.position.y, head_target_y, crouch_speed_lerp * delta)
