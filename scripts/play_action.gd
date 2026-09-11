class_name PlayAction
extends RefCounted


static func update_jump(g: Node, delta: float) -> void:
	if not g.jumping and not g.ramp_used and g.lane == g.ramp_lane:
		var ramp_front_z: float = g.ramp.position.z + 4.0
		if ramp_front_z >= 2.0 and ramp_front_z <= 5.0:
			g._start_jump()
	if not g.jumping:
		return
	g.jump_velocity -= g.jump_gravity * delta
	g.player.position.y += g.jump_velocity * delta
	g.trick_angle += (560.0 if g.trick_requested else 280.0) * delta
	g.vehicle_visual.rotation_degrees.x = g.trick_angle
	g.wolf.rotation_degrees.x = g.trick_angle * 0.92
	if g.player.position.y <= 0.0:
		g.player.position.y = 0.0
		g.jumping = false
		g.jump_velocity = 0.0
		g.vehicle_visual.rotation_degrees.x = 0.0
		g.wolf.rotation_degrees.x = 0.0
		g.camera_shake = 0.55 if g.trick_requested else 0.35
		if g.trick_requested:
			g.trick_score += g.TRICK_BONUS
			g._show_message("ТРЮК +100", 1.2)
		else:
			g._show_message("МЯГКОЕ ПРИЗЕМЛЕНИЕ", 0.8)
		g.trick_requested = false


static func update_camera(g: Node, delta: float) -> void:
	var target_position: Vector3 = g.CAMERA_CHASE
	var target_fov := 68.0
	var target_look: Vector3 = g.player.position + Vector3(g.steer_visual * 0.015, 1.35, -2.4)
	if g.game_state == g.GameState.ROADSIDE_IDLE or g.game_state == g.GameState.MOUNTING:
		target_position = g.CAMERA_IDLE
		target_fov = 58.0
		target_look = g.player.position + Vector3(-0.35, 1.55, 0.15)
	elif g.game_state == g.GameState.MERGING:
		target_fov = 66.0
	elif g.jumping or g._ramp_is_close():
		target_position = g.CAMERA_RAMP
		target_fov = 76.0
		target_look = g.player.position + Vector3(0, 1.7, -3.2)
	elif g.boost_remaining > 0.0:
		target_position = g.CAMERA_CHASE + Vector3(0, 0.25, 1.1)
		target_fov = 74.0
	if g.game_state == g.GameState.GAME_OVER:
		target_position = Vector3(1.6, 3.4, 6.4)
		target_fov = 52.0
		target_look = g.player.position + Vector3(0, 1.1, 0)
	g.camera.position = g.camera.position.lerp(target_position, min(1.0, delta * 3.2))
	if g.camera_shake > 0.0:
		g.camera.position += Vector3(g.rng.randf_range(-1.0, 1.0), g.rng.randf_range(-0.6, 0.6), 0.0) * g.camera_shake * 0.12
	g.camera.fov = lerpf(g.camera.fov, target_fov, min(1.0, delta * 3.0))
	g.camera.look_at(target_look, Vector3.UP)


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
		if g._hero_was_tapped(position):
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
	g.jumping = false
	g.jump_velocity = 0.0
	g.trick_requested = false
	g.trick_angle = 0.0
	g.boost_remaining = 0.0
	g.steer_visual = 0.0
	g.camera_shake = 0.0
	g.ramp_lane = 1
	g.ramp_used = false
	g.ramp.position = Vector3(g.LANE_X[g.ramp_lane], 0.0, g.ramp_home.z)
	for index in g.buildings.size():
		g.buildings[index].position = g.building_homes[index]
	for index in g.props.size():
		g.props[index].position = g.prop_homes[index]
	for index in g.traffic.size():
		g.traffic[index].position = g.traffic_homes[index]
		g.traffic[index].set_meta("lane", g.traffic_home_lanes[index])
	g._enter_roadside_idle()
