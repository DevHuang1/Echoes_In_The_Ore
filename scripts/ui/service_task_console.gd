class_name ServiceTaskConsole
extends CanvasLayer

const SKIN := preload("res://scripts/ui/pixel_ui.gd")

signal task_completed(task_id: StringName)
signal console_closed

const GOLD := Color(1.0, 0.77, 0.34)
const PALE := Color(0.94, 0.91, 0.82)
const MUTED := Color(0.59, 0.69, 0.73)
const CYAN := Color(0.36, 0.9, 1.0)
const ORANGE := Color(1.0, 0.68, 0.32)
const MINT := Color(0.53, 0.94, 0.75)
const GREEN := Color(0.48, 0.93, 0.64)
const POWER_CELL_NAMES := ["AUX CELL", "BUFFER", "MINING BUS"]
const POWER_START_VALUES := [28.0, 81.0, 45.0]
const POWER_TARGET_LOW := [62.0, 38.0, 72.0]
const POWER_TARGET_HIGH := [72.0, 48.0, 82.0]
const POWER_CELL_COLORS := [CYAN, GOLD, MINT]


class PowerDiagram extends Control:
	const PALE := Color(0.94, 0.91, 0.82)
	const MUTED := Color(0.59, 0.69, 0.73)
	const CYAN := Color(0.36, 0.9, 1.0)
	const GREEN := Color(0.48, 0.93, 0.64)
	const ORANGE := Color(1.0, 0.68, 0.32)

	var channel_names: Array[String] = []
	var charge_values: Array[float] = []
	var target_lows: Array[float] = []
	var target_highs: Array[float] = []
	var channel_colors: Array[Color] = []

	func _draw() -> void:
		var card_rect := Rect2(Vector2(8.0, 8.0), size - Vector2(16.0, 16.0))
		draw_style_box(get_theme_stylebox("normal", "InventorySlot"), card_rect)
		var font := get_theme_font("font", "Label")
		if font == null:
			return
		draw_string(font, Vector2(24.0, 34.0), "AUX POWER BUS  /  CELL BANK", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, MUTED)
		draw_line(Vector2(24.0, 47.0), Vector2(size.x - 24.0, 47.0), Color(0.31, 0.47, 0.5), 1.0, false)

		var feed_rail := Rect2(Vector2(24.0, 53.0), Vector2(size.x - 48.0, 8.0))
		draw_rect(feed_rail, Color(0.012, 0.025, 0.031), true)
		draw_rect(Rect2(feed_rail.position + Vector2(0.0, 1.0), Vector2(feed_rail.size.x, 2.0)), Color(0.68, 0.43, 0.19), true)
		draw_line(Vector2(feed_rail.position.x, feed_rail.end.y - 1.0), Vector2(feed_rail.end.x, feed_rail.end.y - 1.0), Color(0.4, 0.52, 0.5), 1.0, false)
		for screw_position in [Vector2(16.0, 16.0), Vector2(size.x - 16.0, 16.0), Vector2(16.0, size.y - 16.0), Vector2(size.x - 16.0, size.y - 16.0)]:
			var screw_rect := Rect2(screw_position - Vector2(2.0, 2.0), Vector2(4.0, 4.0))
			draw_rect(screw_rect, Color(0.31, 0.42, 0.43), true)
			draw_line(screw_rect.position + Vector2(1.0, 2.0), screw_rect.position + Vector2(3.0, 2.0), Color(0.06, 0.10, 0.11), 1.0)

		var slot_width := minf(62.0, (size.x - 82.0) / 3.0)
		var gap := (size.x - slot_width * 3.0) / 4.0
		var bar_top := 92.0
		var bar_height := size.y - 165.0
		for index in range(channel_names.size()):
			var x := gap + float(index) * (slot_width + gap)
			var cell_name: String = channel_names[index]
			var value: float = charge_values[index]
			var low: float = target_lows[index]
			var high: float = target_highs[index]
			var color: Color = channel_colors[index]
			var in_range := value >= low and value <= high
			var connector_x := x + slot_width * 0.5
			var cable_color := color if in_range else color.darkened(0.28)
			draw_line(Vector2(connector_x, feed_rail.end.y - 1.0), Vector2(connector_x, bar_top - 16.0), Color(0.008, 0.018, 0.024), 7.0, false)
			draw_line(Vector2(connector_x, feed_rail.end.y - 1.0), Vector2(connector_x, bar_top - 16.0), cable_color, 3.0, false)
			var rail_terminal := Rect2(Vector2(connector_x - 5.0, feed_rail.position.y), Vector2(10.0, 8.0))
			draw_rect(rail_terminal, Color(0.52, 0.56, 0.5), true)
			draw_rect(Rect2(rail_terminal.position + Vector2(3.0, 2.0), Vector2(4.0, 4.0)), cable_color, true)
			var cell_terminal := Rect2(Vector2(connector_x - 6.0, bar_top - 17.0), Vector2(12.0, 8.0))
			draw_rect(cell_terminal, Color(0.45, 0.53, 0.52), true)
			draw_rect(Rect2(cell_terminal.position + Vector2(4.0, 2.0), Vector2(4.0, 4.0)), cable_color, true)
			var bar := Rect2(Vector2(x, bar_top), Vector2(slot_width, bar_height))
			draw_rect(bar, Color(0.012, 0.027, 0.036), true)
			draw_rect(Rect2(bar.position, Vector2(3.0, bar.size.y)), Color(0.22, 0.32, 0.34), true)
			draw_rect(Rect2(Vector2(bar.end.x - 3.0, bar.position.y), Vector2(3.0, bar.size.y)), Color(0.08, 0.14, 0.16), true)
			var target_top := bar.position.y + bar.size.y * (1.0 - high / 100.0)
			var target_height := bar.size.y * (high - low) / 100.0
			var target_band := Rect2(Vector2(bar.position.x + 3.0, target_top), Vector2(bar.size.x - 6.0, target_height))
			draw_rect(target_band, Color(GREEN.r, GREEN.g, GREEN.b, 0.22), true)
			var segment_count := 20
			var segment_gap := 2.0
			var inner_height := bar.size.y - 8.0
			var segment_height := (inner_height - segment_gap * float(segment_count - 1)) / float(segment_count)
			for segment_index in range(segment_count):
				var segment_top := bar.position.y + 4.0 + float(segment_index) * (segment_height + segment_gap)
				var segment_low := 100.0 - float(segment_index + 1) * 5.0
				var segment_high := 100.0 - float(segment_index) * 5.0
				var target_segment := segment_high > low and segment_low < high
				var filled := value > segment_low
				var segment_color := Color(color.r, color.g, color.b, 0.94) if in_range else Color(color.r, color.g, color.b, 0.70)
				if filled:
					draw_rect(Rect2(Vector2(bar.position.x + 5.0, segment_top), Vector2(bar.size.x - 10.0, segment_height)), segment_color, true)
				elif target_segment:
					draw_rect(Rect2(Vector2(bar.position.x + 5.0, segment_top), Vector2(bar.size.x - 10.0, segment_height)), Color(GREEN.r, GREEN.g, GREEN.b, 0.34), true)
				else:
					draw_rect(Rect2(Vector2(bar.position.x + 5.0, segment_top), Vector2(bar.size.x - 10.0, segment_height)), Color(0.12, 0.19, 0.21), true)
			draw_line(Vector2(bar.position.x + 3.0, target_top), Vector2(bar.end.x - 3.0, target_top), GREEN, 1.0, false)
			draw_line(Vector2(bar.position.x + 3.0, target_top + target_height), Vector2(bar.end.x - 3.0, target_top + target_height), GREEN, 1.0, false)
			draw_rect(bar, Color(0.43, 0.58, 0.60), false, 1.0)
			draw_string(font, Vector2(x - 16.0, bar.end.y + 22.0), "%02d%%" % roundi(value), HORIZONTAL_ALIGNMENT_CENTER, slot_width + 32.0, 12, GREEN if in_range else PALE)
			draw_string(font, Vector2(x - 18.0, bar.end.y + 40.0), "%s" % cell_name, HORIZONTAL_ALIGNMENT_CENTER, slot_width + 36.0, 10, MUTED)
			var indicator := Rect2(Vector2(x + slot_width * 0.5 - 3.0, bar_top - 8.0), Vector2(6.0, 6.0))
			draw_rect(indicator, GREEN if in_range else ORANGE, true)
			draw_rect(indicator, Color(0.76, 0.84, 0.79), false, 1.0)


