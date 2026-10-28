@tool
extends RefCounted
## Echoes in the Ore interface kit: palette, fonts, generated pixel sprites and
## the CSS-like box painter shared by every redesigned screen. Everything here is
## a straight port of "Echoes in the Ore UI" (interface proposal 01).

# ---------------------------------------------------------------- palette
const VOID := Color("#090d0f")
const BULK := Color("#101a1e")
const HULL_LO := Color("#0e1619")
const HULL := Color("#1b292e")
const HULL_2 := Color("#25373d")
const HULL_HI := Color("#405b62")
const EDGE := Color("#05090b")
const LABEL := Color("#a9c4c2")
const GLASS := Color("#04100c")
const GLASS_2 := Color("#0b1f18")
const PHOS := Color("#9cf0c8")
const PHOS_DIM := Color("#4c8f74")
const PHOS_FAINT := Color("#1a382d")
const PAPER := Color("#d9d1b5")
const PAPER_HI := Color("#efe9d3")
const PAPER_LO := Color("#b2a98a")
const INK := Color("#1f2629")
const INK_2 := Color("#565b50")
const OK := Color("#5fd067")
const WARN := Color("#f0b23a")
const FAULT := Color("#e5533d")
const LIVE := Color("#62d0f0")
const WATER := Color("#2f7fd0")
const WATER_HI := Color("#a6dcff")
const CUE := Color("#fff2b8")
const VOICE := Color("#201a2a")
const VOICE_HI := Color("#3b3049")
const VOICE_INK := Color("#f3ead6")
const TEXT := Color("#e6e1d2")

const FONT_DIR := "res://art/ui/fonts/"

# ---------------------------------------------------------------- fonts
static var _fonts := {}
static var _base := {}

static func _try_load(paths: Array) -> Font:
	for p in paths:
		if ResourceLoader.exists(p):
			var f = load(p)
			if f is Font: return f
	return null

static func _base_font(kind: String, weight: int) -> Font:
	var key := kind + str(weight)
	if _base.has(key): return _base[key]
	var f: Font = null
	match kind:
		"body":
			var variable := _try_load([FONT_DIR+"PixelifySans-VariableFont_wght.ttf", FONT_DIR+"PixelifySans[wght].ttf"])
			if variable != null:
				var v := FontVariation.new(); v.base_font = variable
				v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
				f = v
			else:
				var names := {400:"Regular",500:"Medium",600:"SemiBold",700:"Bold"}
				var n: String = names.get(weight, "Regular")
				f = _try_load([FONT_DIR+"static/PixelifySans-"+n+".ttf", FONT_DIR+"PixelifySans-"+n+".ttf"])
				if f == null:
					# Bundled fallback: the Medium cut, emboldened for the heavier weights.
					var medium := _try_load([FONT_DIR+"PixelifySans-Medium.ttf"])
					var e := FontVariation.new(); e.base_font = medium
					e.variation_embolden = {400:-0.12,500:0.0,600:0.45,700:0.8}.get(weight, 0.0)
					f = e
		"label":
			f = _try_load([FONT_DIR+("Silkscreen-Bold.ttf" if weight >= 700 else "Silkscreen-Regular.ttf"), FONT_DIR+"Silkscreen-Regular.ttf"])
		"num":
			f = _try_load([FONT_DIR+"VT323-Regular.ttf", FONT_DIR+"VT323.ttf"])
			if f == null:
				# VT323 not installed yet: a condensed system monospace keeps the layout honest.
				var sys := SystemFont.new(); sys.font_names = PackedStringArray(["VT323", "DejaVu Sans Mono", "Consolas", "Courier New", "monospace"])
				var c := FontVariation.new(); c.base_font = sys
				c.variation_transform = Transform2D(Vector2(0.78, 0), Vector2(0, 1), Vector2.ZERO)
				f = c
			if weight >= 700:
				var b := FontVariation.new(); b.base_font = f; b.variation_embolden = 0.6; f = b
	if f == null: f = ThemeDB.fallback_font
	if kind == "body":
		# Pixelify Sans' "fi"/"fl" ligatures read as "A" at this size ("Aow", "Arst").
		var nl := FontVariation.new(); nl.base_font = f
		var ts := TextServerManager.get_primary_interface()
		nl.opentype_features = {ts.name_to_tag("liga"): 0, ts.name_to_tag("clig"): 0}
		f = nl
	_base[key] = f
	return f

