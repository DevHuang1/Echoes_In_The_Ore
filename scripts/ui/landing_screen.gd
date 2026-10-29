extends Control

const SKIN := preload("res://scripts/ui/pixel_ui.gd")
const STORY_SAVE := preload("res://scripts/ship/ship_story_save.gd")
const STORY := preload("res://scripts/ship/first_watch_story.gd")

const INTRO_SCENE := "res://scenes/ui/earth_years_montage.tscn"
const HERO_IMAGE := preload("res://art/storyboards/thura_earth/07_astronaut_selected.png")
const FADE_SECONDS := 0.85

var _background: TextureRect
var _start_button: Button
var _fade_overlay: ColorRect
var _continue_button: Button
var _continue_path := ""


func _ready() -> void:
	SKIN.apply(self)
	_build_screen()
	if is_instance_valid(_continue_button): _continue_button.grab_focus()
	else: _start_button.grab_focus()
	_play_ambient_zoom()


func _build_screen() -> void:
	_background = TextureRect.new()
	_background.texture = HERO_IMAGE
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	var scene_tint := ColorRect.new()
	scene_tint.color = Color(0.008, 0.014, 0.025, 0.28)
	scene_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scene_tint)

	var title_panel := PanelContainer.new()
	title_panel.anchor_left = 0.52
	title_panel.anchor_top = 0.0
	title_panel.anchor_right = 1.0
	title_panel.anchor_bottom = 1.0
	title_panel.add_theme_stylebox_override("panel", SKIN.panel(36.0))
	title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	title_panel.add_child(content)

	var header_meta := HBoxContainer.new()
	header_meta.add_theme_constant_override("separation", 12)
	var sys_badge := Label.new()
	sys_badge.text = "[ SYS // FLIGHT DECK ]"
	sys_badge.add_theme_font_override("font", SKIN.get_pixel_font())
	sys_badge.add_theme_font_size_override("font_size", 11)
	sys_badge.add_theme_color_override("font_color", Color(1.0, 0.78, 0.38))
	header_meta.add_child(sys_badge)
	var link_status := Label.new()
	link_status.text = "● TERMINAL LINKED"
	link_status.add_theme_font_override("font", SKIN.get_pixel_font())
	link_status.add_theme_font_size_override("font_size", 11)
	link_status.add_theme_color_override("font_color", Color(0.48, 0.93, 0.64))
	header_meta.add_child(link_status)
	content.add_child(header_meta)

	var eyebrow := Label.new()
	eyebrow.text = "ASTERIA-1 // DEEP-SPACE SURVEY EXPEDITION"
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eyebrow.add_theme_font_override("font", SKIN.get_pixel_font())
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_constant_override("line_spacing", 5)
	eyebrow.add_theme_color_override("font_color", Color(0.88, 0.70, 0.39))
	eyebrow.add_theme_constant_override("outline_size", 0)
	eyebrow.add_theme_color_override("font_outline_color", Color(0.01, 0.018, 0.03, 0.8))
	content.add_child(eyebrow)

	var title := Label.new()
	title.text = "ECHOES\nIN THE ORE"
	title.add_theme_font_override("font", SKIN.get_pixel_font())
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.97, 0.95, 0.89))
	title.add_theme_constant_override("outline_size", 0)
	title.add_theme_color_override("font_outline_color", Color(0.015, 0.025, 0.04, 0.95))
	title.add_theme_constant_override("line_spacing", 8)
	content.add_child(title)

	var tagline := Label.new()
	tagline.text = "Some discoveries are worth leaving behind."
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.add_theme_font_override("font", SKIN.get_pixel_font())
	tagline.add_theme_font_size_override("font_size", 15)
	tagline.add_theme_constant_override("line_spacing", 5)
	tagline.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9))
	content.add_child(tagline)

	var divider := HSeparator.new()
	divider.add_theme_color_override("separator_color", Color(0.24, 0.42, 0.46, 0.6))
	content.add_child(divider)

	var telemetry_info := Label.new()
	telemetry_info.text = "CREW SPECIALIST: THURA MIN  //  STATUS: APPROACHING EREBOS"
	telemetry_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	telemetry_info.add_theme_font_override("font", SKIN.get_pixel_font())
	telemetry_info.add_theme_font_size_override("font_size", 11)
	telemetry_info.add_theme_constant_override("line_spacing", 4)
	telemetry_info.add_theme_color_override("font_color", Color(0.62, 0.73, 0.76))
	content.add_child(telemetry_info)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	content.add_child(gap)

	_start_button = Button.new()
	_start_button.text = "[ INITIALIZE EXPEDITION  → ]"
	_start_button.custom_minimum_size = Vector2(340, 56)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_start_button.focus_mode = Control.FOCUS_ALL
	_start_button.add_theme_font_override("font", SKIN.get_pixel_font())
	_start_button.add_theme_font_size_override("font_size", 15)
	_start_button.pressed.connect(_on_start_pressed)
	content.add_child(_start_button)
	_continue_path = STORY_SAVE.continue_path()
	if not _continue_path.is_empty():
		_start_button.text = "[ START A NEW WATCH  → ]"
		_start_button.tooltip_text = "Start separately. Your existing campaign file will be preserved."
		_continue_button = Button.new()
		_continue_button.text = "[ CONTINUE WATCH  → ]"
		_continue_button.custom_minimum_size = Vector2(340, 52)
		_continue_button.add_theme_font_override("font", SKIN.get_pixel_font())
		_continue_button.add_theme_font_size_override("font_size", 14)
		_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_continue_button.pressed.connect(_on_continue_pressed)
		content.add_child(_continue_button)

	var footer := Label.new()
	footer.text = "ASTERIA-1 TACTICAL INTERFACE // SCI-FI SURVIVAL HORROR"
	footer.anchor_left = 0.04
	footer.anchor_top = 0.94
	footer.anchor_right = 0.50
	footer.anchor_bottom = 0.985
	footer.add_theme_font_override("font", SKIN.get_pixel_font())
	footer.add_theme_font_size_override("font_size", 10)
	footer.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9, 0.65))
	add_child(footer)

	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_overlay)