class FilterDiagram extends Control:
	const GOLD := Color(1.0, 0.77, 0.34)
	const MUTED := Color(0.59, 0.69, 0.73)
	const ORANGE := Color(1.0, 0.68, 0.32)
	const CYAN := Color(0.36, 0.9, 1.0)
	const GREEN := Color(0.48, 0.93, 0.64)

	var filter_removed := false
	var cartridge_seated := false
	var rotation_step := 0
	var airflow := 18.0

	func _draw() -> void:
		var card_rect := Rect2(Vector2(8.0, 8.0), size - Vector2(16.0, 16.0))
		draw_style_box(get_theme_stylebox("normal", "InventorySlot"), card_rect)
		var font := get_theme_font("font", "Label")
		if font == null:
			return
		draw_string(font, Vector2(24.0, 35.0), "LIFE SUPPORT / FILTER B-04", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, MUTED)
		draw_line(Vector2(24.0, 48.0), Vector2(size.x - 24.0, 48.0), Color(0.31, 0.47, 0.5), 1.0, false)

		var housing := Rect2(size.x * 0.30, 68.0, size.x * 0.40, size.y - 132.0)
		var pipe_y := housing.position.y + housing.size.y * 0.53
		var pipe_top_y := pipe_y - 42.0
		var intake_bend_x := maxf(72.0, minf(size.x * 0.20, housing.position.x - 16.0))
		var outlet_bend_x := minf(size.x - 72.0, maxf(size.x * 0.80, housing.end.x + 16.0))
		var flow_color := GREEN if cartridge_seated and airflow >= 62.0 and airflow <= 72.0 else CYAN if cartridge_seated else ORANGE
		var flow_tint := flow_color
		flow_tint.a = 0.2 + clampf(airflow / 100.0, 0.0, 1.0) * 0.58
		var intake_route := PackedVector2Array([
			Vector2(66.0, pipe_top_y),
			Vector2(intake_bend_x, pipe_top_y),
			Vector2(intake_bend_x, pipe_y),
			Vector2(housing.position.x, pipe_y),
		])
		var outlet_route := PackedVector2Array([
			Vector2(housing.end.x, pipe_y),
			Vector2(outlet_bend_x, pipe_y),
			Vector2(outlet_bend_x, pipe_top_y),
			Vector2(size.x - 55.0, pipe_top_y),
		])
		_draw_duct(intake_route, flow_tint)
		_draw_duct(outlet_route, flow_tint)
		_draw_intake_grille(Vector2(43.0, pipe_top_y))
		_draw_pressure_gauge(Vector2(size.x - 32.0, pipe_top_y), flow_color)
		draw_string(font, Vector2(20.0, pipe_top_y - 25.0), "INTAKE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, MUTED)
		draw_string(font, Vector2(size.x - 71.0, pipe_top_y - 25.0), "PRESS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, MUTED)
		_draw_air_arrow(Vector2(size.x * 0.24, pipe_y), flow_color)
		_draw_air_arrow(Vector2(size.x * 0.76, pipe_y), flow_color)

		draw_rect(housing, Color(0.09, 0.16, 0.18), true)
		draw_rect(Rect2(housing.position, Vector2(housing.size.x, 4.0)), Color(0.62, 0.72, 0.7), true)
		draw_rect(Rect2(Vector2(housing.position.x, housing.end.y - 4.0), Vector2(housing.size.x, 4.0)), Color(0.12, 0.22, 0.23), true)
		draw_rect(housing, Color(0.58, 0.68, 0.66), false, 1.0, false)
		for screw_position in [housing.position + Vector2(7.0, 7.0), Vector2(housing.end.x - 7.0, housing.position.y + 7.0), housing.position + Vector2(7.0, housing.size.y - 7.0), housing.end - Vector2(7.0, 7.0)]:
			var screw_rect := Rect2(screw_position - Vector2(2.0, 2.0), Vector2(4.0, 4.0))
			draw_rect(screw_rect, Color(0.48, 0.61, 0.59), true)
			draw_line(screw_rect.position + Vector2(1.0, 2.0), screw_rect.position + Vector2(3.0, 2.0), Color(0.06, 0.10, 0.11), 1.0)
		var inner := housing.grow(-12.0)
		draw_rect(inner, Color(0.018, 0.035, 0.045), true)
		draw_rect(inner, Color(0.32, 0.48, 0.5), false, 1.0, false)
		_draw_pipe_coupler(Vector2(housing.position.x, pipe_y))
		_draw_pipe_coupler(Vector2(housing.end.x, pipe_y))

		if filter_removed and not cartridge_seated:
			draw_string(font, Vector2(inner.position.x + 14.0, inner.position.y + inner.size.y * 0.55), "HOUSING OPEN", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, GOLD)
			var spare_filter := Rect2(Vector2(24.0, size.y - 142.0), Vector2(34.0, 94.0))
			draw_rect(spare_filter, Color(0.10, 0.17, 0.18), true)
			draw_rect(spare_filter, Color(0.65, 0.76, 0.7), false, 1.0, false)
			for line_index in range(1, 5):
				var line_y := spare_filter.position.y + spare_filter.size.y * float(line_index) / 5.0
				draw_line(Vector2(spare_filter.position.x + 3.0, line_y), Vector2(spare_filter.end.x - 3.0, line_y), Color(0.29, 0.68, 0.59), 1.0, false)
			var notch_direction := Vector2(cos(float(rotation_step) * PI * 0.5 + PI * 0.5), sin(float(rotation_step) * PI * 0.5 + PI * 0.5))
			draw_circle(spare_filter.get_center() + notch_direction * spare_filter.size.y * 0.38, 4.0, GOLD if rotation_step == 2 else ORANGE)
			draw_string(font, Vector2(spare_filter.position.x + 3.0, spare_filter.position.y + 14.0), "NEW", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, CYAN)
		else:
			var filter_rect := Rect2(inner.position + Vector2(10.0, 10.0), inner.size - Vector2(20.0, 20.0))
			draw_rect(filter_rect, Color(0.11, 0.19, 0.19), true)
			draw_rect(filter_rect, Color(0.59, 0.69, 0.6), false, 1.0, false)
			var mesh_color := Color(0.39, 0.24, 0.15) if not filter_removed else Color(0.21, 0.49, 0.44)
			for line_index in range(1, 7):
				var line_x := filter_rect.position.x + filter_rect.size.x * float(line_index) / 7.0
				draw_line(Vector2(line_x, filter_rect.position.y + 4.0), Vector2(line_x, filter_rect.end.y - 4.0), mesh_color, 2.0, false)
			for line_index in range(1, 9):
				var line_y := filter_rect.position.y + filter_rect.size.y * float(line_index) / 9.0
				draw_line(Vector2(filter_rect.position.x + 4.0, line_y), Vector2(filter_rect.end.x - 4.0, line_y), mesh_color, 1.0, false)
			var notch_angle := float(rotation_step) * PI * 0.5 + PI * 0.5
			var notch_center := filter_rect.get_center() + Vector2(cos(notch_angle), sin(notch_angle)) * (filter_rect.size.y * 0.42)
			draw_circle(notch_center, 5.0, GOLD if rotation_step == 2 else ORANGE)
			if not filter_removed:
				draw_string(font, Vector2(filter_rect.position.x, filter_rect.end.y - 10.0), "CLOGGED 88%", HORIZONTAL_ALIGNMENT_CENTER, filter_rect.size.x, 10, ORANGE)
			elif cartridge_seated:
				draw_string(font, Vector2(filter_rect.position.x, filter_rect.end.y - 10.0), "SEALED", HORIZONTAL_ALIGNMENT_CENTER, filter_rect.size.x, 12, GREEN)

		draw_string(font, Vector2(24.0, size.y - 31.0), "AIRFLOW  %d%%" % roundi(airflow), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, GREEN if airflow >= 62.0 and airflow <= 72.0 else MUTED)
		draw_string(font, Vector2(size.x - 154.0, size.y - 31.0), "TARGET  /  62–72%", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, MUTED)
		var gauge := Rect2(Vector2(24.0, size.y - 20.0), Vector2(size.x - 48.0, 5.0))
		var gauge_segments := 40
		var gauge_gap := 1.0
		var gauge_segment_width := (gauge.size.x - gauge_gap * float(gauge_segments - 1)) / float(gauge_segments)
		for segment_index in range(gauge_segments):
			var segment_x := gauge.position.x + float(segment_index) * (gauge_segment_width + gauge_gap)
			var segment_low := float(segment_index) * 100.0 / float(gauge_segments)
			var segment_high := float(segment_index + 1) * 100.0 / float(gauge_segments)
			var in_target := segment_high > 62.0 and segment_low < 72.0
			var is_filled := airflow >= segment_high
			var segment_color := GREEN if airflow >= 62.0 and airflow <= 72.0 else CYAN
			if is_filled:
				draw_rect(Rect2(Vector2(segment_x, gauge.position.y), Vector2(gauge_segment_width, gauge.size.y)), segment_color, true)
			elif in_target:
				draw_rect(Rect2(Vector2(segment_x, gauge.position.y), Vector2(gauge_segment_width, gauge.size.y)), Color(GREEN.r, GREEN.g, GREEN.b, 0.55), true)
			else:
				draw_rect(Rect2(Vector2(segment_x, gauge.position.y), Vector2(gauge_segment_width, gauge.size.y)), Color(0.12, 0.20, 0.22), true)
		for tick_index in range(21):
			var tick_x := gauge.position.x + gauge.size.x * float(tick_index) / 20.0
			var tick_height := 4.0 if tick_index % 5 == 0 else 2.0
			draw_line(Vector2(tick_x, gauge.position.y - 1.0), Vector2(tick_x, gauge.position.y - tick_height), Color(0.50, 0.63, 0.61, 0.75), 1.0)

	func _draw_duct(path: PackedVector2Array, glow_color: Color) -> void:
		draw_polyline(path, Color(0.008, 0.018, 0.025), 24.0, false)
		draw_polyline(path, Color(0.31, 0.43, 0.46), 19.0, false)
		draw_polyline(path, Color(0.035, 0.075, 0.092), 12.0, false)
		draw_polyline(path, glow_color, 3.0, false)

	func _draw_intake_grille(center: Vector2) -> void:
		var grille := Rect2(center - Vector2(23.0, 19.0), Vector2(46.0, 38.0))
		draw_rect(grille, Color(0.025, 0.052, 0.063), true)
		draw_rect(Rect2(grille.position, Vector2(grille.size.x, 3.0)), Color(0.62, 0.72, 0.7), true)
		draw_rect(grille, Color(0.42, 0.56, 0.58), false, 1.0, false)
		for slat_index in range(1, 6):
			var slat_y := grille.position.y + float(slat_index) * grille.size.y / 6.0
			draw_line(Vector2(grille.position.x + 5.0, slat_y), Vector2(grille.end.x - 5.0, slat_y), Color(0.29, 0.43, 0.46), 2.0, false)
		draw_rect(Rect2(grille.position + Vector2(4.0, 4.0), Vector2(3.0, 3.0)), CYAN, true)

	func _draw_pressure_gauge(center: Vector2, accent: Color) -> void:
		draw_circle(center, 18.0, Color(0.012, 0.028, 0.038))
		draw_circle(center, 15.0, Color(0.36, 0.49, 0.51))
		draw_circle(center, 12.0, Color(0.028, 0.062, 0.073))
		draw_arc(center, 9.0, PI * 0.78, PI * 2.22, 18, Color(0.76, 0.84, 0.8), 1.0, false)
		for tick_index in range(5):
			var tick_angle := lerpf(PI * 0.78, PI * 2.22, float(tick_index) / 4.0)
			var tick_inner := center + Vector2(cos(tick_angle), sin(tick_angle)) * 8.0
			var tick_outer := center + Vector2(cos(tick_angle), sin(tick_angle)) * 11.0
			draw_line(tick_inner, tick_outer, Color(0.76, 0.84, 0.8), 1.0, false)
		var needle_angle := lerpf(PI * 0.82, PI * 2.18, clampf(airflow / 100.0, 0.0, 1.0))
		draw_line(center, center + Vector2(cos(needle_angle), sin(needle_angle)) * 8.0, accent, 2.0, false)
		draw_circle(center, 2.0, PALE)

	func _draw_pipe_coupler(center: Vector2) -> void:
		var collar := Rect2(center - Vector2(5.0, 14.0), Vector2(10.0, 28.0))
		draw_rect(collar, Color(0.56, 0.67, 0.66), true)
		draw_rect(Rect2(collar.position + Vector2(3.0, 2.0), Vector2(4.0, 24.0)), Color(0.14, 0.24, 0.26), true)
		draw_line(Vector2(collar.position.x + 1.0, center.y - 10.0), Vector2(collar.end.x - 1.0, center.y - 10.0), Color(0.77, 0.84, 0.78), 1.0, false)
		draw_line(Vector2(collar.position.x + 1.0, center.y + 10.0), Vector2(collar.end.x - 1.0, center.y + 10.0), Color(0.26, 0.37, 0.39), 1.0, false)

	func _draw_air_arrow(center: Vector2, accent: Color) -> void:
		draw_line(center + Vector2(-5.0, -4.0), center + Vector2(0.0, 0.0), accent, 1.5, false)
		draw_line(center + Vector2(0.0, 0.0), center + Vector2(-5.0, 4.0), accent, 1.5, false)
		draw_line(center + Vector2(-4.0, 0.0), center + Vector2(3.0, 0.0), accent, 1.0, false)


class NutrientDiagram extends Control:
	const PALE := Color(0.94, 0.91, 0.82)
	const MUTED := Color(0.59, 0.69, 0.73)
	const GOLD := Color(1.0, 0.77, 0.34)
	const CYAN := Color(0.36, 0.9, 1.0)
	const GREEN := Color(0.48, 0.93, 0.64)
	const LEAF := Color(0.42, 0.9, 0.34)

	var rotations: Array[int] = []
	var targets: Array[int] = []

	func all_aligned() -> bool:
		if rotations.size() != targets.size() or rotations.is_empty():
			return false
		for index in range(rotations.size()):
			if rotations[index] != targets[index]:
				return false
		return true

	func _draw() -> void:
		var card := Rect2(Vector2(8.0, 8.0), size - Vector2(16.0, 16.0))
		draw_style_box(get_theme_stylebox("normal", "InventorySlot"), card)
		var font := get_theme_font("font", "Label")
		if font == null:
			return
		draw_string(font, Vector2(24.0, 35.0), "HYDROPONIC / NUTRIENT MANIFOLD", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, MUTED)
		draw_line(Vector2(24.0, 48.0), Vector2(size.x - 24.0, 48.0), Color(0.31, 0.47, 0.5), 1.0, false)

		var aligned := all_aligned()
		var pipe_y := size.y * 0.38
		var tray_y := size.y * 0.68
		var return_y := size.y * 0.87
		var pump_center := Vector2(58.0, pipe_y)
		var valve_centers: Array[Vector2] = []
		var tray_centers: Array[Vector2] = []
		var usable_width := size.x - 142.0
		for index in range(3):
			var x := 112.0 + usable_width * float(index + 1) / 4.0
			valve_centers.append(Vector2(x, pipe_y))
			tray_centers.append(Vector2(x, tray_y))

		var route_points := PackedVector2Array([pump_center + Vector2(27.0, 0.0), valve_centers[0]])
		_draw_pipe(route_points, CYAN if rotations[0] == targets[0] else GOLD)
		for index in range(2):
			var segment_color: Color = GREEN if aligned else CYAN if rotations[index] == targets[index] else GOLD
			_draw_pipe(PackedVector2Array([valve_centers[index], valve_centers[index + 1]]), segment_color)
		for index in range(3):
			var branch_start := valve_centers[index] + Vector2(0.0, 13.0)
			var branch_end := Vector2(tray_centers[index].x, tray_y - 17.0)
			var branch_color: Color = GREEN if aligned else CYAN if rotations[index] == targets[index] else GOLD
			_draw_pipe(PackedVector2Array([branch_start, branch_end]), branch_color, 7.0)
			_draw_valve(valve_centers[index], rotations[index], targets[index], rotations[index] == targets[index])
			_draw_grow_tray(tray_centers[index], index, aligned)

		var pump_left := pump_center + Vector2(-25.0, -27.0)
		var pump_rect := Rect2(pump_left, Vector2(50.0, 54.0))
		draw_rect(pump_rect, Color(0.012, 0.028, 0.038), true)
		draw_rect(Rect2(pump_rect.position, Vector2(pump_rect.size.x, 4.0)), Color(0.72, 0.81, 0.78), true)
		draw_rect(pump_rect, Color(0.46, 0.61, 0.61), false, 1.0, false)
		draw_circle(pump_center, 17.0, Color(0.025, 0.07, 0.085))
		draw_circle(pump_center, 13.0, Color(0.36, 0.62, 0.61))
		draw_circle(pump_center, 9.0, Color(0.045, 0.13, 0.15))
		var pump_accent := GREEN if aligned else CYAN
		draw_line(pump_center, pump_center + Vector2(8.0, -6.0), pump_accent, 2.0, false)
		draw_circle(pump_center, 2.0, PALE)
		draw_string(font, Vector2(28.0, pump_rect.end.y + 15.0), "PUMP", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, MUTED)

		for index in range(3):
			var tray_center: Vector2 = tray_centers[index]
			var drop_points := PackedVector2Array([
				Vector2(tray_center.x, tray_y + 17.0),
				Vector2(tray_center.x, return_y),
			])
			_draw_pipe(drop_points, CYAN.darkened(0.12), 6.0)
		var return_color := GREEN if aligned else CYAN.darkened(0.12)
		_draw_pipe(PackedVector2Array([Vector2(tray_centers[2].x, return_y), Vector2(pump_center.x, return_y), Vector2(pump_center.x, pipe_y + 29.0)]), return_color, 7.0)
		draw_string(font, Vector2(size.x - 114.0, return_y - 7.0), "RETURN LINE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, MUTED)
		_draw_flow_arrow(Vector2(size.x - 146.0, return_y), return_color)

		for index in range(3):
			var valve := valve_centers[index]
			draw_string(font, Vector2(valve.x - 18.0, valve.y - 34.0), "V-%02d" % (index + 1), HORIZONTAL_ALIGNMENT_CENTER, 36.0, 10, MUTED)
		draw_string(font, Vector2(24.0, size.y - 29.0), "SUPPLY / %s" % ("FLOWING" if aligned else "BLOCKED"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, GREEN if aligned else GOLD)
		var target_text := "TARGET / 3 VALVES"
		var target_width := font.get_string_size(target_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(font, Vector2(size.x - 24.0 - target_width, size.y - 29.0), target_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, MUTED)

	func _draw_pipe(points: PackedVector2Array, accent: Color, width: float = 10.0) -> void:
		draw_polyline(points, Color(0.008, 0.018, 0.025), width + 5.0, false)
		draw_polyline(points, Color(0.34, 0.48, 0.5), width + 2.0, false)
		draw_polyline(points, Color(0.035, 0.075, 0.092), width - 1.0, false)
		draw_polyline(points, accent, 2.0, false)

	func _draw_valve(center: Vector2, rotation: int, target: int, correct: bool) -> void:
		draw_circle(center, 15.0, Color(0.012, 0.026, 0.034))
		draw_circle(center, 12.0, Color(0.47, 0.59, 0.56))
		draw_circle(center, 8.0, Color(0.034, 0.09, 0.105))
		var target_angle := float(target) * PI * 0.5 - PI * 0.5
		var handle_angle := float(rotation) * PI * 0.5 - PI * 0.5
		var target_end := center + Vector2(cos(target_angle), sin(target_angle)) * 10.0
		var handle_end := center + Vector2(cos(handle_angle), sin(handle_angle)) * 7.0
		draw_line(center, target_end, GOLD, 2.0, false)
		draw_line(center, handle_end, GREEN if correct else PALE, 2.0, false)
		draw_circle(center, 2.0, GREEN if correct else CYAN)

	func _draw_grow_tray(center: Vector2, index: int, flowing: bool) -> void:
		var tray := Rect2(center + Vector2(-26.0, -10.0), Vector2(52.0, 25.0))
		draw_rect(tray, Color(0.012, 0.028, 0.038), true)
		draw_rect(Rect2(tray.position, Vector2(tray.size.x, 4.0)), Color(0.68, 0.76, 0.72), true)
		draw_rect(tray, Color(0.44, 0.57, 0.56), false, 1.0, false)
		draw_rect(Rect2(tray.position + Vector2(4.0, 16.0), Vector2(tray.size.x - 8.0, 5.0)), Color(0.22, 0.16, 0.1), true)
		var leaf_color := LEAF if flowing else Color(0.62, 0.75, 0.34)
		for plant_index in range(3):
			var leaf_x := tray.position.x + 11.0 + float(plant_index) * 15.0
			var stem_base := Vector2(leaf_x, tray.position.y + 17.0)
			var stem_top := stem_base + Vector2(0.0, -12.0 - float((index + plant_index) % 2) * 3.0)
			draw_line(stem_base, stem_top, Color(0.33, 0.73, 0.34), 1.5, false)
			draw_line(stem_top, stem_top + Vector2(-5.0, -3.0), leaf_color, 2.5, false)
			draw_line(stem_top, stem_top + Vector2(5.0, -4.0), leaf_color, 2.5, false)
		draw_circle(Vector2(tray.position.x + 5.0, tray.position.y + 6.0), 2.0, CYAN)

	func _draw_flow_arrow(center: Vector2, accent: Color) -> void:
		draw_line(center + Vector2(-6.0, -4.0), center, accent, 1.5, false)
		draw_line(center, center + Vector2(-6.0, 4.0), accent, 1.5, false)


class LabStationDisplay extends Control:
	const GOLD := Color(1.0, 0.78, 0.38)
	const PALE := Color(0.91, 0.96, 0.96)
	const MUTED := Color(0.43, 0.59, 0.62)
	const CYAN := Color(0.36, 0.9, 1.0)
	const MINT := Color(0.53, 0.94, 0.75)
	const GREEN := Color(0.48, 0.93, 0.64)
	const ORANGE := Color(1.0, 0.57, 0.32)

	var task_id: StringName = &""
	var status_text := "STANDBY"
	var scan_complete := false
	var single_sample_index := -1
	var joint_angles := Vector3(0.0, 0.0, 0.0)
	var clamp_closed := false
	var chamber_pressure := 1.0
	var containment_locks: Array[bool] = [true, true]
	var focus_position := 0.0
	var objective_magnification := 4

	func _draw() -> void:
		var bounds := Rect2(Vector2.ZERO, size)
		draw_rect(bounds, Color(0.018, 0.039, 0.052), true)
		draw_rect(bounds, Color(0.21, 0.36, 0.4), false, 1.0)
		draw_rect(Rect2(10.0, 10.0, size.x - 20.0, 23.0), Color(0.04, 0.084, 0.1), true)
		draw_string(ThemeDB.fallback_font, Vector2(18.0, 26.0), _station_name(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, 10, GOLD)
		match task_id:
			&"lab_specimen":
				_draw_spectrum()
			&"lab_containment":
				_draw_containment()
			&"lab_trolley":
				_draw_instruments()
			&"lab_earth_comms":
				_draw_research_console()
			&"lab_archive_01", &"lab_archive_02", &"lab_archive_03":
				_draw_archive()
			&"lab_robot_arm":
				_draw_robot_arm()
			_:
				_draw_generic_readout()
		draw_string(ThemeDB.fallback_font, Vector2(16.0, size.y - 12.0), status_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 32.0, 9, GREEN if scan_complete or status_text.contains("SECURE") else MUTED)

	func _station_name() -> String:
		match task_id:
			&"lab_specimen": return "ORE SPECTROMETER  /  SAMPLES 07 + 08"
			&"lab_containment": return "SEALED CHAMBER  /  PRESSURE LOCKS"
			&"lab_trolley": return "FIELD INSTRUMENTS  /  CALIBRATION"
			&"lab_archive_01": return "DATA ARCHIVE 01  /  PERSONNEL LOG"
			&"lab_archive_02": return "DATA ARCHIVE 02  /  SPECIMEN INDEX"
			&"lab_archive_03": return "DATA ARCHIVE 03  /  CONTAINMENT RECORD"
			&"lab_robot_arm": return "SAMPLE MANIPULATOR  /  GRIP CONTROL"
		return "LAB STATION  /  DIAGNOSTIC"

	func _draw_spectrum() -> void:
		var chart := Rect2(18.0, 48.0, size.x - 36.0, size.y - 91.0)
		_draw_chart_grid(chart)
		var first := PackedVector2Array()
		var second := PackedVector2Array()
		for index in range(33):
			var t := float(index) / 32.0
			var x := chart.position.x + t * chart.size.x
			var peak_a := exp(-pow((t - 0.34) * 18.0, 2.0)) * 0.62 + exp(-pow((t - 0.71) * 35.0, 2.0)) * 0.2
			var peak_b := exp(-pow((t - 0.38) * 19.0, 2.0)) * 0.5 + exp(-pow((t - 0.71) * 35.0, 2.0)) * 0.2
			first.append(Vector2(x, chart.end.y - 8.0 - peak_a * (chart.size.y - 18.0)))
			second.append(Vector2(x, chart.end.y - 8.0 - peak_b * (chart.size.y - 18.0)))
		if scan_complete:
			if single_sample_index != 1:
				draw_polyline(first, CYAN, 2.0, true)
			if single_sample_index != 0:
				draw_polyline(second, MINT, 1.5, true)
		if single_sample_index != 1:
			draw_string(ThemeDB.fallback_font, Vector2(chart.position.x + 3.0, chart.position.y + 13.0), "SAMPLE 07", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, CYAN)
		if single_sample_index != 0:
			draw_string(ThemeDB.fallback_font, Vector2(chart.position.x + 77.0, chart.position.y + 13.0), "SAMPLE 08", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, MINT)
		draw_line(Vector2(chart.position.x + chart.size.x * 0.71, chart.position.y), Vector2(chart.position.x + chart.size.x * 0.71, chart.end.y), ORANGE, 1.0, true)
		draw_string(ThemeDB.fallback_font, Vector2(chart.position.x + chart.size.x * 0.71 + 4.0, chart.end.y - 3.0), "17s", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, ORANGE)

	func _draw_containment() -> void:
		var chamber := Rect2(size.x * 0.38, 52.0, size.x * 0.24, size.y - 100.0)
		draw_rect(Rect2(chamber.position.x - 11.0, chamber.position.y - 5.0, chamber.size.x + 22.0, chamber.size.y + 10.0), Color(0.1, 0.19, 0.2), true)
		draw_rect(chamber, Color(0.025, 0.08, 0.09), true)
		draw_rect(chamber, CYAN.darkened(0.12), false, 2.0)
		draw_line(Vector2(chamber.position.x, chamber.position.y + 12.0), Vector2(chamber.end.x, chamber.position.y + 12.0), MUTED, 1.0)
		draw_line(Vector2(chamber.position.x, chamber.end.y - 12.0), Vector2(chamber.end.x, chamber.end.y - 12.0), MUTED, 1.0)
		draw_circle(chamber.get_center(), minf(chamber.size.x, chamber.size.y) * 0.23, Color(0.62, 0.39, 0.2, 0.92))
		draw_circle(chamber.get_center(), minf(chamber.size.x, chamber.size.y) * 0.15, Color(0.9, 0.66, 0.33, 0.9))
		for index in range(2):
			var y := chamber.position.y + 19.0 + float(index) * (chamber.size.y - 38.0)
			var lock := Rect2(chamber.position.x - 30.0, y - 5.0, 18.0, 10.0)
			draw_rect(lock, GREEN if containment_locks[index] else ORANGE, true)
			draw_string(ThemeDB.fallback_font, Vector2(18.0, y + 4.0), "NORTH LOCK" if index == 0 else "SOUTH LOCK", HORIZONTAL_ALIGNMENT_LEFT, 83.0, 8, PALE)
		draw_string(ThemeDB.fallback_font, Vector2(chamber.end.x + 15.0, chamber.position.y + 13.0), "PRESSURE", HORIZONTAL_ALIGNMENT_LEFT, 65.0, 8, MUTED)
		draw_string(ThemeDB.fallback_font, Vector2(chamber.end.x + 15.0, chamber.position.y + 30.0), "%.2f ATM" % chamber_pressure, HORIZONTAL_ALIGNMENT_LEFT, 70.0, 10, GREEN if status_text.contains("SECURE") or status_text.contains("PASSED") else CYAN)

	func _draw_research_console() -> void:
		var screen := Rect2(22.0, 49.0, size.x - 44.0, size.y - 88.0)
		draw_rect(screen, Color(0.012, 0.03, 0.04), true)
		draw_rect(screen, Color(0.25, 0.41, 0.44), false, 1.0)
		draw_string(ThemeDB.fallback_font, screen.position + Vector2(12.0, 18.0), "LOCAL CATALOG  /  LINK ACTIVE", HORIZONTAL_ALIGNMENT_LEFT, screen.size.x - 24.0, 9, GREEN)
		for index in range(4):
			var y := screen.position.y + 38.0 + float(index) * 35.0
			draw_circle(Vector2(screen.position.x + 15.0, y - 3.0), 3.0, CYAN if index == 0 else MUTED)
			draw_line(Vector2(screen.position.x + 25.0, y), Vector2(screen.end.x - 14.0, y), Color(0.43, 0.59, 0.62, 0.7), 2.0)
			draw_line(Vector2(screen.position.x + 25.0, y + 7.0), Vector2(screen.end.x - 50.0, y + 7.0), Color(0.21, 0.36, 0.4, 0.75), 1.0)

	func _draw_instruments() -> void:
		var center := Vector2(size.x * 0.49, size.y * 0.53)
		draw_circle(center, 38.0, Color(0.08, 0.15, 0.16))
		draw_circle(center, 29.0, Color(0.018, 0.04, 0.05))
		draw_arc(center, 27.0, -PI * 0.78, PI * 0.78, 36, CYAN, 2.0, true)
		draw_line(center, center + Vector2(15.0, -12.0), GOLD, 2.0, true)
		draw_circle(center + Vector2(15.0, -12.0), 3.0, PALE)
		var sample := Rect2(center.x + 49.0, center.y - 13.0, 17.0, 26.0)
		draw_rect(sample, Color(0.1, 0.2, 0.2), true)
		draw_rect(Rect2(sample.position + Vector2(3.0, 7.0), Vector2(11.0, 14.0)), Color(0.69, 0.41, 0.22), true)
		draw_rect(sample, MUTED, false, 1.0)
		draw_line(center + Vector2(-38.0, 28.0), center + Vector2(67.0, 28.0), MUTED, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(16.0, size.y - 42.0), "MICROSCOPE  /  READER  /  SAMPLE VIAL", HORIZONTAL_ALIGNMENT_CENTER, size.x - 32.0, 8, PALE)
		draw_string(ThemeDB.fallback_font, Vector2(center.x - 58.0, center.y + 51.0), "FOCUS  %.2f" % focus_position, HORIZONTAL_ALIGNMENT_CENTER, 116.0, 8, GREEN if status_text.contains("ZEROED") else MUTED)
		draw_string(ThemeDB.fallback_font, Vector2(center.x - 40.0, center.y + 65.0), "OBJ  %d×" % objective_magnification, HORIZONTAL_ALIGNMENT_CENTER, 80.0, 8, CYAN)

	func _draw_archive() -> void:
		var row_count := 4
		var row_height := 19.0
		var top := 48.0
		for index in range(row_count):
			var row := Rect2(17.0, top + float(index) * (row_height + 5.0), size.x - 34.0, row_height)
			draw_rect(row, Color(0.035, 0.075, 0.088) if index % 2 == 0 else Color(0.025, 0.057, 0.07), true)
			var is_match := index == (1 if task_id == &"lab_archive_01" else 2 if task_id == &"lab_archive_02" else 3)
			if is_match:
				draw_rect(row, Color(0.36, 0.9, 1.0, 0.14), true)
			draw_circle(Vector2(row.position.x + 9.0, row.get_center().y), 3.0, GREEN if is_match else CYAN.darkened(0.35))
			var text := _archive_row_text(index)
			draw_string(ThemeDB.fallback_font, Vector2(row.position.x + 19.0, row.position.y + 13.0), text, HORIZONTAL_ALIGNMENT_LEFT, row.size.x - 24.0, 8, PALE if is_match else MUTED)
		draw_string(ThemeDB.fallback_font, Vector2(18.0, size.y - 28.0), "INDEX HEALTH  96%     ENCRYPTION  ACTIVE", HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, 8, GREEN)

	func _archive_row_text(index: int) -> String:
		match task_id:
			&"lab_archive_01":
				return ["SHIFT HANDOVER  /  DAY 183", "ANALYZER CALIBRATION  /  FLAGGED", "CREW LOG  /  OKOYE", "MAINTENANCE  /  CLOSED"][index]
			&"lab_archive_02":
				return ["EREBOS-06  /  BASELINE", "EREBOS-07  /  SIGNAL INDEX", "EREBOS-08  /  PAIRED SAMPLE", "MINERAL INDEX  /  UPDATED"][index]
		return ["CHAMBER PRESSURE  /  1.0 ATM", "SEAL CYCLE  /  02:14", "CONTAINMENT LOG  /  LATEST", "RESEARCH NOTES  /  UNVERIFIED"][index]

	func _draw_robot_arm() -> void:
		var base := Vector2(size.x * 0.32, size.y * 0.75)
		var upper_length := size.y * 0.25
		var lower_length := size.y * 0.21
		var elbow := base + Vector2(cos(deg_to_rad(joint_angles.x)), -sin(deg_to_rad(joint_angles.x))) * upper_length
		var wrist := elbow + Vector2(cos(deg_to_rad(joint_angles.y)), -sin(deg_to_rad(joint_angles.y))) * lower_length
		var tip := wrist + Vector2(cos(deg_to_rad(joint_angles.z)), -sin(deg_to_rad(joint_angles.z))) * size.y * 0.14
		draw_rect(Rect2(size.x * 0.17, base.y, size.x * 0.68, 15.0), Color(0.07, 0.13, 0.15), true)
		draw_line(base, elbow, Color(0.2, 0.36, 0.38), 13.0, true)
		draw_line(elbow, wrist, Color(0.2, 0.36, 0.38), 11.0, true)
		draw_line(wrist, tip, Color(0.2, 0.36, 0.38), 7.0, true)
		draw_line(base, elbow, CYAN, 2.0, true)
		draw_line(elbow, wrist, CYAN, 2.0, true)
		draw_line(wrist, tip, GOLD, 2.0, true)
		for joint in [base, elbow, wrist]:
			draw_circle(joint, 8.0, Color(0.1, 0.21, 0.22))
			draw_circle(joint, 4.0, CYAN)
		draw_line(tip, tip + Vector2(-10.0, -8.0 if not clamp_closed else -3.0), ORANGE if not clamp_closed else GREEN, 2.0, true)
		draw_line(tip, tip + Vector2(9.0, -9.0 if not clamp_closed else -3.0), ORANGE if not clamp_closed else GREEN, 2.0, true)
		draw_circle(Vector2(size.x * 0.82, size.y * 0.75), 16.0, Color(0.08, 0.16, 0.17))
		draw_arc(Vector2(size.x * 0.82, size.y * 0.75), 11.0, -PI, PI, 32, GREEN if clamp_closed else GOLD, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(18.0, size.y - 30.0), "A1 %03d°   A2 %03d°   A3 %03d°" % [roundi(joint_angles.x), roundi(joint_angles.y), roundi(joint_angles.z)], HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, 8, MUTED)

	func _draw_generic_readout() -> void:
		_draw_chart_grid(Rect2(18.0, 48.0, size.x - 36.0, size.y - 91.0))

	func _draw_chart_grid(chart: Rect2) -> void:
		draw_rect(chart, Color(0.012, 0.03, 0.04), true)
		for index in range(1, 5):
			var x := chart.position.x + chart.size.x * float(index) / 5.0
			draw_line(Vector2(x, chart.position.y), Vector2(x, chart.end.y), Color(0.12, 0.25, 0.27), 1.0)
		var row_count := 4
		for index in range(1, row_count):
			var y := chart.position.y + chart.size.y * float(index) / float(row_count)
			draw_line(Vector2(chart.position.x, y), Vector2(chart.end.x, y), Color(0.12, 0.25, 0.27), 1.0)
		draw_rect(chart, Color(0.25, 0.41, 0.44), false, 1.0)


var _task_id: StringName = &""
var _completed_count := 0
var _task_total := 3
var _task_complete := false
var _is_closing := false

var _root: Control
var _status_label: Label
var _status_light: ColorRect
var _title_label: Label
var _instruction_label: Label
var _progress_bar: ProgressBar
var _progress_label: Label
var _content_stack: VBoxContainer
var _success_banner: Label
var _close_button: Button
var _return_button: Button

var _power_diagram: PowerDiagram
var _power_sliders: Array[HSlider] = []
var _power_value_labels: Array[Label] = []
var _power_status: Label
var _power_sync_button: Button

var _filter_diagram: FilterDiagram
var _filter_instruction: Label
var _filter_stage_label: Label
var _filter_action_box: VBoxContainer
var _filter_stage_controls: VBoxContainer
var _filter_status_label: Label
var _filter_release_button: Button
var _filter_step_labels: Array[Label] = []
var _filter_pressure_slider: HSlider
var _filter_pressure_label: Label
var _filter_pressure_button: Button
var _filter_stage := 0
var _filter_rotation := 0
var _filter_airflow := 18.0
var _resume_progress := {}

var _nutrient_diagram: NutrientDiagram
var _nutrient_rotations: Array[int] = []
var _nutrient_targets: Array[int] = []
var _nutrient_rotation_labels: Array[Label] = []
var _nutrient_rotate_buttons: Array[Button] = []
var _nutrient_status: Label
var _nutrient_restore_button: Button
var _nutrient_step_labels: Array[Label] = []

var _lab_station_display: LabStationDisplay
var _lab_device_status: Label
var _lab_primary_control: Control
var _lab_gain_label: Label
var _lab_focus_label: Label
var _lab_pressure_label: Label
var _lab_baseline_checkbox: CheckBox
var _lab_clamp_button: Button
var _lab_selected_vial := "ERE-07"
var _lab_scan_mode: OptionButton
var _lab_sample_slot: OptionButton
var _lab_scan_gain: HSlider
var _lab_archive_search: LineEdit
var _lab_archive_records: ItemList
var _lab_archive_detail: Label
var _lab_open_record_button: Button
var _lab_archive_data: Array[Dictionary] = []
var _lab_axis_sliders: Array[HSlider] = []
var _lab_axis_names: Array[String] = []
var _lab_axis_value_labels: Array[Label] = []
var _lab_lock_buttons: Array[Button] = []


func setup(task_id: StringName, completed_count: int, task_total: int) -> void:
	_task_id = task_id
	_completed_count = completed_count
	_task_total = maxi(task_total, 1)


func _ready() -> void:
	layer = 20
	_build_ui()
	_restore_service_progress()
	_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(_root, "modulate", Color.WHITE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _task_id == &"auxiliary_power" and not _power_sliders.is_empty():
		_power_sliders[0].grab_focus()
	elif _task_id == &"air_filter" and is_instance_valid(_filter_release_button):
		_filter_release_button.grab_focus()
	elif _task_id == &"nutrient_flow" and not _nutrient_rotate_buttons.is_empty():
		_nutrient_rotate_buttons[0].grab_focus()
	elif _is_labroom_task() and is_instance_valid(_lab_primary_control):
		_lab_primary_control.grab_focus()


func _build_ui() -> void:
	_root = Control.new()
	SKIN.apply(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.008, 0.018, 0.032, 0.82)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(1232.0, 672.0)
	var frame_style := _panel_style(Color(0.031, 0.067, 0.086, 0.99), Color(1.0, 0.78, 0.38, 0.94), 16.0)
	frame.add_theme_stylebox_override("panel", frame_style)
	center.add_child(frame)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	frame.add_child(layout)
	layout.add_child(_build_header())
	var divider := HSeparator.new()
	divider.add_theme_color_override("separator_color", Color(1.0, 0.78, 0.38, 0.52))
	layout.add_child(divider)
	layout.add_child(_build_body())
	layout.add_child(_build_footer())


func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 48.0
	row.add_theme_constant_override("separation", 14)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(48.0, 48.0)
	badge.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.16, 0.17), GOLD, 4.0))
	var badge_label := _label("SYS", 14, GOLD)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(badge_label)
	row.add_child(badge)

	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 1)
	heading.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(_label("ASTERIA-1  /  SCIENCE LAB" if _is_labroom_task() else "ASTERIA-1 // ENGINEERING TELEMETRY", 10, GOLD))
	var header_title := _label(_lab_device_name() if _is_labroom_task() else "SHIP MAINTENANCE TERMINAL", 20, PALE)
	heading.add_child(header_title)
	row.add_child(heading)
	row.add_spacer(false)

	var status_group := HBoxContainer.new()
	status_group.add_theme_constant_override("separation", 8)
	status_group.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_status_light = ColorRect.new()
	_status_light.color = GREEN
	_status_light.custom_minimum_size = Vector2(8.0, 8.0)
	status_group.add_child(_centered(_status_light))
	_status_label = _label("DEVICE ONLINE" if _is_labroom_task() else "TERMINAL LINK SECURE", 10, GREEN)
	status_group.add_child(_centered(_status_label))
	row.add_child(status_group)

	_close_button = Button.new()
	SKIN.close_button(_close_button)
	_close_button.pressed.connect(_close_console)
	row.add_child(_close_button)
	return row


func _build_body() -> Control:
	if _is_labroom_task():
		return _build_lab_device_ui()
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	body.add_child(_build_sidebar())
	body.add_child(_build_game_panel())
	return body


func _build_sidebar() -> Control:
	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size.x = 264.0
	sidebar.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.055, 0.074, 0.98), Color(0.34, 0.51, 0.55), 14.0))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	sidebar.add_child(stack)
	stack.add_child(_label("CREW WORK ORDERS", 11, GOLD))
	stack.add_child(_label("Restore ship\nservice systems", 17, PALE))

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = _task_total
	_progress_bar.value = _completed_count
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size.y = 8.0
	_progress_bar.add_theme_stylebox_override("background", _panel_style(Color(0.02, 0.05, 0.07), Color(0.12, 0.22, 0.25), 0.0))
	_progress_bar.add_theme_stylebox_override("fill", _panel_style(GREEN, GREEN, 0.0))
	stack.add_child(_progress_bar)
	_progress_label = _label("%02d / %02d TASKS COMPLETED" % [_completed_count, _task_total], 10, MUTED)
	stack.add_child(_progress_label)

	var section_line := HSeparator.new()
	section_line.add_theme_color_override("separator_color", Color(0.34, 0.51, 0.55))
	stack.add_child(section_line)
	stack.add_child(_label("SERVICE QUEUE", 10, MUTED))
	stack.add_child(_task_card("01", "[AUX POWER]", "Reconnect the cell", _task_id == &"auxiliary_power"))
	stack.add_child(_task_card("02", "[LIFE SUPPORT]", "Replace the filter", _task_id == &"air_filter"))
	stack.add_child(_task_card("03", "[HYDROPONICS]", "Route nutrient flow", _task_id == &"nutrient_flow"))
	stack.add_spacer(false)
	var note := _label("WORK ORDER PROTOCOL\nComplete the console sequence to restore the selected ship subsystem.", 10, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(note)
	return sidebar


func _task_card(number: String, title: String, detail: String, active: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size.y = 72.0
	var color := GOLD if active else Color(0.22, 0.35, 0.4)
	card.add_theme_stylebox_override("panel", SKIN.panel(9.0, true, active))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	card.add_child(row)
	var number_label := _label(number, 12, color)
	number_label.custom_minimum_size.x = 22.0
	row.add_child(number_label)
	var labels := VBoxContainer.new()
	labels.add_theme_constant_override("separation", 3)
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.add_child(_label(title, 10, PALE))
	var detail_label := _label("● IN PROGRESS" if active else detail.to_upper(), 9, color if active else MUTED)
	labels.add_child(detail_label)
	row.add_child(labels)
	return card


func _build_game_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.068, 0.087, 0.99), Color(0.34, 0.51, 0.55), 12.0))
	_content_stack = VBoxContainer.new()
	_content_stack.add_theme_constant_override("separation", 8)
	panel.add_child(_content_stack)

	var game_heading := HBoxContainer.new()
	game_heading.add_theme_constant_override("separation", 10)
	var number := "01"
	var category := "ELECTRICAL // POWER BUS"
	var title := "Calibrate Capacitor Banks"
	var instruction := "Tune each capacitor bank into its target frequency window, then synchronize the power bus."
	if _task_id == &"air_filter":
		number = "02"
		category = "LIFE SUPPORT // O2 FILTRATION DUCT"
		title = "Replace O2 Filter Canister"
		instruction = "Release housing latch, rotate keyway 180°, seat replacement canister, and regulate airflow velocity to 62–72%."
	elif _task_id == &"nutrient_flow":
		number = "03"
		category = "HYDROPONICS // IRRIGATION MANIFOLD"
		title = "Divert Nutrient Manifold"
		instruction = "Rotate each manifold valve to clear conduit flow paths, then engage automated irrigation."
	_title_label = _label(title, 22, PALE)
	var heading_stack := VBoxContainer.new()
	heading_stack.add_theme_constant_override("separation", 3)
	heading_stack.add_child(_label("WORK ORDER %s  /  %s" % [number, category], 10, GOLD))
	heading_stack.add_child(_title_label)
	game_heading.add_child(heading_stack)
	game_heading.add_spacer(false)
	_instruction_label = _label(instruction, 11, MUTED)
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_instruction_label.custom_minimum_size.x = 260.0
	game_heading.add_child(_instruction_label)
	_content_stack.add_child(game_heading)
	var separator := HSeparator.new()
	separator.add_theme_color_override("separator_color", Color(0.34, 0.51, 0.55))
	_content_stack.add_child(separator)

	if _task_id == &"auxiliary_power":
		_build_power_game()
	elif _task_id == &"air_filter":
		_build_filter_game()
	else:
		_build_hydroponics_game()

	_success_banner = _label("", 11, GREEN)
	_success_banner.custom_minimum_size.y = 30.0
	_success_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_stack.add_child(_success_banner)
	_return_button = _button("[ RETURN TO SHIP ]", Vector2(190.0, 42.0), GOLD)
	_return_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_return_button.visible = false
	_return_button.pressed.connect(_close_console)
	return panel


