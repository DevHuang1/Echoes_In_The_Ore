extends "res://scripts/ui/eito/eito_screen.gd"
## B · Hydroponic irrigation. The panel is the plumbing itself, left to right:
## tank, pump, supply valve, manifold, beds. Ported 1:1 from the design and
## backed by ShipMissionState (diagnosis, isolation, alignment, restore, verify).

const VT := [2, 5, 3]
const BY := [120, 236, 352]
const O := Vector2(22, 58)   # padding-box origin of the wall module
const STEPS := [
	{"t":"Find where the water is lost","do":"Follow the water from tank to beds. Tap the part where the flow drops.","why":"Chemistry, pump and delivery each have their own reading."},
	{"t":"Restore the service supply","do":"Restore auxiliary power, then come back.","why":"The supply valve can’t be operated until the service supply is back."},
	{"t":"Close the supply valve","do":"Turn the red supply handle across the pipe.","why":"Stops the water so the manifold valves can be reset."},
	{"t":"Set the manifold valves","do":"Turn each valve until its pointer meets the yellow mark.","why":"Each valve feeds one growing bed."},
	{"t":"Reopen the supply","do":"Turn the red handle back along the pipe, then watch the beds.","why":"Delivery should climb to match what the pump sends."},
	{"t":"Verify delivery","do":"Press Verify.","why":"Three steady readings. Verify confirms the beds get what the pump sends."},
]
const DONE := {"do":"Irrigation is restored and verified.", "why":"Next objective: report to Amara."}
const NEED := ["Find where the water is lost first.", "Needs the service supply. Restore auxiliary power first.", "Close the supply valve first.", "Set all three valves to their marks first.", "Reopen the supply first."]
const NOTES := "<b>Readings:</b> chemistry says whether the water is right, pump output says whether it is being pushed, delivery says how much reaches the beds. If chemistry and pump are fine but delivery is low, something in between is restricting it."
const SAMPLE_SECONDS := 1.2
const HEAD_MSG := {"res":["ok", "Reservoir chemistry is in range. Not the cause."], "pump":["ok", "Pump output is normal: 19 of 20 L/min."], "beds":["warn", "The beds get only 6 L/min, so the loss happens before them. Look further upstream."]}

var ctl
var valves := [0, 3, 6]
var fb := {"s":"", "t":"Panel ready."}
var drawer_mode := ""
var drawer_t := 0.0
var flash_t := -10.0
var _last_samples := -1

func setup(owner) -> void:
	ctl = owner
	var saved: Dictionary = S().legacy_progress.get("nutrient_flow", {})
	if saved.get("nutrient_rotations") is Array and saved.nutrient_rotations.size() == 3:
		for i in range(3): valves[i] = clampi(int(saved.nutrient_rotations[i]), 0, 7)
	elif S().systems.hydro.aligned:
		valves = VT.duplicate()
	_last_samples = samples()

# ------------------------------------------------------------ model view
func S() -> Object: return ctl.state
func power() -> bool: return bool(S().bus_powered("science"))
func identified() -> bool: return bool(S().flags.get("hydro.diagnosed", false))
func isolated() -> bool: return bool(S().systems.hydro.isolated)
func restored() -> bool: return bool(S().systems.hydro.restored) and not isolated()
func verified() -> bool: return S().completed.has("hydro")
func aligned() -> bool:
	for i in range(3):
		if valves[i] != VT[i]: return false
	return true
func samples() -> int:
	if not restored(): return 0
	if verified(): return 3
	return mini(3, int(floor(float(S().verification.get("hydro", 0.0)) / SAMPLE_SECONDS)))

func step() -> int:
	if not identified(): return 0
	if not power(): return 1
	if not isolated() and not restored(): return 2
	if not restored() and not aligned(): return 3
	if not restored() or samples() < 3: return 4
	if not verified(): return 5
	return 6

func say(s: String, t: String) -> void:
	fb = {"s":s, "t":t}; pop("i:fb")

