class_name PlayLoop
extends RefCounted

const SPEED_MULTIPLIER := 3.0
const TRAFFIC_RAMP_CLEARANCE := 10.0
const TRAFFIC_OBSTACLE_CLEARANCE := 8.0
const RUN_START_GRACE := 3.0
const PICKUP_RECYCLE_Z := 24.0
const MAGNET_RANGE := 8.0
const FLIGHT_LANDING_INVULNERABILITY := 3.5
const RAMP_HALF_LENGTH := 4.1
const RAMP_TOP_Y := 0.59
const RAMP_ANGLE_DEG := 11.0
const RAMP_PLAYER_Y_OFFSET := 0.0

static func animate_wolf(g: Node) -> void:
	if g.wolf == null:
		return
	var delta: float = g.get_physics_process_delta_time()
	if g.game_state == g.GameState.ROADSIDE_IDLE:
		g.player.position = Vector3(0.0, 0.0, 4.0)
		g.wolf.position.y = sin(g.elapsed_time * 1.55) * 0.028
		g.wolf.rotation_degrees.z = sin(g.elapsed_time * 0.55) * 1.8
		g.wolf.rotation_degrees.x = sin(g.elapsed_time * 0.8) * 1.2
		g.look_yaw = lerpf(g.look_yaw, sin(g.elapsed_time * 0.35) * 16.0 + sin(g.elapsed_time * 0.11) * 8.0, min(1.0, delta * 2.4))
		g.look_pitch = lerpf(g.look_pitch, sin(g.elapsed_time * 0.7) * 3.5, min(1.0, delta * 3.0))
	elif g.game_state == g.GameState.GAME_OVER and g.crash_active:
		return
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
	var smooth_t: float = smoothstep(0.0, 1.0, t)
	g.player.position.x = 0.0
	g.player.position.z = lerpf(4.0, 0.0, smooth_t)
	g.vehicle_visual.rotation_degrees.z = 0.0
	if t >= 1.0:
		g.player.position = Vector3(0.0, g.player.position.y, 0.0)
		g.game_state = g.GameState.RUNNING
		g.vehicle_visual.rotation_degrees.z = 0.0
		g.hud.visible = true
		g.set_meta("run_grace_remaining", RUN_START_GRACE)
		for car in g.traffic:
			var start_lane: int = 0 if g.rng.randi_range(0, 1) == 0 else 4
			car.set_meta("lane", start_lane)
			car.set_meta("target_lane", start_lane)
			car.position.x = g.LANE_X[start_lane]

static func update_running(g: Node, delta: float) -> void:
	var speed_ramp: float = min(g.distance * 0.0025, 8.0)
	var normal_speed: float = g.BASE_SPEED + speed_ramp
	var boost_speed: float = g.BOOST_SPEED + min(g.distance * 0.002, 6.0)
	var current_speed: float = (boost_speed if g.boost_remaining > 0.0 else normal_speed) * SPEED_MULTIPLIER
	g.set_meta("current_speed_kmh", current_speed * 3.6)
	var was_flying: bool = g.flight_remaining > 0.0
	g.boost_remaining = max(0.0, g.boost_remaining - delta)
	g.shield_remaining = max(0.0, g.shield_remaining - delta)
	g.magnet_remaining = max(0.0, g.magnet_remaining - delta)
	g.flight_remaining = max(0.0, g.flight_remaining - delta)
	g.flight_invulnerability_remaining = max(0.0, g.flight_invulnerability_remaining - delta)
	if was_flying and g.flight_remaining <= 0.0:
		g.flight_invulnerability_remaining = FLIGHT_LANDING_INVULNERABILITY
	var grace: float = float(g.get_meta("run_grace_remaining", 0.0))
	if grace > 0.0:
		g.set_meta("run_grace_remaining", max(0.0, grace - delta))
	g.distance += current_speed * delta
	g.score = int(g.distance) + g.trick_score + g.coins * 5
	scroll(g.buildings, 22.0, 156.0, current_speed * delta)
	scroll(g.props, 22.0, 168.0, current_speed * delta)
	g.ramp.position.z += current_speed * delta
	if g.ramp.position.z > 18.0:
		g.ramp.position.z = -118.0
		g.ramp_lane = g.rng.randi_range(0, 4)
		g.ramp.position.x = g.LANE_X[g.ramp_lane]
		g.ramp_used = false
	_update_pickups(g, delta, current_speed)
	g._move_traffic(delta, current_speed * 0.72, true)
	_update_ramp_and_jump(g, delta)
	if g.flight_remaining > 0.0:
		g.player.position.y = lerpf(g.player.position.y, 2.8, min(1.0, delta * 7.0))
	elif not g.jumping and not _ramp_under_player(g) and g.player.position.y > 0.0:
		g.player.position.y = lerpf(g.player.position.y, 0.0, min(1.0, delta * 8.0))
	g._update_world_shift(delta)
	g.vehicle_visual.rotation_degrees.z = 0.0
	if g.wolf != null and not g.jumping:
		g.wolf.rotation_degrees.z = 0.0
	_update_powerup_visuals(g, delta)
	for spin_pivot in g.wheel_spin_pivots:
		spin_pivot.rotate_x(current_speed * delta * 1.7)
	if not g.jumping and g.flight_remaining <= 0.0 and not _ramp_under_player(g):
		g.vehicle_visual.position.y = lerpf(g.vehicle_visual.position.y, sin(g.elapsed_time * current_speed * 0.55) * 0.018, min(1.0, delta * 10.0))
	g._update_camera(delta)
	g.message_time = 0.0
	g._update_hud(delta)

