class_name StoryCutsceneOverlay
extends CanvasLayer

signal cutscene_finished(cutscene_id: StringName, choice_id: StringName)

const SKIN := preload("res://scripts/ui/pixel_ui.gd")

const GOLD := Color(1.0, 0.78, 0.38)
const PALE := Color(0.95, 0.92, 0.84)
const MUTED := Color(0.66, 0.76, 0.80)
const CYAN := Color(0.36, 0.90, 1.0)
const ORANGE := Color(1.0, 0.68, 0.32)
const GREEN := Color(0.48, 0.93, 0.64)
const ECHO_RED := Color(1.0, 0.38, 0.34)
const SURFACE_DARK := Color(0.012, 0.024, 0.038, 0.96)

const TYPEWRITER_SPEED := 42.0

var _root: Control
var _blackout_layer: ColorRect
var _act_badge: Label
var _clock_label: Label
var _pulse_indicator: Label
var _title_label: Label
var _artwork_rect: TextureRect
var _artwork_frame: PanelContainer
var _speaker_badge: Label
var _dialogue_label: Label
var _step_counter_label: Label
var _reward_panel: PanelContainer
var _reward_icon: TextureRect
var _reward_title: Label
var _reward_desc: Label
var _choices_box: VBoxContainer
var _advance_button: Button
var _skip_button: Button

var _cutscene_id: StringName = &""
var _slides: Array = []
var _slide_index: int = 0
var _typed_chars: float = 0.0
var _total_chars: int = 0
var _is_typing: bool = false
var _is_active: bool = false
var _selected_choice: StringName = &""
var _pulse_timer: float = 0.0
var _echo_pulse_active: bool = false
var _blackout_timer: float = 0.0
var _auto_advance_timer: float = 0.0
var _typing_speed: float = TYPEWRITER_SPEED
var _image_fade_tween: Tween


func _ready() -> void:
	layer = 28
	_build_ui()
	set_process(true)
	set_process_unhandled_input(true)
	_root.hide()


func is_active() -> bool:
	return _is_active


func play_cutscene(cutscene_id: StringName, data: Dictionary) -> void:
	_cutscene_id = cutscene_id
	_slides = data.get("slides", []).duplicate(true)
	if _slides.is_empty():
		return
	var large_artwork := bool(data.get("large_artwork", false))
	_artwork_frame.custom_minimum_size.y = 350.0 if large_artwork else 180.0
	_artwork_rect.custom_minimum_size.y = 334.0 if large_artwork else 164.0
	_slide_index = 0
	_selected_choice = &""
	_echo_pulse_active = bool(data.get("echo_pulse", false))
	_act_badge.text = "[ %s ]" % str(data.get("act", "ACT I — THE LONG APPROACH")).to_upper()
	_clock_label.text = str(data.get("clock", "ASTERIA-1 // DAY 184 // EREBOS ORBIT")).to_upper()
	_title_label.text = str(data.get("title", "MISSION TRANSMISSION")).to_upper()

	var reward: Dictionary = data.get("reward", {})
	if not reward.is_empty():
		_reward_panel.visible = true
		_reward_title.text = "EQUIPMENT UNLOCKED: %s" % str(reward.get("name", "TOOL")).to_upper()
		_reward_desc.text = str(reward.get("desc", "Added to your active hotbar."))
		var tex: Texture2D = reward.get("texture", null) as Texture2D
		_reward_icon.texture = tex
		_reward_icon.visible = tex != null
	else:
		_reward_panel.visible = false

	_is_active = true
	_root.show()
	_show_slide(0)


