extends Control

const SKIN := preload("res://scripts/ui/pixel_ui.gd")
const STORY_SAVE := preload("res://scripts/ship/ship_story_save.gd")
const STORY := preload("res://scripts/ship/first_watch_story.gd")

const INTRO_SCENE := "res://scenes/ui/earth_years_montage.tscn"
const HERO_IMAGE := preload("res://art/storyboards/thura_earth/07_astronaut_selected.png")
const TITLE_MUSIC := preload("res://audio/music/Theme music dubstep.mp3")
const FADE_SECONDS := 0.85

var _background: TextureRect
var _start_button: Button
var _fade_overlay: ColorRect
var _continue_button: Button
var _continue_path := ""
var _cloud_badge: Label
var _auth_label: Label
var _google_btn: Button


func _ready() -> void:
	SKIN.apply(self)
	_build_screen()
	if is_instance_valid(_continue_button): _continue_button.grab_focus()
	else: _start_button.grab_focus()
	_play_ambient_zoom()
	_setup_firebase_listeners()
	if has_node("/root/BackgroundMusic"):
		BackgroundMusic.play_title_music()


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

	_cloud_badge = Label.new()
	_cloud_badge.text = "● CLOUD: INITIALIZING"
	_cloud_badge.add_theme_font_override("font", SKIN.get_pixel_font())
	_cloud_badge.add_theme_font_size_override("font_size", 11)
	_cloud_badge.add_theme_color_override("font_color", Color(0.88, 0.70, 0.39))
	header_meta.add_child(_cloud_badge)
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

	# ── FIREBASE & GOOGLE SIGN-IN ───────────────────────────────────────────
	var cloud_sep := HSeparator.new()
	cloud_sep.add_theme_color_override("separator_color", Color(0.24, 0.42, 0.46, 0.4))
	content.add_child(cloud_sep)

	_auth_label = Label.new()
	_auth_label.text = "CLOUD PERSISTENCE: CONNECTING..."
	_auth_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_auth_label.add_theme_font_override("font", SKIN.get_pixel_font())
	_auth_label.add_theme_font_size_override("font_size", 10)
	_auth_label.add_theme_color_override("font_color", Color(0.62, 0.73, 0.76))
	content.add_child(_auth_label)

	_google_btn = Button.new()
	_google_btn.text = "[ SIGN IN WITH GOOGLE  G ]"
	_google_btn.custom_minimum_size = Vector2(340, 44)
	_google_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_google_btn.focus_mode = Control.FOCUS_ALL
	_google_btn.add_theme_font_override("font", SKIN.get_pixel_font())
	_google_btn.add_theme_font_size_override("font_size", 12)
	_google_btn.pressed.connect(_on_google_btn_pressed)
	content.add_child(_google_btn)

	# ── INPUT MODE TOGGLE ────────────────────────────────────────────────────
	var mode_sep := HSeparator.new()
	mode_sep.add_theme_color_override("separator_color", Color(0.24, 0.42, 0.46, 0.4))
	content.add_child(mode_sep)

	var mode_header := Label.new()
	mode_header.text = "INPUT MODE"
	mode_header.add_theme_font_override("font", SKIN.get_pixel_font())
	mode_header.add_theme_font_size_override("font_size", 10)
	mode_header.add_theme_color_override("font_color", Color(1.0, 0.78, 0.38))
	content.add_child(mode_header)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	mode_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content.add_child(mode_row)

	var auto_btn := _make_mode_btn("AUTO", -1)
	var pc_btn   := _make_mode_btn("PC", 0)
	var mob_btn  := _make_mode_btn("MOBILE", 1)
	mode_row.add_child(auto_btn)
	mode_row.add_child(pc_btn)
	mode_row.add_child(mob_btn)
	_refresh_landing_mode_btns(auto_btn, pc_btn, mob_btn)
	# ─────────────────────────────────────────────────────────────────────────

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
	DialogueAudioSynth.play_sfx("button_click", self, -4.0)
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
	if has_node("/root/BackgroundMusic"):
		BackgroundMusic.stop_music(FADE_SECONDS)
	await _fade_to_black()
	var result := get_tree().change_scene_to_file(INTRO_SCENE)
	if result != OK:
		push_error("Could not open the Earth-years montage: %s" % INTRO_SCENE)
		_start_button.disabled = false
		if has_node("/root/BackgroundMusic"):
			BackgroundMusic.play_title_music(FADE_SECONDS)
		await _fade_from_black()

