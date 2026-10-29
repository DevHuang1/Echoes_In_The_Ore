extends "res://scripts/ui/eito/eito_screen.gd"
## A · Auxiliary power. Visuals, steps, interlocks and wording follow the design;
## every state change goes through ShipMissionState so the story, saves and the
## rest of the ship see the same truth.

const PLANS := [{"n":"Standard","id":"standard","e":50,"s":40,"r":10}, {"n":"Science first","id":"science","e":45,"s":45,"r":10}, {"n":"Repair hold","id":"repair","e":65,"s":15,"r":20}]
const MIN := {"e":60, "r":15}
const FD := {
	"v":{"name":"Voltage","hint":"strength","unit":"V","min":200,"max":260,"lo":226,"hi":236,"start":212},
	"f":{"name":"Frequency","hint":"rhythm","unit":"Hz","min":390,"max":410,"lo":398,"hi":402,"start":393},
	"p":{"name":"Phase","hint":"timing","unit":"°","min":-60,"max":60,"lo":-8,"hi":8,"start":38},
}
const FKEYS := ["v", "f", "p"]
const REF := {"v":231, "f":400, "p":0}
const STEPS := [
	{"t":"Find the bank that doesn’t match","do":"Compare the three banks. Tap the one that doesn’t match.","why":"One auxiliary bank has drifted out of step with the other two."},
	{"t":"Isolate the service circuit","do":"Pull the Service lever down to Isolated.","why":"This cuts power to the circuit you’re repairing. Essential power stays on."},
	{"t":"Choose a safe power plan","do":"Turn the Power plan knob until every limit shows a check.","why":"While the service circuit is off, essential and reserve power must stay above their minimums."},
	{"t":"Bring bank B into range","do":"Slide each Bank B control into its green band.","why":"On the scope, the bright wave should land on top of the dim one."},
	{"t":"Sync bank B","do":"Press Sync.","why":"Locks bank B to the other two banks."},
	{"t":"Restore the circuit","do":"Push the Service lever up to Live, then watch the readings.","why":"The repair isn’t finished until the circuit carries power again."},
	{"t":"Verify the repair","do":"Press Verify.","why":"All three readings are steady. Verify confirms bank B holds under load."},
]
const DONE := {"do":"Auxiliary power is restored and verified.", "why":"Next objective: restore irrigation."}
const NEED := ["Find the bank that doesn’t match first.", "Isolate the service circuit first.", "Choose a safe power plan first.", "Move all three Bank B controls into the green first.", "Sync bank B first.", "Restore the circuit first.", "", ""]
const NOTES := "<b>Readings:</b> volts show how hard a bank pushes, hertz how fast it cycles, phase whether its timing lines up. A bank is in step when all three match the others."
const SAMPLE_SECONDS := 1.1

var ctl  # owning layer: state, act(), story_mode, has_tool()
var plan := 0
var val := {"v":212, "f":393, "p":38}
var syncing := false
var prog := 0
var _sync_t := 0.0
var fb := {"s":"", "t":"Panel ready."}
var drawer_mode := ""
var drawer_t := 0.0
var flash_t := -10.0
var comms := false
var comms_t := 0.0
var _last_samples := -1
var _scope_t := 0.0
var _scope_acc := 0.0
var _comms_due := -1.0

func setup(owner) -> void:
	ctl = owner
	var p: Dictionary = ctl.state.systems.power
	if ctl.state.flags.get("power.allocated", false):
		for i in range(PLANS.size()):
			if PLANS[i].e == int(p.essential) and PLANS[i].r == int(p.reserve): plan = i
	var saved: Dictionary = ctl.state.legacy_progress.get("auxiliary_power", {})
	if saved.get("power") is Array and saved.power.size() == 3:
		for i in range(3):
			var k: String = FKEYS[i]
			val[k] = int(roundf(lerpf(FD[k].min, FD[k].max, clampf(float(saved.power[i]) / 100.0, 0, 1))))
	else:
		for k in FKEYS: val[k] = FD[k].start
	if verified(): comms = ctl.story_mode; comms_t = -10.0
	_last_samples = samples()

# ------------------------------------------------------------ model view
func S() -> Object: return ctl.state
func identified() -> bool: return bool(S().flags.get("power.diagnosed", false))
func isolated() -> bool: return bool(S().systems.power.isolated)
func synced() -> bool: return bool(S().systems.power.calibrated)
func restored() -> bool: return bool(S().systems.power.restored) and not isolated()
func verified() -> bool: return S().completed.has("power")
func samples() -> int:
	if not restored(): return 0
	if verified(): return 3
	return mini(3, int(floor(float(S().verification.get("power", 0.0)) / SAMPLE_SECONDS)))
func in_band(k: String) -> bool: return val[k] >= FD[k].lo and val[k] <= FD[k].hi
func all_in() -> bool: return in_band("v") and in_band("f") and in_band("p")
func safe() -> bool: return PLANS[plan].e >= MIN.e and PLANS[plan].r >= MIN.r

func step() -> int:
	if not identified(): return 0
	if not isolated() and not synced(): return 1
	if not synced():
		if not safe(): return 2
		if not all_in(): return 3
		return 4
	if not restored() or samples() < 3: return 5
	if not verified(): return 6
	return 7

func say(s: String, t: String) -> void:
	fb = {"s":s, "t":t}; pop("p:fb")