func _process(delta: float) -> void:
	if not _is_active:
		return
	if _blackout_timer > 0.0:
		_blackout_timer = maxf(0.0, _blackout_timer - delta)
		if _blackout_timer <= 0.0:
			if _slide_index < _slides.size() - 1:
				_show_slide(_slide_index + 1)
			else:
				_close_cutscene()
		return
	if _auto_advance_timer > 0.0:
		_auto_advance_timer = maxf(0.0, _auto_advance_timer - delta)
		if _auto_advance_timer <= 0.0:
			if _slide_index < _slides.size() - 1:
				_show_slide(_slide_index + 1)
			else:
				_close_cutscene()
		return

	if _echo_pulse_active:
		_pulse_timer = fposmod(_pulse_timer + delta, 11.0)
		if _pulse_timer < 4.0:
			var beat: int = int(floorf(_pulse_timer)) + 1
			var flash: bool = fposmod(_pulse_timer, 1.0) < 0.45
			_pulse_indicator.text = "● ECHO SIGNAL: PULSE %d / 4" % beat if flash else "○ ECHO SIGNAL: PULSE %d / 4" % beat
			_pulse_indicator.add_theme_color_override("font_color", ECHO_RED if flash else ORANGE)
		else:
			var pause_rem: int = maxi(1, int(ceilf(11.0 - _pulse_timer)))
			_pulse_indicator.text = "— 7-SECOND SILENCE (%dS) —" % pause_rem
			_pulse_indicator.add_theme_color_override("font_color", MUTED)
		_pulse_indicator.visible = true
	else:
		_pulse_indicator.visible = false

	if _is_typing:
		_typed_chars = minf(_typed_chars + delta * _typing_speed, float(_total_chars))
		_dialogue_label.visible_characters = int(_typed_chars)
		if _dialogue_label.visible_characters >= _total_chars:
			_finish_typing_current_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return
	if _blackout_layer.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_on_skip_pressed()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if _is_typing:
				_finish_typing_current_slide()
				get_viewport().set_input_as_handled()
			elif _choices_box.get_child_count() == 0:
				_on_advance_pressed()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_on_skip_pressed()
			get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_root = Control.new()
	SKIN.apply(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.005, 0.012, 0.022, 0.88)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	_blackout_layer = ColorRect.new()
	_blackout_layer.color = Color.BLACK
	_blackout_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blackout_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_blackout_layer.hide()
	_root.add_child(_blackout_layer)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920.0, 0.0)
	panel.add_theme_stylebox_override("panel", SKIN.panel(22.0))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Top meta bar
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	_act_badge = _make_label("[ ACT I — THE LONG APPROACH ]", 9, GOLD)
	top_row.add_child(_act_badge)
	_clock_label = _make_label("ASTERIA-1 // DAY 184", 9, MUTED)
	top_row.add_child(_clock_label)
	top_row.add_spacer(false)
	_pulse_indicator = _make_label("● ECHO SIGNAL: 4 PULSES / 7S PAUSE", 9, ECHO_RED)
	top_row.add_child(_pulse_indicator)
	_skip_button = Button.new()
	_skip_button.text = "[ SKIP ]"
	_skip_button.custom_minimum_size = Vector2(96.0, 32.0)
	_skip_button.add_theme_font_size_override("font_size", 9)
	_skip_button.pressed.connect(_on_skip_pressed)
	top_row.add_child(_skip_button)
	vbox.add_child(top_row)

	_title_label = _make_label("STORY CUTSCENE", 15, PALE)
	vbox.add_child(_title_label)

	var sep := HSeparator.new()
	sep.add_theme_color_override("separator_color", Color(0.55, 0.44, 0.25, 0.7))
	vbox.add_child(sep)

	# Optional storyboard image frame
	_artwork_frame = PanelContainer.new()
	_artwork_frame.custom_minimum_size = Vector2(0.0, 180.0)
	_artwork_frame.add_theme_stylebox_override("panel", SKIN.panel(8.0, true))
	_artwork_frame.visible = false
	vbox.add_child(_artwork_frame)

	_artwork_rect = TextureRect.new()
	_artwork_rect.custom_minimum_size = Vector2(0.0, 164.0)
	_artwork_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_artwork_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_artwork_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_artwork_frame.add_child(_artwork_rect)

	# Dialogue box
	var diag_panel := PanelContainer.new()
	diag_panel.custom_minimum_size = Vector2(0.0, 132.0)
	diag_panel.add_theme_stylebox_override("panel", SKIN.panel(14.0, true))
	vbox.add_child(diag_panel)

	var diag_vbox := VBoxContainer.new()
	diag_vbox.add_theme_constant_override("separation", 8)
	diag_panel.add_child(diag_vbox)

	var speaker_row := HBoxContainer.new()
	_speaker_badge = _make_label("DR. THURA MIN // PLANETARY GEOLOGIST", 10, CYAN)
	speaker_row.add_child(_speaker_badge)
	speaker_row.add_spacer(false)
	_step_counter_label = _make_label("01 / 01", 9, MUTED)
	speaker_row.add_child(_step_counter_label)
	diag_vbox.add_child(speaker_row)

	_dialogue_label = _make_label("", 11, PALE)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_constant_override("line_spacing", 5)
	_dialogue_label.custom_minimum_size = Vector2(820.0, 78.0)
	diag_vbox.add_child(_dialogue_label)

	# Equipment reward showcase panel
	_reward_panel = PanelContainer.new()
	_reward_panel.add_theme_stylebox_override("panel", SKIN.panel(12.0, true))
	_reward_panel.visible = false
	vbox.add_child(_reward_panel)

	var reward_hbox := HBoxContainer.new()
	reward_hbox.add_theme_constant_override("separation", 14)
	_reward_panel.add_child(reward_hbox)

	_reward_icon = TextureRect.new()
	_reward_icon.custom_minimum_size = Vector2(44.0, 44.0)
	_reward_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_reward_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	reward_hbox.add_child(_reward_icon)

	var reward_text_vbox := VBoxContainer.new()
	reward_text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_text_vbox.add_theme_constant_override("separation", 4)
	_reward_title = _make_label("EQUIPMENT UNLOCKED", 10, GREEN)
	_reward_desc = _make_label("", 9, PALE)
	_reward_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_text_vbox.add_child(_reward_title)
	reward_text_vbox.add_child(_reward_desc)
	reward_hbox.add_child(reward_text_vbox)

	# Choices container (for branching decisions & Act V Endings)
	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 6)
	vbox.add_child(_choices_box)

	# Footer action row
	var footer_row := HBoxContainer.new()
	var hint_lbl := _make_label("[E / SPACE / TAP] CONTINUE", 9, MUTED)
	footer_row.add_child(hint_lbl)
	footer_row.add_spacer(false)
	_advance_button = Button.new()
	_advance_button.text = "[ CONTINUE  › ]"
	_advance_button.custom_minimum_size = Vector2(210.0, 42.0)
	_advance_button.add_theme_font_size_override("font_size", 11)
	_advance_button.pressed.connect(_on_advance_pressed)
	footer_row.add_child(_advance_button)
	vbox.add_child(footer_row)


