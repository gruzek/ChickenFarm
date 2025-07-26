# buildable_object.gd
# Base class for all objects that can be placed in build mode
extends Node3D
class_name BuildableObject

var is_buildable = true
var in_preview_mode = false
var collision_area: Area3D = null

func _ready():
	# Add all buildable objects to a group for collision detection
	add_to_group("buildable_objects")
	
	# Create collision area for build validation if we're in preview mode
	if in_preview_mode:
		_setup_collision_area()

func set_preview_mode(is_preview: bool):
	in_preview_mode = is_preview
	var alpha = 1.0 if not is_preview else 0.5
	#set_transparency_recursive(self, alpha)
	
	# Setup collision area for preview mode
	if is_preview:
		_setup_collision_area()

func set_buildable(buildable: bool):
	is_buildable = buildable
	# Update appearance when buildable state changes
	var alpha = 0.5  # Assume we're in preview mode
	#set_transparency_recursive(self, alpha)

func set_transparency_recursive(node: Node, alpha: float):
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		
		# Create or modify material for transparency
		# Always create a unique material to avoid shared material issues
		if mesh_instance.material_override == null:
			if mesh_instance.get_surface_override_material(0):
				mesh_instance.material_override = mesh_instance.get_surface_override_material(0).duplicate()
			else:
				# Check if there's a base material to duplicate
				var base_material = mesh_instance.get_surface_override_material(0)
				if base_material == null and mesh_instance.mesh:
					# Try to get material from the mesh itself
					base_material = mesh_instance.mesh.surface_get_material(0)
				
				if base_material:
					mesh_instance.material_override = base_material.duplicate()
				else:
					mesh_instance.material_override = StandardMaterial3D.new()
		else:
			# If material_override exists but might be shared, duplicate it
			if not mesh_instance.material_override.has_meta("_buildable_unique"):
				mesh_instance.material_override = mesh_instance.material_override.duplicate()
				mesh_instance.material_override.set_meta("_buildable_unique", true)
		
		var material = mesh_instance.material_override as StandardMaterial3D
		material.albedo_color.a = alpha
		material.flags_transparent = true
		
		# Apply red tint if unbuildable
		if not is_buildable:
			material.albedo_color.r = 1.0  # Full red
			material.albedo_color.g = 0.3  # Reduced green
			material.albedo_color.b = 0.3  # Reduced blue
		else:
			# Reset to normal color (white tint)
			material.albedo_color.r = 1.0
			material.albedo_color.g = 1.0
			material.albedo_color.b = 1.0
	
	# Recursively apply to all children
	for child in node.get_children():
		set_transparency_recursive(child, alpha)

# Helper function to get the first collision shape for physics queries
func get_collision_shape() -> Shape3D:
	return find_collision_shape_recursive(self)

func find_collision_shape_recursive(node: Node) -> Shape3D:
	if node is CollisionShape3D:
		var collision_shape = node as CollisionShape3D
		if collision_shape.shape:
			return collision_shape.shape
	
	# Recursively check children
	for child in node.get_children():
		var shape = find_collision_shape_recursive(child)
		if shape:
			return shape
	
	return null

# Create a collision area for build validation
func _setup_collision_area():
	# Remove existing area if any
	if collision_area:
		collision_area.queue_free()
	
	# Create new area
	collision_area = Area3D.new()
	collision_area.name = "BuildValidationArea"
	add_child(collision_area)
	
	# Find and duplicate all collision shapes from the static body
	var shapes = _find_all_collision_shapes(self)
	
	for shape_data in shapes:
		var original_shape = shape_data["shape"]
		var original_transform = shape_data["transform"]
		
		# Create new collision shape for the area
		var new_shape = CollisionShape3D.new()
		new_shape.shape = original_shape.shape.duplicate()
		new_shape.transform = original_transform
		collision_area.add_child(new_shape)
	
	# Set collision properties
	collision_area.collision_layer = 0  # Don't collide with anything
	collision_area.collision_mask = 2   # Only detect layer 2 (other buildings)
	
	# Connect signals
	collision_area.body_entered.connect(_on_body_entered)
	collision_area.body_exited.connect(_on_body_exited)
	

# Find all collision shapes in the node tree
func _find_all_collision_shapes(node: Node) -> Array:
	var shapes = []
	
	if node is CollisionShape3D:
		var parent = node.get_parent()
		if parent is StaticBody3D:
			shapes.append({"shape": node, "transform": node.global_transform})
	
	# Recursively check children
	for child in node.get_children():
		shapes.append_array(_find_all_collision_shapes(child))
	
	return shapes

# Signal handlers for collision detection
func _on_body_entered(body: Node3D):
	set_buildable(false)

# Signal handlers for collision detection
func _on_body_exited(body: Node3D):
	# Only set buildable to true if there are no more collisions
	if collision_area and collision_area.get_overlapping_bodies().size() == 0:
		set_buildable(true)
