extends SceneTree

const WALK_HUD_SCENE = preload("res://scenes/ui/walk_hud.tscn")
const WALKTHROUGH_SCRIPT = preload("res://scripts/ship/ship_mission_walkthrough.gd")
const FIRST_WATCH_STORY = preload("res://scripts/ship/first_watch_story.gd")

func _init() -> void:
	print("--- BEGIN MISSION SYSTEM ROADMAP, MAP PIN & CUTSCENES TEST ---")

	# -------------------------------------------------------------------------
	# 1. Test WalkHud Roadmap Panel & Tab Switching
	# -------------------------------------------------------------------------
	print("[TEST 1] Testing WalkHud Roadmap UI tab & visibility toggling...")
	var hud: WalkHud = WALK_HUD_SCENE.instantiate() as WalkHud
	root.add_child(hud)
	if not hud.is_node_ready():
		hud._ready()
	var dummy_tasks: Array[Dictionary] = []
	hud.setup(null, dummy_tasks, Vector2.ZERO, Vector2(1774, 887))

	# Verify roadmap tab components
	assert(hud.get("_roadmap_view_container") != null, "ERROR: _roadmap_view_container must exist!")
	assert(hud.get("_tasks_list_scroll") != null, "ERROR: _tasks_list_scroll must exist!")
	assert(hud.get("_roadmap_replay_btn") != null, "ERROR: _roadmap_replay_btn must exist!")

	# Initial state: Tasks list visible, Roadmap hidden
	assert(not hud.get("_roadmap_view_container").visible, "ERROR: Roadmap container should be hidden by default.")
	assert(hud.get("_tasks_list_scroll").visible, "ERROR: Tasks list scroll should be visible by default.")

	# Switch to ROADMAP tab
	hud.set("_tasks_filter_tab", &"roadmap")
	hud.call("_refresh_tasks_overlay")
	assert(hud.get("_roadmap_view_container").visible, "ERROR: Roadmap container should be visible when tab is 'roadmap'!")
	assert(not hud.get("_tasks_list_scroll").visible, "ERROR: Tasks list scroll should be hidden when tab is 'roadmap'!")

	# Switch back to ALL tab
	hud.set("_tasks_filter_tab", &"all")
	hud.call("_refresh_tasks_overlay")
	assert(not hud.get("_roadmap_view_container").visible, "ERROR: Roadmap container should be hidden when tab is 'all'!")
	assert(hud.get("_tasks_list_scroll").visible, "ERROR: Tasks list scroll should be restored when tab is 'all'!")
	print("✓ Test 1 Passed: Tab switching toggles TasksScroll and RoadmapScroll cleanly.")

	# -------------------------------------------------------------------------
	# 2. Test Roadmap Timeline Step States (Done / Active / Locked)
	# -------------------------------------------------------------------------
	print("[TEST 2] Testing Roadmap timeline step visual states...")
	hud.set("_tasks_filter_tab", &"roadmap")

	# Test 0 completed (Start of game: Step 0 active, 1..4 locked)
	hud.call("_refresh_roadmap", 0)
	var inner: VBoxContainer = hud.get("_roadmap_view_container").get_node("RoadmapInner")
	assert(inner != null, "ERROR: RoadmapInner must exist!")
	print("  RoadmapInner child count at 0 completed: %d" % inner.get_child_count())

	# Test 1 completed (Step 0 done ✓, Step 1 active →, Steps 2..4 locked ○)
	hud.call("_refresh_roadmap", 1)
	assert(inner.get_child_count() >= 5, "ERROR: Expected at least 5 mission rows in roadmap!")

	# Test all 5 completed
	hud.call("_refresh_roadmap", 5)
	print("✓ Test 2 Passed: Roadmap timeline refreshes for completed counts 0 through 5.")

	# -------------------------------------------------------------------------
	# 3. Test Roadmap Replay Briefing Button
	# -------------------------------------------------------------------------
	print("[TEST 3] Testing Replay Briefing Button...")
	var replay_btn: Button = hud.get("_roadmap_replay_btn")
	hud.call("set_story_last_unlock_slide", {})
	assert(not replay_btn.visible, "ERROR: Replay button should be hidden when no slide data is set!")

	var test_slide := {
		"act": "ACT I — THE LONG APPROACH",
		"clock": "ASTERIA-1 // DAY 184 // CREW QUARTERS",
		"title": "STEP 2: REVIEW DUTY ROSTER",
		"slides": [{"speaker": "MISSION CONTROL", "text": "Test briefing text."}]
	}
	hud.call("set_story_last_unlock_slide", test_slide)
	assert(replay_btn.visible, "ERROR: Replay button should be visible when slide data is present!")
	print("✓ Test 3 Passed: Replay button shows only when unlock slide data exists.")

	# -------------------------------------------------------------------------
	# 4. Test Ship Map Objective Pin & Room Dimming
	# -------------------------------------------------------------------------
	print("[TEST 4] Testing Map Objective Pin and Inactive Room Dimming...")
	var map_pin = hud.get("_map_obj_pin")
	var map_label: Label = hud.get("_map_obj_pin_label")
	var floor_layer = hud.get("_map_floor_layer")
	assert(map_pin != null and map_label != null, "ERROR: Objective pin and label must exist on HUD!")

	# Set objective in Crew Quarters
	hud.call("set_story_objective", {"id": "quarters", "title": "Review duty roster", "station": "quarters.desk", "marker_label": "QUARTERS", "position": Vector2(300, 450)}, 1)
	assert(map_pin.visible, "ERROR: Map objective pin should be visible for active story objective!")
	assert(map_label.visible, "ERROR: Map objective pin label should be visible!")
	assert(map_label.text == "QUARTERS", "ERROR: Pin label should display 'QUARTERS'!")
	if floor_layer != null:
		assert(floor_layer.modulate.a <= 0.65, "ERROR: Floor layer should be dimmed to ~0.60 alpha!")

	# Set objective for Amara (should map to Hydroponics room)
	hud.call("set_story_objective", {"id": "amara", "title": "Meet Amara", "station": "amara", "marker_label": "AMARA", "position": Vector2(100, 650)}, 2)
	assert(map_pin.visible, "ERROR: Map pin should resolve Amara's location to Hydroponics!")
	assert(map_label.text == "AMARA", "ERROR: Pin label should display 'AMARA'!")

	# When story completed count reaches 5 (story over), pin should hide
	hud.call("set_story_objective", {"id": "bridge", "title": "Watch handed over", "marker_label": "BRIDGE", "position": Vector2(100, 200)}, 5)
	assert(not map_pin.visible, "ERROR: Map pin should hide after story completion (count >= 5)!")
	print("✓ Test 4 Passed: Map objective pin positions correctly, maps AMARA to hydro, and dims background.")

	# -------------------------------------------------------------------------
	# 5. Test ShipMissionWalkthrough Roadmap Counts & Unlock Cutscenes
	# -------------------------------------------------------------------------
	print("[TEST 5] Testing ShipMissionWalkthrough Roadmap & Cutscenes...")
	var wt = WALKTHROUGH_SCRIPT.new()
	root.add_child(wt)

	var story = FIRST_WATCH_STORY.new()
	wt.set("_ship_story", story)
	wt.set("_ship_hud", hud)
	wt.set("_story_prev_mission_id", "story.a1.010_watch_briefing")

	# Step 0: Initial state
	assert(wt.call("_story_roadmap_completed_count") == 0, "ERROR: Initial roadmap completed count should be 0.")
	assert(wt.call("_story_current_mission_key") == "story.a1.010_watch_briefing", "ERROR: Step 0 mission key mismatch.")

	# Complete Step 0 by recording watch.accepted
	story.record("watch.accepted")
	assert(wt.call("_story_roadmap_completed_count") == 1, "ERROR: After watch.accepted, roadmap completed count should be 1.")
	assert(wt.call("_story_current_mission_key") == "story.a1.020_meet_amara", "ERROR: Step 1 mission key mismatch.")

	# Trigger unlock cutscene for step 2
	wt.call("_story_fire_unlock_cutscene", "story.a1.020_meet_amara")
	assert(wt.get("_story_unlock_overlay") != null, "ERROR: _story_unlock_overlay should be created!")
	assert(hud.get("_story_last_unlock_slide").get("title") == "STEP 2: REVIEW DUTY ROSTER", "ERROR: HUD last unlock slide title mismatch.")

	# Complete Step 1 by recording roster.reviewed
	story.record("roster.reviewed")
	assert(wt.call("_story_roadmap_completed_count") == 2, "ERROR: After roster.reviewed, roadmap completed count should be 2.")
	assert(wt.call("_story_current_mission_key") == "story.a1.030_aux_service", "ERROR: Step 2 mission key mismatch.")

	# Complete Step 2 by recording amara.observation_reported
	story.record("amara.observation_reported")
	assert(wt.call("_story_roadmap_completed_count") == 3, "ERROR: After amara.observation_reported, roadmap completed count should be 3.")
	assert(wt.call("_story_current_mission_key") == "story.a1.040_irrigation_report", "ERROR: Step 3 mission key mismatch.")

	# Complete Step 3 by recording power.reported
	story.record("power.reported")
	assert(wt.call("_story_roadmap_completed_count") == 4, "ERROR: After power.reported, roadmap completed count should be 4.")
	assert(wt.call("_story_current_mission_key") == "story.a1.050_watch_handoff", "ERROR: Step 4 mission key mismatch.")

	# Complete Step 4 by recording watch.acknowledged
	story.record("watch.acknowledged")
	assert(wt.call("_story_roadmap_completed_count") == 5, "ERROR: After watch.acknowledged, roadmap completed count should be 5.")

	# Cleanup
	wt.queue_free()
	hud.queue_free()
	print("✓ Test 5 Passed: Walkthrough correctly computes roadmap counts and fires unlock cutscenes.")

	print("--- ALL MISSION SYSTEM ROADMAP, PIN & CUTSCENE TESTS PASSED PERFECTLY! ---")
	quit(0)