func log_lines() -> Array:
	var out := []
	if identified(): out.append("Restriction found at the manifold: 19 L/min in, 6 L/min out.")
	if isolated() or restored(): out.append("Supply valve closed.")
	if S().systems.hydro.aligned and (isolated() or restored()): out.append("Manifold aligned.")
	if restored(): out.append("Supply valve reopened.")
	if restored() and samples() >= 3: out.append("Delivery steady.")
	if verified(): out.append("Delivery verified.")
	return out

func _save_progress() -> void:
	S().legacy_progress["nutrient_flow"] = {"task":"nutrient_flow", "complete":bool(S().systems.hydro.aligned), "filter_stage":0, "filter_rotation":0, "filter_airflow":0.0, "power":[], "nutrient_rotations":valves.duplicate()}

func tick(_delta: float) -> void:
	var n := samples()
	if restored() and not verified() and n != _last_samples:
		if n < 3: say("live", "Supply open. Watching delivery: %d of 3 steady." % n)
		else: say("ok", "Delivery steady. Press Verify.")
	_last_samples = n

# ------------------------------------------------------------ locks
func sv_lock() -> String:
	if restored(): return ""
	if not power(): return NEED[1]
	if not identified(): return NEED[0]
	if isolated() and not aligned(): return NEED[3]
	if not isolated():
		var pre: String = S().prerequisite("hydro")
		if not pre.is_empty(): return pre
	return ""

func valve_lock() -> String:
	if restored(): return ""
	if not isolated():
		var st := step()
		return NEED[mini(st, 2)] if st < 2 else NEED[2]
	if not ctl.has_tool(): return "Carry the engineering multitool to turn the manifold valves. It is stored in the crew quarters wardrobe."
	return ""

func verify_lock() -> String:
	if verified() or step() == 5: return ""
	return "Wait for three steady readings first." if restored() else NEED[mini(step(), 4)]

# ------------------------------------------------------------ interaction
func on_click(id: String, _event) -> void:
	if id == "esc": close_requested.emit(); return
	if id.begins_with("head:"):
		if step() != 0: return
		var k := id.get_slice(":", 1)
		if k == "man":
			if not S().flags.get("hydro.observed", false): ctl.act("observe", null)
			ctl.act("diagnose", "restriction")
			if identified():
				say("warn", "Flow drops at the manifold: 19 in, 6 out. Close the supply valve next." if power() else "Flow drops at the manifold: 19 in, 6 out. The supply valve needs the service supply.")
		else:
			if not S().flags.get("hydro.observed", false): ctl.act("observe", null)
			say(HEAD_MSG[k][0], HEAD_MSG[k][1])
		return
	if id == "sv":
		var lr := sv_lock()
		if not lr.is_empty(): nudge("sv"); say("lock", lr); return
		if restored(): return
		var st := step()
		if st == 2:
			ctl.act("isolate", null)
			if isolated(): say("ok", "Supply valve closed. Water has stopped. Set the manifold valves.")
		elif st == 4 and isolated():
			ctl.act("restore", null)
			if restored():
				_last_samples = 0; say("live", "Supply open. Watching delivery: 0 of 3 steady.")
		return
	if id.begins_with("wheel:"):
		_rot(int(id.get_slice(":", 1)), 1); return
	if id.begins_with("vb:"):
		_rot(int(id.get_slice(":", 1)), int(id.get_slice(":", 2))); return
	match id:
		"verify":
			var lr := verify_lock()
			if not lr.is_empty(): nudge("verify"); say("lock", lr); return
			if verified(): return
			ctl.act("verify", null)
			if verified():
				say("ok", "Delivery verified. Report to Amara."); flash_t = now
		"i:manual", "i:dm_manual":
			if drawer_mode.is_empty(): drawer_t = now
			drawer_mode = "manual"
		"i:log", "i:dm_log":
			if drawer_mode.is_empty(): drawer_t = now
			drawer_mode = "log"
		"i:dm_close":
			drawer_mode = ""

