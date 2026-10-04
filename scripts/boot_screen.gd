extends Control

const BACKGROUND := Color("#07131b")
const PANEL := Color("#10242d")
const BORDER := Color("#29414a")
const PAPER := Color("#eee5d3")
const MUTED := Color("#aab7b2")
const AMBER := Color("#e7aa55")

var _panel: PanelContainer
var _title: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_screen()
	get_viewport().size_changed.connect(_update_responsive_size)
	_update_responsive_size()


func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	_panel.add_child(content)

	content.add_child(_make_label("WEB FOUNDATION", 15, AMBER))

	_title = _make_label("ECHOES IN THE ORE", 42, PAPER)
	content.add_child(_title)

	content.add_child(_make_label("Godot 4.7 / Compatibility renderer / WebGL 2.0", 17, MUTED))
	content.add_child(_make_label("Web export preset: single-threaded", 16, MUTED))
	content.add_child(_make_label("Startup only. No gameplay systems or levels yet.", 15, AMBER))


func _make_label(label_text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(24)
	return style


func _update_responsive_size() -> void:
	if not is_instance_valid(_panel) or not is_instance_valid(_title):
		return

	var viewport_width := get_viewport_rect().size.x
	_panel.custom_minimum_size = Vector2(clampf(viewport_width - 40.0, 280.0, 640.0), 0.0)
	_title.add_theme_font_size_override("font_size", int(clampf(viewport_width * 0.07, 24.0, 42.0)))
