class_name CrewDialogue
extends CanvasLayer

const SKIN := preload("res://scripts/ui/pixel_ui.gd")
const AUDIO_SYNTH := preload("res://scripts/audio/dialogue_audio_synth.gd")

const THURA_ATLAS_TEX: Texture2D = preload("res://art/characters/runtime/thura_walk_4dir.png")
const AMARA_ATLAS_TEX: Texture2D = preload("res://art/characters/runtime/amara_okoye_lab_walk_4dir.png")

signal dialogue_finished(accepted_tasks: bool)
signal conversation_finished(conversation_id: String, result_id: String)

const PALE := Color(0.94, 0.91, 0.82)
const MUTED := Color(0.59, 0.69, 0.73)
const GOLD := Color(1.0, 0.77, 0.34)
const CYAN := Color(0.38, 0.88, 0.98)
const ORANGE := Color(1.0, 0.68, 0.32)
const EMERALD := Color(0.42, 0.92, 0.65)
const DARK_BG := Color(0.018, 0.032, 0.048, 0.96)
const BORDER_CYAN := Color(0.24, 0.58, 0.74, 0.85)
const BORDER_GOLD := Color(0.95, 0.76, 0.32, 0.95)

const TYPEWRITER_CHARS_PER_SECOND := 42.0

# Base required properties
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

# Cutscene enhancements
var _top_bar: PanelContainer
var _bottom_bar: PanelContainer
var _rec_label: Label
var _cam_telemetry: Label
var _waveform_label: Label

# Character portraits
var _portraits_container: HBoxContainer
var _player_portrait_panel: PanelContainer
var _player_portrait_rect: TextureRect
var _player_name_label: Label
var _player_status_badge: Label

var _npc_portrait_panel: PanelContainer
var _npc_portrait_rect: TextureRect
var _npc_name_label: Label
var _npc_role_label: Label
var _npc_status_badge: Label
var _npc_hologram_overlay: Control

# SFX & Audio
var _sfx_player: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _snd_open: AudioStreamWAV
var _snd_close: AudioStreamWAV
var _snd_hover: AudioStreamWAV
var _snd_click: AudioStreamWAV
var _snd_advance: AudioStreamWAV
var _snd_speech_amara: AudioStreamWAV
var _snd_speech_thura: AudioStreamWAV
var _snd_speech_chen: AudioStreamWAV
var _snd_speech_mateo: AudioStreamWAV
var _snd_speech_ward: AudioStreamWAV
var _snd_speech_leila: AudioStreamWAV
var _snd_speech_terminal: AudioStreamWAV
var _last_char_sound_pos := -1

# Camera close-up cutscene
var _camera: Camera2D = null
var _original_camera_pos := Vector2.ZERO
var _original_camera_zoom := Vector2(1.75, 1.75)
var _target_npc: Node2D = null
var _camera_tween: Tween = null
var _in_cutscene := false

# VFX & Animation state
var _fx_overlay: Control
var _anim_timer := 0.0
var _waveform_phase := 0.0
var _spores: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _current_speaker_kind := "amara" # "amara", "thura", "terminal"
var _offer_buttons: Array[Button] = []


func _ready() -> void:
	layer = 24
	_rng.randomize()
	_init_audio()
	_init_particles()
	_build_ui()
	set_process_input(true)
	set_process(true)
	_root.hide()
	var vp := get_viewport()
	if is_instance_valid(vp):
		vp.size_changed.connect(_resize_bubble)
	_resize_bubble()


func _init_audio() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = &"Master"
	add_child(_sfx_player)

	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = &"Master"
	_voice_player.volume_db = -4.0
	add_child(_voice_player)

	_snd_open = AUDIO_SYNTH.create_open_cutscene()
	_snd_close = AUDIO_SYNTH.create_close_cutscene()
	_snd_hover = AUDIO_SYNTH.create_button_hover()
	_snd_click = AUDIO_SYNTH.create_button_click()
	_snd_advance = AUDIO_SYNTH.create_page_advance()
	_snd_speech_amara = AUDIO_SYNTH.create_speech_amara()
	_snd_speech_thura = AUDIO_SYNTH.create_speech_thura()
	_snd_speech_chen = AUDIO_SYNTH.create_speech_chen()
	_snd_speech_mateo = AUDIO_SYNTH.create_speech_mateo()
	_snd_speech_ward = AUDIO_SYNTH.create_speech_ward()
	_snd_speech_leila = AUDIO_SYNTH.create_speech_leila()
	_snd_speech_terminal = AUDIO_SYNTH.create_speech_terminal()