func _rot(i: int, d: int) -> void:
	var lr := valve_lock()
	if not lr.is_empty(): nudge("wheel:%d" % i); say("lock", lr); return
	if restored(): return
	var was: bool = valves[i] == VT[i]
	valves[i] = (valves[i] + d + 8) % 8
	var ok: bool = valves[i] == VT[i]
	_save_progress()
	if aligned():
		ctl.act("align", null)
		say("ok", "Manifold aligned. The supply is still closed. Reopen it next.")
	elif ok: say("ok", "Valve %d is on its mark." % (i + 1))
	elif was: say("warn", "Valve %d moved off its mark." % (i + 1))

func on_key(id: String, e: InputEventKey) -> bool:
	if id.begins_with("wheel:") and e.keycode in [KEY_LEFT, KEY_RIGHT]:
		_rot(int(id.get_slice(":", 1)), -1 if e.keycode == KEY_LEFT else 1); return true
	return false

# ------------------------------------------------------------ painting
func paint() -> void:
	screen_bg()
	var st := step()
	var obj := "Report to Amara" if verified() else ("Diagnose irrigation" if st == 0 else ("Restore auxiliary power" if st == 1 else "Restore irrigation"))
	hud(obj, "Hydroponics · Irrigation line", "Step away", flash_t)
	_paint_wall(st)
	var over := {}
	if restored() and samples() < 3 and not verified(): over = {"do":"Watch the beds recover.", "why":"Verify unlocks after three steady delivery readings."}
	procedure("i", Rect2(20, 522, 620, 182), STEPS, st, fb, DONE, over)
	_paint_flow(st)
	if not drawer_mode.is_empty():
		drawer("i", Rect2(20, 56, 640, 456), drawer_mode, STEPS, st, log_lines(), NOTES, drawer_t)

func _paint_wall(st: int) -> void:
	var wall := Rect2(20, 56, 1240, 456)
	UI.metal_module(self, wall)
	_paint_pipes()
	# station heads
	var heads := [["res", 16, 240, "Reservoir", "ok"], ["pump", 290, 214, "Pump", "ok" if not isolated() else "ok"], ["", 536, 128, "Supply", ""],
		["man", 690, 316, "Manifold", _manifold_lamp()], ["beds", 1040, 186, "Growing beds", _beds_lamp()]]
	for h in heads: _head(h[0], h[1], h[2], h[3], h[4], st)
	_paint_tank()
	_paint_chem()
	_paint_pump()
	_paint_supply(st)
	for i in range(3): _valve(i, st)
	for i in range(3): _bed(i)

func _manifold_lamp() -> String:
	if not identified(): return "off"
	return "ok" if aligned() and (restored() or isolated()) else "warn"

func _beds_lamp() -> String:
	return "ok" if restored() and samples() >= 3 else "warn"

func _head(k: String, left: float, w: float, title: String, l: String, st: int) -> void:
	var r := Rect2(O.x + left, O.y + 12, w, 34)
	var hov := not k.is_empty() and st == 0 and hover == "head:" + k
	var grad := [[0.0, Color("#e2e9d6")], [1.0, Color("#b8c4aa")]] if hov else [[0.0, Color("#b9c3be")], [1.0, Color("#94a29e")]]
	UI.box(self, r, {"grad":grad, "border":UI.EDGE, "insets":[[2,2,0,Color("#e0e8e4")],[-2,-2,0,Color("#6f807c")]]})
	var f := F("label", 400, 0.9)
	var tx := r.position.x + 2 + 10
	var avail := r.size.x - 4 - 20 - (18 + 8 if not l.is_empty() else 0)
	var lines := UI.wrap_text(f, 15, title.to_upper(), avail)
	var lh := f.get_ascent(15) + f.get_descent(15)
	var top := r.position.y + 2 + (30 - lh * lines.size()) * 0.5
	for i in range(lines.size()): T(f, 15, lines[i], tx, top + i * lh, Color("#1b2326"), lh)
	if not l.is_empty():
		var lp := Vector2(r.end.x - 2 - 10 - 18, r.position.y + 8)
		# .st-head .lamp { filter:none } : no glow, keeps the blink
		var key := l if l in ["ok", "warn", "fault", "live"] else "off"
		var a := blink(1.0) if key == "warn" else (blink(0.6) if key == "live" else 1.0)
		draw_texture_rect(UI.tex("l_" + key), Rect2(lp, Vector2(18, 18)), false, Color(1, 1, 1, a))
	if not k.is_empty():
		hit("head:" + k, r, {"fixed":st != 0})
		if st == 0: cue(r)

