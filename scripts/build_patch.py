from pathlib import Path


def replace_once(path: Path, old: str, new: str, label: str) -> str:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise SystemExit(f"{label} pattern not found")
    text = text.replace(old, new, 1)
    path.write_text(text, encoding="utf-8")
    return text


# Keep only one flight pickup and place it 4 km ahead. The visual size is untouched.
game_base = Path("scripts/game_base.gd")
text = game_base.read_text(encoding="utf-8")
old_types = 'var types := ["coin", "coin", "magnet", "coin", "coin", "flight", "coin", "magnet", "coin", "coin", "coin", "flight", "coin", "magnet", "coin", "coin", "coin", "flight", "coin", "coin"]'
new_types = 'var types := ["coin", "coin", "magnet", "coin", "coin", "flight", "coin", "magnet", "coin", "coin", "coin", "coin", "coin", "magnet", "coin", "coin", "coin", "coin", "coin", "coin"]'
if old_types not in text:
    raise SystemExit("flight pickup list pattern not found")
text = text.replace(old_types, new_types, 1)
old_pos = 'pickup.position = Vector3(LANE_X[index % 5], 0.9 if pickup_type == "coin" else 1.05, -18.0 - float(index) * 18.0)'
new_pos = 'pickup.position = Vector3(LANE_X[index % 5], 0.9 if pickup_type == "coin" else 1.05, -4000.0 if pickup_type == "flight" else -18.0 - float(index) * 18.0)'
if old_pos not in text:
    raise SystemExit("pickup position pattern not found")
text = text.replace(old_pos, new_pos, 1)
game_base.write_text(text, encoding="utf-8")

# Store physical speed separately so the HUD never feeds its displayed value back into the physics value.
loop = Path("scripts/play_loop.gd")
text = replace_once(
    loop,
    'g.set_meta("current_speed_kmh", current_speed * 3.6)',
    'g.set_meta("physical_speed_kmh", current_speed * 3.6)',
    "physical speed marker",
)

# Every visible pickup moves with the world. Previously movement was accidentally inside the magnet-only block.
old_pickup = '''\t\tif g.magnet_remaining > 0.0 and pickup_type == "coin":
\t\t\tvar distance_to_player: float = Vector2(pickup.position.x - player_local_x, pickup.position.z - player_z).length()
\t\t\tif distance_to_player < MAGNET_RANGE:
\t\t\t\tpickup.position.x = lerpf(pickup.position.x, player_local_x, min(1.0, delta * 8.0))
\t\t\t\tpickup.position.z = lerpf(pickup.position.z, player_z, min(1.0, delta * 8.0))
\t\t\t\tpickup.position.z += current_speed * delta
'''
new_pickup = '''\t\tif g.magnet_remaining > 0.0 and pickup_type == "coin":
\t\t\tvar distance_to_player: float = Vector2(pickup.position.x - player_local_x, pickup.position.z - player_z).length()
\t\t\tif distance_to_player < MAGNET_RANGE:
\t\t\t\tpickup.position.x = lerpf(pickup.position.x, player_local_x, min(1.0, delta * 8.0))
\t\t\t\tpickup.position.z = lerpf(pickup.position.z, player_z, min(1.0, delta * 8.0))
\t\t# All pickups move toward the player as the road scrolls.
\t\tpickup.position.z += current_speed * delta
'''
if old_pickup not in text:
    raise SystemExit("pickup movement pattern not found")
text = text.replace(old_pickup, new_pickup, 1)

# Smooth flight attitude instead of a rigid zero-rotation pose.
old_flight = '''\tif g.flight_remaining > 0.0:
\t\tg.ramp_used = true
\t\tg.jumping = false
\t\tg.jump_velocity = 0.0
\t\tg.trick_requested = false
\t\tg.vehicle_visual.rotation_degrees.x = 0.0
\t\tg.wolf.rotation_degrees.x = 0.0
\t\treturn
'''
new_flight = '''\tif g.flight_remaining > 0.0:
\t\tg.ramp_used = true
\t\tg.jumping = false
\t\tg.jump_velocity = 0.0
\t\tg.trick_requested = false
\t\tvar flight_phase: float = sin(g.elapsed_time * 5.0)
\t\tg.vehicle_visual.rotation_degrees.x = -4.0 + flight_phase * 1.5
\t\tg.wolf.rotation_degrees.x = -3.7 + flight_phase * 1.4
\t\treturn
'''
if old_flight not in text:
    raise SystemExit("flight visual pattern not found")
text = text.replace(old_flight, new_flight, 1)

# Smooth takeoff: do not snap the player to altitude when the flight pickup is collected.
old_snap = '\t\tg.player.position.y = 2.8\n'
if old_snap not in text:
    raise SystemExit("flight altitude snap pattern not found")
text = text.replace(old_snap, '', 1)
loop.write_text(text, encoding="utf-8")

action = Path("scripts/play_action.gd")
replace_once(
    action,
    'var physical_speed_kmh: float = float(g.get_meta("current_speed_kmh", 0.0))',
    'var physical_speed_kmh: float = float(g.get_meta("physical_speed_kmh", g.BASE_SPEED * 3.0 * 3.6))',
    "HUD speed read",
)

print("Build gameplay patch applied successfully")
