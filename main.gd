extends Node3D

var camera: Camera3D

func _ready():
	# Фон
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.04, 0.10)
	environment.environment = env
	add_child(environment)

	# Свет
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 2.0
	add_child(light)

	# Камера
	camera = Camera3D.new()
	camera.position = Vector3(0, 3, 8)
	add_child(camera)
	camera.look_at(Vector3(0, 1, 0), Vector3.UP)
	camera.current = true

	# Большой красный куб перед камерой
	var cube := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3, 3, 3)
	cube.mesh = mesh
	cube.position = Vector3(0, 1, 0)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.03, 0.05)
	cube.material_override = material

	add_child(cube)

	# Текст поверх всего
	var layer := CanvasLayer.new()
	add_child(layer)

	var label := Label.new()
	label.text = "RED QUADRO\n\n3D TEST OK"
	label.position = Vector2(40, 80)
	label.add_theme_font_size_override("font_size", 48)
	layer.add_child(label)

	print("RED QUADRO TEST STARTED")