func _update_step_counter(current_index: int) -> void:
	var current_step := 0
	var total_steps := 0
	for slide_index in range(_slides.size()):
		var slide_data: Dictionary = _slides[slide_index]
		if bool(slide_data.get("blackout", false)):
			continue
		total_steps += 1
		if slide_index <= current_index:
			current_step += 1
	_step_counter_label.text = "%02d / %02d" % [current_step, total_steps]


func _show_slide(index: int) -> void:
	_slide_index = clampi(index, 0, _slides.size() - 1)
	_auto_advance_timer = 0.0
	var slide: Dictionary = _slides[_slide_index]
	if bool(slide.get("blackout", false)):
		_is_typing = false
		_blackout_timer = maxf(0.1, float(slide.get("hold_seconds", 2.8)))
		_blackout_layer.show()
		return
	_blackout_timer = 0.0
	_blackout_layer.hide()
	var speaker: String = str(slide.get("speaker", "NARRATION")).to_upper()
	_speaker_badge.text = speaker
	_speaker_badge.add_theme_color_override("font_color", _speaker_color(speaker))
	_update_step_counter(_slide_index)

	var img_path: String = str(slide.get("image", ""))
	if not img_path.is_empty() and ResourceLoader.exists(img_path):
		_artwork_rect.texture = load(img_path) as Texture2D
		_artwork_frame.visible = _artwork_rect.texture != null
		if is_instance_valid(_image_fade_tween) and _image_fade_tween.is_running():
			_image_fade_tween.kill()
		var fade_seconds := maxf(0.0, float(slide.get("fade_in_seconds", 0.0)))
		_artwork_rect.modulate = Color(1.0, 1.0, 1.0, 0.0 if fade_seconds > 0.0 else 1.0)
		if fade_seconds > 0.0:
			_image_fade_tween = create_tween()
			_image_fade_tween.tween_property(_artwork_rect, "modulate:a", 1.0, fade_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		_artwork_rect.modulate = Color.WHITE
		_artwork_frame.visible = false

	_dialogue_label.text = str(slide.get("text", ""))
	_total_chars = maxi(1, _dialogue_label.text.length())
	_typed_chars = 0.0
	_dialogue_label.visible_characters = 0
	_is_typing = true
	_typing_speed = maxf(1.0, float(slide.get("typing_speed", TYPEWRITER_SPEED)))

	for child in _choices_box.get_children():
		child.queue_free()

	_advance_button.visible = true
	_advance_button.text = "[ SHOW TEXT ]"


func _finish_typing_current_slide() -> void:
	_is_typing = false
	_dialogue_label.visible_characters = -1
	var slide: Dictionary = _slides[_slide_index]
	var choices: Array = slide.get("choices", [])
	for child in _choices_box.get_children():
		child.queue_free()

	if not choices.is_empty():
		_advance_button.visible = false
		for ch in choices:
			var choice_dict: Dictionary = ch
			var btn := Button.new()
			btn.text = "[ %s ]" % str(choice_dict.get("label", "SELECT")).to_upper()
			btn.custom_minimum_size = Vector2(0.0, 38.0)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.add_theme_font_size_override("font_size", 10)
			var cid: StringName = StringName(choice_dict.get("id", &""))
			btn.pressed.connect(func(): _on_choice_selected(cid))
			_choices_box.add_child(btn)
		if _choices_box.get_child_count() > 0:
			(_choices_box.get_child(0) as Control).grab_focus()
	else:
		_advance_button.visible = true
		if _slide_index < _slides.size() - 1:
			_advance_button.text = "[ CONTINUE  › ]"
		else:
			_advance_button.text = "[ RESUME MISSION  → ]"
		var auto_delay := maxf(0.0, float(slide.get("auto_advance_seconds", 0.0)))
		if auto_delay > 0.0:
			_auto_advance_timer = auto_delay
			_advance_button.text = "[ SKIP AHEAD  › ]"
		_advance_button.grab_focus()


func _on_choice_selected(choice_id: StringName) -> void:
	_selected_choice = choice_id
	if _slide_index < _slides.size() - 1:
		_show_slide(_slide_index + 1)
	else:
		_close_cutscene()


func _on_advance_pressed() -> void:
	if _is_typing:
		_finish_typing_current_slide()
		return
	_auto_advance_timer = 0.0
	if _slide_index < _slides.size() - 1:
		_show_slide(_slide_index + 1)
	else:
		_close_cutscene()


func _on_skip_pressed() -> void:
	_close_cutscene()


func _close_cutscene() -> void:
	if not _is_active:
		return
	_is_active = false
	_is_typing = false
	_blackout_timer = 0.0
	_auto_advance_timer = 0.0
	_blackout_layer.hide()
	_root.hide()
	var finished_id := _cutscene_id
	var chosen := _selected_choice
	cutscene_finished.emit(finished_id, chosen)


func _speaker_color(speaker: String) -> Color:
	if speaker.find("ECHO") != -1 or speaker.find("VOICE") != -1:
		return ECHO_RED
	if speaker.find("THURA") != -1:
		return CYAN
	if speaker.find("AMARA") != -1 or speaker.find("OKOYE") != -1 or speaker.find("MISSION CONTROL") != -1:
		return GREEN
	if speaker.find("LEILA") != -1 or speaker.find("RUIZ") != -1:
		return ORANGE
	if speaker.find("CHEN") != -1 or speaker.find("MAY") != -1 or speaker.find("MOTHER") != -1:
		return GOLD
	return PALE


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", maxi(8, font_size))
	lbl.add_theme_constant_override("line_spacing", 4)
	lbl.add_theme_color_override("font_color", color)
	return lbl
