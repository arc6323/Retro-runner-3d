#!/usr/bin/env bash
set -euo pipefail

# Invariant checks across all GDScript files after the split.
gd() { grep -R -q --include='*.gd' "$1" .; }

gd 'enum GameState { ROADSIDE_IDLE, MOUNTING, MERGING, RUNNING'
gd 'func _physics_process(delta: float)'
gd 'trick_score +='
gd 'world_pivot.position.x = lerpf'
gd 'rotation_degrees.y ='
gd 'CAMERA_RAMP'
gd '_hero_was_tapped'
gd 'DOUBLE_TAP_WINDOW'
gd 'preload("res://assets/models/red_wolf_standing.glb")'
gd 'preload("res://assets/models/street_quad.glb")'
test -s assets/models/red_wolf_standing.glb
test -s assets/models/red_wolf_riding.glb
test -s assets/models/street_quad.glb
! grep -R -q --include='*.gd' 'func _build_quad' .
! grep -R -q --include='*.gd' 'func _build_wolf' .
gd 'ДИСТАНЦИЯ'
gd 'КОСНИСЬ РЭДА ИЛИ КВАДРОЦИКЛА'
! grep -R -q --include='*.gd' 'TRICK button' .
test -s tests/gameplay_smoke.gd
grep -q 'Gameplay smoke test passed' tests/gameplay_smoke.gd
grep -q '^pause=' project.godot
grep -q '^restart=' project.godot
test -s scripts/mesh_kit.gd
test -s scripts/env_kit.gd
test -s scripts/city_kit.gd
test -s scripts/play_loop.gd
test -s scripts/play_action.gd
test -s scripts/game_base.gd
echo "Project invariant checks passed"
