extends Control
## Fixed 1280x720 "game frame" from the design, drawn immediate-mode so every
## module, lamp and label lands on the same pixel as the proposal. Screens
## override paint(), on_click(), on_drag() and on_key(). Interactive regions are
## registered with hit() while painting; the previous frame's regions are used
## for mouse hit-testing, hover, press, keyboard focus and cursor shapes.
const UI := preload("res://scripts/ui/eito/eito_ui.gd")

signal close_requested

const W := 1280.0
const H := 720.0

var now := 0.0
var hover := ""
var press := ""
var focus := ""
var kb := false
var dim := false
var _hits: Array = []
var _build: Array = []
var _nudge := {}
var _pop := {}
var _tweens := {}
var _focus_rect := Rect2()
var _drag_id := ""

func _ready() -> void:
	size = Vector2(W, H)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	clip_contents = true
	UI.tex("noise")

func _process(delta: float) -> void:
	now += delta
	tick(delta)
	queue_redraw()

func tick(_delta: float) -> void:
	pass

func _draw() -> void:
	_build = []
	_focus_rect = Rect2()
	dim = false
	paint()
	if kb and _focus_rect.has_area():
		var r := _focus_rect.grow(3)
		for piece in UI.subtract(r.grow(2), r): draw_rect(piece, UI.CUE)
	_hits = _build

func paint() -> void:
	pass

# ------------------------------------------------------------ hit regions
## opts: cursor (CursorShape), focus (bool), drag (bool), locked (bool), fixed (bool)
func hit(id: String, r: Rect2, opts := {}) -> void:
	var cursor: int = opts.get("cursor", Control.CURSOR_POINTING_HAND)
	if opts.get("locked", false): cursor = Control.CURSOR_FORBIDDEN
	elif opts.get("fixed", false): cursor = Control.CURSOR_ARROW
	_build.append({"id":id, "rect":r, "cursor":cursor, "focus":opts.get("focus", true), "drag":opts.get("drag", false)})
	if id == focus: _focus_rect = opts.get("focus_rect", r)