func _on_continue_pressed() -> void:
	if _start_button.disabled: return
	DialogueAudioSynth.play_sfx("button_click", self, -4.0)
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
	if has_node("/root/BackgroundMusic"):
		BackgroundMusic.stop_music(FADE_SECONDS)
	await _fade_to_black()
	var result := get_tree().change_scene_to_file(INTRO_SCENE if resume_intro else "res://scenes/ship/bare_ship_walkthrough.tscn")
	if result != OK:
		Engine.remove_meta("ship_story_continue_path")
		_start_button.disabled = false; _continue_button.disabled = false
		if has_node("/root/BackgroundMusic"):
			BackgroundMusic.play_title_music(FADE_SECONDS)
		await _fade_from_black()


func _fade_to_black() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color", Color(0.0, 0.0, 0.0, 1.0), FADE_SECONDS)
	await tween.finished


func _fade_from_black() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), FADE_SECONDS)
	await tween.finished


# ── MOBILE / PC MODE TOGGLE HELPERS ─────────────────────────────────────────

func _get_ib() -> Node:
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		return get_tree().root.get_node_or_null("InputBindings")
	return null


func _current_mode_override() -> int:
	var ib := _get_ib()
	if ib != null and "mobile_mode_override" in ib:
		return int(ib.get("mobile_mode_override"))
	return -1


func _make_mode_btn(label: String, override_value: int) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(96, 38)
	btn.add_theme_font_override("font", SKIN.get_pixel_font())
	btn.add_theme_font_size_override("font_size", 11)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func():
		DialogueAudioSynth.play_sfx("switch_toggle", btn, -5.0)
		var ib := _get_ib()
		if ib != null and "mobile_mode_override" in ib:
			ib.set("mobile_mode_override", override_value)
		var row := btn.get_parent() as HBoxContainer
		if row != null:
			_refresh_landing_mode_btns(
				row.get_child(0) as Button,
				row.get_child(1) as Button,
				row.get_child(2) as Button)
	)
	return btn


func _refresh_landing_mode_btns(auto_btn: Button, pc_btn: Button, mob_btn: Button) -> void:
	var cur := _current_mode_override()
	_apply_mode_btn_style(auto_btn, cur == -1)
	_apply_mode_btn_style(pc_btn,   cur == 0)
	_apply_mode_btn_style(mob_btn,  cur == 1)


func _apply_mode_btn_style(btn: Button, active: bool) -> void:
	if not is_instance_valid(btn):
		return
	if active:
		btn.add_theme_color_override("font_color", Color(0.015, 0.030, 0.045))
		var style_on := StyleBoxFlat.new()
		style_on.bg_color = Color(0.38, 0.88, 0.98)
		style_on.border_color = Color(1.0, 0.82, 0.40)
		style_on.set_border_width_all(1)
		style_on.corner_radius_top_left = 4
		style_on.corner_radius_top_right = 4
		style_on.corner_radius_bottom_left = 4
		style_on.corner_radius_bottom_right = 4
		style_on.content_margin_left = 8.0
		style_on.content_margin_right = 8.0
		style_on.content_margin_top = 6.0
		style_on.content_margin_bottom = 6.0
		style_on.anti_aliasing = false
		btn.add_theme_stylebox_override("normal", style_on)
		btn.add_theme_stylebox_override("hover", style_on)
		btn.add_theme_stylebox_override("pressed", style_on)
	else:
		btn.add_theme_color_override("font_color", Color(0.59, 0.69, 0.73))
		var style_off := StyleBoxFlat.new()
		style_off.bg_color = Color(0.035, 0.055, 0.085)
		style_off.border_color = Color(0.34, 0.51, 0.55)
		style_off.set_border_width_all(1)
		style_off.corner_radius_top_left = 4
		style_off.corner_radius_top_right = 4
		style_off.corner_radius_bottom_left = 4
		style_off.corner_radius_bottom_right = 4
		style_off.content_margin_left = 8.0
		style_off.content_margin_right = 8.0
		style_off.content_margin_top = 6.0
		style_off.content_margin_bottom = 6.0
		style_off.anti_aliasing = false
		btn.add_theme_stylebox_override("normal", style_off)
		var style_hover := style_off.duplicate()
		style_hover.border_color = Color(0.38, 0.88, 0.98)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_hover)


