extends "res://scripts/ui/eito/eito_screen.gd"
## Crew records: clipboard roster against the printed check-in log. Links draw
## themselves; the player picks the conclusion the records support.

const ROSTER := ["Maya", "Amara", "Leila", "Thura", "Elias", "Mateo"]
const LOG := [["Maya", "06:00"], ["Leila", "06:02"], ["Amara", "06:04"], ["Elias", "06:07"], ["Thura", "06:10"]]
const MISSING := "Mateo"
const CONC := [
	{"id":"all_checked_in", "t":"Everyone on the roster has checked in.", "ok":false, "why":"Not supported: Mateo has no check-in."},
	{"id":"one_missing", "t":"One expected check-in is missing.", "ok":true, "why":"Supported: 6 on the roster, 5 check-ins. Mateo is the gap."},
	{"id":"not_aboard", "t":"Someone on the roster isn’t aboard.", "ok":false, "why":"Not supported: these records show check-ins, not who is aboard."},
]

var ctl
var picked := -1
var why_override := ""
var open_t := 0.0
var ribbon_t := -10.0
var obj := "Review crew records"
var hl := ""

func setup(owner) -> void:
	ctl = owner
	open_t = 0.0
	if S().completed.has("crew"):
		picked = 1
		obj = ctl.story_objective if not str(ctl.story_objective).is_empty() else "Meet Amara"

func S() -> Object: return ctl.state
func RY(i: int) -> float: return 80.0 + i * 50.0

func on_click(id: String, _event) -> void:
	if id == "esc": close_requested.emit(); return
	if not id.begins_with("slip:"): return
	if picked >= 0 and CONC[picked].ok and why_override.is_empty(): return
	var i := int(id.get_slice(":", 1))
	why_override = ""
	picked = i
	if not CONC[i].ok: return
	# Record the comparison in the mission model; the story reacts to crew_compare.
	if not S().flags.get("crew.roster", false): ctl.act("roster", null)
	if not S().flags.get("crew.log", false): ctl.act("crew_log", null)
	if not S().completed.has("crew"): ctl.act("crew_compare", CONC[i].id)
	if S().completed.has("crew"):
		hl = MISSING
		obj = ctl.story_objective if ctl.story_mode and not str(ctl.story_objective).is_empty() and ctl.story_objective != "Review the duty roster" else "Meet Amara"
		ribbon_t = now
	else:
		why_override = _blocked_reason()

func _blocked_reason() -> String:
	var r: String = S().prerequisite("crew")
	return r if not r.is_empty() else "The comparison could not be recorded. Return to this desk when the watch is assigned."

func say(_s: String, t: String) -> void:
	if picked >= 0: why_override = t

func paint() -> void:
	screen_bg()
	hud(obj, "Watch desk · Crew records", "Step away", ribbon_t)
	var hover_name := hover.get_slice(":", 1) if hover.begins_with("row:") else ""
	var cur := hl if not hl.is_empty() else hover_name
	if not hover_name.is_empty(): cur = hover_name
	_paint_clipboard(cur)
	_paint_links(cur)
	_paint_terminal()
	_paint_strip(cur)
	_paint_conclusions()
	if ribbon_t > 0: ribbon(Vector2(640, 710), "NEW OBJECTIVE", "Meet Amara", ribbon_t, true)

func _paint_clipboard(cur: String) -> void:
	var clip := Rect2(60, 62, 500, 460)
	UI.box(self, clip, {"notch":true, "grad":[[0.0, Color("#5b4733")], [1.0, Color("#47372a")]], "border":Color.BLACK, "insets":[[2,2,0,Color("#7a6248")],[-2,-2,0,Color("#2b2018")]]})
	UI.box(self, Rect2(240, 62, 140, 30), {"grad":[[0.0, Color("#b7c0c2")], [1.0, Color("#7f8a8c")]], "border":Color.BLACK, "insets":[[2,2,0,Color("#e2e8e9")],[-2,-2,0,Color("#535c5e")]]})
	var sh := Rect2(80, 92, 460, 410)
	UI.paper(self, sh)
	T(F("label", 400, 0.8), 16, "WATCH ROSTER", 100, 110, UI.INK, 20)
	T(F("body"), 15, "Who should check in this watch", 100, 134, UI.INK_2, 19.5)
	for i in range(ROSTER.size()):
		var n: String = ROSTER[i]
		var r := Rect2(100, 94 + RY(i), 420, 44)
		if cur == n: draw_rect(Rect2(r.position, Vector2(420, 42)), Color(240/255.0, 178/255.0, 58/255.0, 0.25))
		var dx := 0.0
		while dx < 420:
			draw_rect(Rect2(r.position.x + dx, r.end.y - 2, minf(6.0, 420 - dx), 2), Color("#b3aa8b")); dx += 12.0
		var miss := n == MISSING
		draw_texture_rect(UI.tex("personM" if miss else "person"), Rect2(r.position.x, r.position.y + 11, 20, 20), false)
		T(F("body"), 21, n, r.position.x + 30, r.position.y + 7, Color("#8a4d00") if miss else UI.INK, 27.3)
		hit("row:" + n, r, {"focus":false, "cursor":Control.CURSOR_ARROW})

