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
	title_panel.anchor_left = 0.55
	title_panel.anchor_top = 0.0
	title_panel.anchor_right = 1.0
	title_panel.anchor_bottom = 1.0
	title_panel.add_theme_stylebox_override("panel", SKIN.panel(40.0))
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
	sys_badge.add_theme_font_size_override("font_size", 9)
	sys_badge.add_theme_color_override("font_color", Color(1.0, 0.78, 0.38))
	header_meta.add_child(sys_badge)
	var link_status := Label.new()
	link_status.text = "● TERMINAL LINKED"
	link_status.add_theme_font_size_override("font_size", 9)
	link_status.add_theme_color_override("font_color", Color(0.48, 0.93, 0.64))
	header_meta.add_child(link_status)
	content.add_child(header_meta)

	var eyebrow := Label.new()
	eyebrow.text = "ASTERIA-1 // DEEP-SPACE SURVEY EXPEDITION"
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eyebrow.add_theme_font_size_override("font_size", 10)
	eyebrow.add_theme_constant_override("line_spacing", 4)
	eyebrow.add_theme_color_override("font_color", Color(0.88, 0.70, 0.39))
	eyebrow.add_theme_constant_override("outline_size", 0)
	eyebrow.add_theme_color_override("font_outline_color", Color(0.01, 0.018, 0.03, 0.8))
	content.add_child(eyebrow)

	var title := Label.new()
	title.text = "ECHOES\nIN THE ORE"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.97, 0.95, 0.89))
	title.add_theme_constant_override("outline_size", 0)
	title.add_theme_color_override("font_outline_color", Color(0.015, 0.025, 0.04, 0.95))
	title.add_theme_constant_override("line_spacing", 6)
	content.add_child(title)

	var tagline := Label.new()
	tagline.text = "Some discoveries are worth leaving behind."
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.add_theme_font_size_override("font_size", 11)
	tagline.add_theme_constant_override("line_spacing", 4)
	tagline.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9))
	content.add_child(tagline)

	var divider := HSeparator.new()
	divider.add_theme_color_override("separator_color", Color(0.24, 0.42, 0.46, 0.6))
	content.add_child(divider)

	var telemetry_info := Label.new()
	telemetry_info.text = "CREW SPECIALIST: THURA MIN  //  STATUS: APPROACHING EREBOS"
	telemetry_info.add_theme_font_size_override("font_size", 9)
	telemetry_info.add_theme_constant_override("line_spacing", 4)
	telemetry_info.add_theme_color_override("font_color", Color(0.62, 0.73, 0.76))
	content.add_child(telemetry_info)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	content.add_child(gap)

	_start_button = Button.new()
	_start_button.text = "[ INITIALIZE EXPEDITION  → ]"
	_start_button.custom_minimum_size = Vector2(280, 52)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_start_button.focus_mode = Control.FOCUS_ALL
	_start_button.add_theme_font_size_override("font_size", 12)
	_start_button.pressed.connect(_on_start_pressed)
	content.add_child(_start_button)
	_continue_path = STORY_SAVE.continue_path()
	if not _continue_path.is_empty():
		_start_button.text = "[ START A NEW WATCH  → ]"
		_start_button.tooltip_text = "Start separately. Your existing campaign file will be preserved."
		_continue_button = Button.new()
		_continue_button.text = "[ CONTINUE WATCH  → ]"
		_continue_button.custom_minimum_size = Vector2(280, 48)
		_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_continue_button.add_theme_font_size_override("font_size", 11)
		_continue_button.pressed.connect(_on_continue_pressed)
		content.add_child(_continue_button)

	var footer := Label.new()
	footer.text = "ASTERIA-1 TACTICAL INTERFACE // SCI-FI SURVIVAL HORROR"
	footer.anchor_left = 0.04
	footer.anchor_top = 0.94
	footer.anchor_right = 0.48
	footer.anchor_bottom = 0.985
	footer.add_theme_font_size_override("font_size", 9)
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
	Engine.set_meta("ship_story_continue_path", _continue_path)
	await _fade_to_black()
	var result := get_tree().change_scene_to_file("res://scenes/ship/bare_ship_walkthrough.tscn")
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
