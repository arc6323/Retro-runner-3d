class_name PlayAction
extends RefCounted

static func update_jump(g: Node, delta: float) -> void:
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
		var ramp_blend := 0.12 if not g.jumping else 0.18
		target_position = chase_position.lerp(g.CAMERA_RAMP * 1.8, ramp_blend)
		target_fov = lerpf(68.0, 71.0, ramp_blend)
		target_look = g.player.position + Vector3(0, 1.45, -3.4)
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
		target_look = g.player.position + Vector3(0, 1.1, -4.5)
	g.camera.position = g.camera.position.lerp(target_position, min(1.0, delta * 2.6))
	if g.camera_shake > 0.0:
		g.camera.position += Vector3(g.rng.randf_range(-1.0, 1.0), g.rng.randf_range(-0.6, 0.6), 0.0) * g.camera_shake * 0.12
	g.camera.fov = lerpf(g.camera.fov, target_fov, min(1.0, delta * 2.4))
	g.camera.look_at(target_look, Vector3.UP)
	g.camera.rotation.z = 0.0
	if g.game_state == g.GameState.GAME_OVER and g.crash_active:
		_update_crash_visuals(g, delta)

static func _update_crash_visuals(g: Node, delta: float) -> void:
	var t: float = g.crash_time
	# The traffic car gets a lateral impulse first, then leaves the road while spinning around Y.
	if g.crash_car != null and is_instance_valid(g.crash_car):
		if not g.crash_car.has_meta("crash_visual_origin"):
			g.crash_car.set_meta("crash_visual_origin", g.crash_car.position)
		var origin: Vector3 = g.crash_car.get_meta("crash_visual_origin")
		var side: float = 1.0 if origin.x >= 0.0 else -1.0
		if abs(origin.x) < 0.4:
			side = 1.0 if g.lane >= 2 else -1.0
		var target_x: float = side * 8.6
		var shove_p: float = smoothstep(0.0, 0.75, clampf(t / 0.75, 0.0, 1.0))
		g.crash_car.position.x = lerpf(origin.x, target_x, shove_p)
		g.crash_car.position.z = origin.z - 5.5 * shove_p
		g.crash_car.position.y = sin(shove_p * PI) * 1.0
		g.crash_car.rotation_degrees.y = 900.0 * shove_p
		g.crash_car.rotation_degrees.x = sin(shove_p * PI) * 18.0
		g.crash_car.rotation_degrees.z = side * sin(shove_p * PI) * 12.0
		for wheel in g.crash_car.get_children():
			if bool(wheel.get_meta("traffic_wheel", false)):
				wheel.rotate_x(22.0 * delta)

	# 0.0–1.25: Red is thrown well ahead of the quad.
	if t < 1.25:
		if g.wolf != g.wolf_riding:
			g._set_active_wolf(g.wolf_riding)
		var p: float = clampf(t / 1.25, 0.0, 1.0)
		var arc: float = sin(p * PI) * 3.0
		g.wolf_riding.position = Vector3(0.0, 0.45 + arc, -2.6 - 8.4 * p)
		g.wolf_riding.rotation_degrees = Vector3(lerpf(0.0, -155.0, p), 180.0, lerpf(0.0, -14.0, p))
		_update_dust_motion(g, p)
	# 1.25–2.45: he stands up, turns toward the quad and dusts himself off.
	elif t < 2.45:
		if g.wolf != g.wolf_standing:
			g._set_active_wolf(g.wolf_standing)
		var stand_p: float = smoothstep(0.0, 1.0, (t - 1.25) / 1.2)
		g.wolf_standing.position = Vector3(0.0, 0.0, -11.0)
		g.wolf_standing.rotation_degrees = Vector3(0.0, lerpf(180.0, 0.0, stand_p), sin(stand_p * PI * 4.0) * 4.0)
		if g.wolf_head != null:
			g.wolf_head.rotation_degrees.y = sin(stand_p * PI * 5.0) * 18.0
		_animate_dusting(g, stand_p)
		_update_dust_motion(g, 1.0 - stand_p * 0.75)
	# 2.45–4.75: walk back toward the quad, facing it the whole time.
	elif t < 4.75:
		if g.wolf != g.wolf_standing:
			g._set_active_wolf(g.wolf_standing)
		var return_p: float = smoothstep(0.0, 1.0, (t - 2.45) / 2.3)
		g.wolf_standing.position = Vector3(0.0, sin(return_p * PI * 6.0) * 0.035, lerpf(-11.0, 0.0, return_p))
		g.wolf_standing.rotation_degrees = Vector3(0.0, 0.0, 0.0)
		if g.wolf_head != null:
			g.wolf_head.rotation_degrees.y = sin(return_p * PI * 5.0) * 4.0
		if g.scarf_tail != null:
			g.scarf_tail.rotation_degrees.z = g.scarf_base + sin(t * 8.0) * 5.0
		_update_dust_motion(g, 0.0)
	else:
		_settle_after_crash(g)

