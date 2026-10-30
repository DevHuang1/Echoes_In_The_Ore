@tool
class_name EitoStyle
extends StyleBox
## Theme stylebox painted with the design's box painter, so ordinary Controls
## (buttons, panels, slots, sliders, tooltips) wear the same materials as the
## redesigned station screens at any size: notched metal, bezels, keycaps,
## recessed wells, phosphor glass and paper.

const UI := preload("res://scripts/ui/eito/eito_ui.gd")

@export_enum("module", "bezel", "well", "glass", "paper", "chip", "voice",
	"key", "key_hover", "key_down", "key_active", "key_off",
	"push", "push_hover", "push_down", "push_off",
	"close", "close_hover",
	"slot", "slot_hover", "slot_selected",
	"focus", "rule", "track", "fill", "cells", "none") var kind := "module":
	set(v): kind = v; emit_changed()
## Corner screws on module plates.
@export var screws := false:
	set(v): screws = v; emit_changed()
## Optional accent (fill colour for "fill"/"cells", ring for "focus").
@export var accent := Color(0, 0, 0, 0):
	set(v): accent = v; emit_changed()

static func make(k: String, margin := 8.0, with_screws := false, tint := Color(0, 0, 0, 0)) -> EitoStyle:
	var s := EitoStyle.new()
	s.kind = k; s.screws = with_screws; s.accent = tint
	s.set_content_margin_all(margin)
	return s

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var ci := UI.RidCanvas.new(to_canvas_item)
	paint(ci, rect, kind, screws, accent)

## Shared with custom-drawn controls so a Control can paint the same material.
static func paint(ci, r: Rect2, k: String, with_screws := false, tint := Color(0, 0, 0, 0)) -> void:
	r = Rect2(r.position.round(), r.size.round())
	if r.size.x < 4 or r.size.y < 4: return
	var big := r.size.x >= 16 and r.size.y >= 16
	match k:
		"module":
			UI.box(ci, r, {"notch":big, "bg":UI.HULL, "grad":[[0.0, UI.HULL_2], [1.0, UI.HULL]], "tex":UI.tex("noise"), "border":UI.EDGE, "insets":[[2,2,0,UI.HULL_HI],[-2,-2,0,UI.HULL_LO]]})
			if with_screws and r.size.x >= 60 and r.size.y >= 60: _screws(ci, r)
		"bezel":
			UI.box(ci, r, {"notch":big, "grad":[[0.0, Color("#34494f")], [1.0, Color("#22333a")]], "border":UI.EDGE, "insets":[[2,2,0,Color("#557178")],[-2,-2,0,Color("#141e22")]]})
		"well":
			UI.box(ci, r, {"bg":Color("#0c1518"), "border":UI.EDGE, "insets":[[2,2,0,Color("#05090b")],[-2,-2,0,Color("#22343a")]]})
		"glass":
			UI.glass(ci, r)
			_scan(ci, r)
		"paper":
			UI.paper(ci, r)
		"chip":
			UI.box(ci, r, {"notch":big, "bg":Color("#0a1114"), "border":Color("#2a3b40")})
		"voice":
			UI.box(ci, r, {"notch":big, "bg":UI.VOICE, "border":Color("#07050a"), "insets":[[2,2,0,UI.VOICE_HI],[-2,-2,0,Color("#120e18")]]})
		"key", "key_hover", "key_down", "key_active", "key_off":
			_key(ci, r, k)
		"push", "push_hover", "push_down", "push_off":
			_push(ci, r, k)
		"close", "close_hover":
			var o := {"bg":Color("#26363b"), "border":UI.CUE if k == "close_hover" else UI.EDGE, "insets":[[2,2,0,Color("#46616a")],[-2,-2,0,Color("#141e21")]]}
			UI.box(ci, Rect2(r.position, r.size - Vector2(0, 2)), o)
			ci.draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), UI.EDGE)
		"slot", "slot_hover", "slot_selected":
			var edge := UI.EDGE
			if k == "slot_hover": edge = Color("#557178")
			elif k == "slot_selected": edge = UI.CUE
			UI.box(ci, r, {"grad":[[0.0, Color("#081013")], [1.0, Color("#0d181c")]], "border":edge, "insets":[[2,2,0,Color("#020506")],[-2,-2,0,Color("#1d2d32")]]})
			if k == "slot_selected":
				UI.box(ci, r.grow(-2), {"border":Color(1, 0.95, 0.72, 0.22), "bw":2})
				_brackets(ci, r)
		"focus":
			var c := tint if tint.a > 0 else UI.CUE
			for piece in UI.subtract(r.grow(1), r.grow(-1)): ci.draw_rect(piece, c)
		"rule":
			var y := roundf(r.position.y + r.size.y * 0.5) - 2
			ci.draw_rect(Rect2(r.position.x, y, r.size.x, 2), Color("#0f181b"))
			ci.draw_rect(Rect2(r.position.x, y + 2, r.size.x, 2), Color("#2e444a"))
		"track":
			UI.box(ci, r, {"bg":Color("#05090b"), "border":UI.EDGE, "insets":[[2,2,0,Color("#000000")],[-2,-2,0,Color("#16242a")]]})
		"fill":
			var c := tint if tint.a > 0 else UI.PHOS_DIM
			UI.box(ci, r.grow(-2), {"bg":c, "insets":[[0,1,0,Color(1, 1, 1, 0.18)]]})
		"cells":
			var c := tint if tint.a > 0 else UI.PHOS
			var inner := r.grow(-2)
			var x := inner.position.x
			while x < inner.end.x - 1:
				var w := minf(6.0, inner.end.x - x)
				ci.draw_rect(Rect2(x, inner.position.y, w, inner.size.y), c)
				ci.draw_rect(Rect2(x, inner.position.y, w, 1), Color(0, 0, 0, 0.6))
				x += 8.0
		_:
			pass

