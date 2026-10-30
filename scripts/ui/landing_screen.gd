extends Control

const SKIN := preload("res://scripts/ui/pixel_ui.gd")
const EC := preload("res://scripts/ui/eito/eito_controls.gd")
const UI := preload("res://scripts/ui/eito/eito_ui.gd")
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
	scene_tint.color = Color(0.035, 0.05, 0.06, 0.30)
	scene_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scene_tint)

	# Flight-deck terminal: a screwed metal plate on the right, stamped header,
	# title, a phosphor status screen and paper push-caps for the two actions.
	var title_panel := EC.Plate.new("ASTERIA-1 / FLIGHT DECK", "module", true, 36.0)
	title_panel.set_chip("Terminal linked", "live")
	title_panel.anchor_left = 0.55
	title_panel.anchor_top = 0.0
	title_panel.anchor_right = 1.0
	title_panel.anchor_bottom = 1.0
	title_panel.offset_left = 0.0
	title_panel.offset_top = 16.0
	title_panel.offset_right = -16.0
	title_panel.offset_bottom = -16.0
	title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	title_panel.add_child(content)

	var eyebrow := EC.label("DEEP-SPACE SURVEY EXPEDITION", "EitoAmber", 14)
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(eyebrow)

	var title := EC.stamp(EC.label("Echoes\nin the Ore", "EitoTitle", 60))
	title.add_theme_constant_override("line_spacing", -6)
	title.add_theme_constant_override("shadow_offset_y", 4)
	content.add_child(title)

	var tagline := EC.label("Some discoveries are worth leaving behind.", "", 20, Color("#b4c3c1"))
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(tagline)

	var screen := EC.panel("glass", 14)
	var readings := VBoxContainer.new()
	readings.add_theme_constant_override("separation", 4)
	screen.add_child(readings)
	for pair in [["CREW SPECIALIST", "Thura Min"], ["STATUS", "Approaching Erebos"], ["MISSION CLOCK", "Day 184"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var key := EC.label(pair[0], "EitoTag", 12, UI.PHOS_DIM)
		key.custom_minimum_size.x = 150
		row.add_child(key)
		row.add_child(EC.label(pair[1], "EitoValue", 18))
		readings.add_child(row)
	content.add_child(screen)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	content.add_child(gap)

	_start_button = Button.new()
	_start_button.theme_type_variation = &"PushButton"
	_start_button.text = "BEGIN EXPEDITION"
	_start_button.custom_minimum_size = Vector2(300, 56)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_start_button.focus_mode = Control.FOCUS_ALL
	_start_button.add_theme_font_size_override("font_size", 18)
	_start_button.pressed.connect(_on_start_pressed)
	content.add_child(_start_button)
	_continue_path = STORY_SAVE.continue_path()
	if not _continue_path.is_empty():
		_start_button.text = "START A NEW WATCH"
		_start_button.tooltip_text = "Start separately. Your existing campaign file will be preserved."
		_continue_button = Button.new()
		_continue_button.theme_type_variation = &"PushButton"
		_continue_button.text = "CONTINUE WATCH"
		_continue_button.custom_minimum_size = Vector2(300, 56)
		_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_continue_button.add_theme_font_size_override("font_size", 18)
		_continue_button.pressed.connect(_on_continue_pressed)
		content.add_child(_continue_button)
		content.move_child(_continue_button, _start_button.get_index())

	var hint := HBoxContainer.new()
	hint.add_theme_constant_override("separation", 6)
	hint.add_child(EC.Keycap.new("Enter"))
	hint.add_child(EC.label("Select", "EitoHint"))
	content.add_child(hint)

	var footer := EC.label("ASTERIA-1 TACTICAL INTERFACE / SCI-FI SURVIVAL HORROR", "EitoTag", 12, Color(0.9, 0.88, 0.8, 0.7))
	footer.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	footer.add_theme_constant_override("shadow_offset_y", 2)
	footer.anchor_left = 0.03
	footer.anchor_top = 0.94
	footer.anchor_right = 0.52
	footer.anchor_bottom = 0.985
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
	if not Engine.has_meta("ship_maintenance_entry"):
		var story=STORY.new();story.request_cue("cue.thura.earth_years","existing_montage")
		var payload: Dictionary=STORY_SAVE.initial_campaign(story.snapshot())
		var path: String=STORY_SAVE.new_campaign_path()
		if not STORY_SAVE.valid_payload(payload) or STORY_SAVE.atomic_write(path,payload)!=OK:
			_start_button.disabled=false;_start_button.text="SAVE UNAVAILABLE / RETRY";return
		STORY_SAVE.remember(path)
		Engine.set_meta("ship_story_bootstrap",story.snapshot())
		Engine.set_meta("ship_story_intro_payload",payload)
		Engine.set_meta("ship_story_intro_path",path)
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
