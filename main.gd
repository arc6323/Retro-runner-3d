extends Node3D

enum GameState { ROADSIDE_IDLE, MOUNTING, MERGING, RUNNING, PAUSED, GAME_OVER }

const LANE_X := [-3.5, 0.0, 3.5]
const SWIPE_THRESHOLD := 70.0
const DOUBLE_TAP_WINDOW := 0.32
const TRICK_BONUS := 100
const BASE_SPEED := 11.0
const BOOST_SPEED := 18.0
const CAMERA_CHASE := Vector3(0.0, 5.5, 11.0)
const CAMERA_RAMP := Vector3(0.0, 7.0, 15.5)

var game_state := GameState.ROADSIDE_IDLE
var player: CharacterBody3D
var vehicle_visual: Node3D
var wolf: Node3D
var wolf_head: Node3D
var scarf_tail: Node3D
var camera: Camera3D
var world_pivot: Node3D
var hud: Label
var title: Label
var prompt: Label

var buildings: Array[Node3D] = []
var traffic: Array[Node3D] = []
var wheels: Array[MeshInstance3D] = []
var front_wheel_pivots: Array[Node3D] = []
var ramp: Node3D
var ramp_lane := 1
var ramp_used := false

var lane := 1
var distance := 0.0
var score := 0
var trick_score := 0
var jumping := false
var jump_velocity := 0.0
var jump_gravity := 24.0
var trick_requested := false
var trick_angle := 0.0
var boost_remaining := 0.0

var touch_start := Vector2.ZERO
var touch_active := false
var last_tap_time := -10.0
var elapsed_time := 0.0
var transition_time := 0.0
var steer_visual := 0.0
var message_time := 0.0


func _ready() -> void:
    _create_environment()
    _create_world()
    _create_player()
    _create_camera()
    _create_interface()
    _enter_roadside_idle()


func _create_environment() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("06172a")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("456aa0")
    env.ambient_light_energy = 0.65
    world.environment = env
    add_child(world)

    var moonlight := DirectionalLight3D.new()
    moonlight.rotation_degrees = Vector3(-52, -22, 0)
    moonlight.light_color = Color("b9d9ff")
    moonlight.light_energy = 1.8
    add_child(moonlight)


func _create_world() -> void:
    world_pivot = Node3D.new()
    world_pivot.name = "WorldPivot"
    add_child(world_pivot)

    _create_road()

    var building_specs := [
        [-9.0, -18.0, 5.0, 16.0, 5.0],
        [9.0, -30.0, 5.0, 22.0, 5.0],
        [-10.0, -48.0, 6.0, 27.0, 6.0],
        [10.0, -63.0, 5.0, 19.0, 5.0],
        [-9.0, -80.0, 6.0, 34.0, 6.0],
        [10.0, -98.0, 6.0, 28.0, 6.0],
    ]
    for spec in building_specs:
        _create_building(spec[0], spec[1], spec[2], spec[3], spec[4])

    _create_ramp()
    _create_traffic()


func _create_road() -> void:
    var road := _box(Vector3(11, 0.5, 120), Vector3(0, -0.3, -48), Color("171c2b"))
    world_pivot.add_child(road)

    var edge_material := Color("16d9f4")
    var left_edge := _box(Vector3(0.12, 0.08, 120), Vector3(-5.3, 0.02, -48), edge_material, edge_material)
    var right_edge := _box(Vector3(0.12, 0.08, 120), Vector3(5.3, 0.02, -48), edge_material, edge_material)
    world_pivot.add_child(left_edge)
    world_pivot.add_child(right_edge)

    for x in [-1.75, 1.75]:
        for z in range(-104, 14, 6):
            var marker := _box(Vector3(0.11, 0.04, 3.0), Vector3(x, 0.01, float(z)), Color("d8f4ff"), Color("62d8ff"))
            world_pivot.add_child(marker)


func _create_building(x: float, z: float, width: float, height: float, depth: float) -> void:
    var building := Node3D.new()
    building.position = Vector3(x, 0, z)
    world_pivot.add_child(building)
    buildings.append(building)

    var body := _box(Vector3(width, height, depth), Vector3(0, height * 0.5, 0), Color("09172d"))
    building.add_child(body)

    var glow := Color("e72bcb") if x < 0 else Color("16d9f4")
    for row in range(2, int(height), 3):
        var windows := _box(
            Vector3(width * 0.72, 0.3, 0.08),
            Vector3(0, float(row), depth * 0.5 + 0.05),
            glow,
            glow
        )
        building.add_child(windows)


