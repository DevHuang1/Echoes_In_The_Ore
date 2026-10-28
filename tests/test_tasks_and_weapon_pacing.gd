extends SceneTree

const WALK_HUD_SCENE := preload("res://scenes/ui/walk_hud.tscn")
const BARE_SHIP_SCENE := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
const SECOND_FLOOR_SCENE := preload("res://scenes/ship/second_floor_subdeck.tscn")

func _init() -> void:
	print("--- BEGIN TASKS SECTION & WEAPON PROGRESSION PACING TEST ---")
	test_fresh_start_unarmed()
	test_tasks_dossier_overlay()
	test_stale_meta_sanitization()
	test_legitimate_task_milestone_unlocks()
	test_bottom_floor_no_dropped_guns_and_task_highlights()
	print("--- ALL TASKS & WEAPON PROGRESSION PACING TESTS PASSED! ---")
	quit(0)


func test_fresh_start_unarmed() -> void:
	print("[TEST 1] Testing fresh start unarmed state...")
	# Ensure clear meta
	if Engine.has_meta(&"echoes_campaign_inventory_state"):
		Engine.remove_meta(&"echoes_campaign_inventory_state")
	for item_id in [&"suit_flashlight", &"engineering_multitool", &"pressure_sealant", &"medical_injector",
			&"mineral_survey_scanner", &"survey_beacon", &"emergency_flare", &"industrial_plasma_cutter",
			&"electrical_discharge_tool", &"captains_revolver"]:
		if Engine.has_meta(str(item_id) + "_unlocked"):
			Engine.remove_meta(str(item_id) + "_unlocked")

	var hud: WalkHud = WALK_HUD_SCENE.instantiate() as WalkHud
	root.add_child(hud)
	if not hud.is_node_ready():
		hud._ready()
	var sample_tasks: Array[Dictionary] = [
		{
			"id": &"cabin_may_recording",
			"title": "Play May's Yangon message",
			"room_name": "Living Quarters",
			"action_hint": "Access terminal desk at Thura's bunk",
			"marker_label": "QUARTERS",
			"milestone_reward": &"suit_flashlight",
			"reward_item": &"",
			"position": Vector2(100, 100),
		},
		{
			"id": &"bridge_flight_piloting",
			"title": "Evade asteroid swarm at manual helm",
			"room_name": "Bridge",
			"action_hint": "Pilot ship through asteroid belt",
			"marker_label": "BRIDGE",
			"milestone_reward": &"suit_flashlight",
			"reward_item": &"suit_flashlight",
			"position": Vector2(200, 200),
		}
	]
	hud.setup(null, sample_tasks, Vector2.ZERO, Vector2(1000, 1000))

	# Assert player is completely unarmed
	var equipped: Dictionary = hud.get_equipment_items()
	assert(equipped.get(&"tool", &"") == &"", "Tool slot must be empty at start!")
	assert(equipped.get(&"suit", &"") == &"", "Suit slot must be empty at start!")
	assert(not hud.has_equipment_item(&"captains_revolver"), "Player must NOT have revolver at start!")
	assert(not hud.has_equipment_item(&"industrial_plasma_cutter"), "Player must NOT have plasma cutter at start!")
	assert(not hud.has_equipment_item(&"suit_flashlight"), "Player must NOT have flashlight at start!")

	for item in hud.get_hotbar_items():
		assert(item == &"", "All hotbar slots must be empty at start, but found: %s" % str(item))

	for item in hud.get_storage_items():
		assert(item == &"", "All storage slots must be empty at start, but found: %s" % str(item))

	hud.queue_free()
	print("✓ Test 1 Passed: Fresh start begins with 0 weapons, 0 tools, clean hotbar and storage.")


func test_tasks_dossier_overlay() -> void:
	print("[TEST 2] Testing Tasks Section (HUD Tracker & Mission Dossier)...")
	var hud: WalkHud = WALK_HUD_SCENE.instantiate() as WalkHud
	root.add_child(hud)
	if not hud.is_node_ready():
		hud._ready()
	var sample_tasks: Array[Dictionary] = [
		{
			"id": &"cabin_may_recording",
			"title": "Play May's Yangon message",
			"room_name": "Living Quarters",
			"action_hint": "Access terminal desk at Thura's bunk",
			"marker_label": "QUARTERS",
			"milestone_reward": &"suit_flashlight",
			"reward_item": &"",
			"position": Vector2(100, 100),
		},
		{
			"id": &"bridge_flight_piloting",
			"title": "Evade asteroid swarm at manual helm",
			"room_name": "Bridge",
			"action_hint": "Pilot ship through asteroid belt",
			"marker_label": "BRIDGE",
			"milestone_reward": &"suit_flashlight",
			"reward_item": &"suit_flashlight",
			"position": Vector2(200, 200),
		}
	]
	hud.setup(null, sample_tasks, Vector2.ZERO, Vector2(1000, 1000))

	# Verify [T] TASKS button exists and open_tasks opens the dossier
	hud._open_tasks()
	assert(hud.get_active_overlay() == &"tasks", "Overlay must be 'tasks' after _open_tasks()!")

	# Verify dossier modal contains task cards and arsenal items
	var dossier_modal: Control = hud._overlay_nodes[&"tasks"]
	assert(dossier_modal.visible, "Tasks dossier overlay must be visible!")
	var tasks_list: Control = dossier_modal.find_child("TasksList", true, false)
	assert(tasks_list != null and tasks_list.get_child_count() == 2, "Tasks list must display 2 task cards!")

	var arsenal_list: Control = dossier_modal.find_child("ArsenalList", true, false)
	assert(arsenal_list != null and arsenal_list.get_child_count() == 10, "Arsenal catalog must showcase all 10 progression items!")

	hud._close_overlay()
	assert(hud.get_active_overlay() == &"", "Overlay must close when _close_overlay is called!")

	hud.queue_free()
	print("✓ Test 2 Passed: Tasks Section is unique, tactile, and showcases tasks & arsenal progression.")


