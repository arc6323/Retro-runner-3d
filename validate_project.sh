#!/usr/bin/env bash
set -euo pipefail

# Lightweight project invariant checks; Godot headless import is run in CI.
grep -q 'func _physics_process(delta: float)' main.gd
! grep -q '^    score = int(distance)$' main.gd
grep -q 'trick_score += TRICK_BONUS' main.gd
grep -q 'event.is_action_pressed("move_left")' main.gd
grep -q 'event.is_action_pressed("move_right")' main.gd
grep -q 'CollisionShape3D' main.gd
grep -q '^pause=' project.godot
grep -q '^restart=' project.godot
echo "Project invariant checks passed"
