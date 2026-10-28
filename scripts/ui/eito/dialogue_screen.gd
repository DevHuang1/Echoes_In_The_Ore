extends "res://scripts/ui/eito/eito_screen.gd"
## Dialogue frame from the design. Two registers: in person (busts, name tab,
## numbered replies) and over comms (handheld channel with a short transcript).
## Pure view: CrewDialogue owns the conversation state and feeds it here.

var d  # CrewDialogue

func setup(owner) -> void:
	d = owner

func paint() -> void:
	if d == null: return
	if d.mode == "ribbon":
		# Below the walk HUD's top-right buttons, centred like the design's ribbon.
		if d.ribbon_text != "": ribbon(Vector2(640, 96), "NEW OBJECTIVE", d.ribbon_text, d.ribbon_t)
		return
	hud(d.objective, "", "Leave conversation")
	if d.mode == "comms": _paint_comms()
	else: _paint_person()

# ------------------------------------------------------------ in person
func _paint_person() -> void:
	var me_speaking: bool = d.speaking == "me"
	var awaiting: bool = d.phase == "choose"
	var them_dim := tween("them_dim", 1.0 if me_speaking else 0.0, 0.2, 2)
	var me_dim := tween("me_dim", 0.0 if (me_speaking or awaiting) else 1.0, 0.2, 2)
	var them_key: String = "bust_" + d.who + ("_dim" if them_dim > 0.5 else "")
	var me_key := "bust_thura" + ("_dim" if me_dim > 0.5 else "")
	draw_texture_rect(UI.tex(them_key), Rect2(12, 440 + 10 * them_dim, 280, 280), false)
	draw_texture_rect(UI.tex(me_key), Rect2(1012, 500 + 10 * me_dim, 220, 220), false)
	# dialogue box: the design's fixed frame; longer story lines grow it upward
	# (bottom edge, text inset and the choice stack's spacing stay the same).
	var f := F("body")
	var lines := UI.wrap_text(f, 25, d.full_text(), 618)
	var n: int = d.reserved_choices()
	var text_bottom := 520.0 + lines.size() * 33.75
	var choices_top := maxf(598.0, text_bottom + 10.5)
	var needed := (choices_top + n * 43.3 + (n - 1) * 6.0 + 11.4) if n > 0 else (text_bottom + 47.0)
	var lift := maxf(0.0, ceilf(needed - 702.0))
	var box := Rect2(300, 486 - lift, 690, 216 + lift)
	UI.box(self, box, {"notch":true, "bg":UI.VOICE, "border":Color("#07050a"), "insets":[[0,0,2,UI.VOICE_HI],[0,0,6,UI.VOICE],[0,0,8,Color("#6e5b86")]]})
	hit("dbox", box, {"focus":false})
	var text: String = d.visible_text()
	# Typewriter: wrap the full line first so words never jump between rows.
	var shown := text.length()
	var y := 520.0 - lift
	for l in lines:
		var part := l.substr(0, maxi(0, shown))
		if not part.is_empty(): T(f, 25, part, 336, y, UI.VOICE_INK, 33.75)
		shown -= l.length() + 1
		y += 33.75
	if d.show_more():
		var c := Color("#b9a8cf"); c.a = blink(1.0)
		var fm := F("label")
		var s := "CLICK ▸"
		T(fm, 14, s, 968 - tw(fm, 14, s), 670, c, 18)
	# name tab
	_name_tab(me_speaking, 452 - lift)
	if awaiting: _choices(Rect2(336, choices_top - lift, 618, 0))

func _name_tab(you: bool, top: float) -> void:
	var fb := F("body", 700); var fs := F("label", 400, 0.65)
	var name: String = "Thura" if you else d.display_name
	var tag: String = "YOU" if you else d.tag
	var w := 2 + 16 + tw(fb, 22, name) + (10 + tw(fs, 13, tag) if not tag.is_empty() else 0.0) + 16 + 2
	var h := 2 + 6 + 28.6 + 4 + 2
	var x := 1280.0 - 314 - w if you else 324.0
	var r := Rect2(x, top, w, h)
	var grad := [[0.0, Color("#b9d7e0")], [1.0, Color("#8fb2bd")]] if you else [[0.0, Color("#efd9a6")], [1.0, Color("#cdb27a")]]
	var ins := [[2,2,0,Color("#e3f4f8")],[-2,-2,0,Color("#5d7d87")]] if you else [[2,2,0,Color("#fff0c8")],[-2,-2,0,Color("#9e8653")]]
	UI.box(self, r, {"notch":true, "grad":grad, "border":Color("#07050a"), "insets":ins})
	var base := roundf(UI.baseline(fb, 22, r.position.y + 2 + 6, 28.6))
	UI.run(self, fb, 22, name, Vector2(r.position.x + 2 + 16, base), Color("#1d1626"))
	if not tag.is_empty():
		UI.run(self, fs, 13, tag, Vector2(roundf(r.position.x + 2 + 16 + tw(fb, 22, name) + 10), base), Color("#5b4a2e"))

func _choices(area: Rect2) -> void:
	var y := area.position.y
	for i in range(d.choices.size()):
		var r := Rect2(area.position.x, y, area.size.x, 43.3)
		var id := "choice:%d" % i
		var hot := hover == id or (kb and focus == id)
		UI.box(self, r, {"bg":Color("#3d3150") if hot else Color("#2c2338"), "border":UI.CUE if hot else Color("#4a3d5c")})
		var key := str(i + 1) if d.choices[i].get("key", "").is_empty() else str(d.choices[i].key)
		var kw := kbd(r.position.x + 2 + 12, r.position.y + (43.3 - 22) * 0.5, key, 26, 22)
		T(F("body"), 21, str(d.choices[i].label), r.position.x + 2 + 12 + kw + 12, r.position.y + 2 + 6, UI.VOICE_INK, 27.3)
		hit(id, r)
		y += 43.3 + 6