static func _animate_dusting(g: Node, p: float) -> void:
	# Use common arm node names when present; otherwise the body/head motion still reads as a dust-off gesture.
	var left_arm_names := ["LeftArm", "ArmLeft", "LeftArmPivot", "ArmL"]
	var right_arm_names := ["RightArm", "ArmRight", "RightArmPivot", "ArmR"]
	for node_name in left_arm_names:
		var arm_l := g.wolf_standing.find_child(node_name, true, false) as Node3D
		if arm_l != null:
			arm_l.rotation_degrees.z = -18.0 + sin(p * PI * 6.0) * 28.0
			break
	for node_name in right_arm_names:
		var arm_r := g.wolf_standing.find_child(node_name, true, false) as Node3D
		if arm_r != null:
			arm_r.rotation_degrees.z = 18.0 - sin(p * PI * 6.0) * 28.0
			break
	g.wolf_standing.rotation_degrees.z = sin(p * PI * 6.0) * 4.0

static func _update_dust_motion(g: Node, amount: float) -> void:
	if not "crash_dust" in g:
		return
	var center := g.player.global_position + Vector3(0, 0.12, -4.0)
	for i in g.crash_dust.size():
		var puff: Node3D = g.crash_dust[i]
		var phase: float = float(i) * 0.7
		puff.global_position = center + Vector3(cos(phase) * 1.2, 0.1 + float(i % 3) * 0.2, sin(phase) * 0.9) + Vector3(0, 0, -amount * 1.4)
		puff.scale = Vector3.ONE * (0.22 + amount * (1.15 + float(i % 3) * 0.22))

static func _settle_after_crash(g: Node) -> void:
	if g.wolf != g.wolf_riding:
		g._set_active_wolf(g.wolf_riding)
	g.wolf_riding.position = Vector3.ZERO
	g.wolf_riding.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	if g.crash_car != null and is_instance_valid(g.crash_car):
		var origin: Vector3 = g.crash_car.get_meta("crash_visual_origin", g.crash_car.position)
		var side: float = 1.0 if origin.x >= 0.0 else -1.0
		g.crash_car.position.x = side * 8.6
		g.crash_car.position.z = origin.z - 5.5
	g._clear_crash_dust()

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
		if g.crash_active and g.crash_time < 4.8:
			return
		g._reset_run()
		return
	if g.game_state != g.GameState.RUNNING:
		return
	if abs(difference.x) > g.SWIPE_THRESHOLD and abs(difference.x) > abs(difference.y):
		g.lane = clampi(g.lane + (1 if difference.x > 0 else -1), 0, 4)
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
	g.crash_active = false
	g.crash_time = 0.0
	g.crash_car = null
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
	g.ramp_lane = 2
	g.ramp_used = false
	g.ramp.position = Vector3(g.LANE_X[g.ramp_lane], 0.20, g.ramp_home.z)
	for index in g.pickups.size():
		g.pickups[index].position = g.pickup_homes[index]
		g.pickups[index].position.x = g.LANE_X[index % 5]
		g.pickups[index].visible = true
	for index in g.buildings.size():
		g.buildings[index].position = g.building_homes[index]
	for index in g.props.size():
		g.props[index].position = g.prop_homes[index]
	for index in g.traffic.size():
		g.traffic[index].position = g.traffic_homes[index]
		g.traffic[index].set_meta("lane", g.traffic_home_lanes[index])
		g.traffic[index].set_meta("target_lane", g.traffic_home_lanes[index])
	g._enter_roadside_idle()
