class_name GameBase
extends Node3D

enum GameState { ROADSIDE_IDLE, MOUNTING, MERGING, RUNNING, PAUSED, GAME_OVER }

const LANE_X := [-3.5, 0.0, 3.5]
const SWIPE_THRESHOLD := 70.0
const DOUBLE_TAP_WINDOW := 0.32
const TRICK_BONUS := 100
const BASE_SPEED := 11.0
const BOOST_SPEED := 18.0
# Keep the chase camera exactly centered on the road to avoid a perceived right tilt.
const CAMERA_CHASE := Vector3(0.0, 4.8, 9.6)
const CAMERA_RAMP := Vector3(0.0, 6.2, 13.2)
const CAMERA_IDLE := Vector3(0.0, 4.6, 9.8)
const SAVE_PATH := "user://neon_wasteland.cfg"
const WOLF_STANDING_SCENE: PackedScene = preload("res://assets/models/red_wolf_standing.glb")
const WOLF_RIDING_SCENE: PackedScene = preload("res://assets/models/red_wolf_riding.glb")
const STREET_QUAD_SCENE: PackedScene = preload("res://assets/models/street_quad.glb")

var game_state := GameState.ROADSIDE_IDLE
var player: CharacterBody3D
var vehicle_visual: Node3D
var wolf: Node3D
var wolf_standing: Node3D
var wolf_riding: Node3D
var wolf_head: Node3D
var scarf_tail: Node3D
var camera: Camera3D
var world_pivot: Node3D
var hud: Label
var title: Label
var prompt: Label
var buildings: Array[Node3D] = []
var traffic: Array[Node3D] = []
var props: Array[Node3D] = []
var wheel_spin_pivots: Array[Node3D] = []
var front_wheel_pivots: Array[Node3D] = []
var ramp: Node3D
var ramp_lane := 1
var ramp_used := false
var lane := 1
var distance := 0.0
var score := 0
var trick_score := 0
var high_score := 0
var jumping := false
var jump_velocity := 0.0
var jump_gravity := 24.0
var trick_requested := false
var trick_angle := 0.0
var boost_remaining := 0.0
var shield_remaining := 0.0
var magnet_remaining := 0.0
var flight_remaining := 0.0
var flight_invulnerability_remaining := 0.0
var coins := 0
var touch_start := Vector2.ZERO
var touch_active := false
var last_tap_time := -10.0
var elapsed_time := 0.0
var transition_time := 0.0
var steer_visual := 0.0
var message_time := 0.0
var camera_shake := 0.0
var look_yaw := 0.0
var look_pitch := 0.0
var scarf_base := -28.0
var rng := RandomNumberGenerator.new()
var building_homes: Array[Vector3] = []
var traffic_homes: Array[Vector3] = []
var traffic_home_lanes: Array[int] = []
var prop_homes: Array[Vector3] = []
var pickup_homes: Array[Vector3] = []
var pickup_types: Array[String] = []
var pickups: Array[Node3D] = []
var ramp_home := Vector3(0, 0, -55)


func _create_world() -> void:
	world_pivot = Node3D.new()
	world_pivot.name = "WorldPivot"
	add_child(world_pivot)
	CityKit.attach_road(world_pivot)
	var specs := [
		[-9.4, -14.0, 5.4, 18.0, 6.2, 0], [9.6, -22.0, 6.0, 26.0, 6.8, 1],
		[-10.2, -36.0, 5.8, 32.0, 7.0, 2], [10.4, -48.0, 5.2, 15.0, 5.6, 0],
		[-9.6, -62.0, 6.4, 28.0, 6.4, 1], [9.8, -76.0, 5.6, 21.0, 6.0, 2],
		[-10.6, -90.0, 6.8, 38.0, 7.4, 0], [10.8, -104.0, 5.4, 24.0, 6.2, 1],
		[-9.2, -118.0, 5.0, 16.0, 5.4, 2], [9.4, -132.0, 6.2, 30.0, 6.8, 0],
	]
	for spec in specs:
		var building := CityKit.attach_building(world_pivot, spec[0], spec[1], spec[2], spec[3], spec[4], int(spec[5]))
		buildings.append(building)
		building_homes.append(building.position)
	for lamp in CityKit.attach_lamps(world_pivot):
		props.append(lamp)
		prop_homes.append(lamp.position)
	ramp_home = Vector3(LANE_X[ramp_lane], 0, -55)
	ramp = CityKit.attach_ramp(world_pivot, ramp_home)
	_create_pickups()
	# Traffic is intentionally restricted to the two side lanes; the center lane is the player's safe line.
	var cars := [
		[0, -24.0, Color(0.12, 0.13, 0.16)], [2, -41.0, Color(0.42, 0.08, 0.08)],
		[0, -63.0, Color(0.08, 0.12, 0.22)], [2, -88.0, Color(0.18, 0.18, 0.16)],
		[0, -112.0, Color(0.08, 0.08, 0.08)],
	]
	for spec in cars:
		var car := CityKit.make_car(int(spec[0]), spec[1], spec[2], LANE_X)
		world_pivot.add_child(car)
		traffic.append(car)
		traffic_homes.append(car.position)
		traffic_home_lanes.append(int(spec[0]))


