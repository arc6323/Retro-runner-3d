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