func _play_ambient_zoom() -> void:
	_background.pivot_offset = get_viewport_rect().size * 0.5
	_background.scale = Vector2(1.025, 1.025)
	var zoom_tween := create_tween().set_loops()
	zoom_tween.tween_property(_background, "scale", Vector2(1.065, 1.065), 20.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	zoom_tween.tween_property(_background, "scale", Vector2(1.025, 1.025), 20.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_start_pressed() -> void:
	if _start_button.disabled:
		return
	_start_button.disabled = true
	# Clear previous session persistent metadata for fresh expedition start
	for meta_k in [
		&"echoes_campaign_inventory_state",
		&"echoes_story_progression_state",
		&"echoes_arrival_briefing_shown",
		&"resonance_ore_sample_collected",
		&"resonance_ore_sample_stored",
		&"returning_from_planet",
		&"returning_from_second_floor",
		&"ship_story_continue_path",
		&"suit_flashlight_unlocked",
		&"engineering_multitool_unlocked",
		&"pressure_sealant_unlocked",
		&"mineral_survey_scanner_unlocked",
		&"survey_beacon_unlocked",
		&"emergency_flare_unlocked",
		&"industrial_plasma_cutter_unlocked",
		&"electrical_discharge_tool_unlocked",
		&"medical_injector_unlocked",
		&"captains_revolver_unlocked",
	]:
		if Engine.has_meta(meta_k):
			Engine.remove_meta(meta_k)
	if not Engine.has_meta("ship_maintenance_entry"):
		var story=STORY.new();story.request_cue("cue.thura.earth_years","existing_montage")
		var payload: Dictionary=STORY_SAVE.initial_campaign(story.snapshot())
		var path: String=STORY_SAVE.new_campaign_path()
		if not STORY_SAVE.valid_payload(payload) or STORY_SAVE.atomic_write(path,payload)!=OK:
			_start_button.disabled=false;_start_button.text="SAVE UNAVAILABLE / RETRY NEW WATCH";return
		STORY_SAVE.remember(path)
		Engine.set_meta("ship_story_bootstrap",story.snapshot())
		Engine.set_meta("ship_story_intro_payload",payload)
		Engine.set_meta("ship_story_intro_path",path)
	else:
		Engine.set_meta("ship_story_bootstrap", STORY.new().snapshot())
	await _fade_to_black()
	var result := get_tree().change_scene_to_file(INTRO_SCENE)
	if result != OK:
		push_error("Could not open the Earth-years montage: %s" % INTRO_SCENE)
		_start_button.disabled = false
		await _fade_from_black()

func _on_continue_pressed() -> void:
	if _start_button.disabled: return
	if STORY_SAVE.read(_continue_path).is_empty():
		_continue_button.disabled = true; _continue_button.text = "SAVE UNAVAILABLE / START A NEW WATCH"; return
	_start_button.disabled = true; _continue_button.disabled = true
	var payload: Dictionary=STORY_SAVE.read(_continue_path)
	var intro_status: String=str(payload.get("story",{}).get("cues",{}).get("cue.thura.earth_years",{}).get("status",""))
	var resume_intro: bool = intro_status in ["pending","cancelled","failed"] and not payload.get("story",{}).get("cues",{}).has("cue.asteria.arrival")
	if resume_intro:
		Engine.set_meta("ship_story_bootstrap",payload.story)
		Engine.set_meta("ship_story_intro_payload",payload)
		Engine.set_meta("ship_story_intro_path",_continue_path)
	else: Engine.set_meta("ship_story_continue_path", _continue_path)
	await _fade_to_black()
	var result := get_tree().change_scene_to_file(INTRO_SCENE if resume_intro else "res://scenes/ship/bare_ship_walkthrough.tscn")
	if result != OK:
		Engine.remove_meta("ship_story_continue_path")
		_start_button.disabled = false; _continue_button.disabled = false
		await _fade_from_black()


func _fade_to_black() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color", Color(0.0, 0.0, 0.0, 1.0), FADE_SECONDS)
	await tween.finished


func _fade_from_black() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), FADE_SECONDS)
	await tween.finished