func _create_pickups() -> void:
	# Rare power-ups: flight/rocket is intentionally only one item in this cycle.
	var types := ["coin", "coin", "shield", "coin", "magnet", "coin", "coin", "coin", "boost", "coin", "coin", "shield", "coin", "coin", "magnet", "coin", "boost", "coin", "coin", "coin", "coin", "coin", "coin", "flight"]
	for index in range(types.size()):
		var pickup_type: String = types[index]
		var pickup := Node3D.new()
		pickup.name = "Pickup_%02d_%s" % [index, pickup_type]
		pickup.position = Vector3(LANE_X[index % 3], 0.9 if pickup_type == "coin" else 1.05, -18.0 - float(index) * 18.0)
		pickup.set_meta("pickup_type", pickup_type)
		pickup.set_meta("home_position", pickup.position)
		world_pivot.add_child(pickup)
		_create_pickup_visual(pickup, pickup_type)
		pickups.append(pickup)
		pickup_homes.append(pickup.position)
		pickup_types.append(pickup_type)


func _create_pickup_visual(pickup: Node3D, pickup_type: String) -> void:
	var icon_color := Color(1.0, 0.78, 0.15)
	var icon_text := ""
	if pickup_type == "shield":
		icon_color = Color(0.25, 0.72, 1.0)
		icon_text = "ЩИТ"
		pickup.add_child(MeshKit.cylinder(0.5, 0.16, Vector3(0, 0, 0), icon_color))
		pickup.add_child(MeshKit.box(Vector3(0.58, 0.12, 0.16), Vector3(0, 0, -0.32), Color(0.7, 0.9, 1.0)))
	elif pickup_type == "magnet":
		icon_color = Color(0.95, 0.22, 0.48)
		icon_text = "МАГ"
		pickup.add_child(MeshKit.box(Vector3(0.16, 0.62, 0.18), Vector3(-0.3, 0, 0), icon_color))
		pickup.add_child(MeshKit.box(Vector3(0.16, 0.62, 0.18), Vector3(0.3, 0, 0), icon_color))
		pickup.add_child(MeshKit.box(Vector3(0.76, 0.16, 0.18), Vector3(0, -0.28, 0), icon_color))
	elif pickup_type == "boost":
		icon_color = Color(1.0, 0.38, 0.08)
		icon_text = "БУСТ"
		var bolt := MeshKit.box(Vector3(0.22, 0.9, 0.22), Vector3(0, 0, 0), icon_color, Color(1.0, 0.85, 0.2))
		bolt.rotation_degrees.z = 35.0
		pickup.add_child(bolt)
		pickup.add_child(MeshKit.box(Vector3(0.7, 0.12, 0.12), Vector3(0, 0.18, 0), Color(1.0, 0.85, 0.2)))
	elif pickup_type == "flight":
		icon_color = Color(0.75, 0.42, 1.0)
		icon_text = "ПОЛЁТ"
		var wing_l := MeshKit.box(Vector3(0.95, 0.12, 0.38), Vector3(-0.48, 0, 0), icon_color)
		var wing_r := MeshKit.box(Vector3(0.95, 0.12, 0.38), Vector3(0.48, 0, 0), icon_color)
		wing_l.rotation_degrees.z = -18.0
		wing_r.rotation_degrees.z = 18.0
		pickup.add_child(wing_l)
		pickup.add_child(wing_r)
	else:
		var coin := MeshKit.cylinder(0.42, 0.16, Vector3.ZERO, icon_color)
		coin.rotation_degrees.x = 90.0
		pickup.add_child(coin)
		return
	var label := Label3D.new()
	label.text = icon_text
	label.position = Vector3(0, 0.78, 0)
	label.font_size = 42
	label.pixel_size = 0.004
	label.outline_size = 7
	label.outline_modulate = Color(0.02, 0.02, 0.03, 1.0)
	label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true
	label.no_depth_test = true
	pickup.add_child(label)