## kind: "body" (Pixelify Sans), "label" (Silkscreen), "num" (VT323).
## spacing: CSS letter-spacing in (fractional) pixels. Godot only spaces glyphs by
## whole pixels, so spaced text is laid out glyph by glyph in text()/tw().
static func font(kind: String, weight := 400, spacing := 0.0) -> Font:
	var key := "%s|%d|%.3f" % [kind, weight, spacing]
	if _fonts.has(key): return _fonts[key]
	var f := _base_font(kind, weight)
	if not is_zero_approx(spacing):
		var s := FontVariation.new(); s.base_font = f
		s.set_meta("ls", spacing)
		f = s
	_fonts[key] = f
	return f

static func ls_of(f: Font) -> float:
	return float(f.get_meta("ls", 0.0)) if f.has_meta("ls") else 0.0

static func has_real_num_font() -> bool:
	return ResourceLoader.exists(FONT_DIR+"VT323-Regular.ttf") or ResourceLoader.exists(FONT_DIR+"VT323.ttf")

# ---------------------------------------------------------------- text
static func tw(f: Font, size: int, s: String) -> float:
	var ls := ls_of(f)
	if is_zero_approx(ls): return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var w := 0.0
	for i in range(s.length()): w += f.get_char_size(s.unicode_at(i), size).x + ls
	return w

## Draws a run at a baseline, honouring fractional letter-spacing.
static func run(ci, f: Font, size: int, s: String, pos: Vector2, color: Color) -> void:
	var ls := ls_of(f)
	if is_zero_approx(ls):
		ci.draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color); return
	var x := pos.x
	for i in range(s.length()):
		var c := s.unicode_at(i)
		ci.draw_char(f, Vector2(roundf(x), pos.y), String.chr(c), size, color)
		x += f.get_char_size(c, size).x + ls

## Baseline for text set in a CSS line box of height lh whose top is `top`.
static func baseline(f: Font, size: int, top: float, lh: float = -1.0) -> float:
	var a := f.get_ascent(size); var d := f.get_descent(size)
	if lh < 0: lh = a + d
	return top + (lh - (a + d)) * 0.5 + a

static func text(ci, f: Font, size: int, s: String, x: float, top: float, color: Color, lh: float = -1.0, align := 0, width := 0.0) -> float:
	var w := tw(f, size, s)
	var px := x
	if align == 1: px = x + (width - w) * 0.5
	elif align == 2: px = x + width - w
	run(ci, f, size, s, Vector2(roundf(px), roundf(baseline(f, size, top, lh))), color)
	return w

static func wrap_text(f: Font, size: int, s: String, width: float) -> PackedStringArray:
	var out := PackedStringArray()
	for para in s.split("\n"):
		var words := para.split(" ", false)
		var line := ""
		for word in words:
			var trial := word if line.is_empty() else line + " " + word
			if line.is_empty() or tw(f, size, trial) <= width + 0.01: line = trial
			else:
				out.append(line); line = word
		out.append(line)
	return out

## CSS text-wrap: balance. Same line count as greedy wrapping, narrowest width.
static func wrap_balanced(f: Font, size: int, s: String, width: float) -> PackedStringArray:
	var lines := wrap_text(f, size, s, width)
	if lines.size() <= 1: return lines
	var lo := 0.0; var hi := width
	for i in range(14):
		var mid := (lo + hi) * 0.5
		if wrap_text(f, size, s, mid).size() > lines.size(): lo = mid
		else: hi = mid
	return wrap_text(f, size, s, hi)

static func paragraph(ci, f: Font, size: int, s: String, x: float, top: float, width: float, lh: float, color: Color, balanced := false, align := 0) -> int:
	var lines := wrap_balanced(f, size, s, width) if balanced else wrap_text(f, size, s, width)
	for i in range(lines.size()):
		text(ci, f, size, lines[i], x, top + i * lh, color, lh, align, width)
	return lines.size()

# ---------------------------------------------------------------- colour maths
static func hexa(h: String, a: float) -> Color:
	var c := Color(h); c.a = a; return c

static func over(base: Color, top: Color) -> Color:
	var a := top.a + base.a * (1.0 - top.a)
	if a <= 0.0: return Color(0, 0, 0, 0)
	return Color((top.r * top.a + base.r * base.a * (1.0 - top.a)) / a, (top.g * top.a + base.g * base.a * (1.0 - top.a)) / a, (top.b * top.a + base.b * base.a * (1.0 - top.a)) / a, a)