func _hit_at(p: Vector2) -> Dictionary:
	for i in range(_hits.size() - 1, -1, -1):
		if (_hits[i].rect as Rect2).has_point(p): return _hits[i]
	return {}

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _hit_at(event.position)
		hover = h.get("id", "")
		mouse_default_cursor_shape = h.get("cursor", Control.CURSOR_ARROW)
		if not _drag_id.is_empty(): on_drag(_drag_id, event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var h := _hit_at(event.position)
			if event.pressed:
				kb = false
				press = h.get("id", "")
				if not press.is_empty() and h.get("focus", true): focus = press
				if h.get("drag", false) and on_press(press, event.position):
					_drag_id = press; on_drag(press, event.position)
			else:
				var was := press; press = ""
				if not _drag_id.is_empty():
					on_drag_end(_drag_id); _drag_id = ""
				elif not was.is_empty() and h.get("id", "") == was:
					on_click(was, event)
			accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var h := _hit_at(event.position)
			if not h.is_empty() and on_wheel(h.id, 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1): accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hover = ""

## Keyboard entry point (forwarded by the owning layer). Returns true if used.
func key(event: InputEventKey) -> bool:
	if not event.pressed: return false
	if event.keycode == KEY_ESCAPE:
		close_requested.emit(); return true
	if event.keycode == KEY_TAB:
		kb = true; _cycle_focus(-1 if event.shift_pressed else 1); return true
	if not focus.is_empty() and on_key(focus, event):
		kb = true; return true
	if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and not focus.is_empty():
		kb = true
		for h in _hits:
			if h.id == focus: on_click(focus, null); return true
	return false

func _cycle_focus(step: int) -> void:
	var ids := []
	for h in _hits:
		if h.focus and not ids.has(h.id): ids.append(h.id)
	if ids.is_empty(): return
	var i := ids.find(focus)
	focus = ids[(i + step + ids.size()) % ids.size()] if i >= 0 else ids[0 if step > 0 else ids.size() - 1]

func on_click(_id: String, _event) -> void: pass
## Called on mouse-down over a drag region; return true to start dragging.
func on_press(_id: String, _pos: Vector2) -> bool: return true
func on_drag(_id: String, _pos: Vector2) -> void: pass
func on_drag_end(_id: String) -> void: pass
func on_wheel(_id: String, _dir: int) -> bool: return false
func on_key(_id: String, _event: InputEventKey) -> bool: return false

# ------------------------------------------------------------ timing helpers
func nudge(id: String) -> void: _nudge[id] = now
func nudge_dx(id: String) -> float:
	var t := now - float(_nudge.get(id, -10.0))
	if t < 0.1: return 0.0
	if t < 0.2: return -3.0
	if t < 0.3: return 3.0
	return 0.0

func pop(id: String) -> void: _pop[id] = now
func pop_t(id: String) -> float:
	return now - float(_pop.get(id, -10.0))

func blink(period := 1.0) -> float:
	return 1.0 if fmod(now, period) < period * 0.5 else 0.45

## Stepped transition (CSS "transition: X .2s steps(3)").
func tween(key: String, target: float, duration: float, steps := 3) -> float:
	var t: Dictionary = _tweens.get(key, {})
	if t.is_empty():
		_tweens[key] = {"from":target, "to":target, "t0":-10.0}; return target
	if not is_equal_approx(t.to, target):
		var cur := tween(key, t.to, duration, steps)
		_tweens[key] = {"from":cur, "to":target, "t0":now}; t = _tweens[key]
	var p := clampf((now - float(t.t0)) / duration, 0.0, 1.0)
	if p >= 1.0: return t.to
	p = floorf(p * steps) / steps
	return lerpf(t.from, t.to, p)

# ------------------------------------------------------------ drawing helpers
func C(c: Color) -> Color:
	return UI.filt(c, 0.2, 0.6) if dim else c

func R(r: Rect2, c: Color) -> void:
	draw_rect(r, C(c))

func B(r: Rect2, o: Dictionary) -> void:
	if dim:
		var f := {}
		for k in o:
			var v = o[k]
			if v is Color: f[k] = C(v)
			elif k in ["grad", "hgrad"]:
				var s := []
				for st in v: s.append([st[0], C(st[1])])
				f[k] = s
			elif k in ["insets", "outer"]:
				var s := []
				for st in v: s.append([st[0], st[1], st[2], C(st[3])])
				f[k] = s
			else: f[k] = v
		o = f
	UI.box(self, r, o)

func T(f: Font, sz: int, s: String, x: float, top: float, c: Color, lh := -1.0, align := 0, width := 0.0) -> float:
	return UI.text(self, f, sz, s, x, top, C(c), lh, align, width)

func P(f: Font, sz: int, s: String, x: float, top: float, width: float, lh: float, c: Color, balanced := false, align := 0) -> int:
	return UI.paragraph(self, f, sz, s, x, top, width, lh, C(c), balanced, align)

func F(kind: String, w := 400, sp := 0.0) -> Font:
	return UI.font(kind, w, sp)

func tw(f: Font, sz: int, s: String) -> float:
	return UI.tw(f, sz, s)

func IMG(name: String, r: Rect2, modulate := Color.WHITE) -> void:
	var key := name + "_dim" if dim and UI.has_tex(name + "_dim") else name
	draw_texture_rect(UI.tex(key), r, false, modulate)

## Status lamp: shape + colour + glow, blinking for warn/live like the CSS.
func lamp(p: Vector2, s: String) -> void:
	if s == "lock":
		IMG("lockA", Rect2(p + Vector2(2, 1), Vector2(14, 16))); return
	var key := s if s in ["ok", "warn", "fault", "live"] else "off"
	var a := 1.0
	if key == "warn": a = blink(1.0)
	elif key == "live": a = blink(0.6)
	if key != "off":
		var g := "g_" + key + ("_dim" if dim else "")
		draw_texture_rect(UI.tex(g), Rect2(p - Vector2(6, 6), Vector2(30, 30)), false, Color(1, 1, 1, a))
	IMG("l_" + key, Rect2(p, Vector2(18, 18)), Color(1, 1, 1, a))

func screws(r: Rect2) -> void:
	for pos in [r.position + Vector2(6, 6), Vector2(r.end.x - 18, r.position.y + 6), Vector2(r.position.x + 6, r.end.y - 18), r.end - Vector2(18, 18)]:
		draw_texture_rect(UI.tex("screw"), Rect2(pos, Vector2(12, 12)), false)

## Metal module with header strip and stamped title. Returns the content top.
func module(r: Rect2, title: String) -> void:
	UI.metal_module(self, r)
	# .mod-h: margin 0 -10px 8px, padding 0 22px, 2px bottom border + 2px highlight
	var hx := r.position.x + 4.0; var hw := r.size.x - 8.0
	draw_rect(Rect2(hx, r.position.y + 2 + 32, hw, 2), Color("#0f181b"))
	draw_rect(Rect2(hx, r.position.y + 2 + 34, hw, 2), Color("#2e444a"))
	if not title.is_empty():
		var f := F("label", 400, 0.96)
		T(f, 16, title, hx + 22, r.position.y + 2 + 2, Color("#0a1012"), 32)
		T(f, 16, title, hx + 22, r.position.y + 2, UI.LABEL, 32)

## Right-aligned header chip inside a module header.
func module_chip(r: Rect2, s: String, l: String) -> void:
	if s.is_empty(): return
	var f := F("body")
	var w := tw(f, 16, s) + (24 if not l.is_empty() else 0)
	chip(r.end.x - 4 - 22 - w, r.position.y + 2 + 6, s, l, 16, Color("#ddd8c8"), 20.8)

func chip(x: float, top: float, s: String, l: String, sz := 16, color := Color("#ddd8c8"), h := 20.0) -> float:
	var f := F("body")
	var lh := h
	if not l.is_empty():
		lamp(Vector2(x, top + (lh - 18) * 0.5), l)
		x += 24
	return T(f, sz, s, x, top, color, lh) + (24 if not l.is_empty() else 0)

func kbd(x: float, top: float, s: String, min_w := 28.0, hgt := 24.0, sz := 14) -> float:
	var f := F("label")
	var w := maxf(min_w, tw(f, sz, s) + 12 + 4)
	var r := Rect2(x, top, w, hgt)
	B(r, {"bg":Color("#26363b"), "border":UI.EDGE, "insets":[[2,2,0,Color("#46616a")],[-2,-2,0,Color("#141e21")]], "outer":[[0,2,0,UI.EDGE]]})
	T(f, sz, s, x, top, Color("#ece6d4"), hgt, 1, w)
	return w

func hazard(r: Rect2, c1: Color, c2: Color, period := 8.0) -> void:
	# repeating-linear-gradient(-45deg, c1 0 4px, c2 4px 8px)
	var k := 0.70710678
	for y in range(int(r.size.y)):
		var runs := []
		var x := 0
		while x < int(r.size.x):
			var t := fposmod(-(x + 0.5 + y + 0.5) * k, period)
			var col := c1 if t < period * 0.5 else c2
			var x0 := x
			while x < int(r.size.x):
				var tt := fposmod(-(x + 0.5 + y + 0.5) * k, period)
				if (tt < period * 0.5) != (t < period * 0.5): break
				x += 1
			if col.a > 0: draw_rect(Rect2(r.position.x + x0, r.position.y + y, x - x0, 1), C(col))

## Corner brackets around the next action (".cue::after").
func cue(r: Rect2) -> void:
	var inset := -8.0 if fmod(now, 1.1) < 0.55 else -4.0
	var g := r.grow(-inset)
	var corners := [[g.position, Vector2(1, 1)], [Vector2(g.end.x, g.position.y), Vector2(-1, 1)], [Vector2(g.position.x, g.end.y), Vector2(1, -1)], [g.end, Vector2(-1, -1)]]
	for pass_i in range(2):
		for c in corners:
			var p: Vector2 = c[0]; var d: Vector2 = c[1]
			var h := Rect2(p.x if d.x > 0 else p.x - 12, p.y if d.y > 0 else p.y - 3, 12, 3)
			var v := Rect2(p.x if d.x > 0 else p.x - 3, p.y if d.y > 0 else p.y - 12, 3, 12)
			if pass_i == 0:
				draw_rect(h.grow(2), Color(1, 0.95, 0.72, 0.18)); draw_rect(v.grow(2), Color(1, 0.95, 0.72, 0.18))
			else:
				draw_rect(h, UI.CUE); draw_rect(v, UI.CUE)

## Padlock pinned to the top-right corner of a locked control (".locked::before").
func lock_corner(r: Rect2) -> void:
	lock_at(Vector2(r.end.x + 6 - 14, r.position.y - 6))

func lock_at(p: Vector2) -> void:
	IMG("lock", Rect2(p, Vector2(14, 16)))

func locktag(r: Rect2, s: String, sz := 16, pad_right := 10.0) -> void:
	B(r, {"bg":Color("#1d180e"), "border":Color("#050505"), "insets":[[0,0,2,Color("#5e4515")]]})
	hazard(Rect2(r.position.x + 2, r.position.y + 2, 8, r.size.y - 4), UI.WARN, Color("#1d180e"))
	var f := F("body")
	var tx := r.position.x + 2 + 8 + 8
	var lines := UI.wrap_text(f, sz, s, r.end.x - 2 - pad_right - tx)
	var lh := sz * 1.15
	var top := r.position.y + (r.size.y - lh * lines.size()) * 0.5
	for i in range(lines.size()): T(f, sz, lines[i], tx, top + i * lh, Color("#f6e7c1"), lh)

## Push button. state: "", "working", "done". Returns the button box.
func push(id: String, x: float, y: float, w: float, cap: String, label: String, state := "", locked := false, fixed := false, cap_w := 84.0, cap_h := 50.0, cap_sz := 16, label_sz := 15, prog := -1, prog_cells := 8) -> Rect2:
	var dx := nudge_dx(id)
	x += dx
	var f_lbl := F("body")
	var lines := UI.wrap_text(f_lbl, label_sz, label, 110.0) if not label.is_empty() else PackedStringArray()
	var lh := label_sz * 1.15
	var bh := cap_h + (8.0 + lines.size() * lh if lines.size() > 0 else 0.0) + (8.0 + 8.0 if prog >= 0 else 0.0)
	var box := Rect2(x, y, w, bh)
	dim = locked
	var pressed := press == id and hover == id and not locked and not fixed
	var ty := 0.0; var drop := 6.0
	var grad := [[0.0, Color("#cfc7a8")], [1.0, Color("#a9a083")]]
	var ins := [[2,2,0,Color("#f0ead2")],[-2,-2,0,Color("#7e7660")]]
	if state == "working":
		grad = [[0.0, Color("#8adcf2")], [1.0, Color("#4aa4c2")]]; ins = [[2,2,0,Color("#d8f6ff")],[-2,-2,0,Color("#2d7790")]]
	elif state == "done":
		grad = [[0.0, Color("#7fd685")], [1.0, Color("#4c9f52")]]; ins = [[2,2,0,Color("#c9f5c9")],[-2,-2,0,Color("#2c6a31")]]
		ty = 3; drop = 3
	if pressed: ty = 4; drop = 2
	var cap_r := Rect2(x + (w - cap_w) * 0.5, y + ty, cap_w, cap_h)
	B(cap_r, {"grad":grad, "border":UI.EDGE, "insets":ins, "outer":[[0, drop, 0, UI.EDGE]]})
	T(F("label", 400, 0.64), cap_sz, cap, cap_r.position.x, cap_r.position.y, Color("#1f2326"), cap_h, 1, cap_w)
	var cy := y + cap_h + 8
	for i in range(lines.size()):
		T(f_lbl, label_sz, lines[i], x, cy + i * lh, Color("#b4c3c1"), lh, 1, w)
	if prog >= 0:
		var pw := prog_cells * 8 + (prog_cells - 1) * 2
		var px := x + (w - pw) * 0.5
		for i in range(prog_cells):
			var cr := Rect2(px + i * 10, cy, 8, 8)
			R(cr, UI.LIVE if i < prog else Color("#0c1518"))
			R(Rect2(cr.position, Vector2(8, 1)), Color.BLACK); R(Rect2(cr.position, Vector2(1, 8)), Color.BLACK)
	if locked: lock_at(Vector2(box.end.x + 6 - 14, box.position.y - 6))
	dim = false
	hit(id, box, {"locked":locked, "fixed":fixed})
	return box

func tagbtn(id: String, x: float, y: float, s: String, active := false) -> float:
	var f := F("label", 400, 0.7)
	var w := tw(f, 14, s) + 20 + 4
	var r := Rect2(x, y, w, 28)
	var down := press == id and hover == id
	var ins := [[2,2,0,Color("#e9e2c9")],[-2,-2,0,Color("#a39a7b")]]
	if down: ins = [[-2,-2,0,Color("#e9e2c9")],[2,2,0,Color("#a39a7b")]]
	B(r, {"bg":UI.INK if active else Color("#cbc2a4"), "border":Color("#6f6750"), "insets":ins})
	T(f, 14, s, x, y, UI.PAPER if active else UI.INK, 28, 1, w)
	hit(id, r)
	return w

# ------------------------------------------------------------ HUD
## Objective chip, centred nameplate and the Esc hint, laid out with
## justify-content: space-between exactly like ".hud".
func hud(objective: String, nameplate: String, esc_label: String, obj_flash_t := -10.0, obj_key := "Objective") -> void:
	var fk := F("label", 400, 0.84); var fv := F("body")
	var kw := tw(fk, 14, obj_key); var vw := tw(fv, 19, objective)
	var ow := 2 + 12 + kw + 10 + vw + 16 + 2
	var fn := F("label", 400, 1.28)
	var nw := 0.0 if nameplate.is_empty() else tw(fn, 16, nameplate) + 36 + 4
	var fe := F("body")
	var ekw := maxf(28.0, tw(F("label"), 14, "Esc") + 16)
	var ew := ekw + 8 + tw(fe, 17, esc_label)
	var gap := (1240.0 - ow - nw - ew) * 0.5
	# objective chip
	var orr := Rect2(20, 11, ow, 34)
	var flash := false
	var ft := now - obj_flash_t
	if ft >= 0 and ft < 3.0: flash = fmod(ft, 0.5) >= 0.25
	B(orr, {"notch":true, "bg":Color("#2a2610") if flash else Color("#0a1114"), "border":UI.CUE if flash else Color("#2a3b40")})
	T(fk, 14, obj_key, 34, 13, UI.WARN, 30)
	T(fv, 19, objective, 34 + kw + 10, 13, Color("#f2ecd9"), 30)
	if not nameplate.is_empty():
		var nr := Rect2(20 + ow + gap, 12, nw, 33)
		B(nr, {"notch":true, "grad":[[0.0, Color("#c4cdc8")], [1.0, Color("#9aa9a5")]], "border":UI.EDGE, "insets":[[2,2,0,Color("#e4ece8")],[-2,-2,0,Color("#6f807c")]]})
		T(fn, 16, nameplate, nr.position.x + 2 + 18, nr.position.y + 2 + 5, Color("#1b2326"), nr.size.y - 4 - 9)
	var ex := 1260.0 - ew
	kbd(ex, 16, "Esc")
	T(fe, 17, esc_label, ex + ekw + 8, 16, Color("#a9b8b6"), 24)
	hit("esc", Rect2(ex, 14, ew, 28), {"focus":false})

# ------------------------------------------------------------ screen background
func screen_bg() -> void:
	draw_rect(Rect2(0, 0, W, H), UI.BULK)
	var y := H
	while y > 0.0:
		draw_rect(Rect2(0, maxf(0.0, y - 46), W, minf(46.0, y)), Color("#0e171b"))
		if y - 46 > 0: draw_rect(Rect2(0, maxf(0.0, y - 48), W, minf(2.0, y - 46)), Color("#0a1215"))
		if y - 48 > 0: draw_rect(Rect2(0, maxf(0.0, y - 50), W, minf(2.0, y - 48)), Color(21/255.0, 34/255.0, 39/255.0, 0x28/255.0))
		y -= 50.0
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.2))