func log_lines() -> Array:
	var out := []
	if identified(): out.append("Bank B found out of sync with banks A and C.")
	if isolated() or synced(): out.append("Service circuit isolated. Essential power on.")
	if S().flags.get("power.allocated", false): out.append("Power plan set: %s." % PLANS[plan].n)
	if synced(): out.append("Bank B synchronized.")
	if restored(): out.append("Service circuit restored.")
	if samples() >= 3 and restored(): out.append("Readings steady.")
	if verified(): out.append("Repair verified. Auxiliary power restored.")
	return out

func _save_progress() -> void:
	var arr := []
	for k in FKEYS: arr.append(clampf((val[k] - FD[k].min) * 100.0 / (FD[k].max - FD[k].min), 0, 100))
	S().legacy_progress["auxiliary_power"] = {"task":"auxiliary_power", "complete":synced(), "filter_stage":0, "filter_rotation":0, "filter_airflow":0.0, "power":arr, "nutrient_rotations":[]}

func show_comms() -> void:
	if comms: return
	_comms_due = now + 0.7

# ------------------------------------------------------------ ticking
func tick(delta: float) -> void:
	_scope_acc += delta
	while _scope_acc >= 0.07:
		_scope_acc -= 0.07; _scope_t += 0.12
	if syncing:
		_sync_t += delta
		while syncing and _sync_t >= 0.28:
			_sync_t -= 0.28; prog += 1
			if prog >= 8: _finish_sync()
	if _comms_due > 0 and now >= _comms_due:
		_comms_due = -1.0; comms = true; comms_t = now; flash_t = now
	var n := samples()
	if restored() and not verified() and n != _last_samples:
		if n < 3: say("live", "Circuit live. Watching readings: %d of 3 steady." % n)
		else: say("ok", "Readings steady. Press Verify.")
	_last_samples = n

func _finish_sync() -> void:
	syncing = false
	ctl.act("sync", null)
	if synced():
		_save_progress()
		say("ok", "Bank B synchronized. The circuit is still isolated. Restore it next.")
	else:
		prog = 0

# ------------------------------------------------------------ interaction
func lock_reason(id: String) -> String:
	var st := step()
	match id:
		"lever":
			if st == 0: return NEED[0]
			if isolated() and not synced(): return "Sync bank B before restoring the circuit."
		"knob":
			if not isolated() and not synced(): return NEED[mini(st, 1)]
		"fader":
			if not synced() and not (isolated() and safe()): return NEED[mini(st, 2)]
			if not synced() and not ctl.has_tool(): return "Carry the engineering multitool to adjust bank B. It is stored in the crew quarters wardrobe."
		"sync":
			if not synced() and not syncing and st != 4: return NEED[mini(st, 3)]
			if not synced() and not syncing and not ctl.has_tool(): return "Carry the engineering multitool to synchronize bank B."
		"verify":
			if not verified() and st != 6: return "Wait for three steady readings first." if restored() else NEED[mini(st, 5)]
	return ""

func fixed(id: String) -> bool:
	match id:
		"lever": return restored()
		"knob": return synced()
		"fader": return synced()
		"sync": return synced() or syncing
		"verify": return verified()
	return false

func _blocked(id: String, nid := "") -> bool:
	var reason := lock_reason(id)
	if not reason.is_empty():
		nudge(nid if not nid.is_empty() else id); say("lock", reason); return true
	return fixed(id)

func on_click(id: String, _event) -> void:
	if id == "esc": close_requested.emit(); return
	if id.begins_with("bank:"):
		if identified(): return
		var b := id.get_slice(":", 1)
		if not S().flags.get("power.observed", false): ctl.act("observe", null)
		if b == "B":
			ctl.act("diagnose", "cell")
			if identified(): say("warn", "Bank B is out of step with A and C. Isolate the service circuit next.")
		else:
			say("ok", "Bank %s reads 231 V, 400 Hz and is in step. Compare it with the others." % b)
		return
	match id:
		"guard":
			say("ok", "Essential power stays on for this whole repair. Its guard stays closed.")
		"lever":
			if _blocked("lever"): return
			var st := step()
			if st == 1:
				ctl.act("isolate", null)
				if isolated(): say("ok", "Service circuit isolated. Essential power is still on.")
			elif st == 5 and not restored():
				ctl.act("restore", null)
				if restored():
					_last_samples = 0; say("live", "Circuit live. Watching readings: 0 of 3 steady.")
		"knob":
			_turn(1, "knob")
		"arrow:-1", "arrow:1":
			_turn(int(id.get_slice(":", 1)), "knob")
		"sync":
			if _blocked("sync"): return
			syncing = true; prog = 0; _sync_t = 0.0
			say("live", "Synchronizing bank B with banks A and C…")
		"verify":
			if _blocked("verify"): return
			ctl.act("verify", null)
			if verified():
				say("ok", "Repair verified. Auxiliary power is restored.")
				flash_t = now
		"p:manual", "p:dm_manual":
			if drawer_mode.is_empty(): drawer_t = now
			drawer_mode = "manual"
		"p:log", "p:dm_log":
			if drawer_mode.is_empty(): drawer_t = now
			drawer_mode = "log"
		"p:dm_close":
			drawer_mode = ""

func _turn(d: int, nid: String) -> void:
	if _blocked("knob", nid): return
	plan = (plan + d + 3) % 3
	var p: Dictionary = PLANS[plan]
	if safe():
		ctl.act("allocation", p.id)
		if S().flags.get("power.allocated", false) and int(S().systems.power.essential) == p.e:
			say("ok", "%s is safe. Bank B controls unlocked." % p.n)
	else:
		say("warn", "%s would drop %s power below its minimum." % [p.n, "essential" if p.e < MIN.e else "reserve"])

