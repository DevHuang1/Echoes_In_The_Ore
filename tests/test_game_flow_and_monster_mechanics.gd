extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const VILLAIN_SCENE := preload("res://scenes/ship/crew/resonance_ore_villain.tscn")
const LIGHTING_SCENE := preload("res://scenes/ship/props/ship_room_lighting.tscn")
const SERVICE_CONSOLE_SCENE := preload("res://scenes/ui/service_task_console.tscn")

func _init() -> void:
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	print("\n--- BEGIN TEST: GAME FLOW, MONSTER MECHANICS & DYNAMIC LIGHTING ---")
	
	_test_flashlight_battery()
	_test_room_lighting_breakers()
	_test_monster_sensory_and_light_reactions()
	_test_flare_safe_zone_protection()
	_test_system_milestone_mutations()
	_test_struggle_escape_and_console_bailout()
	
	print("--- ALL GAME FLOW & MONSTER MECHANICS TESTS PASSED SUCCESSFULLY! ---\n")
	quit(0)

func _test_flashlight_battery() -> void:
	print("[TEST 1] Testing Flashlight Battery Drain & Recharge...")
	var player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	
	player.set_suit_flashlight_unlocked(true)
	player.set_suit_flashlight_enabled(true)
	assert(player.is_suit_flashlight_enabled(), "Flashlight should be enabled.")
	assert(player.get_flashlight_battery() == 100.0, "Initial battery should be 100%.")
	
	# Simulate 10 seconds of battery drain
	player._physics_process(10.0)
	var drained_battery = player.get_flashlight_battery()
	assert(drained_battery <= 90.0, "Battery should have drained by at least 10%. Current: " + str(drained_battery))
	
	# Recharge battery
	player.recharge_flashlight_battery(50.0)
	assert(player.get_flashlight_battery() > drained_battery, "Battery should be recharged.")
	
	# Drain completely
	player._physics_process(120.0)
	assert(player.get_flashlight_battery() == 0.0, "Battery should be 0.")
	assert(not player.is_suit_flashlight_enabled(), "Flashlight should automatically shut off when battery is 0.")
	
	# Cannot turn on with 0 battery
	player.set_suit_flashlight_enabled(true)
	assert(not player.is_suit_flashlight_enabled(), "Flashlight cannot turn on with 0 battery.")
	
	player.free()
	print("✓ Test 1 Passed: Flashlight battery drains, turns off at 0%, and recharges properly.")

func _test_room_lighting_breakers() -> void:
	print("[TEST 2] Testing Ship Power Grid Circuit Breakers...")
	var lighting = LIGHTING_SCENE.instantiate()
	root.add_child(lighting)
	
	lighting.set_emergency_breaker_mode(true)
	assert(lighting.is_emergency_breaker_mode(), "Emergency breaker mode should be active.")
	lighting.set_max_power_units(2)
	assert(lighting.get_max_power_units() == 2, "Max power units should be 2.")
	
	# Power 2 rooms
	var p1 = lighting.set_breaker_power(&"r04_power_maint", true)
	var p2 = lighting.set_breaker_power(&"r05_life_support", true)
	assert(p1 and p2, "Should successfully power rooms within budget.")
	assert(lighting.get_used_power_units() == 2, "Used units should be 2.")
	assert(lighting.is_breaker_powered(&"r04_power_maint"), "Power maint should be powered.")
	
	# Attempt to power 3rd room beyond budget
	var p3 = lighting.set_breaker_power(&"r06_hydroponics", true)
	assert(not p3, "Should reject powering beyond budget.")
	assert(not lighting.is_breaker_powered(&"r06_hydroponics"), "Hydroponics should remain unpowered.")
	
	# Free power and reroute
	lighting.set_breaker_power(&"r04_power_maint", false)
	assert(lighting.get_used_power_units() == 1, "Used units should drop to 1.")
	var p4 = lighting.set_breaker_power(&"r06_hydroponics", true)
	assert(p4, "Should successfully reroute power to Hydroponics.")
	assert(lighting.is_breaker_powered(&"r06_hydroponics"), "Hydroponics should now be powered.")
	
	lighting.free()
	print("✓ Test 2 Passed: Power breaker circuit budgeting, rerouting, and toggling verified.")

func _test_monster_sensory_and_light_reactions() -> void:
	print("[TEST 3] Testing Monster Multi-Sensory Perception (Flashlight vs. Sprint vs. Darkness)...")
	var player = PLAYER_SCENE.instantiate()
	var villain = VILLAIN_SCENE.instantiate()
	var lighting = LIGHTING_SCENE.instantiate()
	root.add_child(player)
	root.add_child(villain)
	root.add_child(lighting)
	
	player.global_position = Vector2(500.0, 500.0)
	villain.global_position = Vector2(740.0, 500.0) # 240 px away
	villain.wake_up()
	villain.set_physics_process(false)
	
	# Scenario A: Player standing still in dark (no sprint, no flashlight)
	lighting.set_emergency_breaker_mode(true)
	player.set_suit_flashlight_enabled(false)
	villain._check_player_stalking()
	assert(not villain._is_chasing, "Monster should NOT detect player at 240px in darkness while stationary.")
	
	# Scenario B: Player turns on flashlight at 240px
	player.set_suit_flashlight_unlocked(true)
	player.recharge_flashlight_battery(100.0)
	player.set_suit_flashlight_enabled(true)
	assert(player.is_suit_flashlight_enabled(), "Player flashlight should be on.")
	villain._check_player_stalking()
	assert(villain._is_chasing, "Monster SHOULD detect player at 240px when flashlight illuminates them.")
	
	# Scenario C: Flashlight off, but player sprints at 300px away
	player.set_suit_flashlight_enabled(false)
	villain.global_position = Vector2(800.0, 500.0) # 300 px away
	villain._is_chasing = false
	player._is_sprinting = true
	villain._check_player_stalking()
	assert(villain._is_chasing, "Monster SHOULD acoustically detect player at 300px when sprinting.")
	
	player.free()
	villain.free()
	lighting.free()
	print("✓ Test 3 Passed: Multi-sensory perception correctly weights flashlight beam, sprint noise, and darkness.")

