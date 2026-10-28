extends Control

const SKIN := preload("res://scripts/ui/pixel_ui.gd")
const STORY := preload("res://scripts/ship/first_watch_story.gd")
const STORY_SAVE := preload("res://scripts/ship/ship_story_save.gd")
signal cue_finished(request_token: String, cue_id: String, outcome: String, landing_id: String)
var _cue_context := {}
var _bootstrap_story
var _campaign_payload := {}
var _campaign_path := ""

const GAMEPLAY_SCENE := "res://scenes/ship/bare_ship_walkthrough.tscn"
const TYPEWRITER_CHARACTERS_PER_SECOND := 38.0
const POST_SUBTITLE_HOLD_SECONDS := 2.6
const TRANSITION_SECONDS := 0.62

const STORY_FRAMES := [
	{
		"image": "res://art/storyboards/thura_earth/01_yangon_rooftop.png",
		"chapter": "YANGON  /  CHILDHOOD",
		"subtitle": "When Yangon lost power, Thura and his mother found the constellations together."
	},
	{
		"image": "res://art/storyboards/thura_earth/02_radio_with_father.png",
		"chapter": "YANGON  /  HOME",
		"subtitle": "From his father, he learned to hear what a machine needed."
	},
	{
		"image": "res://art/storyboards/thura_earth/sequences/scholarship/01_open_envelope.png",
		"chapter": "THE SCHOLARSHIP  /  THE ENVELOPE",
		"subtitle": "Then an envelope arrived from a university far from home."
	},
	{
		"image": "res://art/storyboards/thura_earth/03_scholarship_letter.png",
		"chapter": "THE SCHOLARSHIP  /  THE LETTER",
		"subtitle": "An international scholarship opened the way to planetary geology and robotics."
	},
	{
		"image": "res://art/storyboards/thura_earth/sequences/scholarship/03_family_reaction.png",
		"chapter": "THE SCHOLARSHIP  /  THE FAMILY",
		"subtitle": "For a moment, the distance ahead felt possible."
	},
	{
		"image": "res://art/storyboards/thura_earth/04_failed_assessment.png",
		"chapter": "ASTRONAUT CANDIDATE  /  THE SETBACK",
		"subtitle": "His first astronaut assessment ended in failure."
	},
	{
		"image": "res://art/storyboards/thura_earth/05_tries_again.png",
		"chapter": "ASTRONAUT CANDIDATE  /  AGAIN",
		"subtitle": "Thura returned, prepared, and tried again."
	},
	{
		"image": "res://art/storyboards/thura_earth/sequences/neutral_buoyancy/01_poolside_preparation.png",
		"chapter": "NEUTRAL-BUOYANCY TRAINING  /  PREPARATION",
		"subtitle": "He trained for the weightlessness of space."
	},
	{
		"image": "res://art/storyboards/thura_earth/06_neutral_buoyancy_training.png",
		"chapter": "NEUTRAL-BUOYANCY TRAINING  /  THE REPAIR",
		"subtitle": "Underwater, every repair took patience, practice, and trust."
	},
	{
		"image": "res://art/storyboards/thura_earth/sequences/neutral_buoyancy/03_repair_complete.png",
		"chapter": "NEUTRAL-BUOYANCY TRAINING  /  COMPLETED",
		"subtitle": "The work became instinct: precise, quiet, deliberate."
	},
	{
		"image": "res://art/storyboards/thura_earth/07_astronaut_selected.png",
		"chapter": "ASTERIA-1  /  MISSION SELECTION",
		"subtitle": "At 34, Thura became the first Myanmar-born astronaut selected for this mission."
	},
	{
		"image": "res://art/storyboards/thura_earth/sequences/may_farewell/01_before_handoff.png",
		"chapter": "MAY  /  BEFORE DEPARTURE",
		"subtitle": "Before departure, May brought him a small piece of home."
	},
	{
		"image": "res://art/storyboards/thura_earth/08_may_gives_paper_star.png",
		"chapter": "MAY  /  THE PAPER STAR",
		"subtitle": "She folded it from one of their mother's old lesson books."
	},
	{
		"image": "res://art/storyboards/thura_earth/sequences/may_farewell/03_after_handoff.png",
		"chapter": "ASTERIA-1  /  DEPARTURE",
		"subtitle": "Thura carried it toward a sky he had watched since childhood."
	}
]