## CSS filter: saturate(s) brightness(b), in sRGB like the browser.
static func filt(c: Color, sat: float, bright: float) -> Color:
	var r := (0.213 + 0.787 * sat) * c.r + (0.715 - 0.715 * sat) * c.g + (0.072 - 0.072 * sat) * c.b
	var g := (0.213 - 0.213 * sat) * c.r + (0.715 + 0.285 * sat) * c.g + (0.072 - 0.072 * sat) * c.b
	var b := (0.213 - 0.213 * sat) * c.r + (0.715 - 0.715 * sat) * c.g + (0.072 + 0.928 * sat) * c.b
	return Color(clampf(r * bright, 0, 1), clampf(g * bright, 0, 1), clampf(b * bright, 0, 1), c.a)

static func filt_image(src: Image, sat: float, bright: float) -> Image:
	var img := src.duplicate() as Image
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			img.set_pixel(x, y, filt(img.get_pixel(x, y), sat, bright))
	return img

# ---------------------------------------------------------------- box painter
## Paints a CSS box: outer shadows, background colour, vertical gradient, tiled
## texture, 2px border and inset shadows, optionally clipped by the stepped
## "--notch" clip-path. Options:
##   notch: bool, bg: Color, grad: [[t, Color], ...] (top->bottom),
##   hgrad: [[t, Color], ...] (left->right), tex: Texture2D (tiled from the padding box),
##   border: Color, bw: int, insets: [[dx, dy, spread, Color], ...], outer: same shape.
static func box(ci, r: Rect2, o: Dictionary) -> void:
	var notch: bool = o.get("notch", false)
	var clips := notch_strips(r) if notch else [r]
	var bw: int = o.get("bw", 2 if o.has("border") else 0)
	if not notch:
		for s in o.get("outer", []):
			var sr := Rect2(r.position + Vector2(s[0], s[1]) - Vector2(s[2], s[2]), r.size + Vector2(s[2], s[2]) * 2)
			for piece in subtract(sr, r): ci.draw_rect(piece, s[3])
	var pad := r.grow(-bw)
	if o.has("bg"): fill(ci, r, clips, o.bg)
	if o.has("grad"): fill_grad(ci, r, clips, pad, o.grad, true)
	if o.has("hgrad"): fill_grad(ci, r, clips, pad, o.hgrad, false)
	if o.has("tex"):
		# Tiled from the padding box; tiles are cut by hand so it also works on
		# canvas items without texture repeat (theme styleboxes).
		var t: Texture2D = o.tex
		var ts := t.get_size()
		for c in clips:
			var d: Rect2 = (c as Rect2).intersection(r)
			if not d.has_area(): continue
			var ty := floorf((d.position.y - pad.position.y) / ts.y)
			while pad.position.y + ty * ts.y < d.end.y:
				var tx := floorf((d.position.x - pad.position.x) / ts.x)
				while pad.position.x + tx * ts.x < d.end.x:
					var tile := Rect2(pad.position + Vector2(tx, ty) * ts, ts).intersection(d)
					if tile.has_area():
						ci.draw_texture_rect_region(t, tile, Rect2(tile.position - pad.position - Vector2(tx, ty) * ts, tile.size))
					tx += 1.0
				ty += 1.0
	if o.has("border") and bw > 0:
		for piece in subtract(r, pad): fill(ci, piece, clips, o.border)
	var ins: Array = o.get("insets", [])
	for i in range(ins.size() - 1, -1, -1):
		var s: Array = ins[i]
		var inner := Rect2(pad.position + Vector2(s[0], s[1]) + Vector2(s[2], s[2]), pad.size - Vector2(s[2], s[2]) * 2)
		for piece in subtract(pad, inner): fill(ci, piece, clips, s[3])

static func notch_strips(r: Rect2) -> Array:
	var x := r.position.x; var y := r.position.y; var w := r.size.x; var h := r.size.y
	return [Rect2(x+6, y, w-12, 2), Rect2(x+4, y+2, w-8, 2), Rect2(x+2, y+4, w-4, 2), Rect2(x, y+6, w, h-12),
		Rect2(x+2, y+h-6, w-4, 2), Rect2(x+4, y+h-4, w-8, 2), Rect2(x+6, y+h-2, w-12, 2)]

static func fill(ci, r: Rect2, clips: Array, c: Color) -> void:
	for clip in clips:
		var d: Rect2 = r.intersection(clip)
		if d.has_area(): ci.draw_rect(d, c)