func _test_flare_safe_zone_protection() -> void:
	print("[TEST 4] Testing High-Intensity Flare Safe Zone Barrier...")
	var player = PLAYER_SCENE.instantiate()
	var villain = VILLAIN_SCENE.instantiate()
	root.add_child(player)
	root.add_child(villain)
	
	player.global_position = Vector2(300.0, 300.0)
	villain.global_position = Vector2(350.0, 300.0) # 50 px away
	villain.wake_up()
	
	# Place active burning flare at (300, 300)
	player._burning_flares.append({
		"pos": player.global_position,
		"timer": 20.0,
		"max_timer": 20.0,
		"light": null,
		"seed": 1.0,
	})
	assert(player.is_position_in_flare_safe_zone(player.global_position), "Player should be inside flare safe zone.")
	
	# Check stalking: monster cannot chase player inside flare zone
	villain._check_player_stalking()
	assert(not villain._is_chasing, "Monster must not chase or enter active flare safe zone.")
	
	# Monster touching flare boundary gets repelled
	villain.global_position = player.global_position + Vector2(10.0, 0.0)
	villain._is_repelled = false
	villain._check_player_stalking()
	assert(villain._is_repelled, "Monster touching burning flare perimeter must be repelled.")
	
	player.free()
	villain.free()
	print("✓ Test 4 Passed: Flare safe circle protects player and repels hostile entity.")

func _test_system_milestone_mutations() -> void:
	print("[TEST 5] Testing System-Milestone Driven Mutations...")
	var villain = VILLAIN_SCENE.instantiate()
	root.add_child(villain)
	
	villain.set_form_stage(villain.FormStage.STAGE1_INFECTED, true)
	assert(villain.form_stage == villain.FormStage.STAGE1_INFECTED, "Should start at Stage 1 Fused Amara.")
	
	# Milestone 1: Auxiliary Power Grid Restored -> Mutate to Stage 2
	villain.on_system_milestone_completed(&"power_auxiliary")
	assert(villain.form_stage == villain.FormStage.STAGE2_MUTATED, "Should escalate to Stage 2 Mutated.")
	assert(villain.move_speed >= 96.0, "Speed should increase to Mutated level.")
	
	# Milestone 2: Life Support Airflow Restored -> Mutate to Final Form
	villain.on_system_milestone_completed(&"life_support")
	assert(villain.form_stage == villain.FormStage.STAGE3_FINAL_FORM, "Should escalate to Stage 3 Apex Final Form.")
	assert(villain.move_speed >= 105.0, "Speed should increase to Apex level.")
	
	villain.free()
	print("✓ Test 5 Passed: System restoration milestones correctly trigger entity form mutations.")

func _test_struggle_escape_and_console_bailout() -> void:
	print("[TEST 6] Testing Struggle Escape & Real-Time Console Bailout...")
	var player = PLAYER_SCENE.instantiate()
	var villain = VILLAIN_SCENE.instantiate()
	var console = SERVICE_CONSOLE_SCENE.instantiate()
	root.add_child(player)
	root.add_child(villain)
	root.add_child(console)
	
	console.setup(&"auxiliary_power", 0, 1)
	assert(console.is_in_group("service_task_console"), "Console should be registered in group.")
	
	# Zero out flares and survey beacons so struggle consumes medical injector
	player.set_equipment_amount(&"emergency_flare", 0)
	player.set_equipment_amount(&"survey_beacon", 0)
	player.set_equipment_amount(&"medical_injector", 2)
	assert(player.get_equipment_amount(&"medical_injector") == 2, "Should have 2 medical injectors.")
	
	# Monster attacks player
	villain._attack_player(player)
	assert(player.get_equipment_amount(&"medical_injector") == 1, "Struggle escape should consume 1 injector.")
	assert(villain._is_repelled, "Monster should be repelled upon struggle escape.")
	
	# Console proximity detection
	villain.global_position = player.global_position + Vector2(100.0, 0.0)
	villain._in_ducts = false
	villain.visible = true
	console._process(0.016)
	assert(console._proximity_alert_label != null and console._proximity_alert_label.visible, "Console should display proximity alert.")
	
	# Close console
	console._close_console()
	
	player.free()
	villain.free()
	console.free()
	print("✓ Test 6 Passed: Struggle escape consumes items to survive, and console alerts/bails out.")
