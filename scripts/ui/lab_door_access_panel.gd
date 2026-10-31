extends CanvasLayer

signal release_requested
signal repair_requested
signal dismissed

var _controller_repaired: bool = false


func setup(controller_repaired: bool) -> void:
	_controller_repaired = controller_repaired


func _ready() -> void:
	layer = 70
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.015, 0.035, 0.055, 0.82)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600.0, 0.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	margin.add_child(stack)

	var header := Label.new()
	header.text = "ASTERIA-1  //  PRESSURE DOOR CONTROL"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color("#e7f3ee"))
	stack.add_child(header)

	var subtitle := Label.new()
	subtitle.text = "LAB ACCESS NETWORK  •  CENTRAL BAY / RESEARCH DECK"
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("#65d5e5"))
	stack.add_child(subtitle)
	stack.add_child(HSeparator.new())

	var status := Label.new()
	status.text = "CONTROLLER OFFLINE  /  PRESSURE SEALS ENGAGED" if not _controller_repaired else "CONTROLLER ONLINE  /  BULKHEADS READY FOR RELEASE"
	status.add_theme_font_size_override("font_size", 15)
	status.add_theme_color_override("font_color", Color("#ffbd62") if not _controller_repaired else Color("#73e7ae"))
	stack.add_child(status)

	var detail := Label.new()
	if _controller_repaired:
		detail.text = "The maintenance bypass is stable. Release the lab bulkheads to investigate the missing crew signal."
	else:
		detail.text = "A resonance surge tripped this interlock. Start a manual relay repair here, then release the sealed bulkheads from this panel."
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.y = 48.0
	detail.add_theme_font_size_override("font_size", 14)
	detail.add_theme_color_override("font_color", Color("#b7c9ca"))
	stack.add_child(detail)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	stack.add_child(buttons)

	var release_button := Button.new()
	release_button.custom_minimum_size = Vector2(360.0, 48.0)
	release_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	release_button.text = "RELEASE ALL LAB BULKHEADS" if _controller_repaired else "START INTERLOCK REPAIR"
	release_button.add_theme_font_size_override("font_size", 14)
	release_button.pressed.connect(_on_release_pressed)
	buttons.add_child(release_button)

	var close_button := Button.new()
	close_button.custom_minimum_size = Vector2(120.0, 48.0)
	close_button.text = "CLOSE  [ESC]"
	close_button.add_theme_font_size_override("font_size", 12)
	close_button.pressed.connect(_dismiss)
	buttons.add_child(close_button)
	close_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_dismiss()
		get_viewport().set_input_as_handled()


func _on_release_pressed() -> void:
	if _controller_repaired:
		release_requested.emit()
	else:
		repair_requested.emit()
	_dismiss()


func _dismiss() -> void:
	dismissed.emit()
	queue_free()


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#07121a")
	style.border_color = Color("#45c7dc")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	return style