static func grad_at(stops: Array, t: float) -> Color:
	if t <= stops[0][0]: return stops[0][1]
	for i in range(1, stops.size()):
		if t <= stops[i][0]:
			var a: Array = stops[i-1]; var b: Array = stops[i]
			var span: float = b[0] - a[0]
			return b[1] if span <= 0.0 else (a[1] as Color).lerp(b[1], (t - a[0]) / span)
	return stops[-1][1]

## Gradient sized to the padding box (CSS background-origin) but painted under
## the border too, exactly like the browser's default background-clip.
static func fill_grad(ci, r: Rect2, clips: Array, pad: Rect2, stops: Array, vertical: bool) -> void:
	var p0 := pad.position.y if vertical else pad.position.x
	var plen := pad.size.y if vertical else pad.size.x
	var cuts := [r.position.y if vertical else r.position.x, r.end.y if vertical else r.end.x]
	for s in stops:
		cuts.append(p0 + float(s[0]) * plen)
	cuts.sort()
	for clip in clips:
		var d: Rect2 = r.intersection(clip)
		if not d.has_area(): continue
		var a0 := d.position.y if vertical else d.position.x
		var a1 := d.end.y if vertical else d.end.x
		var pts := [a0]
		for c in cuts:
			if c > a0 and c < a1: pts.append(c)
		pts.append(a1)
		for i in range(pts.size() - 1):
			var u0: float = pts[i]; var u1: float = pts[i+1]
			if u1 - u0 <= 0.0: continue
			var c0 := grad_at(stops, (u0 - p0) / plen); var c1 := grad_at(stops, (u1 - p0) / plen)
			var q: PackedVector2Array
			if vertical: q = PackedVector2Array([Vector2(d.position.x, u0), Vector2(d.end.x, u0), Vector2(d.end.x, u1), Vector2(d.position.x, u1)])
			else: q = PackedVector2Array([Vector2(u0, d.position.y), Vector2(u1, d.position.y), Vector2(u1, d.end.y), Vector2(u0, d.end.y)])
			var cs := PackedColorArray([c0, c0, c1, c1]) if vertical else PackedColorArray([c0, c1, c1, c0])
			ci.draw_polygon(q, cs)

static func subtract(outer: Rect2, inner: Rect2) -> Array:
	var o := outer; var i := inner.intersection(outer)
	if not i.has_area(): return [o] if o.has_area() else []
	var out := []
	if i.position.y > o.position.y: out.append(Rect2(o.position.x, o.position.y, o.size.x, i.position.y - o.position.y))
	if i.end.y < o.end.y: out.append(Rect2(o.position.x, i.end.y, o.size.x, o.end.y - i.end.y))
	if i.position.x > o.position.x: out.append(Rect2(o.position.x, i.position.y, i.position.x - o.position.x, i.size.y))
	if i.end.x < o.end.x: out.append(Rect2(i.end.x, i.position.y, o.end.x - i.end.x, i.size.y))
	return out

# ---------------------------------------------------------------- material presets
static func metal_module(ci, r: Rect2) -> void:
	box(ci, r, {"notch":true, "bg":HULL, "grad":[[0.0, HULL_2], [1.0, HULL]], "tex":tex("noise"), "border":EDGE, "insets":[[2,2,0,HULL_HI],[-2,-2,0,HULL_LO]]})

static func bezel(ci, r: Rect2) -> void:
	box(ci, r, {"notch":true, "grad":[[0.0, Color("#34494f")], [1.0, Color("#22333a")]], "border":EDGE, "insets":[[2,2,0,Color("#557178")],[-2,-2,0,Color("#141e22")]]})

static func paper(ci, r: Rect2) -> void:
	box(ci, r, {"notch":true, "bg":PAPER, "tex":tex("paper"), "border":Color("#6f6750"), "insets":[[2,2,0,PAPER_HI],[-2,-2,0,PAPER_LO]]})

## Glass screen body (radial phosphor gradient + inner bevel). Call glass_overlay
## after drawing the screen contents for the scanlines and sheen.
static func glass(ci, r: Rect2) -> void:
	ci.draw_texture_rect(radial_texture(), Rect2(r.position + Vector2(2, 2), r.size - Vector2(4, 4)), false)
	box(ci, r, {"border":Color.BLACK, "insets":[[0,0,2,Color("#12271f")],[6,6,0,Color(0,0,0,0.35)]]})