var _frame_image: TextureRect
var _fade_overlay: ColorRect
var _chapter_label: Label
var _counter_label: Label
var _subtitle_label: Label
var _progress_fill: ColorRect
var _next_button: Button
var _skip_button: Button
var _zoom_tween: Tween
var _frame_index := 0
var _remaining_seconds := 0.0
var _typed_character_progress := 0.0
var _subtitle_character_count := 0
var _is_subtitle_typing := false
var _transitioning := false
var _finished := false


func _ready() -> void:
	_bootstrap_story = STORY.new()
	if Engine.has_meta("ship_story_bootstrap"): _bootstrap_story.restore(Engine.get_meta("ship_story_bootstrap"))
	# A cold resume is a new attempt. Earlier pending tokens cannot finish it.
	_cue_context = _bootstrap_story.request_cue("cue.thura.earth_years", "existing_montage")
	if Engine.has_meta("ship_story_intro_payload"):
		_campaign_payload=Engine.get_meta("ship_story_intro_payload");Engine.remove_meta("ship_story_intro_payload")
		_campaign_path=str(Engine.get_meta("ship_story_intro_path",""));Engine.remove_meta("ship_story_intro_path")
		_persist_intro()
	SKIN.apply(self)
	_build_ui()
	_show_frame(0)
	_transitioning = true
	_fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	await _fade_to_alpha(0.0, 0.9)
	_transitioning = false


