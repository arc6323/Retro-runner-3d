extends Node3D

var player: Node3D
var camera: Camera3D
var hud: Label

var speed: float = 10.0
var lane: int = 1
var lanes: Array[float] = [-3.5, 0.0, 3.5]

var distance: float = 0.0
var score: int = 0


func _ready() -> void:
	# Сначала создаём HUD.
	# Даже если ниже что-то пойдёт не так,
	# этот текст должен появиться.
	var canvas := CanvasLayer.new()
	add_child(canvas)

	hud = Label.new()
	hud.position = Vector2(30, 30)
	hud.add_theme_font_size_override("font_size", 32)
	hud.text = "RED QUADRO\nЗАПУСК..."
	canvas.add_child(hud)

	# Фон.
	var world := WorldEnvironment.new()
	var env := Environment.new()

	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.025, 0.06)

	world.environment = env
	add_child(world)

	# Свет.
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -20, 0)
	light.light_energy = 2.0
	add_child(light)

	# Дорога.
	var road := MeshInstance3D.new()
	var road_mesh := BoxMesh.new()

	road_mesh.size = Vector3(11, 0.5, 100)
	road.mesh = road_mesh
	road.position = Vector3(0, -0.3, -40)

	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.12, 0.13, 0.16)

	road.material_override = road_mat
	add_child(road)

	# Разметка.
	for x in [-1.75, 1.75]:
		var line := MeshInstance3D.new()
		var line_mesh := BoxMesh.new()

		line_mesh.size = Vector3(0.12, 0.03, 100)
		line.mesh = line_mesh
		line.position = Vector3(x, 0.0, -40)

		var line_mat := StandardMaterial3D.new()
		line_mat.albedo_color = Color(0.8, 0.8, 0.65)

		line.material_override = line_mat
		add_child(line)

	# Квадроцикл.
	player = Node3D.new()
	player.position = Vector3(0, 0, 4)
	add_child(player)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()

	body_mesh.size = Vector3(2.5, 0.7, 3.0)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.8, 0)

	var red_mat := StandardMaterial3D.new()
	red_mat.albedo_color = Color(0.9, 0.03, 0.04)

	body.material_override = red_mat
	player.add_child(body)

	# Сиденье.
	var seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()

	seat_mesh.size = Vector3(1.3, 0.35, 1.3)
	seat.mesh = seat_mesh
	seat.position = Vector3(0, 1.35, 0)

	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.03, 0.03, 0.04)

	seat.material_override = dark_mat
	player.add_child(seat)

	# Камера.
	camera = Camera3D.new()
	camera.position = Vector3(0, 5.5, 11)

	add_child(camera)

	camera.look_at(
		Vector3(0, 1, 0),
		Vector3.UP
	)

	camera.current = true

	hud.text = "RED QUADRO\n\n🏁 0000 m    ⭐ 00000\n\nСВАЙП ВЛЕВО / ВПРАВО"


func _process(delta: float) -> void:
	distance += speed * delta
	score += int(speed * delta)

	if player != null:
		player.position.x = lerp(
			player.position.x,
			lanes[lane],
			min(1.0, delta * 8.0)
		)

	if hud != null:
		hud.text = "RED QUADRO\n\n🏁 %04d m    ⭐ %05d\n\nСВАЙП ВЛЕВО / ВПРАВО" % [
			int(distance),
			score
		]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			return

		if event.position.x < 360:
			lane = max(0, lane - 1)
		else:
			lane = min(2, lane + 1)

	elif event is InputEventKey:
		if not event.pressed:
			return

		if event.keycode == KEY_LEFT:
			lane = max(0, lane - 1)

		if event.keycode == KEY_RIGHT:
			lane = min(2, lane + 1)
