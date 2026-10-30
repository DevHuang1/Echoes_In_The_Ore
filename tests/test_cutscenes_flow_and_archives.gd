extends SceneTree

const WALK_HUD_SCENE = preload("res://scenes/ui/walk_hud.tscn")
const STORY_OVERLAY_SCRIPT = preload("res://scripts/ui/story_cutscene_overlay.gd")
const BARE_SHIP_SCRIPT = preload("res://scripts/ship/bare_ship_walkthrough.gd")
const SUBDECK_SCRIPT = preload("res://scripts/ship/second_floor_subdeck.gd")
const PLAYER_CONTROLLER_SCRIPT = preload("res://scripts/player/player_controller.gd")

func _init() -> void:
	print("\n--- BEGIN CUTSCENE FLOW, CAMERA GLIDES & STORY ARCHIVES TEST ---")

	_test_dialogue_audio_synth_sfx()
	_test_story_cutscene_overlay_presentation()
	_test_walk_hud_story_archives_tab()
	_test_bare_ship_cinematic_camera_and_triggers()
	_test_emotional_scripting_and_endings()
	_test_subdeck_cinematic_camera_and_triggers()

	print("--- ALL CUTSCENE FLOW & STORY ARCHIVE TESTS PASSED PERFECTLY! ---\n")
	quit(0)


func _test_dialogue_audio_synth_sfx() -> void:
	print("[TEST 1] Testing DialogueAudioSynth procedural acoustic tremor & impact SFX...")
	var tremor: AudioStream = DialogueAudioSynth.get_sfx("tremor_pulse")
	assert(tremor != null, "ERROR: tremor_pulse SFX must be generated!")
	assert(tremor is AudioStreamWAV, "ERROR: tremor_pulse must return AudioStreamWAV!")

	var thud: AudioStream = DialogueAudioSynth.get_sfx("landing_thud")
	assert(thud != null, "ERROR: landing_thud SFX must be generated!")

	var whisper: AudioStream = DialogueAudioSynth.get_sfx("echo_mimic_whisper")
	assert(whisper != null, "ERROR: echo_mimic_whisper SFX must be generated!")

	var squelch: AudioStream = DialogueAudioSynth.get_sfx("radio_squelch")
	assert(squelch != null, "ERROR: radio_squelch SFX must be generated!")
	print("✓ Test 1 Passed: Procedural acoustic tremor, landing thud, and echo whisper synthesized.")


func _test_story_cutscene_overlay_presentation() -> void:
	print("[TEST 2] Testing StoryCutsceneOverlay Letterbox Title Cards & Tremor Shakes...")
	var overlay = STORY_OVERLAY_SCRIPT.new()
	root.add_child(overlay)
	if not overlay.is_node_ready():
		overlay._ready()

	assert(overlay.get("_letterbox_top") != null, "ERROR: _letterbox_top must exist!")
	assert(overlay.get("_letterbox_bottom") != null, "ERROR: _letterbox_bottom must exist!")
	assert(overlay.get("_title_card_overlay") != null, "ERROR: _title_card_overlay must exist!")
	assert(overlay.get("_artwork_crt_vignette_overlay") != null, "ERROR: _artwork_crt_vignette_overlay must exist!")

	# Verify dynamic letterbox scaling
	overlay.call("_update_letterbox_bars")
	var top_bar: ColorRect = overlay.get("_letterbox_top")
	assert(top_bar.custom_minimum_size.y >= 48.0, "ERROR: Letterbox bar must dynamically size >= 48px!")

	var test_cutscene := {
		"act": "ACT III: FIRST BLOOD",
		"clock": "ASTERIA-1 // DAY 184 // CARGO HOLD",
		"title": "THE CONTAINMENT POD IS EMPTY",
		"echo_pulse": true,
		"slides": [
			{
				"speaker": "THE ECHO (OKOYE'S VOICE) // CARGO BAY",
				"image": "res://art/storyboards/thura_earth/01_yangon_rooftop.png",
				"text": "Thura, I found him.",
				"shake": true
			}
		]
	}

	overlay.call("play_cutscene", &"test_breach", test_cutscene)
	assert(overlay.call("is_active"), "ERROR: Cutscene overlay must be active!")
	assert(overlay.get("_title_card_showing"), "ERROR: Title card must be active initially!")
	assert(overlay.get("_title_card_act_label").text.find("ACT III: FIRST BLOOD") != -1, "ERROR: Title card act label mismatch!")
	assert(overlay.get("_last_pulse_beat") == 1, "ERROR: _last_pulse_beat must be 1 to prevent double trigger!")

	# Simulate dismiss title card
	overlay.call("_dismiss_title_card")
	assert(not overlay.get("_title_card_showing"), "ERROR: Title card should dismiss into slide sequence!")

	# Verify CRT vignette overlay exists and is visible on slide with image
	var crt_overlay: Control = overlay.get("_artwork_crt_vignette_overlay")
	assert(crt_overlay != null and crt_overlay.visible, "ERROR: CRT vignette overlay must be visible for image slide!")

	# Verify screen shake trigger
	overlay.call("trigger_screen_shake", 6.0, 0.4)
	assert(overlay.get("_shake_timer") > 0.0, "ERROR: Screen shake timer must be positive!")

	# Verify pulse timer process
	overlay._process(0.5)
	assert(overlay.get("_echo_pulse_active"), "ERROR: Echo pulse must remain active!")

	overlay.call("_close_cutscene")
	assert(not overlay.call("is_active"), "ERROR: Cutscene overlay must be inactive after close!")
	overlay.queue_free()
	print("✓ Test 2 Passed: Dynamic letterbox bars, CRT & vignette visual overlay, dramatic title cards, and tremor shake verified.")


