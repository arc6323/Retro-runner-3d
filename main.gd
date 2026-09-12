extends GameBase

var garage_button: Button
var settings_button: Button
var garage_panel: Panel
var settings_panel: Panel
var sound_button: Button
var selected_character := 0
var selected_vehicle := 0
var sound_enabled := true

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
	prompt.text = "КОСНИСЬ РЭДА ИЛИ КВАДРОЦИКЛА, ЧТОБЫ НАЧАТЬ"
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

	garage_panel = _build_garage_panel(root)
	settings_panel = _build_settings_panel(root)

func _make_menu_button(text_value: String, side: int) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 20)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT if side == 0 else Control.PRESET_BOTTOM_RIGHT)
	button.offset_top = -270
	button.offset_bottom = -205
	if side == 0:
		button.offset_left = 28
		button.offset_right = 218
	else:
		button.offset_left = -218
		button.offset_right = -28
	return button

func _build_garage_panel(parent: Control) -> Panel:
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -290
	panel.offset_top = -360
	panel.offset_right = 290
	panel.offset_bottom = 360
	panel.z_index = 20
	panel.visible = false
	parent.add_child(panel)
	var title_label := Label.new()
	title_label.position = Vector2(30, 24)
	title_label.size = Vector2(520, 55)
	title_label.text = "ГАРАЖ"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	panel.add_child(title_label)
	var character_label := Label.new()
	character_label.position = Vector2(30, 88)
	character_label.size = Vector2(520, 35)
	character_label.text = "ПЕРСОНАЖ"
	character_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(character_label)
	var red_button := Button.new()
	red_button.position = Vector2(30, 130)
	red_button.size = Vector2(165, 70)
	red_button.text = "РЭД\nДОСТУПЕН"
	red_button.add_theme_font_size_override("font_size", 18)
	red_button.pressed.connect(_select_red)
	panel.add_child(red_button)
	for index in 2:
		var locked := Button.new()
		locked.position = Vector2(210 + index * 165, 130)
		locked.size = Vector2(155, 70)
		locked.text = "СЛОТ %d\nСКОРО" % (index + 2)
		locked.disabled = true
		locked.add_theme_font_size_override("font_size", 17)
		panel.add_child(locked)
	var vehicle_label := Label.new()
	vehicle_label.position = Vector2(30, 225)
	vehicle_label.size = Vector2(520, 35)
	vehicle_label.text = "КВАДРОЦИКЛ"
	vehicle_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(vehicle_label)
	var quad_button := Button.new()
	quad_button.position = Vector2(30, 267)
	quad_button.size = Vector2(165, 70)
	quad_button.text = "STREET QUAD\nДОСТУПЕН"
	quad_button.add_theme_font_size_override("font_size", 17)
	quad_button.pressed.connect(_select_quad)
	panel.add_child(quad_button)
	for index in 2:
		var locked_quad := Button.new()
		locked_quad.position = Vector2(210 + index * 165, 267)
		locked_quad.size = Vector2(155, 70)
		locked_quad.text = "NEON-%d\nСКОРО" % (index + 1)
		locked_quad.disabled = true
		locked_quad.add_theme_font_size_override("font_size", 17)
		panel.add_child(locked_quad)
	var close := Button.new()
	close.position = Vector2(180, 555)
	close.size = Vector2(220, 70)
	close.text = "ЗАКРЫТЬ"
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(_close_menus)
	panel.add_child(close)
	return panel

func _build_settings_panel(parent: Control) -> Panel:
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -290
	panel.offset_top = -260
	panel.offset_right = 290
	panel.offset_bottom = 260
	panel.z_index = 20
	panel.visible = false
	parent.add_child(panel)
	var title_label := Label.new()
	title_label.position = Vector2(30, 28)
	title_label.size = Vector2(520, 55)
	title_label.text = "НАСТРОЙКИ"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	panel.add_child(title_label)
	sound_button = Button.new()
	sound_button.position = Vector2(70, 115)
	sound_button.size = Vector2(440, 75)
	sound_button.add_theme_font_size_override("font_size", 21)
	sound_button.pressed.connect(_toggle_sound)
	panel.add_child(sound_button)
	var info := Label.new()
	info.position = Vector2(55, 215)
	info.size = Vector2(470, 110)
	info.text = "УПРАВЛЕНИЕ\nСвайп ← → — 5 полос\nСвайп вверх — прыжок / трюк\nТап — трюк / ускорение"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 19)
	panel.add_child(info)
	var close := Button.new()
	close.position = Vector2(180, 370)
	close.size = Vector2(220, 70)
	close.text = "ЗАКРЫТЬ"
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(_close_menus)
	panel.add_child(close)
	_update_sound_button()
	return panel

func _open_garage() -> void:
	if game_state != GameState.ROADSIDE_IDLE:
		return
	garage_panel.visible = true
	settings_panel.visible = false

func _open_settings() -> void:
	if game_state != GameState.ROADSIDE_IDLE:
		return
	settings_panel.visible = true
	garage_panel.visible = false

func _close_menus() -> void:
	garage_panel.visible = false
	settings_panel.visible = false

func _select_red() -> void:
	selected_character = 0
	_show_menu_message("РЭД ВЫБРАН")

func _select_quad() -> void:
	selected_vehicle = 0
	_show_menu_message("STREET QUAD ВЫБРАН")

func _toggle_sound() -> void:
	sound_enabled = not sound_enabled
	_update_sound_button()

func _update_sound_button() -> void:
	if sound_button != null:
		sound_button.text = "ЗВУК: ВКЛ" if sound_enabled else "ЗВУК: ВЫКЛ"

func _show_menu_message(text_value: String) -> void:
	prompt.text = text_value
	await get_tree().create_timer(0.8).timeout
	if game_state == GameState.ROADSIDE_IDLE:
		prompt.text = "РЕКОРД %05d\nКОСНИСЬ РЭДА ИЛИ КВАДРОЦИКЛА, ЧТОБЫ НАЧАТЬ" % high_score if high_score > 0 else "КОСНИСЬ РЭДА ИЛИ КВАДРОЦИКЛА, ЧТОБЫ НАЧАТЬ"

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
	title.visible = true
	prompt.visible = true
	garage_button.visible = true
	settings_button.visible = true
	hud.visible = false
	garage_panel.visible = false
	settings_panel.visible = false
	if high_score > 0:
		prompt.text = "РЕКОРД %05d\nКОСНИСЬ РЭДА ИЛИ КВАДРОЦИКЛА, ЧТОБЫ НАЧАТЬ" % high_score
	else:
		prompt.text = "КОСНИСЬ РЭДА ИЛИ КВАДРОЦИКЛА, ЧТОБЫ НАЧАТЬ"

func _begin_start_sequence() -> void:
	if game_state != GameState.ROADSIDE_IDLE:
		return
	_close_menus()
	game_state = GameState.MOUNTING
	transition_time = 0.0
	prompt.text = "ВЫХОДИМ НА ТРАССУ..."
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
		PlayLoop.update_crash(self, delta)
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
	return

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
	# Gameplay notifications are intentionally kept off the main HUD.
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
	_save_high_score()
	Input.vibrate_handheld(90)
	hud.text = "🪙 %d      %.2f км      %d км/ч" % [coins, distance / 1000.0, int(round(float(get_meta("current_speed_kmh", 0.0))))]

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
	var now := Time.get_ticks_msec() / 1000.0
	if jumping:
		trick_requested = true
	elif now - last_tap_time <= DOUBLE_TAP_WINDOW:
		boost_remaining = 1.35
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