static func _update_ramp_and_jump(g: Node, delta: float) -> void:
	if g.flight_remaining > 0.0:
		g.ramp_used = true
		g.jumping = false
		g.jump_velocity = 0.0
		g.trick_requested = false
		g.vehicle_visual.rotation_degrees.x = 0.0
		g.wolf.rotation_degrees.x = 0.0
		return

	if g.jumping:
		g.jump_velocity -= g.jump_gravity * delta
		g.player.position.y += g.jump_velocity * delta
		if g.trick_requested:
			g.trick_angle += 560.0 * delta
			g.vehicle_visual.rotation_degrees.x = g.trick_angle
			g.wolf.rotation_degrees.x = g.trick_angle * 0.92
		else:
			g.trick_angle = 0.0
			g.vehicle_visual.rotation_degrees.x = 0.0
			g.wolf.rotation_degrees.x = 0.0
		if g.player.position.y <= 0.0 and g.jump_velocity < 0.0:
			g.player.position.y = 0.0
			g.jumping = false
			g.jump_velocity = 0.0
			g.vehicle_visual.rotation_degrees.x = 0.0
			g.wolf.rotation_degrees.x = 0.0
			g.camera_shake = 0.55 if g.trick_requested else 0.35
			if g.trick_requested:
				g.trick_score += g.TRICK_BONUS
			g.trick_requested = false
		return

	if not _ramp_under_player(g) or g.lane != g.ramp_lane:
		return

	var local_z: float = g.player.position.z - g.ramp.position.z
	var angle_rad: float = deg_to_rad(RAMP_ANGLE_DEG)
	var surface_y: float = g.ramp.position.y + RAMP_TOP_Y * cos(angle_rad) + local_z * sin(angle_rad)
	g.player.position.y = max(0.0, surface_y + RAMP_PLAYER_Y_OFFSET)
	g.vehicle_visual.rotation_degrees.x = RAMP_ANGLE_DEG
	g.wolf.rotation_degrees.x = RAMP_ANGLE_DEG * 0.92

	if local_z >= 2.7 and not g.ramp_used:
		g.ramp_used = true
		g.jumping = true
		g.jump_velocity = 14.5
		g.trick_angle = 0.0
		g.player.position.y = max(g.player.position.y, 0.28)
		g.vehicle_visual.rotation_degrees.x = 0.0
		g.wolf.rotation_degrees.x = 0.0

static func _ramp_under_player(g: Node) -> bool:
	if g.ramp == null or g.lane != g.ramp_lane:
		return false
	var local_z: float = g.player.position.z - g.ramp.position.z
	return local_z > -RAMP_HALF_LENGTH - 0.45 and local_z < RAMP_HALF_LENGTH + 0.45

static func _update_pickups(g: Node, delta: float, current_speed: float) -> void:
	var player_local_x: float = -g.world_pivot.position.x
	var player_z: float = g.player.position.z
	for index in g.pickups.size():
		var pickup: Node3D = g.pickups[index]
		if not pickup.visible:
			continue
		var pickup_type: String = g.pickup_types[index]
		if g.magnet_remaining > 0.0 and pickup_type == "coin":
			var distance_to_player: float = Vector2(pickup.position.x - player_local_x, pickup.position.z - player_z).length()
			if distance_to_player < MAGNET_RANGE:
				pickup.position.x = lerpf(pickup.position.x, player_local_x, min(1.0, delta * 8.0))
				pickup.position.z = lerpf(pickup.position.z, player_z, min(1.0, delta * 8.0))
			pickup.position.z += current_speed * delta
		var hit_distance: float = Vector2(pickup.position.x - player_local_x, pickup.position.z - player_z).length()
		if hit_distance < (1.15 if pickup_type == "coin" else 1.45) and abs(pickup.position.y - g.player.position.y) < 2.0:
			_collect_pickup(g, index)
			continue
		if pickup.position.z > PICKUP_RECYCLE_Z:
			pickup.position = g.pickup_homes[index]
			pickup.position.x = g.LANE_X[g.rng.randi_range(0, 4)]