func _test_walk_hud_story_archives_tab() -> void:
	# Create a dummy current_scene to test replay freezing
	var dummy_script := GDScript.new()
	dummy_script.source_code = "extends Node2D\nvar _cutscene_open: bool = false\nfunc _update_player_walk_state() -> void:\n\tpass\n"
	dummy_script.reload()
	var dummy_scene := Node2D.new()
	dummy_scene.set_script(dummy_script)
	root.add_child(dummy_scene)
	current_scene = dummy_scene

	var hud: WalkHud = WALK_HUD_SCENE.instantiate() as WalkHud
	dummy_scene.add_child(hud)
	if not hud.is_node_ready():
		hud._ready()
	hud.setup(null, [], Vector2.ZERO, Vector2(1774, 887))

	assert(hud.get("_story_archives_view_container") != null, "ERROR: _story_archives_view_container must exist!")
	assert(hud.get("_tasks_filter_buttons").has(&"story_archives"), "ERROR: filter buttons must include 'story_archives'!")

	# Switch to STORY ARCHIVES tab
	hud.set("_tasks_filter_tab", &"story_archives")
	hud.call("_refresh_tasks_overlay")

	assert(hud.get("_story_archives_view_container").visible, "ERROR: Story archives container must be visible!")
	assert(not hud.get("_tasks_list_scroll").visible, "ERROR: Tasks list scroll must be hidden on archives tab!")
	assert(not hud.get("_roadmap_view_container").visible, "ERROR: Roadmap scroll must be hidden on archives tab!")

	# Verify archives inner cards populated
	var inner: VBoxContainer = hud.get("_story_archives_inner")
	assert(inner != null, "ERROR: _story_archives_inner must exist!")
	assert(inner.get_child_count() >= 5, "ERROR: Expected at least 5 archive items populated!")

	# Trigger story archive replay
	hud.call("_replay_story_archive", &"cabin_may_recording")
	var overlay: CanvasLayer = hud.get_node_or_null("RoadmapCutsceneOverlay") as CanvasLayer
	assert(overlay != null, "ERROR: RoadmapCutsceneOverlay must be instantiated for replay!")
	assert(dummy_scene.get("_cutscene_open") == true, "ERROR: Scene _cutscene_open must be true during archive replay!")

	# Close cutscene and verify restoration
	overlay.call("_close_cutscene")
	assert(dummy_scene.get("_cutscene_open") == false, "ERROR: Scene _cutscene_open must reset to false after replay finishes!")
	current_scene = null
	dummy_scene.queue_free()

	# Switch back to ALL tab
	hud.set("_tasks_filter_tab", &"all")
	hud.call("_refresh_tasks_overlay")
	assert(not hud.get("_story_archives_view_container").visible, "ERROR: Archives container must hide on 'all' tab!")
	assert(hud.get("_tasks_list_scroll").visible, "ERROR: Tasks list scroll must restore on 'all' tab!")

	hud.queue_free()
	print("✓ Test 3 Passed: Story & Memory Archives tab toggles cleanly and replay synchronizes HUD & player freeze.")


