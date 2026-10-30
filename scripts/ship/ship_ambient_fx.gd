@tool
extends Node2D

const GAS_MIST_SCENE: PackedScene = preload("res://scenes/ship/props/ambient_gas_mist.tscn")

@export var is_subdeck: bool = false

# Abundant slow-drifting gas, steam, and industrial fume clouds across the First Floor (Main Deck)
const MAIN_DECK_FUME_ZONES: Array = [
	# R01 Bridge & West Foyer subtle coolant vapor
	{"pos": Vector2(215.0, 355.0), "color": Color(0.52, 0.84, 0.96, 1.0), "opacity": 0.34, "spread": Vector2(54.0, 26.0), "blobs": 18, "size": Vector2(44.0, 30.0)},
	{"pos": Vector2(360.0, 350.0), "color": Color(0.62, 0.80, 0.92, 1.0), "opacity": 0.38, "spread": Vector2(48.0, 24.0), "blobs": 16, "size": Vector2(42.0, 28.0)},
	# R02 Upper Main Room vent & console fumes
	{"pos": Vector2(725.0, 175.0), "color": Color(0.58, 0.82, 0.94, 1.0), "opacity": 0.38, "spread": Vector2(72.0, 32.0), "blobs": 20, "size": Vector2(48.0, 32.0)},
	{"pos": Vector2(980.0, 175.0), "color": Color(0.66, 0.78, 0.90, 1.0), "opacity": 0.36, "spread": Vector2(68.0, 30.0), "blobs": 18, "size": Vector2(46.0, 30.0)},
	# R03 Center Recess lift shaft rising sub-deck fumes
	{"pos": Vector2(862.0, 326.0), "color": Color(0.86, 0.64, 0.34, 1.0), "opacity": 0.46, "spread": Vector2(56.0, 24.0), "blobs": 20, "size": Vector2(44.0, 30.0)},
	# Main Corridor spine vent fumes
	{"pos": Vector2(615.0, 390.0), "color": Color(0.64, 0.82, 0.90, 1.0), "opacity": 0.40, "spread": Vector2(64.0, 22.0), "blobs": 18, "size": Vector2(44.0, 28.0)},
	{"pos": Vector2(965.0, 390.0), "color": Color(0.72, 0.80, 0.88, 1.0), "opacity": 0.40, "spread": Vector2(64.0, 22.0), "blobs": 18, "size": Vector2(44.0, 28.0)},
	# R04 Power Maintenance & R05 Life Support heavy coolant/scrubber fumes
	{"pos": Vector2(1118.0, 336.0), "color": Color(0.92, 0.68, 0.32, 1.0), "opacity": 0.48, "spread": Vector2(58.0, 30.0), "blobs": 22, "size": Vector2(46.0, 32.0)},
	{"pos": Vector2(1275.0, 330.0), "color": Color(0.48, 0.90, 0.82, 1.0), "opacity": 0.48, "spread": Vector2(58.0, 30.0), "blobs": 22, "size": Vector2(46.0, 32.0)},
	# R06 Engine Room thick turbine exhaust & coolant steam
	{"pos": Vector2(1465.0, 295.0), "color": Color(0.95, 0.64, 0.28, 1.0), "opacity": 0.52, "spread": Vector2(76.0, 42.0), "blobs": 24, "size": Vector2(52.0, 36.0)},
	{"pos": Vector2(1480.0, 395.0), "color": Color(0.76, 0.86, 0.96, 1.0), "opacity": 0.50, "spread": Vector2(82.0, 44.0), "blobs": 24, "size": Vector2(54.0, 36.0)},
	{"pos": Vector2(1465.0, 485.0), "color": Color(0.92, 0.58, 0.26, 1.0), "opacity": 0.52, "spread": Vector2(76.0, 42.0), "blobs": 24, "size": Vector2(52.0, 36.0)},
	# R07 Crew Quarters mist (Lab Room kept clear of industrial fumes)
	{"pos": Vector2(465.0, 565.0), "color": Color(0.62, 0.80, 0.92, 1.0), "opacity": 0.36, "spread": Vector2(72.0, 36.0), "blobs": 18, "size": Vector2(48.0, 32.0)},
	# R09 Shuttle Bay hazmat fumes
	{"pos": Vector2(1285.0, 625.0), "color": Color(0.84, 0.66, 0.34, 1.0), "opacity": 0.46, "spread": Vector2(74.0, 38.0), "blobs": 22, "size": Vector2(50.0, 34.0)},
	# R10 Hydroponics & R11 Lower Deck East dense bio-fumes & bilge fog
	{"pos": Vector2(215.0, 742.0), "color": Color(0.46, 0.90, 0.68, 1.0), "opacity": 0.50, "spread": Vector2(82.0, 38.0), "blobs": 24, "size": Vector2(52.0, 36.0)},
	{"pos": Vector2(365.0, 736.0), "color": Color(0.52, 0.88, 0.82, 1.0), "opacity": 0.48, "spread": Vector2(78.0, 36.0), "blobs": 22, "size": Vector2(50.0, 34.0)},
	{"pos": Vector2(675.0, 742.0), "color": Color(0.62, 0.84, 0.72, 1.0), "opacity": 0.50, "spread": Vector2(86.0, 40.0), "blobs": 24, "size": Vector2(54.0, 36.0)},
	{"pos": Vector2(885.0, 748.0), "color": Color(0.78, 0.68, 0.38, 1.0), "opacity": 0.50, "spread": Vector2(86.0, 40.0), "blobs": 24, "size": Vector2(54.0, 36.0)},
]