# ==============================================================================
# Firebase & Google Authentication UI
# ==============================================================================
func _setup_firebase_listeners() -> void:
	var fb = get_node_or_null("/root/FirebaseManager")
	if fb == null:
		if is_instance_valid(_cloud_badge):
			_cloud_badge.text = "● CLOUD: OFFLINE"
		return
	
	fb.auth_completed.connect(func(_success: bool, _uid: String): _update_firebase_ui())
	fb.google_sign_in_completed.connect(func(_success: bool, _uid: String, _email: String): _update_firebase_ui())
	fb.signed_out.connect(func(): _update_firebase_ui())
	_update_firebase_ui()


func _update_firebase_ui() -> void:
	var fb = get_node_or_null("/root/FirebaseManager")
	if fb == null:
		if is_instance_valid(_cloud_badge):
			_cloud_badge.text = "● CLOUD: UNAVAILABLE"
			_cloud_badge.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
		return
	
	if fb.is_authenticated:
		if fb.auth_provider == "google.com":
			if is_instance_valid(_cloud_badge):
				_cloud_badge.text = "● CLOUD: GOOGLE"
				_cloud_badge.add_theme_color_override("font_color", Color(0.48, 0.93, 0.64))
			if is_instance_valid(_auth_label):
				var identity: String = fb.user_email if not fb.user_email.is_empty() else fb.user_display_name
				_auth_label.text = "AUTHENTICATED: %s (CLOUD SAVES ACTIVE)" % identity
				_auth_label.add_theme_color_override("font_color", Color(0.48, 0.93, 0.64))
			if is_instance_valid(_google_btn):
				var tag: String = fb.user_email.split("@")[0] if "@" in fb.user_email else "GOOGLE"
				_google_btn.text = "[ SIGN OUT (%s) ]" % tag
				_google_btn.disabled = false
		else:
			if is_instance_valid(_cloud_badge):
				_cloud_badge.text = "● CLOUD: GUEST"
				_cloud_badge.add_theme_color_override("font_color", Color(0.88, 0.70, 0.39))
			if is_instance_valid(_auth_label):
				var short_uid = fb.current_user_id.substr(0, 8) if fb.current_user_id.length() >= 8 else fb.current_user_id
				_auth_label.text = "GUEST LINKED (UID: %s...) // SIGN IN TO SYNC TO GOOGLE" % short_uid
				_auth_label.add_theme_color_override("font_color", Color(0.62, 0.73, 0.76))
			if is_instance_valid(_google_btn):
				_google_btn.text = "[ SIGN IN WITH GOOGLE  G ]"
				_google_btn.disabled = false
	else:
		if is_instance_valid(_cloud_badge):
			_cloud_badge.text = "● CLOUD: CONNECTING..."
			_cloud_badge.add_theme_color_override("font_color", Color(1.0, 0.78, 0.38))
		if is_instance_valid(_auth_label):
			_auth_label.text = "INITIALIZING FIREBASE SERVICES..."
			_auth_label.add_theme_color_override("font_color", Color(0.62, 0.73, 0.76))
		if is_instance_valid(_google_btn):
			_google_btn.text = "[ SIGN IN WITH GOOGLE  G ]"
			_google_btn.disabled = false


func _on_google_btn_pressed() -> void:
	var fb = get_node_or_null("/root/FirebaseManager")
	if fb == null:
		return
	
	DialogueAudioSynth.play_sfx("button_click", self, -4.0)
	
	if fb.is_authenticated and fb.auth_provider == "google.com":
		# Sign out back to guest
		if is_instance_valid(_auth_label):
			_auth_label.text = "Signing out..."
		fb.sign_out()
	else:
		if is_instance_valid(_google_btn):
			_google_btn.disabled = true
		if is_instance_valid(_auth_label):
			_auth_label.text = "Opening browser for Google Authentication..."
			_auth_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.38))
		
		fb.sign_in_with_google(func(success: bool, _uid: String, email: String):
			if is_instance_valid(_google_btn):
				_google_btn.disabled = false
			_update_firebase_ui()
			if success:
				print("[LandingScreen] Google Sign-in successful for: ", email)
				# Check for remote save in Firestore
				fb.load_player_game(func(load_success: bool, data: Dictionary):
					if load_success and not data.is_empty():
						print("[LandingScreen] Remote cloud save verified for user.")
				)
		)

