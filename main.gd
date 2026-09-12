extends GameBase

var garage_button: Button
var settings_button: Button
var garage_panel: Panel
var settings_panel: Panel
var sound_button: Button
var selected_character := 0
var selected_vehicle := 0
var sound_enabled := true
var crash_dust: Array[Node3D] = []

func _ready() -> void:
	rng.randomize()
	_load_high_score()
	EnvKit.attach(self)
	_create_world()
	_create_player()
	_create_camera()
	_create_interface()
	_hide_legacy_boost_pickups()
	_enter_roadside_idle()

func _hide_legacy_boost_pickups() -> void:
	for index in pickups.size():
		if pickup_types[index] == "boost":
			pickups[index].visible = false

func _create_camera() -> void:
	camera = Camera3D.new()
	camera.name = "CameraRig"
	camera.position = CAMERA_IDLE * 1.8
	camera.fov = 62.0
	camera.near = 0.12
	camera.far = 260.0
	camera.current = true
	add_child(camera)
	camera.look_at(player.position + Vector3(0, 1.5, 0), Vector3.UP)

func _create_interface() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	title = Label.new()
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 96
	title.offset_bottom = 260
	title.offset_left = 24
	title.offset_right = -24
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.text = "НЕОНОВАЯ\nПУСТОШЬ"
	title.visible = false
	root.add_child(title)
	prompt = Label.new()
	prompt.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_top = -180
	prompt.offset_bottom = -70
	prompt.offset_left = 28
	prompt.offset_right = -28
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.text = ""
	prompt.visible = false
	root.add_child(prompt)
	garage_button = _make_menu_button("ГАРАЖ", 0)
	root.add_child(garage_button)
	garage_button.pressed.connect(_open_garage)
	settings_button = _make_menu_button("⚙ НАСТРОЙКИ", 1)
	root.add_child(settings_button)
	settings_button.pressed.connect(_open_settings)
	hud = Label.new()
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_left = 18
	hud.offset_right = -18
	hud.offset_top = 82
	hud.offset_bottom = 158
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_theme_font_size_override("font_size", 27)
	hud.add_theme_color_override("font_color", Color(0.98, 0.98, 0.94))
	hud.visible = false
	root.add_child(hud)
	garage_panel = _build_simple_panel(root, "ГАРАЖ", "РЭД\nДОСТУПЕН")
	settings_panel = _build_simple_panel(root, "НАСТРОЙКИ", "ЗВУК: ВКЛ\n\nСвайп ← → — 5 полос\nСвайп вверх — прыжок / трюк\nТап — трюк")

func _make_menu_button(text_value: String, side: int) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 20)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT if side == 0 else Control.PRESET_BOTTOM_RIGHT)
	button.offset_top = -270
	button.offset_bottom = -205
	button.offset_left = 28 if side == 0 else -218
	button.offset_right = 218 if side == 0 else -28
	return button

func _build_simple_panel(parent: Control, heading: String, body: String) -> Panel:
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -290
	panel.offset_top = -260
	panel.offset_right = 290
	panel.offset_bottom = 260
	panel.z_index = 20
	panel.visible = false
	parent.add_child(panel)
	var label := Label.new()
	label.position = Vector2(30, 35)
	label.size = Vector2(520, 330)
	label.text = heading + "\n\n" + body
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	panel.add_child(label)
	var close := Button.new()
	close.position = Vector2(180, 390)
	close.size = Vector2(220, 70)
	close.text = "ЗАКРЫТЬ"
	close.pressed.connect(_close_menus)
	panel.add_child(close)
	return panel

func _open_garage() -> void:
	if game_state == GameState.ROADSIDE_IDLE:
		garage_panel.visible = true
		settings_panel.visible = false

func _open_settings() -> void:
	if game_state == GameState.ROADSIDE_IDLE:
		settings_panel.visible = true
		garage_panel.visible = false

func _close_menus() -> void:
	garage_panel.visible = false
	settings_panel.visible = false

func _select_red() -> void:
	selected_character = 0

func _select_quad() -> void:
	selected_vehicle = 0

func _toggle_sound() -> void:
	sound_enabled = not sound_enabled

func _update_sound_button() -> void:
	if sound_button != null:
		sound_button.text = "ЗВУК: ВКЛ" if sound_enabled else "ЗВУК: ВЫКЛ"

func _enter_roadside_idle() -> void:
	game_state = GameState.ROADSIDE_IDLE
	transition_time = 0.0
	lane = 2
	world_pivot.position.x = 0.0
	player.position = Vector3(0.0, 0.0, 4.0)
	vehicle_visual.rotation_degrees = Vector3(0, 180, 0)
	vehicle_visual.position = Vector3.ZERO
	_set_active_wolf(wolf_standing)
	wolf.position = Vector3(-1.55, 0, 0.22)
	wolf.rotation_degrees = Vector3(0, -12, 0)
	wolf_riding.position = Vector3.ZERO
	wolf_riding.rotation_degrees = Vector3(0, 180, 0)
	crash_active = false
	crash_time = 0.0
	crash_car = null
	_clear_crash_dust()
	title.visible = false
	prompt.visible = false
	garage_button.visible = true
	settings_button.visible = true
	hud.visible = false
	garage_panel.visible = false
	settings_panel.visible = false