func _create_ramp() -> void:
    ramp = Node3D.new()
    ramp.name = "Ramp"
    ramp.position = Vector3(LANE_X[ramp_lane], 0, -55)
    world_pivot.add_child(ramp)

    var ramp_color := Color("d92132")
    var ramp_mesh := _box(Vector3(3.0, 0.45, 8.0), Vector3(0, 0.35, 0), ramp_color)
    ramp_mesh.rotation_degrees.x = 10.0
    ramp.add_child(ramp_mesh)

    for x in [-1.48, 1.48]:
        var rail := _box(Vector3(0.18, 0.65, 8.0), Vector3(x, 0.48, 0), Color("16d9f4"), Color("16d9f4"))
        rail.rotation_degrees.x = 10.0
        ramp.add_child(rail)

    for z in [-2.4, -0.8, 0.8, 2.4]:
        var arrow := _box(Vector3(2.1, 0.07, 0.22), Vector3(0, 0.62, z), Color("16d9f4"), Color("16d9f4"))
        arrow.rotation_degrees.x = 10.0
        ramp.add_child(arrow)


func _create_traffic() -> void:
    var specs := [[0, -28.0, Color("30384a")], [2, -50.0, Color("ad2334")], [0, -76.0, Color("233d6b")]]
    for spec in specs:
        var car := Node3D.new()
        car.position = Vector3(LANE_X[spec[0]], 0, spec[1])
        car.set_meta("lane", spec[0])
        car.add_child(_box(Vector3(2.1, 0.8, 3.7), Vector3(0, 0.65, 0), spec[2]))
        car.add_child(_box(Vector3(1.6, 0.6, 1.8), Vector3(0, 1.25, 0.2), Color("101827")))
        var tail_left := _box(Vector3(0.45, 0.16, 0.08), Vector3(-0.62, 0.75, 1.88), Color("ff304f"), Color("ff304f"))
        var tail_right := _box(Vector3(0.45, 0.16, 0.08), Vector3(0.62, 0.75, 1.88), Color("ff304f"), Color("ff304f"))
        car.add_child(tail_left)
        car.add_child(tail_right)
        world_pivot.add_child(car)
        traffic.append(car)


func _create_player() -> void:
    player = CharacterBody3D.new()
    player.name = "PlayerAnchor"
    player.position = Vector3(-4.2, 0, 4)
    add_child(player)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.35, 1.7, 2.8)
    collision.shape = shape
    collision.position = Vector3(0, 0.9, 0)
    player.add_child(collision)

    vehicle_visual = Node3D.new()
    vehicle_visual.name = "QuadVisual"
    player.add_child(vehicle_visual)
    _build_quad(vehicle_visual)

    wolf = Node3D.new()
    wolf.name = "RedWolf"
    player.add_child(wolf)
    _build_wolf(wolf)


func _build_quad(parent: Node3D) -> void:
    parent.add_child(_box(Vector3(2.4, 0.58, 2.8), Vector3(0, 0.78, 0), Color("d51f32")))
    parent.add_child(_box(Vector3(1.25, 0.32, 1.3), Vector3(0, 1.22, 0.28), Color("10131c")))
    parent.add_child(_box(Vector3(1.7, 0.18, 0.5), Vector3(0, 1.05, -1.25), Color("ee3347")))
    parent.add_child(_box(Vector3(1.0, 0.22, 0.12), Vector3(0, 1.18, -1.53), Color("bff8ff"), Color("16d9f4")))

    for is_front in [true, false]:
        var z := -1.12 if is_front else 1.12
        for side in [-1.0, 1.0]:
            var pivot := Node3D.new()
            pivot.position = Vector3(side * 1.22, 0.52, z)
            parent.add_child(pivot)
            if is_front:
                front_wheel_pivots.append(pivot)
            var wheel := _cylinder(0.46, 0.38, Vector3.ZERO, Color("08090c"))
            wheel.rotation_degrees.z = 90
            pivot.add_child(wheel)
            wheels.append(wheel)

    var handlebar := _box(Vector3(1.6, 0.08, 0.08), Vector3(0, 1.55, -0.55), Color("242b37"))
    parent.add_child(handlebar)


