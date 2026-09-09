extends Node3D

var player: Node3D
var camera: Camera3D
var hud: Label

var speed: float = 10.0
var lane: int = 1
var distance: float = 0.0
var score: int = 0

var touch_start: Vector2 = Vector2.ZERO


func _ready() -> void:
	# WORLD
	var world := WorldEnvironment.new()
	var env := Environment.new()

	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.025, 0.06)

	world.environment = env
	add_child(world)

	# LIGHT
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -20, 0)
	light.light_energy = 2.0
	add_child(light)

	# ROAD
	var road := MeshInstance3D.new()
	var road_mesh := BoxMesh.new()

	road_mesh.size = Vector3(11, 0.5, 100)
	road.mesh = road_mesh
	road.position = Vector3(0, -0.3, -40)

	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.12, 0.13, 0.16)

	road.material_override = road_mat
	add_child(road)

	# ROAD LINES
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.8, 0.8, 0.65)

	var line1 := MeshInstance3D.new()
	var line_mesh1 := BoxMesh.new()

	line_mesh1.size = Vector3(0.12, 0.03, 100)
	line1.mesh = line_mesh1
	line1.position = Vector3(-1.75, 0, -40)
	line1.material_override = line_mat

	add_child(line1)

	var line2 := MeshInstance3D.new()
	var line_mesh2 := BoxMesh.new()

	line_mesh2.size = Vector3(0.12, 0.03, 100)
	line2.mesh = line_mesh2
	line2.position = Vector3(1.75, 0, -40)
	line2.material_override = line_mat

	add_child(line2)

	# ONE LEFT BUILDING
	var building_mat := StandardMaterial3D.new()
	building_mat.albedo_color = Color(0.07, 0.10, 0.17)

	var left_building := MeshInstance3D.new()
	var left_mesh := BoxMesh.new()

	left_mesh.size = Vector3(5, 12, 8)
	left_building.mesh = left_mesh
	left_building.position = Vector3(-9, 6, -25)
	left_building.material_override = building_mat

	add_child(left_building)

	# ONE RIGHT BUILDING
	var right_building := MeshInstance3D.new()
	var right_mesh := BoxMesh.new()

	right_mesh.size = Vector3(5, 9, 8)
	right_building.mesh = right_mesh
	right_building.position = Vector3(9, 4.5, -35)
	right_building.material_override = building_mat

	add_child(right_building)

	# PLAYER
	player = Node3D.new()
	player.position = Vector3(0, 0, 4)

	add_child(player)

	# RED QUAD
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()

	body_mesh.size = Vector3(2.5, 0.7, 3)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.8, 0)

	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.9, 0.03, 0.04)

	body.material_override = red
	player.add_child(body)

	# SEAT
	var seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()

	seat_mesh.size = Vector3(1.3, 0.35, 1.3)
	seat.mesh = seat_mesh
	seat.position = Vector3(0, 1.35, 0)

	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.03, 0.03, 0.04)

	seat.material_override = dark
	player.add_child(seat)

	# CAMERA
	camera = Camera3D.new()
	camera.position = Vector3(0, 5.5, 11)

	add_child(camera)

	camera.look_at(
		Vector3(0, 1, 0),
		Vector3.UP
	)

	camera.current = true

	# HUD
	var canvas := CanvasLayer.new()
	add_child(canvas)

	hud = Label.new()
	hud.position = Vector2(30, 30)
	hud.add_theme_font_size_override("font_size", 32)

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

	if player != null:
		var target_x := 0.0

		if lane == 0:
			target_x = -3.5
		elif lane == 2:
			target_x = 3.5

		player.position.x = lerp(
			player.position.x,
			target_x,
			min(1.0, delta * 8.0)
		)

	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
		else:
			if touch_start != Vector2.ZERO:
				var difference := event.position - touch_start

				if abs(difference.x) > 80:
					if difference.x > 0:
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