func _set_val(k: String, v: float) -> void:
	var f: Dictionary = FD[k]
	var nv := clampi(int(roundf(v)), f.min, f.max)
	if nv == val[k]: return
	var was := in_band(k); var was_all := all_in()
	val[k] = nv
	if all_in() and not was_all: say("ok", "All three controls are in the green. Press Sync.")
	elif in_band(k) and not was: say("ok", "%s is in range." % f.name)
	elif not in_band(k) and was: say("warn", "%s left its green band." % f.name)
	_save_progress()

func _fader_track(k: String) -> Rect2:
	var i := FKEYS.find(k)
	return Rect2(898 + i * 84 + 2, 508, 52, 140)

func on_press(id: String, pos: Vector2) -> bool:
	if not id.begins_with("fader:"): return false
	if not _fader_track(id.get_slice(":", 1)).has_point(pos): return false
	return not _blocked("fader", id)

func on_drag(id: String, pos: Vector2) -> void:
	if not id.begins_with("fader:"): return
	var k := id.get_slice(":", 1)
	var r := _fader_track(k)
	var f: Dictionary = FD[k]
	_set_val(k, f.min + (1.0 - (pos.y - r.position.y) / r.size.y) * (f.max - f.min))

func on_wheel(id: String, dir: int) -> bool:
	if id.begins_with("fader:"):
		if not lock_reason("fader").is_empty() or fixed("fader"): return true
		var k := id.get_slice(":", 1)
		_set_val(k, val[k] + dir)
		return true
	return false

func on_key(id: String, e: InputEventKey) -> bool:
	if id.begins_with("fader:"):
		var d: int = {KEY_UP:1, KEY_RIGHT:1, KEY_DOWN:-1, KEY_LEFT:-1, KEY_PAGEUP:5, KEY_PAGEDOWN:-5}.get(e.keycode, 0)
		if d == 0: return false
		if _blocked("fader", id): return true
		var k := id.get_slice(":", 1)
		_set_val(k, val[k] + d)
		return true
	if id == "knob" and e.keycode in [KEY_LEFT, KEY_RIGHT]:
		_turn(-1 if e.keycode == KEY_LEFT else 1, "knob"); return true
	return false

# ------------------------------------------------------------ painting
func paint() -> void:
	screen_bg()
	var st := step()
	var over := {}
	if syncing: over = {"do":"Hold on while bank B synchronizes.", "why":"The service circuit stays isolated until you restore it."}
	elif restored() and samples() < 3 and not verified(): over = {"do":"Watch the readings settle.", "why":"Verify unlocks after three steady readings."}
	hud("Restore irrigation" if verified() else "Restore auxiliary power", "Auxiliary power · Distribution", "Step away", flash_t)
	_paint_map()
	procedure("p", Rect2(20, 500, 680, 204), STEPS, st, fb, DONE, over)
	_paint_banks(st)
	_paint_circuits(st)
	_paint_plan(st)
	_paint_trim(st)
	if comms:
		comms_card(Rect2(724, 500, 524, 186), "leila", "Leila", "Ship comms", "Got it on my board. Bank B is holding steady with the others. Thanks, Thura.", "New objective: Restore irrigation", comms_t)
	if not drawer_mode.is_empty():
		drawer("p", Rect2(20, 56, 680, 432), drawer_mode, STEPS, st, log_lines(), NOTES, drawer_t)

# ---------------- circuit map (GLASS)
func _paint_map() -> void:
	UI.bezel(self, Rect2(20, 56, 680, 432))
	var g := Rect2(34, 70, 652, 404)
	UI.glass(self, g)
	var fnum := F("num", 400, 0.88)
	T(fnum, 22, "CIRCUIT MAP", 48, 76, UI.PHOS, 26)
	# legend, right aligned with 14px gaps
	var items := [["POWERED", "live"], ["OFF", "off"], ["UNSTABLE", "warn"]]
	var lf := F("num", 400, 0.88)
	var widths := []; var total := 0.0
	for it in items:
		var w := 20 + 6 + tw(lf, 18, it[0]); widths.append(w); total += w
	total += 14 * (items.size() - 1)
	var lx := 672.0 - total
	for i in range(items.size()):
		var iy := 76 + 13 - 2
		match items[i][1]:
			"live": dashed(PackedVector2Array([Vector2(lx, iy + 2), Vector2(lx + 20, iy + 2)]), 4, [6, 4], 0, UI.PHOS)
			"off": dashed(PackedVector2Array([Vector2(lx, iy + 2), Vector2(lx + 20, iy + 2)]), 4, [2, 4], 0, Color("#2c5848"))
			"warn": dashed(PackedVector2Array([Vector2(lx, iy + 2), Vector2(lx + 20, iy + 2)]), 4, [3, 3], 0, UI.WARN)
		T(lf, 18, items[i][0], lx + 26, 76, UI.PHOS_DIM, 26)
		lx += widths[i] + 14
	_paint_circuit_svg(Vector2(36, 102))
	if verified(): _paint_stamp(g)
	UI.glass_overlay(self, g)

func _flow_offset() -> float:
	return -3.0 * floor(fmod(now, 0.8) / 0.2)

func _ln(o: Vector2, pts: Array, kind: String) -> void:
	var p := PackedVector2Array()
	for q in pts: p.append(o + q)
	match kind:
		"live": dashed(p, 3, [8, 4], _flow_offset(), UI.PHOS)
		"dead": dashed(p, 3, [2, 6], 0, Color("#2c5848"))
		"warn":
			var second := fmod(now, 0.45) >= 0.225
			var c := UI.WARN; if second: c.a = 0.6
			dashed(p, 3, [3, 3, 9, 4], 5.0 if second else 0.0, c)