static func glass_overlay(ci, r: Rect2) -> void:
	var p := r.grow(-2)
	var y := p.position.y + 2.0
	var dark := Color(0, 0, 0, 0.13)
	while y < p.end.y:
		ci.draw_rect(Rect2(p.position.x, y, p.size.x, minf(2.0, p.end.y - y)), dark)
		y += 4.0
	ci.draw_texture_rect(sheen_texture(), p, false)

# ---------------------------------------------------------------- generated textures
static var _tex := {}

static func tex(name: String) -> Texture2D:
	if _tex.is_empty(): _build()
	return _tex.get(name)

static func has_tex(name: String) -> bool:
	if _tex.is_empty(): _build()
	return _tex.has(name)

## Mulberry32, bit-exact with the JavaScript generator in the design.
class Rng:
	var s := 0
	func _init(seed: int) -> void: s = seed
	static func i32(x: int) -> int:
		x = x & 0xFFFFFFFF
		return x - 0x100000000 if x >= 0x80000000 else x
	static func imul(a: int, b: int) -> int:
		a = a & 0xFFFFFFFF; b = b & 0xFFFFFFFF
		return i32((a & 0xFFFF) * b + ((((a >> 16) * b) & 0xFFFF) << 16))
	func next() -> float:
		s = i32(s + 0x6D2B79F5)
		var t := imul(s ^ ((s & 0xFFFFFFFF) >> 15), 1 | s)
		t = i32(t + imul(t ^ ((t & 0xFFFFFFFF) >> 7), 61 | t)) ^ t
		return float(((t ^ ((t & 0xFFFFFFFF) >> 14)) & 0xFFFFFFFF)) / 4294967296.0

static func _blend(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, mini(y + h, img.get_height())):
		for xx in range(x, mini(x + w, img.get_width())):
			img.set_pixel(xx, yy, over(img.get_pixel(xx, yy), c))

static func spr_image(rows: Array, pal: Dictionary) -> Image:
	var h := rows.size(); var w := 0
	for row in rows: w = maxi(w, row.length())
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var row: String = rows[y]
		for x in range(row.length()):
			var ch := row[x]
			if pal.has(ch): img.set_pixel(x, y, Color(pal[ch]))
	return img

static func _scaled(img: Image, k: int) -> ImageTexture:
	var c := img.duplicate() as Image
	c.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(c)

const M := {
	"screw":[".dddd.","dhhhmd","dhkmmd","dmmkmd","dmmmkd",".dddd."],
	"lock":["..kkk..",".kyyyk.",".yk.ky.","kkkkkkk","kyyyyyk","kyykyyk","kyykyyk","kkkkkkk"],
	"circ":["..xxxxx..",".xxhhxxx.","xxhhxxxxx","xxhxxxxxx","xxxxxxxxx","xxxxxxxxx","xxxxxxxxs",".xxxxxxs.","..xxxss.."],
	"tri":["....x....","...xxx...","...xkx...","..xxkxx..","..xxkxx..",".xxxxxxx.",".xxxkxxx.","xxxxxxxxx"],
	"sq":["xxxxxxxxx","xkxxxxxkx","xxkxxxkxx","xxxkxkxxx","xxxxkxxxx","xxxkxkxxx","xxkxxxkxx","xkxxxxxkx","xxxxxxxxx"],
	"dia":["....x....","...xxx...","..xxhxx..",".xxhxxxx.","xxxxxxxxx",".xxxxxxx.","..xxxxx..","...xxx...","....x...."],
	"check":["......x",".....xx","x...xx.","xx.xx..",".xxx...","..x...."],
	"heart":[".xx...xx.","xxxx.xxxx","xxxxxxxxx","xxxxxxxxx",".xxxxxxx.","..xxxxx..","...xxx...","....x...."],
	"flask":["..xxxxx..","...x.x...","...x.x...","..x...x..",".x.....x.","x.xxxxx.x","xxxxxxxxx","xxxxxxxxx"],
	"batt":["xxxxxxxx.","x......xx","x.xxxx.xx","x.xxxx.xx","x......xx","xxxxxxxx."],
	"bolt":["...xxxx","..xxxx.","..xxx..",".xxx...","xxxxxx.","...xxx.","..xxx..","..xx...",".xx....",".x....."],
	"person":["..xxx..","..xxx..","..xxx..","...x...",".xxxxx.","x.xxx.x","..x.x..","..x.x.."],
	"plant":["....g.....","...gGg....","g..gGg..g.","gg..g..gg.",".gG.g.Gg..","..gGgGg...","....g.....","....g.....","...ggg....","..g.g.g..."],
	"droop":["..........","......y...",".....yg...","..y...g...",".yg...g.y.","g.....g..y",".g....g.g.","..g...gg..","...gggg...","....g....."],
}

