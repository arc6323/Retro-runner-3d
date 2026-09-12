class_name CityKit
extends RefCounted

static func attach_road(world_pivot: Node3D) -> void:
	world_pivot.add_child(MeshKit.box(Vector3(28, 0.4, 180), Vector3(0, -0.38, -70), Color(0.09, 0.09, 0.1)))
	world_pivot.add_child(MeshKit.box(Vector3(11.4, 0.18, 180), Vector3(0, -0.18, -70), Color(0.12, 0.12, 0.13)))
	world_pivot.add_child(MeshKit.box(Vector3(2.4, 0.22, 180), Vector3(-7.2, -0.12, -70), Color(0.22, 0.21, 0.2)))
	world_pivot.add_child(MeshKit.box(Vector3(2.4, 0.22, 180), Vector3(7.2, -0.12, -70), Color(0.22, 0.21, 0.2)))
	world_pivot.add_child(MeshKit.box(Vector3(0.12, 0.06, 180), Vector3(-5.55, 0.02, -70), Color(0.82, 0.78, 0.55), Color(0.55, 0.45, 0.15)))
	world_pivot.add_child(MeshKit.box(Vector3(0.12, 0.06, 180), Vector3(5.55, 0.02, -70), Color(0.82, 0.78, 0.55), Color(0.55, 0.45, 0.15)))
	# Four dashed separators create five playable lanes.
	for x in [-3.45, -1.15, 1.15, 3.45]:
		for z in range(-150, 20, 7):
			world_pivot.add_child(MeshKit.box(Vector3(0.10, 0.03, 2.6), Vector3(x, 0.01, float(z)), Color(0.78, 0.76, 0.68)))

static func attach_building(world_pivot: Node3D, x: float, z: float, width: float, height: float, depth: float, variant: int) -> Node3D:
	var building := Node3D.new()
	building.position = Vector3(x, 0, z)
	world_pivot.add_child(building)
	var body_colors := [Color(0.16, 0.16, 0.17), Color(0.13, 0.15, 0.18), Color(0.18, 0.14, 0.12)]
	var accent_colors := [Color(0.95, 0.78, 0.42), Color(0.45, 0.72, 0.95), Color(0.95, 0.42, 0.28)]
	building.add_child(MeshKit.box(Vector3(width, height, depth), Vector3(0, height * 0.5, 0), body_colors[variant % 3]))
	building.add_child(MeshKit.box(Vector3(width + 0.35, 0.35, depth + 0.35), Vector3(0, height + 0.1, 0), Color(0.1, 0.1, 0.11)))
	var window_color: Color = accent_colors[variant % 3]
	var rows: int = max(3, int(height / 2.4))
	for row in range(rows):
		var wy: float = 1.6 + float(row) * 2.3
		if wy > height - 1.2:
			continue
		var lit := (row + variant) % 3 != 0
		var emission := window_color * (0.55 if lit else 0.04)
		var albedo := Color(0.55, 0.52, 0.4) if lit else Color(0.12, 0.13, 0.15)
		building.add_child(MeshKit.box(Vector3(width * 0.78, 0.55, 0.06), Vector3(0, wy, depth * 0.5 + 0.04), albedo, emission))
	if variant == 1:
		building.add_child(MeshKit.box(Vector3(width * 0.35, 2.2, width * 0.35), Vector3(width * 0.18, height + 1.2, 0), Color(0.28, 0.28, 0.3)))
	elif variant == 2:
		building.add_child(MeshKit.box(Vector3(width * 0.7, 1.6, 0.12), Vector3(0, height * 0.62, depth * 0.5 + 0.2), Color(0.08, 0.08, 0.08), window_color * 0.4))
	return building

