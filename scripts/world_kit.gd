class_name WorldKit
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


static func attach_environment(root: Node3D) -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.016, 0.03, 0.055)
	sky_mat.sky_horizon_color = Color(0.42, 0.24, 0.12)
	sky_mat.sky_curve = 0.14
	sky_mat.ground_bottom_color = Color(0.03, 0.03, 0.035)
	sky_mat.ground_horizon_color = Color(0.18, 0.11, 0.07)
	sky_mat.sun_angle_max = 8.0
	sky_mat.sun_curve = 0.08
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.48)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.08
	env.fog_enabled = true
	env.fog_light_color = Color(0.18, 0.16, 0.14)
	env.fog_density = 0.012
	env.fog_aerial_perspective = 0.55
	env.fog_sky_affect = 0.45
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.85
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.05
	world.environment = env
	root.add_child(world)

	var moonlight := DirectionalLight3D.new()
	moonlight.rotation_degrees = Vector3(-48, -18, 0)
	moonlight.light_color = Color(0.72, 0.82, 1.0)
	moonlight.light_energy = 1.15
	moonlight.shadow_enabled = true
	root.add_child(moonlight)

	var city_fill := DirectionalLight3D.new()
	city_fill.rotation_degrees = Vector3(-12, 140, 0)
	city_fill.light_color = Color(1.0, 0.62, 0.28)
	city_fill.light_energy = 0.28
	root.add_child(city_fill)
