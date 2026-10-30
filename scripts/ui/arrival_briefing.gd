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


func _ready() -> void:
	_build_ui()
	_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_continue_button.grab_focus()
	DialogueAudioSynth.play_sfx("terminal_open", self, -3.0)
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
	panel.custom_minimum_size = Vector2(980.0, 0.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	var badge := _label("[ MISSION BRIEFING ]", 11, GOLD)
	header_row.add_child(badge)
	var telemetry_tag := _label("// FLIGHT RECORD DAY 184 // ASTERIA-1", 11, MUTED)
	header_row.add_child(telemetry_tag)
	header_row.add_spacer(false)
	var status_tag := _label("● ORBITAL TELEMETRY LINKED", 11, GREEN)
	header_row.add_child(status_tag)
	content.add_child(header_row)

	var welcome := _label("WELCOME ABOARD, SPECIALIST THURA MIN", 24, PALE)
	welcome.custom_minimum_size.y = 38.0
	content.add_child(welcome)

	var status := _label("DAY 184 ABOARD ASTERIA-1 // PREPARING FOR THE EREBOS SURVEY", 13, MUTED)
	content.add_child(status)

	var divider := HSeparator.new()
	divider.add_theme_color_override("separator_color", Color(0.66, 0.49, 0.27, 0.72))
	content.add_child(divider)

	var mission_heading := _label("OPERATION DIRECTIVE // SURVEY & EXTRACTION", 13, GOLD)
	content.add_child(mission_heading)

	var mission := _label(
		"Crewed deep-space industrial research expedition to survey minor planet Erebos and validate autonomous ore extraction systems.",
		14,
		PALE
	)
	mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission.custom_minimum_size.y = 36.0
	content.add_child(mission)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 14)
	content.add_child(cards)
	cards.add_child(_info_card("[ 01 // DESTINATION ]", "EREBOS (MINOR PLANET)", "High-density ore survey target; anomalous magnetic signature."))
	cards.add_child(_info_card("[ 02 // ASSIGNMENT ]", "PLANETARY GEOLOGY", "Lead specialist: autonomous drone deployment & core sampling."))
	cards.add_child(_info_card("[ 03 // FIRST WATCH ]", "REPORT TO THE BRIDGE", "Maya's assignment is waiting at the planning table. Other routine systems are running normally."))

	var crew := _label(
		"CREW ONBOARD:  Maya Chen (CDR) · Elias Ward (PLT) · Amara Okoye (MED) · Leila Haddad (ENG) · Mateo Ruiz (MIN)",
		12,
		PALE
	)
	crew.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crew.custom_minimum_size.y = 32.0
	content.add_child(crew)

	var first_duty := _label("FIRST OBJECTIVE: Go west through the bridge corridor. Use the planning table beside the main helm to receive Maya's watch assignment. She will explain the work before you begin.", 13, Color(0.78, 0.88, 0.94))
	first_duty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	first_duty.custom_minimum_size.y = 38.0
	content.add_child(first_duty)

	_continue_button = Button.new()
	_continue_button.text = "[ ENTER SHIP DECK  → ]"
	_continue_button.custom_minimum_size = Vector2(280.0, 50.0)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_continue_button.add_theme_font_override("font", SKIN.get_pixel_font())
	_continue_button.add_theme_font_size_override("font_size", 14)
	_continue_button.pressed.connect(_dismiss)
	content.add_child(_continue_button)


func _label(text: String, font_size: int, color: Color, _use_clean: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", SKIN.get_pixel_font())
	label.add_theme_font_size_override("font_size", maxi(8, font_size))
	label.add_theme_constant_override("line_spacing", 6)
	label.add_theme_color_override("font_color", color)
	return label


func _info_card(heading: String, title: String, detail: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, 122.0)
	card.add_theme_stylebox_override("panel", _card_style())

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	card.add_child(stack)
	stack.add_child(_label(heading, 11, GOLD))

	var card_title := _label(title, 13, PALE)
	card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(card_title)

	var card_detail := _label(detail, 11, MUTED)
	card_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(card_detail)
	return card


func _panel_style() -> StyleBox:
	return SKIN.panel(24.0)

func _card_style() -> StyleBox:
	return SKIN.panel(14.0, true)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE, KEY_E, KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			_dismiss()
			get_viewport().set_input_as_handled()


func _dismiss() -> void:
	if _is_dismissing:
		return
	_is_dismissing = true
	_continue_button.disabled = true
	DialogueAudioSynth.play_sfx("button_click", self, -4.0)
	var tween := create_tween()
	tween.tween_property(_root, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	dismissed.emit()
	queue_free()
