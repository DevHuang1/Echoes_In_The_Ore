class_name CrewDialogue
extends CanvasLayer

signal dialogue_finished(accepted_tasks: bool)

const PALE := Color(0.94, 0.97, 0.96)
const MUTED := Color(0.62, 0.75, 0.77)
const GOLD := Color(1.0, 0.76, 0.39)
const SURFACE := Color(0.025, 0.065, 0.078, 0.97)
const EDGE := Color(0.34, 0.62, 0.61)

const TYPEWRITER_CHARS_PER_SECOND := 38.0

var _root: Control
var _bubble: PanelContainer
var _speaker_label: Label
var _dialogue_label: Label
var _prompt_label: Label
var _lines: Array[String] = []
var _line_index := 0
var _visible_characters := 0
var _typewriter_progress := 0.0
var _is_typing := false
var _is_active := false
var _offer_enabled := false


func _ready() -> void:
	layer = 20
	_build_ui()
	set_process_input(true)
	set_process(true)
	_root.hide()


func _process(delta: float) -> void:
	if not _is_typing:
		return
	_typewriter_progress += delta * TYPEWRITER_CHARS_PER_SECOND
	var new_visible_count := mini(int(_typewriter_progress), _dialogue_label.text.length())
	if new_visible_count != _visible_characters:
		_visible_characters = new_visible_count
		_dialogue_label.visible_characters = _visible_characters
	if _visible_characters >= _dialogue_label.text.length():
		_is_typing = false
		_refresh_prompt()


func start_dialogue(lines: Array[String], offer_enabled: bool = false) -> void:
	if lines.is_empty():
		return
	_lines = lines.duplicate()
	_line_index = 0
	_offer_enabled = offer_enabled
	_is_active = true
	_root.show()
	_show_current_line()


func _input(event: InputEvent) -> void:
	if not _is_active or (event is InputEventKey and event.echo):
		return
	var advance := event.is_action_pressed(&"interact")
	var decline: bool = false
	if event is InputEventKey:
		decline = event.pressed and event.keycode == KEY_Q
	if not advance and not decline:
		return
	if _is_typing:
		if advance:
			_reveal_current_line()
		get_viewport().set_input_as_handled()
		return
	if _line_index < _lines.size() - 1:
		if advance:
			_line_index += 1
			_show_current_line()
	elif _offer_enabled:
		if advance:
			_finish(true)
		elif decline:
			_finish(false)
	elif advance:
		_finish(false)
	get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_bubble = PanelContainer.new()
	_bubble.name = "AmaraSpeechBubble"
	_bubble.anchor_left = 0.5
	_bubble.anchor_right = 0.5
	_bubble.anchor_top = 1.0
	_bubble.anchor_bottom = 1.0
	_bubble.offset_left = -365.0
	_bubble.offset_top = -236.0
	_bubble.offset_right = 365.0
	_bubble.offset_bottom = -106.0
	_bubble.add_theme_stylebox_override("panel", _bubble_style())
	_root.add_child(_bubble)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	_bubble.add_child(content)
	_speaker_label = Label.new()
	_speaker_label.text = "AMARA OKOYE   /   HYDROPONICS"
	_speaker_label.add_theme_font_size_override("font_size", 11)
	_speaker_label.add_theme_color_override("font_color", GOLD)
	content.add_child(_speaker_label)
	_dialogue_label = Label.new()
	_dialogue_label.custom_minimum_size = Vector2(690.0, 50.0)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_font_size_override("font_size", 15)
	_dialogue_label.add_theme_color_override("font_color", PALE)
	content.add_child(_dialogue_label)
	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt_label.add_theme_font_size_override("font_size", 10)
	_prompt_label.add_theme_color_override("font_color", MUTED)
	content.add_child(_prompt_label)


func _show_current_line() -> void:
	_dialogue_label.text = _lines[_line_index]
	_visible_characters = 0
	_typewriter_progress = 0.0
	_is_typing = not _dialogue_label.text.is_empty()
	_dialogue_label.visible_characters = 0 if _is_typing else -1
	_refresh_prompt()


func _reveal_current_line() -> void:
	_is_typing = false
	_visible_characters = _dialogue_label.text.length()
	_dialogue_label.visible_characters = -1
	_refresh_prompt()


func _refresh_prompt() -> void:
	if _is_typing:
		_prompt_label.text = "[E]  SHOW LINE"
	elif _line_index < _lines.size() - 1:
		_prompt_label.text = "[E]  CONTINUE"
	elif _offer_enabled:
		_prompt_label.text = "[E]  TAKE TASKS     [Q]  MAYBE LATER"
	else:
		_prompt_label.text = "[E]  CLOSE"


func _finish(accepted_tasks: bool) -> void:
	_is_active = false
	_is_typing = false
	_root.hide()
	dialogue_finished.emit(accepted_tasks)


func _bubble_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SURFACE
	style.border_color = EDGE
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.set_corner_radius_all(12)
	style.content_margin_left = 19.0
	style.content_margin_right = 19.0
	style.content_margin_top = 13.0
	style.content_margin_bottom = 11.0
	return style
