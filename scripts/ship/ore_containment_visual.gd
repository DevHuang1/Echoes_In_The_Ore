extends Node2D
## Adds physical support hardware and a pressure-responsive gauge to the tank sprite.

const PRESSURE_START := 0.82


class SupportFrame extends Node2D:
	func _draw() -> void:
		var dark_steel := Color(0.025, 0.043, 0.052)
		var steel := Color(0.24, 0.32, 0.34)
		var edge := Color(0.47, 0.57, 0.57)
		var brass := Color(0.62, 0.39, 0.18)
		var pipe_path := PackedVector2Array([
			Vector2(-48.0, 2.0), Vector2(-55.0, 2.0), Vector2(-59.0, 6.0),
			Vector2(-59.0, 24.0), Vector2(-50.0, 29.0),
		])
		draw_polyline(pipe_path, dark_steel, 5.0, true)
		draw_polyline(pipe_path, steel, 3.0, true)
		draw_polyline(PackedVector2Array([Vector2(-57.5, 9.0), Vector2(-57.5, 23.0)]), Color(0.18, 0.56, 0.59), 1.0, true)
		var return_pipe := PackedVector2Array([
			Vector2(72.0, 4.0), Vector2(79.0, 4.0), Vector2(83.0, 8.0),
			Vector2(83.0, 23.0), Vector2(73.0, 29.0),
		])
		draw_polyline(return_pipe, dark_steel, 5.0, true)
		draw_polyline(return_pipe, steel, 3.0, true)
		draw_polyline(PackedVector2Array([Vector2(81.5, 11.0), Vector2(81.5, 22.0)]), Color(0.18, 0.56, 0.59), 1.0, true)

		# A bolted cradle carries the vessel's weight instead of leaving it floating.
		draw_rect(Rect2(Vector2(-50.0, 22.0), Vector2(132.0, 5.0)), dark_steel, true)
		draw_rect(Rect2(Vector2(-47.0, 21.0), Vector2(126.0, 2.0)), steel, true)
		draw_line(Vector2(-47.0, 21.0), Vector2(79.0, 21.0), edge, 1.0, true)
		for foot_x in [-34.0, 58.0]:
			draw_polygon(PackedVector2Array([
				Vector2(foot_x - 4.0, 18.0), Vector2(foot_x + 4.0, 18.0),
				Vector2(foot_x + 7.0, 29.0), Vector2(foot_x - 7.0, 29.0),
			]), PackedColorArray([steel, steel, dark_steel, dark_steel]))
			draw_line(Vector2(foot_x - 4.0, 19.0), Vector2(foot_x + 4.0, 19.0), edge, 1.0, true)
			draw_circle(Vector2(foot_x, 26.0), 1.2, brass)
		for bolt_x in [-43.0, -18.0, 47.0, 72.0]:
			draw_circle(Vector2(bolt_x, 23.5), 0.9, edge)


class PressureGauge extends Node2D:
	var pressure := 0.82
	var specimen_active := false
	var pulse_time := 0.0

	func _process(delta: float) -> void:
		pulse_time = fposmod(pulse_time + delta * 5.0, TAU)
		queue_redraw()

	func _draw() -> void:
		# Overlay a readable moving needle on the tiny printed gauge in the tank art.
		var gauge_center := Vector2(-24.5, -3.5)
		var pressure_fraction := clampf((pressure - 0.7) / 0.6, 0.0, 1.0)
		var needle_angle := lerpf(deg_to_rad(138.0), deg_to_rad(42.0), pressure_fraction)
		var safe := absf(pressure - 1.0) <= 0.03
		draw_circle(gauge_center, 5.2, Color(0.015, 0.026, 0.032, 0.96))
		draw_circle(gauge_center, 4.5, Color(0.35, 0.47, 0.47))
		draw_circle(gauge_center, 3.8, Color(0.02, 0.055, 0.067))
		draw_arc(gauge_center, 3.1, deg_to_rad(40.0), deg_to_rad(140.0), 20, Color(0.72, 0.81, 0.76), 0.55, true)
		for tick in range(5):
			var tick_angle := lerpf(deg_to_rad(42.0), deg_to_rad(138.0), float(tick) / 4.0)
			var tick_inner := gauge_center + Vector2(cos(tick_angle), sin(tick_angle)) * 2.6
			var tick_outer := gauge_center + Vector2(cos(tick_angle), sin(tick_angle)) * 3.3
			draw_line(tick_inner, tick_outer, Color(0.8, 0.86, 0.79), 0.55, true)
		draw_line(gauge_center, gauge_center + Vector2(cos(needle_angle), sin(needle_angle)) * 2.9, Color(1.0, 0.68, 0.32), 0.9, true)
		draw_circle(gauge_center, 0.8, Color(0.9, 0.91, 0.82))

		var lamp_color := Color(1.0, 0.25, 0.18) if specimen_active else Color(0.28, 0.95, 0.63) if safe else Color(1.0, 0.66, 0.24)
		var lamp_alpha := 0.68 + 0.32 * (sin(pulse_time) + 1.0) * 0.5 if specimen_active else 1.0
		var lamp_center := Vector2(52.0, -7.0)
		draw_circle(lamp_center, 2.4, Color(0.025, 0.04, 0.045))
		var lamp_fill := lamp_color
		lamp_fill.a = lamp_alpha
		draw_circle(lamp_center, 1.45, lamp_fill)
		draw_circle(lamp_center + Vector2(-0.45, -0.45), 0.45, Color(1.0, 1.0, 1.0, 0.72))