static func _collect_pickup(g: Node, index: int) -> void:
	var pickup: Node3D = g.pickups[index]
	var pickup_type: String = g.pickup_types[index]
	pickup.position = g.pickup_homes[index]
	pickup.position.x = g.LANE_X[g.rng.randi_range(0, 4)]
	if pickup_type == "coin":
		g.coins += 1
	elif pickup_type == "shield":
		g.shield_remaining = 7.0
	elif pickup_type == "magnet":
		g.magnet_remaining = 7.0
	elif pickup_type == "boost":
		g.boost_remaining = 2.5
	elif pickup_type == "flight":
		g.ramp_used = true
		g.flight_remaining = 4.5
		g.flight_invulnerability_remaining = 0.0
		g.jumping = false
		g.jump_velocity = 0.0
		g.trick_requested = false
		g.vehicle_visual.rotation_degrees.x = 0.0
		g.wolf.rotation_degrees.x = 0.0
		g.player.position.y = 2.8

static func _update_powerup_visuals(g: Node, delta: float) -> void:
	for index in g.pickups.size():
		var pickup: Node3D = g.pickups[index]
		if pickup == null:
			continue
		pickup.rotation_degrees.y += 110.0 * delta
		pickup.position.y = (0.9 if g.pickup_types[index] == "coin" else 1.05) + sin(g.elapsed_time * 4.0 + float(index)) * 0.08
	var wing_l: Node3D = g.player.get_node_or_null("FlightFX/WingLeft") as Node3D
	var wing_r: Node3D = g.player.get_node_or_null("FlightFX/WingRight") as Node3D
	var exhaust: Node3D = g.player.get_node_or_null("FlightFX/Exhaust") as Node3D
	var flight_on: bool = g.flight_remaining > 0.0
	if wing_l != null:
		wing_l.visible = flight_on
		wing_l.scale = Vector3.ONE * 0.58
	if wing_r != null:
		wing_r.visible = flight_on
		wing_r.scale = Vector3.ONE * 0.58
	if exhaust != null:
		exhaust.visible = flight_on
		exhaust.scale = Vector3(0.62, 0.62, 0.62 + (sin(g.elapsed_time * 28.0) * 0.08 if flight_on else 0.0))

static func scroll(nodes: Array, front_z: float, recycle: float, step: float) -> void:
	for node in nodes:
		node.position.z += step
		if node.position.z > front_z:
			node.position.z -= recycle

static func _choose_safe_traffic_lane(g: Node, current_lane: int) -> int:
	var candidates: Array[int] = []
	if current_lane > 0:
		candidates.append(current_lane - 1)
	if current_lane < 4:
		candidates.append(current_lane + 1)
	if abs(g.ramp.position.z - 0.0) < TRAFFIC_RAMP_CLEARANCE:
		if candidates.has(g.ramp_lane):
			candidates.erase(g.ramp_lane)
	if candidates.is_empty():
		return current_lane
	return candidates[g.rng.randi_range(0, candidates.size() - 1)]

static func _lane_is_blocked(g: Node, lane_index: int, z_pos: float, self_car: Node3D) -> bool:
	for other in g.traffic:
		if other == self_car:
			continue
		var other_lane: int = int(other.get_meta("target_lane", other.get_meta("lane", 0)))
		if other_lane == lane_index and abs(other.position.z - z_pos) < TRAFFIC_OBSTACLE_CLEARANCE:
			return true
	return false

static func _avoid_traffic_obstacles(g: Node, car: Node3D, car_lane: int) -> int:
	var candidates: Array[int] = []
	if car_lane > 0:
		candidates.append(car_lane - 1)
	if car_lane < 4:
		candidates.append(car_lane + 1)
	if abs(car.position.z - g.ramp.position.z) < TRAFFIC_RAMP_CLEARANCE and candidates.has(g.ramp_lane):
		candidates.erase(g.ramp_lane)
	for candidate in candidates:
		if not _lane_is_blocked(g, candidate, car.position.z, car):
			return candidate
	return car_lane