static var _img := {}

static func img(name: String) -> Image:
	if _tex.is_empty(): _build()
	return _img.get(name)

static func _reg(name: String, image: Image, scale := 1) -> void:
	_img[name] = image
	_tex[name] = _scaled(image, scale) if scale > 1 else ImageTexture.create_from_image(image)

static func _build() -> void:
	_tex["__"] = null
	_reg("screw", spr_image(M.screw, {"d":"#071013","m":"#5e777b","h":"#9db3b4","k":"#26353a"}), 2)
	_reg("lock", spr_image(M.lock, {"k":"#0b0e10","y":"#e8e2c8"}), 2)
	_reg("lockA", spr_image(M.lock, {"k":"#2a1a00","y":"#f0b23a"}), 2)
	var lamps := {
		"ok": spr_image(M.circ, {"x":"#47b851","h":"#b9f2b4","s":"#2a7a33"}),
		"warn": spr_image(M.tri, {"x":"#f0b23a","k":"#2b1b00"}),
		"fault": spr_image(M.sq, {"x":"#e5533d","k":"#2b0906"}),
		"live": spr_image(M.dia, {"x":"#4bc3ea","h":"#d8f6ff"}),
		"off": spr_image(M.circ, {"x":"#2b3c41","h":"#3f565c","s":"#1c282c"}),
	}
	var glow := {"ok":Color(95/255.0,208/255.0,103/255.0,0.55), "warn":Color(240/255.0,178/255.0,58/255.0,0.55), "fault":Color(229/255.0,83/255.0,61/255.0,0.55), "live":Color(98/255.0,208/255.0,240/255.0,0.6)}
	for k in lamps:
		_reg("l_"+k, lamps[k], 2)
		_reg("l_"+k+"_dim", filt_image(lamps[k], 0.2, 0.6), 2)
		if glow.has(k):
			_tex["g_"+k] = _glow(lamps[k], 2, glow[k], 1.5)
			_tex["g_"+k+"_dim"] = _glow(lamps[k], 2, filt(glow[k], 0.2, 0.6), 1.5)
	_reg("lockA_dim", filt_image(_img["lockA"], 0.2, 0.6), 2)
	_reg("check", spr_image(M.check, {"x":"#2f7a37"}))
	var P := {"x":"#9cf0c8"}
	for k in ["heart","flask","batt","bolt"]: _reg(k, spr_image(M[k], P))
	_reg("person", spr_image(M.person, {"x":"#3a3f38"}))
	_reg("personM", spr_image(M.person, {"x":"#8a4d00"}))
	_reg("plant", spr_image(M.plant, {"g":"#3f9a4a","G":"#8fdc7a"}))
	_reg("droop", spr_image(M.droop, {"g":"#6f8a3a","y":"#c9b04a"}))
	# Surface textures: 64x64 generated, displayed at 128x128 with nearest filtering.
	var r := Rng.new(7)
	var noise := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	for i in range(240):
		var c := Color(1, 1, 1, 0.035) if r.next() < 0.5 else Color(0, 0, 0, 0.09)
		var x := int(r.next() * 64); var y := int(r.next() * 64)
		_blend(noise, x, y, 1, 1, c)
	for i in range(5):
		var x := int(r.next() * 64); var y := int(r.next() * 64); var w := 3 + int(r.next() * 6)
		_blend(noise, x, y, w, 1, Color(1, 1, 1, 0.03))
	_reg("noise", noise, 2)
	var pt := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	for i in range(300):
		var c := Color(1, 1, 1, 0.08) if r.next() < 0.5 else Color(90/255.0, 70/255.0, 30/255.0, 0.07)
		var x := int(r.next() * 64); var y := int(r.next() * 64); var w := 1 + int(r.next() * 2)
		_blend(pt, x, y, w, 1, c)
	_reg("paper", pt, 2)
	for who in WHO:
		_reg("face_"+who, portrait(who, false))
		_reg("bust_"+who, portrait(who, true))
		_reg("bust_"+who+"_dim", filt_image(portrait(who, true), 0.6, 0.45))