class ResonanceChamberVFX extends Node2D:
	var pulse_time := 0.0
	var pressure := 0.82
	var specimen_active := false

	func _process(delta: float) -> void:
		pulse_time = fposmod(pulse_time + delta * 3.5, 1000.0)
		queue_redraw()

	func _draw() -> void:
		var center := Vector2(14.0, -4.0)
		var unstable: bool = specimen_active or absf(pressure - 1.0) > 0.12
		var pulse: float = 0.75 + 0.25 * sin(pulse_time * (6.0 if unstable else 2.5))

		# 1. Glowing alien resonance core (shifting cyan / magenta / violet)
		var res_col := Color.from_hsv(lerpf(0.52, 0.82, 0.5 + 0.5 * sin(pulse_time * 1.5)), 0.85, 0.95, 0.45 * pulse)
		draw_circle(center, 24.0 * pulse, Color(res_col.r, res_col.g, res_col.b, 0.16 * pulse))
		draw_circle(center, 13.0 * pulse, Color(res_col.r, res_col.g, res_col.b, 0.38 * pulse))
		draw_circle(center, 5.0, Color(1.0, 1.0, 1.0, 0.88 * pulse))

		# 2. Concentric spatial ripple rings pulsing outward
		for r_i in range(3):
			var r_prog: float = fposmod(pulse_time * 0.45 + float(r_i) * 0.33, 1.0)
			var r_rad: float = 6.0 + r_prog * 28.0
			var r_alpha: float = (1.0 - r_prog) * (0.65 if unstable else 0.35)
			draw_arc(center, r_rad, 0.0, TAU, 22, Color(res_col.r, res_col.g, res_col.b, r_alpha), 1.3, false)

		# 3. Levitating crystalline shards inside the tank
		for c_i in range(5):
			var c_ang: float = float(c_i) * 1.25 + pulse_time * (1.2 if unstable else 0.5)
			var c_dist: float = 4.0 + 8.0 * (0.5 + 0.5 * sin(pulse_time * 2.0 + float(c_i)))
			var c_pos := center + Vector2(cos(c_ang), sin(c_ang) * 0.6) * c_dist
			draw_rect(Rect2(c_pos - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(res_col.r, res_col.g, res_col.b, 0.85))
			draw_circle(c_pos, 0.8, Color(1.0, 1.0, 1.0, 0.95))

		# 4. Crackling crystalline electric arcs across the glass
		if unstable:
			for arc_i in range(3):
				var a_phase: float = fposmod(pulse_time * 5.0 + float(arc_i) * 1.7, 1.0)
				if a_phase > 0.4:
					continue
				var a_start := center + Vector2(-15.0 + float(arc_i) * 12.0, -18.0)
				var a_end := center + Vector2(-12.0 + float(arc_i) * 14.0, 14.0)
				var prev := a_start
				for seg in range(1, 5):
					var t_seg := float(seg) / 4.0
					var jit := sin(pulse_time * 30.0 + float(seg) * 2.5) * 5.0
					var next_p := a_start.lerp(a_end, t_seg) + Vector2(jit, 0.0)
					draw_line(prev, next_p, Color(0.35, 0.95, 1.0, 0.85), 1.4, false)
					prev = next_p


var _gauge: PressureGauge
var _chamber_vfx: ResonanceChamberVFX


func _ready() -> void:
	var compensation := Vector2(1.0 / scale.x, 1.0 / scale.y)
	var support := SupportFrame.new()
	support.name = "TankSupportFrame"
	support.scale = compensation
	support.z_index = -1
	add_child(support)
	_chamber_vfx = ResonanceChamberVFX.new()
	_chamber_vfx.name = "ResonanceChamberVFX"
	_chamber_vfx.scale = compensation
	_chamber_vfx.z_index = 1
	add_child(_chamber_vfx)
	_gauge = PressureGauge.new()
	_gauge.name = "LivePressureGauge"
	_gauge.scale = compensation
	_gauge.z_index = 2
	add_child(_gauge)


func _process(_delta: float) -> void:
	if not is_instance_valid(_gauge):
		return
	_gauge.pressure = float(Engine.get_meta(&"resonance_ore_chamber_pressure", PRESSURE_START))
	_gauge.specimen_active = Engine.has_meta(&"resonance_ore_stimulated") and bool(Engine.get_meta(&"resonance_ore_stimulated"))
	if is_instance_valid(_chamber_vfx):
		_chamber_vfx.pressure = _gauge.pressure
		_chamber_vfx.specimen_active = _gauge.specimen_active
