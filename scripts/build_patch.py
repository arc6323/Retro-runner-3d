from pathlib import Path
import re


def replace_once(path: Path, old: str, new: str, label: str, *, required: bool = True) -> str:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        if required:
            raise SystemExit(f"{label} pattern not found")
        return text
    text = text.replace(old, new, 1)
    path.write_text(text, encoding="utf-8")
    return text


game_base = Path("scripts/game_base.gd")
text = game_base.read_text(encoding="utf-8")
text = re.sub(
    r'var types := \[.*?\]',
    'var types := ["coin", "coin", "coin", "coin", "magnet", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "flight", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin"]',
    text,
    count=1,
)
text = text.replace(
    'pickup.position = Vector3(LANE_X[index % 5], 0.9 if pickup_type == "coin" else 1.05, -18.0 - float(index) * 18.0)',
    'pickup.position = Vector3(LANE_X[index % 5], 0.9 if pickup_type == "coin" else 1.05, -4000.0 if pickup_type == "flight" else -12.0 - float(index) * 11.0)',
    1,
)
game_base.write_text(text, encoding="utf-8")

loop = Path("scripts/play_loop.gd")
text = loop.read_text(encoding="utf-8")

if 'g.set_meta("current_speed_kmh", current_speed * 3.6)' in text:
    text = text.replace(
        'g.set_meta("current_speed_kmh", current_speed * 3.6)',
        'g.set_meta("physical_speed_kmh", current_speed * 3.6)',
        1,
    )

text, movement_count = re.subn(r'\n\t{3,}pickup\.position\.z \+= current_speed \* delta\n', '\n', text, count=1)
if movement_count != 1:
    raise SystemExit("pickup movement line not found")
hit_needle = '\t\tvar hit_distance: float = Vector2(pickup.position.x - player_local_x, pickup.position.z - player_z).length()'
if hit_needle not in text:
    raise SystemExit("pickup hit test not found")
if '\t\tif pickup_type != "flight":\n\t\t\tpickup.position.z += current_speed * delta\n' not in text:
    text = text.replace(
        hit_needle,
        '\t\tif pickup_type != "flight":\n\t\t\tpickup.position.z += current_speed * delta\n' + hit_needle,
        1,
    )

old_type_line = '\t\tvar pickup_type: String = g.pickup_types[index]\n'
flight_setup = '''\t\tvar pickup_type: String = g.pickup_types[index]\n\t\tif pickup_type == "flight":\n\t\t\tvar flight_target_distance: float = float(pickup.get_meta("flight_target_distance", 4000.0))\n\t\t\tpickup.set_meta("flight_target_distance", flight_target_distance)\n\t\t\tpickup.position.x = g.LANE_X[index % 5]\n\t\t\tpickup.position.y = 1.05\n\t\t\tpickup.position.z = player_z - (flight_target_distance - g.distance)\n'''
if old_type_line not in text:
    raise SystemExit("pickup type line not found")
if 'flight_target_distance' not in text:
    text = text.replace(old_type_line, flight_setup, 1)

old_recycle = '''\t\tif pickup.position.z > PICKUP_RECYCLE_Z:\n\t\t\tpickup.position = g.pickup_homes[index]\n\t\t\tpickup.position.x = g.LANE_X[g.rng.randi_range(0, 4)]\n'''
new_recycle = '''\t\tif pickup.position.z > PICKUP_RECYCLE_Z:\n\t\t\tif pickup_type == "flight":\n\t\t\t\tvar next_flight_distance: float = float(pickup.get_meta("flight_target_distance", g.distance + 4000.0)) + 4000.0\n\t\t\t\tpickup.set_meta("flight_target_distance", next_flight_distance)\n\t\t\t\tcontinue\n\t\t\tpickup.position = g.pickup_homes[index]\n\t\t\tif pickup_type == "coin":\n\t\t\t\tvar pattern_step: int = int(floor(g.distance / 220.0)) + index\n\t\t\t\tvar pattern_kind: int = pattern_step % 4\n\t\t\t\tif pattern_kind == 0:\n\t\t\t\t\tpickup.position.x = g.LANE_X[(pattern_step + index) % 5]\n\t\t\t\t\tpickup.position.y = 0.92 + 0.24 * sin(float(index) * 0.75)\n\t\t\t\telif pattern_kind == 1:\n\t\t\t\t\tpickup.position.x = g.LANE_X[(index * 2 + pattern_step) % 5]\n\t\t\t\t\tpickup.position.y = 1.02\n\t\t\t\telif pattern_kind == 2:\n\t\t\t\t\tpickup.position.x = g.LANE_X[(4 - index + pattern_step) % 5]\n\t\t\t\t\tpickup.position.y = 0.92 + 0.20 * cos(float(index) * 0.8)\n\t\t\t\telse:\n\t\t\t\t\tpickup.position.x = g.LANE_X[(pattern_step + index + 1) % 5]\n\t\t\t\t\tpickup.position.y = 1.08\n\t\t\telse:\n\t\t\t\tpickup.position.x = g.LANE_X[g.rng.randi_range(0, 4)]\n'''
if old_recycle in text:
    text = text.replace(old_recycle, new_recycle, 1)

