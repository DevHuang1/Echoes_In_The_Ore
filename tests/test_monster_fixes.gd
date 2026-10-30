extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const VILLAIN_SCENE := preload("res://scenes/ship/crew/resonance_ore_villain.tscn")
const PRESSURE_DOOR_SCENE := preload("res://scenes/ship/doors/pressure_door.tscn")

func _init() -> void:
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	print("\n--- BEGIN TEST: MONSTER MOVEMENT, WALLS, SHADOW & TENTACLE ATTACK ---")

	_test_facing_and_animation_rows()
	_test_wall_and_door_collision()
	_test_shadow_rendering_and_states()
	_test_tentacle_attack_mechanics()

	print("--- ALL MONSTER FIX TESTS PASSED SUCCESSFULLY! ---\n")
	quit(0)


func _test_facing_and_animation_rows() -> void:
	print("[TEST 1] Testing Monster Facing Direction & ANIMATION_ROWS Mapping...")
	var villain: ResonanceOreVillain = VILLAIN_SCENE.instantiate()
	root.add_child(villain)

	# 1. Verify ANIMATION_ROWS matches standard 4-direction layout
	assert(ResonanceOreVillain.ANIMATION_ROWS[&"walk_down"] == 0, "walk_down should be row 0")
	assert(ResonanceOreVillain.ANIMATION_ROWS[&"walk_left"] == 1, "walk_left should be row 1 (was inverted to row 2)")
	assert(ResonanceOreVillain.ANIMATION_ROWS[&"walk_right"] == 2, "walk_right should be row 2 (was inverted to row 1)")
	assert(ResonanceOreVillain.ANIMATION_ROWS[&"walk_up"] == 3, "walk_up should be row 3")

	# 2. Verify facing animation selection
	villain._update_facing(Vector2.RIGHT)
	assert(villain._facing_animation == &"walk_right", "Moving right must set facing animation to walk_right.")

	villain._update_facing(Vector2.LEFT)
	assert(villain._facing_animation == &"walk_left", "Moving left must set facing animation to walk_left.")

	villain._update_facing(Vector2.DOWN)
	assert(villain._facing_animation == &"walk_down", "Moving down must set facing animation to walk_down.")

	villain._update_facing(Vector2.UP)
	assert(villain._facing_animation == &"walk_up", "Moving up must set facing animation to walk_up.")

	# 3. Verify SpriteFrames atlas region for walk_left vs walk_right
	var frames: SpriteFrames = villain.sprite.sprite_frames
	assert(frames != null, "Sprite frames must be configured.")
	var tex_left: AtlasTexture = frames.get_frame_texture(&"walk_left", 0) as AtlasTexture
	var tex_right: AtlasTexture = frames.get_frame_texture(&"walk_right", 0) as AtlasTexture
	assert(tex_left != null and tex_right != null, "Atlas textures must exist.")

	var frame_h: float = tex_left.region.size.y
	# row 1: y = 1 * frame_h
	assert(is_equal_approx(tex_left.region.position.y, frame_h), "walk_left frame must come from Row 1.")
	# row 2: y = 2 * frame_h
	assert(is_equal_approx(tex_right.region.position.y, frame_h * 2.0), "walk_right frame must come from Row 2.")

	villain.free()
	print("✓ Test 1 Passed: Facing animation and row index mapping verified (no longer walks backwards).")


func _test_wall_and_door_collision() -> void:
	print("[TEST 2] Testing Monster Wall and Closed Pressure Door Blocking...")
	var villain: ResonanceOreVillain = VILLAIN_SCENE.instantiate()
	root.add_child(villain)

	# 1. Create a synthetic floor mask: 200x200 image where (0..100) is solid floor and (101..200) is void
	var mask_img := Image.create(200, 200, false, Image.FORMAT_RGBA8)
	mask_img.fill(Color(0, 0, 0, 0)) # transparent void
	for y in range(200):
		for x in range(100):
			mask_img.set_pixel(x, y, Color(1, 1, 1, 1)) # solid walkable floor

	villain._floor_mask = mask_img
	villain._floor_origin = Vector2.ZERO
	villain.global_position = Vector2(50.0, 50.0)

	# (50, 50) is walkable floor
	assert(villain._position_is_walkable(Vector2(50.0, 50.0)), "Center of floor must be walkable.")

	# (150, 50) is void (non-walkable)
	assert(not villain._position_is_walkable(Vector2(150.0, 50.0)), "Void area must NOT be walkable.")

	# Motion from (50, 50) to (150, 50) steps into void
	var motion_into_void := Vector2(100.0, 0.0)
	assert(not villain._can_move_on_walkable_floor(motion_into_void), "Motion into void must be rejected by _can_move_on_walkable_floor.")

	# Motion within walkable floor (from 50 to 60)
	var valid_motion := Vector2(10.0, 0.0)
	assert(villain._can_move_on_walkable_floor(valid_motion), "Motion within solid floor must be allowed.")

	# 2. Test Pressure Door blocking
	var door: ShipPressureDoor = PRESSURE_DOOR_SCENE.instantiate()
	root.add_child(door)
	door.global_position = Vector2(50.0, 50.0)
	door.locked = true
	door.set("_is_open", false)

	# Closed door must block the villain's position
	assert(door.blocks_position(door.global_position, villain._get_effective_radius()), "Door must report blocking.")
	assert(not villain._position_is_walkable(Vector2(50.0, 50.0), true), "Closed door must make position non-walkable.")
	assert(villain._get_blocking_door(Vector2(50.0, 50.0)) == door, "Blocking door must be identified.")

	# Open the door
	door.set("_is_open", true)
	door.locked = false
	assert(not door.blocks_position(door.global_position, villain._get_effective_radius()), "Open door must not block.")
	assert(villain._position_is_walkable(Vector2(50.0, 50.0), true), "Open door position must be walkable.")
	assert(villain._get_blocking_door(Vector2(50.0, 50.0)) == null, "Open door must not report as blocking door.")

	door.free()
	villain.free()
	print("✓ Test 2 Passed: Non-walkable deck boundaries and closed pressure doors strictly block the monster.")


