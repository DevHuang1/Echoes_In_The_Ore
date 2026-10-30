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
const TITLE_CARD_DURATION := 2.2

var _root: Control
var _dimmer: ColorRect
var _letterbox_top: ColorRect
var _letterbox_bottom: ColorRect
var _center_container: CenterContainer
var _main_panel: PanelContainer

# Title Card Elements
var _title_card_overlay: Control
var _title_card_act_label: Label
var _title_card_title_label: Label
var _title_card_clock_label: Label
var _title_card_sub_label: Label
var _title_card_showing: bool = false
var _title_card_timer: float = 0.0

# Dialogue & Slide UI
var _act_badge: Label
var _clock_label: Label
var _pulse_indicator: Label
var _title_label: Label
var _artwork_rect: TextureRect
var _artwork_frame: PanelContainer
var _artwork_crt_vignette_overlay: Control
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
var _scroll_container: ScrollContainer
var _scroll_body: VBoxContainer

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
var _last_pulse_beat: int = 0

# Screen Shake & Tremor
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _last_image_path: String = ""


func _ready() -> void:
	layer = 28
	if _root == null:
		_build_ui()
	set_process(true)
	set_process_unhandled_input(true)
	_root.hide()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_update_letterbox_bars)
	_update_letterbox_bars()


func _update_letterbox_bars() -> void:
	if not is_instance_valid(_letterbox_top) or not is_instance_valid(_letterbox_bottom):
		return
	var vp_h: float = get_viewport().get_visible_rect().size.y if get_viewport() != null else 720.0
	var bar_h: float = clampf(vp_h * 0.12, 48.0, 140.0)
	_letterbox_top.custom_minimum_size.y = bar_h
	_letterbox_top.offset_bottom = bar_h
	_letterbox_bottom.custom_minimum_size.y = bar_h
	_letterbox_bottom.offset_top = -bar_h


func is_active() -> bool:
	return _is_active


func play_cutscene(cutscene_id: StringName, data: Dictionary) -> void:
	if _root == null:
		_build_ui()
	_update_letterbox_bars()
	_cutscene_id = cutscene_id
	_slides = data.get("slides", []).duplicate(true)
	if _slides.is_empty():
		return
	_slide_index = 0
	_selected_choice = &""
	_echo_pulse_active = bool(data.get("echo_pulse", false))
	_last_pulse_beat = 0
	_last_image_path = ""

	var act_text: String = str(data.get("act", "ACT I — THE LONG APPROACH")).to_upper()
	var clock_text: String = str(data.get("clock", "ASTERIA-1 // DAY 184 // EREBOS ORBIT")).to_upper()
	var title_text: String = str(data.get("title", "MISSION TRANSMISSION")).to_upper()

	_act_badge.text = "[ %s ]" % act_text
	_clock_label.text = clock_text
	_title_label.text = title_text

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

	var skip_title: bool = bool(data.get("skip_title_card", false))
	if not skip_title and not act_text.is_empty():
		_start_title_card(act_text, title_text, clock_text)
	else:
		_title_card_showing = false
		_title_card_overlay.hide()
		_center_container.show()
		_show_slide(0)


func _start_title_card(act_text: String, title_text: String, clock_text: String) -> void:
	_title_card_showing = true
	_title_card_timer = TITLE_CARD_DURATION
	_center_container.hide()

	_title_card_act_label.text = "[ %s ]" % act_text
	_title_card_title_label.text = "// %s" % title_text if not title_text.begins_with("//") else title_text
	_title_card_clock_label.text = clock_text
	if _echo_pulse_active:
		_title_card_sub_label.text = "● ACOUSTIC RESONANCE: 4-PULSE TREMOR DETECTED"
		_title_card_sub_label.add_theme_color_override("font_color", ECHO_RED)
	else:
		_title_card_sub_label.text = "TRANSMISSION FREQUENCY SECURED // ASTERIA-1 LOGS"
		_title_card_sub_label.add_theme_color_override("font_color", MUTED)

	_title_card_overlay.modulate.a = 0.0
	_title_card_overlay.show()
	var tween := create_tween()
	tween.tween_property(_title_card_overlay, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)

	DialogueAudioSynth.play_sfx("radio_squelch", self, -3.0)
	if _echo_pulse_active:
		DialogueAudioSynth.play_sfx("tremor_pulse", self, -1.0)
		trigger_screen_shake(4.0, 0.35)
		_last_pulse_beat = 1


