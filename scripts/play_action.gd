class_name PlayAction
extends RefCounted


static func update_jump(g: Node, delta: float) -> void:
	# Jump simulation is owned by main.gd now. Kept as a compatibility stub.
	return


static func update_camera(g: Node, delta: float) -> void:
	var chase_position: Vector3 = g.CAMERA_CHASE * 1.8
	var target_position: Vector3 = chase_position
	var target_fov := 68.0
	var target_look: Vector3 = g.player.position + Vector3(0, 1.35, -2.4)
	if g.game_state == g.GameState.ROADSIDE_IDLE or g.game_state == g.GameState.MOUNTING:
		target_position = g.CAMERA_IDLE * 1.8
		target_fov = 58.0
		target_look = g.player.position + Vector3(0, 1.55, 0.15)
	elif g.game_state == g.GameState.MERGING:
		target_fov = 66.0
	elif g.jumping or g._ramp_is_close():
		# Gentle pull-back: no snap when approaching a ramp.
		var ramp_blend := 0.22 if not g.jumping else 0.30
		target_position = chase_position.lerp(g.CAMERA_RAMP * 1.8, ramp_blend)
		target_fov = lerpf(68.0, 72.0, ramp_blend)
		target_look = g.player.position + Vector3(0, 1.45, -2.8)
	elif g.boost_remaining > 0.0:
		target_position = (g.CAMERA_CHASE + Vector3(0, 0.15, 0.55)) * 1.8
		target_fov = 71.0
	if g.flight_remaining > 0.0:
		target_position = chase_position + Vector3(0, 0.8, 1.5)
		target_fov = 71.0
		target_look = g.player.position + Vector3(0, 1.0, -2.5)
	if g.game_state == g.GameState.GAME_OVER:
		target_position = Vector3(0.0, 3.4, 6.4) * 1.8
		target_fov = 52.0
		target_look = g.player.position + Vector3(0, 1.1, 0)
	g.camera.position = g.camera.position.lerp(target_position, min(1.0, delta * 2.6))
	if g.camera_shake > 0.0:
		g.camera.position += Vector3(g.rng.randf_range(-1.0, 1.0), g.rng.randf_range(-0.6, 0.6), 0.0) * g.camera_shake * 0.12
	g.camera.fov = lerpf(g.camera.fov, target_fov, min(1.0, delta * 2.4))
	g.camera.look_at(target_look, Vector3.UP)
	# Explicitly remove roll so the road never appears slanted.
	g.camera.rotation.z = 0.0


static func handle_pointer(g: Node, position: Vector2, pressed: bool) -> void:
	if pressed:
		g.touch_start = position
		g.touch_active = true
		return
	if not g.touch_active:
		return
	g.touch_active = false
	var difference: Vector2 = position - g.touch_start
	if g.game_state == g.GameState.ROADSIDE_IDLE:
		if g._hero_was_tapped(position) or g._vehicle_was_tapped(position):
			g._begin_start_sequence()
		return
	if g.game_state == g.GameState.PAUSED:
		g.game_state = g.GameState.RUNNING
		return
	if g.game_state == g.GameState.GAME_OVER:
		g._reset_run()
		return
	if g.game_state != g.GameState.RUNNING:
		return
	if abs(difference.x) > g.SWIPE_THRESHOLD and abs(difference.x) > abs(difference.y):
		g.lane = clampi(g.lane + (1 if difference.x > 0 else -1), 0, 2)
	elif difference.y < -g.SWIPE_THRESHOLD:
		g._try_player_jump()
	elif difference.length() < 34.0:
		g._handle_tap()


static func reset_run(g: Node) -> void:
	g.distance = 0.0
	g.trick_score = 0
	g.score = 0
	g.coins = 0
	g.jumping = false
	g.jump_velocity = 0.0
	g.trick_requested = false
	g.trick_angle = 0.0
	g.boost_remaining = 0.0
	g.shield_remaining = 0.0
	g.magnet_remaining = 0.0
	g.flight_remaining = 0.0
	g.flight_invulnerability_remaining = 0.0
	var wing_l: Node3D = g.player.get_node_or_null("FlightFX/WingLeft") as Node3D
	var wing_r: Node3D = g.player.get_node_or_null("FlightFX/WingRight") as Node3D
	var exhaust: Node3D = g.player.get_node_or_null("FlightFX/Exhaust") as Node3D
	if wing_l != null:
		wing_l.visible = false
	if wing_r != null:
		wing_r.visible = false
	if exhaust != null:
		exhaust.visible = false
	g.steer_visual = 0.0
	g.camera_shake = 0.0
	g.player.position = Vector3(0.0, 0.0, 0.0)
	g.vehicle_visual.rotation_degrees = Vector3(0, 180, 0)
	g.set_meta("run_grace_remaining", 0.0)
	g.ramp_lane = 1
	g.ramp_used = false
	g.ramp.position = Vector3(g.LANE_X[g.ramp_lane], 0.0, g.ramp_home.z)
	for index in g.pickups.size():
		g.pickups[index].position = g.pickup_homes[index]
		g.pickups[index].position.x = g.LANE_X[index % 3]
		g.pickups[index].visible = true
	for index in g.buildings.size():
		g.buildings[index].position = g.building_homes[index]
	for index in g.props.size():
		g.props[index].position = g.prop_homes[index]
	for index in g.traffic.size():
		g.traffic[index].position = g.traffic_homes[index]
		g.traffic[index].set_meta("lane", g.traffic_home_lanes[index])
	g._enter_roadside_idle()
