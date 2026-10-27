@tool
extends Node2D

@export var lift_title: String = "SUB-DECK 02 // CARGO & PIPE HOLD"
@export var is_up_lift: bool = false

var _pulse: float = 0.0


func _ready() -> void:
	z_as_relative = false
	z_index = -1
	set_process(not Engine.is_editor_hint())
	queue_redraw()


func _process(delta: float) -> void:
	_pulse = fposmod(_pulse + delta * 2.4, TAU)
	queue_redraw()


func _draw() -> void:
	var half_w: float = 36.0
	var half_h: float = 19.0
	var outer: Rect2 = Rect2(-half_w, -half_h, half_w * 2.0, half_h * 2.0)

	# Outer shadow & recessed shaft curb
	draw_rect(outer.grow(3.0), Color(0.01, 0.015, 0.02, 0.92), true)
	draw_rect(outer.grow(1.5), Color(0.22, 0.25, 0.29, 0.96), true)

	# Hazard warning border stripes along top and bottom sills
	var stripe_col_a: Color = Color(0.78, 0.56, 0.14, 0.88)
	var stripe_col_b: Color = Color(0.08, 0.09, 0.11, 0.95)
	var stripe_w: float = 6.0
	var x: float = -half_w
	var idx: int = 0
	while x < half_w:
		var w: float = minf(stripe_w, half_w - x)
		var c: Color = stripe_col_a if idx % 2 == 0 else stripe_col_b
		draw_rect(Rect2(x, -half_h, w, 3.0), c, true)
		draw_rect(Rect2(x, half_h - 3.0, w, 3.0), c, true)
		x += stripe_w
		idx += 1

	# Inner dark elevator platform deck
	var plat: Rect2 = Rect2(-half_w + 3.0, -half_h + 3.0, (half_w - 3.0) * 2.0, (half_h - 3.0) * 2.0)
	draw_rect(plat, Color(0.055, 0.07, 0.09, 0.98), true)
	draw_rect(plat, Color(0.30, 0.36, 0.42, 0.88), false, 1.0)

	# Recessed shaft steps / grating ribs
	var rib_ys: Array = [-10.0, -5.0, 0.0, 5.0, 10.0]
	for ry in rib_ys:
		draw_line(
			Vector2(-half_w + 6.0, ry),
			Vector2(half_w - 6.0, ry),
			Color(0.11, 0.15, 0.18, 0.95),
			1.5,
			false
		)

	# Center split seam
	draw_line(Vector2(0.0, -half_h + 3.0), Vector2(0.0, half_h - 3.0), Color(0.02, 0.03, 0.04, 0.95), 2.0, false)

	# Subtle glowing guide rails on left and right sides
	var glow: float = 0.60 + 0.40 * (0.5 + 0.5 * sin(_pulse))
	var accent: Color = Color(0.26, 0.76, 0.92, 0.62 * glow) if is_up_lift else Color(0.92, 0.58, 0.20, 0.62 * glow)
	draw_line(Vector2(-half_w + 5.0, -half_h + 5.0), Vector2(-half_w + 5.0, half_h - 5.0), accent, 1.8, false)
	draw_line(Vector2(half_w - 5.0, -half_h + 5.0), Vector2(half_w - 5.0, half_h - 5.0), accent, 1.8, false)

	# Direction chevron in center
	var dir_sign: float = -1.0 if is_up_lift else 1.0
	var chev_a: Vector2 = Vector2(-6.0, -2.0 * dir_sign)
	var chev_b: Vector2 = Vector2(0.0, 3.5 * dir_sign)
	var chev_c: Vector2 = Vector2(6.0, -2.0 * dir_sign)
	draw_line(chev_a, chev_b, accent.lightened(0.20), 1.8, false)
	draw_line(chev_b, chev_c, accent.lightened(0.20), 1.8, false)