# Dense industrial fumes, steam clouds, and containment gas across the Second Floor (Sub-Deck 02)
const SUBDECK_FUME_ZONES: Array = [
	# Upper service spine and lift junction
	{"pos": Vector2(882.0, 255.0), "color": Color(0.88, 0.62, 0.30, 1.0), "opacity": 0.50, "spread": Vector2(82.0, 30.0), "blobs": 22, "size": Vector2(50.0, 34.0)},
	{"pos": Vector2(882.0, 420.0), "color": Color(0.68, 0.82, 0.92, 1.0), "opacity": 0.44, "spread": Vector2(44.0, 76.0), "blobs": 20, "size": Vector2(42.0, 32.0)},
	# Cargo vault cold vapor and dusty aisle haze
	{"pos": Vector2(300.0, 235.0), "color": Color(0.66, 0.82, 0.92, 1.0), "opacity": 0.46, "spread": Vector2(100.0, 52.0), "blobs": 24, "size": Vector2(54.0, 38.0)},
	{"pos": Vector2(525.0, 325.0), "color": Color(0.82, 0.64, 0.36, 1.0), "opacity": 0.44, "spread": Vector2(78.0, 42.0), "blobs": 22, "size": Vector2(50.0, 34.0)},
	# Turbine hall hot exhaust and coolant steam
	{"pos": Vector2(1355.0, 250.0), "color": Color(0.94, 0.62, 0.28, 1.0), "opacity": 0.54, "spread": Vector2(96.0, 54.0), "blobs": 26, "size": Vector2(58.0, 40.0)},
	{"pos": Vector2(1525.0, 265.0), "color": Color(0.54, 0.86, 0.94, 1.0), "opacity": 0.48, "spread": Vector2(76.0, 38.0), "blobs": 22, "size": Vector2(52.0, 36.0)},
	# Lower workshop and coolant-pump haze
	{"pos": Vector2(535.0, 680.0), "color": Color(0.88, 0.64, 0.32, 1.0), "opacity": 0.48, "spread": Vector2(84.0, 46.0), "blobs": 22, "size": Vector2(52.0, 36.0)},
	{"pos": Vector2(925.0, 680.0), "color": Color(0.50, 0.88, 0.82, 1.0), "opacity": 0.48, "spread": Vector2(84.0, 48.0), "blobs": 24, "size": Vector2(54.0, 38.0)},
	# Toxic bio-fumes gather in the blind run and hidden nest
	{"pos": Vector2(1285.0, 682.0), "color": Color(0.56, 0.84, 0.42, 1.0), "opacity": 0.50, "spread": Vector2(96.0, 32.0), "blobs": 24, "size": Vector2(50.0, 34.0)},
	{"pos": Vector2(1600.0, 680.0), "color": Color(0.48, 0.86, 0.38, 1.0), "opacity": 0.58, "spread": Vector2(84.0, 56.0), "blobs": 26, "size": Vector2(54.0, 38.0)},
	{"pos": Vector2(1625.0, 735.0), "color": Color(0.86, 0.48, 0.24, 1.0), "opacity": 0.50, "spread": Vector2(58.0, 36.0), "blobs": 20, "size": Vector2(48.0, 34.0)},
]

