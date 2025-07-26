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
	set_transparency_recursive(self, alpha)

func set_buildable(buildable: bool):
	is_buildable = buildable
	# Update appearance when buildable state changes
	var alpha = 0.5  # Assume we're in preview mode
	set_transparency_recursive(self, alpha)

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
# This function is no longer used - collision detection is handled by build_node.gd
func _setup_collision_area():
	# We're keeping this function as a stub in case we need to revert
	print("BuildableObject: _setup_collision_area is deprecated")

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

# Signal handlers are no longer used - collision detection is handled by build_node.gd
func _on_body_entered(body: Node3D):
	print("BuildableObject: _on_body_entered is deprecated")

# Signal handlers are no longer used - collision detection is handled by build_node.gd
func _on_body_exited(body: Node3D):
	print("BuildableObject: _on_body_exited is deprecated")