# ------------------------------------------------------------ procedure card (PAPER)
## steps: [{t, do, why}], st: current index, fb: {s, t}, done: {do, why}, over: optional override.
func procedure(id_prefix: String, r: Rect2, steps: Array, st: int, fb: Dictionary, done: Dictionary, over := {}) -> void:
	UI.paper(self, r)
	var x := r.position.x + 2 + 16; var top := r.position.y + 2 + 12
	var inner_w := r.size.x - 4 - 32
	var fn := F("label", 400, 0.75)
	var n := steps.size()
	var label := "STEP %d OF %d" % [st + 1, n] if st < n else "COMPLETE"
	var lw := T(fn, 15, label, x, top, Color("#6a5a2a"), 26)
	var px := x + lw + 12
	for i in range(n):
		var pr := Rect2(px + i * 20, top + 8, 16, 10)
		if i < st:
			draw_rect(pr, Color("#3e6e47")); draw_rect(Rect2(pr.position.x, pr.end.y - 2, 16, 2), Color("#24442b")); draw_rect(Rect2(pr.end.x - 2, pr.position.y, 2, 10), Color("#24442b"))
		elif i == st:
			var c := UI.INK; c.a = blink(1.0)
			draw_rect(pr, c)
		else:
			draw_rect(pr, Color("#c3b997")); draw_rect(Rect2(pr.position, Vector2(16, 2)), Color("#a99f7f")); draw_rect(Rect2(pr.position, Vector2(2, 10)), Color("#a99f7f"))
	# Manual / Log tabs, right aligned
	var f14 := F("label", 400, 0.7)
	var log_w := tw(f14, 14, "Log") + 24; var man_w := tw(f14, 14, "Manual") + 24
	var tx := x + inner_w - log_w - 6 - man_w
	tagbtn(id_prefix + ":manual", tx, top - 1, "Manual")
	tagbtn(id_prefix + ":log", tx + man_w + 6, top - 1, "Log")
	var s: Dictionary = over if not over.is_empty() else (steps[st] if st < n else done)
	var fdo := F("body", 600)
	var y := top + 26 + 5 + 2
	var lines := P(fdo, 25, str(s.get("do", "")), x, y, inner_w, 29.5, UI.INK, true)
	y += lines * 29.5 + 5
	if not str(s.get("why", "")).is_empty():
		var wl := P(F("body"), 18, str(s.why), x, y, inner_w, 22.5, UI.INK_2)
		y += wl * 22.5 + 5
	# feedback strip at the bottom (margin-top:auto); overflowing content pushes it down
	var fr := Rect2(x, maxf(r.end.y - 2 - 14 - 40, y), inner_w, 40)
	var bg := Color("#172023")
	var pt := pop_t(id_prefix + ":fb")
	if pt < 0.175: bg = Color("#2e3a2a")
	elif pt < 0.35: bg = Color("#2e3a2a").lerp(Color("#172023"), 0.5)
	B(fr, {"bg":bg, "border":Color("#0b1012"), "insets":[[2,2,0,Color("#2c3b40")]]})
	lamp(Vector2(fr.position.x + 2 + 12, fr.position.y + 11), str(fb.get("s", "")))
	var ff := F("body")
	var fl := UI.wrap_text(ff, 18, str(fb.get("t", "")), fr.size.x - 4 - 24 - 28 - 10)
	var flh := 21.6
	var ftop := fr.position.y + (40 - flh * fl.size()) * 0.5
	for i in range(fl.size()): T(ff, 18, fl[i], fr.position.x + 2 + 12 + 18 + 10, ftop + i * flh, Color("#ece6d4"), flh)

