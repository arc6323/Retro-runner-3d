extends GameBase

func _ready() -> void:
	rng.randomize()
	_load_high_score()
	EnvKit.attach(self)
	_create_world()
	_create_player()
	_create_camera()
	_create_interface()
	_enter_roadside_idle()


func _create_camera() -> void:
	camera = Camera3D.new()
	camera.name = "CameraRig"
	camera.position = CAMERA_IDLE
	camera.fov = 62.0
	camera.near = 0.12
	camera.far = 220.0
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
	title.add_theme_color_override("font_color", Color(0.93, 0.93, 0.9))
	title.text = "НЕОНОВАЯ\nПУСТОШЬ"
	root.add_child(title)
	prompt = Label.new()
	prompt.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_top = -180
	prompt.offset_bottom = -70
	prompt.offset_left = 28
	prompt.offset_right = -28
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	prompt.text = "КОСНИСЬ ГЕРОЯ, ЧТОБЫ НАЧАТЬ"
	root.add_child(prompt)
	hud = Label.new()
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_left = 20
	hud.offset_right = -20
	hud.offset_top = 28
	hud.offset_bottom = 140
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_theme_font_size_override("font_size", 26)
	hud.visible = false
	root.add_child(hud)


func _enter_roadside_idle() -> void:
	game_state = GameState.ROADSIDE_IDLE
	transition_time = 0.0
	lane = 1
	world_pivot.position.x = 0.0
	player.position = Vector3(-4.2, 0, 4)
	vehicle_visual.rotation_degrees = Vector3(0, 180, 0)
	vehicle_visual.position = Vector3.ZERO
	_set_active_wolf(wolf_standing)
	wolf.position = Vector3(-1.55, 0, 0.22)
	wolf.rotation_degrees = Vector3(0, -12, 0)
	wolf_riding.position = Vector3.ZERO
	wolf_riding.rotation_degrees = Vector3(0, 180, 0)
	title.visible = true
	prompt.visible = true
	hud.visible = false
	if high_score > 0:
		prompt.text = "РЕКОРД %05d\nКОСНИСЬ ГЕРОЯ, ЧТОБЫ НАЧАТЬ" % high_score
	else:
		prompt.text = "КОСНИСЬ ГЕРОЯ, ЧТОБЫ НАЧАТЬ"


func _begin_start_sequence() -> void:
	if game_state != GameState.ROADSIDE_IDLE:
		return
	game_state = GameState.MOUNTING
	transition_time = 0.0
	prompt.text = "ВЫХОДИМ НА ТРАССУ..."


func _physics_process(delta: float) -> void:
	elapsed_time += delta
	camera_shake = max(0.0, camera_shake - delta * 3.6)
	PlayLoop.animate_wolf(self)
	if game_state == GameState.PAUSED:
		return
	if game_state == GameState.ROADSIDE_IDLE:
		_move_traffic(delta, 6.2, false)
		_update_camera(delta)
		return
	if game_state == GameState.MOUNTING:
		_update_mounting(delta)
		_move_traffic(delta, 6.2, false)
		_update_camera(delta)
		return
	if game_state == GameState.MERGING:
		_update_merging(delta)
		_move_traffic(delta, 8.4, false)
		_update_camera(delta)
		return
	if game_state == GameState.GAME_OVER:
		_update_camera(delta)
		return
	_update_running(delta)


func _update_mounting(delta: float) -> void:
	PlayLoop.update_mounting(self, delta)


func _update_merging(delta: float) -> void:
	PlayLoop.update_merging(self, delta)


func _update_running(delta: float) -> void:
	PlayLoop.update_running(self, delta)


func _move_traffic(delta: float, movement_speed: float, check_collision: bool) -> void:
	PlayLoop.move_traffic(self, delta, movement_speed, check_collision)


func _update_world_shift(delta: float) -> void:
	PlayLoop.update_world_shift(self, delta)


func _update_jump(delta: float) -> void:
	PlayAction.update_jump(self, delta)


func _start_jump() -> void:
	if jumping or game_state != GameState.RUNNING:
		return
	jumping = true
	jump_velocity = 12.0
	trick_angle = 0.0
	ramp_used = true
	_show_message("ПРЫЖОК!", 0.7)


func _try_player_jump() -> void:
	if jumping:
		trick_requested = true
		_show_message("ТРЮК!", 0.45)
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
	var boost_text := "  •  УСКОРЕНИЕ" if boost_remaining > 0.0 else ""
	hud.text = "ДИСТАНЦИЯ %04d м     СЧЁТ %05d%s\nРЕКОРД %05d" % [int(distance), score, boost_text, high_score]


func _show_message(text: String, duration: float) -> void:
	hud.text = text
	message_time = duration


func _game_over() -> void:
	game_state = GameState.GAME_OVER
	camera_shake = 0.8
	_save_high_score()
	Input.vibrate_handheld(90)
	hud.text = "СТОЛКНОВЕНИЕ\nСЧЁТ %05d   РЕКОРД %05d\n\nКОСНИСЬ ЭКРАНА — ЕЩЁ РАЗ" % [score, high_score]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and game_state in [GameState.RUNNING, GameState.PAUSED]:
		game_state = GameState.RUNNING if game_state == GameState.PAUSED else GameState.PAUSED
		hud.text = "ПРОДОЛЖИТЬ — КОСНИСЬ ЭКРАНА" if game_state == GameState.PAUSED else "ПОЕХАЛИ!"
		return
	if event.is_action_pressed("restart"):
		_reset_run()
		return
	if event.is_action_pressed("move_left") and game_state == GameState.RUNNING:
		lane = max(0, lane - 1)
		return
	if event.is_action_pressed("move_right") and game_state == GameState.RUNNING:
		lane = min(2, lane + 1)
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
	return camera.unproject_position(wolf.global_position + Vector3(0, 2.0, 0)).distance_to(screen_position) < 210.0


func _handle_tap() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if jumping:
		trick_requested = true
		_show_message("ТРЮК!", 0.45)
	elif now - last_tap_time <= DOUBLE_TAP_WINDOW:
		boost_remaining = 1.35
		_show_message("УСКОРЕНИЕ!", 0.65)
		last_tap_time = -10.0
	else:
		last_tap_time = now


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
