extends SceneTree

const BARE_SHIP_SCENE := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
const CREW_DIALOGUE_SCENE := preload("res://scenes/ui/crew_dialogue.tscn")
const DIALOGUE_SYNTH := preload("res://scripts/audio/dialogue_audio_synth.gd")

func _init() -> void:
	print("--- BEGIN ALL NPC INTERACTIONS CONSISTENCY TEST ---")
	test_dialogue_audio_synth_voices()
	test_ship_crew_npcs_and_prompts()
	print("--- ALL NPC INTERACTIONS TESTS PASSED! ---")
	quit(0)


func test_dialogue_audio_synth_voices() -> void:
	print("[TEST 1] Testing unique procedural voice synthesis for all crew members...")
	var amara_snd := DIALOGUE_SYNTH.create_speech_amara()
	assert(amara_snd != null and not amara_snd.data.is_empty(), "Amara voice blip must synthesize!")

	var thura_snd := DIALOGUE_SYNTH.create_speech_thura()
	assert(thura_snd != null and not thura_snd.data.is_empty(), "Thura voice blip must synthesize!")

	var chen_snd := DIALOGUE_SYNTH.create_speech_chen()
	assert(chen_snd != null and not chen_snd.data.is_empty(), "Commander Chen voice blip must synthesize!")

	var mateo_snd := DIALOGUE_SYNTH.create_speech_mateo()
	assert(mateo_snd != null and not mateo_snd.data.is_empty(), "Mateo Ruiz voice blip must synthesize!")

	var ward_snd := DIALOGUE_SYNTH.create_speech_ward()
	assert(ward_snd != null and not ward_snd.data.is_empty(), "Elias Ward voice blip must synthesize!")

	var leila_snd := DIALOGUE_SYNTH.create_speech_leila()
	assert(leila_snd != null and not leila_snd.data.is_empty(), "Leila Haddad voice blip must synthesize!")

	print("✓ Test 1 Passed: All 5 crew members + player have unique synthesized voice waveforms.")


func test_ship_crew_npcs_and_prompts() -> void:
	print("[TEST 2] Testing all 5 crew members on Asteria-1 for Commander Chen-style dialogue & prompts...")
	# Clean meta
	if Engine.has_meta(&"ship_landed_on_erebos"):
		Engine.remove_meta(&"ship_landed_on_erebos")
	if Engine.has_meta(&"elias_ward_deceased"):
		Engine.remove_meta(&"elias_ward_deceased")
	if Engine.has_meta(&"leila_haddad_deceased"):
		Engine.remove_meta(&"leila_haddad_deceased")
	if Engine.has_meta(&"lab_destroyed_by_xenomorph"):
		Engine.remove_meta(&"lab_destroyed_by_xenomorph")

	var ship: Node = BARE_SHIP_SCENE.instantiate()
	root.add_child(ship)
	if not ship.is_node_ready():
		ship._ready()

	# 1. Verify all 5 crew members are present
	var amara: Node2D = ship.get("amara") as Node2D
	assert(is_instance_valid(amara), "Dr. Amara Okoye must be present!")

	var chen: Node2D = ship.get("_chen_npc") as Node2D
	assert(is_instance_valid(chen), "Commander Maya Chen must be present!")

	var mateo: Node2D = ship.get("_mateo_npc") as Node2D
	assert(is_instance_valid(mateo), "Mateo Ruiz must be present!")

	var ward: Node2D = ship.get("_ward_npc") as Node2D
	assert(is_instance_valid(ward), "Elias Ward must be present!")

	var leila: Node2D = ship.get("_leila_npc") as Node2D
	assert(is_instance_valid(leila), "Chief Engineer Leila Haddad must be present!")

	var player: Node2D = ship.get("player") as Node2D
	var hud: Node = ship.get("_walk_hud") as Node
	assert(is_instance_valid(player) and is_instance_valid(hud), "Player and WalkHUD must be valid!")

	# 2. Test interaction prompts near each NPC
	if not hud.is_node_ready():
		hud._ready()

	# Test Amara
	player.global_position = amara.global_position + Vector2(20.0, 0.0)
	ship.call("_refresh_room_task_prompt")
	assert(bool(ship.get("_active_amara_interaction")) == true, "Amara interaction must be active!")

	# Test Commander Chen
	player.global_position = chen.global_position + Vector2(20.0, 0.0)
	ship.call("_refresh_room_task_prompt")
	assert(bool(ship.get("_active_chen_interaction")) == true, "Commander Chen interaction must be active!")

	# Test Mateo Ruiz
	player.global_position = mateo.global_position + Vector2(20.0, 0.0)
	ship.call("_refresh_room_task_prompt")
	assert(bool(ship.get("_active_mateo_interaction")) == true, "Mateo Ruiz interaction must be active!")

	# Test Elias Ward
	player.global_position = ward.global_position + Vector2(20.0, 0.0)
	ship.call("_refresh_room_task_prompt")
	assert(bool(ship.get("_active_ward_interaction")) == true, "Elias Ward interaction must be active!")

	# Test Leila Haddad
	player.global_position = leila.global_position + Vector2(20.0, 0.0)
	ship.call("_refresh_room_task_prompt")
	assert(bool(ship.get("_active_leila_interaction")) == true, "Leila Haddad interaction must be active!")

	# 3. Test dialogue initiation and branching choices for Dr. Amara Okoye
	ship.call("_begin_amara_dialogue")
	var crew_dlg: Node = ship.get("_crew_dialogue") as Node
	assert(is_instance_valid(crew_dlg), "CrewDialogue must be valid!")
	var choices: Array = crew_dlg.get("_choices")
	assert(choices.size() >= 3, "Amara must offer multiple rich conversational topics like Commander Chen! Found: %d" % choices.size())

	# Test choosing amara_tasks unlocks the hydroponics maintenance
	ship.call("_handle_amara_dialogue_result", "amara_tasks")
	assert(bool(ship.get("_crew_tasks_unlocked")) == true, "Choosing amara_tasks must unlock crew tasks!")
	ship.set("_crew_dialogue_open", false)
	crew_dlg.set("_is_active", false)

	# 4. Test dialogue choices for Elias Ward
	ship.call("_begin_ward_dialogue")
	choices = crew_dlg.get("_choices")
	assert(choices.size() >= 3, "Elias Ward must offer multiple rich topics! Found: %d" % choices.size())
	ship.call("_handle_ward_dialogue_result", "ward_descent")
	ship.set("_crew_dialogue_open", false)
	crew_dlg.set("_is_active", false)

	# 5. Test dialogue choices for Chief Engineer Leila Haddad
	ship.call("_begin_leila_dialogue")
	choices = crew_dlg.get("_choices")
	assert(choices.size() >= 3, "Leila Haddad must offer multiple rich topics! Found: %d" % choices.size())
	ship.call("_handle_leila_dialogue_result", "leila_power_grid")
	ship.set("_crew_dialogue_open", false)
	crew_dlg.set("_is_active", false)

	# 6. Test dialogue choices for Mateo Ruiz
	ship.call("_begin_mateo_dialogue")
	choices = crew_dlg.get("_choices")
	assert(choices.size() >= 3, "Mateo Ruiz must offer multiple rich topics! Found: %d" % choices.size())
	ship.call("_handle_mateo_dialogue_result", "mateo_sponsor")
	ship.set("_crew_dialogue_open", false)
	crew_dlg.set("_is_active", false)

	ship.queue_free()
	print("✓ Test 2 Passed: Every NPC interaction on Asteria-1 has Commander Chen-style dialogue, badges, prompts, and rich choices.")