# ------------------------------------------------------------ drawer (manual/log on PAPER)
func drawer(id_prefix: String, r: Rect2, mode: String, steps: Array, st: int, log_lines: Array, notes: String, open_t: float) -> void:
	var t := clampf((now - open_t) / 0.3, 0, 1)
	var p := floorf(t * 3) / 3.0
	var off := Vector2(0, 40 * (1.0 - p))
	if p < 1.0: draw_set_transform(off)
	UI.paper(self, r)
	var x := r.position.x + 2 + 18; var top := r.position.y + 2 + 14
	var w := r.size.x - 4 - 36
	var fh := F("label", 400, 0.9)
	var hw := T(fh, 18, "PROCEDURE" if mode == "manual" else "PANEL LOG", x, top, UI.INK, 28)
	var bx := x + hw + 6
	bx += tagbtn(id_prefix + ":dm_manual", bx, top, "Manual", mode == "manual") + 6
	tagbtn(id_prefix + ":dm_log", bx, top, "Log", mode == "log")
	var cw := tw(F("label", 400, 0.7), 14, "Close") + 24
	tagbtn(id_prefix + ":dm_close", x + w - cw, top, "Close")
	var y := top + 28 + 10
	var f := F("body"); var fb := F("body", 700)
	var lh := 19 * 1.35
	if mode == "manual":
		for i in range(steps.size()):
			var item: String = steps[i].t
			var done := i < st; var cur := i == st
			var col := Color("#4f6b51") if done else UI.INK
			var font := fb if cur else f
			var num := "%d." % (i + 1)
			T(font, 19, num, x + 28 - 6 - tw(font, 19, num), y, col, lh)
			var lines := UI.wrap_text(font, 19, item, w - 28)
			for j in range(lines.size()):
				var lw := T(font, 19, lines[j], x + 28, y + j * lh, col, lh)
				if done: R(Rect2(x + 28, roundf(UI.baseline(font, 19, y + j * lh, lh) - 6), lw, 2), col)
			y += lines.size() * lh + 4
		y += 10 - 4
		draw_rect(Rect2(x, y, w, 2), Color(0, 0, 0, 0))
		var dx := 0.0
		while dx < w:
			R(Rect2(x + dx, y, minf(6.0, w - dx), 2), Color("#a39a7b")); dx += 12.0
		y += 2 + 8
		_rich_note(notes, x, y, w)
	else:
		if log_lines.is_empty():
			P(f, 18, "Nothing logged yet. Actions you take on this panel are recorded here.", x, y, w, 18 * 1.3, UI.INK_2)
		else:
			for item in log_lines:
				R(Rect2(x + 14, y + lh * 0.5 - 3, 6, 6), UI.INK)
				var n := P(f, 19, str(item), x + 28, y, w - 28, lh, UI.INK)
				y += n * lh + 4
	if p < 1.0: draw_set_transform(Vector2.ZERO)