# ------------------------------------------------------------ comms device
func _paint_comms() -> void:
	var dev := Rect2(360, 96, 560, 520)
	UI.box(self, dev, {"notch":true, "grad":[[0.0, Color("#2b2236")], [1.0, Color("#1d1726")]], "border":Color("#05040a"), "insets":[[2,2,0,Color("#4a3d5c")],[-2,-2,0,Color("#110d17")]]})
	var face := Rect2(380, 116, 112, 112)
	UI.glass(self, face)
	draw_texture_rect(UI.tex("face_" + d.who), face.grow(-2), false)
	UI.glass_overlay(self, face)
	var fb := F("body", 700)
	var idx := 508.0
	T(fb, 28, d.display_name, idx, 139, UI.TEXT, 36.4)
	var fs := F("label", 400, 0.7)
	var sw := T(fs, 14, "SHIP COMMS · CHANNEL OPEN", idx, 185, Color("#b9a8cf"), 18)
	wave(Vector2(idx + sw, 185))
	var gr := Rect2(810, 127, 90, 90)
	draw_rect(gr, Color.BLACK)
	var gy := 0.0
	while gy < 86.0:
		draw_rect(Rect2(812, 129 + gy, 86, minf(4.0, 86 - gy)), Color("#0c0910"))
		if gy + 4 < 86: draw_rect(Rect2(812, 129 + gy + 4, 86, minf(4.0, 86 - gy - 4)), Color("#3a3047"))
		gy += 8.0
	# reply area grows with the number of replies; the transcript takes the rest
	var n: int = d.choices.size() if d.phase == "choose" else 0
	var reply_h := maxf(84.0, n * 43.3 + maxf(0, n - 1) * 6.0)
	var log_r := Rect2(380, 242, 520, 520 - 4 - 36 - 112 - 14 - 14 - reply_h)
	UI.box(self, log_r, {"bg":Color("#120e18"), "border":Color.BLACK, "insets":[[2,2,0,Color.BLACK]]})
	hit("log", log_r, {"focus":false, "cursor":Control.CURSOR_ARROW})
	var clip := log_r.grow(-2)
	var bottom := log_r.end.y - 2 - 12
	var f := F("body"); var fsm := F("label", 400, 0.65)
	var maxw := (520.0 - 4 - 24) * 0.8
	for i in range(d.transcript.size() - 1, -1, -1):
		var m: Dictionary = d.transcript[i]
		var full: String = m.text
		var lines := UI.wrap_text(f, 21, full, maxw - 28 - 4)
		var tw_max := tw(fsm, 13, m.name)
		for l in lines: tw_max = maxf(tw_max, tw(f, 21, l))
		# shrink-to-fit: a wrapped message takes the whole max-width, like the browser
		var w := maxw if lines.size() > 1 else minf(maxw, tw_max + 28 + 4)
		var h := 2 + 10 + 16 + 2 + lines.size() * 27.3 + 10 + 2
		var top := bottom - h
		var mine: bool = m.who == "me"
		var x := (log_r.end.x - 2 - 12 - w) if mine else (log_r.position.x + 2 + 12)
		var t := clampf((now - float(m.t0)) / 0.3, 0, 1)
		var p := floorf(t * 3) / 3.0 if t < 1.0 else 1.0
		var r := Rect2(x, top + 40 * (1.0 - p), w, h)
		bottom = top - 10
		if r.end.y < clip.position.y: break
		var a := p
		var bg := Color("#26414a") if mine else Color("#3b3049")
		var hi := Color("#3d6670") if mine else Color("#574870")
		_clipped_box(r, clip, bg, hi, a)
		var sc := Color("#bfe0e6") if mine else Color("#cbbfe0")
		var shown: int = int(m.get("shown", full.length()))
		_clip_text(fsm, 13, m.name, r.position.x + 2 + 14, r.position.y + 2 + 10, Color(sc, a), 16, clip)
		var ly := r.position.y + 2 + 10 + 16 + 2
		for l in lines:
			var part := l.substr(0, maxi(0, shown))
			if not part.is_empty(): _clip_text(f, 21, part, r.position.x + 2 + 14, ly, Color(UI.TEXT, a), 27.3, clip)
			shown -= l.length() + 1
			ly += 27.3
		if top < clip.position.y: break
	if d.phase == "choose": _choices(Rect2(380, log_r.end.y + 14, 520, 0))

func _clipped_box(r: Rect2, clip: Rect2, bg: Color, hi: Color, a: float) -> void:
	var rr := r.intersection(clip)
	if not rr.has_area(): return
	draw_rect(rr, Color(Color.BLACK, a))
	var inner := r.grow(-2).intersection(clip)
	if inner.has_area(): draw_rect(inner, Color(bg, a))
	for piece in [Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 2)), Rect2(r.position + Vector2(2, 2), Vector2(2, r.size.y - 4))]:
		var q: Rect2 = piece.intersection(clip)
		if q.has_area(): draw_rect(q, Color(hi, a))

func _clip_text(f: Font, sz: int, s: String, x: float, top: float, c: Color, lh: float, clip: Rect2) -> void:
	if top + lh < clip.position.y or top > clip.end.y: return
	if top < clip.position.y: return
	T(f, sz, s, x, top, c, lh)

# ------------------------------------------------------------ input
func on_click(id: String, _event) -> void:
	if d == null: return
	if id == "esc": d.cancel_dialogue(); return
	if id == "dbox" or id == "log": d.advance(); return
	if id.begins_with("choice:"): d.pick(int(id.get_slice(":", 1)))
