# buildable_object.gd
# Base class for all objects that can be placed in build mode
extends Node3D
class_name BuildableObject

func set_preview_mode(is_preview: bool):
	var alpha = 1.0 if not is_preview else 0.5
	set_transparency_recursive(self, alpha)

func set_transparency_recursive(node: Node, alpha: float):
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		
		# Create or modify material for transparency
		if mesh_instance.material_override == null:
			if mesh_instance.get_surface_override_material(0):
				mesh_instance.material_override = mesh_instance.get_surface_override_material(0).duplicate()
			else:
				mesh_instance.material_override = StandardMaterial3D.new()
		
		var material = mesh_instance.material_override as StandardMaterial3D
		material.albedo_color.a = alpha
		material.flags_transparent = true
	
	# Recursively apply to all children
	for child in node.get_children():
		set_transparency_recursive(child, alpha)
