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
	# R07 Crew Quarters & R08 Central Cargo Bay mist
	{"pos": Vector2(465.0, 565.0), "color": Color(0.62, 0.80, 0.92, 1.0), "opacity": 0.36, "spread": Vector2(72.0, 36.0), "blobs": 18, "size": Vector2(48.0, 32.0)},
	{"pos": Vector2(835.0, 565.0), "color": Color(0.58, 0.86, 0.82, 1.0), "opacity": 0.42, "spread": Vector2(84.0, 40.0), "blobs": 22, "size": Vector2(52.0, 34.0)},
	{"pos": Vector2(1015.0, 565.0), "color": Color(0.74, 0.82, 0.90, 1.0), "opacity": 0.40, "spread": Vector2(78.0, 38.0), "blobs": 20, "size": Vector2(50.0, 34.0)},
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

const SUBDECK_SHADOW_EYES: Array = []

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
	_draw_vent_fume_plumes()
	if is_subdeck:
		_draw_shadow_eyes()


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