func _dismiss_title_card() -> void:
	if not _title_card_showing:
		return
	_title_card_showing = false
	var tween := create_tween()
	tween.tween_property(_title_card_overlay, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		if is_instance_valid(_title_card_overlay):
			_title_card_overlay.hide()
		if is_instance_valid(_center_container):
			_center_container.show()
			_center_container.modulate.a = 0.0
			var f_in := create_tween()
			f_in.tween_property(_center_container, "modulate:a", 1.0, 0.3)
		_show_slide(0)
	)


func trigger_screen_shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_duration = maxf(0.05, duration)
	_shake_timer = _shake_duration


func _process(delta: float) -> void:
	if not _is_active:
		return

	# Title Card countdown
	if _title_card_showing:
		_title_card_timer -= delta
		if _title_card_timer <= 0.0:
			_dismiss_title_card()
			return

	# Screen Shake application
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var factor := clampf(_shake_timer / _shake_duration, 0.0, 1.0)
		var offset := Vector2(
			randf_range(-1.0, 1.0) * _shake_intensity * factor,
			randf_range(-1.0, 1.0) * _shake_intensity * factor
		)
		if is_instance_valid(_center_container) and _center_container.visible:
			_center_container.position = offset
		elif is_instance_valid(_title_card_overlay) and _title_card_overlay.visible:
			_title_card_overlay.position = offset
	else:
		if is_instance_valid(_center_container):
			_center_container.position = Vector2.ZERO
		if is_instance_valid(_title_card_overlay):
			_title_card_overlay.position = Vector2.ZERO

	# 4-pulse deep acoustic tremor heartbeats (rhythmic 4 pulses, 7-second pause)
	if _echo_pulse_active:
		_pulse_timer = fposmod(_pulse_timer + delta, 11.0)
		if _pulse_timer < 4.0:
			var beat: int = int(floorf(_pulse_timer)) + 1
			var flash: bool = fposmod(_pulse_timer, 1.0) < 0.45
			_pulse_indicator.text = "● ECHO SIGNAL: PULSE %d / 4" % beat if flash else "○ ECHO SIGNAL: PULSE %d / 4" % beat
			_pulse_indicator.add_theme_color_override("font_color", ECHO_RED if flash else ORANGE)
			if beat != _last_pulse_beat:
				_last_pulse_beat = beat
				DialogueAudioSynth.play_sfx("tremor_pulse", self, -2.5)
				trigger_screen_shake(3.2, 0.22)
		else:
			_last_pulse_beat = 0
			var pause_rem: int = maxi(1, int(ceilf(11.0 - _pulse_timer)))
			_pulse_indicator.text = "— 7-SECOND SILENCE (%dS) —" % pause_rem
			_pulse_indicator.add_theme_color_override("font_color", MUTED)
		_pulse_indicator.visible = true
	else:
		_pulse_indicator.visible = false

	if _is_typing:
		var prev_chars := int(_typed_chars)
		_typed_chars = minf(_typed_chars + delta * TYPEWRITER_SPEED, float(_total_chars))
		_dialogue_label.visible_characters = int(_typed_chars)
		if int(_typed_chars) > prev_chars and int(_typed_chars) % 4 == 0:
			DialogueAudioSynth.play_sfx("slider_tick", self, -14.0, &"UI", 0.15)
		if _dialogue_label.visible_characters >= _total_chars:
			_finish_typing_current_slide()


