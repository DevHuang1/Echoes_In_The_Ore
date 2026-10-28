@tool
extends RefCounted
## Builds the shared Control theme in the design language. tools/build_eito_theme.gd
## writes it to res://themes/ship_pixel_theme.tres, which every older screen already
## loads (HUD, inventory, map, settings, title, intro, briefing, service consoles).
## Type variations give screens the design's materials and type roles:
##   PanelContainer: EitoModule (screwed plate), EitoBezel, EitoWell, EitoGlass, EitoPaper, EitoChip, EitoVoice
##   Button: PushButton (paper push-cap), KeyButton (default), CloseButton
##   Label: EitoTag (Silkscreen caps), EitoAmber, EitoValue (phosphor), EitoInk (on paper), EitoTitle, EitoHint

const UI := preload("res://scripts/ui/eito/eito_ui.gd")
const STYLE := preload("res://scripts/ui/eito/eito_style.gd")
const BODY_FONT := "res://themes/eito_body_font.tres"
const LABEL_FONT := "res://themes/eito_label_font.tres"
const KNOB := "res://art/ui/eito/fader_knob.png"
const KNOB_HI := "res://art/ui/eito/fader_knob_hover.png"

static func S(k: String, margin := 8.0, screws := false, tint := Color(0, 0, 0, 0)) -> StyleBox:
	return STYLE.make(k, margin, screws, tint)

static func S4(k: String, l: float, t: float, r: float, b: float, screws := false) -> StyleBox:
	var s := STYLE.make(k, 0.0, screws)
	s.content_margin_left = l; s.content_margin_top = t; s.content_margin_right = r; s.content_margin_bottom = b
	return s

## Body (Pixelify Sans, ligatures off) and label (Silkscreen) fonts, each falling
## back to the original bitmap font for the few symbols the pixel fonts lack.
static func make_fonts() -> Dictionary:
	var bitmap: Font = load("res://art/ui/pixel/ore_pixel_font.fnt")
	var ts := TextServerManager.get_primary_interface()
	var body := FontVariation.new()
	body.base_font = load("res://art/ui/fonts/PixelifySans-Medium.ttf")
	body.opentype_features = {ts.name_to_tag("liga"): 0, ts.name_to_tag("clig"): 0}
	body.fallbacks = [bitmap]
	var label := FontVariation.new()
	label.base_font = load("res://art/ui/fonts/Silkscreen-Regular.ttf")
	label.spacing_glyph = 1
	label.fallbacks = [load("res://art/ui/fonts/PixelifySans-Medium.ttf"), bitmap]
	return {"body":body, "label":label}

static func knob_image(hover: bool) -> Image:
	var w := 18; var h := 28
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var edge := Color("#05090b")
	var top := Color("#d8d1b4") if hover else Color("#cfc7a8")
	var bot := Color("#b0a789") if hover else Color("#a9a083")
	for y in range(h):
		for x in range(w):
			var c := top.lerp(bot, float(y) / h)
			if x == 0 or y == 0 or x == w - 1 or y == h - 1: c = edge
			elif x == 1 or y == 1: c = Color("#f0ead2")
			elif x == w - 2 or y == h - 2: c = Color("#7e7660")
			img.set_pixel(x, y, c)
	for y in [9, 13, 17]:
		for x in range(4, w - 4):
			img.set_pixel(x, y, Color("#5d5a4c")); img.set_pixel(x, y + 1, Color("#efe9d3"))
	img.set_pixel(0, 0, Color(0, 0, 0, 0)); img.set_pixel(w - 1, 0, Color(0, 0, 0, 0))
	img.set_pixel(0, h - 1, Color(0, 0, 0, 0)); img.set_pixel(w - 1, h - 1, Color(0, 0, 0, 0))
	return img