func _build_wolf(parent: Node3D) -> void:
    var fur := Color("69727e")
    var light_fur := Color("b8bec4")
    var dark := Color("141923")
    var red := Color("c91f32")

    var torso := _box(Vector3(0.85, 1.45, 0.52), Vector3(0, 2.45, 0.15), dark)
    torso.rotation_degrees.x = -8
    parent.add_child(torso)

    wolf_head = Node3D.new()
    wolf_head.position = Vector3(0, 3.45, -0.08)
    parent.add_child(wolf_head)
    wolf_head.add_child(_sphere(Vector3(0.48, 0.55, 0.48), Vector3.ZERO, fur))
    wolf_head.add_child(_box(Vector3(0.43, 0.28, 0.48), Vector3(0, -0.12, -0.42), light_fur))
    wolf_head.add_child(_sphere(Vector3(0.13, 0.11, 0.12), Vector3(0, -0.12, -0.68), Color("090b0e")))
    _add_ear(wolf_head, -0.28, fur)
    _add_ear(wolf_head, 0.28, fur)
    _add_eye(wolf_head, -0.18)
    _add_eye(wolf_head, 0.18)

    for side in [-1.0, 1.0]:
        var arm := _cylinder(0.14, 1.25, Vector3(side * 0.53, 2.2, -0.18), fur)
        arm.rotation_degrees.z = side * 18
        arm.rotation_degrees.x = -50
        parent.add_child(arm)
        var leg := _cylinder(0.18, 1.15, Vector3(side * 0.28, 1.15, 0.15), dark)
        leg.rotation_degrees.x = 72
        parent.add_child(leg)

    var scarf_band := _cylinder(0.38, 0.26, Vector3(0, 3.03, 0.02), red)
    parent.add_child(scarf_band)
    scarf_tail = _box(Vector3(0.32, 1.8, 0.09), Vector3(-0.5, 3.0, 0.65), red)
    scarf_tail.rotation_degrees = Vector3(70, 0, -28)
    parent.add_child(scarf_tail)

    var tail := _cylinder(0.24, 1.4, Vector3(0, 1.85, 0.88), fur)
    tail.rotation_degrees.x = 58
    parent.add_child(tail)


func _add_ear(parent: Node3D, x: float, color: Color) -> void:
    var ear := _box(Vector3(0.25, 0.48, 0.18), Vector3(x, 0.48, 0), color)
    ear.rotation_degrees.z = -12 if x < 0 else 12
    parent.add_child(ear)


func _add_eye(parent: Node3D, x: float) -> void:
    parent.add_child(_sphere(Vector3(0.08, 0.07, 0.045), Vector3(x, 0.08, -0.44), Color("ffc83d"), Color("ffc83d")))


func _create_camera() -> void:
    camera = Camera3D.new()
    camera.name = "CameraRig"
    camera.position = Vector3(-2.5, 5.1, 11.5)
    camera.fov = 68.0
    camera.current = true
    add_child(camera)
    camera.look_at(player.position + Vector3(0, 1.8, 0), Vector3.UP)


func _create_interface() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)

    title = Label.new()
    title.position = Vector2(0, 105)
    title.size = Vector2(720, 150)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 56)
    title.add_theme_color_override("font_color", Color("16d9f4"))
    title.add_theme_color_override("font_shadow_color", Color("e72bcb"))
    title.add_theme_constant_override("shadow_offset_x", 4)
    title.add_theme_constant_override("shadow_offset_y", 4)
    title.text = "НЕОНОВАЯ\nПУСТОШЬ"
    canvas.add_child(title)

    prompt = Label.new()
    prompt.position = Vector2(30, 1410)
    prompt.size = Vector2(660, 90)
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.add_theme_font_size_override("font_size", 25)
    prompt.add_theme_color_override("font_color", Color("f2faff"))
    prompt.text = "КОСНИСЬ ГЕРОЯ, ЧТОБЫ НАЧАТЬ"
    canvas.add_child(prompt)

    hud = Label.new()
    hud.position = Vector2(26, 32)
    hud.size = Vector2(668, 120)
    hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud.add_theme_font_size_override("font_size", 28)
    hud.add_theme_color_override("font_color", Color("f2faff"))
    hud.visible = false
    canvas.add_child(hud)


