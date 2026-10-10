extends CanvasLayer

signal dismissed

const GOLD := Color(0.91, 0.69, 0.36)
const PALE := Color(0.91, 0.94, 0.95)
const MUTED := Color(0.62, 0.7, 0.75)

var _root: Control
var _continue_button: Button
var _is_dismissing := false


func _ready() -> void:
	_build_ui()
	_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_continue_button.grab_focus()
	var tween := create_tween()
	tween.tween_property(_root, "modulate", Color.WHITE, 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.008, 0.018, 0.032, 0.76)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1000.0, 0.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 11)
	panel.add_child(content)

	var eyebrow := _label("ASTERIA-1  /  CREW ARRIVAL BRIEF", 14, GOLD)
	content.add_child(eyebrow)

	var welcome := _label("WELCOME ABOARD, THURA MIN!", 40, PALE)
	welcome.custom_minimum_size.y = 54.0
	content.add_child(welcome)

	var status := _label("DAY 184     •     FINAL APPROACH TO EREBOS", 17, MUTED)
	content.add_child(status)

	var divider := HSeparator.new()
	divider.add_theme_color_override("separator_color", Color(0.66, 0.49, 0.27, 0.72))
	content.add_child(divider)

	var mission_heading := _label("MISSION BRIEF", 13, GOLD)
	content.add_child(mission_heading)

	var mission := _label(
		"A crewed deep-space industrial research mission to survey Erebos and test autonomous mining systems.",
		18,
		PALE
	)
	mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission.custom_minimum_size.y = 28.0
	content.add_child(mission)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	content.add_child(cards)
	cards.add_child(_info_card("DESTINATION", "EREBOS", "Metal-rich minor planet"))
	cards.add_child(_info_card("YOUR SPECIALTY", "PLANETARY GEOLOGY", "Operate autonomous mining drones"))
	cards.add_child(_info_card("SHIP SYSTEMS", "LIFE SUPPORT", "Power · oxygen · pressure doors · communications"))

	var crew := _label(
		"CREW ONBOARD   Maya Chen — Commander  ·  Elias Ward — Pilot  ·  Amara Okoye — Medical / Astrobiology  ·  Leila Haddad — Chief Engineer  ·  Mateo Ruiz — Mining Specialist",
		15,
		PALE
	)
	crew.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crew.custom_minimum_size.y = 40.0
	content.add_child(crew)

	var first_duty := _label("FIRST DUTY   Recalibrate the oxygen sensor and inspect the sample chamber.", 15, MUTED)
	first_duty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(first_duty)

	_continue_button = Button.new()
	_continue_button.text = "ENTER THE SHIP  →"
	_continue_button.custom_minimum_size = Vector2(230.0, 50.0)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_continue_button.add_theme_font_size_override("font_size", 16)
	_continue_button.add_theme_color_override("font_color", Color(0.07, 0.08, 0.08))
	_continue_button.add_theme_color_override("font_hover_color", Color(0.07, 0.08, 0.08))
	_continue_button.add_theme_stylebox_override("normal", _button_style(Color(0.89, 0.68, 0.36), Color(0.99, 0.82, 0.53)))
	_continue_button.add_theme_stylebox_override("hover", _button_style(Color(0.98, 0.8, 0.49), Color(1.0, 0.9, 0.69)))
	_continue_button.add_theme_stylebox_override("focus", _button_style(Color(0.89, 0.68, 0.36), Color(1.0, 0.94, 0.79)))
	_continue_button.pressed.connect(_dismiss)
	content.add_child(_continue_button)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
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
	stack.add_child(_label(heading, 12, GOLD))

	var card_title := _label(title, 17, PALE)
	card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(card_title)

	var card_detail := _label(detail, 13, MUTED)
	card_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(card_detail)
	return card


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.041, 0.063, 0.98)
	style.border_color = Color(0.75, 0.58, 0.34, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 36.0
	style.content_margin_right = 36.0
	style.content_margin_top = 30.0
	style.content_margin_bottom = 26.0
	return style


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.071, 0.096, 0.96)
	style.border_color = Color(0.27, 0.36, 0.4, 0.85)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 10.0
	return style


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


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
