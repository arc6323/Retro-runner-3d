extends Node3D

enum GameState { ROADSIDE_IDLE, MOUNTING, MERGING, RUNNING, PAUSED, GAME_OVER }

const LANE_X := [-3.5, 0.0, 3.5]
const SWIPE_THRESHOLD := 70.0
const DOUBLE_TAP_WINDOW := 0.32
const TRICK_BONUS := 100
const BASE_SPEED := 11.0
const BOOST_SPEED := 18.0
const CAMERA_CHASE := Vector3(0.35, 4.8, 9.6)
const CAMERA_RAMP := Vector3(0.15, 6.4, 13.8)
const CAMERA_IDLE := Vector3(-2.15, 4.6, 9.8)
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
var ramp_home := Vector3(0, 0, -55)