# Subtle, non-shaky console status lights & radar sweeps
const MAIN_DECK_CONSOLES: Array = [
	{"pos": Vector2(261.0, 347.0), "kind": &"radar", "color": Color(0.28, 0.90, 0.78, 0.75), "radius": 8.0},
	{"pos": Vector2(116.0, 340.0), "kind": &"leds", "color": Color(0.35, 0.88, 1.0, 0.80)},
	{"pos": Vector2(166.0, 294.0), "kind": &"leds", "color": Color(0.32, 0.95, 0.62, 0.80)},
	{"pos": Vector2(161.0, 416.0), "kind": &"leds", "color": Color(1.0, 0.72, 0.28, 0.80)},
	{"pos": Vector2(1108.0, 292.0), "kind": &"bars", "color": Color(1.0, 0.64, 0.24, 0.78)},
	{"pos": Vector2(1268.0, 286.0), "kind": &"bars", "color": Color(0.34, 0.92, 0.78, 0.78)},
]

const SUBDECK_CONSOLES: Array = []

const SUBDECK_SHADOW_EYES: Array = [
	{"pos": Vector2(420.0, 340.0), "phase": 0.4, "color": Color(1.0, 0.25, 0.15, 0.85)},
	{"pos": Vector2(650.0, 210.0), "phase": 1.9, "color": Color(0.85, 0.20, 0.35, 0.85)},
	{"pos": Vector2(1240.0, 690.0), "phase": 3.2, "color": Color(1.0, 0.30, 0.10, 0.90)},
	{"pos": Vector2(1580.0, 660.0), "phase": 4.7, "color": Color(0.95, 0.18, 0.22, 0.95)},
]

const REACTOR_ARCS: Array = [
	{"a": Vector2(1092.0, 315.0), "b": Vector2(1136.0, 315.0), "color": Color(0.35, 0.88, 1.0, 0.85)},
	{"a": Vector2(1114.0, 315.0), "b": Vector2(1114.0, 355.0), "color": Color(1.0, 0.72, 0.28, 0.80)},
	{"a": Vector2(1445.0, 385.0), "b": Vector2(1495.0, 385.0), "color": Color(0.42, 0.95, 1.0, 0.85)},
	{"a": Vector2(1470.0, 370.0), "b": Vector2(1470.0, 415.0), "color": Color(1.0, 0.55, 0.20, 0.85)},
]

const HOLOGRAPHIC_TERMINALS: Array = [
	{"pos": Vector2(261.0, 340.0), "type": &"radar_wireframe", "color": Color(0.28, 0.92, 1.0, 0.75)},
	{"pos": Vector2(116.0, 335.0), "type": &"telemetry_stream", "color": Color(0.35, 0.95, 0.65, 0.70)},
]

const HYDROPONICS_SPORES_BOUNDS := Rect2(Vector2(140.0, 680.0), Vector2(300.0, 140.0))

var _time: float = 0.0
var _vent_positions: Array = []
var _vents_cached: bool = false


func _ready() -> void:
	z_as_relative = false
	z_index = 2
	_spawn_fume_emitters()
	set_process(true)
	_cache_vent_positions.call_deferred()