func _is_labroom_task() -> bool:
	return str(_task_id).begins_with("lab_")


func _lab_device_name() -> String:
	match _task_id:
		&"lab_specimen": return "SPECIMEN ANALYSIS TABLE"
		&"lab_earth_comms": return "RESEARCH CONSOLE"
		&"lab_containment": return "SAMPLE CONTAINMENT"
		&"lab_trolley": return "INSTRUMENT TROLLEY"
		&"lab_archive_01": return "DATA ARCHIVE  /  PERSONNEL"
		&"lab_archive_02": return "DATA ARCHIVE  /  SPECIMENS"
		&"lab_archive_03": return "DATA ARCHIVE  /  CONTAINMENT"
		&"lab_robot_arm": return "SAMPLE MANIPULATOR"
	return "LAB DEVICE"


func _build_lab_device_ui() -> Control:
	var workspace := VBoxContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 10)
	var device_heading := HBoxContainer.new()
	device_heading.add_child(_label("LOCAL EQUIPMENT PANEL", 10, GOLD))
	device_heading.add_spacer(false)
	_lab_device_status = _label("LOCKS ENGAGED  /  READY" if _task_id == &"lab_containment" else "IDLE  /  READY", 10, GREEN)
	_lab_device_status.clip_text = true
	_lab_device_status.custom_minimum_size.x = 200.0
	_lab_device_status.size_flags_horizontal = Control.SIZE_SHRINK_END
	_lab_device_status.tooltip_text = "Device status and the result of your last action."
	device_heading.add_child(_lab_device_status)
	workspace.add_child(device_heading)

	var device_body := HBoxContainer.new()
	device_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	device_body.add_theme_constant_override("separation", 12)
	var display_panel := PanelContainer.new()
	display_panel.custom_minimum_size.x = 365.0
	display_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	display_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	display_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.042, 0.055), Color(0.29, 0.47, 0.52), 8.0))
	_lab_station_display = LabStationDisplay.new()
	_lab_station_display.task_id = _task_id
	if _task_id == &"lab_containment":
		_lab_station_display.status_text = "LOCKS ENGAGED  /  READY"
	_lab_station_display.custom_minimum_size = Vector2(350.0, 300.0)
	_lab_station_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lab_station_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	display_panel.add_child(_lab_station_display)
	device_body.add_child(display_panel)

	var controls_panel := PanelContainer.new()
	controls_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.068, 0.087, 0.99), Color(0.34, 0.51, 0.55), 16.0))
	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	controls_panel.add_child(controls)
	match _task_id:
		&"lab_specimen": _build_spectrometer_controls(controls)
		&"lab_earth_comms": _build_research_console_controls(controls)
		&"lab_containment": _build_containment_controls(controls)
		&"lab_trolley": _build_trolley_controls(controls)
		&"lab_archive_01", &"lab_archive_02", &"lab_archive_03": _build_archive_controls(controls)
		&"lab_robot_arm": _build_manipulator_controls(controls)
	device_body.add_child(controls_panel)
	workspace.add_child(device_body)
	return workspace