func _mark_handled() -> void:
	if is_inside_tree() and get_viewport() != null:
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return

	if _title_card_showing:
		if (event is InputEventKey and event.pressed and not event.echo) or \
		   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
		   (event is InputEventScreenTouch and event.pressed):
			_dismiss_title_card()
			_mark_handled()
			return

	if event is InputEventKey and event.pressed and not event.echo:
		if not _choices_box.get_children().is_empty():
			if event.keycode >= KEY_1 and event.keycode <= KEY_9:
				var idx := int(event.keycode) - int(KEY_1)
				if idx < _choices_box.get_child_count():
					var btn := _choices_box.get_child(idx) as Button
					if btn != null:
						btn.pressed.emit()
						_mark_handled()
						return
		if event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if _is_typing:
				_finish_typing_current_slide()
				_mark_handled()
			elif _choices_box.get_child_count() == 0:
				_on_advance_pressed()
				_mark_handled()
		elif event.keycode == KEY_ESCAPE:
			_on_skip_pressed()
			_mark_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_typing:
			_finish_typing_current_slide()
			_mark_handled()
		elif _choices_box.get_child_count() == 0:
			_on_advance_pressed()
			_mark_handled()
	elif event is InputEventScreenTouch and event.pressed:
		if _is_typing:
			_finish_typing_current_slide()
			_mark_handled()
		elif _choices_box.get_child_count() == 0:
			_on_advance_pressed()
			_mark_handled()