old_collect_y = '\t\tg.player.position.y = 2.8\n'
if old_collect_y in text:
    text = text.replace(old_collect_y, '\t\tg.player.position.y = max(g.player.position.y, 0.0)\n', 1)

old_landing = '\t\t\tg.camera_shake = 0.55 if g.trick_requested else 0.35\n'
new_landing = '\t\t\tg.camera_shake = 0.65 if g.trick_requested else 0.42\n'
if old_landing in text:
    text = text.replace(old_landing, new_landing, 1)

text = text.replace('\t\twing_l.scale = Vector3.ONE * 0.58', '\t\twing_l.scale = Vector3.ONE', 1)
text = text.replace('\t\twing_r.scale = Vector3.ONE * 0.58', '\t\twing_r.scale = Vector3.ONE', 1)
text = text.replace('\t\texhaust.scale = Vector3(0.62, 0.62, 0.62 + (sin(g.elapsed_time * 28.0) * 0.08 if flight_on else 0.0))', '\t\texhaust.scale = Vector3(1.0, 1.0, 1.0 + (sin(g.elapsed_time * 28.0) * 0.10 if flight_on else 0.0))', 1)

old_world_shift = '''\tg.world_pivot.position.x = lerpf(g.world_pivot.position.x, target_x, min(1.0, delta * 8.5))\n\tvar lane_step := 2.3\n\tvar desired_steer: float = clampf(-error / lane_step, -1.0, 1.0) * 26.0\n\tg.steer_visual = lerpf(g.steer_visual, desired_steer, min(1.0, delta * 11.0))\n\tif abs(error) < 0.03:\n\t\tg.steer_visual = lerpf(g.steer_visual, 0.0, min(1.0, delta * 10.0))\n\tfor pivot in g.front_wheel_pivots:\n\t\tpivot.rotation_degrees.y = g.steer_visual\n\tg.vehicle_visual.rotation_degrees.z = 0.0\n\tif g.wolf != null:\n\t\tg.wolf.rotation_degrees.z = 0.0\n'''
new_world_shift = '''\tg.world_pivot.position.x = lerpf(g.world_pivot.position.x, target_x, min(1.0, delta * 12.5))\n\tvar lane_step := 2.3\n\tvar desired_steer: float = clampf(-error / lane_step, -1.0, 1.0) * 32.0\n\tg.steer_visual = lerpf(g.steer_visual, desired_steer, min(1.0, delta * 14.0))\n\tif abs(error) < 0.03:\n\t\tg.steer_visual = lerpf(g.steer_visual, 0.0, min(1.0, delta * 12.0))\n\tfor pivot in g.front_wheel_pivots:\n\t\tpivot.rotation_degrees.y = g.steer_visual\n\tvar lean_target: float = clampf(-g.steer_visual * 0.14, -7.5, 7.5)\n\tg.vehicle_visual.rotation_degrees.z = lerpf(g.vehicle_visual.rotation_degrees.z, lean_target, min(1.0, delta * 12.0))\n\tif g.wolf != null and not g.jumping:\n\t\tg.wolf.rotation_degrees.z = lerpf(g.wolf.rotation_degrees.z, lean_target * 0.82, min(1.0, delta * 12.0))\n'''
if old_world_shift not in text:
    raise SystemExit("world shift block not found")
text = text.replace(old_world_shift, new_world_shift, 1)

old_traffic = '\tg._move_traffic(delta, current_speed * 0.72, true)\n'
new_traffic = '''\tvar traffic_factor: float = 0.72 + min(g.distance / 20000.0, 0.16)\n\tg._move_traffic(delta, current_speed * traffic_factor, true)\n'''
if old_traffic in text:
    text = text.replace(old_traffic, new_traffic, 1)

loop.write_text(text, encoding="utf-8")

action = Path("scripts/play_action.gd")
action_text = action.read_text(encoding="utf-8")
old_camera_fov = '\tvar target_fov := 68.0\n'
new_camera_fov = '''\tvar target_fov := 68.0\n\tif g.game_state == g.GameState.RUNNING:\n\t\tvar shown_speed: float = float(g.get_meta("current_speed_kmh", 50.0))\n\t\ttarget_fov = clampf(68.0 + (shown_speed - 50.0) * 0.075, 68.0, 75.0)\n'''
if old_camera_fov in action_text and 'shown_speed' not in action_text:
    action_text = action_text.replace(old_camera_fov, new_camera_fov, 1)
old_speed = 'var physical_speed_kmh: float = float(g.get_meta("current_speed_kmh", 0.0))'
new_speed = 'var physical_speed_kmh: float = float(g.get_meta("physical_speed_kmh", g.BASE_SPEED * 3.0 * 3.6))'
if old_speed in action_text:
    action_text = action_text.replace(old_speed, new_speed, 1)
action.write_text(action_text, encoding="utf-8")

print("Build gameplay pickup density patch applied successfully")
