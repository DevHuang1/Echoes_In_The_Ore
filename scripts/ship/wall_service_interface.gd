@tool
extends Node2D

@export var system_code: String = "PWR":
	set(value):
		system_code = value.to_upper().substr(0, 3)
		queue_redraw()

@export var accent_color: Color = Color(1.0, 0.62, 0.28, 1.0):
	set(value):
		accent_color = value
		queue_redraw()

@export_range(0.1, 4.0, 0.1) var pulse_speed: float = 1.5

var _pulse_phase: float = 0.0


func _process(delta: float) -> void:
	_pulse_phase = fposmod(_pulse_phase + delta * pulse_speed, TAU)
	queue_redraw()


func _draw() -> void:
	# The housing and controls stay fixed; only the small status lamp changes brightness.
	draw_rect(Rect2(-15.0, -22.0, 30.0, 44.0), Color(0.018, 0.025, 0.031))
	draw_rect(Rect2(-13.0, -20.0, 26.0, 40.0), Color(0.37, 0.38, 0.36))
	draw_rect(Rect2(-11.0, -18.0, 22.0, 36.0), Color(0.075, 0.09, 0.095))
	draw_rect(Rect2(-9.0, -16.0, 18.0, 14.0), Color(0.012, 0.045, 0.055))
	draw_rect(Rect2(-9.0, -16.0, 18.0, 14.0), Color(0.31, 0.38, 0.38), false, 1.0)

	draw_rect(Rect2(-6.0, -13.0, 12.0, 2.0), accent_color.darkened(0.35))
	draw_rect(Rect2(-6.0, -8.0, 12.0, 1.0), Color(0.24, 0.67, 0.69, 0.78))
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, Vector2(-7.0, -3.0), system_code, HORIZONTAL_ALIGNMENT_CENTER, 14.0, 5, Color(0.84, 0.91, 0.87))

	draw_rect(Rect2(-8.0, 2.0, 16.0, 6.0), Color(0.12, 0.15, 0.15))
	draw_rect(Rect2(-6.0, 4.0, 4.0, 2.0), Color(0.36, 0.69, 0.68))
	draw_rect(Rect2(2.0, 4.0, 4.0, 2.0), Color(0.36, 0.69, 0.68))
	draw_rect(Rect2(-8.0, 11.0, 16.0, 3.0), Color(0.18, 0.21, 0.21))
	draw_rect(Rect2(-8.0, 16.0, 16.0, 1.0), Color(0.59, 0.59, 0.53))

	var pulse := 0.55 + 0.45 * (0.5 + 0.5 * sin(_pulse_phase))
	var lamp_color := accent_color.lerp(Color.WHITE, 0.1 + 0.2 * pulse)
	draw_circle(Vector2(0.0, 19.0), 1.7, accent_color.darkened(0.45))
	draw_circle(Vector2(0.0, 19.0), 1.0, lamp_color)