func _build_spectrometer_controls(parent: VBoxContainer) -> void:
	parent.add_child(_label("SPECTROMETER SETUP", 11, GOLD))
	parent.add_child(_label("1. Choose a sample   →   2. Set scan   →   3. Acquire", 10, MUTED))
	parent.add_child(_label("SAMPLE", 9, CYAN))
	_lab_sample_slot = OptionButton.new()
	_lab_sample_slot.add_item("Paired tray  /  ERE-07 + ERE-08")
	_lab_sample_slot.add_item("Sample vial  /  ERE-07")
	_lab_sample_slot.add_item("Sample vial  /  ERE-08")
	parent.add_child(_lab_sample_slot)
	parent.add_child(_label("SCAN TYPE", 9, CYAN))
	_lab_scan_mode = OptionButton.new()
	_lab_scan_mode.add_item("X-ray fluorescence")
	_lab_scan_mode.add_item("Reflectance spectrum")
	_lab_scan_mode.add_item("Electromagnetic survey")
	parent.add_child(_lab_scan_mode)
	_lab_gain_label = _label("SENSOR SENSITIVITY  /  64%", 9, CYAN)
	parent.add_child(_lab_gain_label)
	_lab_scan_gain = HSlider.new()
	_lab_scan_gain.min_value = 0.0
	_lab_scan_gain.max_value = 100.0
	_lab_scan_gain.value = 64.0
	_lab_scan_gain.step = 1.0
	_lab_scan_gain.custom_minimum_size.y = 30.0
	_lab_scan_gain.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_task_slider(_lab_scan_gain, CYAN)
	_lab_scan_gain.value_changed.connect(_on_spectrometer_gain_changed)
	parent.add_child(_lab_scan_gain)
	_lab_scan_gain.tooltip_text = "Increase sensitivity to reveal weaker readings."
	_lab_baseline_checkbox = CheckBox.new()
	_lab_baseline_checkbox.text = "Correct background noise"
	_lab_baseline_checkbox.button_pressed = true
	_lab_baseline_checkbox.tooltip_text = "Recommended: remove the detector's normal background signal."
	parent.add_child(_lab_baseline_checkbox)
	parent.add_spacer(false)
	var run_button := _button("ACQUIRE SPECTRUM", Vector2(0.0, 46.0), CYAN)
	run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_button.pressed.connect(_on_spectrometer_scan)
	_lab_primary_control = run_button
	parent.add_child(run_button)