func _paint_circuit_svg(o: Vector2) -> void:
	var L := {"main":[Vector2(16,34),Vector2(636,34)], "dE":[Vector2(115,34),Vector2(115,70)], "dS":[Vector2(326,34),Vector2(326,70)], "dR":[Vector2(537,34),Vector2(537,70)],
		"bA":[Vector2(94,268),Vector2(94,222)], "bB":[Vector2(254,268),Vector2(254,222)], "bC":[Vector2(414,268),Vector2(414,222)], "sync":[Vector2(94,222),Vector2(470,222)], "svc":[Vector2(510,222),Vector2(536,222)]}
	for k in L: seg(o + L[k][0], o + L[k][1], 8, Color("#0f2a20"), "square")
	var is_synced := synced(); var iso := isolated(); var rest := restored()
	for k in ["main","dE","dS","dR","bA","bC"]: _ln(o, L[k], "live")
	_ln(o, L.bB, "live" if is_synced else "warn")
	_ln(o, L.sync, "live" if is_synced else "warn")
	_ln(o, L.svc, "live" if rest else ("dead" if iso else "warn"))
	var f18 := F("num"); var f16 := F("num"); var f20 := F("num"); var f22 := F("num")
	_svg_text(f18, 18, "MAIN BUS", o + Vector2(18, 24), UI.PHOS)
	_svg_text(f18, 18, "SYNC BUS", o + Vector2(100, 212), UI.PHOS)
	_svg_text(f16, 16, "BREAKER", o + Vector2(452, 252), UI.PHOS)
	var p: Dictionary = PLANS[plan]
	_load_box(o, "bxE", 20, "heart", "ESSENTIAL", p.e, MIN.e)
	_load_box(o, "bxS", 231, "flask", "SCIENCE", p.s, 0)
	_load_box(o, "bxR", 442, "batt", "RESERVE", p.r, MIN.r)
	for b in ["A", "B", "C"]:
		var x: float = {"A":24, "B":184, "C":344}[b]
		var cls := "on"; var st := "IN STEP"; var rd := "231V 400HZ"
		if b == "B":
			rd = "%dV %dHZ" % [val.v, val.f]
			cls = "on" if is_synced else ("warn sel" if identified() else "warn")
			st = "IN STEP" if is_synced else ("SYNCING" if syncing else ("OUT OF SYNC" if identified() else "UNSTABLE"))
		_frame(o + Vector2(x, 268), Vector2(140, 72), cls)
		var tcol := UI.PHOS
		_svg_text(f20, 20, "BANK " + b, o + Vector2(x + 12, 288), tcol)
		_svg_text(f18, 18, st, o + Vector2(x + 12, 310), UI.WARN if cls.begins_with("warn") else tcol)
		_svg_text(f18, 18, rd, o + Vector2(x + 12, 332), tcol)
	# breaker terminals and blade
	draw_rect(Rect2(o + Vector2(466, 218), Vector2(8, 8)), UI.PHOS)
	draw_rect(Rect2(o + Vector2(506, 218), Vector2(8, 8)), UI.PHOS)
	var blade_open := tween("blade", 1.0 if iso else 0.0, 0.2, 2)
	var tip := Vector2(506, 222).lerp(Vector2(500, 198), blade_open)
	seg(o + Vector2(474, 222), o + tip, 4, UI.PHOS, "square")
	# service box
	var vcls := "on" if rest else ("off" if iso else "warn")
	_frame(o + Vector2(536, 182), Vector2(106, 96), vcls)
	var vt := Color("#4a7a66") if vcls == "off" else UI.PHOS
	draw_texture_rect(UI.tex("bolt"), Rect2(o + Vector2(546, 192), Vector2(14, 20)), false, Color(1,1,1,1) if vcls != "off" else Color(1,1,1,1))
	_svg_text(f20, 20, "SERVICE", o + Vector2(566, 208), vt)
	_svg_text(f16, 16, "IRRIGATION", o + Vector2(546, 232), vt)
	_svg_text(f20, 20, "LIVE" if rest else ("ISOLATED" if iso else "UNSTABLE"), o + Vector2(546, 264), UI.WARN if vcls == "warn" else vt)
	if rest:
		_svg_text(f18, 18, "STEADY", o + Vector2(536, 304), UI.PHOS)
		var n := samples()
		for i in range(3):
			var dr := Rect2(o + Vector2(598 + i * 14, 294), Vector2(10, 10))
			draw_rect(dr, UI.PHOS if i < n else Color("#123227"))
			rect_stroke(dr, 1, UI.PHOS_DIM)