func _spawn_fume_emitters() -> void:
	for child in get_children():
		child.queue_free()
	var zones: Array = SUBDECK_FUME_ZONES if is_subdeck else MAIN_DECK_FUME_ZONES
	for i in range(zones.size()):
		var zcfg: Dictionary = zones[i]
		var mist: Node2D = GAS_MIST_SCENE.instantiate() as Node2D
		mist.name = "FumeCloud_%02d" % i
		mist.position = zcfg["pos"]
		mist.set("gas_color", zcfg["color"])
		mist.set("opacity", float(zcfg["opacity"]))
		mist.set("spread", zcfg["spread"])
		mist.set("blob_count", int(zcfg["blobs"]))
		mist.set("blob_size", zcfg["size"])
		mist.set("drift_speed", 4.2)
		mist.set("lifetime", 8.5)
		add_child(mist)


func _cache_vent_positions() -> void:
	_vent_positions.clear()
	var root_node: Node = get_parent()
	if root_node != null:
		_collect_vents_recursive(root_node)
	_vents_cached = true


func _collect_vents_recursive(node: Node) -> void:
	for child in node.get_children():
		if child == self:
			continue
		var sp: Sprite2D = child as Sprite2D
		if sp != null and sp.texture != null and sp.texture.resource_path.find("floor_vent") != -1:
			_vent_positions.append(to_local(sp.global_position))
		_collect_vents_recursive(child)


func _process(delta: float) -> void:
	_time = fposmod(_time + delta, 10000.0)
	if not _vents_cached:
		_cache_vent_positions()
	queue_redraw()


func _get_player_world_pos() -> Vector2:
	var root_node: Node = get_parent()
	if root_node == null:
		return Vector2(-9999.0, -9999.0)
	var p: Node2D = root_node.get_node_or_null("Player") as Node2D
	if is_instance_valid(p):
		return p.global_position
	return Vector2(-9999.0, -9999.0)


func _draw() -> void:
	_draw_console_telemetry()
	_draw_holographic_terminals()
	_draw_vent_fume_plumes()
	_draw_vent_steam_geysers()
	_draw_reactor_lightning_arcs()
	_draw_engine_heat_and_embers()
	_draw_hydroponics_bioluminescent_spores()
	_draw_ambient_dust_motes()
	if is_subdeck:
		_draw_shadow_eyes()
		_draw_subdeck_atmosphere()


func _draw_reactor_lightning_arcs() -> void:
	if is_subdeck:
		return
	# Periodic violent electrical discharges between conduit terminals
	for arc_idx in range(REACTOR_ARCS.size()):
		var arc_def: Dictionary = REACTOR_ARCS[arc_idx]
		var p_start: Vector2 = arc_def["a"]
		var p_end: Vector2 = arc_def["b"]
		var base_col: Color = arc_def["color"]
		var arc_cycle: float = fposmod(_time * 1.8 + float(arc_idx) * 1.33, 3.2)
		if arc_cycle > 0.42:
			continue
		var arc_alpha: float = clampf(sin((arc_cycle / 0.42) * PI), 0.0, 1.0)
		var segs: int = 6
		var prev_pt := p_start
		var delta_v := p_end - p_start
		var perp_v := Vector2(-delta_v.y, delta_v.x).normalized()
		for s in range(1, segs + 1):
			var t_s: float = float(s) / float(segs)
			var jitter: float = sin(_time * 36.0 + float(s) * 3.7 + float(arc_idx) * 5.2) * 6.5 * sin(t_s * PI)
			var next_pt: Vector2 = p_start.lerp(p_end, t_s) + perp_v * jitter
			draw_line(prev_pt, next_pt, Color(base_col.r, base_col.g, base_col.b, arc_alpha * 0.45), 3.4, true)
			draw_line(prev_pt, next_pt, Color(1.0, 1.0, 1.0, arc_alpha * 0.95), 1.4, true)
			prev_pt = next_pt
		draw_circle(p_start, 2.5 * arc_alpha, Color(1.0, 1.0, 1.0, arc_alpha))
		draw_circle(p_end, 2.5 * arc_alpha, Color(1.0, 1.0, 1.0, arc_alpha))


