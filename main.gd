extends Node3D

var player: Node3D
var camera: Camera3D
var hud: Label

var speed: float = 10.0
var lane: int = 1
var distance: float = 0.0
var score: int = 0

var city: Array[Node3D] = []

var touch_start: Vector2 = Vector2.ZERO


func _ready() -> void:
	_build_world()
	_build_road()
	_build_city()
	_build_player()
	_build_camera()
	_build_ui()


func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


func make_box(
	parent: Node3D,
	size: Vector3,
	pos: Vector3,
	material: Material
) -> MeshInstance3D:
	var object := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	mesh.size = size
	object.mesh = mesh
	object.position = pos
	object.material_override = material

	parent.add_child(object)

	return object


func _build_world() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.015, 0.025, 0.06)

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.8)
	environment.ambient_light_energy = 1.0

	world.environment = environment
	add_child(world)

	var light := DirectionalLight3D.new()

	light.rotation_degrees = Vector3(-50, -25, 0)
	light.light_energy = 1.8

	add_child(light)


func _build_road() -> void:
	var road_material := make_material(
		Color(0.12, 0.13, 0.16)
	)

	var line_material := make_material(
		Color(0.8, 0.8, 0.65)
	)

	var road := MeshInstance3D.new()
	var road_mesh := BoxMesh.new()

	road_mesh.size = Vector3(11, 0.5, 250)
	road.mesh = road_mesh
	road.position = Vector3(0, -0.3, -110)
	road.material_override = road_material

	add_child(road)

	var line_left := MeshInstance3D.new()
	var line_mesh_left := BoxMesh.new()

	line_mesh_left.size = Vector3(0.12, 0.03, 250)
	line_left.mesh = line_mesh_left
	line_left.position = Vector3(-1.75, 0, -110)
	line_left.material_override = line_material

	add_child(line_left)

	var line_right := MeshInstance3D.new()
	var line_mesh_right := BoxMesh.new()

	line_mesh_right.size = Vector3(0.12, 0.03, 250)
	line_right.mesh = line_mesh_right
	line_right.position = Vector3(1.75, 0, -110)
	line_right.material_override = line_material

	add_child(line_right)


func _build_city() -> void:
	var building_material := make_material(
		Color(0.07, 0.10, 0.16)
	)

	var building_dark := make_material(
		Color(0.05, 0.07, 0.12)
	)

	var red_material := make_material(
		Color(0.65, 0.03, 0.08)
	)

	var window_material := make_material(
		Color(0.75, 0.25, 0.10)
	)

	for i in range(18):
		var z := -15.0 - float(i) * 14.0

		# ЛЕВОЕ ЗДАНИЕ
		var left := Node3D.new()
		left.position = Vector3(-10.0, 0.0, z)
		add_child(left)
		city.append(left)

		var left_height := 5.0 + float((i * 3) % 7)

		make_box(
			left,
			Vector3(5.0, left_height, 9.0),
			Vector3(0, left_height / 2.0, 0),
			building_material
		)

		# Красная вертикальная полоса
		make_box(
			left,
			Vector3(0.25, left_height * 0.8, 0.3),
			Vector3(2.55, left_height / 2.0, -4.65),
			red_material
		)

		# Окна
		for row in range(3):
			make_box(
				left,
				Vector3(2.5, 0.35, 0.12),
				Vector3(0, 1.5 + float(row) * 2.0, -4.56),
				window_material
			)

		# ПРАВОЕ ЗДАНИЕ
		var right := Node3D.new()
		right.position = Vector3(10.0, 0.0, z - 7.0)
		add_child(right)
		city.append(right)

		var right_height := 6.0 + float((i * 5) % 6)

		make_box(
			right,
			Vector3(5.0, right_height, 9.0),
			Vector3(0, right_height / 2.0, 0),
			building_dark
		)

		make_box(
			right,
			Vector3(0.25, right_height * 0.8, 0.3),
			Vector3(-2.55, right_height / 2.0, -4.65),
			red_material
		)

		for row in range(3):
			make_box(
				right,
				Vector3(2.5, 0.35, 0.12),
				Vector3(0, 1.5 + float(row) * 2.0, -4.56),
				window_material
			)