static func _screws(ci, r: Rect2) -> void:
	var t := UI.tex("screw")
	for pos in [r.position + Vector2(6, 6), Vector2(r.end.x - 18, r.position.y + 6), Vector2(r.position.x + 6, r.end.y - 18), r.end - Vector2(18, 18)]:
		ci.draw_texture_rect(t, Rect2(pos, Vector2(12, 12)), false)

static func _scan(ci, r: Rect2) -> void:
	var p := r.grow(-2)
	var y := p.position.y + 2.0
	while y < p.end.y:
		ci.draw_rect(Rect2(p.position.x, y, p.size.x, minf(2.0, p.end.y - y)), Color(0, 0, 0, 0.13))
		y += 4.0

static func _brackets(ci, r: Rect2) -> void:
	var g := r.grow(3)
	for c in [[g.position, Vector2(1, 1)], [Vector2(g.end.x, g.position.y), Vector2(-1, 1)], [Vector2(g.position.x, g.end.y), Vector2(1, -1)], [g.end, Vector2(-1, -1)]]:
		var p: Vector2 = c[0]; var d: Vector2 = c[1]
		ci.draw_rect(Rect2(p.x if d.x > 0 else p.x - 8, p.y if d.y > 0 else p.y - 2, 8, 2), UI.CUE)
		ci.draw_rect(Rect2(p.x if d.x > 0 else p.x - 2, p.y if d.y > 0 else p.y - 8, 2, 8), UI.CUE)

## Bezel keycap: raised cap with a 3px shadow; pressed sinks into it.
static func _key(ci, r: Rect2, k: String) -> void:
	var drop := 3.0
	var top := 0.0
	var grad := [[0.0, Color("#34494f")], [1.0, Color("#22333a")]]
	var ins := [[2,2,0,Color("#557178")],[-2,-2,0,Color("#141e22")]]
	var border := UI.EDGE
	match k:
		"key_hover":
			grad = [[0.0, Color("#3f575e")], [1.0, Color("#2a3e45")]]; ins = [[2,2,0,Color("#6c8d95")],[-2,-2,0,Color("#16232a")]]
		"key_down":
			grad = [[0.0, Color("#1c2a2f")], [1.0, Color("#253940")]]; ins = [[2,2,0,Color("#0f171a")],[-2,-2,0,Color("#3c545b")]]; top = 2.0; drop = 1.0
		"key_active":
			grad = [[0.0, Color("#1c2a2f")], [1.0, Color("#253940")]]; ins = [[2,2,0,Color("#0f171a")],[-2,-2,0,Color("#3c545b")]]; top = 2.0; drop = 1.0
		"key_off":
			grad = [[0.0, UI.filt(Color("#34494f"), 0.2, 0.6)], [1.0, UI.filt(Color("#22333a"), 0.2, 0.6)]]
			ins = [[2,2,0,UI.filt(Color("#557178"), 0.2, 0.6)],[-2,-2,0,Color("#101619")]]
	var cap := Rect2(r.position.x, r.position.y + top, r.size.x, r.size.y - 3.0)
	ci.draw_rect(Rect2(r.position.x + 2, cap.end.y, r.size.x - 4, drop), UI.EDGE)
	UI.box(ci, cap, {"notch":cap.size.x >= 16 and cap.size.y >= 16, "grad":grad, "border":border, "insets":ins})
	if k == "key_active":
		ci.draw_rect(Rect2(cap.position.x + 6, cap.end.y - 6, cap.size.x - 12, 2), UI.WARN)

## Paper push-cap (primary actions), like the design's push buttons.
static func _push(ci, r: Rect2, k: String) -> void:
	var drop := 4.0
	var top := 0.0
	var grad := [[0.0, Color("#cfc7a8")], [1.0, Color("#a9a083")]]
	var ins := [[2,2,0,Color("#f0ead2")],[-2,-2,0,Color("#7e7660")]]
	match k:
		"push_hover":
			grad = [[0.0, Color("#ddd5b6")], [1.0, Color("#b7ae90")]]
		"push_down":
			top = 3.0; drop = 1.0
		"push_off":
			grad = [[0.0, UI.filt(Color("#cfc7a8"), 0.2, 0.6)], [1.0, UI.filt(Color("#a9a083"), 0.2, 0.6)]]
			ins = [[2,2,0,UI.filt(Color("#f0ead2"), 0.2, 0.6)],[-2,-2,0,UI.filt(Color("#7e7660"), 0.2, 0.6)]]
	var cap := Rect2(r.position.x, r.position.y + top, r.size.x, r.size.y - 4.0)
	ci.draw_rect(Rect2(r.position.x + 2, cap.end.y, r.size.x - 4, drop), UI.EDGE)
	UI.box(ci, cap, {"notch":cap.size.x >= 16 and cap.size.y >= 16, "grad":grad, "border":UI.EDGE, "insets":ins})