func _on_spectrometer_gain_changed(value: float) -> void:
	_lab_gain_label.text = "SENSOR SENSITIVITY  /  %02d%%" % roundi(value)


func _on_spectrometer_scan() -> void:
	_lab_station_display.scan_complete = true
	_lab_station_display.single_sample_index = _lab_sample_slot.selected - 1
	var mode := _lab_scan_mode.get_item_text(_lab_scan_mode.selected)
	var sample := _lab_sample_slot.get_item_text(_lab_sample_slot.selected)
	var baseline_note := "  /  BASELINE CORRECTED" if _lab_baseline_checkbox.button_pressed else ""
	_lab_station_display.status_text = "ACQUISITION COMPLETE"
	_lab_station_display.queue_redraw()
	_set_lab_device_status("SPECTRUM ACQUIRED  /  %s  /  %s%s" % [sample, mode, baseline_note], GREEN)


func _build_research_console_controls(parent: VBoxContainer) -> void:
	parent.add_child(_label("RESEARCH DATA TERMINAL", 11, GOLD))
	parent.add_child(_label("Search, select a record, then open it to read the full entry.", 10, MUTED))
	_lab_archive_search = LineEdit.new()
	_lab_archive_search.placeholder_text = "Search reference catalog…"
	_lab_archive_search.clear_button_enabled = true
	_lab_archive_search.text_changed.connect(_on_research_search_changed)
	parent.add_child(_lab_archive_search)
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 8)
	_lab_archive_records = ItemList.new()
	_lab_archive_records.custom_minimum_size.x = 220.0
	_lab_archive_records.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lab_archive_records.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lab_archive_records.item_selected.connect(_on_research_record_selected)
	split.add_child(_lab_archive_records)
	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.042, 0.055), Color(0.21, 0.36, 0.4), 10.0))
	_lab_archive_detail = _label("Select an entry to preview its contents.", 11, PALE)
	_lab_archive_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(_lab_archive_detail)
	split.add_child(detail_panel)
	parent.add_child(split)
	_lab_archive_data = [
		{"title": "Instrument reference", "detail": "Spectrometer operating ranges, detector response, and routine calibration procedure."},
		{"title": "Mineral library", "detail": "Reference reflectance and fluorescence profiles for common silicates, iron, and nickel ores."},
		{"title": "Sample catalog", "detail": "Registered sample vials, storage locations, collection notes, and chain-of-custody records."},
		{"title": "Lab handbook", "detail": "Bench procedures for microscopy, containment, and specimen handling."},
	]
	_refresh_lab_archive_list()
	_lab_open_record_button = _button("OPEN SELECTED ENTRY", Vector2(0.0, 46.0), CYAN)
	_lab_open_record_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lab_open_record_button.disabled = true
	_lab_open_record_button.pressed.connect(_on_research_record_open)
	_lab_primary_control = _lab_archive_search
	parent.add_child(_lab_open_record_button)


func _on_research_search_changed(_value: String) -> void:
	_lab_archive_detail.text = "Choose a result to preview its contents."
	_refresh_lab_archive_list()


func _on_research_record_selected(index: int) -> void:
	var record := _visible_archive_record(index)
	if not record.is_empty():
		_lab_archive_detail.text = str(record["detail"])
		_lab_open_record_button.disabled = false
		_set_lab_device_status("ENTRY SELECTED  /  READY TO OPEN", CYAN)


