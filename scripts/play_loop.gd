class_name PlayLoop
extends RefCounted


static func animate_wolf(g: Node) -> void:
	if g.wolf == null:
		return
	var delta: float = g.get_physics_process_delta_time()
	if g.game_state == g.GameState.ROADSIDE_IDLE:
		g.wolf.position.y = sin(g.elapsed_time * 1.55) * 0.028
		g.wolf.rotation_degrees.z = sin(g.elapsed_time * 0.55) * 1.8
		g.wolf.rotation_degrees.x = sin(g.elapsed_time * 0.8) * 1.2
		g.look_yaw = lerpf(g.look_yaw, sin(g.elapsed_time * 0.35) * 16.0 + sin(g.elapsed_time * 0.11) * 8.0, min(1.0, delta * 2.4))
		g.look_pitch = lerpf(g.look_pitch, sin(g.elapsed_time * 0.7) * 3.5, min(1.0, delta * 3.0))
	else:
		g.look_yaw = lerpf(g.look_yaw, clampf(-g.steer_visual * 0.55, -18.0, 18.0), min(1.0, delta * 6.0))
		g.look_pitch = lerpf(g.look_pitch, 4.0 if g.jumping else sin(g.elapsed_time * 9.0) * 1.4, min(1.0, delta * 6.0))
		if g.game_state == g.GameState.RUNNING:
			g.wolf.position.y = lerpf(g.wolf.position.y, sin(g.elapsed_time * 11.0) * 0.012, min(1.0, delta * 8.0))
		else:
			g.wolf.position.y = lerpf(g.wolf.position.y, 0.0, min(1.0, delta * 8.0))
	if g.wolf_head != null:
		g.wolf_head.rotation_degrees.y = g.look_yaw
		g.wolf_head.rotation_degrees.x = g.look_pitch
	if g.scarf_tail != null:
		var wind := 14.0 if g.game_state == g.GameState.RUNNING else 7.0
		g.scarf_tail.rotation_degrees.z = g.scarf_base + sin(g.elapsed_time * wind) * (12.0 if g.boost_remaining > 0.0 else 7.0)
		g.scarf_tail.rotation_degrees.x = sin(g.elapsed_time * (wind * 0.65)) * 5.0


static func update_mounting(g: Node, delta: float) -> void:
	g.transition_time += delta
	var t: float = clampf(g.transition_time / 0.85, 0.0, 1.0)
	if t < 0.42:
		var mount_phase: float = smoothstep(0.0, 0.42, t)
		g.wolf_standing.position = Vector3(-1.55, 0, 0.22).lerp(Vector3(-0.45, 0.62, 0.02), mount_phase)
		g.wolf_standing.rotation_degrees.y = lerpf(-12.0, 8.0, mount_phase)
		g.wolf_standing.rotation_degrees.x = -sin(mount_phase * PI) * 22.0
		g.wolf_standing.rotation_degrees.z = sin(mount_phase * PI) * 6.0
	else:
		if g.wolf != g.wolf_riding:
			g._set_active_wolf(g.wolf_riding)
		var landing_phase: float = smoothstep(0.42, 1.0, t)
		g.wolf_riding.position = Vector3(0, 0.5, 0.0).lerp(Vector3(0, 0.02, 0), landing_phase)
		g.wolf_riding.rotation_degrees.x = -sin(landing_phase * PI) * 10.0
	if t >= 1.0:
		g.game_state = g.GameState.MERGING
		g.transition_time = 0.0
		g.wolf_riding.position = Vector3.ZERO
		g.wolf_riding.rotation_degrees = Vector3(0, 180, 0)
		g.title.visible = false
		g.prompt.visible = false


static func update_merging(g: Node, delta: float) -> void:
	g.transition_time += delta
	var t: float = clampf(g.transition_time / 1.15, 0.0, 1.0)
	g.player.position.x = lerpf(-4.2, 0.0, smoothstep(0.0, 1.0, t))
	g.vehicle_visual.rotation_degrees.z = -sin(t * PI) * 8.0
	if t >= 1.0:
		g.game_state = g.GameState.RUNNING
		g.vehicle_visual.rotation_degrees.z = 0.0
		g.hud.visible = true
		g._show_message("ПОЕХАЛИ!", 1.0)


static func update_running(g: Node, delta: float) -> void:
	var current_speed: float = g.BOOST_SPEED if g.boost_remaining > 0.0 else g.BASE_SPEED
	g.boost_remaining = max(0.0, g.boost_remaining - delta)
	g.distance += current_speed * delta
	g.score = int(g.distance) + g.trick_score
	scroll(g.buildings, 22.0, 156.0, current_speed * delta)
	scroll(g.props, 22.0, 168.0, current_speed * delta)
	g.ramp.position.z += current_speed * delta
	if g.ramp.position.z > 18.0:
		g.ramp.position.z = -118.0
		g.ramp_lane = g.rng.randi_range(0, 2)
		g.ramp.position.x = g.LANE_X[g.ramp_lane]
		g.ramp_used = false
	g._move_traffic(delta, current_speed * 0.72, true)
	g._update_world_shift(delta)
	g._update_jump(delta)
	for spin_pivot in g.wheel_spin_pivots:
		spin_pivot.rotate_x(current_speed * delta * 1.7)
	if not g.jumping:
		g.vehicle_visual.position.y = lerpf(g.vehicle_visual.position.y, sin(g.elapsed_time * current_speed * 0.55) * 0.018, min(1.0, delta * 10.0))
	g._update_camera(delta)
	g._update_hud(delta)


static func scroll(nodes: Array, front_z: float, recycle: float, step: float) -> void:
	for node in nodes:
		node.position.z += step
		if node.position.z > front_z:
			node.position.z -= recycle


static func move_traffic(g: Node, delta: float, movement_speed: float, check_collision: bool) -> void:
	for car in g.traffic:
		car.position.z += movement_speed * delta
		if car.position.z > 18.0:
			car.position.z -= 128.0
			var next_lane := g.rng.randi_range(0, 2)
			car.set_meta("lane", next_lane)
			car.position.x = g.LANE_X[next_lane]
		if check_collision and not g.jumping and int(car.get_meta("lane")) == g.lane and car.position.z > 1.8 and car.position.z < 5.7:
			g._game_over()
			return


static func update_world_shift(g: Node, delta: float) -> void:
	var target_x: float = -float(g.LANE_X[g.lane])
	var error: float = target_x - g.world_pivot.position.x
	g.world_pivot.position.x = lerpf(g.world_pivot.position.x, target_x, min(1.0, delta * 8.5))
	var desired_steer: float = clampf(-error / 3.5, -1.0, 1.0) * 26.0
	g.steer_visual = lerpf(g.steer_visual, desired_steer, min(1.0, delta * 11.0))
	if abs(error) < 0.03:
		g.steer_visual = lerpf(g.steer_visual, 0.0, min(1.0, delta * 10.0))
	for pivot in g.front_wheel_pivots:
		pivot.rotation_degrees.y = g.steer_visual
	g.vehicle_visual.rotation_degrees.z = -g.steer_visual * 0.16
	if g.wolf != null:
		g.wolf.rotation_degrees.z = -g.steer_visual * 0.28
