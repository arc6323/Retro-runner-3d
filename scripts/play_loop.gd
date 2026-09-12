class_name PlayLoop
extends RefCounted

const SPEED_MULTIPLIER := 3.0
const TRAFFIC_RAMP_CLEARANCE := 10.0
const RUN_START_GRACE := 1.35
const PICKUP_RECYCLE_Z := 24.0
const MAGNET_RANGE := 8.0
const FLIGHT_LANDING_INVULNERABILITY := 3.5

static func animate_wolf(g: Node) -> void:
	if g.wolf == null:
		return
	var delta: float = g.get_physics_process_delta_time()
	if g.game_state == g.GameState.ROADSIDE_IDLE:
		# Keep the parked quad centered; the standing wolf remains beside it.
		g.player.position = Vector3(0.0, 0.0, 4.0)
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
	var smooth_t: float = smoothstep(0.0, 1.0, t)
	# The quad is already centered before the start; only move it forward into the run.
	g.player.position.x = 0.0
	g.player.position.z = lerpf(4.0, 0.0, smooth_t)
	g.vehicle_visual.rotation_degrees.z = 0.0
	if t >= 1.0:
		g.player.position = Vector3(0.0, g.player.position.y, 0.0)
		g.game_state = g.GameState.RUNNING
		g.vehicle_visual.rotation_degrees.z = 0.0
		g.hud.visible = true
		g.set_meta("run_grace_remaining", RUN_START_GRACE)
		# Before start cars are side-only. From this moment they can use any of the three lanes.
		for car in g.traffic:
			var start_lane: int = g.rng.randi_range(0, 2)
			car.set_meta("lane", start_lane)
			car.set_meta("target_lane", start_lane)
			car.position.x = g.LANE_X[start_lane]

static func update_running(g: Node, delta: float) -> void:
	var speed_ramp: float = min(g.distance * 0.0025, 8.0)
	var normal_speed: float = g.BASE_SPEED + speed_ramp
	var boost_speed: float = g.BOOST_SPEED + min(g.distance * 0.002, 6.0)
	var current_speed: float = (boost_speed if g.boost_remaining > 0.0 else normal_speed) * SPEED_MULTIPLIER
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
		g.ramp_lane = g.rng.randi_range(0, 2)
		g.ramp.position.x = g.LANE_X[g.ramp_lane]
		g.ramp_used = false
	_update_pickups(g, delta, current_speed)
	g._move_traffic(delta, current_speed * 0.72, true)
	if g.flight_remaining > 0.0:
		g.player.position.y = lerpf(g.player.position.y, 2.8, min(1.0, delta * 7.0))
	elif not g.jumping and g.player.position.y > 0.0:
		g.player.position.y = lerpf(g.player.position.y, 0.0, min(1.0, delta * 8.0))
	g._update_world_shift(delta)
	g.vehicle_visual.rotation_degrees.z = 0.0
	if g.wolf != null and not g.jumping:
		g.wolf.rotation_degrees.z = 0.0
	var trick_before_jump: bool = g.trick_requested
	g._update_jump(delta)
	if g.jumping and not trick_before_jump:
		g.trick_angle = 0.0
		g.vehicle_visual.rotation_degrees.x = 0.0
		g.wolf.rotation_degrees.x = 0.0
	_update_powerup_visuals(g, delta)
	for spin_pivot in g.wheel_spin_pivots:
		spin_pivot.rotate_x(current_speed * delta * 1.7)
	if not g.jumping and g.flight_remaining <= 0.0:
		g.vehicle_visual.position.y = lerpf(g.vehicle_visual.position.y, sin(g.elapsed_time * current_speed * 0.55) * 0.018, min(1.0, delta * 10.0))
	g._update_camera(delta)
	g.message_time = 0.0
	g._update_hud(delta)

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
			pickup.position.x = g.LANE_X[g.rng.randi_range(0, 2)]

static func _collect_pickup(g: Node, index: int) -> void:
	var pickup: Node3D = g.pickups[index]
	var pickup_type: String = g.pickup_types[index]
	pickup.position = g.pickup_homes[index]
	pickup.position.x = g.LANE_X[g.rng.randi_range(0, 2)]
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
	if wing_r != null:
		wing_r.visible = flight_on
	if exhaust != null:
		exhaust.visible = flight_on
		if flight_on:
			exhaust.scale = Vector3(1.0, 1.0, 1.0 + sin(g.elapsed_time * 28.0) * 0.28)

static func scroll(nodes: Array, front_z: float, recycle: float, step: float) -> void:
	for node in nodes:
		node.position.z += step
		if node.position.z > front_z:
			node.position.z -= recycle

static func _choose_safe_traffic_lane(g: Node, current_lane: int) -> int:
	var candidates: Array[int] = [0, 2]
	if g.ramp_lane == 0:
		candidates = [2]
	elif g.ramp_lane == 2:
		candidates = [0]
	if candidates.is_empty():
		return current_lane
	if candidates.has(g.lane) and candidates.size() > 1:
		for candidate in candidates:
			if candidate != g.lane:
				return candidate
	return candidates[0]

static func move_traffic(g: Node, delta: float, movement_speed: float, check_collision: bool) -> void:
	for car in g.traffic:
		var car_lane: int = int(car.get_meta("lane", 0))
		if g.game_state != g.GameState.RUNNING and car_lane == 1:
			car_lane = _choose_safe_traffic_lane(g, car_lane)
		if g.game_state != g.GameState.RUNNING and abs(car.position.z - g.ramp.position.z) < TRAFFIC_RAMP_CLEARANCE and car_lane == g.ramp_lane:
			car_lane = _choose_safe_traffic_lane(g, car_lane)
		car.set_meta("lane", car_lane)
		car.set_meta("target_lane", car_lane)
		car.position.x = g.LANE_X[car_lane]

		car.position.z += movement_speed * delta
		if car.position.z > 18.0:
			car.position.z -= 128.0
			car_lane = g.rng.randi_range(0, 2) if g.game_state == g.GameState.RUNNING else (0 if g.rng.randi_range(0, 1) == 0 else 2)
			car.set_meta("lane", car_lane)
			car.set_meta("target_lane", car_lane)

		var target_x: float = float(g.LANE_X[car_lane])
		car.position.x = lerpf(car.position.x, target_x, min(1.0, delta * 5.5))
		car.rotation_degrees.y = lerpf(car.rotation_degrees.y, clampf((target_x - car.position.x) * -7.0, -18.0, 18.0), min(1.0, delta * 6.0))
		for wheel in car.get_children():
			if bool(wheel.get_meta("traffic_wheel", false)):
				wheel.rotate_x(movement_speed * delta * 1.9)

		var grace: float = float(g.get_meta("run_grace_remaining", 0.0))
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
	g.vehicle_visual.rotation_degrees.z = 0.0
	if g.wolf != null:
		g.wolf.rotation_degrees.z = 0.0