func _draw_engine_heat_and_embers() -> void:
	if is_subdeck:
		return
	# Turbine core heat pulse
	var t_pos := Vector2(1475.0, 395.0)
	var heat_pulse := 0.75 + 0.25 * sin(_time * 4.2)
	draw_circle(t_pos, 36.0 * heat_pulse, Color(1.0, 0.42, 0.12, 0.08 * heat_pulse))
	draw_circle(t_pos, 20.0 * heat_pulse, Color(1.0, 0.58, 0.18, 0.14 * heat_pulse))
	draw_circle(t_pos, 8.0 * heat_pulse, Color(1.0, 0.88, 0.45, 0.35 * heat_pulse))

	# Showers of floating industrial embers drifting from engine machinery
	for e in range(18):
		var e_phase: float = fposmod(_time * 0.18 + float(e) * 0.055, 1.0)
		var e_origin := Vector2(1440.0 + fposmod(float(e) * 31.0, 80.0), 280.0 + fposmod(float(e) * 47.0, 240.0))
		var e_drift := Vector2(sin(_time * 0.8 + float(e)) * 14.0, -e_phase * 34.0)
		var e_pos := e_origin + e_drift
		var e_fade := sin(e_phase * PI)
		var e_sz := 1.2 + 0.6 * sin(float(e) * 2.0)
		draw_rect(Rect2(e_pos - Vector2(e_sz, e_sz) * 0.5, Vector2(e_sz, e_sz)), Color(1.0, 0.62, 0.22, e_fade * 0.85))
		draw_rect(Rect2(e_pos - Vector2(0.5, 0.5), Vector2(1.0, 1.0)), Color(1.0, 0.95, 0.75, e_fade))


func _draw_vent_steam_geysers() -> void:
	for i in range(_vent_positions.size()):
		var vpos: Vector2 = _vent_positions[i]
		var geyser_cycle: float = fposmod(_time * 0.35 + float(i) * 0.85, 4.0)
		if geyser_cycle > 0.85:
			continue
		var g_norm: float = geyser_cycle / 0.85
		var g_fade: float = sin(g_norm * PI)
		var jet_h: float = g_norm * 38.0
		var jet_w: float = 3.5 + g_norm * 14.0
		var jet_col := Color(0.75, 0.90, 0.98, 0.28 * g_fade) if not is_subdeck else Color(0.65, 0.85, 0.55, 0.32 * g_fade)
		_draw_custom_ellipse(vpos + Vector2(0.0, -jet_h * 0.6), jet_w * 0.5, jet_h * 0.5, jet_col)
		draw_circle(vpos + Vector2(sin(_time * 8.0 + float(i)) * 4.0, -jet_h), 5.5 + g_norm * 8.0, Color(jet_col.r, jet_col.g, jet_col.b, jet_col.a * 0.75))


func _draw_hydroponics_bioluminescent_spores() -> void:
	if is_subdeck:
		return
	var b_pos := HYDROPONICS_SPORES_BOUNDS.position
	var b_sz := HYDROPONICS_SPORES_BOUNDS.size
	for s in range(26):
		var s_phase: float = fposmod(_time * 0.12 + float(s) * 0.038, 1.0)
		var sx: float = b_pos.x + fposmod(float(s) * 43.7 + sin(_time * 0.3 + float(s)) * 25.0, b_sz.x)
		var sy: float = b_pos.y + fposmod(float(s) * 29.3 - s_phase * b_sz.y, b_sz.y)
		var fade := sin(s_phase * PI)
		var spore_pos := Vector2(sx, sy)
		var spore_col := Color(0.35, 0.98, 0.65, 0.85 * fade) if s % 2 == 0 else Color(0.42, 0.88, 1.0, 0.85 * fade)
		var halo_col := Color(spore_col.r, spore_col.g, spore_col.b, 0.22 * fade)
		draw_circle(spore_pos, 4.2 + sin(_time * 3.0 + float(s)) * 1.2, halo_col)
		draw_circle(spore_pos, 1.5, spore_col)
		draw_circle(spore_pos, 0.7, Color(1.0, 1.0, 1.0, fade * 0.95))