func _build_player() -> void:
	player = Node3D.new()
	player.position = Vector3(0, 0, 4)

	add_child(player)

	# КОРПУС
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()

	body_mesh.size = Vector3(2.5, 0.7, 3.0)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.8, 0)

	var red := make_material(
		Color(0.9, 0.03, 0.04)
	)

	body.material_override = red
	player.add_child(body)

	# СИДЕНЬЕ
	var seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()

	seat_mesh.size = Vector3(1.3, 0.35, 1.3)
	seat.mesh = seat_mesh
	seat.position = Vector3(0, 1.35, 0)

	var dark := make_material(
		Color(0.03, 0.03, 0.04)
	)

	seat.material_override = dark
	player.add_child(seat)

	# СПИНКА
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()

	back_mesh.size = Vector3(1.5, 0.7, 0.25)
	back.mesh = back_mesh
	back.position = Vector3(0, 1.7, 0.65)
	back.material_override = dark

	player.add_child(back)

	# РУЛЬ
	var handle := MeshInstance3D.new()
	var handle_mesh := BoxMesh.new()

	handle_mesh.size = Vector3(1.8, 0.15, 0.15)
	handle.mesh = handle_mesh
	handle.position = Vector3(0, 1.65, -0.9)

	var metal := make_material(
		Color(0.45, 0.45, 0.48)
	)

	handle.material_override = metal
	player.add_child(handle)


func _build_camera() -> void:
	camera = Camera3D.new()

	camera.position = Vector3(0, 5.5, 11)

	add_child(camera)

	camera.look_at(
		Vector3(0, 1, -8),
		Vector3.UP
	)

	camera.current = true


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	hud = Label.new()

	hud.position = Vector2(30, 30)

	hud.add_theme_font_size_override(
		"font_size",
		30
	)

	canvas.add_child(hud)

	_update_hud()


func _update_hud() -> void:
	if hud == null:
		return

	hud.text = "RED QUADRO\n\nDISTANCE: %04d m\nSCORE: %05d" % [
		int(distance),
		score
	]


func _process(delta: float) -> void:
	distance += speed * delta
	score += int(speed * delta)

	# Квадроцикл
	if player != null:
		var target_x := 0.0

		if lane == 0:
			target_x = -3.5
		elif lane == 1:
			target_x = 0.0
		else:
			target_x = 3.5

		player.position.x = lerp(
			player.position.x,
			target_x,
			min(1.0, delta * 8.0)
		)

	# ГОРОД ДВИЖЕТСЯ НАВСТРЕЧУ
	for building in city:
		if building == null:
			continue

		building.position.z += speed * delta

		if building.position.z > 20.0:
			building.position.z -= 18.0 * 14.0

	_update_hud()

	# Камера немного следует за игроком
	if camera != null and player != null:
		camera.position.x = lerp(
			camera.position.x,
			player.position.x * 0.25,
			min(1.0, delta * 3.0)
		)

		camera.look_at(
			Vector3(
				player.position.x * 0.15,
				1.0,
				-8.0
			),
			Vector3.UP
		)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
		else:
			if touch_start != Vector2.ZERO:
				var difference := event.position - touch_start

				if abs(difference.x) > 80.0:
					if difference.x > 0.0:
						lane = min(2, lane + 1)
					else:
						lane = max(0, lane - 1)

				touch_start = Vector2.ZERO

	elif event is InputEventKey:
		if not event.pressed:
			return

		if event.keycode == KEY_LEFT:
			lane = max(0, lane - 1)

		elif event.keycode == KEY_RIGHT:
			lane = min(2, lane + 1)
