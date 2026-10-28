extends RefCounted
## Shared skin for procedural screens. Pixel-font typography hierarchy for sci-fi UI.
const THEME := preload("res://themes/ship_pixel_theme.tres")
const IVORY := Color(0.94, 0.91, 0.82)
const AMBER := Color(1.0, 0.77, 0.34)
const GOLD := Color(1.0, 0.82, 0.40)
const CYAN := Color(0.38, 0.88, 0.98)
const MUTED := Color(0.59, 0.69, 0.73)
const GREEN := Color(0.48, 0.93, 0.64)
const ORANGE := Color(1.0, 0.68, 0.32)
const DARK_BG := Color(0.015, 0.028, 0.044, 0.95)

const FONT_TINY := 8
const FONT_TELEMETRY := 10
const FONT_SMALL := 11
const FONT_BODY := 13
const FONT_SUBHEAD := 15
const FONT_TITLE := 20
const DEFAULT_LINE_SPACING := 5

static func get_clean_font() -> Font:
	return THEME.default_font

static func get_pixel_font() -> Font:
	return THEME.default_font

static func clean_label(text: String = "", size: int = FONT_BODY, color: Color = IVORY) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", get_pixel_font())
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

static func pixel_label(text: String = "", size: int = FONT_TELEMETRY, color: Color = MUTED) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", get_pixel_font())
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

static func header_label(text: String = "", size: int = FONT_TITLE, color: Color = GOLD) -> Label:
	var lbl := pixel_label(text, size, color)
	return lbl

static func style_label(lbl: Label, _use_clean: bool, size: int, color: Color) -> void:
	lbl.add_theme_font_override("font", get_pixel_font())
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)

static func apply(control: Control) -> void:
	control.theme = THEME
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func panel(padding := 16.0, inset := false, selected := false) -> StyleBoxTexture:
	var style: StyleBoxTexture
	if inset:
		style = THEME.get_stylebox("selected" if selected else "normal", "InventorySlot").duplicate()
	else:
		style = THEME.get_stylebox("panel", "PanelContainer").duplicate()
	for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(edge, padding)
	return style

static func close_button(button: Button) -> void:
	button.theme_type_variation = &"CloseButton"
	button.text = "X"
	button.custom_minimum_size = Vector2(48, 48)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 16)