func _enter_roadside_idle() -> void:
    game_state = GameState.ROADSIDE_IDLE
    transition_time = 0.0
    lane = 1
    world_pivot.position.x = 0.0
    player.position = Vector3(-4.2, 0, 4)
    vehicle_visual.rotation = Vector3.ZERO
    wolf.position = Vector3(-1.3, 0, 0.2)
    wolf.rotation_degrees = Vector3(0, -12, 0)
    title.visible = true
    prompt.visible = true
    hud.visible = false


func _begin_start_sequence() -> void:
    if game_state != GameState.ROADSIDE_IDLE:
        return
    game_state = GameState.MOUNTING
    transition_time = 0.0
    prompt.text = "ВЫХОДИМ НА ТРАССУ..."


func _physics_process(delta: float) -> void:
    elapsed_time += delta
    _animate_living_wolf(delta)

    if game_state == GameState.PAUSED:
        return

    if game_state == GameState.ROADSIDE_IDLE:
        _move_traffic(delta, 7.0, false)
        _update_camera(delta)
        return

    if game_state == GameState.MOUNTING:
        _update_mounting(delta)
        _move_traffic(delta, 7.0, false)
        _update_camera(delta)
        return

    if game_state == GameState.MERGING:
        _update_merging(delta)
        _move_traffic(delta, 9.0, false)
        _update_camera(delta)
        return

    if game_state == GameState.GAME_OVER:
        _update_camera(delta)
        return

    _update_running(delta)


func _animate_living_wolf(delta: float) -> void:
    if wolf == null:
        return
    if game_state == GameState.ROADSIDE_IDLE:
        wolf.position.y = sin(elapsed_time * 1.7) * 0.035
        wolf.rotation_degrees.z = sin(elapsed_time * 0.7) * 1.5
        wolf_head.rotation_degrees.y = sin(elapsed_time * 0.48) * 9.0
        wolf_head.rotation_degrees.x = sin(elapsed_time * 0.9) * 2.0
        scarf_tail.rotation_degrees.z = -28.0 + sin(elapsed_time * 3.2) * 8.0
    else:
        wolf.position.y = lerpf(wolf.position.y, 0.0, min(1.0, delta * 8.0))
        wolf_head.rotation_degrees.y = lerpf(wolf_head.rotation_degrees.y, 0.0, min(1.0, delta * 7.0))
        scarf_tail.rotation_degrees.z = -38.0 + sin(elapsed_time * 8.0) * 10.0


func _update_mounting(delta: float) -> void:
    transition_time += delta
    var t: float = clampf(transition_time / 0.85, 0.0, 1.0)
    var eased: float = smoothstep(0.0, 1.0, t)
    wolf.position = Vector3(-1.3, 0, 0.2).lerp(Vector3(0, 0, 0), eased)
    wolf.rotation_degrees.y = lerpf(-12.0, 0.0, eased)
    wolf.rotation_degrees.x = -sin(t * PI) * 22.0
    if t >= 1.0:
        game_state = GameState.MERGING
        transition_time = 0.0
        title.visible = false
        prompt.visible = false


func _update_merging(delta: float) -> void:
    transition_time += delta
    var t: float = clampf(transition_time / 1.15, 0.0, 1.0)
    var eased: float = smoothstep(0.0, 1.0, t)
    player.position.x = lerpf(-4.2, 0.0, eased)
    vehicle_visual.rotation_degrees.z = -sin(t * PI) * 8.0
    if t >= 1.0:
        game_state = GameState.RUNNING
        vehicle_visual.rotation_degrees.z = 0.0
        hud.visible = true
        _show_message("ПОЕХАЛИ!", 1.0)


func _update_running(delta: float) -> void:
    var current_speed: float = BOOST_SPEED if boost_remaining > 0.0 else BASE_SPEED
    boost_remaining = max(0.0, boost_remaining - delta)
    distance += current_speed * delta
    score = int(distance) + trick_score

    for building in buildings:
        building.position.z += current_speed * delta
        if building.position.z > 18.0:
            building.position.z -= 130.0

    ramp.position.z += current_speed * delta
    if ramp.position.z > 17.0:
        ramp.position.z = -105.0
        ramp_lane = (ramp_lane + 1) % 3
        ramp.position.x = LANE_X[ramp_lane]
        ramp_used = false

    _move_traffic(delta, current_speed * 0.88, true)
    _update_world_shift(delta)
    _update_jump(delta)
    _spin_wheels(delta, current_speed)
    _update_camera(delta)
    _update_hud(delta)


