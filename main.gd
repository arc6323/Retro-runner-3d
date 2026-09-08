extends Node3D

var speed: float = 16.0
var lane: int = 1
var lane_x: Array[float] = [-4.0, 0.0, 4.0]

var distance: float = 0.0
var score: int = 0
var coins: int = 0

var quad: Node3D
var quad_visual: Node3D
var camera: Camera3D

var road_segments: Array[Node3D] = []
var city_objects: Array[Node3D] = []

var hud: Label
var message: Label

var touch_start: Vector2 = Vector2.ZERO


func _ready() -> void:
	randomize()

	_build_environment()
	_build_road()
	_build_city()
	_build_quad()
	_build_camera()
	_build_ui()


func make_material(color: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color

	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy

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
	environment.ambient_light_color = Color("7888aa")
	environment.ambient_light_energy = 1.0

	world.environment = environment
	add_child(world)

	var light := DirectionalLight3D.new()

	light.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	light.light_energy = 1.5

	add_child(light)


func _build_road() -> void:
	var road_material := make_material(Color("242832"))
	var line_material := make_material(Color("d7d0a8"))

	for i in range(20):
		var segment := Node3D.new()

		segment.position = Vector3(0.0, 0.0, -i * 24.0)

		add_child(segment)
		road_segments.append(segment)

		make_box(
			segment,
			Vector3(14.0, 0.6, 24.0),
			Vector3(0.0, -0.35, 0.0),
			road_material
		)

		make_box(
			segment,
			Vector3(0.12, 0.04, 24.0),
			Vector3(-2.0, 0.0, 0.0),
			line_material
		)

		make_box(
			segment,
			Vector3(0.12, 0.04, 24.0),
			Vector3(2.0, 0.0, 0.0),
			line_material
		)


func _build_city() -> void:
	var building_material := make_material(Color("172238"))
	var red_material := make_material(
		Color("a51e2a"),
		Color("a51e2a"),
		0.4
	)

	for i in range(24):
		var left := Node3D.new()
		var right := Node3D.new()

		var z := -float(i) * 20.0 - 10.0

		left.position = Vector3(-12.0, 0.0, z)
		right.position = Vector3(12.0, 0.0, z)

		add_child(left)
		add_child(right)

		var left_height := 4.0 + float((i * 7) % 9)
		var right_height := 5.0 + float((i * 5) % 8)

		make_box(
			left,
			Vector3(5.0, left_height, 7.0),
			Vector3(0.0, left_height / 2.0, 0.0),
			building_material
		)

		make_box(
			right,
			Vector3(5.0, right_height, 7.0),
			Vector3(0.0, right_height / 2.0, 0.0),
			building_material
		)

		make_box(
			left,
			Vector3(0.2, 1.2, 4.0),
			Vector3(0.0, left_height * 0.55, -3.55),
			red_material
		)

		make_box(
			right,
			Vector3(0.2, 1.2, 4.0),
			Vector3(0.0, right_height * 0.55, -3.55),
			red_material
		)


func _build_quad() -> void:
	quad = Node3D.new()
	quad.position = Vector3(0.0, 0.0, 4.0)

	add_child(quad)

	quad_visual = Node3D.new()
	quad.add_child(quad_visual)

	var red := make_material(Color("c51f2b"))
	var dark := make_material(Color("11141b"))
	var white := make_material(Color("e9e0cc"))

	# корпус квадроцикла
	make_box(
		quad_visual,
		Vector3(2.8, 0.6, 3.2),
		Vector3(0.0, 1.0, 0.0),
		red
	)

	# сиденье
	make_box(
		quad_visual,
		Vector3(1.5, 0.4, 1.5),
		Vector3(0.0, 1.45, 0.2),
		dark
	)

	# четыре колеса
	for x in [-1.55, 1.55]:
		for z in [-1.0, 1.0]:
			var wheel := make_cylinder(
				quad_visual,
				0.58,
				0.45,
				Vector3(x, 0.55, z),
				dark
			)

			wheel.rotation_degrees.z = 90.0

	# туловище волка
	make_box(
		quad_visual,
		Vector3(0.9, 1.3, 0.65),
		Vector3(0.0, 2.15, 0.1),
		dark
	)

	# голова
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()

	sphere.radius = 0.48
	sphere.height = 0.96

	head.mesh = sphere
	head.position = Vector3(0.0, 3.0, -0.05)
	head.material_override = make_material(Color("777373"))

	quad_visual.add_child(head)

	# уши
	make_box(
		quad_visual,
		Vector3(0.22, 0.45, 0.22),
		Vector3(-0.25, 3.5, -0.05),
		head.material_override
	)

	make_box(
		quad_visual,
		Vector3(0.22, 0.45, 0.22),
		Vector3(0.25, 3.5, -0.05),
		head.material_override
	)

	# красная фара
	make_box(
		quad_visual,
		Vector3(0.7, 0.18, 0.12),
		Vector3(0.0, 1.35, -1.65),
		white
	)


func _build_camera() -> void:
	camera = Camera3D.new()

	camera.position = Vector3(0.0, 6.0, 12.0)

	add_child(camera)

	camera.look_at(
		Vector3(0.0, 1.5, 0.0),
		Vector3.UP
	)

	camera.current = true


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	hud = Label.new()

	hud.position = Vector2(28.0, 25.0)

	hud.add_theme_font_size_override(
		"font_size",
		30
	)

	layer.add_child(hud)

	message = Label.new()

	message.position = Vector2(0.0, 150.0)
	message.size = Vector2(720.0, 100.0)

	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	message.add_theme_font_size_override(
		"font_size",
		34
	)

	message.text = "RED QUADRO"

	layer.add_child(message)

	_update_hud()


func _update_hud() -> void:
	if hud == null:
		return

	hud.text = "🏁 %04dm    🪙 %03d    ⭐ %05d" % [
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

		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			change_lane(-1)

		if event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			change_lane(1)


func change_lane(direction: int) -> void:
	lane += direction
	lane = clamp(lane, 0, 2)


func _process(delta: float) -> void:
	distance += speed * delta
	score += int(speed * delta * 2.0)

	# движение квадроцикла между полосами
	if quad != null:
		quad.position.x = lerp(
			quad.position.x,
			lane_x[lane],
			min(1.0, delta * 10.0)
		)

	# движение дороги
	for segment in road_segments:
		if segment == null:
			continue

		segment.position.z += speed * delta

		if segment.position.z > 30.0:
			segment.position.z -= 20.0 * 24.0

	_update_hud()

	# лёгкое следование камеры
	if camera != null and quad != null:
		camera.position.x = lerp(
			camera.position.x,
			quad.position.x * 0.35,
			min(1.0, delta * 3.0)
		)

		camera.look_at(
			Vector3(quad.position.x * 0.15, 1.5, 0.0),
			Vector3.UP
		)
