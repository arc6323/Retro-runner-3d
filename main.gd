extends Node3D

var player: Node3D
var camera: Camera3D
var hud: Label
var message: Label

var speed: float = 10.0
var lane: int = 1
var lanes: Array[float] = [-3.5, 0.0, 3.5]

var distance: float = 0.0
var score: int = 0
var coins: int = 0

var world_objects: Array[Node3D] = []

var touch_start: Vector2 = Vector2.ZERO


func _ready() -> void:
	_build_environment()
	_build_road()
	_build_city()
	_build_ramps()
	_build_player()
	_build_camera()
	_build_ui()


func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


func make_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var object := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	mesh.size = size
	object.mesh = mesh
	object.position = pos
	object.material_override = material

	parent.add_child(object)

	return object


func make_cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var object := MeshInstance3D.new()
	var mesh := CylinderMesh.new()

	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height

	object.mesh = mesh
	object.position = pos
	object.material_override = material

	parent.add_child(object)

	return object


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("050914")

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("7182a8")
	environment.ambient_light_energy = 1.0

	world.environment = environment
	add_child(world)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, -25.0, 0.0)
	light.light_energy = 1.8

	add_child(light)


func _build_road() -> void:
	var road_material := make_material(Color("252832"))
	var line_material := make_material(Color("ddd7a8"))

	for i in range(24):
		var segment := Node3D.new()

		segment.position = Vector3(
			0.0,
			0.0,
			-float(i) * 24.0
		)

		add_child(segment)
		world_objects.append(segment)

		make_box(
			segment,
			Vector3(11.0, 0.5, 24.0),
			Vector3(0.0, -0.3, 0.0),
			road_material
		)

		make_box(
			segment,
			Vector3(0.12, 0.03, 24.0),
			Vector3(-1.75, 0.0, 0.0),
			line_material
		)

		make_box(
			segment,
			Vector3(0.12, 0.03, 24.0),
			Vector3(1.75, 0.0, 0.0),
			line_material
		)


func _build_city() -> void:
	var building := make_material(Color("172238"))
	var windows := make_material(Color("b92331"))

	for i in range(30):
		var z := -20.0 - float(i) * 18.0

		var left := Node3D.new()
		left.position = Vector3(-10.0, 0.0, z)
		add_child(left)
		world_objects.append(left)

		var lh := 5.0 + float((i * 3) % 8)

		make_box(
			left,
			Vector3(5.0, lh, 10.0),
			Vector3(0.0, lh / 2.0, 0.0),
			building
		)

		make_box(
			left,
			Vector3(0.2, 1.0, 5.0),
			Vector3(0.0, lh * 0.55, -5.1),
			windows
		)

		var right := Node3D.new()
		right.position = Vector3(10.0, 0.0, z - 8.0)
		add_child(right)
		world_objects.append(right)

		var rh := 4.0 + float((i * 5) % 10)

		make_box(
			right,
			Vector3(5.0, rh, 10.0),
			Vector3(0.0, rh / 2.0, 0.0),
			building
		)

		make_box(
			right,
			Vector3(0.2, 1.0, 5.0),
			Vector3(0.0, rh * 0.55, -5.1),
			windows
		)


func _build_ramps() -> void:
	_make_ramp(Vector3(0.0, 0.0, -65.0))
	_make_ramp(Vector3(0.0, 0.0, -155.0))


func _make_ramp(pos: Vector3) -> void:
	var ramp := Node3D.new()
	ramp.position = pos

	add_child(ramp)
	world_objects.append(ramp)

	var red := make_material(Color("c52231"))
	var dark := make_material(Color("30333c"))

	var top := make_box(
		ramp,
		Vector3(8.5, 1.0, 7.0),
		Vector3(0.0, 1.8, 0.0),
		red
	)

	top.rotation_degrees.x = -20.0

	make_box(
		ramp,
		Vector3(8.5, 3.0, 2.0),
		Vector3(0.0, 0.8, 3.0),
		dark
	)
	
	var sign := make_box(
		ramp,
		Vector3(5.0, 1.2, 0.25),
		Vector3(0.0, 3.8, -2.5),
		red
	)

	sign.rotation_degrees.x = -20.0


