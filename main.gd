extends Node3D

# RED QUADRO — first playable prototype
# Vertical 9:16, auto-run, 3 lanes, ramps, automatic aerial trick, landing scoring.

var speed := 16.0
var base_speed := 16.0
var lane := 1
var lane_x := [-4.0, 0.0, 4.0]
var lane_smooth := 10.0
var distance := 0.0
var score := 0
var coins := 0
var airborne := false
var air_time := 0.0
var jump_duration := 1.15
var jump_start_z := 0.0
var current_trick := 0
var trick_names := ["САЛЬТО ВПЕРЁД", "САЛЬТО НАЗАД", "БОЧКА", "СПИРАЛЬ", "ЭКСТРЕМАЛЬНЫЙ ТРЮК"]
var quad: Node3D
var quad_visual: Node3D
var road_segments: Array[Node3D] = []
var obstacles: Array[Node3D] = []
var hud: Label
var trick_label: Label
var result_label: Label
var camera: Camera3D

func _ready():
    randomize()
    _build_world()
    _build_quad()
    _build_camera()
    _build_ui()

func mat(color: Color, emission := Color(0,0,0), energy := 0.0) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = color
    if energy > 0.0:
        m.emission_enabled = true
        m.emission = emission
        m.emission_energy_multiplier = energy
    return m

func box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
    var n = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.position = pos
    n.material_override = material
    parent.add_child(n)
    return n

func cyl(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
    var n = MeshInstance3D.new()
    var mesh = CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    n.mesh = mesh
    n.position = pos
    n.material_override = material
    parent.add_child(n)
    return n

func _build_world():
    var env = WorldEnvironment.new()
    var e = Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color("071020")
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color("7d8db5")
    e.ambient_light_energy = 0.8
    env.environment = e
    add_child(env)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,-25,0)
    sun.light_energy = 1.2
    add_child(sun)

    # Long road chunks ahead of the rider.
    for i in range(18):
        var seg = Node3D.new()
        seg.position = Vector3(0,0,-i*24.0)
        add_child(seg)
        box(seg, Vector3(14,0.6,24), Vector3(0,-0.35,0), mat(Color("242834")))
        for x in [-2.0,2.0]:
            box(seg, Vector3(0.12,0.03,24), Vector3(x,0.0,0), mat(Color("d5d5b0")))
        # Soviet-future street pylons
        for side in [-1,1]:
            box(seg, Vector3(0.5,5,0.5), Vector3(side*8,2.5,0), mat(Color("a41e2a")))
            box(seg, Vector3(0.5,0.5,4), Vector3(side*8,5,0), mat(Color("d9d7ca")))
        road_segments.append(seg)

    # A ramp and landing deck far ahead.
    _make_ramp(Vector3(0,0,-55), 0.0)
    _make_ramp(Vector3(0,0,-145), 0.0)
    _make_loop_marker(Vector3(0,0,-205))

func _make_ramp(pos: Vector3, rot_y: float):
    var r = Node3D.new()
    r.position = pos
    r.rotation.y = rot_y
    add_child(r)
    var mesh = BoxMesh.new()
    mesh.size = Vector3(12,1.2,10)
    var top = MeshInstance3D.new()
    top.mesh = mesh
    top.position = Vector3(0,2.4,0)
    top.rotation.x = deg_to_rad(-20)
    top.material_override = mat(Color("c52b37"))
    r.add_child(top)
    box(r, Vector3(12,4,2), Vector3(0,0,4), mat(Color("333743")))

func _make_loop_marker(pos: Vector3):
    var ring = MeshInstance3D.new()
    var torus = TorusMesh.new()
    torus.inner_radius = 5.0
    torus.outer_radius = 5.5
    ring.mesh = torus
    ring.position = pos + Vector3(0,7,0)
    ring.rotation_degrees.x = 90
    ring.material_override = mat(Color("2fe6ff"), Color("2fe6ff"), 3.0)
    add_child(ring)

func _build_quad():
    quad = Node3D.new()
    quad.position = Vector3(0,0,4)
    add_child(quad)
    quad_visual = Node3D.new()
    quad.add_child(quad_visual)
    var red = mat(Color("c51f2b"))
    var dark = mat(Color("11131a"))
    var white = mat(Color("e9e2d2"))
    box(quad_visual, Vector3(2.8,0.6,3.2), Vector3(0,1.0,0), red)
    box(quad_visual, Vector3(1.5,0.4,1.6), Vector3(0,1.5,-0.2), white)
    for x in [-1.55,1.55]:
        for z in [-1.0,1.0]:
            var w = cyl(quad_visual,0.58,0.45,Vector3(x,0.55,z),dark)
            w.rotation_degrees.z = 90
    # simplified wolf: torso, head, ears
    box(quad_visual, Vector3(0.9,1.3,0.65), Vector3(0,2.15,0.1), dark)
    var head = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = 0.48
    sphere.height = 0.96
    head.mesh = sphere
    head.position = Vector3(0,3.0,-0.05)
    head.material_override = mat(Color("6e6a6a"))
    quad_visual.add_child(head)
    for x in [-0.25,0.25]:
        var ear = MeshInstance3D.new()
        var cone = PrismMesh.new()
        cone.size = Vector3(0.22,0.45,0.22)
        ear.mesh = cone
        ear.position = Vector3(x,3.5,-0.05)
        ear.material_override = head.material_override
        quad_visual.add_child(ear)

