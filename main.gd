extends Node3D

# КРАСНЫЙ КВАДРО — Retro Runner
# Первый рабочий Android-прототип

var speed: float = 16.0
var lane: int = 1
var lane_x: Array[float] = [-4.0, 0.0, 4.0]

var distance: float = 0.0
var score: int = 0
var coins: int = 0

var airborne: bool = false
var air_time: float = 0.0
var jump_duration: float = 1.15
var current_trick: int = 0

var trick_names: Array[String] = [
	"САЛЬТО ВПЕРЁД",
	"САЛЬТО НАЗАД",
	"БОЧКА",
	"СПИРАЛЬ",
	"ЭКСТРЕМАЛЬНЫЙ ТРЮК"
]

var quad: Node3D
var quad_visual: Node3D
var camera: Camera3D

var road_segments: Array[Node3D] = []

var hud: Label
var trick_label: Label


func _ready() -> void:
	randomize()

	_build_world()
	_build_quad()
	_build_camera()
	_build_ui()

	print("RED QUADRO: GAME STARTED")


# ---------------------------------------------------------
# MATERIALS
# ---------------------------------------------------------

func make_material(color: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()

	material.albedo_color = color

	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy

	return material


# ---------------------------------------------------------
# BOX
# ---------------------------------------------------------

func make_box(
	parent: Node3D,
	size: Vector3,
	pos: Vector3,
	material: Material
) -> MeshInstance3D:

	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	mesh.size = size

	node.mesh = mesh
	node.position = pos
	node.material_override = material

	parent.add_child(node)

	return node


# ---------------------------------------------------------
# CYLINDER
# ---------------------------------------------------------

func make_cylinder(
	parent: Node3D,
	radius: float,
	height: float,
	pos: Vector3,
	material: Material
) -> MeshInstance3D:

	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()

	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height

	node.mesh = mesh
	node.position = pos
	node.material_override = material

	parent.add_child(node)

	return node


# ---------------------------------------------------------
# WORLD
# ---------------------------------------------------------

func _build_world() -> void:

	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("071020")

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8b9bc4")
	environment.ambient_light_energy = 1.0

	environment_node.environment = environment

	add_child(environment_node)


	# Свет

	var sun := DirectionalLight3D.new()

	sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	sun.light_energy = 1.5

	add_child(sun)


	# -----------------------------------------------------
	# ROAD
	# -----------------------------------------------------

	for i in range(18):

		var segment := Node3D.new()

		segment.position = Vector3(
			0.0,
			0.0,
			-i * 24.0
		)

		add_child(segment)

		var road_material := make_material(
			Color("242834")
		)

		make_box(
			segment,
			Vector3(14.0, 0.6, 24.0),
			Vector3(0.0, -0.35, 0.0),
			road_material
		)


		# Разметка

		var line_material := make_material(
			Color("d5d5b0")
		)

		for x in [-2.0, 2.0]:

			make_box(
				segment,
				Vector3(0.12, 0.04, 24.0),
				Vector3(x, 0.02, 0.0),
				line_material
			)


		# Футуристические пилоны

		var red_material := make_material(
			Color("a41e2a")
		)

		var white_material := make_material(
			Color("d9d7ca")
		)

		for side in [-1.0, 1.0]:

			make_box(
				segment,
				Vector3(0.5, 5.0, 0.5),
				Vector3(side * 8.0, 2.5, 0.0),
				red_material
			)

			make_box(
				segment,
				Vector3(0.5, 0.5, 4.0),
				Vector3(side * 8.0, 5.0, 0.0),
				white_material
			)


		road_segments.append(segment)


	# Рампы

	make_ramp(Vector3(0.0, 0.0, -55.0))
	make_ramp(Vector3(0.0, 0.0, -145.0))


# ---------------------------------------------------------
# RAMP
# ---------------------------------------------------------

func make_ramp(pos: Vector3) -> void:

	var ramp := Node3D.new()

	ramp.position = pos

	add_child(ramp)


	var ramp_material := make_material(
		Color("c52b37")
	)

	var ramp_mesh := BoxMesh.new()

	ramp_mesh.size = Vector3(
		12.0,
		1.2,
		10.0
	)

	var ramp_node := MeshInstance3D.new()

	ramp_node.mesh = ramp_mesh

	ramp_node.position = Vector3(
		0.0,
		2.4,
		0.0
	)

	ramp_node.rotation_degrees.x = -20.0

	ramp_node.material_override = ramp_material

	ramp.add_child(ramp_node)


	var support_material := make_material(
		Color("333743")
	)

	make_box(
		ramp,
		Vector3(12.0, 4.0, 2.0),
		Vector3(0.0, 0.0, 4.0),
		support_material
	)


# ---------------------------------------------------------
# QUAD
# ---------------------------------------------------------

func _build_quad() -> void:

	quad = Node3D.new()

	quad.position = Vector3(
		0.0,
		0.0,
		4.0
	)

	add_child(quad)


	quad_visual = Node3D.new()

	quad.add_child(quad_visual)


	var red := make_material(
		Color("c51f2b")
	)

	var dark := make_material(
		Color("11131a")
	)

	var white := make_material(
		Color("e9e2d2")
	)


	# Корпус квадроцикла

	make_box(
		quad_visual,
		Vector3(2.8, 0.6, 3.2),
		Vector3(0.0, 1.0, 0.0),
		red
	)


	make_box(
		quad_visual,
		Vector3(1.5, 0.4, 1.6),
		Vector3(0.0, 1.5, -0.2),
		white
	)


	# Колёса

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


	# Волк

	make_box(
		quad_visual,
		Vector3(0.9, 1.3, 0.65),
		Vector3(0.0, 2.15, 0.1),
		dark
	)


	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()

	sphere.radius = 0.48
	sphere.height = 0.96

	head.mesh = sphere

	head.position = Vector3(
		0.0,
		3.0,
		-0.05
	)

	head.material_override = make_material(
		Color("6e6a6a")
	)

	quad_visual.add_child(head)


	# Уши

	for x in [-0.25, 0.25]:

		var ear := MeshInstance3D.new()
		var ear_mesh := BoxMesh.new()

		ear_mesh.size = Vector3(
			0.22,
			0.45,
			0.22
		)

		ear.mesh = ear_mesh

		ear.position = Vector3(
			x,
			3.5,
			-0.05
		)

		ear.material_override = head.material_override

		quad_visual.add_child(ear)


# ---------------------------------------------------------
# CAMERA
# ---------------------------------------------------------

func _build_camera() -> void:

	camera = Camera3D.new()

	# Камера смотрит на квадроцикл,
	# а не вверх.

	camera.position = Vector3(
		0.0,
		6.0,
		12.0
	)

	add_child(camera)

	camera.look_at(
		Vector3(0.0, 1.5, 0.0),
		Vector3.UP
	)

	camera.current = true


# ---------------------------------------------------------
# UI
# ---------------------------------------------------------

func _build_ui() -> void:

	var layer := CanvasLayer.new()

	add_child(layer)


	hud = Label.new()

	hud.position = Vector2(
		24.0,
		24.0
	)

	hud.add_theme_font_size_override(
		"font_size",
		28
	)

	hud.text = "КРАСНЫЙ КВАДРО"

	layer.add_child(hud)


	trick_label = Label.new()

	trick_label.position = Vector2(
		0.0,
		180.0
	)

	trick_label.size = Vector2(
		720.0,
		80.0
	)

	trick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	trick_label.add_theme_font_size_override(
		"font_size",
		32
	)

	layer.add_child(trick_label)


	_update_hud()


# ---------------------------------------------------------
# HUD
# ---------------------------------------------------------

func _update_hud() -> void:

	if hud == null:
		return

	hud.text = "🏁 %04dm    🪙 %03d    ⭐ %05d" % [
		int(distance),
		coins,
		score
	]


# ---------------------------------------------------------
# TOUCH
# ---------------------------------------------------------

var touch_start := Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventScreenTouch:

		if event.pressed:

			touch_start = event.position

		else:

			if touch_start != Vector2.ZERO:

				_screen_touch(event.position)

				touch_start = Vector2.ZERO


	elif event is InputEventKey:

		if not event.pressed:
			return

		if event.keycode == KEY_A:
			change_lane(-1)

		elif event.keycode == KEY_LEFT:
			change_lane(-1)

		elif event.keycode == KEY_D:
			change_lane(1)

		elif event.keycode == KEY_RIGHT:
			change_lane(1)

		elif event.keycode == KEY_SPACE:

			if airborne:
				do_extra_trick()


func _screen_touch(position: Vector2) -> void:

	var delta := position - touch_start

	if abs(delta.x) > 80.0:

		if delta.x > 0.0:
			change_lane(1)
		else:
			change_lane(-1)

	elif abs(delta.y) > 80.0:

		if airborne:
			do_extra_trick()


# ---------------------------------------------------------
# LANES
# ---------------------------------------------------------

func change_lane(direction: int) -> void:

	lane += direction

	lane = clamp(
		lane,
		0,
		2
	)


# ---------------------------------------------------------
# TRICK
# ---------------------------------------------------------

func do_extra_trick() -> void:

	if not airborne:
		return

	score += 150

	trick_label.text = "ТРЮК +150"


# ---------------------------------------------------------
# GAME LOOP
# ---------------------------------------------------------

func _process(delta: float) -> void:

	if quad == null:
		return


	distance += speed * delta

	score += int(
		speed * delta * 2.0
	)


	# Переезд между полосами

	quad.position.x = lerp(
		quad.position.x,
		lane_x[lane],
		min(1.0, 10.0 * delta)
	)


	# Движение дороги

	for segment in road_segments:

		segment.position.z += speed * delta

		if segment.position.z > 30.0:

			segment.position.z -= 18.0 * 24.0


	_update_hud()


	# Прыжок

	if airborne:

		update_air(delta)

	else:

		# Возвращаем квадроцикл
		# в нормальное положение.

		quad_visual.rotation = quad_visual.rotation.slerp(
			Vector3.ZERO,
			min(1.0, delta * 8.0)
		)


	# Камера следует за полосой

	camera.position.x = lerp(
		camera.position.x,
		quad.position.x * 0.35,
		min(1.0, delta * 3.0)
	)

	camera.look_at(
		Vector3(
			quad.position.x * 0.15,
			1.5,
			0.0
		),
		Vector3.UP
	)


	# Проверка рампы

	check_ramp()


# ---------------------------------------------------------
# RAMP CHECK
# ---------------------------------------------------------

func check_ramp() -> void:

	if airborne:
		return


	# Первый прыжок через некоторое время.

	var cycle := fmod(
		distance,
		90.0
	)

	if cycle > 53.0 and cycle < 56.0:

		start_jump()


# ---------------------------------------------------------
# START JUMP
# ---------------------------------------------------------

func start_jump() -> void:

	if airborne:
		return

	airborne = true
	air_time = 0.0

	current_trick = randi_range(
		0,
		4
	)

	trick_label.text = trick_names[current_trick]


# ---------------------------------------------------------
# AIR
# ---------------------------------------------------------

func update_air(delta: float) -> void:

	air_time += delta

	var t := clamp(
		air_time / jump_duration,
		0.0,
		1.0
	)


	# Высота

	quad.position.y = sin(
		t * PI
	) * 7.0


	# Трюк

	var angle := t * TAU


	if current_trick == 0:

		quad_visual.rotation.x = angle


	elif current_trick == 1:

		quad_visual.rotation.x = -angle


	elif current_trick == 2:

		quad_visual.rotation.z = angle


	elif current_trick == 3:

		quad_visual.rotation.x = angle
		quad_visual.rotation.z = angle * 0.7


	else:

		quad_visual.rotation.x = angle * 1.6
		quad_visual.rotation.z = angle * 1.2


	# Приземление

	if t >= 1.0:

		airborne = false

	quad.position.y = 0.0

	score += 250

	trick_label.text = "ИДЕАЛЬНОЕ ПРИЗЕМЛЕНИЕ +250"

	quad_visual.rotation = Vector3.ZERO
