extends Node3D

var player: Node3D
var camera: Camera3D
var hud: Label

var buildings: Array[Node3D] = []
var ramp: Node3D

var speed: float = 10.0
var lane: int = 1
var distance: float = 0.0
var score: int = 0

var touch_start: Vector2 = Vector2.ZERO

# Прыжок
var jumping: bool = false
var jump_velocity: float = 0.0
var jump_gravity: float = 22.0

# Защита от повторного срабатывания
var ramp_used: bool = false

# Один полный кувырок
var trick_rotation: float = 0.0


func _ready() -> void:

    # =========================
    # HUD
    # =========================

    var canvas := CanvasLayer.new()
    add_child(canvas)

    hud = Label.new()
    hud.position = Vector2(30, 30)
    hud.add_theme_font_size_override("font_size", 32)
    hud.text = "RED QUADRO\nBOOT: 1"
    canvas.add_child(hud)


    # =========================
    # WORLD
    # =========================

    var world := WorldEnvironment.new()
    var env := Environment.new()

    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.015, 0.025, 0.06)

    world.environment = env
    add_child(world)

    hud.text = "RED QUADRO\nBOOT: 2"


    # =========================
    # LIGHT
    # =========================

    var light := DirectionalLight3D.new()

    light.rotation_degrees = Vector3(-50, -20, 0)
    light.light_energy = 2.0

    add_child(light)


    # =========================
    # ROAD
    # =========================

    var road := MeshInstance3D.new()
    var road_mesh := BoxMesh.new()

    road_mesh.size = Vector3(11, 0.5, 100)
    road.mesh = road_mesh
    road.position = Vector3(0, -0.3, -40)

    var road_material := StandardMaterial3D.new()
    road_material.albedo_color = Color(0.12, 0.13, 0.16)

    road.material_override = road_material

    add_child(road)


    # =========================
    # ROAD LINES
    # =========================

    var line_material := StandardMaterial3D.new()
    line_material.albedo_color = Color(0.8, 0.8, 0.65)


    var line_left := MeshInstance3D.new()
    var line_mesh_left := BoxMesh.new()

    line_mesh_left.size = Vector3(0.12, 0.03, 100)
    line_left.mesh = line_mesh_left
    line_left.position = Vector3(-1.75, 0, -40)
    line_left.material_override = line_material

    add_child(line_left)


    var line_right := MeshInstance3D.new()
    var line_mesh_right := BoxMesh.new()

    line_mesh_right.size = Vector3(0.12, 0.03, 100)
    line_right.mesh = line_mesh_right
    line_right.position = Vector3(1.75, 0, -40)
    line_right.material_override = line_material

    add_child(line_right)


    # =========================
    # QUADRO
    # =========================

    player = Node3D.new()
    player.position = Vector3(0, 0, 4)

    add_child(player)


    # Корпус

    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()

    body_mesh.size = Vector3(2.5, 0.7, 3.0)
    body.mesh = body_mesh
    body.position = Vector3(0, 0.8, 0)

    var red := StandardMaterial3D.new()
    red.albedo_color = Color(0.9, 0.03, 0.04)

    body.material_override = red

    player.add_child(body)


    # Сиденье

    var seat := MeshInstance3D.new()
    var seat_mesh := BoxMesh.new()

    seat_mesh.size = Vector3(1.3, 0.35, 1.3)
    seat.mesh = seat_mesh
    seat.position = Vector3(0, 1.35, 0)

    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(0.03, 0.03, 0.04)

    seat.material_override = dark

    player.add_child(seat)


    # =========================
    # ГОРОД
    # =========================

    _create_building(-9.0, 16.0, -20.0, 5.0, 16.0, 5.0)
    _create_building(9.0, 22.0, -32.0, 5.0, 22.0, 5.0)

    _create_building(-10.0, 26.0, -50.0, 6.0, 26.0, 6.0)
    _create_building(10.0, 18.0, -65.0, 5.0, 18.0, 5.0)

    _create_building(-9.0, 36.0, -82.0, 6.0, 36.0, 6.0)
    _create_building(10.0, 28.0, -100.0, 6.0, 28.0, 6.0)


    # =========================
    # ТРАМПЛИН
    # =========================

    _create_ramp()


    # =========================
    # CAMERA
    # =========================

    camera = Camera3D.new()

    camera.position = Vector3(0, 5.5, 11)

    add_child(camera)

    camera.look_at(
        Vector3(0, 1, 0),
        Vector3.UP
    )

    camera.current = true


    # =========================
    # READY
    # =========================

    hud.text = "RED QUADRO\nBOOT: OK\n\nDISTANCE: 0000 m\nSCORE: 00000"


func _create_building(
    x: float,
    height: float,
    z: float,
    width: float,
    building_height: float,
    depth: float
) -> void:

    var building := Node3D.new()

    building.position = Vector3(x, 0, z)

    add_child(building)
    buildings.append(building)


    # =========================
    # BUILDING
    # =========================

    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()

    mesh.size = Vector3(
        width,
        building_height,
        depth
    )

    body.mesh = mesh

    body.position = Vector3(
        0,
        building_height / 2.0,
        0
    )


    var material := StandardMaterial3D.new()

    material.albedo_color = Color(
        0.06,
        0.09,
        0.16
    )

    body.material_override = material

    building.add_child(body)


    # =========================
    # WINDOWS
    # =========================

    var window_material := StandardMaterial3D.new()

    window_material.albedo_color = Color(
        0.95,
        0.65,
        0.15
    )

    window_material.emission_enabled = true
    window_material.emission = Color(
        0.8,
        0.4,
        0.05
    )

    window_material.emission_energy_multiplier = 1.5


    # Передние окна

    var windows_front := MeshInstance3D.new()
    var windows_front_mesh := BoxMesh.new()

    windows_front_mesh.size = Vector3(
        width * 0.65,
        building_height * 0.55,
        0.08
    )

    windows_front.mesh = windows_front_mesh

    windows_front.position = Vector3(
        0,
        building_height * 0.55,
        depth / 2.0 + 0.05
    )

    windows_front.material_override = window_material

    building.add_child(windows_front)


    # Боковые окна

    var windows_side := MeshInstance3D.new()
    var windows_side_mesh := BoxMesh.new()

    windows_side_mesh.size = Vector3(
        0.08,
        building_height * 0.55,
        depth * 0.65
    )

    windows_side.mesh = windows_side_mesh

    windows_side.position = Vector3(
        width / 2.0 + 0.05,
        building_height * 0.55,
        0
    )

    windows_side.material_override = window_material

    building.add_child(windows_side)


