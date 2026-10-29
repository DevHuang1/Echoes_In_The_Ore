extends SceneTree

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
const WALK_HUD_SCRIPT = preload("res://scripts/ui/walk_hud.gd")

func _init() -> void:
	print("--- BEGIN TEST: PLASMA GUN ORIENTATION & LIMITED FLARES/AMMO ---")

	if Engine.has_meta(&"echoes_campaign_inventory_state"):
		Engine.remove_meta(&"echoes_campaign_inventory_state")

	var player: ShipPlayer = PLAYER_SCENE.instantiate() as ShipPlayer
	player._setup_equipment_visual_nodes()

	var hud = WALK_HUD_SCRIPT.new()
	var dummy_tasks: Array[Dictionary] = []
	hud.setup(player, dummy_tasks, Vector2.ZERO, Vector2(1000, 1000))

	# TEST 1: Industrial Plasma Cutter Orientation & Holding Visuals
	hud.unlock_equipment_item(&"industrial_plasma_cutter", true)
	player.equip_item(&"industrial_plasma_cutter")
	assert(player._equipped_item_id == &"industrial_plasma_cutter", "Player should have plasma cutter equipped")

	# Check icon texture orientation (mass distribution): top_com_x > bot_com_x means barrel is right, grip is left
	var cutter_icon = Image.load_from_file("art/tools/icons/industrial_plasma_cutter.png")
	assert(cutter_icon != null, "Cutter icon must exist")
	var w = cutter_icon.get_width()
	var h = cutter_icon.get_height()
	var top_com_x = 0.0
	var top_sum = 0.0
	var bot_com_x = 0.0
	var bot_sum = 0.0
	for y in range(h):
		for x in range(w):
			var a = cutter_icon.get_pixel(x, y).a
			if a > 0.2:
				if y < h / 2:
					top_com_x += x * a
					top_sum += a
				else:
					bot_com_x += x * a
					bot_sum += a
	var t_x = (top_com_x / max(1.0, top_sum)) / float(w)
	var b_x = (bot_com_x / max(1.0, bot_sum)) / float(w)
	assert(t_x > b_x, "Plasma cutter must face right in base texture (barrel forward/right, grip left)")
	print("✓ Test 1 Passed: Plasma cutter icon and sprite texture face forward with handle at the grip.")

	# TEST 2: Facing Right & Left Hand Transforms
	player._facing_animation = &"walk_right"
	player._update_equipment_transform()
	assert(player._held_item_sprite.flip_h == false, "Facing right: flip_h should be false so muzzle points right")

	player._facing_animation = &"walk_left"
	player._update_equipment_transform()
	assert(player._held_item_sprite.flip_h == true, "Facing left: flip_h should be true so muzzle points left")
	print("✓ Test 2 Passed: Plasma cutter correctly held in hand pointing forward in both walk_right and walk_left.")

	# TEST 3: Flare Limited Amount Initialization
	hud.unlock_equipment_item(&"emergency_flare", true)
	assert(hud.is_item_limited(&"emergency_flare"), "Emergency flare must be marked as limited")
	assert(hud.get_item_amount(&"emergency_flare") == 5, "Initial flare amount should be 5")
	assert(player.get_equipment_amount(&"emergency_flare") == 5, "Player flare amount should match HUD (5)")
	print("✓ Test 3 Passed: Emergency flare unlocks with limited amount (5 flares).")

	# TEST 4: Flare Depletion (Throwing Flares)
	player.equip_item(&"emergency_flare")
	player._update_equipment_transform()
	assert(player._equipment_light.enabled == true, "Held flare should have lit glow when flares remain")
	assert(player._held_item_sprite.visible == true, "Held flare sprite should be visible")

	# Throw all 5 flares
	for i in range(5):
		var before_amt = player.get_equipment_amount(&"emergency_flare")
		player._action_cooldown = 0.0
		player.start_using_equipment(false)
		var after_amt = player.get_equipment_amount(&"emergency_flare")
		assert(after_amt == before_amt - 1, "Throwing flare should decrement count by 1")

	assert(player.get_equipment_amount(&"emergency_flare") == 0, "Flares should now be 0")
	assert(hud.get_item_amount(&"emergency_flare") == 0, "HUD flare amount should be 0")

	# Try to throw when 0
	var prev_flying_count = player._flying_flares.size()
	player._action_cooldown = 0.0
	player.start_using_equipment(false)
	assert(player._flying_flares.size() == prev_flying_count, "Cannot throw flare when out of flares!")
	player._update_equipment_transform()
	assert(player._held_item_sprite.visible == false, "Flare sprite should be hidden when flares are 0")
	assert(player._equipment_light.enabled == false, "Flare light should be off when flares are 0")
	print("✓ Test 4 Passed: Flares decrement per throw and cannot be thrown when depleted; unlit when empty.")

	# TEST 5: Restock and Add Flares
	hud.add_item_amount(&"emergency_flare", 3)
	assert(player.get_equipment_amount(&"emergency_flare") == 3, "Adding flares should update amount to 3")
	player._update_equipment_transform()
	assert(player._held_item_sprite.visible == true, "Held flare becomes visible again once restocked")
	assert(player._equipment_light.enabled == true, "Held flare light reignites once restocked")
	print("✓ Test 5 Passed: Flares restocked and held visual reactivates.")

	# TEST 6: Captain's Revolver Limited Ammo
	hud.unlock_equipment_item(&"captains_revolver", true)
	player.equip_item(&"captains_revolver")
	assert(hud.is_item_limited(&"captains_revolver"), "Revolver must be limited ammo")
	assert(player.get_equipment_amount(&"captains_revolver") == 6, "Revolver should start with full 6-round cylinder")

	for i in range(6):
		player._action_cooldown = 0.0
		player.start_using_equipment(false)
	assert(player.get_equipment_amount(&"captains_revolver") == 0, "Revolver should be empty after 6 shots")

	var prev_tracers = player._bullet_tracers.size()
	player._action_cooldown = 0.0
	player.start_using_equipment(false)
	assert(player._bullet_tracers.size() == prev_tracers, "Cannot fire revolver when cylinder is empty")
	print("✓ Test 6 Passed: Captain's revolver has limited 6-round cylinder and dry-fires when empty.")

	# TEST 7: Other Limited Gear (Beacons, Med-Injector, Pressure Sealant)
	hud.unlock_equipment_item(&"survey_beacon", true)
	assert(hud.is_item_limited(&"survey_beacon") and hud.get_item_amount(&"survey_beacon") == 3, "Survey beacon has limited 3 beacons")

	hud.unlock_equipment_item(&"medical_injector", true)
	assert(hud.is_item_limited(&"medical_injector") and hud.get_item_amount(&"medical_injector") == 3, "Medical injector has limited 3 doses")

	hud.unlock_equipment_item(&"pressure_sealant", true)
	assert(hud.is_item_limited(&"pressure_sealant") and hud.get_item_amount(&"pressure_sealant") == 50, "Pressure sealant has 50 PSI capacity")
	print("✓ Test 7 Passed: Survey beacons, medical injector, and pressure sealant correctly configured with limited amounts.")

	# TEST 8: Dropping and Picking up Preserved Amounts
	hud.unlock_equipment_item(&"captains_revolver", true)
	hud.set_item_amount(&"captains_revolver", 4)
	assert(player.get_equipment_amount(&"captains_revolver") == 4, "Set revolver to 4 rounds")
	hud.drop_active_item()
	assert(hud._dropped_world_items.size() > 0, "Dropped item should exist in world")
	var last_drop = hud._dropped_world_items.back()
	assert(last_drop["item_id"] == &"captains_revolver", "Dropped item should be revolver")
	assert(last_drop["amount"] == 4, "Dropped item must preserve its remaining 4 rounds")

	# Pick it back up
	player.global_position = last_drop["pos"]
	hud.pickup_nearby_or_interact()
	assert(hud.get_item_amount(&"captains_revolver") == 4, "Picked up revolver must still have 4 rounds")
	print("✓ Test 8 Passed: Dropping and picking up gear preserves remaining ammo and flare counts.")

	# TEST 9: Campaign State Persistence
	hud.set_item_amount(&"emergency_flare", 8)
	hud._save_persistent_inventory_state()
	var state = Engine.get_meta(&"echoes_campaign_inventory_state")
	assert(state.has("item_amounts"), "Campaign state must serialize item_amounts")
	assert(state["item_amounts"][&"emergency_flare"] == 8, "Persisted flare count must be 8")

	# Simulate scene change / reload
	var hud2 = WALK_HUD_SCRIPT.new()
	hud2.setup(player, [], Vector2.ZERO, Vector2(1000, 1000))
	assert(hud2.get_item_amount(&"emergency_flare") == 8, "Reloaded HUD must restore 8 flares")
	print("✓ Test 9 Passed: Limited amounts successfully persist across scene transitions via campaign state.")

	print("--- ALL TESTS PASSED SUCCESSFULLY! ---")
	quit()