func _svg_text(f: Font, sz: int, s: String, base: Vector2, c: Color, anchor_end := false) -> void:
	var x := base.x
	if anchor_end: x -= tw(f, sz, s)
	draw_string(f, Vector2(roundf(x), roundf(base.y)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)

func _frame(p: Vector2, s: Vector2, cls: String) -> void:
	var r := Rect2(p, s)
	draw_rect(r, Color("#08180f"))
	var col := UI.PHOS_DIM; var w := 2.0; var dash := []
	if cls.begins_with("on"): col = UI.PHOS
	if cls.begins_with("warn"): col = UI.WARN; dash = [6, 3]
	if cls.begins_with("off"): col = Color("#2c5848")
	if cls.contains("sel"): w = 4.0; dash = []
	rect_stroke(r, w, col, dash)

func _load_box(o: Vector2, _id: String, x: float, icon: String, name: String, value: int, minv: int) -> void:
	var low := isolated() and minv > 0 and value < minv
	_frame(o + Vector2(x, 70), Vector2(190, 92), "warn" if low else "on")
	var isz := Vector2(18, 16)
	var ir := Rect2(o + Vector2(x + 12, 82), isz)
	var tex := UI.tex(icon)
	var k := minf(isz.x / tex.get_width(), isz.y / tex.get_height())
	var dsz := Vector2(tex.get_width(), tex.get_height()) * k
	draw_texture_rect(tex, Rect2(ir.position + (isz - dsz) * 0.5, dsz), false)
	var f := F("num")
	_svg_text(f, 20, name, o + Vector2(x + 38, 96), UI.PHOS)
	var st := "BELOW MINIMUM" if low else ("STILL ONLINE" if name == "ESSENTIAL" and isolated() else "ONLINE")
	_svg_text(f, 18, st, o + Vector2(x + 12, 122), UI.WARN if low else UI.PHOS)
	var on := int(roundf(value / 10.0))
	for i in range(10):
		draw_rect(Rect2(o + Vector2(x + 12 + i * 11, 136), Vector2(9, 12)), (UI.WARN if low else UI.PHOS) if i < on else Color("#123227"))
	_svg_text(f, 22, "%d%%" % value, o + Vector2(x + 178, 148), UI.PHOS, true)

func _paint_stamp(g: Rect2) -> void:
	# .crt-stamp sits at left:50% of the glass, so its shrink-to-fit width is
	# capped at half the screen width and the sub-line wraps exactly like the design.
	var t := clampf((now - flash_t) / 0.4, 0, 1) if now - flash_t < 0.4 else 1.0
	var p := floorf(t * 3) / 3.0
	var fb7 := F("body", 700); var f17 := F("body")
	var title := "Repair verified"; var sub := "Auxiliary power is back to normal"
	var max_text := (g.size.x - 4) * 0.5 - 52 - 42
	var sub_lines := UI.wrap_text(f17, 17, sub, max_text)
	var cw := tw(fb7, 28, title)
	for l in sub_lines: cw = maxf(cw, tw(f17, 17, l))
	cw = minf(cw, max_text)
	var text_h := 36.4 + sub_lines.size() * 22.1
	var w := 4 + 22 + 28 + 14 + cw + 22 + 4
	var h := 4 + 14 + text_h + 14 + 4
	var scale := lerpf(1.6, 1.0, p)
	var center := g.get_center()
	draw_set_transform(center, 0, Vector2(scale, scale))
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	var a := p
	draw_rect(r.grow(4), Color(0, 0, 0, 0.45 * a))
	UI.box(self, r, {"bg":UI.PAPER, "border":Color("#2f6b38"), "bw":4, "insets":[[0,0,2,UI.PAPER_HI]]})
	draw_texture_rect(UI.tex("check"), Rect2(r.position.x + 4 + 22, r.position.y + (h - 24) * 0.5, 28, 24), false)
	var tx := r.position.x + 4 + 22 + 28 + 14
	var ty := r.position.y + 4 + 14
	UI.text(self, fb7, 28, title, tx, ty, UI.INK, 36.4)
	for i in range(sub_lines.size()):
		UI.text(self, f17, 17, sub_lines[i], tx, ty + 36.4 + i * 22.1, UI.INK_2, 22.1)
	draw_set_transform(Vector2.ZERO)

# ---------------- bank readings module
func _paint_banks(st: int) -> void:
	var m := Rect2(712, 56, 548, 152)
	module(m, "Bank readings")
	if identified():
		module_chip(m, "All in step" if synced() else "Bank B out of sync", "ok" if synced() else "warn")
	for i in range(3):
		var b: String = ["A", "B", "C"][i]
		_bank(b, Rect2(726 + i * 130, 100, 120, 96))
	if st == 0: cue(Rect2(726, 100, 380, 96))
	var vlab := "Verified" if verified() else ("Steady %d of 3" % samples() if restored() and samples() < 3 else "Test under load")
	var lr := lock_reason("verify")
	var lines := UI.wrap_text(F("body"), 15, vlab, 110.0)
	var bw := 110.0 if lines.size() > 1 else maxf(84.0, tw(F("body"), 15, vlab))
	var bh := 50.0 + 8 + lines.size() * 17.25
	var pr := push("verify", 1128 + (118 - bw) * 0.5, 100 + (96 - bh) * 0.5, bw, "VERIFY", vlab, "done" if verified() else "", not lr.is_empty(), fixed("verify"))
	if st == 6: cue(pr)
	screws(m)

func _bank(b: String, r: Rect2) -> void:
	var off := b == "B" and not synced()
	var sel := b == "B" and identified() and not synced()
	var ok := b == "B" and synced()
	var ring := Color("#17302a")
	if sel: ring = UI.WARN
	elif ok: ring = UI.OK
	elif hover == "bank:" + b and not identified(): ring = UI.PHOS
	UI.box(self, r, {"bg":Color("#081510"), "border":Color.BLACK, "insets":[[0,0,2,ring]]})
	var fl := F("label", 400, 0.65)
	T(fl, 13, "BANK " + b, r.position.x, r.position.y + 7, UI.WARN if sel else UI.PHOS_DIM, 16, 1, r.size.x)
	# dial (viewBox 96x44 drawn into 96x42 -> uniform 0.9545 scale, centred)
	var k := 42.0 / 44.0
	var dpos := Vector2(r.position.x + 6 + (96 - 96 * k) * 0.5 + 6, r.position.y + 7 + 16 + 1)
	draw_set_transform(dpos, 0, Vector2(k, k))
	var c := Vector2(48, 40)
	var pts := PackedVector2Array()
	for i in range(33): pts.append(c + Vector2(-40, 0).rotated(PI * i / 32.0))
	draw_polyline(pts, UI.PHOS_DIM, 2)
	for a in [-60, -30, 30, 60]:
		var d := Vector2(0, -1).rotated(deg_to_rad(a))
		draw_line(c + d * 32, c + d * 38, UI.PHOS_DIM, 2)
	draw_line(c + Vector2(0, -31), c + Vector2(0, -40), UI.PHOS, 3)
	var ang := 0.0
	if off and not syncing:
		var tt := fmod(now, 2.6); var u := tt / 1.3 if tt < 1.3 else (2.6 - tt) / 1.3
		ang = lerpf(18, 52, floorf(u * 6) / 6.0)
	elif off and syncing: ang = 10
	draw_line(c, c + Vector2(0, -30).rotated(deg_to_rad(ang)), UI.PHOS, 3)
	draw_rect(Rect2(44, 36, 8, 8), UI.PHOS)
	draw_set_transform(Vector2.ZERO)
	var rd := "%dV %dHz" % [val.v, val.f] if b == "B" else "231V 400Hz"
	T(F("num"), 19, rd, r.position.x, r.position.y + 67, UI.PHOS, 19, 1, r.size.x)
	if identified():
		lamp(Vector2(r.end.x - 2 - 4 - 18, r.position.y + 2 + 4), "warn" if (b == "B" and not synced()) else "ok")
	hit("bank:" + b, r, {"fixed":identified()})

# ---------------- circuits module
func _paint_circuits(st: int) -> void:
	var m := Rect2(712, 218, 214, 196)
	module(m, "Circuits")
	var fl := F("label", 400, 0.7)
	T(fl, 14, "Essential", 726, 262, UI.LABEL, 18, 1, 90)
	T(fl, 14, "Service", 826, 262, UI.LABEL, 18, 1, 90)
	_guard(Vector2(739, 286))
	chip(726 + (90 - 42) * 0.5, 384, "On", "ok", 15)
	var lr := lock_reason("lever")
	var lx := 839.0 + nudge_dx("lever")
	var lev := Rect2(lx, 286, 64, 92)
	dim = not lr.is_empty()
	_lever(lev)
	if dim: lock_corner(lev)
	dim = false
	hit("lever", lev, {"locked":not lr.is_empty(), "fixed":fixed("lever")})
	if st == 1 or (st == 5 and not restored()): cue(lev)
	var sl := "Live" if restored() else ("Isolated" if isolated() else "Unstable")
	var ls := "ok" if restored() else ("" if isolated() else "warn")
	var cw := 24 + tw(F("body"), 15, sl)
	chip(826 + maxf(0, (90 - cw) * 0.5), 384, sl, ls if not ls.is_empty() else "off", 15)
	screws(m)

func _guard(p: Vector2) -> void:
	var r := Rect2(p, Vector2(64, 92))
	B(Rect2(p + Vector2(12, 10), Vector2(40, 72)), {"bg":Color("#0d1417"), "border":Color.BLACK, "insets":[[2,2,0,Color("#26363b")]]})
	var cov := Rect2(p + Vector2(6, 4), Vector2(52, 84))
	B(cov, {"grad":[[0.0, Color("#c84a36")], [1.0, Color("#8f2c1e")]], "border":Color.BLACK})
	hazard(cov.grow(-2), Color(0, 0, 0, 0.18), Color(0, 0, 0, 0))
	B(cov, {"insets":[[2,2,0,Color("#ec7a62")],[-2,-2,0,Color("#5a1a11")]], "bw":2})
	var f := F("label", 400, 0.48)
	var sp := Rect2(cov.position.x + 2, cov.end.y - 2 - 6 - 32, 48, 32)
	draw_rect(sp, Color("#3a120c"))
	T(f, 12, "KEEP", sp.position.x + 4, sp.position.y + 1, Color("#fde9e1"), 15)
	T(f, 12, "ON", sp.position.x + 4, sp.position.y + 16, Color("#fde9e1"), 15)
	hit("guard", r)

func _lever(r: Rect2) -> void:
	var up := not isolated()
	var f := F("body")
	T(f, 14, "Live", r.position.x, r.position.y - 2, Color("#f2ecd9") if up else Color("#9fb0ae"), 18.2, 1, 64)
	T(f, 14, "Isolated", r.position.x, r.end.y + 4 - 18.2, Color("#f2ecd9") if not up else Color("#9fb0ae"), 18.2, 1, 64)
	var slot := Rect2(r.position + Vector2(26, 18), Vector2(12, 56))
	B(slot, {"bg":Color("#05090a"), "border":Color.BLACK, "insets":[[2,2,0,Color.BLACK]], "outer":[[0,0,2,Color("#2e444a")]]})
	var top := tween("lever", 14.0 if up else 60.0, 0.2, 3)
	var hd := Rect2(r.position + Vector2(12, top), Vector2(40, 18))
	B(hd, {"grad":[[0.0, Color("#dcd4b6")], [1.0, Color("#a39b7e")]], "border":Color.BLACK, "insets":[[2,2,0,Color("#f6f0da")],[-2,-2,0,Color("#6d6653")]]})
	R(Rect2(hd.position + Vector2(2 + 8, 2 + 6), Vector2(20, 2)), Color("#6d6653"))
	R(Rect2(hd.position + Vector2(2 + 8, 2 + 10), Vector2(20, 2)), Color("#6d6653"))

# ---------------- power plan module
func _paint_plan(st: int) -> void:
	var m := Rect2(936, 218, 324, 196)
	module(m, "Power plan")
	var chip_s := "Normal running"; var chip_l := "off"
	if isolated():
		chip_s = "Safe" if safe() else "Not safe"; chip_l = "ok" if safe() else "warn"
	module_chip(m, chip_s, chip_l)
	var lr := lock_reason("knob")
	var kx := 951.0 + nudge_dx("knob")
	var row := Rect2(kx, 262, 116, 72)
	dim = not lr.is_empty()
	_arrow("arrow:-1", Rect2(kx, 284, 18, 28), "‹", lr)
	_knob(Rect2(kx + 22, 262, 72, 72))
	_arrow("arrow:1", Rect2(kx + 98, 284, 18, 28), "›", lr)
	if dim: lock_corner(row)
	dim = false
	hit("knob", Rect2(kx + 22, 262, 72, 72), {"locked":not lr.is_empty(), "fixed":fixed("knob")})
	if st == 2: cue(row)
	var pn: String = PLANS[plan].n
	var fname := F("body")
	var lines := UI.wrap_text(fname, 17, pn, 118)
	for i in range(lines.size()): T(fname, 17, lines[i], 950, 340 + i * 18.7, Color("#f2ecd9"), 18.7, 1, 118)
	var p: Dictionary = PLANS[plan]
	_mrow(262, "Essential", p.e, MIN.e)
	_mrow(304, "Science", p.s, 0)
	_mrow(346, "Reserve", p.r, MIN.r)
	screws(m)

func _arrow(id: String, r: Rect2, s: String, lr: String) -> void:
	B(r, {"bg":Color("#26363b"), "border":Color.BLACK, "insets":[[2,2,0,Color("#46616a")],[-2,-2,0,Color("#141e21")]]})
	T(F("label"), 16, s, r.position.x, r.position.y, Color("#e6e1d2"), r.size.y, 1, r.size.x)
	hit(id, r, {"locked":not lr.is_empty(), "fixed":fixed("knob"), "focus":false})

func _knob(r: Rect2) -> void:
	var o := r.position
	R(Rect2(o + Vector2(8, 8), Vector2(56, 56)), Color("#0a1114"))
	R(Rect2(o + Vector2(8, 8), Vector2(5, 5)), Color("#5f7a80"))
	R(Rect2(o + Vector2(34, 1), Vector2(4, 6)), Color("#5f7a80"))
	R(Rect2(o + Vector2(59, 8), Vector2(5, 5)), Color("#5f7a80"))
	var ang := deg_to_rad(tween("knob", [-45.0, 0.0, 45.0][plan], 0.25, 3))
	var c := o + Vector2(36, 36)
	draw_set_transform(c, ang)
	for q in [[14,14,44,44,"#3a525a"],[12,20,48,32,"#3a525a"],[20,12,32,48,"#3a525a"],[16,16,20,4,"#5d7a82"],[34,12,4,22,"#fff2b8"]]:
		draw_rect(Rect2(q[0] - 36, q[1] - 36, q[2], q[3]), C(Color(q[4])))
	draw_set_transform(Vector2.ZERO)

func _mrow(y: float, label: String, value: int, minv: int) -> void:
	var bad := isolated() and minv > 0 and value < minv
	var x := 1080.0
	var lx := x
	if minv > 0 and isolated():
		lamp(Vector2(x, y + 2), "warn" if bad else "ok"); lx += 24
	T(F("body"), 16, label, lx, y + 1, UI.TEXT, 20.8)
	T(F("num"), 22, "%d%%" % value, x, y, UI.WARN if bad else UI.PHOS, 22, 2, 166)
	cell_row(Rect2(x, y + 24, 166, 12), cells_on(10, int(roundf(value / 10.0)), UI.WARN if bad else UI.PHOS))
	if minv > 0 and isolated():
		var mx := x + 166 * minv / 100.0 - 1
		draw_rect(Rect2(mx - 1, y + 24 - 4 - 1, 4, 20 + 2), Color.BLACK)
		draw_rect(Rect2(mx, y + 24 - 4, 2, 20), UI.CUE)

# ---------------- bank B controls module
func _paint_trim(st: int) -> void:
	var m := Rect2(712, 424, 548, 280)
	module(m, "Bank B controls")
	var chip_s := ""; var chip_l := ""
	if synced(): chip_s = "Synchronized"; chip_l = "ok"
	elif syncing: chip_s = "Synchronizing"; chip_l = "live"
	elif identified():
		var n := 0
		for k in FKEYS: n += 1 if in_band(k) else 0
		chip_s = "%d of 3 in range" % n; chip_l = "ok" if all_in() else "warn"
	module_chip(m, chip_s, chip_l)
	# scope
	var sg := Rect2(726, 468, 160, 134)
	UI.glass(self, sg)
	_paint_scope(Vector2(728, 472), Rect2(728, 470, 156, 130))
	UI.glass_overlay(self, sg)
	var fcap := F("body")
	var cap_words := "= bank B · dim = banks A and C. Make them overlap."
	_rich_caption(Vector2(726, 608), 160, "Bright", cap_words)
	# faders
	var lr := lock_reason("fader")
	for i in range(3): _fader(FKEYS[i], 898 + i * 84, lr)
	if st == 3: cue(Rect2(898, 468, 246, 205))
	# sync
	var slr := lock_reason("sync")
	var sp := push("sync", 1159, 498, 84, "SYNCED" if synced() else ("MATCH…" if syncing else "SYNC"), "", "done" if synced() else ("working" if syncing else ""), not slr.is_empty(), fixed("sync"), 84, 50, 16, 15, 8 if synced() else prog)
	if st == 4 and not syncing: cue(sp)
	if st == 3:
		var tr := Rect2(1156 + (90 - 90) * 0.5, 498 + 66 + 10, 90, 0)
		var lines := UI.wrap_text(F("body"), 15, "Move all three into the green", 90 - 4 - 8 - 8 - 6)
		tr.size.y = lines.size() * 15 * 1.15 + 12 + 4
		locktag(tr, "Move all three into the green", 15, 6)
	screws(m)

func _rich_caption(p: Vector2, w: float, bold: String, rest: String) -> void:
	var f := F("body"); var lh := 16.8
	var cx := p.x; var cy := p.y
	cx += T(f, 14, bold, cx, cy, UI.PHOS, lh)
	cx += tw(f, 14, " ")
	for word in rest.split(" ", false):
		var ww := tw(f, 14, word)
		if cx + ww > p.x + w + 0.01 and cx > p.x:
			cx = p.x; cy += lh
		T(f, 14, word, cx, cy, Color("#9fb0ae"), lh)
		cx += ww + tw(f, 14, " ")

func _paint_scope(o: Vector2, clip: Rect2) -> void:
	var Wd := 80; var Hd := 64
	var px := func(x: int, y: int, h: int, c: Color):
		var r := Rect2(o.x + x * 2, o.y + y * 2, 2, h * 2).intersection(clip)
		if r.has_area(): draw_rect(r, c)
	var grid := Color("#14382b")
	for x in range(0, Wd, 10):
		for y in range(2, Hd, 10): px.call(x, y, 1, grid)
	for x in range(Wd): px.call(x, 32, 1, grid)
	var wave_fn := func(amp: float, cyc: float, ph: float, col: Color):
		var py := -9999
		for x in range(Wd):
			var y := int(roundf(32 - amp * sin((float(x) / Wd) * cyc * TAU + ph + _scope_t)))
			if py != -9999:
				var a := mini(py, y); var b := maxi(py, y)
				px.call(x, a, maxi(1, b - a), col)
			else: px.call(x, y, 1, col)
			py = y
	wave_fn.call(20.0, 2.0, 0.0, Color("#2f6b55"))
	var amp: float = 20.0 * (1.0 + (float(val.v) - REF.v) / float(REF.v) * 5.0)
	var cyc: float = 2.0 * (1.0 + (float(val.f) - REF.f) / float(REF.f) * 12.0)
	var ph: float = float(val.p) * PI / 180.0
	wave_fn.call(clampf(amp, 3.0, 30.0), cyc, ph, Color("#9cf0c8") if synced() else Color("#d7fff0"))

func _fader(k: String, x: float, lr: String) -> void:
	var id := "fader:" + k
	var f: Dictionary = FD[k]
	x += nudge_dx(id)
	var locked := not lr.is_empty()
	dim = locked
	var fn := F("body")
	T(fn, 16, f.name, x, 468, UI.TEXT, 16, 1, 78)
	T(fn, 14, f.hint, x, 487, Color("#8fa19f"), 14, 1, 78)
	var tr := Rect2(x + 2, 508, 52, 140)
	var pc := func(v: float) -> float: return (1.0 - (v - f.min) / float(f.max - f.min)) * 140.0
	# ticks
	var ty := 0.0
	while ty < 140.0:
		R(Rect2(tr.position.x, tr.position.y + ty, 8, minf(2.0, 140 - ty)), Color("#5f7a80")); ty += 14.0
	var band_top: float = pc.call(f.hi); var band_h: float = pc.call(f.lo) - band_top
	var band := Rect2(tr.position.x + 12, tr.position.y + band_top, 28, band_h)
	R(band, Color(95/255.0, 208/255.0, 103/255.0, 0.22))
	R(Rect2(band.position, Vector2(28, 2)), UI.OK); R(Rect2(band.position.x, band.end.y - 2, 28, 2), UI.OK)
	B(Rect2(tr.position.x + 21, tr.position.y, 10, 140), {"bg":Color("#05090a"), "border":Color.BLACK, "outer":[[0,0,2,Color("#2e444a")]]})
	var cap := Rect2(tr.position.x + 10, tr.position.y + pc.call(val[k]) - 8, 32, 16)
	B(cap, {"grad":[[0.0, Color("#dcd4b6")], [1.0, Color("#a39b7e")]], "border":Color.BLACK, "insets":[[2,2,0,Color("#f6f0da")],[-2,-2,0,Color("#6d6653")]]})
	R(Rect2(cap.position + Vector2(2 + 4, 2 + 5), Vector2(32 - 4 - 8, 2)), Color("#2f8a37") if in_band(k) else Color("#6d6653"))
	lamp(Vector2(tr.position.x + 58, tr.position.y + (band_top + band_h * 0.5) - 9), "ok" if in_band(k) else "warn")
	var v: int = val[k]
	var txt := ("+" if k == "p" and v > 0 else "") + str(v) + ("°" if k == "p" else " " + str(f.unit))
	T(F("num", 700), 22, txt, x, 651, UI.PHOS, 22, 1, 78 - 22)
	if locked: lock_corner(Rect2(x, 468, 78, 205))
	dim = false
	hit(id, Rect2(x, 468, 78, 205), {"locked":locked, "fixed":fixed("fader"), "drag":true, "cursor":Control.CURSOR_VSIZE, "focus_rect":tr})