func _bezier(a: Vector2, c1: Vector2, c2: Vector2, b: Vector2, n := 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var t := float(i) / n; var u := 1.0 - t
		pts.append(a * u * u * u + c1 * 3 * u * u * t + c2 * 3 * u * t * t + b * t * t * t)
	return pts

func _partial(pts: PackedVector2Array, length: float) -> PackedVector2Array:
	var out := PackedVector2Array([pts[0]])
	var acc := 0.0
	for i in range(1, pts.size()):
		var d := pts[i - 1].distance_to(pts[i])
		if acc + d >= length:
			out.append(pts[i - 1].lerp(pts[i], (length - acc) / d)); return out
		acc += d; out.append(pts[i])
	return out

func _paint_links(cur: String) -> void:
	var o := Vector2(560, 62)
	for i in range(ROSTER.size()):
		var t0 := 0.25 + i * 0.26
		if now < t0: continue
		var n: String = ROSTER[i]
		var y1 := RY(i) + 52
		var li := -1
		for k in range(LOG.size()):
			if LOG[k][0] == n: li = k
		if li < 0:
			dashed(PackedVector2Array([o + Vector2(0, y1), o + Vector2(70, y1)]), 4, [6, 6], 0, UI.WARN, "square")
			draw_texture_rect(UI.tex("l_warn"), Rect2(o + Vector2(76, y1 - 9), Vector2(18, 18)), false)
			draw_string(F("body"), o + Vector2(100, y1 + 6), "No check-in", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f6e7c1"))
			continue
		var y2 := RY(li) + 100
		var pts := _bezier(o + Vector2(0, y1), o + Vector2(110, y1), o + Vector2(100, y2), o + Vector2(210, y2))
		var p := clampf((now - t0) / 0.5, 0, 1)
		var k6 := floorf(p * 6) / 6.0 if p < 1.0 else 1.0
		var vis := 400.0 * k6
		var col := UI.WARN if cur == n else Color("#3d6b45")
		var line := _partial(pts, vis) if k6 < 1.0 else pts
		if line.size() >= 2:
			for j in range(line.size() - 1): seg(line[j], line[j + 1], 4, col, "square")

func _paint_terminal() -> void:
	var r := Rect2(740, 62, 480, 84)
	UI.box(self, r, {"notch":true, "grad":[[0.0, Color("#2c3f45")], [1.0, Color("#1d2c31")]], "border":Color.BLACK, "insets":[[2,2,0,Color("#4a666d")],[-2,-2,0,Color("#111b1e")]]})
	var g := Rect2(760, 81, 176, 46)
	UI.glass(self, g)
	T(F("num"), 22, "CHECK-IN LOG", g.position.x, g.position.y, UI.PHOS, g.size.y, 1, g.size.x)
	UI.glass_overlay(self, g)
	var f := F("label", 400, 0.84)
	T(f, 14, "Crew terminals", 950, 95 + 2, Color("#0a1012"), 18)
	T(f, 14, "Crew terminals", 950, 95, UI.LABEL, 18)
	lamp(Vector2(1182, 95), "ok")

func _paint_strip(cur: String) -> void:
	var r := Rect2(770, 140, 420, 380)
	# clip-path: polygon(0 0,100% 0,100% calc(100% - 8px),95% 100%,90% calc(100% - 8px),...,0 calc(100% - 8px))
	var poly := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y - 8)])
	for j in range(1, 21):
		poly.append(Vector2(r.position.x + r.size.x * (1.0 - j * 0.05), r.end.y if j % 2 == 1 else r.end.y - 8))
	draw_colored_polygon(poly, Color("#ecebe2"))
	draw_rect(Rect2(r.position, Vector2(2, r.size.y - 8)), Color.WHITE)
	draw_rect(Rect2(r.end.x - 2, r.position.y, 2, r.size.y - 8), Color("#c9c7bb"))
	T(F("label", 400, 0.8), 16, "CHECK-INS RECEIVED", 786, 154, Color("#2a2c2c"), 20)
	T(F("body"), 15, "Printed in arrival order", 786, 178, UI.INK_2, 19.5)
	for i in range(LOG.size()):
		var n: String = LOG[i][0]
		var rr := Rect2(788, 140 + RY(i), 384, 44)
		if cur == n: draw_rect(Rect2(rr.position, Vector2(384, 42)), Color(240/255.0, 178/255.0, 58/255.0, 0.25))
		var dx := 0.0
		while dx < 384:
			draw_rect(Rect2(rr.position.x + dx, rr.end.y - 2, 2, 2), Color("#c9c7bb")); dx += 4.0
		var fn := F("num")
		T(fn, 24, n.to_upper(), rr.position.x, rr.position.y + 5, Color("#2a2c2c"), 31.2)
		T(fn, 22, LOG[i][1], rr.position.x, rr.position.y + 9, UI.INK_2, 25, 2, 384 - 31)
		draw_texture_rect(UI.tex("check"), Rect2(rr.end.x - 21, rr.position.y + 12, 21, 18), false)
		hit("row:" + n, rr, {"focus":false, "cursor":Control.CURSOR_ARROW})

