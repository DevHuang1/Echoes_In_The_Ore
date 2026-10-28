extends CanvasLayer

const SKIN := preload("res://scripts/ui/pixel_ui.gd")

signal dismissed

const GOLD := Color(1.0, 0.77, 0.34)
const PALE := Color(0.94, 0.91, 0.82)
const MUTED := Color(0.59, 0.69, 0.73)
const GREEN := Color(0.48, 0.93, 0.64)

var _root: Control
var _continue_button: Button
var _is_dismissing := false
var _panel: PanelContainer
var _welcome: Label


func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_resize_briefing)
	_resize_briefing()
	_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_continue_button.grab_focus()
	var tween := create_tween()
	tween.tween_property(_root, "modulate", Color.WHITE, 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _build_ui() -> void:
	_root = Control.new()
	SKIN.apply(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.008, 0.018, 0.032, 0.82)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := PanelContainer.new()
	_panel = panel
	panel.custom_minimum_size = Vector2(1120.0, 0.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	var badge := _label("[ MISSION BRIEFING ]", 11, GOLD)
	header_row.add_child(badge)
	var telemetry_tag := _label("// FLIGHT RECORD DAY 184 // ASTERIA-1", 11, MUTED)
	telemetry_tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	telemetry_tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(telemetry_tag)
	header_row.add_spacer(false)
	var status_tag := _label("TELEMETRY LINKED", 11, GREEN)
	header_row.add_child(status_tag)
	content.add_child(header_row)

	var welcome := _label("WELCOME ABOARD, SPECIALIST THURA MIN", 34, PALE)
	_welcome = welcome
	welcome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	welcome.custom_minimum_size.y = 44.0
	content.add_child(welcome)

	var status := _label("DAY 184 ABOARD ASTERIA-1 // PREPARING FOR THE EREBOS SURVEY", 14, MUTED)
	content.add_child(status)

	var divider := HSeparator.new()
	divider.add_theme_color_override("separator_color", Color(0.66, 0.49, 0.27, 0.72))
	content.add_child(divider)

	var mission_heading := _label("OPERATION DIRECTIVE // SURVEY & EXTRACTION", 12, GOLD)
	content.add_child(mission_heading)

	var mission := _label(
		"Crewed deep-space industrial research expedition to survey minor planet Erebos and validate autonomous ore extraction systems.",
		16,
		PALE
	)
	mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission.custom_minimum_size.y = 26.0
	content.add_child(mission)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	content.add_child(cards)
	cards.add_child(_info_card("[ 01 // DESTINATION ]", "EREBOS (MINOR PLANET)", "High-density ore survey target; anomalous magnetic signature."))
	cards.add_child(_info_card("[ 02 // ASSIGNMENT ]", "PLANETARY GEOLOGY", "Lead specialist: autonomous drone deployment & core sampling."))
	cards.add_child(_info_card("[ 03 // FIRST WATCH ]", "REPORT TO THE BRIDGE", "Maya's assignment is waiting at the planning table. Other routine systems are running normally."))

	var crew := _label(
		"CREW ONBOARD:  Maya Chen (CDR) · Elias Ward (PLT) · Amara Okoye (MED) · Leila Haddad (ENG) · Mateo Ruiz (MIN)",
		14,
		PALE
	)
	crew.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crew.custom_minimum_size.y = 32.0
	content.add_child(crew)

	var first_duty := _label("FIRST OBJECTIVE: Go west through the bridge corridor. Use the planning table beside the main helm to receive Maya's watch assignment. She will explain the work before you begin.", 14, MUTED)
	first_duty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(first_duty)

	_continue_button = Button.new()
	_continue_button.text = "[ ENTER SHIP DECK  → ]"
	_continue_button.custom_minimum_size = Vector2(250.0, 50.0)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_continue_button.add_theme_font_size_override("font_size", 16)
	_continue_button.pressed.connect(_dismiss)
	content.add_child(_continue_button)


func _resize_briefing() -> void:
	var view := get_viewport().get_visible_rect().size
	_panel.custom_minimum_size.x = minf(1120.0, view.x-48.0)
	_welcome.add_theme_font_size_override("font_size", 28 if view.x<1150 else 34)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", maxi(12, font_size))
	label.add_theme_color_override("font_color", color)
	return label


func _info_card(heading: String, title: String, detail: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, 108.0)
	card.add_theme_stylebox_override("panel", _card_style())

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	card.add_child(stack)
	stack.add_child(_label(heading, 11, GOLD))

	var card_title := _label(title, 16, PALE)
	card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(card_title)

	var card_detail := _label(detail, 12, MUTED)
	card_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(card_detail)
	return card


func _panel_style() -> StyleBox:
	return SKIN.panel(24.0)

func _card_style() -> StyleBox:
	return SKIN.panel(14.0, true)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_dismiss()
			get_viewport().set_input_as_handled()


func _dismiss() -> void:
	if _is_dismissing:
		return
	_is_dismissing = true
	_continue_button.disabled = true
	var tween := create_tween()
	tween.tween_property(_root, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	dismissed.emit()
	queue_free()