func _draw_holographic_terminals() -> void:
	if is_subdeck:
		return
	for ht in HOLOGRAPHIC_TERMINALS:
		var pos: Vector2 = ht["pos"]
		var h_type: StringName = ht["type"]
		var h_col: Color = ht["color"]
		var h_pulse: float = 0.85 + 0.15 * sin(_time * 4.0)

		# Upward projector beam cone
		var p_top_l := pos + Vector2(-16.0, -28.0)
		var p_top_r := pos + Vector2(16.0, -28.0)
		var p_bot := pos + Vector2(0.0, -2.0)
		draw_colored_polygon(
			PackedVector2Array([p_bot, p_top_l, p_top_r]),
			Color(h_col.r, h_col.g, h_col.b, 0.065 * h_pulse)
		)

		match h_type:
			&"radar_wireframe":
				var center := pos + Vector2(0.0, -24.0)
				var rot_ang: float = _time * 1.5
				_draw_custom_ellipse(center, 12.0, 5.0, Color(h_col.r, h_col.g, h_col.b, 0.45 * h_pulse))
				var cross1 := center + Vector2(cos(rot_ang) * 12.0, sin(rot_ang) * 5.0)
				var cross2 := center - Vector2(cos(rot_ang) * 12.0, sin(rot_ang) * 5.0)
				draw_line(cross1, cross2, Color(1.0, 1.0, 1.0, 0.75 * h_pulse), 1.2, false)
				draw_circle(center, 1.8, Color(1.0, 1.0, 1.0, 0.95 * h_pulse))
			&"telemetry_stream":
				var base_y := pos.y - 30.0
				for line_i in range(4):
					var ly := base_y + float(line_i) * 5.0
					var l_w := 6.0 + 10.0 * (0.5 + 0.5 * sin(_time * 5.0 + float(line_i) * 2.1))
					draw_line(Vector2(pos.x - 8.0, ly), Vector2(pos.x - 8.0 + l_w, ly), Color(h_col.r, h_col.g, h_col.b, 0.70 * h_pulse), 1.2, false)


func _draw_ambient_dust_motes() -> void:
	for m in range(24):
		var m_phase: float = fposmod(_time * 0.08 + float(m) * 0.041, 1.0)
		var mx: float = 120.0 + fposmod(float(m) * 73.1 + sin(_time * 0.2 + float(m)) * 18.0, 1500.0)
		var my: float = 180.0 + fposmod(float(m) * 51.7 + cos(_time * 0.15 + float(m)) * 12.0, 600.0)
		var fade: float = sin(m_phase * PI)
		var mote_alpha: float = 0.45 * fade
		draw_circle(Vector2(mx, my), 0.9, Color(0.85, 0.95, 1.0, mote_alpha))


func _draw_subdeck_atmosphere() -> void:
	var beacon_center := Vector2(882.0, 320.0)
	var sweep_angle := _time * 2.2
	var sweep_arm := beacon_center + Vector2(cos(sweep_angle), sin(sweep_angle)) * 160.0
	draw_line(beacon_center, sweep_arm, Color(1.0, 0.18, 0.12, 0.22), 6.0, false)
	draw_line(beacon_center, sweep_arm, Color(1.0, 0.45, 0.35, 0.45), 2.0, false)
	draw_circle(beacon_center, 6.0, Color(1.0, 0.20, 0.15, 0.85))


func _draw_custom_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	if rx <= 0.05 or ry <= 0.05 or color.a <= 0.005:
		return
	var pts := PackedVector2Array()
	const STEPS := 16
	for i in range(STEPS):
		var angle := TAU * float(i) / float(STEPS)
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, color)