func _move_traffic(delta: float, movement_speed: float, check_collision: bool) -> void:
    for car in traffic:
        car.position.z += movement_speed * delta
        if car.position.z > 18.0:
            car.position.z -= 92.0
            var next_lane := (int(car.get_meta("lane")) + 1) % 3
            car.set_meta("lane", next_lane)
            car.position.x = LANE_X[next_lane]
        if check_collision and not jumping:
            var car_lane := int(car.get_meta("lane"))
            if car_lane == lane and car.position.z > 1.6 and car.position.z < 6.2:
                _game_over()


func _update_world_shift(delta: float) -> void:
    var target_x: float = -float(LANE_X[lane])
    var error: float = target_x - world_pivot.position.x
    world_pivot.position.x = lerpf(world_pivot.position.x, target_x, min(1.0, delta * 8.5))

    var desired_steer: float = clampf(-error / 3.5, -1.0, 1.0) * 24.0
    steer_visual = lerpf(steer_visual, desired_steer, min(1.0, delta * 12.0))
    if abs(error) < 0.03:
        steer_visual = lerpf(steer_visual, 0.0, min(1.0, delta * 10.0))

    for pivot in front_wheel_pivots:
        pivot.rotation_degrees.y = steer_visual
    vehicle_visual.rotation_degrees.z = -steer_visual * 0.18
    wolf.rotation_degrees.z = -steer_visual * 0.24


func _update_jump(delta: float) -> void:
    if not jumping and not ramp_used and lane == ramp_lane:
        var ramp_front_z := ramp.position.z + 4.0
        if ramp_front_z >= 2.0 and ramp_front_z <= 5.0:
            _start_jump()

    if not jumping:
        return

    jump_velocity -= jump_gravity * delta
    player.position.y += jump_velocity * delta
    var trick_speed := 560.0 if trick_requested else 300.0
    trick_angle += trick_speed * delta
    vehicle_visual.rotation_degrees.x = trick_angle
    wolf.rotation_degrees.x = trick_angle

    if player.position.y <= 0.0:
        player.position.y = 0.0
        jumping = false
        jump_velocity = 0.0
        vehicle_visual.rotation_degrees.x = 0.0
        wolf.rotation_degrees.x = 0.0
        if trick_requested:
            trick_score += TRICK_BONUS
            _show_message("ТРЮК +100", 1.2)
        else:
            _show_message("МЯГКОЕ ПРИЗЕМЛЕНИЕ", 0.8)
        trick_requested = false


func _start_jump() -> void:
    if jumping or game_state != GameState.RUNNING:
        return
    jumping = true
    jump_velocity = 12.0
    trick_angle = 0.0
    ramp_used = true
    _show_message("ПРЫЖОК!", 0.7)


func _spin_wheels(delta: float, current_speed: float) -> void:
    for wheel in wheels:
        wheel.rotate_x(current_speed * delta * 1.7)


func _update_camera(delta: float) -> void:
    var target_position := CAMERA_CHASE
    var target_fov := 70.0
    var target_look := player.position + Vector3(0, 1.4, -2.0)

    if game_state == GameState.ROADSIDE_IDLE or game_state == GameState.MOUNTING:
        target_position = Vector3(-2.3, 5.2, 11.6)
        target_fov = 64.0
        target_look = player.position + Vector3(-0.45, 1.8, 0)
    elif game_state == GameState.MERGING:
        target_position = CAMERA_CHASE
        target_fov = 70.0
    elif jumping or _ramp_is_close():
        target_position = CAMERA_RAMP
        target_fov = 79.0

    camera.position = camera.position.lerp(target_position, min(1.0, delta * 3.5))
    camera.fov = lerpf(camera.fov, target_fov, min(1.0, delta * 3.2))
    camera.look_at(target_look, Vector3.UP)


func _ramp_is_close() -> bool:
    if ramp == null or ramp_used or lane != ramp_lane:
        return false
    var front_z := ramp.position.z + 4.0
    return front_z > -11.0 and front_z < 5.0


func _update_hud(delta: float) -> void:
    message_time = max(0.0, message_time - delta)
    if message_time > 0.0:
        return
    var boost_text := "  •  УСКОРЕНИЕ" if boost_remaining > 0.0 else ""
    hud.text = "ДИСТАНЦИЯ %04d м     СЧЁТ %05d%s" % [int(distance), score, boost_text]


func _show_message(text: String, duration: float) -> void:
    hud.text = text
    message_time = duration