func _rich_note(notes: String, x: float, y: float, w: float) -> void:
	# "<b>Readings:</b> rest" -> bold lead-in then wrapped text, 17px ink-2.
	var lead := ""; var rest := notes
	if notes.begins_with("<b>"):
		var e := notes.find("</b>")
		lead = notes.substr(3, e - 3); rest = notes.substr(e + 4)
	var f := F("body"); var fb := F("body", 700)
	var lh := 17 * 1.3
	var words := rest.strip_edges().split(" ", false)
	var cx := x; var cy := y
	if not lead.is_empty():
		cx += T(fb, 17, lead, cx, cy, UI.INK_2, lh) + tw(f, 17, " ")
	for word in words:
		var ww := tw(f, 17, word)
		if cx + ww > x + w + 0.01 and cx > x:
			cx = x; cy += lh
		T(f, 17, word, cx, cy, UI.INK_2, lh)
		cx += ww + tw(f, 17, " ")

# ------------------------------------------------------------ comms card (VOICE)
func comms_card(r: Rect2, who: String, name: String, role: String, message: String, next_line: String, open_t: float) -> void:
	var t := clampf((now - open_t) / 0.45, 0, 1)
	var p := floorf(t * 4) / 4.0
	var a := p
	if p < 1.0: draw_set_transform(Vector2(0, 40 * (1.0 - p)))
	var mod := Color(1, 1, 1, a)
	UI.box(self, r, {"notch":true, "bg":UI.VOICE, "border":Color("#07050a"), "insets":[[2,2,0,UI.VOICE_HI],[-2,-2,0,Color("#120e18")]]})
	var face := Rect2(r.position + Vector2(16, 16), Vector2(96, 96))
	UI.glass(self, face)
	draw_texture_rect(UI.tex("face_" + who), face.grow(-2), false, mod)
	UI.glass_overlay(self, face)
	var x := face.end.x + 14; var top := r.position.y + 16
	var cw := r.end.x - 16 - x
	var fb := F("body", 700)
	var base_y := roundf(UI.baseline(fb, 22, top, 28.6))
	draw_string(fb, Vector2(x, base_y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UI.VOICE_INK)
	var nw := tw(fb, 22, name)
	var fl := F("label", 400, 0.7)
	UI.run(self, fl, 14, role, Vector2(roundf(x + nw + 10), base_y), Color("#b9a8cf"))
	wave(Vector2(r.end.x - 16 - 23, base_y - 14))
	var y := top + 28.6 + 6
	P(F("body"), 20, message, x, y, cw, 26, UI.VOICE_INK)
	# cm-next sits at the bottom of the column (margin-top:auto)
	var ny := r.end.y - 16 - 30.8
	draw_rect(Rect2(x, ny, cw, 2), UI.VOICE_HI)
	lamp(Vector2(x, roundf(ny + 2 + 8 + 1.4)), "live")
	T(F("body"), 16, next_line, x + 26, ny + 10, Color("#d8cfe6"), 20.8)
	if p < 1.0: draw_set_transform(Vector2.ZERO)

## Segmented cells (".cells", ".wcells", ".fcells"): flex:1 cells, 2px gaps,
## inset 1px black top/left on every cell. colors: one Color per cell.
func cell_row(r: Rect2, colors: Array, gap := 2.0) -> void:
	var n := colors.size()
	var cw := (r.size.x - gap * (n - 1)) / n
	for i in range(n):
		var x0 := roundf(r.position.x + i * (cw + gap)); var x1 := roundf(r.position.x + i * (cw + gap) + cw)
		var cr := Rect2(x0, r.position.y, x1 - x0, r.size.y)
		R(cr, colors[i])
		R(Rect2(cr.position, Vector2(cr.size.x, 1)), Color.BLACK); R(Rect2(cr.position, Vector2(1, cr.size.y)), Color.BLACK)

func cells_on(n: int, on: int, color: Color, off := Color("#0b1714")) -> Array:
	var out := []
	for i in range(n): out.append(color if i < on else off)
	return out

## ".ribbon": NEW OBJECTIVE strip. anchor is the centre-bottom when bottom_anchor.
func ribbon(anchor: Vector2, key: String, value: String, t0: float, bottom_anchor := false) -> void:
	var fk := F("label", 400, 0.84); var fv := F("body")
	var w := 2 + 22 + tw(fk, 14, key) + 12 + tw(fv, 21, value) + 22 + 2
	var h := 2 + 10 + 27.3 + 10 + 2
	var r := Rect2(anchor.x - w * 0.5, anchor.y - h if bottom_anchor else anchor.y, w, h)
	var p := clampf((now - t0) / 0.4, 0, 1)
	var k := floorf(p * 4) / 4.0 if p < 1.0 else 1.0
	r.position.y += 40 * (1.0 - k)
	var a := k
	UI.box(self, r, {"notch":true, "bg":Color("#0a1114", a), "border":Color(UI.CUE, a)})
	var x := r.position.x + 2 + 22
	x += T(fk, 14, key, x, r.position.y + 2 + 10, Color(UI.WARN, a), 27.3) + 12
	T(fv, 21, value, x, r.position.y + 2 + 10, Color("#f2ecd9", a), 27.3)

# ------------------------------------------------------------ stroked lines (SVG port)
## Solid stroke between two points. cap: "butt" | "square".
func seg(a: Vector2, b: Vector2, w: float, c: Color, cap := "butt") -> void:
	var d := b - a
	var len := d.length()
	if len <= 0.0: return
	var u := d / len
	if cap == "square":
		a -= u * w * 0.5; b += u * w * 0.5
	if is_zero_approx(u.y) or is_zero_approx(u.x):
		var r := Rect2(a, Vector2.ZERO).expand(b)
		if is_zero_approx(u.y): r = r.grow_individual(0, w * 0.5, 0, w * 0.5)
		else: r = r.grow_individual(w * 0.5, 0, w * 0.5, 0)
		draw_rect(r, C(c))
	else:
		draw_line(a, b, C(c), w)

## Dashed polyline with SVG semantics (dasharray + dashoffset continuity).
func dashed(pts: PackedVector2Array, w: float, dashes: Array, offset: float, c: Color, cap := "butt", closed := false) -> void:
	if dashes.is_empty():
		for i in range(pts.size() - 1): seg(pts[i], pts[i+1], w, c, cap)
		if closed: seg(pts[-1], pts[0], w, c, cap)
		return
	var pat: Array = dashes.duplicate()
	if pat.size() % 2 == 1: pat.append_array(dashes)
	var period := 0.0
	for v in pat: period += v
	var pp := fposmod(offset, period)
	var idx := 0
	while pp >= pat[idx]:
		pp -= pat[idx]; idx = (idx + 1) % pat.size()
	var path := pts
	if closed:
		path = pts.duplicate(); path.append(pts[0])
	for i in range(path.size() - 1):
		var a: Vector2 = path[i]; var b: Vector2 = path[i+1]
		var L := a.distance_to(b)
		var u := (b - a) / L if L > 0 else Vector2.ZERO
		var s := 0.0
		while s < L - 0.0001:
			var remain: float = pat[idx] - pp
			var e := minf(L, s + remain)
			if idx % 2 == 0: seg(a + u * s, a + u * e, w, c, cap)
			pp += e - s; s = e
			if pp >= pat[idx] - 0.0001:
				pp = 0.0; idx = (idx + 1) % pat.size()

## SVG <rect> stroke (centred on the edge), optionally dashed.
func rect_stroke(r: Rect2, w: float, c: Color, dashes := [], offset := 0.0) -> void:
	if dashes.is_empty():
		var o := r.grow(w * 0.5)
		for piece in UI.subtract(o, r.grow(-w * 0.5)): draw_rect(piece, C(c))
		return
	var p := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	dashed(p, w, dashes, offset, c, "butt", true)

## Five-bar voice meter (".cm-wave").
func wave(p: Vector2, color := Color("#b9a8cf")) -> void:
	var delays := [0.0, -0.2, -0.4, -0.1, -0.3]
	for i in range(5):
		var t := fposmod(now - delays[i], 1.0)
		var u := t / 0.5 if t < 0.5 else (1.0 - t) / 0.5
		u = floorf(u * 3) / 3.0
		var h := lerpf(3.0, 14.0, u)
		draw_rect(Rect2(p.x + i * 5, p.y + 14 - h, 3, h), color)