func _begin_start_sequence() -> void:
	if game_state != GameState.ROADSIDE_IDLE:
		return
	_close_menus()
	game_state = GameState.MOUNTING
	transition_time = 0.0
	garage_button.visible = false
	settings_button.visible = false

func _physics_process(delta: float) -> void:
	elapsed_time += delta
	camera_shake = max(0.0, camera_shake - delta * 3.6)
	PlayLoop.animate_wolf(self)
	if game_state == GameState.PAUSED:
		return
	if game_state == GameState.ROADSIDE_IDLE:
		_move_traffic(delta, 18.6, false)
		_update_camera(delta)
		return
	if game_state == GameState.MOUNTING:
		_update_mounting(delta)
		_move_traffic(delta, 18.6, false)
		_update_camera(delta)
		return
	if game_state == GameState.MERGING:
		_update_merging(delta)
		_move_traffic(delta, 25.2, false)
		_update_camera(delta)
		return
	if game_state == GameState.GAME_OVER:
		_update_crash_sequence(delta)
		_update_camera(delta)
		return
	_update_running(delta)

func _update_mounting(delta: float) -> void:
	PlayLoop.update_mounting(self, delta)

func _update_merging(delta: float) -> void:
	# Keep the traffic that was already on the road before start; do not teleport it at RUNNING.
	transition_time += delta
	var t: float = clampf(transition_time / 1.15, 0.0, 1.0)
	var smooth_t: float = smoothstep(0.0, 1.0, t)
	player.position.x = 0.0
	player.position.z = lerpf(4.0, 0.0, smooth_t)
	vehicle_visual.rotation_degrees.z = 0.0
	if t >= 1.0:
		player.position = Vector3(0.0, player.position.y, 0.0)
		game_state = GameState.RUNNING
		vehicle_visual.rotation_degrees.z = 0.0
		hud.visible = true
		set_meta("run_grace_remaining", 3.0)

func _update_running(delta: float) -> void:
	PlayLoop.update_running(self, delta)

func _move_traffic(delta: float, movement_speed: float, check_collision: bool) -> void:
	PlayLoop.move_traffic(self, delta, movement_speed, check_collision)

func _update_world_shift(delta: float) -> void:
	PlayLoop.update_world_shift(self, delta)

func _update_jump(delta: float) -> void:
	PlayLoop._update_ramp_and_jump(self, delta)

func _start_jump() -> void:
	if jumping or game_state != GameState.RUNNING:
		return
	jumping = true
	jump_velocity = 14.5
	player.position.y = 0.28
	trick_angle = 0.0
	ramp_used = true

func _try_player_jump() -> void:
	if jumping:
		trick_requested = true
		return
	if _ramp_is_close():
		_start_jump()

func _update_camera(delta: float) -> void:
	PlayAction.update_camera(self, delta)

func _ramp_is_close() -> bool:
	if ramp == null or ramp_used or lane != ramp_lane:
		return false
	return ramp.position.z + 4.0 > -11.0 and ramp.position.z + 4.0 < 5.0

func _update_hud(delta: float) -> void:
	message_time = max(0.0, message_time - delta)
	if message_time > 0.0:
		return
	var speed_kmh: int = int(round(float(get_meta("current_speed_kmh", 0.0))))
	hud.text = "🪙 %d      %.2f км      %d км/ч" % [coins, distance / 1000.0, speed_kmh]

func _show_message(text: String, duration: float) -> void:
	message_time = duration

func _game_over(hit_car: Node3D = null) -> void:
	if game_state == GameState.GAME_OVER:
		return
	game_state = GameState.GAME_OVER
	crash_active = true
	crash_time = 0.0
	crash_car = hit_car
	jumping = false
	jump_velocity = 0.0
	vehicle_visual.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	camera_shake = 0.8
	_create_crash_dust()
	_save_high_score()
	Input.vibrate_handheld(90)
	hud.text = "🪙 %d      %.2f км      %d км/ч" % [coins, distance / 1000.0, int(round(float(get_meta("current_speed_kmh", 0.0))))]

func _create_crash_dust() -> void:
	_clear_crash_dust()
	for i in range(8):
		var puff := MeshKit.cylinder(0.16 + float(i % 3) * 0.06, 0.10 + float(i % 2) * 0.04, Vector3.ZERO, Color(0.48, 0.42, 0.34))
		puff.name = "CrashDust_%02d" % i
		puff.rotation_degrees.x = 90.0
		puff.scale = Vector3.ONE * 0.25
		world_pivot.add_child(puff)
		crash_dust.append(puff)

func _clear_crash_dust() -> void:
	for puff in crash_dust:
		if is_instance_valid(puff):
			puff.queue_free()
	crash_dust.clear()