func _build_camera():
    camera = Camera3D.new()
    camera.position = Vector3(0,8,13)
    camera.rotation_degrees = Vector3(-18,0,0)
    add_child(camera)
    camera.current = true

func _build_ui():
    var layer = CanvasLayer.new()
    add_child(layer)
    hud = Label.new()
    hud.position = Vector2(24,24)
    hud.add_theme_font_size_override("font_size", 32)
    layer.add_child(hud)
    trick_label = Label.new()
    trick_label.position = Vector2(0,180)
    trick_label.size = Vector2(720,80)
    trick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    trick_label.add_theme_font_size_override("font_size", 38)
    layer.add_child(trick_label)
    result_label = Label.new()
    result_label.position = Vector2(0,520)
    result_label.size = Vector2(720,160)
    result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_label.add_theme_font_size_override("font_size", 34)
    result_label.visible = false
    layer.add_child(result_label)
    _update_hud()

func _update_hud():
    hud.text = "🏁 %04dm    🪙 %03d    ⭐ %05d" % [int(distance), coins, score]

func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        _screen_touch(event.position)
    elif event is InputEventKey and event.pressed:
        if event.keycode == KEY_A or event.keycode == KEY_LEFT: _change_lane(-1)
        if event.keycode == KEY_D or event.keycode == KEY_RIGHT: _change_lane(1)
        if event.keycode == KEY_SPACE and airborne: _do_extra_trick()

var touch_start := Vector2.ZERO
func _screen_touch(p: Vector2):
    if touch_start == Vector2.ZERO:
        touch_start = p
        return
    var delta = p - touch_start
    if abs(delta.x) > 80:
        _change_lane(1 if delta.x > 0 else -1)
    elif abs(delta.y) > 80 and airborne:
        _do_extra_trick()
    touch_start = Vector2.ZERO

func _change_lane(dir: int):
    lane = clamp(lane + dir, 0, 2)

func _do_extra_trick():
    if not airborne: return
    score += 150
    trick_label.text = "ТРЮК +150"

func _process(delta):
    distance += speed * delta
    score += int(speed * delta * 2.0)
    quad.position.x = lerp(quad.position.x, lane_x[lane], min(1.0, lane_smooth*delta))
    # Fake forward motion: move world toward rider.
    for seg in road_segments:
        seg.position.z += speed * delta
        if seg.position.z > 30: seg.position.z -= 18*24.0
    _update_hud()
    _check_ramp(delta)
    if airborne:
        _update_air(delta)
    else:
        quad_visual.rotation = quad_visual.rotation.slerp(Quaternion.IDENTITY, min(1.0, delta*8.0))
    camera.position.x = lerp(camera.position.x, quad.position.x*0.35, delta*3.0)

func _check_ramp(delta):
    if airborne: return
    # Trigger first/second ramp as the road approaches the rider.
    var z = -55.0 + fmod(distance, 90.0)
    if z > -2.0 and z < 0.2:
        _start_jump()

func _start_jump():
    airborne = true
    air_time = 0.0
    current_trick = randi_range(0,4)
    trick_label.text = "ВЫКРУТАС: " + trick_names[current_trick]
    jump_start_z = quad.position.z

func _update_air(delta):
    air_time += delta
    var t = clamp(air_time / jump_duration, 0.0, 1.0)
    quad.position.y = sin(t*PI) * 7.0
    var angle = t * TAU * (1.0 if current_trick != 0 else 0.65)
    if current_trick == 0: quad_visual.rotation.x = angle
    elif current_trick == 1: quad_visual.rotation.x = -angle
    elif current_trick == 2: quad_visual.rotation.z = angle
    elif current_trick == 3:
        quad_visual.rotation.x = angle
        quad_visual.rotation.z = angle*0.7
    else:
        quad_visual.rotation.x = angle*1.6
        quad_visual.rotation.z = angle*1.2
    if t >= 1.0:
        airborne = false
        quad.position.y = 0
        score += 250
        trick_label.text = "ИДЕАЛЬНОЕ ПРИЗЕМЛЕНИЕ +250"
        quad_visual.rotation = Vector3.ZERO
