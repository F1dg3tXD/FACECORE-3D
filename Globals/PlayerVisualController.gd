extends Node3D
class_name PlayerVisualController

# All available character shapes the player can use
@export var shape_variants: Array[PackedScene]

# Selected index (can be loaded from player profile)
@export var selected_shape: int = 0

# Color customizations
@export var primary_color: Color = Color(1, 1, 1)
@export var secondary_color: Color = Color(1, 1, 1)

# Internal reference
var current_shape: Node3D
var anim_tree: AnimationTree
var anim_player: AnimationPlayer
var face: Node

func _ready():
	load_shape(selected_shape)
	apply_colors()

func load_shape(index: int):
	if index < 0 or index >= shape_variants.size():
		push_error("Invalid shape index: %s" % index)
		return

	# Remove old visual if it exists
	if current_shape and current_shape.is_inside_tree():
		current_shape.queue_free()

	# Instantiate new shape
	current_shape = shape_variants[index].instantiate()
	add_child(current_shape)

	# Cache important nodes if they exist
	anim_tree = current_shape.get_node_or_null("AnimationTree")
	anim_player = current_shape.get_node_or_null("AnimationPlayer")
	face = current_shape.get_node_or_null("Face")

func apply_colors():
	if not current_shape:
		return

	for child in current_shape.get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			if mesh_instance.mesh == null:
				continue

			var surface_count := mesh_instance.mesh.get_surface_count()

			for s in range(surface_count):
				var mat = mesh_instance.get_active_material(s)

				# Ensure we have a ShaderMaterial
				if mat is StandardMaterial3D:
					# Convert it to ShaderMaterial automatically
					var shader_mat := ShaderMaterial.new()
					shader_mat.shader = load("res://shaders/color_mask.gdshader")

					# Copy textures from StandardMaterial if present
					if mat.albedo_texture:
						shader_mat.set("shader_parameter/albedo_tex", mat.albedo_texture)
					if mat.detail_albedo:
						shader_mat.set("shader_parameter/albedo_tex", mat.detail_albedo)

					# You MUST assign a mask texture in advance!
					# Give a useful error if missing
					if not mat.albedo_texture:
						push_warning("Mesh %s has no mask texture assigned!" % mesh_instance.name)

					mesh_instance.set_surface_override_material(s, shader_mat)
					mat = shader_mat

				# Now set shader parameters
				if mat is ShaderMaterial:
					mat.set("shader_parameter/primary_color", primary_color)
					mat.set("shader_parameter/secondary_color", secondary_color)