func _build_player() -> void:
	player = Node3D.new()
	player.position = Vector3(0.0, 0.0, 4.0)

	add_child(player)

	var visual := Node3D.new()
	player.add_child(visual)

	var red := make_material(Color("d52230"))
	var dark := make_material(Color("11151c"))
	var grey := make_material(Color("777777"))
	var white := make_material(Color("eee5cf"))

	# Квадроцикл
	make_box(
		visual,
		Vector3(2.5, 0.65, 3.0),
		Vector3(0.0, 0.8, 0.0),
		red
	)

	make_box(
		visual,
		Vector3(1.3, 0.35, 1.4),
		Vector3(0.0, 1.3, 0.2),
		dark
	)

	# Колёса
	for x in [-1.35, 1.35]:
		for z in [-1.0, 1.0]:
			var wheel := make_cylinder(
				visual,
				0.55,
				0.45,
				Vector3(x, 0.5, z),
				dark
			)

			wheel.rotation_degrees.z = 90.0

	# Волк — тело
	make_box(
		visual,
		Vector3(0.8, 1.2, 0.65),
		Vector3(0.0, 2.1, 0.1),
		grey
	)

	# Голова
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()

	head_mesh.radius = 0.48
	head_mesh.height = 0.96

	head.mesh = head_mesh
	head.position = Vector3(0.0, 3.0, -0.1)
	head.material_override = grey

	visual.add_child(head)

	# Уши
	make_box(
		visual,
		Vector3(0.25, 0.5, 0.25),
		Vector3(-0.27, 3.5, -0.1),
		grey
	)

	make_box(
		visual,
		Vector3(0.25, 0.5, 0.25),
		Vector3(0.27, 3.5, -0.1),
		grey
	)

	# Глаза
	make_box(
		visual,
		Vector3(0.12, 0.12, 0.08),
		Vector3(-0.18, 3.08, -0.52),
		white
	)

	make_box(
		visual,
		Vector3(0.12, 0.12, 0.08),
		Vector3(0.18, 3.08, -0.52),
		white
	)


func _build_camera() -> void:
	camera = Camera3D.new()

	camera.position = Vector3(0.0, 6.0, 12.0)

	add_child(camera)

	camera.look_at(
		Vector3(0.0, 1.5, -10.0),
		Vector3.UP
	)

	camera.current = true


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	hud = Label.new()

	hud.position = Vector2(30.0, 25.0)

	hud.add_theme_font_size_override(
		"font_size",
		30
	)

	layer.add_child(hud)

	message = Label.new()

	message.position = Vector2(0.0, 155.0)
	message.size = Vector2(720.0, 80.0)

	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	message.add_theme_font_size_override(
		"font_size",
		30
	)

	message.text = "КРАСНЫЙ КВАДРО"

	layer.add_child(message)

	_update_hud()


func _update_hud() -> void:
	if hud == null:
		return

	hud.text = "🏁 %04d m    🪙 %03d    ⭐ %05d" % [
		int(distance),
		coins,
		score
	]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
		else:
			if touch_start != Vector2.ZERO:
				var delta := event.position - touch_start

				if abs(delta.x) > 80.0:
					if delta.x > 0.0:
						change_lane(1)
					else:
						change_lane(-1)

				touch_start = Vector2.ZERO

	elif event is InputEventKey:
		if not event.pressed:
			return

		if event.keycode == KEY_LEFT:
			change_lane(-1)

		if event.keycode == KEY_RIGHT:
			change_lane(1)


func change_lane(direction: int) -> void:
	lane += direction
	lane = clamp(lane, 0, 2)


func _process(delta: float) -> void:
	distance += speed * delta
	score += int(speed * delta * 2.0)

	if player != null:
		player.position.x = lerp(
			player.position.x,
			lanes[lane],
			min(1.0, delta * 8.0)
		)

	# Движение мира навстречу игроку
	for object in world_objects:
		if object == null:
			continue

		object.position.z += speed * delta

		if object.position.z > 25.0:
			object.position.z -= 24.0 * 20.0

	_update_hud()

	if camera != null and player != null:
		camera.position.x = lerp(
			camera.position.x,
			player.position.x * 0.3,
			min(1.0, delta * 3.0)
		)

		camera.look_at(
			Vector3(
				player.position.x * 0.15,
				1.5,
				-10.0
			),
			Vector3.UP
		)