func _build_ui() -> void:
	_root = Control.new()
	SKIN.apply(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_dimmer = ColorRect.new()
	_dimmer.color = Color(0.005, 0.010, 0.018, 0.88)
	_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_dimmer.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			if _title_card_showing:
				_dismiss_title_card()
			elif _is_typing:
				_finish_typing_current_slide()
			elif _choices_box.get_child_count() == 0:
				_on_advance_pressed()
	)
	_root.add_child(_dimmer)

	# --- Full-width Cinematic Letterbox Bars ---
	_letterbox_top = ColorRect.new()
	_letterbox_top.color = Color(0.002, 0.004, 0.008, 1.0)
	_letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_letterbox_top.custom_minimum_size.y = 52.0
	_letterbox_top.offset_bottom = 52.0
	_letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_letterbox_top)

	_letterbox_bottom = ColorRect.new()
	_letterbox_bottom.color = Color(0.002, 0.004, 0.008, 1.0)
	_letterbox_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_letterbox_bottom.custom_minimum_size.y = 52.0
	_letterbox_bottom.offset_top = -52.0
	_letterbox_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_letterbox_bottom)

	# --- Title Card Dramatic Presentation Overlay ---
	_title_card_overlay = Control.new()
	_title_card_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_card_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_title_card_overlay)

	var tc_center := CenterContainer.new()
	tc_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tc_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_card_overlay.add_child(tc_center)

	var tc_box := VBoxContainer.new()
	tc_box.custom_minimum_size = Vector2(880.0, 0.0)
	tc_box.add_theme_constant_override("separation", 14)
	tc_box.alignment = BoxContainer.ALIGNMENT_CENTER
	tc_center.add_child(tc_box)

	_title_card_act_label = _make_label("[ ACT I — THE LONG APPROACH ]", 14, GOLD)
	_title_card_act_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc_box.add_child(_title_card_act_label)

	_title_card_title_label = _make_label("THE EMPTY SAMPLE POD", 22, PALE)
	_title_card_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_card_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tc_box.add_child(_title_card_title_label)

	var tc_sep := HSeparator.new()
	tc_sep.add_theme_color_override("separator_color", Color(GOLD.r, GOLD.g, GOLD.b, 0.6))
	tc_box.add_child(tc_sep)

	_title_card_clock_label = _make_label("ASTERIA-1 // DAY 184 // EREBOS ORBIT", 10, CYAN)
	_title_card_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc_box.add_child(_title_card_clock_label)

	_title_card_sub_label = _make_label("● ACOUSTIC RESONANCE: 4-PULSE TREMOR DETECTED", 10, ECHO_RED)
	_title_card_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc_box.add_child(_title_card_sub_label)

	var tc_hint := _make_label("[ CLICK OR PRESS SPACE / E TO ADVANCE ]", 9, MUTED)
	tc_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc_box.add_child(tc_hint)

	_title_card_overlay.hide()

	# --- Slide Layout Panel & Scroll Container ---
	_center_container = CenterContainer.new()
	_center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_center_container)

	_main_panel = PanelContainer.new()
	_main_panel.custom_minimum_size = Vector2(920.0, 0.0)
	_main_panel.add_theme_stylebox_override("panel", SKIN.panel(20.0))
	_center_container.add_child(_main_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_main_panel.add_child(vbox)

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

	# Scrollable body container for artwork, dialogue, rewards & choices
	_scroll_container = ScrollContainer.new()
	_scroll_container.custom_minimum_size = Vector2(880.0, 120.0)
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(_scroll_container)

	_scroll_body = VBoxContainer.new()
	_scroll_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_body.add_theme_constant_override("separation", 10)
	_scroll_container.add_child(_scroll_body)

	# Storyboard frame with CRT / Vignette border
	_artwork_frame = PanelContainer.new()
	_artwork_frame.custom_minimum_size = Vector2(0.0, 164.0)
	_artwork_frame.add_theme_stylebox_override("panel", SKIN.panel(10.0, true))
	_artwork_frame.visible = false
	_scroll_body.add_child(_artwork_frame)

	_artwork_rect = TextureRect.new()
	_artwork_rect.custom_minimum_size = Vector2(0.0, 150.0)
	_artwork_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_artwork_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_artwork_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_artwork_frame.add_child(_artwork_rect)

	_artwork_crt_vignette_overlay = Control.new()
	_artwork_crt_vignette_overlay.name = "ArtworkCrtVignetteOverlay"
	_artwork_crt_vignette_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_artwork_crt_vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_artwork_crt_vignette_overlay.draw.connect(_on_draw_artwork_crt_vignette)
	_artwork_frame.add_child(_artwork_crt_vignette_overlay)

	# Dialogue box
	var diag_panel := PanelContainer.new()
	diag_panel.custom_minimum_size = Vector2(0.0, 108.0)
	diag_panel.add_theme_stylebox_override("panel", SKIN.panel(14.0, true))
	diag_panel.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			if _is_typing:
				_finish_typing_current_slide()
			elif _choices_box.get_child_count() == 0:
				_on_advance_pressed()
	)
	_scroll_body.add_child(diag_panel)

	var diag_vbox := VBoxContainer.new()
	diag_vbox.add_theme_constant_override("separation", 6)
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
	_dialogue_label.add_theme_constant_override("line_spacing", 4)
	_dialogue_label.custom_minimum_size = Vector2(820.0, 54.0)
	diag_vbox.add_child(_dialogue_label)

	# Equipment reward showcase panel
	_reward_panel = PanelContainer.new()
	_reward_panel.add_theme_stylebox_override("panel", SKIN.panel(12.0, true))
	_reward_panel.visible = false
	_scroll_body.add_child(_reward_panel)

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
	_scroll_body.add_child(_choices_box)

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


func _update_scroll_height() -> void:
	if not is_instance_valid(_scroll_container) or not is_instance_valid(_scroll_body):
		return
	var body_h := _scroll_body.get_combined_minimum_size().y
	_scroll_container.custom_minimum_size.y = clampf(body_h, 120.0, 410.0)


