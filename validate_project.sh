#!/usr/bin/env bash
set -euo pipefail

# Lightweight project invariant checks; Godot headless import is run in CI.
grep -q 'enum GameState { ROADSIDE_IDLE, MOUNTING, MERGING, RUNNING' main.gd
grep -q 'func _physics_process(delta: float)' main.gd
grep -q 'trick_score += TRICK_BONUS' main.gd
grep -q 'world_pivot.position.x = lerpf' main.gd
grep -q 'pivot.rotation_degrees.y = steer_visual' main.gd
grep -q 'target_position = CAMERA_RAMP' main.gd
grep -q '_hero_was_tapped' main.gd
grep -q 'DOUBLE_TAP_WINDOW' main.gd
grep -q 'preload("res://assets/models/red_wolf_standing.glb")' main.gd
grep -q 'preload("res://assets/models/street_quad.glb")' main.gd
test -s assets/models/red_wolf_standing.glb
test -s assets/models/red_wolf_riding.glb
test -s assets/models/street_quad.glb
! grep -q 'func _build_quad' main.gd
! grep -q 'func _build_wolf' main.gd
grep -q 'ДИСТАНЦИЯ' main.gd
grep -q 'КОСНИСЬ ГЕРОЯ, ЧТОБЫ НАЧАТЬ' main.gd
! grep -q 'TRICK button' main.gd
test -s tests/gameplay_smoke.gd
grep -q 'Gameplay smoke test passed' tests/gameplay_smoke.gd
grep -q '^pause=' project.godot
grep -q '^restart=' project.godot
echo "Project invariant checks passed"