func _create_ramp() -> void:

    ramp = Node3D.new()

    ramp.position = Vector3(
        0,
        0,
        -55
    )

    add_child(ramp)


    # =========================
    # НАКЛОННЫЙ ТРАМПЛИН
    # =========================

    var ramp_mesh := MeshInstance3D.new()
    var ramp_box := BoxMesh.new()

    ramp_box.size = Vector3(
        6.5,
        2.0,
        8.0
    )

    ramp_mesh.mesh = ramp_box

    # Наклон вверх в сторону дальнего края
    ramp_mesh.rotation_degrees.x = 14.0

    ramp_mesh.position = Vector3(
        0,
        0.8,
        0
    )


    var ramp_material := StandardMaterial3D.new()

    ramp_material.albedo_color = Color(
        0.75,
        0.05,
        0.03
    )

    ramp_material.emission_enabled = true

    ramp_material.emission = Color(
        0.35,
        0.01,
        0.01
    )

    ramp_material.emission_energy_multiplier = 1.2

    ramp_mesh.material_override = ramp_material

    ramp.add_child(ramp_mesh)


    # =========================
    # НЕОНОВАЯ ПОЛОСА
    # =========================

    var neon := MeshInstance3D.new()
    var neon_mesh := BoxMesh.new()

    neon_mesh.size = Vector3(
        6.7,
        0.12,
        0.25
    )

    neon.mesh = neon_mesh

    neon.position = Vector3(
        0,
        1.9,
        3.2
    )

    neon.rotation_degrees.x = 14.0

    var neon_material := StandardMaterial3D.new()

    neon_material.albedo_color = Color(
        1.0,
        0.15,
        0.02
    )

    neon_material.emission_enabled = true
    neon_material.emission = Color(
        1.0,
        0.05,
        0.01
    )

    neon_material.emission_energy_multiplier = 2.0

    neon.material_override = neon_material

    ramp.add_child(neon)


func _start_jump() -> void:

    if jumping:
        return

    jumping = true

    jump_velocity = 11.0

    trick_rotation = 0.0

    ramp_used = true

    hud.text = "RED QUADRO\n\nJUMP!"


func _process(delta: float) -> void:

    # =========================
    # ДИСТАНЦИЯ
    # =========================

    distance += speed * delta

    score += int(speed * delta)


    # =========================
    # ГОРОД ДВИЖЕТСЯ
    # =========================

    for building in buildings:

        if building != null:

            building.position.z += speed * delta

            if building.position.z > 15.0:

                building.position.z -= 130.0


    # =========================
    # ТРАМПЛИН ДВИЖЕТСЯ
    # =========================

    if ramp != null:

        ramp.position.z += speed * delta

        # Когда трамплин ушёл назад,
        # возвращаем его далеко вперёд

        if ramp.position.z > 15.0:

            ramp.position.z = -100.0
            ramp_used = false


    # =========================
    # АВТОМАТИЧЕСКИЙ ЗАЕЗД
    # НА ТРАМПЛИН
    # =========================

    if ramp != null and not jumping and not ramp_used:

        var ramp_z := ramp.position.z

        if ramp_z > -2.0 and ramp_z < 7.0:

            _start_jump()


    # =========================
    # ПРЫЖОК
    # =========================

    if jumping and player != null:

        jump_velocity -= jump_gravity * delta

        player.position.y += jump_velocity * delta


        # Квадроцикл делает
        # полный кувырок вперёд

        trick_rotation += 720.0 * delta

        player.rotation_degrees.x = trick_rotation


        # Приземление

        if player.position.y <= 0.0:

            player.position.y = 0.0

            jumping = false
            jump_velocity = 0.0

            player.rotation_degrees = Vector3.ZERO

            score += 100

            hud.text = "RED QUADRO\n\nTRICK +100"


    # =========================
    # ПОЛОСЫ
    # =========================

    if player != null:

        var target_x: float = 0.0

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


    # =========================
    # HUD
    # =========================

    if hud != null and not jumping:

        hud.text = "RED QUADRO\nBOOT: OK\n\nDISTANCE: %04d m\nSCORE: %05d" % [
            int(distance),
            score
        ]


func _unhandled_input(event: InputEvent) -> void:

    # =========================
    # TOUCH
    # =========================

    if event is InputEventScreenTouch:

        if event.pressed:

            touch_start = event.position

        else:

            if touch_start != Vector2.ZERO:

                var difference: Vector2 = event.position - touch_start

                if abs(difference.x) > 80.0:

                    if difference.x > 0.0:

                        lane = min(2, lane + 1)

                    else:

                        lane = max(0, lane - 1)

                touch_start = Vector2.ZERO


    # =========================
    # KEYBOARD
    # =========================

    elif event is InputEventKey:

        if not event.pressed:

            return

        if event.keycode == KEY_LEFT:

            lane = max(0, lane - 1)

        if event.keycode == KEY_RIGHT:

            lane = min(2, lane + 1)