func _show_slide(index: int) -> void:
	_slide_index = clampi(index, 0, _slides.size() - 1)
	var slide: Dictionary = _slides[_slide_index]
	var speaker: String = str(slide.get("speaker", "NARRATION")).to_upper()
	_speaker_badge.text = speaker
	_speaker_badge.add_theme_color_override("font_color", _speaker_color(speaker))
	_step_counter_label.text = "%02d / %02d" % [_slide_index + 1, _slides.size()]

	# Radio squelch or audio cue for incoming radio communications
	if speaker.find("INTERCOM") != -1 or speaker.find("RADIO") != -1 or speaker.find("CONTROL") != -1 or speaker.find("RECORDING") != -1:
		DialogueAudioSynth.play_sfx("radio_squelch", self, -5.0)
	elif speaker.find("ECHO") != -1 or speaker.find("VOICE") != -1:
		DialogueAudioSynth.play_sfx("echo_mimic_whisper", self, -3.0)

	# Screen tremors on impact moments (e.g. landing thud, reactor pulse, cargo breach)
	var slide_text: String = str(slide.get("text", ""))
	var slide_text_upper := slide_text.to_upper()
	if bool(slide.get("shake", false)) or slide_text_upper.find("THUD!") != -1 or slide_text_upper.find("IMPACT") != -1 or slide_text_upper.find("BREACH") != -1 or slide_text_upper.find("REACTOR PULSE") != -1 or slide_text_upper.find("REACTOR") != -1:
		DialogueAudioSynth.play_sfx("landing_thud", self, -1.0)
		trigger_screen_shake(8.0, 0.45)

	var img_path: String = str(slide.get("image", ""))
	if not img_path.is_empty() and ResourceLoader.exists(img_path):
		var new_tex := load(img_path) as Texture2D
		_artwork_rect.texture = new_tex
		_artwork_frame.visible = _artwork_rect.texture != null
		if is_instance_valid(_artwork_crt_vignette_overlay):
			_artwork_crt_vignette_overlay.visible = _artwork_frame.visible
			_artwork_crt_vignette_overlay.queue_redraw()
		if _last_image_path != img_path:
			_last_image_path = img_path
			_artwork_rect.modulate.a = 0.2
			var tween := create_tween()
			tween.tween_property(_artwork_rect, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	else:
		_artwork_frame.visible = false
		if is_instance_valid(_artwork_crt_vignette_overlay):
			_artwork_crt_vignette_overlay.visible = false
		_last_image_path = ""

	_dialogue_label.text = slide_text
	_total_chars = maxi(1, _dialogue_label.text.length())
	_typed_chars = 0.0
	_dialogue_label.visible_characters = 0
	_is_typing = true

	for child in _choices_box.get_children():
		child.queue_free()

	_advance_button.visible = true
	_advance_button.text = "[ SHOW TEXT ]"
	if is_instance_valid(_scroll_container):
		_scroll_container.scroll_vertical = 0
	_update_scroll_height()


func _finish_typing_current_slide() -> void:
	_is_typing = false
	_dialogue_label.visible_characters = -1
	var slide: Dictionary = _slides[_slide_index]
	var choices: Array = slide.get("choices", [])
	for child in _choices_box.get_children():
		child.queue_free()

	if not choices.is_empty():
		_advance_button.visible = false
		for i in choices.size():
			var choice_dict: Dictionary = choices[i]
			var btn := Button.new()
			var shortcut_prefix := "[%d] " % (i + 1)
			btn.text = "[ %s%s ]" % [shortcut_prefix, str(choice_dict.get("label", "SELECT")).to_upper()]
			btn.custom_minimum_size = Vector2(0.0, 38.0)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.add_theme_font_size_override("font_size", 10)
			var cid: StringName = StringName(choice_dict.get("id", &""))
			btn.pressed.connect(_on_choice_selected.bind(cid))
			_choices_box.add_child(btn)
		if _choices_box.get_child_count() > 0:
			var first_choice := _choices_box.get_child(0) as Control
			if is_inside_tree() and is_instance_valid(first_choice):
				first_choice.grab_focus()
	else:
		_advance_button.visible = true
		if _slide_index < _slides.size() - 1:
			_advance_button.text = "[ CONTINUE  › ]"
		else:
			_advance_button.text = "[ RESUME MISSION  → ]"
		if is_inside_tree():
			_advance_button.grab_focus()
	_update_scroll_height()


func _on_choice_selected(choice_id: StringName) -> void:
	DialogueAudioSynth.play_sfx("button_click", self, -4.0)
	_selected_choice = choice_id
	if _slide_index < _slides.size() - 1:
		_show_slide(_slide_index + 1)
	else:
		_close_cutscene()


func _on_advance_pressed() -> void:
	if _is_typing:
		_finish_typing_current_slide()
		return
	DialogueAudioSynth.play_sfx("button_click", self, -6.0)
	if _slide_index < _slides.size() - 1:
		_show_slide(_slide_index + 1)
	else:
		_close_cutscene()


func _on_skip_pressed() -> void:
	DialogueAudioSynth.play_sfx("close_cutscene", self, -3.0)
	_close_cutscene()


func _close_cutscene() -> void:
	if not _is_active:
		return
	_is_active = false
	_is_typing = false
	_title_card_showing = false
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


func _on_draw_artwork_crt_vignette() -> void:
	if not is_instance_valid(_artwork_crt_vignette_overlay):
		return
	var rect := _artwork_crt_vignette_overlay.get_rect()
	var w: float = rect.size.x
	var h: float = rect.size.y
	if w <= 1.0 or h <= 1.0:
		return

	# 1. CRT Scanlines (horizontal scanlines across artwork)
	var scanline_color := Color(0.0, 0.0, 0.0, 0.16)
	var y: float = 0.0
	while y < h:
		_artwork_crt_vignette_overlay.draw_line(Vector2(0, y), Vector2(w, y), scanline_color, 1.0)
		y += 3.0

	# 2. Cinematic Vignette (dark gradient around all edges)
	var vig_dark := Color(0.005, 0.012, 0.02, 0.65)
	var vig_mid := Color(0.005, 0.012, 0.02, 0.35)
	var vig_light := Color(0.005, 0.012, 0.02, 0.12)

	# Top vignette strips
	_artwork_crt_vignette_overlay.draw_rect(Rect2(0, 0, w, 4), vig_dark)
	_artwork_crt_vignette_overlay.draw_rect(Rect2(0, 4, w, 8), vig_mid)
	_artwork_crt_vignette_overlay.draw_rect(Rect2(0, 12, w, 12), vig_light)

	# Bottom vignette strips
	_artwork_crt_vignette_overlay.draw_rect(Rect2(0, h - 4, w, 4), vig_dark)
	_artwork_crt_vignette_overlay.draw_rect(Rect2(0, h - 12, w, 8), vig_mid)
	_artwork_crt_vignette_overlay.draw_rect(Rect2(0, h - 24, w, 12), vig_light)

	# Left vignette strips
	_artwork_crt_vignette_overlay.draw_rect(Rect2(0, 0, 4, h), vig_dark)
	_artwork_crt_vignette_overlay.draw_rect(Rect2(4, 0, 8, h), vig_mid)
	_artwork_crt_vignette_overlay.draw_rect(Rect2(12, 0, 12, h), vig_light)

	# Right vignette strips
	_artwork_crt_vignette_overlay.draw_rect(Rect2(w - 4, 0, 4, h), vig_dark)
	_artwork_crt_vignette_overlay.draw_rect(Rect2(w - 12, 0, 8, h), vig_mid)
	_artwork_crt_vignette_overlay.draw_rect(Rect2(w - 24, 0, 12, h), vig_light)

	# 3. Retro Phosphor Glow Border
	var border_glow := Color(0.35, 0.85, 1.0, 0.32) if not _echo_pulse_active else Color(1.0, 0.38, 0.34, 0.35)
	_artwork_crt_vignette_overlay.draw_rect(Rect2(0, 0, w, h), border_glow, false, 1.0)

