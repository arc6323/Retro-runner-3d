extends SceneTree


func _initialize() -> void:
    var packed: PackedScene = load("res://main.tscn")
    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame
    game.set_physics_process(false)

    assert(game.game_state == 0, "Игра должна начинаться на обочине")
    assert(game.title.visible, "Название должно отображаться до старта")
    assert(not game.hud.visible, "HUD не должен перекрывать стартовую сцену")

    game._begin_start_sequence()
    game._update_mounting(1.0)
    assert(game.game_state == 2, "После посадки должен начаться выезд")
    game._update_merging(1.3)
    assert(game.game_state == 3, "После выезда должен начаться заезд")
    assert(game.hud.visible, "HUD должен появиться после выезда")

    game._handle_pointer(Vector2(200, 800), true)
    game._handle_pointer(Vector2(420, 800), false)
    assert(game.lane == 2, "Свайп вправо должен менять логическую полосу")
    for step in range(40):
        game._update_world_shift(1.0 / 60.0)
    assert(abs(game.player.position.x) < 0.01, "Игрок должен оставаться в центре")
    assert(game.world_pivot.position.x < -3.3, "Мир должен смещаться вместо игрока")

    game._handle_tap()
    game._handle_tap()
    assert(game.boost_remaining > 0.0, "Двойное касание должно включать ускорение")

    game._start_jump()
    game.trick_requested = true
    for step in range(180):
        game._update_jump(1.0 / 60.0)
        if not game.jumping:
            break
    assert(not game.jumping, "Прыжок должен завершаться приземлением")
    assert(game.trick_score == 100, "Трюк должен сохранять бонус")

    print("Gameplay smoke test passed")
    quit(0)