func _on_research_record_open() -> void:
	var selected := _lab_archive_records.get_selected_items()
	if selected.is_empty() or _visible_archive_record(selected[0]).is_empty():
		_set_lab_device_status("SELECT A CATALOG ENTRY", GOLD)
		return
	var record: Dictionary = _visible_archive_record(selected[0])
	_lab_archive_detail.text = "%s\n\n%s\n\nREVISION  3.4   /   LOCAL COPY VERIFIED" % [record["title"], record["detail"]]
	_set_lab_device_status("REFERENCE ENTRY OPEN", GREEN)


func _build_containment_controls(parent: VBoxContainer) -> void:
	parent.add_child(_label("CONTAINMENT CONTROL", 11, GOLD))
	parent.add_child(_label("Secure both locks and set pressure to 1.00 ATM, then run the test.", 10, MUTED))
	var lock_row := HBoxContainer.new()
	lock_row.add_theme_constant_override("separation", 8)
	for index in range(2):
		var lock_button := _button("NORTH LOCK  /  ENGAGED" if index == 0 else "SOUTH LOCK  /  ENGAGED", Vector2(0.0, 48.0), CYAN)
		lock_button.toggle_mode = true
		lock_button.button_pressed = true
		lock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lock_button.toggled.connect(_on_containment_lock_toggled.bind(index))
		_lab_lock_buttons.append(lock_button)
		lock_row.add_child(lock_button)
	_lab_station_display.containment_locks = [true, true]
	parent.add_child(lock_row)
	_lab_pressure_label = _label("CHAMBER PRESSURE  /  1.00 ATM", 9, CYAN)
	parent.add_child(_lab_pressure_label)
	var pressure_slider := HSlider.new()
	pressure_slider.min_value = 0.7
	pressure_slider.max_value = 1.3
	pressure_slider.step = 0.01
	pressure_slider.value = 1.0
	pressure_slider.custom_minimum_size.y = 30.0
	pressure_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_task_slider(pressure_slider, CYAN)
	pressure_slider.tooltip_text = "Target: 0.97–1.03 ATM. Use the arrow keys for fine adjustment."
	pressure_slider.value_changed.connect(_on_containment_pressure_changed)
	parent.add_child(pressure_slider)
	var test_button := _button("RUN PRESSURE-HOLD TEST", Vector2(0.0, 44.0), GOLD)
	test_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	test_button.pressed.connect(_on_containment_test)
	_lab_primary_control = test_button
	parent.add_child(test_button)
	parent.add_spacer(false)
	parent.add_child(_label("PASS CHECK: both locks engaged and pressure within 0.03 ATM of target.", 9, MUTED))


func _on_containment_lock_toggled(is_engaged: bool, index: int) -> void:
	var lock_name := "NORTH" if index == 0 else "SOUTH"
	_lab_lock_buttons[index].text = "%s LOCK  /  %s" % [lock_name, "ENGAGED" if is_engaged else "RELEASED"]
	_lab_station_display.containment_locks[index] = is_engaged
	var both_engaged := _lab_lock_buttons[0].button_pressed and _lab_lock_buttons[1].button_pressed
	_lab_station_display.status_text = "VESSEL SECURE" if both_engaged else "INTERLOCK OPEN"
	_lab_station_display.queue_redraw()
	_set_lab_device_status("BOTH INTERLOCKS ENGAGED" if both_engaged else "%s LOCK %s" % [lock_name, "ENGAGED" if is_engaged else "RELEASED"], GREEN if both_engaged else GOLD)


func _on_containment_pressure_changed(value: float) -> void:
	_lab_pressure_label.text = "CHAMBER PRESSURE  /  %.2f ATM" % value
	_lab_station_display.chamber_pressure = value
	_lab_station_display.queue_redraw()
	_set_lab_device_status("CHAMBER PRESSURE  /  %.2f ATM" % value, CYAN)


func _on_containment_test() -> void:
	var locks_engaged := _lab_lock_buttons.size() == 2 and _lab_lock_buttons[0].button_pressed and _lab_lock_buttons[1].button_pressed
	if not locks_engaged:
		_lab_station_display.status_text = "INTERLOCK OPEN"
		_lab_station_display.queue_redraw()
		_set_lab_device_status("TEST INHIBITED  /  CLOSE BOTH LOCKS", ORANGE)
		return
	if absf(_lab_station_display.chamber_pressure - 1.0) > 0.03:
		_lab_station_display.status_text = "PRESSURE OUT OF RANGE"
		_lab_station_display.queue_redraw()
		_set_lab_device_status("TEST FAILED  /  PRESSURE OUT OF RANGE", ORANGE)
		return
	_lab_station_display.status_text = "VESSEL SECURE"
	_lab_station_display.queue_redraw()
	_set_lab_device_status("PRESSURE-HOLD TEST PASSED  /  1.0 ATM", GREEN)


func _build_trolley_controls(parent: VBoxContainer) -> void:
	parent.add_child(_label("PORTABLE INSTRUMENTS", 11, GOLD))
	parent.add_child(_label("Choose magnification and focus, then zero the selected vial.", 10, MUTED))
	parent.add_child(_label("1  /  MAGNIFICATION", 9, CYAN))
	var objective := OptionButton.new()
	objective.add_item("4×  /  Locator")
	objective.add_item("10×  /  Survey")
	objective.add_item("40×  /  Detail")
	objective.item_selected.connect(_on_trolley_objective_changed)
	parent.add_child(objective)
	parent.add_child(_label("2  /  FOCUS  —  0.00 MM", 9, CYAN))
	_lab_focus_label = parent.get_child(parent.get_child_count() - 1) as Label
	var focus_slider := HSlider.new()
	focus_slider.min_value = -5.0
	focus_slider.max_value = 5.0
	focus_slider.step = 0.01
	focus_slider.value = 0.0
	focus_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_task_slider(focus_slider, CYAN)
	focus_slider.value_changed.connect(_on_trolley_focus_changed)
	parent.add_child(focus_slider)
	parent.add_child(_label("3  /  SAMPLE READER", 9, CYAN))
	var reader_row := HBoxContainer.new()
	var vial := OptionButton.new()
	vial.add_item("Vial  /  ERE-07")
	vial.add_item("Vial  /  ERE-08")
	vial.item_selected.connect(_on_trolley_vial_changed)
	reader_row.add_child(vial)
	var zero_button := _button("ZERO SELECTED VIAL", Vector2(170.0, 42.0), GOLD)
	zero_button.pressed.connect(_on_trolley_zero)
	reader_row.add_child(zero_button)
	parent.add_child(reader_row)
	parent.add_spacer(false)
	_lab_primary_control = zero_button


func _on_trolley_objective_changed(index: int) -> void:
	_lab_station_display.objective_magnification = [4, 10, 40][index]
	_lab_station_display.queue_redraw()
	_set_lab_device_status("MICROSCOPE OBJECTIVE  /  %s" % ["4× LOCATOR", "10× SURVEY", "40× DETAIL"][index], CYAN)


func _on_trolley_focus_changed(value: float) -> void:
	_lab_focus_label.text = "2  /  FOCUS  —  %.2f MM" % value
	_lab_station_display.focus_position = value
	_lab_station_display.status_text = "FOCUS %.2f MM" % value
	_lab_station_display.queue_redraw()
	_set_lab_device_status("FOCUS ADJUSTMENT  /  %.2f MM" % value, CYAN)


func _on_trolley_zero() -> void:
	_lab_station_display.status_text = "%s READER ZEROED" % _lab_selected_vial
	_lab_station_display.queue_redraw()
	_set_lab_device_status("%s SAMPLE READER ZEROED" % _lab_selected_vial, GREEN)


func _on_trolley_vial_changed(index: int) -> void:
	_lab_selected_vial = "ERE-07" if index == 0 else "ERE-08"
	_set_lab_device_status("READER SLOT  /  %s" % _lab_selected_vial, CYAN)


func _build_archive_controls(parent: VBoxContainer) -> void:
	parent.add_child(_label("ARCHIVE BROWSER", 11, GOLD))
	parent.add_child(_label("Type to filter. Select a record to preview it, then open it.", 10, MUTED))
	_lab_archive_search = LineEdit.new()
	_lab_archive_search.placeholder_text = "Filter by title or keyword…"
	_lab_archive_search.clear_button_enabled = true
	_lab_archive_search.text_changed.connect(_on_archive_search_changed)
	parent.add_child(_lab_archive_search)
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 8)
	_lab_archive_records = ItemList.new()
	_lab_archive_records.custom_minimum_size.x = 240.0
	_lab_archive_records.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lab_archive_records.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lab_archive_records.item_selected.connect(_on_archive_record_selected)
	split.add_child(_lab_archive_records)
	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.042, 0.055), Color(0.21, 0.36, 0.4), 10.0))
	_lab_archive_detail = _label("Select a record to inspect its stored fields.", 11, PALE)
	_lab_archive_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(_lab_archive_detail)
	split.add_child(detail_panel)
	parent.add_child(split)
	_lab_archive_data = _archive_records_for_device()
	_refresh_lab_archive_list()
	_lab_open_record_button = _button("OPEN SELECTED RECORD", Vector2(0.0, 46.0), CYAN)
	_lab_open_record_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lab_open_record_button.disabled = true
	_lab_open_record_button.pressed.connect(_on_archive_record_open)
	_lab_primary_control = _lab_archive_search
	parent.add_child(_lab_open_record_button)


func _archive_records_for_device() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	match _task_id:
		&"lab_archive_01":
			records.append({"title": "Shift handover  /  Day 183", "detail": "Operator: M. Ilyanov\nBench: north analysis station\nNote: detector baseline drift recorded during routine calibration."})
			records.append({"title": "Personnel roster  /  Science", "detail": "Research crew assignments, certifications, and current station access permissions."})
			records.append({"title": "Maintenance entry  /  Microscope", "detail": "Objective turret inspected. Focus rail cleaned and lubricated; no damage recorded."})
		&"lab_archive_02":
			records.append({"title": "Specimen ERE-07", "detail": "Dark metallic fragment\nMass: 18.42 g\nStorage: sealed vial, rack B2."})
			records.append({"title": "Specimen ERE-08", "detail": "Layered silicate fragment\nMass: 12.07 g\nStorage: sealed vial, rack B3."})
			records.append({"title": "Scan index  /  Mineral library", "detail": "Cross-reference table for fluorescence, reflectance, and elemental readings from registered samples."})
		&"lab_archive_03":
			records.append({"title": "Chamber 04  /  Pressure log", "detail": "Nominal pressure: 1.00 atm\nLast hold test: 02:14:08\nPressure loss: below instrument tolerance."})
			records.append({"title": "Seal inspection  /  Batch 6", "detail": "Elastomer seals inspected under magnification. No cracks, swelling, or surface contamination found."})
			records.append({"title": "Sample storage protocol", "detail": "Keep specimens double-contained. Record chamber pressure before and after each transfer."})
	return records

func _on_archive_search_changed(_value: String) -> void:
	_refresh_lab_archive_list()


func _refresh_lab_archive_list() -> void:
	if not is_instance_valid(_lab_archive_records):
		return
	if is_instance_valid(_lab_open_record_button):
		_lab_open_record_button.disabled = true
	_lab_archive_records.clear()
	if is_instance_valid(_lab_archive_detail):
		_lab_archive_detail.text = "Choose a record to preview its contents."
	var query := _lab_archive_search.text.strip_edges().to_lower() if is_instance_valid(_lab_archive_search) else ""
	for record in _lab_archive_data:
		var searchable := (str(record["title"]) + " " + str(record["detail"])).to_lower()
		if query.is_empty() or searchable.contains(query):
			_lab_archive_records.add_item(str(record["title"]))
	if _lab_archive_records.item_count == 0 and is_instance_valid(_lab_archive_detail):
		_lab_archive_detail.text = "No matching records. Try another search."


func _on_archive_record_selected(index: int) -> void:
	var record := _visible_archive_record(index)
	if not record.is_empty():
		_lab_archive_detail.text = str(record["detail"])
		_lab_open_record_button.disabled = false
		_set_lab_device_status("RECORD SELECTED  /  LOCAL COPY", CYAN)


func _on_archive_record_open() -> void:
	var selected := _lab_archive_records.get_selected_items()
	if selected.is_empty() or _visible_archive_record(selected[0]).is_empty():
		_set_lab_device_status("SELECT A RECORD TO OPEN", GOLD)
		return
	var record := _visible_archive_record(selected[0])
	_lab_archive_detail.text = "%s\n\n%s\n\nRECORD STATUS  /  VERIFIED LOCAL COPY" % [record["title"], record["detail"]]
	_set_lab_device_status("RECORD OPEN  /  READ ONLY", GREEN)


func _visible_archive_record(visible_index: int) -> Dictionary:
	var query := _lab_archive_search.text.strip_edges().to_lower()
	var visible_records: Array[Dictionary] = []
	for record in _lab_archive_data:
		if query.is_empty() or (str(record["title"]) + " " + str(record["detail"])).to_lower().contains(query):
			visible_records.append(record)
	return visible_records[visible_index] if visible_index >= 0 and visible_index < visible_records.size() else {}