func _init_particles() -> void:
	_spores.clear()
	for i in range(22):
		_spores.append({
			"pos": Vector2(_rng.randf_range(0.0, 1280.0), _rng.randf_range(0.0, 720.0)),
			"vel": Vector2(_rng.randf_range(-14.0, 14.0), _rng.randf_range(-18.0, -6.0)),
			"size": _rng.randf_range(1.5, 3.2),
			"alpha": _rng.randf_range(0.2, 0.75),
			"pulse_speed": _rng.randf_range(2.0, 5.0),
			"phase": _rng.randf_range(0.0, TAU),
			"color": Color(0.4, 0.95, 0.72) if _rng.randf() > 0.4 else Color(0.35, 0.8, 1.0)
		})


func _process(delta: float) -> void:
	if not _is_active:
		return

	_anim_timer += delta

	# 1. Update typewriter progress
	if _is_typing:
		_typewriter_progress += delta * TYPEWRITER_CHARS_PER_SECOND
		var new_visible_count := mini(int(_typewriter_progress), _dialogue_label.text.length())
		if new_visible_count != _visible_characters:
			_visible_characters = new_visible_count
			_dialogue_label.visible_characters = _visible_characters

			# Play voice blips on character jumps
			if _visible_characters > _last_char_sound_pos + 2:
				_last_char_sound_pos = _visible_characters
				var next_char := ""
				if _visible_characters > 0 and _visible_characters <= _dialogue_label.text.length():
					next_char = _dialogue_label.text[_visible_characters - 1]
				if next_char != " " and next_char != "\n":
					_play_voice_blip()

		if _visible_characters >= _dialogue_label.text.length():
			_is_typing = false
			_dialogue_label.visible_characters = -1
			_refresh_prompt()
			_update_speaker_visuals()

	# 2. Update recording indicator and telemetry
	if is_instance_valid(_rec_label):
		var rec_blink := sin(_anim_timer * 4.0) > -0.2
		_rec_label.text = "● REC // COMMS CH-01 // BIO-SPEC" if rec_blink else "○ REC // COMMS CH-01 // BIO-SPEC"
		_rec_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3) if rec_blink else Color(0.6, 0.2, 0.2))

	# 3. Update waveform audio visualizer
	if is_instance_valid(_waveform_label):
		if _is_typing:
			_waveform_phase += delta * 14.0
			var wave_frames := [" ▂▃▅▆▅▃▂ ", "▂▃▅▇▆▅▃▂ ", "▃▅▆▇▅▃▂  ", "▅▇▆▅▃▂ ▂▃", "▆▅▃▂ ▂▃▅▇"]
			var frame_idx := int(_waveform_phase) % wave_frames.size()
			_waveform_label.text = wave_frames[frame_idx]
			_waveform_label.add_theme_color_override("font_color", CYAN)
		else:
			_waveform_label.text = "  ▂▃▂   "
			_waveform_label.add_theme_color_override("font_color", MUTED)

	# 4. Update speaker subtle breathing & glowing frame animation
	_update_portrait_animations(delta)

	# 5. Redraw ambient spores / VFX overlay
	if is_instance_valid(_fx_overlay):
		var vp_size := get_viewport().get_visible_rect().size
		for sp in _spores:
			sp["pos"] += sp["vel"] * delta
			if sp["pos"].y < -20.0:
				sp["pos"].y = vp_size.y + 10.0
				sp["pos"].x = _rng.randf_range(0.0, vp_size.x)
			if sp["pos"].x < -20.0:
				sp["pos"].x = vp_size.x + 10.0
			elif sp["pos"].x > vp_size.x + 20.0:
				sp["pos"].x = -10.0
		_fx_overlay.queue_redraw()


func start_dialogue(lines: Array[String], offer_enabled: bool = false, context: Dictionary = {}) -> void:
	if not is_node_ready():
		_ready()
	if lines.is_empty():
		return
	_lines = lines.duplicate()
	_line_index = 0
	_offer_enabled = offer_enabled
	conversation_id = str(context.get("id", ""))

	var speaker_text := str(context.get("speaker", "AMARA OKOYE / MED / HYDROPONICS"))
	_speaker_label.text = speaker_text
	_determine_speaker_kind(speaker_text)

	_choices = context.get("choices", []).duplicate(true)
	_build_choice_and_offer_buttons()

	_is_active = true
	_root.show()

	# Start cutscene camera close-up & letterbox transition
	_start_cutscene_camera(context)
	_animate_cutscene_open()
	_play_sfx(_snd_open, -2.0)

	_show_current_line()