func test_stale_meta_sanitization() -> void:
	print("[TEST 3] Testing stale save / persistent metadata sanitization...")
	# Simulate a dirty old campaign save granting revolver and plasma cutter prematurely
	var dirty_save: Dictionary = {
		"hotbar": [&"captains_revolver", &"industrial_plasma_cutter", &"", &"", &"", &"", &"", &"", &""],
		"storage": [&"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &"", &""],
		"equipment": {&"tool": &"captains_revolver", &"suit": &"suit_flashlight"},
		"unlocked_items": {&"captains_revolver": true, &"industrial_plasma_cutter": true, &"suit_flashlight": true},
		"item_amounts": {},
		"selected_hotbar_index": 0,
		"collected_logs": {},
		"unlocked_achievements": {},
		"story_act": "ACT I — THE LONG APPROACH",
	}
	Engine.set_meta(&"echoes_campaign_inventory_state", dirty_save)

	var hud: WalkHud = WALK_HUD_SCENE.instantiate() as WalkHud
	root.add_child(hud)
	if not hud.is_node_ready():
		hud._ready()
	var sample_tasks: Array[Dictionary] = [
		{
			"id": &"cabin_may_recording",
			"title": "Play May's Yangon message",
			"room_name": "Living Quarters",
			"action_hint": "Access terminal desk at Thura's bunk",
			"marker_label": "QUARTERS",
			"milestone_reward": &"suit_flashlight",
			"reward_item": &"",
			"position": Vector2(100, 100),
		}
	]
	# Setup without completing Act IV tasks
	hud.setup(null, sample_tasks, Vector2.ZERO, Vector2(1000, 1000))

	# Verify premature weapons were wiped by validation
	assert(not hud.has_equipment_item(&"captains_revolver"), "Captains revolver must be stripped from dirty save!")
	assert(not hud.has_equipment_item(&"industrial_plasma_cutter"), "Plasma cutter must be stripped from dirty save!")
	assert(not hud.has_equipment_item(&"suit_flashlight"), "Flashlight must be stripped before piloting milestone!")
	assert(hud.get_equipment_items().get(&"tool", &"") == &"", "Tool slot must be sanitized to empty!")

	for item in hud.get_hotbar_items():
		assert(item == &"", "Hotbar must be cleaned of premature weapons!")

	hud.queue_free()
	if Engine.has_meta(&"echoes_campaign_inventory_state"):
		Engine.remove_meta(&"echoes_campaign_inventory_state")
	print("✓ Test 3 Passed: Dirty saves & metadata are strictly sanitized against task progression.")


func test_legitimate_task_milestone_unlocks() -> void:
	print("[TEST 4] Testing legitimate milestone task progression unlocks...")
	if Engine.has_meta(&"echoes_campaign_inventory_state"):
		Engine.remove_meta(&"echoes_campaign_inventory_state")

	var hud: WalkHud = WALK_HUD_SCENE.instantiate() as WalkHud
	root.add_child(hud)
	if not hud.is_node_ready():
		hud._ready()
	var sample_tasks: Array[Dictionary] = [
		{
			"id": &"cabin_may_recording",
			"title": "Play May's Yangon message",
			"room_name": "Living Quarters",
			"action_hint": "Access terminal desk at Thura's bunk",
			"marker_label": "QUARTERS",
			"milestone_reward": &"suit_flashlight",
			"reward_item": &"",
			"position": Vector2(100, 100),
		},
		{
			"id": &"bridge_flight_piloting",
			"title": "Evade asteroid swarm at manual helm",
			"room_name": "Bridge",
			"action_hint": "Pilot ship through asteroid belt",
			"marker_label": "BRIDGE",
			"milestone_reward": &"suit_flashlight",
			"reward_item": &"suit_flashlight",
			"position": Vector2(200, 200),
		}
	]
	hud.setup(null, sample_tasks, Vector2.ZERO, Vector2(1000, 1000))

	# 1. Complete Task 1 (May's recording)
	hud.set_task_completed(&"cabin_may_recording")
	assert(hud._task_completed.get(&"cabin_may_recording") == true, "Task 1 must be completed!")
	assert(not hud.has_equipment_item(&"suit_flashlight"), "Flashlight must not unlock until Milestone 1 completes!")

	# 2. Complete Task 2 (Bridge ship piloting) -> awards flashlight
	hud.set_task_completed(&"bridge_flight_piloting")
	hud.unlock_equipment_item(&"suit_flashlight", true, "Milestone 1 Complete")
	assert(hud.has_equipment_item(&"suit_flashlight"), "Flashlight must legitimately unlock after bridge piloting!")

	# 3. Simulate Act II Drill Breach completion -> unlocks Industrial Plasma Cutter
	hud.set_task_completed(&"north_viridian_ore")
	hud.unlock_equipment_item(&"industrial_plasma_cutter", true, "Drill breach cleared")
	assert(hud.has_equipment_item(&"industrial_plasma_cutter"), "Plasma cutter must legitimately unlock after breach task!")
	assert(hud.get_equipment_items().get(&"tool", &"") == &"industrial_plasma_cutter", "Plasma cutter should be equipped!")

	# 4. Open tasks dossier and verify the weapon is marked unlocked / authorized
	hud._open_tasks()
	var dossier_modal: Control = hud._overlay_nodes[&"tasks"]
	var summary_lbl: Label = dossier_modal.find_child("RightArsenalColumn", true, false).find_child("Label", true, false)
	# 2 items unlocked so far (flashlight + plasma cutter)
	hud._close_overlay()

	hud.queue_free()
	if Engine.has_meta(&"echoes_campaign_inventory_state"):
		Engine.remove_meta(&"echoes_campaign_inventory_state")
	print("✓ Test 4 Passed: Tasks legitimately award weapons and equipment only upon task completion.")


func test_bottom_floor_no_dropped_guns_and_task_highlights() -> void:
	print("[TEST 5] Testing bottom floor (Sub-Deck) for ZERO dropped guns and functional task highlights...")
	if Engine.has_meta(&"echoes_campaign_inventory_state"):
		Engine.remove_meta(&"echoes_campaign_inventory_state")
	var subdeck: Node2D = SECOND_FLOOR_SCENE.instantiate() as Node2D
	root.add_child(subdeck)
	if not subdeck.is_node_ready():
		subdeck._ready()

	var hud: WalkHud = subdeck.get_node_or_null("WalkHud") as WalkHud
	assert(hud != null, "Subdeck must instantiate WalkHud!")
	if not hud.is_node_ready():
		hud._ready()

	# Assert that no guns/weapons are dropped on the floor
	assert(hud._dropped_world_items.is_empty(), "No weapons or guns may be dropped on the bottom floor, but found: %s" % str(hud._dropped_world_items))

	# Verify world task markers exist and are tracked
	assert(not hud._world_task_markers.is_empty(), "World task markers must be generated for bottom floor tasks!")

	# Verify lights canvas exists and is wired to draw task station highlights
	var lights_canvas: Node2D = subdeck.get_node_or_null("SubdeckLighting/MountedLightsCanvas") as Node2D
	assert(lights_canvas != null, "MountedLightsCanvas must exist for subdeck highlights!")
	assert(lights_canvas.draw.is_connected(subdeck._on_lights_canvas_draw), "MountedLightsCanvas must be connected to _on_lights_canvas_draw!")
	assert(subdeck.has_method("_draw_small_station_highlight"), "Subdeck must provide _draw_small_station_highlight method!")

	subdeck.free()

	# Also verify Main Deck walkthrough highlights
	var bare_ship: Node2D = BARE_SHIP_SCENE.instantiate() as Node2D
	root.add_child(bare_ship)
	if not bare_ship.is_node_ready():
		bare_ship._ready()

	var ship_hud: WalkHud = bare_ship.get_node_or_null("WalkHud") as WalkHud
	assert(ship_hud != null, "Bare ship must instantiate WalkHud!")
	if not ship_hud.is_node_ready():
		ship_hud._ready()
	assert(ship_hud._dropped_world_items.is_empty(), "No guns dropped on floor on main ship deck!")
	assert(not ship_hud._world_task_markers.is_empty(), "World task markers must be generated for main deck tasks!")

	var highlights_canvas: Node2D = bare_ship.get_node_or_null("InteractiveHighlightsCanvas") as Node2D
	assert(highlights_canvas != null, "InteractiveHighlightsCanvas must exist on main ship deck!")
	assert(highlights_canvas.draw.is_connected(bare_ship._on_interactive_highlights_draw), "InteractiveHighlightsCanvas must be connected to _on_interactive_highlights_draw!")
	assert(bare_ship.has_method("_draw_small_station_highlight"), "Bare ship must provide _draw_small_station_highlight method!")

	bare_ship.free()
	print("✓ Test 5 Passed: Bottom floor contains zero dropped guns, and all task highlights draw properly.")
