from pathlib import Path
import re


def replace_once(path: Path, old: str, new: str, label: str) -> str:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise SystemExit(f"{label} pattern not found")
    text = text.replace(old, new, 1)
    path.write_text(text, encoding="utf-8")
    return text


game_base = Path("scripts/game_base.gd")
text = game_base.read_text(encoding="utf-8")
text = re.sub(
    r'var types := \[.*?\]',
    'var types := ["coin", "coin", "magnet", "coin", "coin", "flight", "coin", "magnet", "coin", "coin", "coin", "coin", "coin", "magnet", "coin", "coin", "coin", "coin", "coin", "coin"]',
    text,
    count=1,
)
text = text.replace(
    'pickup.position = Vector3(LANE_X[index % 5], 0.9 if pickup_type == "coin" else 1.05, -18.0 - float(index) * 18.0)',
    'pickup.position = Vector3(LANE_X[index % 5], 0.9 if pickup_type == "coin" else 1.05, -4000.0 if pickup_type == "flight" else -18.0 - float(index) * 18.0)',
    1,
)
game_base.write_text(text, encoding="utf-8")

loop = Path("scripts/play_loop.gd")
text = loop.read_text(encoding="utf-8")
if 'g.set_meta("current_speed_kmh", current_speed * 3.6)' in text:
    text = text.replace('g.set_meta("current_speed_kmh", current_speed * 3.6)', 'g.set_meta("physical_speed_kmh", current_speed * 3.6)', 1)

# The pickup movement used to sit inside the magnet-only branch. Remove that line
# regardless of whether the source currently has three or four tabs of indentation.
movement_pattern = r'\n\t{3,}pickup\.position\.z \+= current_speed \* delta\n'
text, movement_count = re.subn(movement_pattern, '\n', text, count=1)
if movement_count != 1:
    raise SystemExit("pickup movement line not found")

# Add normal world movement after magnet attraction, before hit testing.
hit_needle = '\t\tvar hit_distance: float = Vector2(pickup.position.x - player_local_x, pickup.position.z - player_z).length()'
pos = text.find(hit_needle)
if pos < 0:
    raise SystemExit("pickup hit test not found")
text = text[:pos] + '\t\tif pickup_type != "flight":\n\t\t\tpickup.position.z += current_speed * delta\n' + text[pos:]

# Flight pickup is tied directly to the distance counter: 4 km, 8 km, 12 km, ...
# It is the only flight pickup and its visual size is not changed.
old_type_line = '\t\tvar pickup_type: String = g.pickup_types[index]\n'
flight_setup = '''\t\tvar pickup_type: String = g.pickup_types[index]\n\t\tif pickup_type == "flight":\n\t\t\tvar flight_target_distance: float = float(pickup.get_meta("flight_target_distance", 4000.0))\n\t\t\tpickup.set_meta("flight_target_distance", flight_target_distance)\n\t\t\tpickup.position.x = g.LANE_X[index % 5]\n\t\t\tpickup.position.y = 1.05\n\t\t\tpickup.position.z = player_z - (flight_target_distance - g.distance)\n'''
if old_type_line not in text:
    raise SystemExit("pickup type line not found")
text = text.replace(old_type_line, flight_setup, 1)

old_recycle = '''\t\tif pickup.position.z > PICKUP_RECYCLE_Z:\n\t\t\tpickup.position = g.pickup_homes[index]\n\t\t\tpickup.position.x = g.LANE_X[g.rng.randi_range(0, 4)]\n'''
new_recycle = '''\t\tif pickup.position.z > PICKUP_RECYCLE_Z:\n\t\t\tif pickup_type == "flight":\n\t\t\t\tvar next_flight_distance: float = float(pickup.get_meta("flight_target_distance", g.distance + 4000.0)) + 4000.0\n\t\t\t\tpickup.set_meta("flight_target_distance", next_flight_distance)\n\t\t\t\tcontinue\n\t\t\tpickup.position = g.pickup_homes[index]\n\t\t\tpickup.position.x = g.LANE_X[g.rng.randi_range(0, 4)]\n'''
if old_recycle not in text:
    raise SystemExit("pickup recycle block not found")
text = text.replace(old_recycle, new_recycle, 1)

old_collect = '''\telif pickup_type == "flight":\n\t\tg.ramp_used = true\n\t\tg.flight_remaining = 4.5\n\t\tg.flight_invulnerability_remaining = 0.0\n\t\tg.jumping = false\n\t\tg.jump_velocity = 0.0\n\t\tg.trick_requested = false\n\t\tg.vehicle_visual.rotation_degrees.x = 0.0\n\t\tg.wolf.rotation_degrees.x = 0.0\n\t\tg.player.position.y = 2.8\n'''
new_collect = '''\telif pickup_type == "flight":\n\t\tg.ramp_used = true\n\t\tg.flight_remaining = 4.5\n\t\tg.flight_invulnerability_remaining = 0.0\n\t\tg.jumping = false\n\t\tg.jump_velocity = 0.0\n\t\tg.trick_requested = false\n\t\tg.vehicle_visual.rotation_degrees.x = 0.0\n\t\tg.wolf.rotation_degrees.x = 0.0\n\t\tg.player.position.y = 2.8\n\t\tvar next_flight_distance: float = float(pickup.get_meta("flight_target_distance", g.distance + 4000.0)) + 4000.0\n\t\tpickup.set_meta("flight_target_distance", next_flight_distance)\n'''
if old_collect not in text:
    raise SystemExit("flight collect block not found")
text = text.replace(old_collect, new_collect, 1)

# Keep the no-auto-flip behavior intact; only smooth the visual pose while flying.
old_flight_visual = '''\tif g.flight_remaining > 0.0:\n\t\tg.ramp_used = true\n\t\tg.jumping = false\n\t\tg.jump_velocity = 0.0\n\t\tg.trick_requested = false\n\t\tg.vehicle_visual.rotation_degrees.x = 0.0\n\t\tg.wolf.rotation_degrees.x = 0.0\n\t\treturn\n'''
new_flight_visual = '''\tif g.flight_remaining > 0.0:\n\t\tg.ramp_used = true\n\t\tg.jumping = false\n\t\tg.jump_velocity = 0.0\n\t\tg.trick_requested = false\n\t\tvar flight_phase: float = sin(g.elapsed_time * 5.0)\n\t\tg.vehicle_visual.rotation_degrees.x = -4.0 + flight_phase * 1.5\n\t\tg.wolf.rotation_degrees.x = -3.7 + flight_phase * 1.4\n\t\treturn\n'''
if old_flight_visual in text:
    text = text.replace(old_flight_visual, new_flight_visual, 1)

loop.write_text(text, encoding="utf-8")

action = Path("scripts/play_action.gd")
action_text = action.read_text(encoding="utf-8")
if 'var physical_speed_kmh: float = float(g.get_meta("current_speed_kmh", 0.0))' in action_text:
    action_text = action_text.replace(
        'var physical_speed_kmh: float = float(g.get_meta("current_speed_kmh", 0.0))',
        'var physical_speed_kmh: float = float(g.get_meta("physical_speed_kmh", g.BASE_SPEED * 3.0 * 3.6))',
        1,
    )
    action.write_text(action_text, encoding="utf-8")

print("Build gameplay patch applied successfully")
