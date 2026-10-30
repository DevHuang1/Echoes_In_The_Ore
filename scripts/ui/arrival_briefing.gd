extends CanvasLayer

const SKIN := preload("res://scripts/ui/pixel_ui.gd")
const EC := preload("res://scripts/ui/eito/eito_controls.gd")
const UI := preload("res://scripts/ui/eito/eito_ui.gd")
const ESTYLE := preload("res://scripts/ui/eito/eito_style.gd")

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
	dimmer.color = Color(0.02, 0.03, 0.035, 0.84)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	# A paper dossier on the metal desk: ink type, phosphor readout cards pinned
	# across the middle, and a paper push-cap to go aboard.
	var panel := PanelContainer.new()
	_panel = panel
	panel.custom_minimum_size = Vector2(1120.0, 0.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	var badge := PanelContainer.new()
	var badge_style := StyleBoxFlat.new(); badge_style.bg_color = UI.INK
	badge_style.content_margin_left = 10; badge_style.content_margin_right = 10; badge_style.content_margin_top = 3; badge_style.content_margin_bottom = 3
	badge.add_theme_stylebox_override("panel", badge_style)
	badge.add_child(EC.label("MISSION BRIEFING", "EitoTag", 14, UI.PAPER))
	header_row.add_child(badge)
	var telemetry_tag := EC.label("FLIGHT RECORD DAY 184 / ASTERIA-1", "EitoTag", 12, Color("#6a5a2a"))
	telemetry_tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(telemetry_tag)
	header_row.add_child(EC.Lamp.new("ok"))
	header_row.add_child(EC.label("TELEMETRY LINKED", "EitoTag", 12, Color("#2f6b37")))
	content.add_child(header_row)

	var welcome := _label("Welcome aboard, Specialist Thura Min", 36, UI.INK)
	_welcome = welcome
	welcome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	welcome.custom_minimum_size.y = 44.0
	content.add_child(welcome)

	var status := _label("Day 184 aboard Asteria-1. Preparing for the Erebos survey.", 18, UI.INK_2)
	content.add_child(status)

	content.add_child(_rule())

	content.add_child(EC.label("OPERATION DIRECTIVE / SURVEY & EXTRACTION", "EitoTag", 13, Color("#6a5a2a")))

	var mission := _label(
		"Crewed deep-space industrial research expedition to survey minor planet Erebos and validate autonomous ore extraction systems.",
		18,
		UI.INK
	)
	mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission.custom_minimum_size.y = 26.0
	content.add_child(mission)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	content.add_child(cards)
	cards.add_child(_info_card("01 / DESTINATION", "Erebos (minor planet)", "High-density ore survey target; anomalous magnetic signature."))
	cards.add_child(_info_card("02 / ASSIGNMENT", "Planetary geology", "Lead specialist: autonomous drone deployment & core sampling."))
	cards.add_child(_info_card("03 / FIRST WATCH", "Report to the bridge", "Maya's assignment is waiting at the planning table. Other routine systems are running normally."))

	var crew := _label(
		"Crew onboard:  Maya Chen (CDR) · Elias Ward (PLT) · Amara Okoye (MED) · Leila Haddad (ENG) · Mateo Ruiz (MIN)",
		16,
		UI.INK
	)
	crew.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crew.custom_minimum_size.y = 24.0
	content.add_child(crew)

	var first_duty := _label("First objective: go west through the bridge corridor. Use the planning table beside the main helm to receive Maya's watch assignment. She will explain the work before you begin.", 16, UI.INK_2)
	first_duty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(first_duty)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_child(EC.Keycap.new("Enter"))
	actions.add_child(EC.label("or", "", 15, UI.INK_2))
	_continue_button = Button.new()
	_continue_button.theme_type_variation = &"PushButton"
	_continue_button.text = "ENTER SHIP DECK"
	_continue_button.custom_minimum_size = Vector2(250.0, 52.0)
	_continue_button.add_theme_font_size_override("font_size", 16)
	_continue_button.pressed.connect(_dismiss)
	actions.add_child(_continue_button)
	content.add_child(actions)


func _rule() -> Control:
	var r := ColorRect.new()
	r.color = Color("#a39a7b")
	r.custom_minimum_size = Vector2(0, 2)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _resize_briefing() -> void:
	var view := get_viewport().get_visible_rect().size
	_panel.custom_minimum_size.x = minf(1120.0, view.x-48.0)
	_welcome.add_theme_font_size_override("font_size", 30 if view.x<1150 else 36)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", maxi(12, font_size))
	label.add_theme_color_override("font_color", color)
	return label


func _info_card(heading: String, title: String, detail: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, 112.0)
	card.add_theme_stylebox_override("panel", _card_style())

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	card.add_child(stack)
	stack.add_child(EC.label(heading, "EitoTag", 12, UI.PHOS_DIM))

	var card_title := EC.label(title, "EitoValue", 19)
	card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(card_title)

	var card_detail := _label(detail, 15, Color("#8fd9b5"))
	card_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(card_detail)
	return card


func _panel_style() -> StyleBox:
	return ESTYLE.make("paper", 28.0)

func _card_style() -> StyleBox:
	return ESTYLE.make("glass", 14.0)

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