static func build(fonts: Dictionary = {}) -> Theme:
	if fonts.is_empty():
		fonts = {"body":load(BODY_FONT), "label":load(LABEL_FONT)}
	var body: Font = fonts.body
	var label: Font = fonts.label
	var t := Theme.new()
	t.default_font = body
	t.default_font_size = 16
	# --- text roles
	t.set_color("font_color", "Label", UI.TEXT)
	for v in [["EitoTag", label, 14, UI.LABEL], ["EitoAmber", label, 14, UI.WARN], ["EitoValue", body, 18, UI.PHOS],
			["EitoInk", body, 16, UI.INK], ["EitoTitle", body, 28, Color("#f2ecd9")], ["EitoHint", body, 15, Color("#a9b8b6")]]:
		t.set_type_variation(v[0], "Label")
		t.set_font("font", v[0], v[1]); t.set_font_size("font_size", v[0], v[2]); t.set_color("font_color", v[0], v[3])
	# --- buttons: bezel keycaps
	for type in ["Button", "OptionButton", "MenuButton", "CheckButton", "CheckBox"]:
		t.set_color("font_color", type, UI.TEXT)
		t.set_color("font_hover_color", type, UI.CUE)
		t.set_color("font_pressed_color", type, UI.CUE)
		t.set_color("font_hover_pressed_color", type, UI.CUE)
		t.set_color("font_focus_color", type, UI.TEXT)
		t.set_color("font_disabled_color", type, Color("#7d8a8a"))
	for type in ["Button", "OptionButton", "MenuButton"]:
		t.set_stylebox("normal", type, S4("key", 12, 6, 12, 9))
		t.set_stylebox("hover", type, S4("key_hover", 12, 6, 12, 9))
		t.set_stylebox("pressed", type, S4("key_active", 12, 8, 12, 7))
		t.set_stylebox("hover_pressed", type, S4("key_active", 12, 8, 12, 7))
		t.set_stylebox("disabled", type, S4("key_off", 12, 6, 12, 9))
		t.set_stylebox("focus", type, S("focus", 0))
	t.set_type_variation("KeyButton", "Button")
	t.set_type_variation("PushButton", "Button")
	t.set_font("font", "PushButton", label)
	t.set_font_size("font_size", "PushButton", 16)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, "PushButton", Color("#1f2326"))
	t.set_color("font_disabled_color", "PushButton", Color("#4a4a42"))
	t.set_stylebox("normal", "PushButton", S4("push", 18, 8, 18, 12))
	t.set_stylebox("hover", "PushButton", S4("push_hover", 18, 8, 18, 12))
	t.set_stylebox("pressed", "PushButton", S4("push_down", 18, 11, 18, 9))
	t.set_stylebox("hover_pressed", "PushButton", S4("push_down", 18, 11, 18, 9))
	t.set_stylebox("disabled", "PushButton", S4("push_off", 18, 8, 18, 12))
	t.set_stylebox("focus", "PushButton", S("focus", 0))
	t.set_type_variation("CloseButton", "Button")
	t.set_font("font", "CloseButton", label)
	t.set_stylebox("normal", "CloseButton", S4("close", 6, 4, 6, 6))
	t.set_stylebox("hover", "CloseButton", S4("close_hover", 6, 4, 6, 6))
	t.set_stylebox("pressed", "CloseButton", S4("close_hover", 6, 5, 6, 5))
	t.set_stylebox("hover_pressed", "CloseButton", S4("close_hover", 6, 5, 6, 5))
	t.set_stylebox("focus", "CloseButton", S("focus", 0))
	t.set_stylebox("disabled", "CloseButton", S4("close", 6, 4, 6, 6))
	# --- panels and materials
	t.set_stylebox("panel", "PanelContainer", S("module", 16))
	t.set_stylebox("panel", "Panel", S("module", 0))
	for v in [["EitoModule", "module", 18, true], ["EitoBezel", "bezel", 12, false], ["EitoWell", "well", 10, false],
			["EitoGlass", "glass", 12, false], ["EitoPaper", "paper", 16, false], ["EitoChip", "chip", 8, false], ["EitoVoice", "voice", 14, false]]:
		t.set_type_variation(v[0], "PanelContainer")
		t.set_stylebox("panel", v[0], S(v[1], v[2], v[3]))
	t.set_stylebox("normal", "InventorySlot", S("slot", 4))
	t.set_stylebox("hover", "InventorySlot", S("slot_hover", 4))
	t.set_stylebox("selected", "InventorySlot", S("slot_selected", 4))
	t.set_stylebox("panel", "MapViewport", S("glass", 18))
	t.set_stylebox("panel", "TooltipPanel", S4("chip", 10, 6, 10, 6))
	t.set_color("font_color", "TooltipLabel", UI.TEXT)
	t.set_font_size("font_size", "TooltipLabel", 14)
	t.set_stylebox("separator", "HSeparator", S("rule", 0))
	t.set_constant("separation", "HSeparator", 8)
	# --- sliders / bars
	t.set_stylebox("slider", "HSlider", S4("track", 0, 7, 0, 7))
	t.set_stylebox("grabber_area", "HSlider", S4("cells", 0, 7, 0, 7))
	t.set_stylebox("grabber_area_highlight", "HSlider", S4("cells", 0, 7, 0, 7))
	if ResourceLoader.exists(KNOB):
		t.set_icon("grabber", "HSlider", load(KNOB))
		t.set_icon("grabber_disabled", "HSlider", load(KNOB))
		t.set_icon("grabber_highlight", "HSlider", load(KNOB_HI) if ResourceLoader.exists(KNOB_HI) else load(KNOB))
	t.set_stylebox("background", "ProgressBar", S4("track", 0, 4, 0, 4))
	t.set_stylebox("fill", "ProgressBar", S4("cells", 0, 4, 0, 4))
	t.set_color("font_color", "ProgressBar", UI.TEXT)
	# --- text entry, lists, menus, scrollbars
	for type in ["LineEdit", "TextEdit"]:
		t.set_stylebox("normal", type, S4("well", 10, 6, 10, 6))
		t.set_stylebox("focus", type, S("focus", 0))
		t.set_stylebox("read_only", type, S4("well", 10, 6, 10, 6))
		t.set_color("font_color", type, UI.PHOS)
		t.set_color("font_placeholder_color", type, UI.PHOS_DIM)
		t.set_color("caret_color", type, UI.CUE)
		t.set_color("selection_color", type, Color(0.38, 0.82, 0.94, 0.35))
	t.set_stylebox("panel", "ItemList", S4("well", 6, 6, 6, 6))
	t.set_stylebox("focus", "ItemList", S("focus", 0))
	t.set_stylebox("selected", "ItemList", S("key_active", 4))
	t.set_stylebox("selected_focus", "ItemList", S("key_active", 4))
	t.set_stylebox("hovered", "ItemList", S("key_hover", 4))
	t.set_stylebox("cursor", "ItemList", S("focus", 0))
	t.set_stylebox("cursor_unfocused", "ItemList", S("none", 0))
	t.set_color("font_color", "ItemList", UI.TEXT)
	t.set_color("font_selected_color", "ItemList", UI.CUE)
	t.set_color("font_hovered_color", "ItemList", UI.CUE)
	t.set_stylebox("panel", "PopupMenu", S4("bezel", 8, 8, 8, 8))
	t.set_stylebox("hover", "PopupMenu", S("key_hover", 4))
	t.set_stylebox("separator", "PopupMenu", S("rule", 0))
	t.set_color("font_color", "PopupMenu", UI.TEXT)
	t.set_color("font_hover_color", "PopupMenu", UI.CUE)
	t.set_color("font_disabled_color", "PopupMenu", Color("#7d8a8a"))
	for type in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", type, S("track", 2))
		t.set_stylebox("scroll_focus", type, S("track", 2))
		t.set_stylebox("grabber", type, S("bezel", 4))
		t.set_stylebox("grabber_highlight", type, S("key_hover", 4))
		t.set_stylebox("grabber_pressed", type, S("key_down", 4))
	t.set_color("default_color", "RichTextLabel", UI.TEXT)
	t.set_font("normal_font", "RichTextLabel", body)
	t.set_font_size("normal_font_size", "RichTextLabel", 16)
	t.set_stylebox("normal", "RichTextLabel", S("none", 0))
	t.set_stylebox("focus", "RichTextLabel", S("none", 0))
	return t