# ---------------- pipes (crispEdges SVG)
func _pipe(pts: Array, vert: bool, cls: String) -> void:
	var p := PackedVector2Array()
	for q in pts: p.append(O + q)
	seg(p[0], p[1], 26, Color("#091013"), "square")
	seg(p[0], p[1], 20, Color("#3a5960"), "square")
	var sh := Vector2(-6, 0) if vert else Vector2(0, -6)
	seg(p[0] + sh, p[1] + sh, 2, Color("#5e8189"))
	seg(p[0], p[1], 8, Color("#0d1a20") if cls == "p-empty" else UI.WATER, "square")
	if cls in ["p-still", "p-empty"]: return
	var dash := [4, 12]; var off := 0.0
	match cls:
		"p-slow": off = -4.0 * floor(fmod(now, 1.5) / 0.375)
		"p-trickle":
			dash = [2, 30]; off = -4.0 * floor(fmod(now, 2.6) / 0.325)
		_: off = -4.0 * floor(fmod(now, 0.6) / 0.15)
	dashed(p, 4, dash, off, UI.WATER_HI)

func _paint_pipes() -> void:
	var a1 := "p-fast"; var a2 := "p-fast"; var hdr := "p-fast"; var b := "p-fast"
	if isolated():
		a1 = "p-still"; a2 = "p-empty"; hdr = "p-empty"; b = "p-empty"
	elif not restored():
		a2 = "p-slow"; hdr = "p-slow"; b = "p-trickle"
	_pipe([Vector2(200, 236), Vector2(598, 236)], false, a1)
	_pipe([Vector2(598, 236), Vector2(722, 236)], false, a2)
	_pipe([Vector2(722, 120), Vector2(722, 352)], true, hdr)
	for y in BY: _pipe([Vector2(722, y), Vector2(1050, y)], false, b)
	for fl in [[270, 224], [520, 224], [680, 224], [960, 108], [960, 224], [960, 340]]:
		var r := Rect2(O + Vector2(fl[0], fl[1]), Vector2(8, 24))
		draw_rect(r, Color("#4f7078"))
		rect_stroke(r, 2, Color("#091013"))

# ---------------- tank + chemistry
func _paint_tank() -> void:
	var r := Rect2(O + Vector2(52, 62), Vector2(150, 186))
	UI.box(self, r, {"bg":Color("#071216"), "border":Color.BLACK, "insets":[[0,0,4,Color("#2f4950")],[6,0,4,Color("#1d2f34")]]})
	var pad := r.grow(-2)
	var wh := roundf(pad.size.y * 0.72)
	var wr := Rect2(pad.position.x + 4, pad.end.y - 4 - wh, pad.size.x - 8, wh)
	draw_rect(Rect2(wr.position, Vector2(wr.size.x, 4)), Color("#3f8fd6"))
	draw_rect(Rect2(wr.position + Vector2(0, 4), wr.size - Vector2(0, 4)), Color("#2a6db4"))
	var ty := pad.position.y + 12.0
	while ty < pad.end.y - 12:
		draw_rect(Rect2(pad.end.x - 8 - 10, ty, 10, minf(2.0, pad.end.y - 12 - ty)), Color(159/255.0, 192/255.0, 198/255.0, 0.6)); ty += 18.0
	for bub in [[40, 10, 0.0], [84, 30, -1.4], [110, 4, -2.2]]:
		var t := fposmod(now - bub[2], 3.0) / 3.0
		var k := floorf(t * 10) / 10.0
		var pos := Vector2(pad.position.x + bub[0], pad.end.y - bub[1] - 4 - 110.0 * k)
		var br := Rect2(pos, Vector2(4, 4)).intersection(pad)
		if br.has_area(): draw_rect(br, Color(166/255.0, 220/255.0, 1.0, lerpf(0.9, 0.0, k)))

