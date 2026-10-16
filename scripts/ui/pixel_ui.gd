extends RefCounted
## Shared skin for procedural screens. Gameplay and room themes remain local.
const THEME := preload("res://themes/ship_pixel_theme.tres")
const IVORY := Color(0.94, 0.91, 0.82)
const AMBER := Color(1.0, 0.77, 0.34)
const MUTED := Color(0.59, 0.69, 0.73)

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
	button.add_theme_font_size_override("font_size", 24)

