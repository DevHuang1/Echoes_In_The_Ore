extends CanvasLayer

signal repair_succeeded
signal cancelled

const CYAN := Color("#55dff2")
const GREEN := Color("#74edaa")
const AMBER := Color("#ffbc62")
const PALE := Color("#e8f1e8")
const MUTED := Color("#93aab1")

var _lane: Control
var _stage_label: Label
var _status_label: Label
var _mistakes_label: Label
var _hint_label: Label
var _retry_button: Button
var _relay_cells: Array[Panel] = []
var _sweep_position: float = 0.0
var _sweep_direction: float = 1.0
var _sweep_speed: float = 0.62
var _target_position: float = 0.35
var _target_width: float = 0.12
var _stage: int = 0
var _mistakes: int = 0
var _failed: bool = false

const TARGETS := [0.35, 0.68, 0.47]
const WINDOWS := [0.12, 0.095, 0.075]
const SPEEDS := [0.62, 0.75, 0.88]


func _ready() -> void:
	layer = 80
	_build_ui()
	_configure_stage()
	set_process(true)
	set_process_unhandled_input(true)


func _process(delta: float) -> void:
	if _failed or _stage >= TARGETS.size():
		return
	_sweep_position += _sweep_direction * _sweep_speed * delta
	if _sweep_position >= 1.0:
		_sweep_position = 1.0
		_sweep_direction = -1.0
	elif _sweep_position <= 0.0:
		_sweep_position = 0.0
		_sweep_direction = 1.0
	_lane.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		cancelled.emit()
		queue_free()
		get_viewport().set_input_as_handled()
		return
	if _failed:
		if event.keycode == KEY_R:
			_reset_game()
			get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
		_attempt_lock()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.008, 0.018, 0.026, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var edge_frame := Panel.new()
	edge_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edge_frame.offset_left = 22.0
	edge_frame.offset_top = 22.0
	edge_frame.offset_right = -22.0
	edge_frame.offset_bottom = -22.0
	edge_frame.add_theme_stylebox_override("panel", _frame_style())
	edge_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(edge_frame)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	panel.custom_minimum_size = Vector2(maxf(280.0, minf(760.0, viewport_width - 96.0)), 0.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	for key in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(key, 34)
	for key in ["margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(key, 28)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	margin.add_child(stack)

	var header := HBoxContainer.new()
	var title := _make_label("MAINTENANCE // LAB PRESSURE INTERLOCK", 19, PALE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var exit_label := _make_label("[ ESC ] EXIT", 11, MUTED)
	header.add_child(exit_label)
	stack.add_child(header)

	var subtitle := _make_label("MANUAL OVERRIDE SEQUENCE  /  THREE RELAY CHANNELS", 12, CYAN)
	stack.add_child(subtitle)
	stack.add_child(HSeparator.new())

	_stage_label = _make_label("CHANNEL 01 / 03", 15, AMBER)
	stack.add_child(_stage_label)

	var instruction := _make_label("Press SPACE when the moving signal enters the narrow cyan window.", 14, PALE)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(instruction)

	_lane = Control.new()
	_lane.custom_minimum_size = Vector2(0.0, 96.0)
	_lane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lane.draw.connect(_draw_timing_lane)
	stack.add_child(_lane)

	_status_label = _make_label("SIGNAL SWEEP ACTIVE  //  ALIGN AND LOCK", 13, GREEN)
	stack.add_child(_status_label)

	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 10)
	for index in range(3):
		var cell := Panel.new()
		cell.name = "Relay%d" % index
		cell.custom_minimum_size = Vector2(0.0, 12.0)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_stylebox_override("panel", _relay_style(false))
		_relay_cells.append(cell)
		progress_row.add_child(cell)
	stack.add_child(progress_row)

	var footer := HBoxContainer.new()
	_hint_label = _make_label("STABILIZE ALL THREE CHANNELS. WINDOWS SHRINK AS THE RELAY WARMS.", 10, MUTED)
	_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(_hint_label)
	_mistakes_label = _make_label("MISSES  0 / 3", 12, AMBER)
	footer.add_child(_mistakes_label)
	stack.add_child(footer)

	_retry_button = Button.new()
	_retry_button.text = "RETRY SEQUENCE  [R]"
	_retry_button.custom_minimum_size = Vector2(260.0, 44.0)
	_retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_retry_button.visible = false
	_retry_button.pressed.connect(_reset_game)
	stack.add_child(_retry_button)


func _configure_stage() -> void:
	if _stage >= TARGETS.size():
		return
	_target_position = TARGETS[_stage]
	_target_width = WINDOWS[_stage]
	_sweep_speed = SPEEDS[_stage]
	_sweep_position = 0.0
	_sweep_direction = 1.0
	_stage_label.text = "CHANNEL %02d / 03" % (_stage + 1)
	_lane.queue_redraw()
	_refresh_relay_cells()


func _attempt_lock() -> void:
	if absf(_sweep_position - _target_position) <= _target_width:
		_stage += 1
		if _stage >= TARGETS.size():
			_status_label.text = "ALL RELAYS SYNCHRONIZED  //  PRESSURE SEAL STABLE"
			_status_label.add_theme_color_override("font_color", GREEN)
			_stage_label.text = "INTERLOCK RESTORED"
			_refresh_relay_cells()
			set_process(false)
			get_tree().create_timer(0.55).timeout.connect(func():
				repair_succeeded.emit()
				queue_free()
			)
			return
		_status_label.text = "RELAY LOCKED  //  NEXT CHANNEL IS FASTER"
		_status_label.add_theme_color_override("font_color", GREEN)
		_configure_stage()
	else:
		_mistakes += 1
		_mistakes_label.text = "MISSES  %d / 3" % _mistakes
		_status_label.text = "PHASE ERROR  //  WAIT FOR THE CYAN WINDOW"
		_status_label.add_theme_color_override("font_color", AMBER)
		if _mistakes >= 3:
			_failed = true
			set_process(false)
			_status_label.text = "RELAY TRIPPED  //  RESET THE SEQUENCE AND TRY AGAIN"
			_status_label.add_theme_color_override("font_color", Color("#ff716b"))
			_hint_label.text = "Press R or choose Retry Sequence. The door stays sealed until all relays hold."
			_retry_button.visible = true


func _reset_game() -> void:
	_stage = 0
	_mistakes = 0
	_failed = false
	_mistakes_label.text = "MISSES  0 / 3"
	_hint_label.text = "STABILIZE ALL THREE CHANNELS. WINDOWS SHRINK AS THE RELAY WARMS."
	_status_label.text = "SIGNAL SWEEP ACTIVE  //  ALIGN AND LOCK"
	_status_label.add_theme_color_override("font_color", GREEN)
	_retry_button.hide()
	set_process(true)
	_configure_stage()


func _refresh_relay_cells() -> void:
	for index in range(_relay_cells.size()):
		var cell := _relay_cells[index]
		cell.add_theme_stylebox_override("panel", _relay_style(index < _stage))


func _draw_timing_lane() -> void:
	var lane_size := _lane.size
	if lane_size.x <= 0.0:
		return
	var margin := 12.0
	var track := Rect2(margin, 25.0, lane_size.x - margin * 2.0, 42.0)
	_lane.draw_rect(track, Color("#09151b"), true)
	_lane.draw_rect(track, Color("#29434b"), false, 2.0)
	var target_x := track.position.x + track.size.x * (_target_position - _target_width)
	var target_width := track.size.x * _target_width * 2.0
	_lane.draw_rect(Rect2(target_x, track.position.y + 2.0, target_width, track.size.y - 4.0), Color(0.15, 0.82, 0.82, 0.45), true)
	_lane.draw_rect(Rect2(target_x, track.position.y + 2.0, target_width, track.size.y - 4.0), CYAN, false, 2.0)
	for tick in range(1, 10):
		var x := track.position.x + track.size.x * float(tick) / 10.0
		_lane.draw_line(Vector2(x, track.position.y + 11.0), Vector2(x, track.end.y - 11.0), Color(0.56, 0.68, 0.71, 0.25), 1.0)
	var cursor_x := track.position.x + track.size.x * _sweep_position
	_lane.draw_line(Vector2(cursor_x, track.position.y - 9.0), Vector2(cursor_x, track.end.y + 9.0), PALE, 3.0)
	_lane.draw_circle(Vector2(cursor_x, track.position.y - 10.0), 5.0, AMBER)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#09131a")
	style.border_color = Color("#356d79")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	return style


func _frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(0.16, 0.52, 0.59, 0.8)
	style.set_border_width_all(2)
	return style


func _relay_style(complete: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#65e9a1") if complete else Color("#15232a")
	style.border_color = Color("#65e9a1") if complete else Color("#29434b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style