func _test_bare_ship_cinematic_camera_and_triggers() -> void:
	print("[TEST 4] Testing BareShipWalkthrough camera glides & turning point triggers...")
	var ship = BARE_SHIP_SCRIPT.new()
	assert(ship.has_method("_glide_camera_to_prop"), "ERROR: ship must implement _glide_camera_to_prop!")
	assert(ship.has_method("_restore_camera_from_prop"), "ERROR: ship must implement _restore_camera_from_prop!")
	assert(ship.has_method("_trigger_cinematic_with_camera_focus"), "ERROR: ship must implement _trigger_cinematic_with_camera_focus!")

	# Check that all story stations have station paths defined
	var stations: Array = BARE_SHIP_SCRIPT.STORY_STATIONS
	var expected_stations := [
		&"cabin_may_recording",
		&"bridge_flight_piloting",
		&"drone_vibration_scan",
		&"landing_prep_beacons",
		&"erebos_landing_descent",
		&"cargo_breach_inspection",
		&"commanders_secret_bridge",
		&"act_v_finale_home"
	]
	for exp_id in expected_stations:
		var found := false
		for st in stations:
			if st.get("id") == exp_id:
				found = true
				assert(not st.get("station_path").is_empty(), "ERROR: Station %s must have a station_path!" % String(exp_id))
				break
		assert(found, "ERROR: Required station %s missing from STORY_STATIONS!" % String(exp_id))

	# Test player velocity zeroing and atomic locking
	var PlayerController = load("res://scripts/player/player_controller.gd")
	var dummy_player = PlayerController.new()
	dummy_player.name = "Player"
	dummy_player.velocity = Vector2(250.0, -150.0)
	var dummy_cam := Camera2D.new()
	dummy_player.add_child(dummy_cam)
	dummy_player.camera = dummy_cam
	ship.player = dummy_player
	ship.add_child(dummy_player)

	var dummy_cutscene := STORY_OVERLAY_SCRIPT.new()
	ship.set("_story_cutscene", dummy_cutscene)
	ship.add_child(dummy_cutscene)

	var fake_data := {"act": "TEST", "title": "TEST", "slides": [{"text": "Hello"}]}
	ship.call("_trigger_cinematic_with_camera_focus", &"test_st", fake_data)

	assert(ship.get("_cutscene_open") == true, "ERROR: _cutscene_open must be true immediately on trigger invocation!")
	assert(dummy_player.get("velocity") == Vector2.ZERO, "ERROR: Player velocity must be zeroed immediately!")

	dummy_cutscene.call("_close_cutscene")
	ship.call("_on_story_cutscene_finished", &"test_st", &"")
	assert(ship.get("_cutscene_open") == false, "ERROR: _cutscene_open must reset to false after finish!")

	# Test camera zoom-in on prop and zoom-back-in restoration to 1.75
	dummy_cam.zoom = Vector2(1.75, 1.75)
	ship.call("_glide_camera_to_prop", Vector2(100.0, 100.0), 2.15, 0.05)
	assert(ship.get("_monster_cinematic_camera_saved") == true, "ERROR: Camera state must be saved on glide!")
	assert(ship.get("_monster_cinematic_camera_zoom") == Vector2(1.75, 1.75), "ERROR: Original camera zoom must be saved as 1.75!")
	ship.call("_restore_camera_from_prop", 0.01)
	assert(ship.get("_monster_cinematic_camera_saved") == false, "ERROR: Camera saved flag must reset after restore!")

	ship.free()
	print("✓ Test 4 Passed: Camera glide methods, immediate velocity zeroing, and prop focus paths verified.")


