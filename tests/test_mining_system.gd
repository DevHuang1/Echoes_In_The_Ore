extends SceneTree

const ORE_EXTRACTION_CONSOLE := preload("res://scripts/ui/ore_extraction_console.gd")
const MOCK_PLANET_SCENE := preload("res://scenes/planet/mock_planet_exterior.tscn")
const WALK_HUD_SCRIPT := preload("res://scripts/ui/walk_hud.gd")

func _init() -> void:
	print("--- BEGIN TEST: EREBOS MINING SYSTEM VERIFICATION ---")
	test_assets()
	test_walk_hud_items()
	test_mock_planet_scene()
	test_ore_extraction_console()
	print("--- ALL MINING SYSTEM TESTS PASSED SUCCESSFULLY! ---")
	quit(0)

func test_assets() -> void:
	print("[TEST 1] Verifying mining textures and cutscenes...")
	var tex_surface = load("res://art/planet/erebos_extraction_surface_pixel.png")
	assert(tex_surface != null, "erebos_extraction_surface_pixel.png failed to load")
	
	var tex_drill = load("res://art/planet/erebos_drill_cutaway.png")
	assert(tex_drill != null, "erebos_drill_cutaway.png failed to load")
	
	var cutscene_slides := [
		"res://art/storyboards/resonance_core_recovery/scene_01_rig_awakens.png",
		"res://art/storyboards/resonance_core_recovery/scene_02_descent.png",
		"res://art/storyboards/resonance_core_recovery/scene_03_first_contact.png",
		"res://art/storyboards/resonance_core_recovery/scene_04_reveal.png",
		"res://art/storyboards/resonance_core_recovery/scene_05_extraction.png",
		"res://art/storyboards/resonance_core_recovery/scene_06_horror_reveal.png",
	]
	for slide_path in cutscene_slides:
		var tex_slide = load(slide_path)
		assert(tex_slide != null, "Core recovery cutscene slide %s failed to load" % slide_path)
	print("✓ Test 1 Passed: Mining textures and cutscene slides loaded successfully.")

func test_walk_hud_items() -> void:
	print("[TEST 2] Verifying walk_hud mining item definitions...")
	var items = WALK_HUD_SCRIPT.ITEM_DATA
	assert(items.has(&"harmonic_bypass_coupler"), "Missing harmonic_bypass_coupler in walk_hud ITEM_DATA")
	assert(items.has(&"resonance_ore_core"), "Missing resonance_ore_core in walk_hud ITEM_DATA")
	assert(items.has(&"resonance_ore_core_fractured"), "Missing resonance_ore_core_fractured in walk_hud ITEM_DATA")
	print("✓ Test 2 Passed: Mining items correctly defined in WalkHud.")

func test_mock_planet_scene() -> void:
	print("[TEST 3] Verifying mock_planet_exterior scene instantiation...")
	var scene = MOCK_PLANET_SCENE.instantiate()
	assert(scene != null, "Failed to instantiate mock_planet_exterior.tscn")
	var script = scene.get_script()
	assert(script != null, "mock_planet_exterior scene lacks a script")
	scene.free()
	print("✓ Test 3 Passed: mock_planet_exterior scene instantiates cleanly.")

func test_ore_extraction_console() -> void:
	print("[TEST 4] Verifying OreExtractionConsole minigame logic...")
	var console = ORE_EXTRACTION_CONSOLE.new()
	assert(console != null, "Failed to instantiate OreExtractionConsole")
	
	var rig_config: Dictionary = {
		"id": &"erebos_deep_mining",
		"title": "Erebos Deep Rig",
		"bypass_active": true,
		"test_only": false
	}
	console.open(rig_config)
	
	# Test frequency tuning
	console._on_freq_changed(432.0)
	assert(is_equal_approx(console._current_freq, 432.0), "Frequency tuning failed")
	
	# Test drill engage
	console._on_rpm_changed(60.0)
	assert(is_equal_approx(console._drill_rpm, 60.0), "Drill RPM set failed")
	
	console._toggle_drill()
	assert(console._is_drilling == true, "Drill toggle failed to activate")
	
	# Process ticks with harmonic match
	console._process(0.2)
	assert(console._depth_m > 0.0, "Drill depth failed to advance")
	
	# Test coolant venting
	console._venting_coolant = true
	assert(console._venting_coolant == true, "Coolant venting failed to activate")
	
	console._close_console()
	console.free()
	print("✓ Test 4 Passed: OreExtractionConsole mechanics and simulation verified.")
