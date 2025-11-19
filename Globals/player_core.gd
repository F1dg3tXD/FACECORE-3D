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

var current_height := 2.0
var crouched := false

# ───── CAMERA & FACING ─────
var yaw := 0.0  # horizontal rotation (left/right)
var pitch := 0.0 # up/down
@export var mouse_sensitivity := 0.08
@onready var fps_cam: Camera3D = $Head/Camera3D
@onready var tps_cam: Camera3D = $ThirdPersonRig/SpringArm3D/TPSCamera
var is_tps := false
var cam_blend_time := 0.25

# ───── VISUAL SCENE ─────
@export var visual_controller_scene: PackedScene # assigned to PlayerVisualController
@onready var visual_root: Node3D = $Head/VisualRoot
var visual_controller: PlayerVisualController

func _ready():
	setup_visual()
	fps_cam.cull_mask &= ~(1 << 1) # turns off layer 2
	fps_cam.current = true
	tps_cam.current = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -89, 89)

		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotation_degrees.x = pitch
		
	if event.is_action_pressed("switch_camera"):
		toggle_camera()
		
func toggle_camera():
	is_tps = !is_tps
	
	if is_tps:
		fps_cam.current = false
		tps_cam.current = true   # blend happens automatically
	else:
		tps_cam.current = false
		fps_cam.current = true

#func _process(delta):
	#handle_crouch(delta)
	#pass

func _physics_process(delta):
	# Update crouch state
	crouched = Input.is_action_pressed("crouch")

	handle_crouch(delta)
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
	# Target height
	var target_height := crouching_height if crouched else standing_height
	
	# Capsule shape reference
	var capsule := collider.shape as CapsuleShape3D

	# Smooth collider height
	capsule.height = lerp(capsule.height, target_height, delta * crouch_speed_lerp)

	# Keep the bottom on the ground
	collider.position.y = capsule.height / 2.0
	
	# Move the visual body to stay aligned with physics capsule height
	visual_root.position.y = capsule.height * 0

	# Smooth camera position
	var target_head_y: float = capsule.height * 0.85
	var pos := head.position
	pos.y = lerp(pos.y, target_head_y, delta * crouch_speed_lerp)
	head.position = pos


func setup_visual():
	if visual_controller_scene:
		visual_controller = visual_controller_scene.instantiate()
		visual_root.add_child(visual_controller)

		# Fix: Reset its local transform so it matches visual_root perfectly
		visual_controller.position = Vector3.ZERO
		visual_controller.rotation = Vector3.ZERO
		visual_controller.scale = Vector3.ONE

		visual_controller.owner = self