func _window(r: Rect2, title: String) -> Rect2:
	UI.bezel(self, r)
	var g := Rect2(r.position + Vector2(10, 10), r.size - Vector2(20, 20))
	UI.glass(self, g)
	T(F("label", 400, 0.65), 13, title, g.position.x + 14, g.position.y + 12, UI.PHOS_DIM, 16)
	return g

func _wrow(x: float, y: float, w: float, label: String, cells: Array, value: String) -> void:
	var f := F("num")
	var lw := T(f, 22, label, x, y, UI.PHOS, 22)
	var vw := tw(f, 22, value)
	T(f, 22, value, x, y, UI.PHOS, 22, 2, w)
	cell_row(Rect2(x + lw + 8, y + 6, w - lw - vw - 16, 10), cells)

func _paint_chem() -> void:
	var g := _window(Rect2(O + Vector2(16, 290), Vector2(240, 152)), "CHEMISTRY")
	var x := g.position.x + 14; var w := g.size.x - 28
	var ph := []; var nu := []
	for i in range(10):
		ph.append(UI.PHOS if i == 5 else (Color("#173a2d") if i >= 3 and i <= 7 else Color("#0b1714")))
		nu.append(UI.PHOS if i == 5 else (Color("#173a2d") if i >= 4 and i <= 7 else Color("#0b1714")))
	_wrow(x, g.position.y + 34, w, "pH", ph, "6.0")
	_wrow(x, g.position.y + 62, w, "NUTR", nu, "1.8")
	chip(x, g.end.y - 2 - 10 - 21, "In range", "ok", 17, Color("#d9f2e6"), 21)
	UI.glass_overlay(self, g)

# ---------------- pump
func _paint_pump() -> void:
	var o := O + Vector2(346, 184)
	draw_rect(Rect2(o + Vector2(10, 10), Vector2(84, 84)), Color("#091013"))
	draw_rect(Rect2(o + Vector2(14, 18), Vector2(76, 68)), Color("#4c6c74"))
	draw_rect(Rect2(o + Vector2(18, 14), Vector2(68, 76)), Color("#4c6c74"))
	draw_rect(Rect2(o + Vector2(18, 18), Vector2(68, 4)), Color("#79999f"))
	draw_rect(Rect2(o + Vector2(26, 26), Vector2(52, 52)), Color("#0b1518"))
	var ang := 0.0 if isolated() else TAU * floorf(fmod(now, 1.0) * 8) / 8.0
	draw_set_transform(o + Vector2(52, 52), ang)
	draw_rect(Rect2(-3, -22, 6, 44), Color("#a6dcff"))
	draw_rect(Rect2(-22, -3, 44, 6), Color("#a6dcff"))
	draw_rect(Rect2(-6, -6, 12, 12), Color("#e8e4d6"))
	draw_set_transform(Vector2.ZERO)
	var g := _window(Rect2(O + Vector2(290, 290), Vector2(214, 152)), "PUMP OUTPUT")
	var x := g.position.x + 14; var w := g.size.x - 28
	var f := F("num")
	var y := g.position.y + 34
	if isolated():
		var dw := T(f, 22, "— ", x, y, UI.PHOS, 22)
		T(f, 17, "no flow", x + dw, y + 3, UI.PHOS_DIM, 17)
	else:
		var nw := T(f, 22, "19 ", x, y, UI.PHOS, 22)
		T(f, 17, "of 20 L/min", x + nw, y + 2, UI.PHOS_DIM, 17)
	var pout := 0 if isolated() else 19
	cell_row(Rect2(x, g.position.y + 62, w, 10), cells_on(10, int(roundf(pout / 2.0)), UI.PHOS))
	if isolated(): chip(x, g.end.y - 2 - 10 - 21, "Supply closed", "off", 17, Color("#d9f2e6"), 21)
	else: chip(x, g.end.y - 2 - 10 - 21, "Running normally", "ok", 17, Color("#d9f2e6"), 21)
	UI.glass_overlay(self, g)

