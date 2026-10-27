class_name OreExtractionConsole
extends CanvasLayer

signal extraction_completed(site_id: StringName)
signal modal_state_changed(is_open: bool)

const PIXEL_THEME := preload("res://themes/ship_pixel_theme.tres")
const PALE := Color(0.94, 0.91, 0.82)
const MUTED := Color(0.63, 0.72, 0.75)
const CYAN := Color(0.45, 0.77, 0.82)
const GREEN := Color(0.55, 0.84, 0.67)
const PANEL := Color(0.025, 0.052, 0.068, 0.98)
const DRILL_DURATION := 5.0

var _site: Dictionary = {}
var _elapsed := 0.0
var _is_drilling := false
var _completed := false
var _status_label: Label
var _progress_bar: ProgressBar
var _drill_button: Button
var _close_button: Button


func open(site: Dictionary) -> void:
	_site = site.duplicate(true)
	layer = 20
	_build_interface()
	modal_state_changed.emit(true)


func _process(delta: float) -> void:
	if not _is_drilling:
		return
	_elapsed = minf(_elapsed + delta, DRILL_DURATION)
	var percent := int(roundf(_elapsed / DRILL_DURATION * 100.0))
	_progress_bar.value = percent
	_status_label.text = "CORE EXTRACTION IN PROGRESS  /  %d%%" % percent
	if _elapsed >= DRILL_DURATION:
		_is_drilling = false
		_completed = true
		_status_label.text = "CORE SAMPLE SECURED  /  READY FOR RETURN"
		_status_label.add_theme_color_override("font_color", GREEN)
		_drill_button.text = "SAMPLE SECURED"
		_drill_button.disabled = true
		_close_button.text = "CLOSE CONSOLE"
		extraction_completed.emit(StringName(_site.get("id", &"")))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_console()


func _build_interface() -> void:
	var overlay := Control.new()
	overlay.name = "ExtractionConsoleOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = PIXEL_THEME
	add_child(overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.012, 0.02, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "MiningControlPanel"
	panel.custom_minimum_size = Vector2(740.0, 450.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL
	panel_style.border_color = Color(0.29, 0.48, 0.53)
	panel_style.set_border_width_all(2)
	panel_style.content_margin_left = 28.0
	panel_style.content_margin_right = 28.0
	panel_style.content_margin_top = 24.0
	panel_style.content_margin_bottom = 22.0
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)
	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text = "EXTRACTION CONTROL  /  %s" % str(_site.get("machine", "MINING RIG")).to_upper()
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", PALE)
	header.add_child(title)
	var close_x := Button.new()
	close_x.text = "X"
	close_x.custom_minimum_size = Vector2(42.0, 36.0)
	close_x.pressed.connect(_close_console)
	header.add_child(close_x)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	rule.color = CYAN
	column.add_child(rule)

	var descriptor := Label.new()
	descriptor.text = "REMOTE DRILL TERMINAL  /  EREBOS SURVEY ZONE"
	descriptor.add_theme_font_size_override("font_size", 11)
	descriptor.add_theme_color_override("font_color", MUTED)
	column.add_child(descriptor)

	var telemetry := GridContainer.new()
	telemetry.columns = 2
	telemetry.add_theme_constant_override("h_separation", 32)
	telemetry.add_theme_constant_override("v_separation", 12)
	column.add_child(telemetry)
	_add_reading(telemetry, "DRILL LOCATION", str(_site.get("marker_label", "ORE SITE")))
	_add_reading(telemetry, "TARGET MATERIAL", "BASALT-EMBEDDED RESONANCE ORE")
	_add_reading(telemetry, "BORE DEPTH", "%d m" % int(_site.get("depth_m", 42)))
	_add_reading(telemetry, "CORE PRESSURE", "%s MPa" % str(_site.get("pressure_mpa", "1.8")))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 2.0)
	column.add_child(spacer)
	var status_title := Label.new()
	status_title.text = "EXTRACTION STATUS"
	status_title.add_theme_font_size_override("font_size", 11)
	status_title.add_theme_color_override("font_color", MUTED)
	column.add_child(status_title)
	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0.0, 22.0)
	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = Color(0.012, 0.026, 0.035)
	_progress_bar.add_theme_stylebox_override("background", progress_bg)
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = CYAN
	_progress_bar.add_theme_stylebox_override("fill", progress_fill)
	column.add_child(_progress_bar)
	_status_label = Label.new()
	_status_label.text = "RIG STANDBY  /  CORE SAMPLE AVAILABLE"
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", PALE)
	column.add_child(_status_label)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_END
	controls.add_theme_constant_override("separation", 12)
	column.add_child(controls)
	_drill_button = Button.new()
	_drill_button.text = "START EXTRACTION"
	_drill_button.custom_minimum_size = Vector2(220.0, 46.0)
	_drill_button.pressed.connect(_start_extraction)
	controls.add_child(_drill_button)
	_close_button = Button.new()
	_close_button.text = "CANCEL"
	_close_button.custom_minimum_size = Vector2(140.0, 46.0)
	_close_button.pressed.connect(_close_console)
	controls.add_child(_close_button)


func _add_reading(grid: GridContainer, label_text: String, value_text: String) -> void:
	var name_label := Label.new()
	name_label.text = label_text
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", MUTED)
	grid.add_child(name_label)
	var value_label := Label.new()
	value_label.text = value_text
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", PALE)
	grid.add_child(value_label)


func _start_extraction() -> void:
	if _is_drilling or _completed:
		return
	_elapsed = 0.0
	_is_drilling = true
	_drill_button.disabled = true
	_close_button.text = "ABORT DRILL"
	_status_label.text = "DRILLING INTO THE MINERAL SEAM  /  0%"
	_status_label.add_theme_color_override("font_color", CYAN)


func _close_console() -> void:
	if _is_drilling:
		_is_drilling = false
		_status_label.text = "EXTRACTION ABORTED  /  SAMPLE NOT COLLECTED"
		_drill_button.disabled = false
		_drill_button.text = "RESTART EXTRACTION"
		_close_button.text = "CLOSE CONSOLE"
		_elapsed = 0.0
		_progress_bar.value = 0.0
		return
	modal_state_changed.emit(false)
	queue_free()