func _paint_conclusions() -> void:
	T(F("label", 400, 0.96), 16, "WHAT DO THE RECORDS SHOW?", 60, 534, UI.LABEL, 20)
	var f := F("body"); var fw := F("body")
	var w := (1160.0 - 28) / 3.0
	var heights := []
	var bodies := []
	for i in range(3):
		var lines := UI.wrap_text(f, 19, CONC[i].t, w - 4 - 28)
		var why := ""
		if picked == i: why = why_override if not why_override.is_empty() else CONC[i].why
		var wl := UI.wrap_text(fw, 16, why, w - 4 - 28) if not why.is_empty() else PackedStringArray()
		var h: float = lines.size() * 23.75 + (6.0 + wl.size() * 20.8 if wl.size() > 0 else 0.0)
		bodies.append([lines, wl])
		heights.append(h)
	var row_h := 76.0
	for h in heights: row_h = maxf(row_h, h + 24 + 4)
	var correct: bool = picked >= 0 and CONC[picked].ok and why_override.is_empty()
	for i in range(3):
		var x := 60 + i * (w + 14)
		var r := Rect2(x, 564, w, row_h)
		var bg := UI.PAPER; var border := Color("#6f6750")
		var st := ""
		if picked == i:
			st = "yes" if CONC[i].ok and why_override.is_empty() else "no"
		if st == "yes": bg = Color("#d4e3c4"); border = Color("#2f6b38")
		elif hover == "slip:%d" % i and not correct: bg = Color("#e6dfc4")
		var a := 0.6 if st == "no" else 1.0
		var pr := Rect2(r.position, r.size)
		var tmp := {"bg":bg, "border":border, "insets":[[2,2,0,UI.PAPER_HI],[-2,-2,0,UI.PAPER_LO]], "outer":[[0,4,0,Color.BLACK]]}
		if a < 1.0:
			for k in ["bg", "border"]: tmp[k] = Color(tmp[k], a)
			tmp.insets = [[2,2,0,Color(UI.PAPER_HI, a)],[-2,-2,0,Color(UI.PAPER_LO, a)]]
			tmp.outer = [[0,4,0,Color(0, 0, 0, a)]]
		UI.box(self, pr, tmp)
		var lines: PackedStringArray = bodies[i][0]; var wl: PackedStringArray = bodies[i][1]
		var top: float = r.position.y + (row_h - float(heights[i])) * 0.5
		for j in range(lines.size()): T(f, 19, lines[j], x + 2 + 14, top + j * 23.75, Color(UI.INK, a), 23.75)
		if wl.size() > 0:
			var wy: float = top + lines.size() * 23.75 + 6
			var wc := Color("#2f6b38") if st == "yes" else Color("#7a4a00")
			for j in range(wl.size()): T(fw, 16, wl[j], x + 2 + 14, wy + j * 20.8, Color(wc, a), 20.8)
		hit("slip:%d" % i, r, {"fixed":correct})
	if not correct: cue(Rect2(60, 564, 1160, row_h))