static func _glow(src: Image, scale: int, color: Color, sigma: float) -> ImageTexture:
	var pad := 6
	var w := src.get_width() * scale + pad * 2; var h := src.get_height() * scale + pad * 2
	var a := PackedFloat32Array(); a.resize(w * h)
	for y in range(src.get_height() * scale):
		for x in range(src.get_width() * scale):
			a[(y + pad) * w + x + pad] = src.get_pixel(x / scale, y / scale).a
	var k := []
	var rad := int(ceil(sigma * 3)); var sum := 0.0
	for i in range(-rad, rad + 1):
		var v := exp(-(i * i) / (2.0 * sigma * sigma)); k.append(v); sum += v
	for i in range(k.size()): k[i] /= sum
	var t := PackedFloat32Array(); t.resize(w * h)
	for y in range(h):
		for x in range(w):
			var acc := 0.0
			for i in range(-rad, rad + 1):
				var xx := clampi(x + i, 0, w - 1); acc += a[y * w + xx] * k[i + rad]
			t[y * w + x] = acc
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var acc := 0.0
			for i in range(-rad, rad + 1):
				var yy := clampi(y + i, 0, h - 1); acc += t[yy * w + x] * k[i + rad]
			out.set_pixel(x, y, Color(color.r, color.g, color.b, clampf(acc * color.a, 0, 1)))
	return ImageTexture.create_from_image(out)

static var _radial: Texture2D
static func radial_texture() -> Texture2D:
	# radial-gradient(120% 90% at 50% 40%, glass-2, glass 75%) is resolution
	# independent, so one 256x256 sample stretched over each screen is exact enough.
	if _radial != null: return _radial
	var n := 256
	var im := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in range(n):
		for x in range(n):
			var u := (x + 0.5) / n; var v := (y + 0.5) / n
			var d := sqrt(pow((u - 0.5) / 1.2, 2) + pow((v - 0.4) / 0.9, 2))
			im.set_pixel(x, y, GLASS_2.lerp(GLASS, clampf(d / 0.75, 0, 1)))
	_radial = ImageTexture.create_from_image(im)
	return _radial

static var _sheen: Texture2D
static func sheen_texture() -> Texture2D:
	if _sheen != null: return _sheen
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.035)); g.set_color(1, Color(1, 1, 1, 0))
	g.set_offset(1, 0.35)
	var t := GradientTexture2D.new(); t.gradient = g; t.width = 128; t.height = 128
	# 160deg: towards the bottom, slightly left.
	t.fill_from = Vector2(0.33, 0.0); t.fill_to = Vector2(0.67, 1.0)
	_sheen = t
	return _sheen

# ---------------------------------------------------------------- portraits (32x32)
const WHO := {
	"amara":{"skin":"#b97a52","sk2":"#8e5a3a","hair":"#1e1512","hh":"#3a2a22","uni":"#3f7a4a","uh":"#5f9c66","style":"bun","bg":"#16241f"},
	"maya":{"skin":"#e0b48e","sk2":"#b68866","hair":"#2a2420","hh":"#4a3e36","uni":"#3a4f7a","uh":"#5a73a6","style":"short","bg":"#161b26"},
	"leila":{"skin":"#c99a72","sk2":"#9f7353","hair":"#4a2a1c","hh":"#6e4430","uni":"#8a5a2a","uh":"#b07c42","style":"long","bg":"#221a14"},
	"thura":{"skin":"#c98d62","sk2":"#a06c48","hair":"#17110e","hh":"#2e231c","uni":"#2f5f78","uh":"#4b85a0","style":"crop","bg":"#13202a"},
}