static func move_traffic(g: Node, delta: float, movement_speed: float, check_collision: bool) -> void:
	var grace: float = float(g.get_meta("run_grace_remaining", 0.0))
	for car in g.traffic:
		var car_lane: int = int(car.get_meta("lane", 0))
		if g.game_state != g.GameState.RUNNING:
			if car_lane == 1 or car_lane == 2 or car_lane == 3:
				car_lane = 0 if g.rng.randi_range(0, 1) == 0 else 4
			if abs(car.position.z - g.ramp.position.z) < TRAFFIC_RAMP_CLEARANCE and car_lane == g.ramp_lane:
				car_lane = _choose_safe_traffic_lane(g, car_lane)
		else:
			if grace > 0.0 and car_lane != 0 and car_lane != 4:
				car_lane = _choose_safe_traffic_lane(g, car_lane)
			if abs(car.position.z - g.ramp.position.z) < TRAFFIC_RAMP_CLEARANCE and car_lane == g.ramp_lane:
				car_lane = _avoid_traffic_obstacles(g, car, car_lane)
			if _lane_is_blocked(g, car_lane, car.position.z, car):
				car_lane = _avoid_traffic_obstacles(g, car, car_lane)

		car.set_meta("lane", car_lane)
		car.set_meta("target_lane", car_lane)
		car.position.z += movement_speed * delta
		if car.position.z > 18.0:
			car.position.z -= 128.0
			car_lane = g.rng.randi_range(0, 4) if g.game_state == g.GameState.RUNNING and grace <= 0.0 else (0 if g.rng.randi_range(0, 1) == 0 else 4)
			car.set_meta("lane", car_lane)
			car.set_meta("target_lane", car_lane)

		var target_x: float = float(g.LANE_X[car_lane])
		car.position.x = lerpf(car.position.x, target_x, min(1.0, delta * 5.5))
		car.rotation_degrees.y = lerpf(car.rotation_degrees.y, clampf((target_x - car.position.x) * -7.0, -18.0, 18.0), min(1.0, delta * 6.0))
		for wheel in car.get_children():
			if bool(wheel.get_meta("traffic_wheel", false)):
				wheel.rotate_x(movement_speed * delta * 1.9)

		if check_collision and grace <= 0.0 and g.flight_remaining <= 0.0 and g.flight_invulnerability_remaining <= 0.0 and not g.jumping:
			var player_pos: Vector3 = g.player.global_position
			var car_pos: Vector3 = car.global_position
			var horizontal_distance: float = Vector2(player_pos.x - car_pos.x, player_pos.z - car_pos.z).length()
			var vertical_distance: float = abs(player_pos.y - car_pos.y)
			if horizontal_distance < 1.55 and vertical_distance < 1.35:
				if g.shield_remaining > 0.0:
					g.shield_remaining = 0.0
					g.camera_shake = 0.8
				else:
					g._game_over(car)
				return

static func update_crash(g: Node, delta: float) -> void:
	if not g.crash_active:
		return
	g.crash_time += delta
	var t: float = clampf(g.crash_time / 1.15, 0.0, 1.0)
	var eased: float = smoothstep(0.0, 1.0, t)
	g.vehicle_visual.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	if g.wolf_riding != null:
		g.wolf_riding.position = Vector3(0.0, lerpf(0.02, -0.18, eased), lerpf(0.0, -1.55, eased))
		g.wolf_riding.rotation_degrees = Vector3(lerpf(0.0, -78.0, eased), 180.0, lerpf(0.0, -8.0, eased))
	if g.crash_car != null:
		g.crash_car.position.z += lerpf(0.8, 2.8, eased) * delta
		g.crash_car.rotation_degrees.x += 520.0 * delta
		g.crash_car.rotation_degrees.z = sin(g.crash_time * 9.0) * 18.0
		for wheel in g.crash_car.get_children():
			if bool(wheel.get_meta("traffic_wheel", false)):
				wheel.rotate_x(18.0 * delta)
	g.camera_shake = max(g.camera_shake, 0.18 * (1.0 - t))

static func update_world_shift(g: Node, delta: float) -> void:
	var target_x: float = -float(g.LANE_X[g.lane])
	var error: float = target_x - g.world_pivot.position.x
	g.world_pivot.position.x = lerpf(g.world_pivot.position.x, target_x, min(1.0, delta * 8.5))
	var lane_step := 2.3
	var desired_steer: float = clampf(-error / lane_step, -1.0, 1.0) * 26.0
	g.steer_visual = lerpf(g.steer_visual, desired_steer, min(1.0, delta * 11.0))
	if abs(error) < 0.03:
		g.steer_visual = lerpf(g.steer_visual, 0.0, min(1.0, delta * 10.0))
	for pivot in g.front_wheel_pivots:
		pivot.rotation_degrees.y = g.steer_visual
	g.vehicle_visual.rotation_degrees.z = 0.0
	if g.wolf != null:
		g.wolf.rotation_degrees.z = 0.0