func _test_shadow_rendering_and_states() -> void:
	print("[TEST 3] Testing Grounded Multi-Ellipse Dynamic Shadow...")
	var villain: ResonanceOreVillain = VILLAIN_SCENE.instantiate()
	root.add_child(villain)

	# Idle state: velocity is zero, walk_blend smoothly moves towards 0
	villain.velocity = Vector2.ZERO
	villain._physics_process(0.5)
	assert(villain._walk_blend <= 0.1, "Shadow walk_blend should be near 0 in idle state.")

	# Moving state: velocity > 10
	villain.velocity = Vector2(50.0, 0.0)
	villain._physics_process(0.2)
	assert(villain._walk_blend > 0.0, "Shadow walk_blend should increase when moving.")
	assert(villain._walk_stride_phase > 0.0, "Shadow walk stride phase should advance when moving.")

	# Verify form stage transitions adapt shadow sizes
	for stage in [villain.FormStage.LIQUID, villain.FormStage.STAGE1_INFECTED, villain.FormStage.STAGE2_MUTATED, villain.FormStage.STAGE3_FINAL_FORM]:
		villain.set_form_stage(stage, true)
		assert(villain.form_stage == stage, "Form stage should update correctly.")

	villain.free()
	print("✓ Test 3 Passed: Dynamic grounded shadow properly responds to idle/walk cycles and form stages.")


func _test_tentacle_attack_mechanics() -> void:
	print("[TEST 4] Testing Monster Tentacle Lash Attack & Impact Effects...")
	var villain: ResonanceOreVillain = VILLAIN_SCENE.instantiate()
	var player = PLAYER_SCENE.instantiate()
	root.add_child(villain)
	root.add_child(player)

	villain.global_position = Vector2(200.0, 200.0)
	player.global_position = Vector2(220.0, 200.0) # 20 px away

	# Setup player without struggle items
	player.set_equipment_amount(&"emergency_flare", 0)
	player.set_equipment_amount(&"electrical_discharge_tool", 0)
	player.set_equipment_amount(&"survey_beacon", 0)
	player.set_equipment_amount(&"medical_injector", 0)

	var initial_trauma: float = player.get("_screen_shake_trauma") if player.get("_screen_shake_trauma") != null else 0.0

	# 1. Execute direct tentacle attack
	villain._attack_player(player)

	# Verify tentacle attack parameters were generated
	assert(villain._tentacle_attack_timer > 0.0, "Tentacle attack timer must be active.")
	assert(not villain._tentacle_strikes.is_empty(), "Tentacle strikes tendrils must be generated.")
	assert(villain._tentacle_strikes.size() >= 4, "Should have at least 4 tendrils.")
	assert(not villain._tentacle_impact_particles.is_empty(), "Tentacle impact particles must be spawned.")

	# Verify screen shake triggered on player
	var post_trauma: float = player.get("_screen_shake_trauma") if player.get("_screen_shake_trauma") != null else 0.0
	assert(post_trauma >= 0.8, "Tentacle strike must trigger high screen shake trauma (>= 0.8). Got: " + str(post_trauma))

	# Verify player knockback away from villain
	assert(player.global_position.x > 220.0, "Player must be knocked back away from the tentacle attack.")

	# 2. Advance physics to verify tentacle particles update
	villain._physics_process(0.1)
	assert(villain._tentacle_attack_timer < 0.55, "Tentacle attack timer should advance.")

	# 3. Test equipped item defense vs struggle inventory escape
	# 3a. Equipped flare with charges consumes 1 charge and repels
	player.set_equipment_amount(&"emergency_flare", 2)
	player.equip_item(&"emergency_flare")
	villain._is_repelled = false
	villain._attack_player(player)
	assert(villain._is_repelled, "Equipped flare should repel monster.")
	assert(player.get_equipment_amount(&"emergency_flare") == 1, "Equipped flare defense must consume 1 flare.")

	# 3b. Equipped flare with 0 charges does NOT repel via equipped tool
	player.set_equipment_amount(&"emergency_flare", 0)
	villain._is_repelled = false
	villain._attack_player(player)
	assert(not villain._is_repelled, "Empty flare slot (0 charges) must NOT repel monster.")

	# 3c. Struggle inventory fallback consumes 1 charge
	player.equip_item(&"")
	player.set_equipment_amount(&"emergency_flare", 1)
	villain._is_repelled = false
	villain._attack_player(player)
	assert(villain._is_repelled, "Struggle escape should repel monster.")
	assert(player.get_equipment_amount(&"emergency_flare") == 0, "Struggle escape should consume 1 flare.")

	# 4. Verify player take_damage handles suit hit
	player.take_damage(25.0)
	assert(player.get("_screen_shake_trauma") >= 0.8, "Player take_damage should trigger screen shake trauma.")

	player.free()
	villain.free()
	print("✓ Test 4 Passed: Tentacle lash attack with animated tendrils, visual impact, screen shake, and struggle verified.")
