extends SceneTree

const WALK_HUD_SCRIPT = preload("res://scripts/ui/walk_hud.gd")

func _init() -> void:
	print("--- BEGIN PROGRESSION & PACING VERIFICATION ---")

	# 1. Fresh Start Verification
	if Engine.has_meta(&"echoes_campaign_inventory_state"):
		Engine.remove_meta(&"echoes_campaign_inventory_state")
	if Engine.has_meta(&"echoes_story_progression_state"):
		Engine.remove_meta(&"echoes_story_progression_state")

	var hud = WALK_HUD_SCRIPT.new()
	var dummy_tasks: Array[Dictionary] = []
	hud.setup(null, dummy_tasks, Vector2.ZERO, Vector2(1000, 1000))

	assert(hud.get_unlocked_equipment_count() == 0, "ERROR: Fresh game should have 0 unlocked equipment!")
	assert(not hud.has_equipment_item(&"suit_flashlight"), "ERROR: Flashlight should be locked at start!")
	assert(not hud.has_equipment_item(&"captains_revolver"), "ERROR: Revolver should not be given at start!")
	assert(not hud.has_equipment_item(&"industrial_plasma_cutter"), "ERROR: Plasma cutter should not be given at start!")
	assert(not hud.has_equipment_item(&"electrical_discharge_tool"), "ERROR: Arc tool should not be given at start!")
	print("✓ Test 1 Passed: Fresh start begins with 0 weapons, 0 equipment, flashlight locked.")

	# 2. Act I Utility Unlocks
	hud.unlock_equipment_item(&"suit_flashlight", true, "Milestone 1")
	assert(hud.has_equipment_item(&"suit_flashlight"), "ERROR: Flashlight should be unlocked.")
	assert(not hud.has_equipment_item(&"captains_revolver"), "ERROR: Weapons must not be in Act I.")

	hud.unlock_equipment_item(&"engineering_multitool", true, "Milestone 2")
	hud.unlock_equipment_item(&"pressure_sealant", false, "Milestone 3")
	hud.unlock_equipment_item(&"mineral_survey_scanner", true, "Milestone 3")
	hud.unlock_equipment_item(&"survey_beacon", true, "Milestone 4")

	assert(hud.get_unlocked_equipment_count() == 5, "ERROR: Expected 5 utility items in Act I.")
	assert(not hud.has_equipment_item(&"industrial_plasma_cutter"), "ERROR: Plasma cutter must not be unlocked in Act I.")
	assert(not hud.has_equipment_item(&"electrical_discharge_tool"), "ERROR: Discharge tool must not be unlocked in Act I.")
	assert(not hud.has_equipment_item(&"medical_injector"), "ERROR: Medical injector must not be unlocked in Act I.")
	print("✓ Test 2 Passed: Act I awards strictly 5 utility items (Flashlight, Multitool, Sealant, Scanner, Beacon). No weapons.")

	# 3. Act II Surface Breach (First Weapon)
	hud.unlock_equipment_item(&"emergency_flare", false, "Erebos Surface")
	hud.unlock_equipment_item(&"industrial_plasma_cutter", true, "Erebos Drill Breach")
	assert(hud.has_equipment_item(&"industrial_plasma_cutter"), "ERROR: Ruiz's plasma cutter should be unlocked at drill breach.")
	assert(hud.has_equipment_item(&"emergency_flare"), "ERROR: Emergency flare should be unlocked.")
	assert(not hud.has_equipment_item(&"electrical_discharge_tool"), "ERROR: Arc tool must not be unlocked in Act II.")
	assert(not hud.has_equipment_item(&"captains_revolver"), "ERROR: Revolver must not be unlocked in Act II.")
	print("✓ Test 3 Passed: Act II unlocks Ruiz's Industrial Plasma Cutter as First Weapon beside the drill breach.")

	# 4. Act III Lab Outbreak (Second Weapon + Medical Injector)
	hud.unlock_equipment_item(&"electrical_discharge_tool", true, "Lab Outbreak Specimen Bench")
	hud.unlock_equipment_item(&"medical_injector", true, "Lab Outbreak Overturned Med-Cart")
	hud.record_audio_log(&"log_okoye_containment_breach")
	assert(hud.has_equipment_item(&"electrical_discharge_tool"), "ERROR: Arc discharge tool should be salvaged from lab.")
	assert(hud.has_equipment_item(&"medical_injector"), "ERROR: Medical injector should be salvaged from lab.")
	assert(not hud.has_equipment_item(&"captains_revolver"), "ERROR: Revolver must not be unlocked in Act III.")
	print("✓ Test 4 Passed: Act III unlocks Electrical Discharge Tool & Medical Injector in breached Lab room.")

	# 5. Act IV Climax (Captain's Revolver)
	hud.unlock_equipment_item(&"captains_revolver", true, "Commander Chen Quarantine Hand-off")
	hud.record_audio_log(&"log_chen_farewell")
	assert(hud.has_equipment_item(&"captains_revolver"), "ERROR: Captain's revolver should be unlocked in Act IV.")
	assert(hud.get_unlocked_equipment_count() == 10, "ERROR: Expected all 10 progression items unlocked at end.")
	print("✓ Test 5 Passed: Act IV unlocks Captain's Revolver in tragic quarantine hand-off.")

	# 6. Audio Logs Catalog & PDA System
	var logs_catalog: Array = WALK_HUD_SCRIPT.AUDIO_LOGS_CATALOG
	assert(logs_catalog.size() == 8, "ERROR: Expected 8 audio logs in catalog, got %d" % logs_catalog.size())
	for log_def in logs_catalog:
		assert(log_def.has("id"), "ERROR: Log must have id")
		assert(log_def.has("title"), "ERROR: Log must have title")
		assert(log_def.has("speaker"), "ERROR: Log must have speaker")
		assert(log_def.has("location"), "ERROR: Log must have location")
		assert(log_def.has("transcript"), "ERROR: Log must have transcript")
		assert(str(log_def["transcript"]).length() > 20, "ERROR: Transcript should be substantive")
	print("✓ Test 6 Passed: All 8 storyline audio logs verified with full transcripts, speakers, and locations.")

	hud.free()
	print("--- ALL PROGRESSION & PACING TESTS PASSED PERFECTLY! ---")
	quit(0)
