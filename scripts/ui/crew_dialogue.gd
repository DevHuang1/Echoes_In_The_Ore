class_name CrewDialogue
extends CanvasLayer

const SKIN := preload("res://scripts/ui/pixel_ui.gd")

signal dialogue_finished(accepted_tasks: bool)
signal conversation_finished(conversation_id: String, result_id: String)

const PALE := Color(0.94, 0.91, 0.82)
const MUTED := Color(0.59, 0.69, 0.73)
const GOLD := Color(1.0, 0.77, 0.34)

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
var conversation_id := ""
var _choices: Array = []
var _choice_row: HBoxContainer
var _choice_buttons: Array[Button] = []


func _ready() -> void:
	layer = 20
	_build_ui()
	set_process_input(true)
	set_process(true)
	_root.hide()
	get_viewport().size_changed.connect(_resize_bubble)
	_resize_bubble()


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


func start_dialogue(lines: Array[String], offer_enabled: bool = false, context: Dictionary = {}) -> void:
	if lines.is_empty():
		return
	_lines = lines.duplicate()
	_line_index = 0
	_offer_enabled = offer_enabled
	conversation_id = str(context.get("id", ""))
	_speaker_label.text = str(context.get("speaker", "AMARA OKOYE / MED / HYDROPONICS"))
	_choices = context.get("choices", []).duplicate(true)
	for child in _choice_row.get_children():
		_choice_row.remove_child(child); child.queue_free()
	_choice_buttons.clear()
	for choice in _choices:
		var button := Button.new()
		button.text = str(choice.label)
		button.custom_minimum_size.y = 36
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_choose.bind(str(choice.id)))
		_choice_row.add_child(button); _choice_buttons.append(button)
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
		if event.pressed and event.keycode == KEY_ESCAPE:
			cancel_dialogue(); get_viewport().set_input_as_handled(); return
		advance = advance or (event.pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
		if event.pressed and not _is_typing and _line_index == _lines.size()-1 and not _choices.is_empty():
			var index := int(event.keycode) - int(KEY_1)
			if index >= 0 and index < _choices.size():
				_choose(str(_choices[index].id)); get_viewport().set_input_as_handled(); return
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
	elif not _choices.is_empty():
		if advance: _choose(str(_choices[0].id))
		elif decline: _choose(str(_choices[-1].id))
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
	SKIN.apply(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_bubble = PanelContainer.new()
	_bubble.name = "AmaraSpeechBubble"
	_bubble.anchor_left = 0.5
	_bubble.anchor_right = 0.5
	_bubble.anchor_top = 1.0
	_bubble.anchor_bottom = 1.0
	_bubble.offset_left = -430.0
	_bubble.offset_top = -330.0
	_bubble.offset_right = 430.0
	_bubble.offset_bottom = -106.0
	_bubble.add_theme_stylebox_override("panel", _bubble_style())
	_root.add_child(_bubble)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	_bubble.add_child(content)
	_speaker_label = Label.new()
	_speaker_label.text = "AMARA OKOYE   /   HYDROPONICS"
	_speaker_label.add_theme_font_size_override("font_size", 12)
	_speaker_label.add_theme_color_override("font_color", GOLD)
	content.add_child(_speaker_label)
	_dialogue_label = Label.new()
	_dialogue_label.custom_minimum_size = Vector2(0.0, 70.0)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_font_size_override("font_size", 16)
	_dialogue_label.add_theme_color_override("font_color", PALE)
	content.add_child(_dialogue_label)
	_choice_row = HBoxContainer.new()
	_choice_row.add_theme_constant_override("separation", 8)
	content.add_child(_choice_row)
	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt_label.add_theme_font_size_override("font_size", 12)
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
	_choice_row.visible = not _is_typing and _line_index == _lines.size()-1 and not _choices.is_empty()
	if _is_typing:
		_prompt_label.text = "[E]  SHOW LINE"
	elif _line_index < _lines.size() - 1:
		_prompt_label.text = "[E]  CONTINUE"
	elif not _choices.is_empty():
		_prompt_label.text = "[E] FIRST RESPONSE / [1-%d] CHOOSE / [Q] %s / ESC CLOSE" % [_choices.size(), str(_choices[-1].label).to_upper()]
	elif _offer_enabled:
		_prompt_label.text = "[E]  TAKE TASKS     [Q]  MAYBE LATER"
	else:
		_prompt_label.text = "[E]  CLOSE"


func _finish(accepted_tasks: bool) -> void:
	if not conversation_id.is_empty():
		_choose(str(_choices[0].id) if accepted_tasks and not _choices.is_empty() else "closed")
		return
	_is_active = false
	_is_typing = false
	_root.hide()
	dialogue_finished.emit(accepted_tasks)

func _choose(result_id: String) -> void:
	if not _is_active: return
	_is_active = false; _is_typing = false; _root.hide()
	conversation_finished.emit(conversation_id, result_id)

func cancel_dialogue() -> void:
	if not _is_active: return
	if conversation_id.is_empty(): _finish(false)
	else: _choose("cancelled")

func _resize_bubble() -> void:
	if not is_instance_valid(_bubble): return
	var width := minf(900.0, get_viewport().get_visible_rect().size.x-48.0)
	_bubble.offset_left = -width*0.5; _bubble.offset_right = width*0.5

func _exit_tree() -> void:
	cancel_dialogue()


func _bubble_style() -> StyleBox:
	return SKIN.panel(20.0)