func _build_manipulator_controls(parent: VBoxContainer) -> void:
	parent.add_child(_label("ARM POSITION CONTROL", 11, GOLD))
	parent.add_child(_label("Move a joint with its slider. HOME ARM restores the safe pose.", 10, MUTED))
	var axis_names := ["BASE ROTATION", "ELBOW PITCH", "WRIST PITCH"]
	var defaults := [0.0, 55.0, -35.0]
	for index in range(axis_names.size()):
		var value_label := _label("%s  /  %d°" % [axis_names[index], roundi(defaults[index])], 9, CYAN)
		parent.add_child(value_label)
		_lab_axis_names.append(axis_names[index])
		_lab_axis_value_labels.append(value_label)
		var axis := HSlider.new()
		axis.min_value = -90.0
		axis.max_value = 90.0
		axis.step = 1.0
		axis.value = defaults[index]
		axis.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_task_slider(axis, CYAN)
		axis.tooltip_text = "Range: −90° to +90°. Use arrow keys for precise movement."
		axis.value_changed.connect(_on_manipulator_axis_changed.bind(index))
		_lab_axis_sliders.append(axis)
		parent.add_child(axis)
	_lab_station_display.joint_angles = Vector3(defaults[0], defaults[1], defaults[2])
	var action_row := HBoxContainer.new()
	var home_button := _button("HOME ARM", Vector2(0.0, 42.0), GOLD)
	home_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_button.pressed.connect(_on_manipulator_home)
	_lab_primary_control = home_button
	action_row.add_child(home_button)
	_lab_clamp_button = _button("CLOSE GRIP", Vector2(0.0, 42.0), CYAN)
	_lab_clamp_button.toggle_mode = true
	_lab_clamp_button.toggled.connect(_on_manipulator_grip_toggled)
	_lab_clamp_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(_lab_clamp_button)
	parent.add_child(action_row)
	parent.add_spacer(false)
	parent.add_child(_label("GRIP LOAD  /  NO SAMPLE DETECTED", 9, MUTED))


func _on_manipulator_axis_changed(value: float, index: int) -> void:
	_lab_station_display.joint_angles[index] = value
	_lab_axis_value_labels[index].text = "%s  /  %d°" % [_lab_axis_names[index], roundi(value)]
	_lab_station_display.status_text = "JOINT POSITION UPDATED"
	_lab_station_display.queue_redraw()
	_set_lab_device_status("JOINT %d  /  %03d°" % [index + 1, roundi(value)], CYAN)


func _on_manipulator_home() -> void:
	var defaults := [0.0, 55.0, -35.0]
	for index in range(_lab_axis_sliders.size()):
		_lab_axis_sliders[index].value = defaults[index]
	_lab_station_display.joint_angles = Vector3(defaults[0], defaults[1], defaults[2])
	_lab_station_display.queue_redraw()
	_set_lab_device_status("ARM AT HOME POSITION", GREEN)


func _on_manipulator_grip_toggled(is_closed: bool) -> void:
	_lab_clamp_button.text = "OPEN GRIP" if is_closed else "CLOSE GRIP"
	_lab_station_display.clamp_closed = is_closed
	_lab_station_display.queue_redraw()
	_set_lab_device_status("GRIP CLOSED" if is_closed else "GRIP OPEN", GREEN if is_closed else CYAN)


func _set_lab_device_status(text: String, color: Color) -> void:
	if is_instance_valid(_lab_device_status):
		_lab_device_status.text = text
		_lab_device_status.tooltip_text = text
		_lab_device_status.add_theme_color_override("font_color", color)
	if is_instance_valid(_lab_station_display):
		_lab_station_display.status_text = text
		_lab_station_display.queue_redraw()


func _build_power_game() -> void:
	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 10)
	summary.add_child(_label("CAPACITOR CALIBRATION", 9, MUTED))
	summary.add_spacer(false)
	_power_status = _label("0 / 3 CELLS IN RANGE", 10, GOLD)
	summary.add_child(_power_status)
	_content_stack.add_child(summary)

	var workspace := HBoxContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 12)
	_power_diagram = PowerDiagram.new()
	_power_diagram.custom_minimum_size = Vector2(350.0, 300.0)
	_power_diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_power_diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for index in range(3):
		var cell_name: String = str(POWER_CELL_NAMES[index])
		var start_value: float = float(POWER_START_VALUES[index])
		var target_low: float = float(POWER_TARGET_LOW[index])
		var target_high: float = float(POWER_TARGET_HIGH[index])
		var cell_color: Color = POWER_CELL_COLORS[index]
		_power_diagram.channel_names.append(cell_name)
		_power_diagram.charge_values.append(start_value)
		_power_diagram.target_lows.append(target_low)
		_power_diagram.target_highs.append(target_high)
		_power_diagram.channel_colors.append(cell_color)
	workspace.add_child(_power_diagram)

	var control_panel := PanelContainer.new()
	control_panel.custom_minimum_size.x = 390.0
	control_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.084, 0.103), Color(0.24, 0.39, 0.43), 14.0))
	var control_stack := VBoxContainer.new()
	control_stack.add_theme_constant_override("separation", 6)
	control_panel.add_child(control_stack)
	control_stack.add_child(_label("ENERGY RESERVOIRS", 10, GOLD))
	for index in range(3):
		var cell_panel := PanelContainer.new()
		cell_panel.custom_minimum_size.y = 67.0
		cell_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.08, 0.096), Color(0.24, 0.39, 0.43), 9.0))
		var cell_stack := VBoxContainer.new()
		cell_stack.add_theme_constant_override("separation", 2)
		cell_panel.add_child(cell_stack)
		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 8)
		var cell_name: String = str(POWER_CELL_NAMES[index])
		var cell_color: Color = POWER_CELL_COLORS[index]
		header.add_child(_label("%02d  /  %s" % [index + 1, cell_name], 10, cell_color))
		header.add_spacer(false)
		var start_value: float = float(POWER_START_VALUES[index])
		var target_low: float = float(POWER_TARGET_LOW[index])
		var target_high: float = float(POWER_TARGET_HIGH[index])
		var value_label := _label("%02d%%" % roundi(start_value), 11, PALE)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_power_value_labels.append(value_label)
		header.add_child(value_label)
		cell_stack.add_child(header)
		cell_stack.add_child(_label("TARGET  %02d–%02d%%" % [roundi(target_low), roundi(target_high)], 9, MUTED))
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 100.0
		slider.step = 1.0
		slider.value = start_value
		slider.custom_minimum_size.y = 24.0
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_task_slider(slider, cell_color)
		slider.value_changed.connect(_on_power_value_changed.bind(index))
		_power_sliders.append(slider)
		cell_stack.add_child(slider)
		control_stack.add_child(cell_panel)
	workspace.add_child(control_panel)
	_content_stack.add_child(workspace)

	_power_sync_button = _button("[ ✔ SYNCHRONIZE POWER BUS ]", Vector2(0.0, 46.0), GOLD)
	_power_sync_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_power_sync_button.disabled = true
	_power_sync_button.pressed.connect(_on_power_sync_pressed)
	control_stack.add_child(_power_sync_button)
	_update_power_readouts()


func _on_power_value_changed(value: float, index: int) -> void:
	_power_diagram.charge_values[index] = value
	_power_diagram.queue_redraw()
	_power_value_labels[index].text = "%02d%%" % roundi(value)
	_update_power_readouts()


func _update_power_readouts() -> void:
	var cells_in_range := 0
	for index in range(_power_sliders.size()):
		var value: float = _power_sliders[index].value
		var target_low: float = float(POWER_TARGET_LOW[index])
		var target_high: float = float(POWER_TARGET_HIGH[index])
		var in_range := value >= target_low and value <= target_high
		if in_range:
			cells_in_range += 1
		_power_value_labels[index].add_theme_color_override("font_color", GREEN if in_range else PALE)
	_power_status.text = "%d / 3 CELLS IN RANGE" % cells_in_range
	_power_status.add_theme_color_override("font_color", GREEN if cells_in_range == 3 else GOLD)
	_power_sync_button.disabled = cells_in_range != 3


func _on_power_sync_pressed() -> void:
	if _task_complete or _power_sync_button.disabled:
		return
	_complete_task("AUXILIARY POWER RESTORED  /  CAPACITOR BANKS SYNCHRONIZED")


func _build_hydroponics_game() -> void:
	_nutrient_rotations.clear()
	_nutrient_targets.clear()
	for rotation in [0, 2, 3]:
		_nutrient_rotations.append(int(rotation))
	for target in [1, 3, 2]:
		_nutrient_targets.append(int(target))

	var workspace := HBoxContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 12)
	_nutrient_diagram = NutrientDiagram.new()
	_nutrient_diagram.custom_minimum_size = Vector2(350.0, 310.0)
	_nutrient_diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nutrient_diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_nutrient_diagram.rotations = _nutrient_rotations
	_nutrient_diagram.targets = _nutrient_targets
	workspace.add_child(_nutrient_diagram)

	var controls := PanelContainer.new()
	controls.custom_minimum_size.x = 450.0
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.084, 0.103), Color(0.24, 0.39, 0.43), 13.0))
	var control_stack := VBoxContainer.new()
	control_stack.add_theme_constant_override("separation", 7)
	controls.add_child(control_stack)
	control_stack.add_child(_label("MANIFOLD VALVE ALIGNMENT", 10, GOLD))
	var help := _label("Match each handle to its amber guide.", 10, MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control_stack.add_child(help)
	for index in range(3):
		var row_panel := PanelContainer.new()
		row_panel.custom_minimum_size.y = 57.0
		row_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.08, 0.096), Color(0.24, 0.39, 0.43), 7.0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		row_panel.add_child(row)
		var labels := VBoxContainer.new()
		labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		labels.add_theme_constant_override("separation", 3)
		labels.add_child(_label("VALVE  %02d" % (index + 1), 10, CYAN))
		var target_degrees := _nutrient_targets[index] * 90
		labels.add_child(_label("TARGET  /  %d°" % target_degrees, 9, MUTED))
		row.add_child(labels)
		var value_label := _label("CURRENT  /  %d°" % (_nutrient_rotations[index] * 90), 8, PALE)
		value_label.custom_minimum_size.x = 92.0
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_nutrient_rotation_labels.append(value_label)
		row.add_child(value_label)
		var rotate_button := _button("TURN 90°", Vector2(102.0, 39.0), CYAN)
		rotate_button.pressed.connect(_on_nutrient_rotate_pressed.bind(index))
		_nutrient_rotate_buttons.append(rotate_button)
		row.add_child(rotate_button)
		control_stack.add_child(row_panel)

	_nutrient_status = _label("PUMP READY  /  MANIFOLD MISALIGNED", 9, GOLD)
	control_stack.add_child(_nutrient_status)
	control_stack.add_spacer(false)
	_nutrient_restore_button = _button("[ ✔ RESTORE NUTRIENT IRRIGATION ]", Vector2(0.0, 46.0), GOLD)
	_nutrient_restore_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nutrient_restore_button.disabled = true
	_nutrient_restore_button.pressed.connect(_on_nutrient_flow_restore_pressed)
	control_stack.add_child(_nutrient_restore_button)
	workspace.add_child(controls)
	_content_stack.add_child(workspace)

	var step_footer := HBoxContainer.new()
	step_footer.add_theme_constant_override("separation", 8)
	for step_name in ["PUMP", "ALIGN MANIFOLD", "VERIFY FLOW"]:
		var step_label := _label(step_name, 9, MUTED)
		step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_nutrient_step_labels.append(step_label)
		step_footer.add_child(step_label)
	_content_stack.add_child(step_footer)
	_update_nutrient_readouts()


func _on_nutrient_rotate_pressed(index: int) -> void:
	if _task_complete or index < 0 or index >= _nutrient_rotations.size():
		return
	_nutrient_rotations[index] = (_nutrient_rotations[index] + 1) % 4
	_nutrient_diagram.rotations[index] = _nutrient_rotations[index]
	_nutrient_diagram.queue_redraw()
	_update_nutrient_readouts()


func _update_nutrient_readouts() -> void:
	var aligned_count := 0
	for index in range(_nutrient_rotations.size()):
		var is_aligned := _nutrient_rotations[index] == _nutrient_targets[index]
		if is_aligned:
			aligned_count += 1
		_nutrient_rotation_labels[index].text = "CURRENT  /  %d°" % (_nutrient_rotations[index] * 90)
		_nutrient_rotation_labels[index].add_theme_color_override("font_color", GREEN if is_aligned else PALE)
	var all_aligned := aligned_count == _nutrient_targets.size()
	_nutrient_status.text = "ALL VALVES ALIGNED  /  FLOW READY" if all_aligned else "%d / 3 VALVES ALIGNED  /  FLOW BLOCKED" % aligned_count
	_nutrient_status.add_theme_color_override("font_color", GREEN if all_aligned else GOLD)
	_nutrient_restore_button.disabled = not all_aligned
	_refresh_nutrient_step_footer()