func _process(delta: float) -> void:
	if _transitioning:
		return
	if _is_subtitle_typing:
		_typed_character_progress = minf(
			_typed_character_progress + TYPEWRITER_CHARACTERS_PER_SECOND * delta,
			float(_subtitle_character_count)
		)
		_subtitle_label.visible_characters = int(_typed_character_progress)
		if _subtitle_label.visible_characters >= _subtitle_character_count:
			_finish_subtitle()
		_update_progress()
		return
	if _finished:
		return
	_remaining_seconds -= delta
	_update_progress()
	if _remaining_seconds <= 0.0:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_advance()
			get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_frame_image = TextureRect.new()
	_frame_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frame_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_frame_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame_image)

	var image_tint := ColorRect.new()
	image_tint.color = Color(0.0, 0.008, 0.018, 0.16)
	image_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image_tint)

	var top_bar := Panel.new()
	top_bar.add_theme_stylebox_override("panel", SKIN.panel())
	top_bar.anchor_left = 0.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_bottom = 0.13
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)

	var top_label := Label.new()
	top_label.text = "ASTERIA-1 // CREW ARCHIVE DOSSIER: THURA MIN"
	top_label.anchor_left = 0.045
	top_label.anchor_top = 0.035
	top_label.anchor_right = 0.72
	top_label.anchor_bottom = 0.095
	top_label.add_theme_font_override("font", SKIN.get_pixel_font())
	top_label.add_theme_font_size_override("font_size", 12)
	top_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.7, 0.92))
	top_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_label)

	_skip_button = Button.new()
	_skip_button.text = "[ SKIP DOSSIER  → ]"
	_skip_button.anchor_left = 0.78
	_skip_button.anchor_top = 0.025
	_skip_button.anchor_right = 0.96
	_skip_button.anchor_bottom = 0.105
	_skip_button.add_theme_font_override("font", SKIN.get_pixel_font())
	_skip_button.add_theme_font_size_override("font_size", 12)
	_skip_button.pressed.connect(_enter_game)
	add_child(_skip_button)

	var subtitle_panel := Panel.new()
	subtitle_panel.anchor_left = 0.0
	subtitle_panel.anchor_top = 0.76
	subtitle_panel.anchor_right = 1.0
	subtitle_panel.anchor_bottom = 1.0
	subtitle_panel.add_theme_stylebox_override("panel", SKIN.panel())
	subtitle_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle_panel)

	var progress_track := ColorRect.new()
	progress_track.anchor_left = 0.0
	progress_track.anchor_top = 0.76
	progress_track.anchor_right = 1.0
	progress_track.anchor_bottom = 0.76
	progress_track.offset_bottom = 3.0
	progress_track.color = Color(0.23, 0.26, 0.28, 0.72)
	progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(progress_track)

	_progress_fill = ColorRect.new()
	_progress_fill.anchor_left = 0.0
	_progress_fill.anchor_top = 0.76
	_progress_fill.anchor_right = 0.0
	_progress_fill.anchor_bottom = 0.76
	_progress_fill.offset_bottom = 3.0
	_progress_fill.color = Color(0.24, 0.95, 0.54, 0.98)
	_progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_progress_fill)

	_chapter_label = Label.new()
	_chapter_label.anchor_left = 0.05
	_chapter_label.anchor_top = 0.785
	_chapter_label.anchor_right = 0.78
	_chapter_label.anchor_bottom = 0.84
	_chapter_label.add_theme_font_override("font", SKIN.get_pixel_font())
	_chapter_label.add_theme_font_size_override("font_size", 13)
	_chapter_label.add_theme_color_override("font_color", Color(0.86, 0.67, 0.38))
	add_child(_chapter_label)

	_counter_label = Label.new()
	_counter_label.anchor_left = 0.8
	_counter_label.anchor_top = 0.785
	_counter_label.anchor_right = 0.95
	_counter_label.anchor_bottom = 0.84
	_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_counter_label.add_theme_font_override("font", SKIN.get_pixel_font())
	_counter_label.add_theme_font_size_override("font_size", 12)
	_counter_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.79))
	add_child(_counter_label)

	_subtitle_label = Label.new()
	_subtitle_label.anchor_left = 0.05
	_subtitle_label.anchor_top = 0.835
	_subtitle_label.anchor_right = 0.74
	_subtitle_label.anchor_bottom = 0.98
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_override("font", SKIN.get_pixel_font())
	_subtitle_label.add_theme_font_size_override("font_size", 16)
	_subtitle_label.add_theme_constant_override("line_spacing", 7)
	_subtitle_label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.92))
	_subtitle_label.add_theme_constant_override("outline_size", 0)
	_subtitle_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	add_child(_subtitle_label)

	_next_button = Button.new()
	_next_button.text = "[ PROCEED  › ]"
	_next_button.anchor_left = 0.755
	_next_button.anchor_top = 0.865
	_next_button.anchor_right = 0.965
	_next_button.anchor_bottom = 0.96
	_next_button.add_theme_font_override("font", SKIN.get_pixel_font())
	_next_button.add_theme_font_size_override("font_size", 12)
	_next_button.pressed.connect(_advance)
	add_child(_next_button)

	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_overlay)


