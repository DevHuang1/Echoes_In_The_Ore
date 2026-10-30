class_name EitoControls
extends RefCounted
## Small Control building blocks in the design language, for screens built from
## ordinary Godot containers (HUD, inventory, map, settings, title, intro,
## briefing, station panels). Materials come from EitoStyle; type from eito_ui.

const UI := preload("res://scripts/ui/eito/eito_ui.gd")
const STYLE := preload("res://scripts/ui/eito/eito_style.gd")

## Metal plate with the design's header strip and stamped Silkscreen title.
## Children sit below the header (content margins include it).
class Plate extends PanelContainer:
	var title := ""
	var chip := ""
	var chip_lamp := ""
	var plate_material := "module"
	var screws := true
	var header := true
	var pad := 16.0
	var _now := 0.0

	func _init(plate_title := "", plate_material_arg := "module", with_header := true, padding := 16.0) -> void:
		title = plate_title; plate_material = plate_material_arg; header = with_header and not plate_title.is_empty(); pad = padding
		var s := StyleBoxEmpty.new()
		s.content_margin_left = pad; s.content_margin_right = pad
		s.content_margin_top = (44.0 if header else pad); s.content_margin_bottom = pad
		add_theme_stylebox_override("panel", s)
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func set_chip(text: String, lamp := "") -> void:
		chip = text; chip_lamp = lamp; queue_redraw()
		set_process(lamp in ["warn", "live"])

	func _process(delta: float) -> void:
		_now += delta; queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		STYLE.paint(self, r, plate_material, screws)
		if not header: return
		var hx := 4.0; var hw := size.x - 8.0
		draw_rect(Rect2(hx, 34, hw, 2), Color("#0f181b"))
		draw_rect(Rect2(hx, 36, hw, 2), Color("#2e444a"))
		var f := UI.font("label", 400, 0.96)
		var tx := 22.0 if not screws else 26.0
		UI.text(self, f, 16, title, tx, 4, Color("#0a1012"), 32)
		UI.text(self, f, 16, title, tx, 2, UI.LABEL, 32)
		if not chip.is_empty():
			var fb := UI.font("body")
			var w := UI.tw(fb, 16, chip) + (24.0 if not chip_lamp.is_empty() else 0.0)
			var x := size.x - (26.0 if screws else 22.0) - w
			if not chip_lamp.is_empty():
				UI.draw_lamp(self, Vector2(x, 9), chip_lamp, _now)
				x += 24
			UI.text(self, fb, 16, chip, x, 8, Color("#ddd8c8"), 20)

## Status lamp sprite (ok / warn / fault / live / off), blinking like the design.
class Lamp extends Control:
	var state := "off":
		set(v): state = v; queue_redraw(); set_process(v in ["warn", "live"])
	var _now := 0.0
	func _init(s := "off") -> void:
		custom_minimum_size = Vector2(18, 18); mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; state = s
	func _process(delta: float) -> void:
		_now += delta; queue_redraw()
	func _draw() -> void:
		UI.draw_lamp(self, ((size - Vector2(18, 18)) * 0.5).floor(), state, _now)

## Keyboard keycap (".kbd").
class Keycap extends Control:
	var text := "":
		set(v): text = v; _fit(); queue_redraw()
	var font_size := 14
	var min_w := 28.0
	var cap_h := 24.0
	func _init(t := "", size_px := 14, minimum_width := 28.0, height := 24.0) -> void:
		font_size = size_px; min_w = minimum_width; cap_h = height
		mouse_filter = Control.MOUSE_FILTER_IGNORE; size_flags_vertical = Control.SIZE_SHRINK_CENTER
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		text = t
	func _fit() -> void:
		var w := maxf(min_w, UI.tw(UI.font("label"), font_size, text) + 16.0)
		custom_minimum_size = Vector2(w, cap_h + 2)
	func _draw() -> void:
		var r := Rect2(0, 0, size.x, cap_h)
		UI.box(self, r, {"bg":Color("#26363b"), "border":UI.EDGE, "insets":[[2,2,0,Color("#46616a")],[-2,-2,0,Color("#141e21")]]})
		draw_rect(Rect2(0, cap_h, size.x, 2), UI.EDGE)
		UI.text(self, UI.font("label"), font_size, text, 0, 0, Color("#ece6d4"), cap_h, 1, size.x)

## Segmented meter (".cells"): n cells, `on` lit in `color`.
class Cells extends Control:
	var count := 10
	var on := 0
	var color := UI.PHOS
	var off := Color("#0b1714")
	func _init(n := 10, height := 10.0) -> void:
		count = n; custom_minimum_size = Vector2(n * 8, height); mouse_filter = Control.MOUSE_FILTER_IGNORE
	func set_value(lit: int, c := Color(0, 0, 0, 0)) -> void:
		on = lit
		if c.a > 0: color = c
		queue_redraw()
	func _draw() -> void:
		var gap := 2.0
		var cw := (size.x - gap * (count - 1)) / count
		for i in range(count):
			var x0 := roundf(i * (cw + gap)); var x1 := roundf(i * (cw + gap) + cw)
			var r := Rect2(x0, 0, x1 - x0, size.y)
			draw_rect(r, color if i < on else off)
			draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color.BLACK)
			draw_rect(Rect2(r.position, Vector2(1, r.size.y)), Color.BLACK)

## Thin hazard stripe (warning tape) used on development-only panels.
class Hazard extends Control:
	func _init(height := 8.0) -> void:
		custom_minimum_size = Vector2(0, height); mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var k := 0.70710678
		for y in range(int(size.y)):
			var x := 0
			while x < int(size.x):
				var t := fposmod(-(x + 0.5 + y + 0.5) * k, 8.0)
				if t < 4.0: draw_rect(Rect2(x, y, 1, 1), UI.WARN)
				else: draw_rect(Rect2(x, y, 1, 1), Color("#1d180e"))
				x += 1

static func draw_lamp(ci: CanvasItem, p: Vector2, st: String, now: float) -> void:
	UI.draw_lamp(ci, p, st, now)

## Label in one of the theme's type roles.
static func label(text: String, role := "", size := 0, color := Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	if not role.is_empty(): l.theme_type_variation = StringName(role)
	if size > 0: l.add_theme_font_size_override("font_size", size)
	if color.a > 0: l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

## Stamped look for a header label (dark 2px drop under the text).
static func stamp(l: Label) -> Label:
	l.add_theme_color_override("font_shadow_color", Color("#0a1012"))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

static func panel(material: String, margin := 12.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", STYLE.make(material, margin))
	return p