# ---------------- supply valve
func _paint_supply(st: int) -> void:
	var act := Rect2(O + Vector2(562, 104), Vector2(76, 50))
	UI.box(self, act, {"grad":[[0.0, Color("#2f454b")], [1.0, Color("#1f3035")]], "border":Color.BLACK, "insets":[[2,2,0,Color("#4f6c73")],[-2,-2,0,Color("#122024")]]})
	lamp(Vector2(act.position.x + 29, act.position.y + 7), "ok" if power() else "fault")
	T(F("label"), 12, "SERVICE", act.position.x, act.position.y + 29, UI.LABEL, 15, 1, act.size.x)
	UI.box(self, Rect2(O + Vector2(578, 218), Vector2(40, 40)), {"grad":[[0.0, Color("#5d7d85")], [1.0, Color("#3a5960")]], "border":Color.BLACK, "insets":[[2,2,0,Color("#84a6ad")],[-2,-2,0,Color("#22363b")]]})
	var lr := sv_lock()
	var locked := not lr.is_empty()
	var hitr := Rect2(O + Vector2(550 + nudge_dx("sv"), 190), Vector2(96, 96))
	dim = locked
	var ang := deg_to_rad(tween("svh", 90.0 if isolated() else 0.0, 0.3, 3))
	draw_set_transform(hitr.get_center(), ang)
	B(Rect2(-38, -8, 76, 16), {"grad":[[0.0, Color("#e2564a")], [1.0, Color("#a8382e")]], "border":Color.BLACK, "insets":[[2,2,0,Color("#ff8a7a")],[-2,-2,0,Color("#6a1d17")]]})
	R(Rect2(-38 + 2 + 30, -8 + 2 + 2, 8, 8), Color("#222222"))
	R(Rect2(-38 + 2 + 30, -8 + 2 + 2, 8, 2), Color("#555555")); R(Rect2(-38 + 2 + 30, -8 + 2 + 2, 2, 8), Color("#555555"))
	draw_set_transform(Vector2.ZERO)
	if locked: lock_at(Vector2(hitr.end.x - 4 - 14, hitr.position.y + 30))
	dim = false
	hit("sv", hitr, {"locked":locked, "fixed":restored()})
	if st == 2 or (st == 4 and not restored()): cue(hitr)
	var sx := O.x + 530; var sy := O.y + 296
	if not power() and not restored():
		var f := F("body")
		var lines := UI.wrap_text(f, 16, "Needs service supply", 140 - 4 - 8 - 8 - 10)
		var h := 4 + 12 + lines.size() * 18.4
		locktag(Rect2(sx, sy, 140, h), "Needs service supply", 16)
	else:
		T(F("label", 400, 0.9), 15, "CLOSED" if isolated() else "OPEN", sx, sy, Color("#f2ecd9"), 20, 1, 140)
		var s := "No water past here" if isolated() else "Flowing"
		var l := "off" if isolated() else "ok"
		var cw := 24 + tw(F("body"), 16, s)
		chip(sx + (140 - cw) * 0.5, sy + 28, s, l, 16, Color("#ddd8c8"), 20.8)