func _draw_console_telemetry() -> void:
	var consoles: Array = SUBDECK_CONSOLES if is_subdeck else MAIN_DECK_CONSOLES
	for idx in range(consoles.size()):
		var c: Dictionary = consoles[idx]
		var pos: Vector2 = c["pos"]
		var kind: StringName = c["kind"]
		var col: Color = c["color"]
		var phase: float = _time * 2.0 + float(idx) * 1.4

		match kind:
			&"radar":
				var rad: float = float(c.get("radius", 8.0))
				draw_arc(pos, rad, 0.0, TAU, 20, Color(col.r, col.g, col.b, 0.28), 1.0, false)
				var angle: float = fposmod(_time * 1.6 + float(idx), TAU)
				var sweep_end: Vector2 = pos + Vector2(cos(angle), sin(angle)) * rad
				draw_line(pos, sweep_end, Color(col.r, col.g, col.b, 0.78), 1.2, false)
			&"leds":
				for b in range(3):
					var blink: float = 0.35 + 0.65 * (0.5 + 0.5 * sin(phase + float(b) * 1.9))
					var led_pos: Vector2 = pos + Vector2(float(b - 1) * 3.6, 0.0)
					var led_col: Color = col if b != 2 else Color(1.0, 0.56, 0.24, col.a)
					draw_circle(led_pos, 1.2, Color(led_col.r, led_col.g, led_col.b, led_col.a * blink))
			&"bars":
				for b in range(4):
					var h: float = 2.0 + 3.8 * (0.5 + 0.5 * sin(_time * 2.6 + float(b) * 1.5 + float(idx)))
					var bx: float = pos.x - 6.0 + float(b) * 3.6
					draw_rect(Rect2(bx, pos.y - h, 2.0, h), Color(col.r, col.g, col.b, 0.72), true)


func _draw_vent_fume_plumes() -> void:
	for i in range(_vent_positions.size()):
		var vpos: Vector2 = _vent_positions[i]
		var seed_phase: float = float(i) * 1.47
		for puff in range(3):
			var p_phase: float = fposmod(_time * 0.22 + seed_phase + float(puff) * 0.33, 1.0)
			var fade: float = sin(p_phase * PI)
			var sway_x: float = sin(_time * 0.65 + seed_phase + float(puff) * 2.1) * (8.0 + 6.0 * p_phase)
			var lift_y: float = -22.0 * p_phase
			var cpos: Vector2 = vpos + Vector2(sway_x, lift_y)
			var rad: float = 7.0 + 11.0 * p_phase
			var fume_col: Color = Color(0.64, 0.80, 0.88, 0.11 * fade) if not is_subdeck else Color(0.72, 0.78, 0.68, 0.14 * fade)
			draw_circle(cpos, rad, fume_col)
			draw_circle(cpos + Vector2(rad * 0.35, -2.0), rad * 0.72, Color(fume_col.r, fume_col.g, fume_col.b, fume_col.a * 0.8))


func _draw_shadow_eyes() -> void:
	var player_pos: Vector2 = _get_player_world_pos()
	for idx in range(SUBDECK_SHADOW_EYES.size()):
		var ed: Dictionary = SUBDECK_SHADOW_EYES[idx]
		var epos: Vector2 = ed["pos"]
		var phase: float = float(ed["phase"])
		var col: Color = ed["color"]

		var world_epos: Vector2 = to_global(epos)
		var dist: float = world_epos.distance_to(player_pos)
		if dist < 130.0:
			continue

		var cycle: float = fposmod(_time * 0.45 + phase, 7.0)
		if cycle > 2.6:
			continue
		var blink_curve: float = sin((cycle / 2.6) * PI)
		var alpha: float = col.a * blink_curve * clampf((dist - 130.0) / 90.0, 0.0, 1.0)
		if alpha <= 0.02:
			continue

		var left_eye: Vector2 = epos + Vector2(-2.6, 0.0)
		var right_eye: Vector2 = epos + Vector2(2.6, 0.0)
		draw_circle(left_eye, 2.0, Color(col.r, col.g, col.b, alpha * 0.30))
		draw_circle(right_eye, 2.0, Color(col.r, col.g, col.b, alpha * 0.30))
		draw_circle(left_eye, 1.0, Color(1.0, 0.58, 0.36, alpha))
		draw_circle(right_eye, 1.0, Color(1.0, 0.58, 0.36, alpha))