static func attach_lamps(world_pivot: Node3D) -> Array:
	var lamps: Array = []
	for z in range(-140, 16, 18):
		for side in [-1.0, 1.0]:
			var lamp := Node3D.new()
			lamp.position = Vector3(side * 6.55, 0, float(z) + side)
			world_pivot.add_child(lamp)
			lamp.add_child(MeshKit.cylinder(0.07, 4.4, Vector3(0, 2.2, 0), Color(0.18, 0.18, 0.2)))
			lamp.add_child(MeshKit.box(Vector3(0.9, 0.12, 0.18), Vector3(side * -0.3, 4.35, 0), Color(0.2, 0.2, 0.22)))
			lamp.add_child(MeshKit.box(Vector3(0.28, 0.1, 0.28), Vector3(side * -0.55, 4.22, 0), Color(1.0, 0.86, 0.55), Color(1.0, 0.75, 0.35)))
			if int(z) % 36 == 0:
				var light := OmniLight3D.new()
				light.position = Vector3(side * -0.55, 4.1, 0)
				light.light_color = Color(1.0, 0.78, 0.45)
				light.light_energy = 2.4
				light.omni_range = 9.0
				lamp.add_child(light)
			lamps.append(lamp)
	return lamps

static func attach_ramp(world_pivot: Node3D, position: Vector3) -> Node3D:
	var ramp := Node3D.new()
	ramp.name = "Ramp"
	# Travel is toward positive Z. The ramp must rise toward the near/front edge.
	ramp.position = position + Vector3(0.0, 0.20, 0.0)
	world_pivot.add_child(ramp)
	var deck := MeshKit.box(Vector3(2.0, 0.42, 8.2), Vector3(0, 0.38, 0), Color(0.55, 0.16, 0.12))
	deck.rotation_degrees.x = 11.0
	ramp.add_child(deck)
	for x in [-0.96, 0.96]:
		var rail := MeshKit.box(Vector3(0.10, 0.55, 8.2), Vector3(x, 0.5, 0), Color(0.75, 0.75, 0.72))
		rail.rotation_degrees.x = 11.0
		rail.set_meta("ramp_rail", true)
		ramp.add_child(rail)
	return ramp

static func make_car(car_lane: int, z: float, color: Color, lane_x: Array) -> Node3D:
	var car := Node3D.new()
	car.position = Vector3(lane_x[car_lane], 0, z)
	car.set_meta("lane", car_lane)
	car.add_child(MeshKit.box(Vector3(2.05, 0.72, 4.3), Vector3(0, 0.62, 0), color))
	car.add_child(MeshKit.box(Vector3(1.7, 0.58, 2.0), Vector3(0, 1.18, -0.15), Color(0.08, 0.1, 0.12)))
	car.add_child(MeshKit.box(Vector3(0.38, 0.14, 0.08), Vector3(-0.62, 0.62, -2.18), Color(1.0, 0.92, 0.7), Color(1.0, 0.9, 0.55)))
	car.add_child(MeshKit.box(Vector3(0.38, 0.14, 0.08), Vector3(0.62, 0.62, -2.18), Color(1.0, 0.92, 0.7), Color(1.0, 0.9, 0.55)))
	car.add_child(MeshKit.box(Vector3(0.42, 0.14, 0.08), Vector3(-0.62, 0.68, 2.16), Color(0.85, 0.12, 0.1), Color(0.7, 0.05, 0.05)))
	car.add_child(MeshKit.box(Vector3(0.42, 0.14, 0.08), Vector3(0.62, 0.68, 2.16), Color(0.85, 0.12, 0.1), Color(0.7, 0.05, 0.05)))
	for wheel_pos in [Vector3(-0.9, 0.28, 1.35), Vector3(0.9, 0.28, 1.35), Vector3(-0.9, 0.28, -1.35), Vector3(0.9, 0.28, -1.35)]:
		var wheel := MeshKit.cylinder(0.28, 0.22, wheel_pos, Color(0.06, 0.06, 0.06))
		wheel.set_meta("traffic_wheel", true)
		car.add_child(wheel)
	return car