func _test_emotional_scripting_and_endings() -> void:
	print("[TEST 5] Testing Emotional Horror Scripting & 4 Branching Trajectory Endings...")
	var ship = BARE_SHIP_SCRIPT.new()

	# 1. Check Prologue May's Recording text for Yangon rooftop & paper star
	var may_cutscene: Dictionary = ship.call("_build_cutscene_data", &"cabin_may_recording")
	var may_slides: Array = may_cutscene.get("slides", [])
	assert(may_slides.size() >= 2, "ERROR: cabin_may_recording must have at least 2 slides!")
	var text_may_1: String = may_slides[0].get("text", "")
	assert(text_may_1.find("Yangon") != -1 and text_may_1.find("Do astronauts ever get afraid?") != -1,
		"ERROR: First slide must feature physics-teacher mother on rainy Yangon rooftop!")
	var text_may_2: String = may_slides[1].get("text", "")
	assert(text_may_2.find("paper star") != -1, "ERROR: Second slide must feature May's folded paper star!")

	# 2. Check Act III Cargo Breach for Dr. Okoye mimicry whisper & lights out
	var cargo_cutscene: Dictionary = ship.call("_build_cutscene_data", &"cargo_breach_inspection")
	var cargo_slides: Array = cargo_cutscene.get("slides", [])
	var okoye_whisper_found := false
	for sl in cargo_slides:
		if sl.get("text", "").find("Thura, I found him") != -1:
			okoye_whisper_found = true
			break
	assert(okoye_whisper_found, "ERROR: cargo_breach_inspection must contain Dr. Okoye's whisper!")

	# 3. Check Act IV Commander Chen Standoff & choices
	var chen_cutscene: Dictionary = ship.call("_build_cutscene_data", &"commanders_secret_bridge")
	var chen_slides: Array = chen_cutscene.get("slides", [])
	var choice_slide: Dictionary = chen_slides[chen_slides.size() - 1]
	var choices: Array = choice_slide.get("choices", [])
	assert(choices.size() >= 2, "ERROR: commanders_secret_bridge must provide choices!")

	# 4. Check Act V Finale for Mother's Echo Mimicry and 4 branching trajectories
	var finale_cutscene: Dictionary = ship.call("_build_cutscene_data", &"act_v_finale_home")
	var finale_slides: Array = finale_cutscene.get("slides", [])
	var mother_mimic_found := false
	for sl in finale_slides:
		if sl.get("speaker", "").find("MOTHER'S VOICE") != -1 and sl.get("text", "").find("Do astronauts ever get afraid?") != -1:
			mother_mimic_found = true
			break
	assert(mother_mimic_found, "ERROR: Act V finale must contain Mother's Echo mimicry at the airlock!")

	var final_slide: Dictionary = finale_slides[finale_slides.size() - 1]
	var end_choices: Array = final_slide.get("choices", [])
	assert(end_choices.size() == 4, "ERROR: Act V finale must feature 4 branching endings!")
	var expected_endings := [&"ending_dawn", &"ending_trajectory", &"ending_homecoming", &"ending_voices"]
	for exp_end in expected_endings:
		var has_end := false
		for ch in end_choices:
			if ch.get("id") == exp_end:
				has_end = true
				break
		assert(has_end, "ERROR: Missing expected ending %s in Act V finale!" % String(exp_end))

	ship.free()
	print("✓ Test 5 Passed: Deep emotional horror scripting and 4 branching trajectory endings verified.")


func _test_subdeck_cinematic_camera_and_triggers() -> void:
	print("[TEST 6] Testing SecondFloorSubdeck camera glide & turning point triggers...")
	var subdeck = SUBDECK_SCRIPT.new()
	assert(subdeck.has_method("_glide_camera_to_pos"), "ERROR: subdeck must implement _glide_camera_to_pos!")
	assert(subdeck.has_method("_restore_camera_from_prop"), "ERROR: subdeck must implement _restore_camera_from_prop!")
	assert(subdeck.has_method("_trigger_subdeck_cutscene_with_camera_focus"), "ERROR: subdeck must implement _trigger_subdeck_cutscene_with_camera_focus!")

	# Verify subdeck shadow nest and pipe pressure cutscene data
	var shadow_data: Dictionary = subdeck.call("_build_subdeck_cutscene", &"subdeck_shadow_nest_check")
	assert(not shadow_data.is_empty(), "ERROR: subdeck_shadow_nest_check must have cutscene data!")
	assert(bool(shadow_data.get("echo_pulse", false)), "ERROR: shadow nest must have echo_pulse enabled!")

	var pipe_data: Dictionary = subdeck.call("_build_subdeck_cutscene", &"subdeck_pipe_pressure")
	assert(not pipe_data.is_empty(), "ERROR: subdeck_pipe_pressure must have cutscene data!")

	# Verify subdeck camera zoom behavior
	var subdeck_player = PLAYER_CONTROLLER_SCRIPT.new()
	var subdeck_cam = Camera2D.new()
	subdeck_cam.zoom = Vector2(1.75, 1.75)
	subdeck_player.add_child(subdeck_cam)
	subdeck_player.camera = subdeck_cam
	subdeck.player = subdeck_player
	subdeck.add_child(subdeck_player)

	subdeck.call("_glide_camera_to_pos", Vector2(120.0, 80.0), 2.15, 0.05)
	assert(subdeck.get("_monster_cinematic_camera_saved") == true, "ERROR: Subdeck camera state must be saved on glide!")
	assert(subdeck.get("_monster_cinematic_camera_zoom") == Vector2(1.75, 1.75), "ERROR: Subdeck camera zoom must be saved as 1.75!")
	subdeck.call("_restore_camera_from_prop", 0.01)
	assert(subdeck.get("_monster_cinematic_camera_saved") == false, "ERROR: Subdeck camera saved flag must reset after restore!")

	subdeck.free()
	print("✓ Test 6 Passed: SecondFloorSubdeck camera glides and Sub-Deck 02 turning points verified.")