func _create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "PlayerAnchor"
	player.position = Vector3(-4.2, 0, 4)
	add_child(player)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.7, 1.5, 2.4)
	collision.shape = shape
	collision.position = Vector3(0, 0.85, 0)
	player.add_child(collision)
	vehicle_visual = STREET_QUAD_SCENE.instantiate() as Node3D
	vehicle_visual.name = "StreetQuad"
	vehicle_visual.scale = Vector3.ONE * 0.92
	vehicle_visual.rotation_degrees.y = 180.0
	player.add_child(vehicle_visual)
	wolf_standing = WOLF_STANDING_SCENE.instantiate() as Node3D
	wolf_standing.name = "RedWolfStanding"
	wolf_standing.scale = Vector3.ONE * 0.78
	player.add_child(wolf_standing)
	wolf_riding = WOLF_RIDING_SCENE.instantiate() as Node3D
	wolf_riding.name = "RedWolfRiding"
	wolf_riding.scale = Vector3.ONE * 0.78
	wolf_riding.rotation_degrees.y = 180.0
	player.add_child(wolf_riding)
	_set_active_wolf(wolf_standing)
	_create_flight_fx()
	_connect_vehicle_parts()


func _create_flight_fx() -> void:
	var fx := Node3D.new()
	fx.name = "FlightFX"
	player.add_child(fx)
	var wing_l := MeshKit.box(Vector3(1.65, 0.12, 0.48), Vector3(-1.05, 0.85, 0.0), Color(0.72, 0.42, 0.98), Color(0.5, 0.2, 0.9))
	wing_l.name = "WingLeft"
	wing_l.rotation_degrees.z = -12.0
	fx.add_child(wing_l)
	var wing_r := MeshKit.box(Vector3(1.65, 0.12, 0.48), Vector3(1.05, 0.85, 0.0), Color(0.72, 0.42, 0.98), Color(0.5, 0.2, 0.9))
	wing_r.name = "WingRight"
	wing_r.rotation_degrees.z = 12.0
	fx.add_child(wing_r)
	var exhaust := MeshKit.box(Vector3(0.55, 0.55, 2.2), Vector3(0, 0.48, 1.75), Color(0.92, 0.48, 0.12), Color(1.0, 0.25, 0.05))
	exhaust.name = "Exhaust"
	fx.add_child(exhaust)
	wing_l.visible = false
	wing_r.visible = false
	exhaust.visible = false


func _set_active_wolf(active_wolf: Node3D) -> void:
	wolf = active_wolf
	wolf_standing.visible = active_wolf == wolf_standing
	wolf_riding.visible = active_wolf == wolf_riding
	wolf_head = wolf.find_child("HeadPivot", true, false) as Node3D
	scarf_tail = wolf.find_child("ScarfTailPivot", true, false) as Node3D
	scarf_base = -30.0 if active_wolf == wolf_riding else -24.0


func _connect_vehicle_parts() -> void:
	front_wheel_pivots.clear()
	wheel_spin_pivots.clear()
	for pivot_name in ["WheelFrontLeftPivot", "WheelFrontRightPivot"]:
		var found := vehicle_visual.find_child(pivot_name, true, false) as Node3D
		if found != null:
			front_wheel_pivots.append(found)
	for spin_name in ["WheelFrontLeftSpin", "WheelFrontRightSpin", "WheelRearLeftSpin", "WheelRearRightSpin"]:
		var spin := vehicle_visual.find_child(spin_name, true, false) as Node3D
		if spin != null:
			wheel_spin_pivots.append(spin)