# ---------------- manifold valves
func _valve(i: int, st: int) -> void:
	var y: int = BY[i]
	var ok: bool = valves[i] == VT[i]
	var vl := "ok" if ok else ("warn" if identified() else "off")
	var lab := Vector2(O.x + 742, O.y + y - 50)
	lamp(Vector2(lab.x, lab.y + 1), vl)
	T(F("body"), 16, "Valve %d" % (i + 1), lab.x + 24, lab.y, UI.TEXT, 20.8)
	var vo := Vector2(O.x + 834, O.y + y - 50)
	# plate
	draw_rect(Rect2(vo + Vector2(6, 6), Vector2(88, 88)), Color("#152226"))
	rect_stroke(Rect2(vo + Vector2(6, 6), Vector2(88, 88)), 2, Color("#05090b"))
	var c := vo + Vector2(50, 50)
	for a in [0, 45, 90, 135, 180, 225, 270, 315]:
		draw_set_transform(c, deg_to_rad(a))
		draw_rect(Rect2(-2, -48, 4, 8), Color("#9fb3b4"))
	draw_set_transform(c, deg_to_rad(VT[i] * 45))
	var tri := PackedVector2Array([Vector2(0, -39), Vector2(-9, -50), Vector2(9, -50)])
	draw_colored_polygon(tri, Color("#f0b23a"))
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color("#1d180e"), 2)
	draw_set_transform(Vector2.ZERO)
	# wheel
	var lr := valve_lock()
	var locked := not lr.is_empty()
	var id := "wheel:%d" % i
	var wc := c + Vector2(nudge_dx(id), 0)
	dim = locked
	var ang := deg_to_rad(tween("w%d" % i, valves[i] * 45.0, 0.3, 3))
	draw_set_transform(wc, ang)
	draw_arc(Vector2.ZERO, 28, 0, TAU, 48, C(Color("#091013")), 14)
	draw_arc(Vector2.ZERO, 28, 0, TAU, 48, C(Color("#3f7f8a")), 8)
	var circ := TAU * 31.0
	var s := 0.0
	while s < circ:
		var a0 := s / 31.0; var a1 := minf(s + 3.0, circ) / 31.0
		draw_arc(Vector2.ZERO, 31, a0, a1, 3, C(Color("#7fb3bb")), 2)
		s += 10.0
	for rr in [Rect2(-3, -26, 6, 52), Rect2(-26, -3, 52, 6)]:
		draw_rect(rr, C(Color("#3f7f8a"))); draw_rect(rr, C(Color("#091013")), false, 1)
	draw_rect(Rect2(-9, -9, 18, 18), C(Color("#8fbfc6"))); draw_rect(Rect2(-9, -9, 18, 18), C(Color("#091013")), false, 2)
	var ptr := PackedVector2Array([Vector2(0, -37), Vector2(8, -25), Vector2(-8, -25)])
	draw_colored_polygon(ptr, C(Color("#fff2b8")))
	draw_polyline(PackedVector2Array([ptr[0], ptr[1], ptr[2], ptr[0]]), C(Color("#05090b")), 2)
	if locked: IMG("lock", Rect2(Vector2(38 + 6 - 14, -38 - 6), Vector2(14, 16)))
	draw_set_transform(Vector2.ZERO)
	dim = false
	var wr := Rect2(wc - Vector2(38, 38), Vector2(76, 76))
	hit(id, wr, {"locked":locked, "fixed":restored()})
	if st == 3 and not ok: cue(wr)
	# rotate buttons
	var bo := Vector2(O.x + 742, O.y + y + 16)
	var op := 0.45 if not (isolated() and not restored()) else 1.0
	for j in range(2):
		var d := -1 if j == 0 else 1
		var br := Rect2(bo + Vector2(j * 36, 0), Vector2(30, 26))
		var bid := "vb:%d:%d" % [i, d]
		var down := press == bid and hover == bid
		var ins := [[-2,-2,0,Color("#46616a")],[2,2,0,Color("#141e21")]] if down else [[2,2,0,Color("#46616a")],[-2,-2,0,Color("#141e21")]]
		var m := Color(1, 1, 1, op)
		UI.box(self, br, {"bg":Color("#26363b") * m, "border":Color(0, 0, 0, op), "insets":ins})
		_rot_glyph(br, d, op)
		hit(bid, br, {"focus":false, "locked":locked})

func _rot_glyph(r: Rect2, d: int, op: float) -> void:
	var f := F("body")
	var ch := "⟲" if d < 0 else "⟳"
	var col := Color(UI.TEXT, op)
	T(f, 18, ch, r.position.x, r.position.y, col, r.size.y, 1, r.size.x)

