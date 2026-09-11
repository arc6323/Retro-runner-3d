class_name MeshKit
extends RefCounted


static func material(color: Color, emission: Color = Color(0, 0, 0, 1)) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	mat.metallic = 0.08
	if emission.r > 0.0 or emission.g > 0.0 or emission.b > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 2.2
	return mat


static func box(size: Vector3, position: Vector3, color: Color, emission: Color = Color(0, 0, 0, 1)) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = position
	node.material_override = material(color, emission)
	return node


static func cylinder(radius: float, height: float, position: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.position = position
	node.material_override = material(color)
	return node
