from pathlib import Path


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise SystemExit(f"{label} pattern not found")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


# More traffic variety: nine vehicles instead of five, spaced so the road never becomes a solid wall.
game_base = Path("scripts/game_base.gd")
replace_once(
    game_base,
    '''\tvar cars := [
\t\t[0, -24.0, Color(0.12, 0.13, 0.16)], [4, -41.0, Color(0.42, 0.08, 0.08)],
\t\t[0, -63.0, Color(0.08, 0.12, 0.22)], [4, -88.0, Color(0.18, 0.18, 0.16)],
\t\t[0, -112.0, Color(0.08, 0.08, 0.08)],
\t]
''',
    '''\tvar cars := [
\t\t[0, -24.0, Color(0.12, 0.13, 0.16)], [4, -38.0, Color(0.42, 0.08, 0.08)],
\t\t[2, -54.0, Color(0.08, 0.12, 0.22)], [1, -70.0, Color(0.18, 0.18, 0.16)],
\t\t[3, -88.0, Color(0.08, 0.08, 0.08)], [0, -106.0, Color(0.20, 0.12, 0.10)],
\t\t[4, -124.0, Color(0.10, 0.18, 0.16)], [2, -142.0, Color(0.20, 0.10, 0.22)],
\t\t[1, -158.0, Color(0.16, 0.16, 0.18)],
\t]
''',
    "traffic set",
)

# Vary ramp cadence and lane choice by distance: center, edge, then random sections.
loop = Path("scripts/play_loop.gd")
replace_once(
    loop,
    '''\tg.ramp.position.z += current_speed * delta
\tif g.ramp.position.z > 18.0:
\t\tg.ramp.position.z = -118.0
\t\tg.ramp_lane = g.rng.randi_range(0, 4)
\t\tg.ramp.position.x = g.LANE_X[g.ramp_lane]
\t\tg.ramp_used = false
''',
    '''\tg.ramp.position.z += current_speed * delta
\tif g.ramp.position.z > 18.0:
\t\tvar ramp_phase: int = int(floor(g.distance / 900.0)) % 3
\t\tvar ramp_gap: float = 104.0 + float(ramp_phase) * 18.0
\t\tg.ramp.position.z = -ramp_gap
\t\tif ramp_phase == 0:
\t\t\tg.ramp_lane = 2
\t\telif ramp_phase == 1:
\t\t\tg.ramp_lane = 0 if int(floor(g.distance / 450.0)) % 2 == 0 else 4
\t\telse:
\t\t\tg.ramp_lane = g.rng.randi_range(0, 4)
\t\tg.ramp.position.x = g.LANE_X[g.ramp_lane]
\t\tg.ramp_used = false
''',
    "ramp recycle",
)

print("Track variety patch applied successfully")