func _on_nutrient_flow_restore_pressed() -> void:
	if _task_complete or not _nutrient_diagram.all_aligned():
		return
	_complete_task("HYDROPONICS RESTORED  /  NUTRIENT FLOW REACHING ALL GROW BEDS")


func _refresh_nutrient_step_footer() -> void:
	var all_aligned := not _nutrient_rotations.is_empty() and _nutrient_diagram.all_aligned()
	for index in range(_nutrient_step_labels.size()):
		var color := MUTED
		if _task_complete or all_aligned:
			color = GREEN
		elif index == 0:
			color = GREEN
		elif index == 1:
			color = GOLD
		_nutrient_step_labels[index].add_theme_color_override("font_color", color)


func _build_filter_game() -> void:
	var workspace := HBoxContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 14)

	_filter_diagram = FilterDiagram.new()
	_filter_diagram.custom_minimum_size = Vector2(350.0, 320.0)
	_filter_diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_child(_filter_diagram)

	var controls := PanelContainer.new()
	controls.custom_minimum_size.x = 360.0
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.084, 0.103), Color(0.24, 0.39, 0.43), 15.0))
	_filter_action_box = VBoxContainer.new()
	_filter_action_box.add_theme_constant_override("separation", 10)
	controls.add_child(_filter_action_box)
	_filter_stage_label = _label("STEP 01  /  REMOVE", 10, GOLD)
	_filter_action_box.add_child(_filter_stage_label)
	_filter_instruction = _label("The intake is clogged. Release the housing latch and remove the spent cartridge.", 14, PALE)
	_filter_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_filter_instruction.custom_minimum_size.y = 65.0
	_filter_action_box.add_child(_filter_instruction)
	_filter_action_box.add_spacer(false)
	_filter_stage_controls = VBoxContainer.new()
	_filter_action_box.add_child(_filter_stage_controls)
	_filter_release_button = _button("RELEASE PNEUMATIC LATCH  →", Vector2(0.0, 48.0), GOLD)
	_filter_release_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_release_button.pressed.connect(_on_filter_release_pressed)
	_filter_stage_controls.add_child(_filter_release_button)
	_filter_status_label = _label("LATCH SENSOR  /  LOCKED", 9, MUTED)
	_filter_action_box.add_child(_filter_status_label)
	workspace.add_child(controls)
	_content_stack.add_child(workspace)

	var step_footer := HBoxContainer.new()
	step_footer.add_theme_constant_override("separation", 8)
	for step_name in ["REMOVE", "ALIGN", "PRESSURIZE"]:
		var step_label := _label(step_name, 9, MUTED)
		step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_filter_step_labels.append(step_label)
		step_footer.add_child(step_label)
	_content_stack.add_child(step_footer)
	_refresh_filter_step_footer()


func _on_filter_release_pressed() -> void:
	if _task_complete or _filter_stage != 0:
		return
	_filter_stage = 1
	_filter_diagram.filter_removed = true
	_filter_diagram.queue_redraw()
	_filter_stage_label.text = "STEP 02  /  ALIGN"
	_filter_instruction.text = "Fit the replacement cartridge. Rotate it until the amber notch meets the upper guide."
	_refresh_filter_step_footer()
	_filter_stage_controls.queue_free()
	_filter_stage_controls = VBoxContainer.new()
	_filter_stage_controls.add_theme_constant_override("separation", 8)
	_filter_action_box.add_child(_filter_stage_controls)
	var rotate_row := HBoxContainer.new()
	rotate_row.add_theme_constant_override("separation", 8)
	var rotate_button := _button("ROTATE 90°", Vector2(0.0, 46.0), CYAN)
	rotate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rotate_button.pressed.connect(_on_filter_rotate_pressed)
	rotate_row.add_child(rotate_button)
	_filter_stage_controls.add_child(rotate_row)
	var align_button := _button("[ SEAT CANISTER ]", Vector2(0.0, 46.0), GOLD)
	align_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	align_button.disabled = true
	align_button.pressed.connect(_on_filter_seat_pressed)
	rotate_row.add_child(align_button)
	_filter_status_label.text = "NOTCH POSITION  /  0°"
	_filter_status_label.add_theme_color_override("font_color", MUTED)
	rotate_button.grab_focus()


func _on_filter_rotate_pressed() -> void:
	if _task_complete or _filter_stage != 1:
		return
	_filter_rotation = (_filter_rotation + 1) % 4
	_filter_diagram.rotation_step = _filter_rotation
	_filter_diagram.queue_redraw()
	_filter_status_label.text = "NOTCH POSITION  /  %d°" % (_filter_rotation * 90)
	var rotate_row := _filter_stage_controls.get_child(0) as HBoxContainer
	var align_button := rotate_row.get_child(1) as Button
	align_button.disabled = _filter_rotation != 2
	_filter_status_label.add_theme_color_override("font_color", GREEN if _filter_rotation == 2 else MUTED)
	_filter_instruction.text = "Notch aligned. Seat the cartridge." if _filter_rotation == 2 else "Turn the cartridge until the amber notch meets the upper guide."


func _on_filter_seat_pressed() -> void:
	if _task_complete or _filter_stage != 1 or _filter_rotation != 2:
		return
	_filter_stage = 2
	_filter_diagram.cartridge_seated = true
	_filter_diagram.queue_redraw()
	_filter_stage_label.text = "STEP 03  /  PRESSURIZE"
	_filter_instruction.text = "Prime the line. Set airflow in the green band between 62% and 72%."
	_refresh_filter_step_footer()
	_filter_status_label.text = "TARGET BAND  /  62–72%"
	_filter_status_label.add_theme_color_override("font_color", GREEN)
	_filter_stage_controls.queue_free()
	_filter_stage_controls = VBoxContainer.new()
	_filter_stage_controls.add_theme_constant_override("separation", 9)
	_filter_action_box.add_child(_filter_stage_controls)
	_filter_pressure_label = _label("AIRFLOW PRESSURE  /  18%", 11, PALE)
	_filter_stage_controls.add_child(_filter_pressure_label)
	_filter_pressure_slider = HSlider.new()
	_filter_pressure_slider.min_value = 0.0
	_filter_pressure_slider.max_value = 100.0
	_filter_pressure_slider.step = 1.0
	_filter_pressure_slider.value = _filter_airflow
	_filter_pressure_slider.custom_minimum_size.y = 34.0
	_filter_pressure_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_task_slider(_filter_pressure_slider, CYAN)
	_filter_pressure_slider.value_changed.connect(_on_filter_pressure_changed)
	_filter_stage_controls.add_child(_filter_pressure_slider)
	_filter_stage_controls.add_child(_pressure_scale())
	_filter_pressure_button = _button("[ ✔ STABILIZE AIRFLOW & SEAL DUCT ]", Vector2(0.0, 46.0), GOLD)
	_filter_pressure_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_pressure_button.disabled = true
	_filter_pressure_button.pressed.connect(_on_filter_pressure_locked)
	_filter_stage_controls.add_child(_filter_pressure_button)
	_filter_pressure_slider.grab_focus()


func _on_filter_pressure_changed(value: float) -> void:
	_filter_airflow = value
	_filter_diagram.airflow = value
	_filter_diagram.queue_redraw()
	_filter_pressure_label.text = "AIRFLOW PRESSURE  /  %d%%" % roundi(value)
	var in_band := value >= 62.0 and value <= 72.0
	_filter_pressure_label.add_theme_color_override("font_color", GREEN if in_band else PALE)
	_filter_pressure_button.disabled = not in_band


func _on_filter_pressure_locked() -> void:
	if _task_complete or _filter_stage != 2 or _filter_airflow < 62.0 or _filter_airflow > 72.0:
		return
	_complete_task("LIFE SUPPORT RESTORED  /  AIRFLOW PRESSURE STABLE")


func _complete_task(message: String) -> void:
	if _task_complete:
		return
	_task_complete = true
	if is_instance_valid(_filter_pressure_slider):
		_filter_pressure_slider.editable = false
	if is_instance_valid(_filter_pressure_button):
		_filter_pressure_button.disabled = true
	if is_instance_valid(_power_sync_button):
		_power_sync_button.disabled = true
	if is_instance_valid(_nutrient_restore_button):
		_nutrient_restore_button.disabled = true
	for button in _nutrient_rotate_buttons:
		button.disabled = true
	for slider in _power_sliders:
		slider.editable = false
	_status_label.text = "SYSTEM RESTORED"
	_status_label.add_theme_color_override("font_color", GREEN)
	_status_light.color = GREEN
	_success_banner.text = "✓   %s" % message
	_success_banner.add_theme_color_override("font_color", GREEN)
	_progress_bar.value = mini(_completed_count + 1, _task_total)
	_progress_label.text = "%02d / %02d TASKS COMPLETE" % [mini(_completed_count + 1, _task_total), _task_total]
	_refresh_filter_step_footer()
	_refresh_nutrient_step_footer()
	_return_button.visible = true
	_return_button.grab_focus()
	task_completed.emit(_task_id)


func _refresh_filter_step_footer() -> void:
	for index in range(_filter_step_labels.size()):
		var color := MUTED
		if _task_complete or index < _filter_stage:
			color = GREEN
		elif index == _filter_stage:
			color = GOLD
		_filter_step_labels[index].add_theme_color_override("font_color", color)


func _build_footer() -> Control:
	var footer := HBoxContainer.new()
	footer.custom_minimum_size.y = 42.0
	footer.add_theme_constant_override("separation", 8)
	footer.add_child(_label("DEVICE INTERFACE  /  LOCAL CONTROL" if _is_labroom_task() else "FIELD TERMINAL  /  EREBOS DEEP-SPACE SURVEY", 9, MUTED))
	footer.add_spacer(false)
	footer.add_child(_label("ESC  CLOSE CONSOLE", 9, MUTED))
	if is_instance_valid(_return_button):
		footer.add_child(_return_button)
	return footer


func _centered(control: Control) -> Control:
	var center := CenterContainer.new()
	center.add_child(control)
	return center


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", maxi(12, font_size))
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, minimum_size: Vector2, _accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 12)
	return button

func _style_task_slider(slider: HSlider, _accent: Color) -> void:
	slider.custom_minimum_size.y = maxf(28.0, slider.custom_minimum_size.y)
	slider.focus_mode = Control.FOCUS_ALL

func _pressure_scale() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_child(_label("0% / LOW", 12, MUTED))
	row.add_spacer(false)
	row.add_child(_label("HIGH / 100%", 12, MUTED))
	return row

func _panel_style(background: Color, _border: Color, padding: float) -> StyleBox:
	# The only unframed areas are the solid progress-bar fills.
	if padding <= 0.0:
		var fill := StyleBoxFlat.new()
		fill.bg_color = background
		return fill
	return SKIN.panel(padding, padding < 16.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_close_console()
		get_viewport().set_input_as_handled()


func _close_console() -> void:
	if _is_closing:
		return
	_is_closing = true
	_close_button.disabled = true
	var tween := create_tween()
	tween.tween_property(_root, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	console_closed.emit()
	queue_free()


func set_resume_progress(data: Dictionary) -> void:
	_resume_progress=data.duplicate(true)


func progress_snapshot() -> Dictionary:
	var charges: Array=[]
	for slider in _power_sliders: charges.append(slider.value)
	return {"task":str(_task_id),"power":charges,"filter_stage":_filter_stage,"filter_rotation":_filter_rotation,"filter_airflow":_filter_airflow,"nutrient_rotations":Array(_nutrient_rotations),"complete":_task_complete}


func _restore_service_progress() -> void:
	if _resume_progress.is_empty() or _resume_progress.get("task","")!=str(_task_id): return
	if _task_id==&"auxiliary_power":
		var values: Array=_resume_progress.get("power",[])
		for i in range(mini(values.size(),_power_sliders.size())): _power_sliders[i].value=clampf(float(values[i]),0,100)
	elif _task_id==&"air_filter":
		var stage := clampi(int(_resume_progress.get("filter_stage",0)),0,2)
		if stage>=1:
			_on_filter_release_pressed()
			var rotations := 2 if stage==2 else clampi(int(_resume_progress.get("filter_rotation",0)),0,3)
			for i in range(rotations): _on_filter_rotate_pressed()
		if stage==2:
			_on_filter_seat_pressed()
			_filter_pressure_slider.value=clampf(float(_resume_progress.get("filter_airflow",18)),0,100)
	elif _task_id==&"nutrient_flow":
		var rotations: Array=_resume_progress.get("nutrient_rotations",[])
		for i in range(mini(rotations.size(),_nutrient_rotations.size())):
			_nutrient_rotations[i]=posmod(int(rotations[i]),4)
			_nutrient_diagram.rotations[i]=_nutrient_rotations[i]
		_nutrient_diagram.queue_redraw();_update_nutrient_readouts()