func _input(event: InputEvent) -> void:
	if not _is_active or (event is InputEventKey and event.echo):
		return
	var advance := event.is_action_pressed(&"interact")
	var decline: bool = false
	if event is InputEventKey:
		decline = event.pressed and event.keycode == KEY_Q
		if event.pressed and event.keycode == KEY_ESCAPE:
			cancel_dialogue()
			get_viewport().set_input_as_handled()
			return
		advance = advance or (event.pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
		if event.pressed and not _is_typing and _line_index == _lines.size() - 1 and not _choices.is_empty():
			var index := int(event.keycode) - int(KEY_1)
			if index >= 0 and index < _choices.size():
				_choose(str(_choices[index].id))
				get_viewport().set_input_as_handled()
				return
	elif event is InputEventScreenTouch and event.pressed:
		if _is_typing or (_line_index < _lines.size() - 1) or (_choices.is_empty() and not _offer_enabled):
			advance = true

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
			_play_sfx(_snd_advance, -4.0)
			_show_current_line()
	elif not _choices.is_empty():
		if advance:
			_choose(str(_choices[0].id))
		elif decline:
			_choose(str(_choices[-1].id))
	elif _offer_enabled:
		if advance:
			_finish(true)
		elif decline:
			_finish(false)
	elif advance:
		_finish(false)
	get_viewport().set_input_as_handled()


func _show_current_line() -> void:
	_dialogue_label.text = _lines[_line_index]
	_visible_characters = 0
	_typewriter_progress = 0.0
	_last_char_sound_pos = -1
	_is_typing = not _dialogue_label.text.is_empty()
	_dialogue_label.visible_characters = 0 if _is_typing else -1
	_update_speaker_visuals()
	_refresh_prompt()


func _reveal_current_line() -> void:
	_is_typing = false
	_visible_characters = _dialogue_label.text.length()
	_dialogue_label.visible_characters = -1
	_update_speaker_visuals()
	_refresh_prompt()


func _refresh_prompt() -> void:
	var choices_ready := not _is_typing and _line_index == _lines.size() - 1 and not _choices.is_empty()
	var offer_ready := not _is_typing and _line_index == _lines.size() - 1 and _offer_enabled

	_choice_row.visible = choices_ready or offer_ready

	if _is_typing:
		_prompt_label.text = "[E / TAP]  SHOW FULL LINE  ▶"
	elif _line_index < _lines.size() - 1:
		_prompt_label.text = "[E / SPACE / TAP]  CONTINUE  ▼"
	elif choices_ready:
		_prompt_label.text = "[1-%d] CHOOSE OPTION  /  [E] FIRST  /  [ESC] CLOSE" % _choices.size()
	elif offer_ready:
		_prompt_label.text = "[E]  TAKE TASKS     [Q]  MAYBE LATER"
	else:
		_prompt_label.text = "[E / SPACE / TAP]  CLOSE DIALOGUE  ▼"


func _finish(accepted_tasks: bool) -> void:
	if not conversation_id.is_empty():
		_choose(str(_choices[0].id) if accepted_tasks and not _choices.is_empty() else "closed")
		return
	_is_active = false
	_is_typing = false
	_play_sfx(_snd_close, -3.0)
	_finish_cutscene_camera()
	_root.hide()
	dialogue_finished.emit(accepted_tasks)


func _choose(result_id: String) -> void:
	if not _is_active:
		return
	_is_active = false
	_is_typing = false
	_play_sfx(_snd_click, -1.0)
	_finish_cutscene_camera()
	_root.hide()
	conversation_finished.emit(conversation_id, result_id)


func cancel_dialogue() -> void:
	if not _is_active:
		return
	if conversation_id.is_empty():
		_finish(false)
	else:
		_choose("cancelled")


# ------------------------------------------------------------------------------
# CAMERA CUTSCENE SYSTEM
# ------------------------------------------------------------------------------

func _start_cutscene_camera(context: Dictionary) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	# Locate ShipPlayer and active Camera2D
	var players := tree.get_nodes_in_group("ship_player")
	var player: Node2D = players[0] if not players.is_empty() else null
	if player == null and is_instance_valid(get_parent()):
		player = get_parent().get_node_or_null("Player") as Node2D

	if not is_instance_valid(player):
		return

	_camera = player.get_node_or_null("Camera2D") as Camera2D
	if not is_instance_valid(_camera):
		return

	if not _in_cutscene:
		_original_camera_pos = _camera.position
		_original_camera_zoom = _camera.zoom
		_in_cutscene = true

	# Find target NPC: from context or tree
	_target_npc = context.get("npc", null) as Node2D
	if _target_npc == null:
		var npcs := get_tree().get_nodes_in_group("ship_crew")
		if not npcs.is_empty():
			_target_npc = npcs[0] as Node2D
		else:
			_target_npc = get_parent().get_node_or_null("AmaraOkoye") as Node2D

	var target_pos := Vector2.ZERO
	var target_zoom := Vector2(2.65, 2.65)

	if is_instance_valid(_target_npc):
		# Turn characters to face each other
		if player.has_method("face_toward"):
			player.face_toward(_target_npc.global_position)
		if _target_npc.has_method("set_in_dialogue"):
			_target_npc.set_in_dialogue(true)

		# Center camera on midpoint between player and NPC (in player local coordinates)
		var mid_offset: Vector2 = (_target_npc.global_position - player.global_position) * 0.5
		if mid_offset.length() > 140.0:
			mid_offset = mid_offset.normalized() * 140.0
		target_pos = mid_offset
	else:
		# Comms / Radio broadcast: center zoom on Player receiving the message
		target_zoom = Vector2(2.15, 2.15)
		target_pos = Vector2.ZERO

	if is_instance_valid(_camera_tween):
		_camera_tween.kill()

	_camera_tween = create_tween().set_parallel(true)
	_camera_tween.tween_property(_camera, "position", target_pos, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(_camera, "zoom", target_zoom, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _finish_cutscene_camera() -> void:
	if not _in_cutscene:
		return

	if is_instance_valid(_target_npc) and _target_npc.has_method("set_in_dialogue"):
		_target_npc.set_in_dialogue(false)
	_target_npc = null

	if is_instance_valid(_camera):
		if is_instance_valid(_camera_tween):
			_camera_tween.kill()
		_camera_tween = create_tween().set_parallel(true)
		_camera_tween.tween_property(_camera, "position", _original_camera_pos, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_camera_tween.tween_property(_camera, "zoom", _original_camera_zoom, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	_in_cutscene = false


# ------------------------------------------------------------------------------
# UI CREATION & VISUAL PRESENTATION
# ------------------------------------------------------------------------------

func _build_ui() -> void:
	_root = Control.new()
	SKIN.apply(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# 1. Atmospheric VFX overlay (drifting bioluminescent spores & dark edge vignette)
	_fx_overlay = Control.new()
	_fx_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_overlay.draw.connect(_on_fx_overlay_draw.bind(_fx_overlay))
	_root.add_child(_fx_overlay)

	# 2. Cinematic Letterbox Bars
	_build_letterbox_bars()

	# 3. Main Dialogue Console & Character Close-Up Portraits Container
	_build_dialogue_and_portraits()


func _build_letterbox_bars() -> void:
	# Top Cinematic Bar
	_top_bar = PanelContainer.new()
	_top_bar.name = "TopLetterbox"
	_top_bar.anchor_left = 0.0
	_top_bar.anchor_right = 1.0
	_top_bar.anchor_top = 0.0
	_top_bar.anchor_bottom = 0.0
	_top_bar.offset_top = 0.0
	_top_bar.offset_bottom = 44.0
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.012, 0.022, 0.035, 0.96)
	top_style.border_width_bottom = 1
	top_style.border_color = Color(0.24, 0.55, 0.72, 0.45)
	top_style.set_content_margin_all(8.0)
	_top_bar.add_theme_stylebox_override("panel", top_style)
	_root.add_child(_top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	_top_bar.add_child(top_hbox)

	_rec_label = Label.new()
	_rec_label.text = "● REC // COMMS CH-01 // BIO-SPEC"
	_rec_label.add_theme_font_size_override("font_size", 9)
	_rec_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	top_hbox.add_child(_rec_label)

	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(top_spacer)

	_cam_telemetry = Label.new()
	_cam_telemetry.text = "AST-1 AUDIO-VISUAL // CAM 02-B BIO-SPEC"
	_cam_telemetry.add_theme_font_size_override("font_size", 9)
	_cam_telemetry.add_theme_color_override("font_color", MUTED)
	top_hbox.add_child(_cam_telemetry)

	# Bottom Cinematic Bar
	_bottom_bar = PanelContainer.new()
	_bottom_bar.name = "BottomLetterbox"
	_bottom_bar.anchor_left = 0.0
	_bottom_bar.anchor_right = 1.0
	_bottom_bar.anchor_top = 1.0
	_bottom_bar.anchor_bottom = 1.0
	_bottom_bar.offset_top = -44.0
	_bottom_bar.offset_bottom = 0.0
	_bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bot_style := StyleBoxFlat.new()
	bot_style.bg_color = Color(0.012, 0.022, 0.035, 0.96)
	bot_style.border_width_top = 1
	bot_style.border_color = Color(0.24, 0.55, 0.72, 0.45)
	_bottom_bar.add_theme_stylebox_override("panel", bot_style)
	_root.add_child(_bottom_bar)


func _build_dialogue_and_portraits() -> void:
	_portraits_container = HBoxContainer.new()
	_portraits_container.name = "CutsceneLayout"
	_portraits_container.anchor_left = 0.03
	_portraits_container.anchor_right = 0.97
	_portraits_container.anchor_top = 1.0
	_portraits_container.anchor_bottom = 1.0
	_portraits_container.offset_left = 0.0
	_portraits_container.offset_top = -315.0
	_portraits_container.offset_right = 0.0
	_portraits_container.offset_bottom = -48.0
	_portraits_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_portraits_container.add_theme_constant_override("separation", 12)
	_portraits_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_portraits_container)

	# 1. Player Close-Up Portrait (Left)
	_player_portrait_panel = _create_portrait_box("THURA", "AST-1 ENGINEER", true)
	_portraits_container.add_child(_player_portrait_panel)

	# 2. Central Dialogue Console
	_bubble = PanelContainer.new()
	_bubble.name = "AmaraSpeechBubble"
	_bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bubble.size_flags_vertical = Control.SIZE_FILL
	_bubble.clip_contents = true
	_bubble.add_theme_stylebox_override("panel", _bubble_style())
	_portraits_container.add_child(_bubble)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	_bubble.add_child(content)

	# Header with Speaker Name and Animated Audio Waveform
	var header_hbox := HBoxContainer.new()
	header_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(header_hbox)

	_speaker_label = Label.new()
	_speaker_label.text = "DR. AMARA OKOYE   /   ASTROBIOLOGIST / HYDROPONICS"
	_speaker_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speaker_label.clip_text = true
	_speaker_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_speaker_label.add_theme_font_override("font", SKIN.get_pixel_font())
	_speaker_label.add_theme_font_size_override("font_size", 11)
	_speaker_label.add_theme_color_override("font_color", GOLD)
	header_hbox.add_child(_speaker_label)

	_waveform_label = Label.new()
	_waveform_label.text = "  ▂▃▂   "
	_waveform_label.add_theme_font_size_override("font_size", 10)
	_waveform_label.add_theme_color_override("font_color", CYAN)
	header_hbox.add_child(_waveform_label)

	# Dialogue Text Body
	_dialogue_label = Label.new()
	_dialogue_label.custom_minimum_size = Vector2(0.0, 68.0)
	_dialogue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_font_override("font", SKIN.get_pixel_font())
	_dialogue_label.add_theme_font_size_override("font_size", 13)
	_dialogue_label.add_theme_constant_override("line_spacing", 5)
	_dialogue_label.add_theme_color_override("font_color", PALE)
	content.add_child(_dialogue_label)

	# Interactive Dialogue Choices Container (Grid layout so replies never overflow horizontally)
	_choice_row = HBoxContainer.new()
	_choice_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choice_row.add_theme_constant_override("separation", 8)
	content.add_child(_choice_row)

	# Prompt Footer
	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prompt_label.clip_text = true
	_prompt_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_prompt_label.add_theme_font_override("font", SKIN.get_pixel_font())
	_prompt_label.add_theme_font_size_override("font_size", 10)
	_prompt_label.add_theme_color_override("font_color", MUTED)
	content.add_child(_prompt_label)

	# 3. NPC Close-Up Portrait (Right)
	_npc_portrait_panel = _create_portrait_box("DR. AMARA OKOYE", "ASTROBIOLOGIST", false)
	_portraits_container.add_child(_npc_portrait_panel)


func _create_portrait_box(char_name: String, role: String, is_player: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(124.0, 184.0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_END
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _portrait_panel_style(false))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	# Status indicator tag
	var status := Label.new()
	status.text = "● MONITORING" if is_player else "▶ AUDIO ACTIVE"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 8)
	status.add_theme_color_override("font_color", CYAN if not is_player else MUTED)
	vbox.add_child(status)

	# Close-up Bust Texture
	var frame_panel := PanelContainer.new()
	frame_panel.custom_minimum_size = Vector2(104.0, 108.0)
	frame_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_panel.add_theme_stylebox_override("panel", _portrait_frame_inner_style())
	vbox.add_child(frame_panel)

	var tex_rect := TextureRect.new()
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame_panel.add_child(tex_rect)

	# Name Label
	var name_lbl := Label.new()
	name_lbl.text = char_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", GOLD if is_player else CYAN)
	vbox.add_child(name_lbl)

	# Role Subtitle
	var role_lbl := Label.new()
	role_lbl.text = role
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_lbl.add_theme_font_size_override("font_size", 7)
	role_lbl.add_theme_color_override("font_color", MUTED)
	vbox.add_child(role_lbl)

	if is_player:
		_player_portrait_rect = tex_rect
		_player_name_label = name_lbl
		_player_status_badge = status

		var thura_atlas := AtlasTexture.new()
		thura_atlas.atlas = THURA_ATLAS_TEX
		thura_atlas.region = Rect2(72.0, 38.0, 175.0, 175.0)
		_player_portrait_rect.texture = thura_atlas
	else:
		_npc_portrait_rect = tex_rect
		_npc_name_label = name_lbl
		_npc_role_label = role_lbl
		_npc_status_badge = status

		var amara_atlas := AtlasTexture.new()
		amara_atlas.atlas = AMARA_ATLAS_TEX
		amara_atlas.region = Rect2(72.0, 36.0, 175.0, 175.0)
		_npc_portrait_rect.texture = amara_atlas

	return panel


func _build_choice_and_offer_buttons() -> void:
	for child in _choice_row.get_children():
		_choice_row.remove_child(child)
		child.queue_free()
	_choice_buttons.clear()
	_offer_buttons.clear()

	if not _choices.is_empty():
		var grid := GridContainer.new()
		grid.columns = 2 if _choices.size() >= 2 else 1
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 6)
		_choice_row.add_child(grid)

		for i in range(_choices.size()):
			var choice: Dictionary = _choices[i]
			var button := Button.new()
			var shortcut_num := str(i + 1)
			button.text = "[%s] %s" % [shortcut_num, str(choice.label)]
			button.custom_minimum_size = Vector2(0.0, 36.0)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.clip_text = false
			button.add_theme_font_override("font", SKIN.get_pixel_font())
			button.add_theme_font_size_override("font_size", 11)
			button.add_theme_stylebox_override("normal", _choice_btn_style(false))
			button.add_theme_stylebox_override("hover", _choice_btn_style(true))
			button.add_theme_stylebox_override("pressed", _choice_btn_style(true, true))
			button.add_theme_stylebox_override("focus", _choice_btn_style(true))
			button.mouse_entered.connect(_on_choice_btn_hover.bind(button))
			button.pressed.connect(_choose.bind(str(choice.id)))
			grid.add_child(button)
			_choice_buttons.append(button)
	elif _offer_enabled:
		# Interactive styled buttons for task offer
		var accept_btn := Button.new()
		accept_btn.text = "▶  [E] TAKE TASKS"
		accept_btn.custom_minimum_size = Vector2(0.0, 36.0)
		accept_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		accept_btn.add_theme_font_override("font", SKIN.get_pixel_font())
		accept_btn.add_theme_font_size_override("font_size", 11)
		accept_btn.add_theme_stylebox_override("normal", _choice_btn_style(false, false, true))
		accept_btn.add_theme_stylebox_override("hover", _choice_btn_style(true, false, true))
		accept_btn.add_theme_stylebox_override("pressed", _choice_btn_style(true, true, true))
		accept_btn.mouse_entered.connect(_on_choice_btn_hover.bind(accept_btn))
		accept_btn.pressed.connect(_finish.bind(true))
		_choice_row.add_child(accept_btn)
		_offer_buttons.append(accept_btn)

		var decline_btn := Button.new()
		decline_btn.text = "✕  [Q] MAYBE LATER"
		decline_btn.custom_minimum_size = Vector2(0.0, 36.0)
		decline_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		decline_btn.add_theme_font_override("font", SKIN.get_pixel_font())
		decline_btn.add_theme_font_size_override("font_size", 11)
		decline_btn.add_theme_stylebox_override("normal", _choice_btn_style(false))
		decline_btn.add_theme_stylebox_override("hover", _choice_btn_style(true))
		decline_btn.add_theme_stylebox_override("pressed", _choice_btn_style(true, true))
		decline_btn.mouse_entered.connect(_on_choice_btn_hover.bind(decline_btn))
		decline_btn.pressed.connect(_finish.bind(false))
		_choice_row.add_child(decline_btn)
		_offer_buttons.append(decline_btn)
	_resize_bubble()


func _on_choice_btn_hover(_btn: Button) -> void:
	_play_sfx(_snd_hover, -6.0)


func _determine_speaker_kind(speaker_text: String) -> void:
	var upper := speaker_text.to_upper()
	if upper.contains("AMARA") or upper.contains("OKOYE"):
		_current_speaker_kind = "amara"
		_npc_name_label.text = "DR. AMARA OKOYE"
		_npc_name_label.add_theme_color_override("font_color", CYAN)
		if is_instance_valid(_npc_role_label):
			_npc_role_label.text = "ASTROBIOLOGIST / HYDROPONICS"
		var amara_atlas := AtlasTexture.new()
		amara_atlas.atlas = AMARA_ATLAS_TEX
		amara_atlas.region = Rect2(72.0, 36.0, 175.0, 175.0)
		_npc_portrait_rect.texture = amara_atlas
	elif upper.contains("MAYA") or upper.contains("CHEN") or upper.contains("COMMANDER"):
		_current_speaker_kind = "chen"
		_npc_name_label.text = "MAYA CHEN / CDR"
		_npc_name_label.add_theme_color_override("font_color", GOLD)
		if is_instance_valid(_npc_role_label):
			_npc_role_label.text = "EXPEDITION COMMANDER"
		_npc_portrait_rect.texture = _create_hologram_tex(GOLD)
	elif upper.contains("ELIAS") or upper.contains("WARD"):
		_current_speaker_kind = "ward"
		_npc_name_label.text = "ELIAS WARD / PILOT"
		_npc_name_label.add_theme_color_override("font_color", Color(0.68, 0.88, 1.0))
		if is_instance_valid(_npc_role_label):
			_npc_role_label.text = "PILOT & MEDICAL SUPPORT"
		_npc_portrait_rect.texture = _create_hologram_tex(Color(0.68, 0.88, 1.0))
	elif upper.contains("LEILA") or upper.contains("HADDAD") or upper.contains("CHIEF ENGINEER"):
		_current_speaker_kind = "leila"
		_npc_name_label.text = "LEILA HADDAD / ENG"
		_npc_name_label.add_theme_color_override("font_color", EMERALD)
		if is_instance_valid(_npc_role_label):
			_npc_role_label.text = "CHIEF ENGINEER"
		_npc_portrait_rect.texture = _create_hologram_tex(EMERALD)
	elif upper.contains("MATEO") or upper.contains("RUIZ") or upper.contains("MINING"):
		_current_speaker_kind = "mateo"
		_npc_name_label.text = "MATEO RUIZ / MINING"
		_npc_name_label.add_theme_color_override("font_color", ORANGE)
		if is_instance_valid(_npc_role_label):
			_npc_role_label.text = "MINING SPECIALIST"
		_npc_portrait_rect.texture = _create_hologram_tex(ORANGE)
	else:
		_current_speaker_kind = "terminal"
		_npc_name_label.text = "ASTERIA COMMS"
		_npc_name_label.add_theme_color_override("font_color", MUTED)
		if is_instance_valid(_npc_role_label):
			_npc_role_label.text = "COMMUNICATIONS RELAY"
		_npc_portrait_rect.texture = _create_hologram_tex(MUTED)


func _create_hologram_tex(tint: Color) -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.02, 0.05, 0.08, 0.95))
	for y in range(64):
		var scanline := (y % 4 == 0)
		for x in range(64):
			var dist := Vector2(x - 32, y - 32).length()
			if dist < 24.0 and dist > 21.0:
				img.set_pixel(x, y, tint * 0.9)
			elif dist < 12.0 and dist > 9.0:
				img.set_pixel(x, y, tint * 0.7)
			elif scanline and dist < 28.0:
				img.set_pixel(x, y, Color(tint.r, tint.g, tint.b, 0.35))
	return ImageTexture.create_from_image(img)


func _update_speaker_visuals() -> void:
	var choices_active := not _is_typing and _line_index == _lines.size() - 1 and not _choices.is_empty()
	var offer_active := not _is_typing and _line_index == _lines.size() - 1 and _offer_enabled

	if choices_active or offer_active:
		# Player is selecting / transmitting
		_player_status_badge.text = "▶ TRANSMITTING"
		_player_status_badge.add_theme_color_override("font_color", GOLD)
		_player_portrait_panel.add_theme_stylebox_override("panel", _portrait_panel_style(true, GOLD))

		_npc_status_badge.text = "● STANDBY"
		_npc_status_badge.add_theme_color_override("font_color", MUTED)
		_npc_portrait_panel.add_theme_stylebox_override("panel", _portrait_panel_style(false))
	else:
		# NPC is speaking / audio active
		_player_status_badge.text = "● MONITORING"
		_player_status_badge.add_theme_color_override("font_color", MUTED)
		_player_portrait_panel.add_theme_stylebox_override("panel", _portrait_panel_style(false))

		_npc_status_badge.text = "▶ AUDIO ACTIVE"
		_npc_status_badge.add_theme_color_override("font_color", CYAN)
		_npc_portrait_panel.add_theme_stylebox_override("panel", _portrait_panel_style(true, CYAN))


func _update_portrait_animations(_delta: float) -> void:
	if not is_instance_valid(_npc_portrait_rect):
		return
	if _is_typing:
		var pulse := 1.0 + 0.02 * sin(_anim_timer * 8.0)
		_npc_portrait_rect.scale = Vector2(pulse, pulse)
		_npc_portrait_rect.pivot_offset = _npc_portrait_rect.size * 0.5
	else:
		_npc_portrait_rect.scale = Vector2.ONE


func _animate_cutscene_open() -> void:
	_resize_bubble()
	# Subtle entrance tween for dialogue bubble and letterboxes
	if is_instance_valid(_top_bar) and is_instance_valid(_bottom_bar):
		var vp := get_viewport()
		var vp_h: float = vp.get_visible_rect().size.y if is_instance_valid(vp) else 720.0
		_top_bar.position.y = -50.0
		_bottom_bar.position.y = vp_h + 10.0
		if not is_inside_tree():
			return
		var tween := create_tween().set_parallel(true)
		tween.tween_property(_top_bar, "position:y", 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(_bottom_bar, "position:y", vp_h - 44.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _play_sfx(stream: AudioStream, vol_db: float = 0.0) -> void:
	if stream == null or not is_instance_valid(_sfx_player) or not is_inside_tree():
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = vol_db
	_sfx_player.play()


func _play_voice_blip() -> void:
	if not is_instance_valid(_voice_player) or not is_inside_tree():
		return
	var stream: AudioStreamWAV = _snd_speech_amara
	match _current_speaker_kind:
		"amara":
			stream = _snd_speech_amara
			_voice_player.pitch_scale = _rng.randf_range(0.96, 1.05)
		"thura":
			stream = _snd_speech_thura
			_voice_player.pitch_scale = _rng.randf_range(0.98, 1.04)
		"chen":
			stream = _snd_speech_chen
			_voice_player.pitch_scale = _rng.randf_range(0.96, 1.04)
		"mateo":
			stream = _snd_speech_mateo
			_voice_player.pitch_scale = _rng.randf_range(0.94, 1.06)
		"ward":
			stream = _snd_speech_ward
			_voice_player.pitch_scale = _rng.randf_range(0.95, 1.05)
		"leila":
			stream = _snd_speech_leila
			_voice_player.pitch_scale = _rng.randf_range(0.96, 1.04)
		_:
			stream = _snd_speech_terminal
			_voice_player.pitch_scale = _rng.randf_range(0.94, 1.06)
	_voice_player.stream = stream
	_voice_player.play()


func _resize_bubble() -> void:
	if not is_instance_valid(_portraits_container):
		return
	var vp := get_viewport()
	var vp_rect := vp.get_visible_rect() if is_instance_valid(vp) else Rect2(0.0, 0.0, 1280.0, 720.0)
	var vp_w: float = maxf(vp_rect.size.x, 640.0)
	var vp_h: float = maxf(vp_rect.size.y, 480.0)
	var margin_x := clampf((vp_w - minf(vp_w - 36.0, 1140.0)) * 0.5, 18.0, 180.0)
	_portraits_container.anchor_left = 0.0
	_portraits_container.anchor_right = 1.0
	_portraits_container.anchor_top = 1.0
	_portraits_container.anchor_bottom = 1.0
	_portraits_container.offset_left = margin_x
	_portraits_container.offset_right = -margin_x
	var has_multi_row_choices := _choices.size() > 2
	var box_height := clampf(295.0 if has_multi_row_choices else 245.0, 210.0, vp_h - 96.0)
	_portraits_container.offset_top = -(48.0 + box_height)
	_portraits_container.offset_bottom = -48.0
	if is_instance_valid(_player_portrait_panel) and is_instance_valid(_npc_portrait_panel):
		var show_portraits := vp_w >= 760.0
		_player_portrait_panel.visible = show_portraits
		_npc_portrait_panel.visible = show_portraits


func _exit_tree() -> void:
	cancel_dialogue()


# ------------------------------------------------------------------------------
# STYLES & SHADERS
# ------------------------------------------------------------------------------

func _bubble_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = DARK_BG
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = BORDER_CYAN
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	style.shadow_size = 12
	style.set_content_margin_all(16.0)
	return style


func _portrait_panel_style(is_focused: bool, border_tint := CYAN) -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.026, 0.04, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_tint if is_focused else Color(0.18, 0.35, 0.45, 0.7)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.set_content_margin_all(8.0)
	if is_focused:
		style.shadow_color = Color(border_tint.r, border_tint.g, border_tint.b, 0.35)
		style.shadow_size = 8
	return style


func _portrait_frame_inner_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.008, 0.016, 0.026, 0.98)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.15, 0.4, 0.55, 0.6)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	style.set_content_margin_all(4.0)
	return style


func _choice_btn_style(hover: bool, pressed: bool = false, is_accent: bool = false) -> StyleBox:
	var style := StyleBoxFlat.new()
	if pressed:
		style.bg_color = Color(0.18, 0.42, 0.6, 0.95)
		style.border_color = GOLD if is_accent else Color(0.7, 0.95, 1.0)
	elif hover:
		style.bg_color = Color(0.08, 0.22, 0.32, 0.92)
		style.border_color = GOLD if is_accent else CYAN
		style.shadow_color = Color(0.2, 0.7, 0.9, 0.3) if not is_accent else Color(0.9, 0.7, 0.2, 0.35)
		style.shadow_size = 6
	else:
		style.bg_color = Color(0.025, 0.05, 0.08, 0.88)
		style.border_color = Color(0.7, 0.55, 0.25, 0.85) if is_accent else Color(0.25, 0.45, 0.58, 0.75)

	style.border_width_left = 2 if hover else 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.set_content_margin_all(8.0)
	return style


func _on_fx_overlay_draw(overlay: Control = null) -> void:
	if overlay == null:
		overlay = _fx_overlay
	if not is_instance_valid(overlay) or not overlay.is_inside_tree():
		return
	var vp_size := get_viewport().get_visible_rect().size

	# 1. Subtle cinematic dark vignette at corners
	var vig_col := Color(0.0, 0.0, 0.0, 0.28)
	overlay.draw_rect(Rect2(0, 0, vp_size.x, 24), vig_col)
	overlay.draw_rect(Rect2(0, vp_size.y - 24, vp_size.x, 24), vig_col)

	# 2. Drifting bioluminescent spore motes
	for sp in _spores:
		var pos: Vector2 = sp["pos"]
		var alpha_pulse: float = float(sp["alpha"]) * (0.6 + 0.4 * sin(_anim_timer * float(sp["pulse_speed"]) + float(sp["phase"])))
		var col: Color = sp["color"]
		col.a = clampf(alpha_pulse, 0.05, 0.85)
		overlay.draw_circle(pos, float(sp["size"]), col)