static func portrait(k: String, bust: bool) -> Image:
	var o: Dictionary = WHO[k]
	var im := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	var R := func(x: int, y: int, w: int, h: int, col): _blend(im, x, y, w, h, Color(col) if col is String else col)
	if not bust:
		R.call(0, 0, 32, 32, o.bg); R.call(0, 28, 32, 4, Color(0, 0, 0, 0.25))
	R.call(4,26,24,6,o.uni);R.call(6,24,20,2,o.uni);R.call(8,23,16,1,o.uni);R.call(6,24,20,1,o.uh);R.call(4,26,2,1,o.uh);R.call(26,26,2,1,o.uh)
	R.call(13,22,6,3,o.uh);R.call(15,24,2,8,Color(0,0,0,0.25))
	R.call(13,19,6,4,o.sk2)
	R.call(10,8,12,13,o.skin);R.call(9,10,1,9,o.skin);R.call(22,10,1,9,o.skin);R.call(11,21,10,1,o.skin)
	R.call(11,20,10,1,o.sk2);R.call(21,11,1,9,o.sk2);R.call(8,13,1,3,o.sk2);R.call(23,13,1,3,o.sk2)
	R.call(12,14,2,2,"#140f12");R.call(18,14,2,2,"#140f12");R.call(12,14,1,1,"#f2ece0");R.call(18,14,1,1,"#f2ece0")
	R.call(12,12,3,1,o.hair);R.call(17,12,3,1,o.hair);R.call(16,15,1,3,o.sk2);R.call(14,19,4,1,"#6e3a32")
	var H := func(x, y, w, h): R.call(x, y, w, h, o.hair)
	var HH := func(x, y, w, h): R.call(x, y, w, h, o.hh)
	match o.style:
		"bun":
			H.call(9,5,14,4);H.call(8,7,2,6);H.call(22,7,2,6);H.call(13,1,6,4);H.call(10,8,12,2);HH.call(14,2,3,1);HH.call(11,6,6,1)
		"short":
			H.call(9,5,14,4);H.call(8,7,2,6);H.call(22,7,2,5);H.call(10,8,5,3);H.call(15,8,7,2);HH.call(11,6,8,1)
		"long":
			H.call(9,5,14,4);H.call(7,7,3,16);H.call(22,7,3,16);H.call(10,8,9,3);HH.call(11,6,7,1);HH.call(8,10,1,10)
		"crop":
			H.call(9,5,14,4);H.call(9,7,1,4);H.call(22,7,1,4);H.call(10,8,12,1);HH.call(11,6,9,1)
	return im

## Status lamp sprite with glow, blinking like the design (warn 1s, live 0.6s).
static func draw_lamp(ci, p: Vector2, s: String, now: float) -> void:
	if s == "lock":
		ci.draw_texture_rect(tex("lockA"), Rect2(p + Vector2(2, 1), Vector2(14, 16)), false); return
	var key := s if s in ["ok", "warn", "fault", "live"] else "off"
	var a := 1.0
	if key == "warn": a = 1.0 if fmod(now, 1.0) < 0.5 else 0.45
	elif key == "live": a = 1.0 if fmod(now, 0.6) < 0.3 else 0.45
	if key != "off":
		ci.draw_texture_rect(tex("g_" + key), Rect2(p - Vector2(6, 6), Vector2(30, 30)), false, Color(1, 1, 1, a))
	ci.draw_texture_rect(tex("l_" + key), Rect2(p, Vector2(18, 18)), false, Color(1, 1, 1, a))

# ---------------------------------------------------------------- RID canvas
## Lets the painter draw into a raw canvas item (StyleBox._draw), mirroring the
## few CanvasItem calls it uses.
class RidCanvas:
	var rid: RID
	func _init(r: RID) -> void: rid = r
	func draw_rect(r: Rect2, c: Color, filled := true, width := -1.0) -> void:
		if filled: RenderingServer.canvas_item_add_rect(rid, r, c)
		else:
			var w := maxf(width, 1.0)
			for piece in [Rect2(r.position, Vector2(r.size.x, w)), Rect2(r.position.x, r.end.y - w, r.size.x, w), Rect2(r.position, Vector2(w, r.size.y)), Rect2(r.end.x - w, r.position.y, w, r.size.y)]:
				RenderingServer.canvas_item_add_rect(rid, piece, c)
	func draw_polygon(pts: PackedVector2Array, cols: PackedColorArray) -> void:
		RenderingServer.canvas_item_add_polygon(rid, pts, cols)
	func draw_texture_rect_region(t: Texture2D, r: Rect2, src: Rect2, modulate := Color.WHITE) -> void:
		RenderingServer.canvas_item_add_texture_rect_region(rid, r, t.get_rid(), src, modulate)
	func draw_texture_rect(t: Texture2D, r: Rect2, tile: bool, modulate := Color.WHITE) -> void:
		RenderingServer.canvas_item_add_texture_rect(rid, r, t.get_rid(), tile, modulate)
	func draw_string(f: Font, pos: Vector2, s: String, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, size := 16, color := Color.WHITE) -> void:
		f.draw_string(rid, pos, s, align, width, size, color)
	func draw_char(f: Font, pos: Vector2, ch: String, size := 16, color := Color.WHITE) -> void:
		f.draw_char(rid, pos, ch.unicode_at(0), size, color)