func _game_over() -> void:
    game_state = GameState.GAME_OVER
    hud.text = "СТОЛКНОВЕНИЕ\nСЧЁТ %05d\n\nКОСНИСЬ ЭКРАНА — ЕЩЁ РАЗ" % score


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause") and game_state in [GameState.RUNNING, GameState.PAUSED]:
        game_state = GameState.RUNNING if game_state == GameState.PAUSED else GameState.PAUSED
        hud.text = "ПРОДОЛЖИТЬ — КОСНИСЬ ЭКРАНА" if game_state == GameState.PAUSED else "ПОЕХАЛИ!"
        return

    if event.is_action_pressed("restart"):
        _reset_run()
        return

    if event.is_action_pressed("move_left") and game_state == GameState.RUNNING:
        lane = max(0, lane - 1)
        return
    if event.is_action_pressed("move_right") and game_state == GameState.RUNNING:
        lane = min(2, lane + 1)
        return
    if event.is_action_pressed("trick") and game_state == GameState.RUNNING:
        if jumping:
            trick_requested = true
        else:
            _start_jump()
        return

    if event is InputEventScreenTouch:
        _handle_pointer(event.position, event.pressed)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        _handle_pointer(event.position, event.pressed)


func _handle_pointer(position: Vector2, pressed: bool) -> void:
    if pressed:
        touch_start = position
        touch_active = true
        return

    if not touch_active:
        return
    touch_active = false
    var difference := position - touch_start

    if game_state == GameState.ROADSIDE_IDLE:
        if _hero_was_tapped(position):
            _begin_start_sequence()
        return
    if game_state == GameState.PAUSED:
        game_state = GameState.RUNNING
        return
    if game_state == GameState.GAME_OVER:
        _reset_run()
        return
    if game_state != GameState.RUNNING:
        return

    if abs(difference.x) > SWIPE_THRESHOLD and abs(difference.x) > abs(difference.y):
        lane = clampi(lane + (1 if difference.x > 0 else -1), 0, 2)
    elif difference.y < -SWIPE_THRESHOLD:
        _start_jump()
    elif difference.length() < 34.0:
        _handle_tap()


func _hero_was_tapped(screen_position: Vector2) -> bool:
    if camera.is_position_behind(wolf.global_position):
        return false
    var hero_screen := camera.unproject_position(wolf.global_position + Vector3(0, 2.0, 0))
    return hero_screen.distance_to(screen_position) < 210.0


func _handle_tap() -> void:
    var now := Time.get_ticks_msec() / 1000.0
    if jumping:
        trick_requested = true
        _show_message("ТРЮК!", 0.45)
    elif now - last_tap_time <= DOUBLE_TAP_WINDOW:
        boost_remaining = 1.35
        _show_message("УСКОРЕНИЕ!", 0.65)
        last_tap_time = -10.0
    else:
        last_tap_time = now


func _reset_run() -> void:
    distance = 0.0
    trick_score = 0
    score = 0
    jumping = false
    jump_velocity = 0.0
    trick_requested = false
    trick_angle = 0.0
    boost_remaining = 0.0
    ramp_lane = 1
    ramp.position = Vector3(LANE_X[ramp_lane], 0, -55)
    ramp_used = false
    for index in buildings.size():
        buildings[index].position.z = -18.0 - index * 16.0
    for index in traffic.size():
        var car_lane := index % 3
        traffic[index].set_meta("lane", car_lane)
        traffic[index].position = Vector3(LANE_X[car_lane], 0, -30.0 - index * 24.0)
    _enter_roadside_idle()


func _material(color: Color, emission: Color = Color(0, 0, 0, 1)) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    if emission.r > 0.0 or emission.g > 0.0 or emission.b > 0.0:
        material.emission_enabled = true
        material.emission = emission
        material.emission_energy_multiplier = 1.8
    return material


func _box(size: Vector3, position: Vector3, color: Color, emission: Color = Color(0, 0, 0, 1)) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = position
    node.material_override = _material(color, emission)
    return node


func _sphere(scale_value: Vector3, position: Vector3, color: Color, emission: Color = Color(0, 0, 0, 1)) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.height = 1.0
    mesh.radius = 0.5
    node.mesh = mesh
    node.scale = scale_value
    node.position = position
    node.material_override = _material(color, emission)
    return node


func _cylinder(radius: float, height: float, position: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    node.mesh = mesh
    node.position = position
    node.material_override = _material(color)
    return node