# ---------------- growing beds
func _bed(i: int) -> void:
	var y: int = BY[i]
	var o := Vector2(O.x + 1052, O.y + y - 50)
	var steady := restored() and samples() >= 2
	var bp: Array = [0, 0, 0]
	if not isolated():
		if not restored(): bp = [30, 34, 31]
		else: bp = [[62, 65, 60], [90, 92, 88], [98, 97, 99], [98, 97, 99]][samples()]
	var icon := "plant" if steady else "droop"
	# plants row: justify-content space-around inside 170-16
	var inner := 154.0; var gap := (inner - 4 * 30) / 4.0
	for k in range(4):
		draw_texture_rect(UI.tex(icon), Rect2(o.x + 8 + gap * 0.5 + k * (30 + gap), o.y + 10, 30, 30), false)
	if not isolated():
		var period := 1.2 if restored() else 3.2
		var t := fmod(now, period) / period
		var kk := floorf(t * 6) / 6.0
		draw_rect(Rect2(o.x + 4, o.y + 28 + 18 * kk, 4, 4), Color(166/255.0, 220/255.0, 1.0, 1.0 - kk))
	var soil := Rect2(o.x, o.y + 40, 170, 20)
	UI.box(self, soil, {"grad":[[0.0, Color("#5a4130")], [4.0 / 16.0, Color("#5a4130")], [4.0 / 16.0, Color("#3d2c21")], [1.0, Color("#3d2c21")]], "border":Color.BLACK, "insets":[[2,0,0,Color("#6e5440")]]})
	var by := o.y + 66
	var f := F("body")
	var lw := T(f, 15, "Bed %d" % (i + 1), o.x, by, UI.TEXT, 19.5)
	var fv := F("num")
	T(fv, 20, "%d%%" % bp[i], o.x + 170 - 40, by, UI.PHOS, 20, 2, 40)
	var on := int(roundf(bp[i] / 12.5))
	var cols := []
	for k in range(8): cols.append(UI.WATER_HI if k < on else Color("#0b1714"))
	cell_row(Rect2(o.x + lw + 6, by + 5, 170 - lw - 6 - 6 - 40, 10), cols)

# ---------------- flow strip + verify
func _paint_flow(st: int) -> void:
	var bz := Rect2(652, 522, 608, 182)
	UI.bezel(self, bz)
	var g := Rect2(664, 534, 468, 158)
	UI.glass(self, g)
	T(F("num", 400, 0.88), 22, "WHERE THE WATER GOES", 678, 538, UI.PHOS, 26)
	T(F("num", 400, 0.88), 18, "L/MIN", 678, 538, UI.PHOS_DIM, 26, 2, 1118 - 678)
	var mv := 0
	if not isolated(): mv = 6 if not restored() else [12, 17, 19, 19][samples()]
	var bad := not restored() and not isolated()
	_frow(572, "Pump sends", 0 if isolated() else 19, false, false)
	_frow(600, "Manifold passes", mv, bad, isolated())
	_frow(628, "Beds receive", mv, bad, isolated())
	var ls := ""; var lt := ""
	if restored() and samples() < 3: ls = "live"; lt = "Delivery recovering: %d of 3 steady" % samples()
	elif restored(): ls = "ok"; lt = "Beds receive what the pump sends"
	elif identified() and not isolated(): ls = "warn"; lt = "%d L/min lost at the manifold" % (19 - mv)
	elif isolated(): ls = "off"; lt = "Supply closed. No flow to measure."
	else: ls = "warn"; lt = "Beds receive much less than the pump sends"
	lamp(Vector2(694, 660), ls)
	T(F("body"), 17, lt, 720, 658, Color("#f6e7c1"), 21)
	UI.glass_overlay(self, g)
	var vr := verify_lock()
	var pr := push("verify", 1154 + nudge_dx("verify") * 0, 575, 84, "VERIFY", "Delivery", "done" if verified() else "", not vr.is_empty(), verified())
	if st == 5: cue(pr)

func _frow(y: float, label: String, v: int, bad: bool, dash: bool) -> void:
	T(F("body"), 17, label, 680, y + 1, Color("#cfe9dc"), 21)
	cell_row(Rect2(840, y + 4, 170, 14), cells_on(16, int(roundf(v / 20.0 * 16)), UI.WARN if bad else UI.WATER_HI))
	T(F("num"), 22, "—" if dash else str(v), 1020, y, UI.PHOS, 22, 2, 96)
