class_name EnvKit
extends RefCounted


static func attach(root: Node3D) -> void:
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
	env.ambient_light_color = Color(0.45, 0.47, 0.55)
	env.ambient_light_energy = 0.58
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.12
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
	env.adjustment_contrast = 1.03
	world.environment = env
	root.add_child(world)
	var moonlight := DirectionalLight3D.new()
	moonlight.rotation_degrees = Vector3(-48, -18, 0)
	moonlight.light_color = Color(0.72, 0.82, 1.0)
	moonlight.light_energy = 0.78
	moonlight.shadow_enabled = true
	root.add_child(moonlight)
	var city_fill := DirectionalLight3D.new()
	city_fill.rotation_degrees = Vector3(-12, 140, 0)
	city_fill.light_color = Color(1.0, 0.62, 0.28)
	city_fill.light_energy = 0.36
	root.add_child(city_fill)