func _show_frame(index: int) -> void:
	_frame_index = index
	var frame: Dictionary = STORY_FRAMES[index]
	_frame_image.texture = load(str(frame["image"])) as Texture2D
	_frame_image.pivot_offset = get_viewport_rect().size * 0.5
	_frame_image.scale = Vector2(1.025, 1.025)
	_chapter_label.text = str(frame["chapter"])
	_counter_label.text = "%02d  /  %02d" % [index + 1, STORY_FRAMES.size()]
	_subtitle_label.text = str(frame["subtitle"])
	_next_button.text = "[ PROCEED  › ]"
	_progress_fill.anchor_right = float(index) / float(STORY_FRAMES.size())
	_begin_subtitle_typing()
	if is_instance_valid(_zoom_tween) and _zoom_tween.is_running():
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	var zoom_duration := float(_subtitle_character_count) / TYPEWRITER_CHARACTERS_PER_SECOND + POST_SUBTITLE_HOLD_SECONDS + TRANSITION_SECONDS
	_zoom_tween.tween_property(_frame_image, "scale", Vector2(1.075, 1.075), zoom_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _begin_subtitle_typing() -> void:
	_subtitle_character_count = maxi(1, _subtitle_label.get_total_character_count())
	_typed_character_progress = 0.0
	_subtitle_label.visible_characters = 0
	_is_subtitle_typing = true
	_remaining_seconds = 0.0
	_next_button.text = "[ SHOW TEXT ]"


func _finish_subtitle() -> void:
	_subtitle_label.visible_characters = _subtitle_character_count
	_is_subtitle_typing = false
	_remaining_seconds = POST_SUBTITLE_HOLD_SECONDS
	_next_button.text = "[ BOARD ASTERIA-1  → ]" if _finished else "[ PROCEED  › ]"


func _update_progress() -> void:
	if _finished:
		_progress_fill.anchor_right = 1.0
		return
	var frame_progress := 0.0
	if _is_subtitle_typing:
		frame_progress = 0.82 * float(_subtitle_label.visible_characters) / float(_subtitle_character_count)
	else:
		var hold_progress := 1.0 - clampf(_remaining_seconds / POST_SUBTITLE_HOLD_SECONDS, 0.0, 1.0)
		frame_progress = 0.82 + 0.18 * hold_progress
	_progress_fill.anchor_right = (float(_frame_index) + frame_progress) / float(STORY_FRAMES.size())


func _advance() -> void:
	if _transitioning:
		return
	if _is_subtitle_typing:
		_finish_subtitle()
		return
	if _finished:
		_enter_game()
		return

	_transitioning = true
	await _fade_to_alpha(1.0, TRANSITION_SECONDS)
	if _frame_index < STORY_FRAMES.size() - 1:
		_show_frame(_frame_index + 1)
		await _fade_to_alpha(0.0, TRANSITION_SECONDS)
		_transitioning = false
		return

	_finished = true
	_chapter_label.text = "ASTERIA-1  /  MISSION CLOCK"
	_counter_label.text = "DAY 184"
	_subtitle_label.text = "Approaching minor planet Erebos."
	_skip_button.visible = false
	_progress_fill.anchor_right = 1.0
	_begin_subtitle_typing()
	await _fade_to_alpha(0.0, TRANSITION_SECONDS)
	_transitioning = false


func _enter_game() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _fade_to_alpha(1.0, TRANSITION_SECONDS)
	var outcome := "completed" if _finished else "skipped"
	if _cue_context.get("embedded", false):
		cue_finished.emit(str(_cue_context.request_token), "cue.thura.earth_years", outcome, "ship")
		return
	var result := get_tree().change_scene_to_file(GAMEPLAY_SCENE)
	if result != OK:
		_bootstrap_story.finish_cue("cue.thura.earth_years", str(_cue_context.get("request_token","")), "failed")
		_cue_context = _bootstrap_story.request_cue("cue.thura.earth_years", "existing_montage")
		_persist_intro()
		push_error("Could not open the ship walkthrough: %s" % GAMEPLAY_SCENE)
		_transitioning = false
		await _fade_to_alpha(0.0, TRANSITION_SECONDS)
	else:
		_bootstrap_story.finish_cue("cue.thura.earth_years", str(_cue_context.get("request_token","")), outcome)
		_persist_intro()
		Engine.set_meta("ship_story_bootstrap", _bootstrap_story.snapshot())
		if not _campaign_path.is_empty(): Engine.set_meta("ship_story_continue_path",_campaign_path)

func _persist_intro() -> void:
	if _campaign_payload.is_empty() or not STORY_SAVE.allowed(_campaign_path): return
	_campaign_payload.story=_bootstrap_story.snapshot()
	if STORY_SAVE.valid_payload(_campaign_payload) and STORY_SAVE.atomic_write(_campaign_path,_campaign_payload)==OK: STORY_SAVE.remember(_campaign_path)
	else: push_warning("Intro checkpoint could not be replaced; the previous saved watch is preserved.")

func play_cue(context: Dictionary) -> void:
	_cue_context = context.duplicate(true)
	_cue_context.embedded = true


func _fade_to_alpha(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color", Color(0.0, 0.0, 0.0, alpha), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