func _update_crash_dust(t: float) -> void:
	var center := player.global_position + Vector3(0, 0.12, -2.6)
	for i in crash_dust.size():
		var puff: Node3D = crash_dust[i]
		var phase: float = float(i) * 0.7
		var spread := Vector3(cos(phase) * 1.1, 0.15 + float(i % 3) * 0.18, sin(phase) * 0.8)
		puff.global_position = center + spread + Vector3(0, 0, -t * 1.4)
		puff.scale = Vector3.ONE * (0.25 + t * (1.25 + float(i % 3) * 0.25))

func _update_crash_sequence(delta: float) -> void:
	if not crash_active:
		return
	crash_time += delta
	var t: float = crash_time
	# Red starts outside the quad immediately, then is launched far forward.
	if t < 1.15:
		if wolf != wolf_riding:
			_set_active_wolf(wolf_riding)
		var p: float = clampf(t / 1.15, 0.0, 1.0)
		var arc: float = sin(p * PI) * 2.8
		wolf_riding.position = Vector3(0.0, 0.55 + arc, -1.8 - 7.2 * p)
		wolf_riding.rotation_degrees = Vector3(lerpf(0.0, -150.0, p), 180.0, lerpf(0.0, -18.0, p))
		_update_crash_dust(p * 0.55)
	elif t < 2.25:
		if wolf != wolf_standing:
			_set_active_wolf(wolf_standing)
		var stand_p: float = smoothstep(0.0, 1.0, (t - 1.15) / 1.10)
		wolf_standing.position = Vector3(0.0, 0.0, -9.0)
		wolf_standing.rotation_degrees = Vector3(0.0, 180.0, sin(stand_p * PI * 2.0) * 7.0)
		if wolf_head != null:
			wolf_head.rotation_degrees.y = sin(stand_p * PI * 4.0) * 12.0
		_update_crash_dust(0.8 - stand_p * 0.8)
	elif t < 4.25:
		if wolf != wolf_standing:
			_set_active_wolf(wolf_standing)
		var return_p: float = smoothstep(0.0, 1.0, (t - 2.25) / 2.0)
		wolf_standing.position = Vector3(0.0, 0.0, lerpf(-9.0, 0.0, return_p))
		wolf_standing.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		_update_crash_dust(0.0)
	else:
		_set_active_wolf(wolf_riding)
		wolf_riding.position = Vector3.ZERO
		wolf_riding.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		_clear_crash_dust()
	# The collision car is launched forward and spins around the vertical axis.
	if crash_car != null and is_instance_valid(crash_car):
		var car_p: float = clampf(t / 1.45, 0.0, 1.0)
		crash_car.position.z -= lerpf(3.5, 7.0, car_p) * delta
		crash_car.rotation_degrees.y += 760.0 * delta
		crash_car.rotation_degrees.x = sin(t * 7.0) * 10.0 * (1.0 - car_p)
		crash_car.rotation_degrees.z = sin(t * 8.0) * 8.0 * (1.0 - car_p)
		for wheel in crash_car.get_children():
			if bool(wheel.get_meta("traffic_wheel", false)):
				wheel.rotate_x(26.0 * delta)
	camera_shake = max(camera_shake, 0.22 * max(0.0, 1.0 - min(t, 1.0)))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and game_state in [GameState.RUNNING, GameState.PAUSED]:
		game_state = GameState.RUNNING if game_state == GameState.PAUSED else GameState.PAUSED
		return
	if event.is_action_pressed("restart"):
		_reset_run()
		return
	if event.is_action_pressed("move_left") and game_state == GameState.RUNNING:
		lane = max(0, lane - 1)
		return
	if event.is_action_pressed("move_right") and game_state == GameState.RUNNING:
		lane = min(4, lane + 1)
		return
	if event.is_action_pressed("trick") and game_state == GameState.RUNNING:
		_try_player_jump()
		return
	if event is InputEventScreenTouch:
		_handle_pointer(event.position, event.pressed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(event.position, event.pressed)

func _handle_pointer(position: Vector2, pressed: bool) -> void:
	PlayAction.handle_pointer(self, position, pressed)

func _hero_was_tapped(screen_position: Vector2) -> bool:
	if camera.is_position_behind(wolf.global_position):
		return false
	var hero_point := camera.unproject_position(wolf.global_position + Vector3(0, 1.4, 0))
	return hero_point.distance_to(screen_position) < 185.0

func _vehicle_was_tapped(screen_position: Vector2) -> bool:
	if camera.is_position_behind(vehicle_visual.global_position):
		return false
	var quad_point := camera.unproject_position(vehicle_visual.global_position + Vector3(0, 0.55, 0))
	return quad_point.distance_to(screen_position) < 250.0

func _handle_tap() -> void:
	if jumping:
		trick_requested = true

func _reset_run() -> void:
	PlayAction.reset_run(self)

func _load_high_score() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = int(cfg.get_value("run", "high_score", 0))

func _save_high_score() -> void:
	if score > high_score:
		high_score = score
	var cfg := ConfigFile.new()
	cfg.set_value("run", "high_score", high_score)
	cfg.save(SAVE_PATH)
