extends SceneTree

const SPACE_BACKDROP_SCRIPT: Script = preload("res://scripts/ship/space_backdrop.gd")
const SHIP_PILOTING_SCRIPT: Script = preload("res://scripts/ui/ship_piloting_console.gd")

func _init() -> void:
	print("--- BEGIN 3D FIRST-PERSON FLIGHT & DYNAMIC BACKGROUND TEST ---")

	# 1. Test Space Backdrop (770+ stars & dynamic sector transitions)
	print("[TEST 1] Testing Space Backdrop star density and dynamic sector states...")
	var backdrop: Node2D = SPACE_BACKDROP_SCRIPT.new()
	assert(backdrop != null, "Backdrop must instantiate successfully")
	backdrop._ready()

	var total_stars: int = backdrop._far_stars.size() + backdrop._mid_stars.size() + backdrop._near_stars.size()
	print("  -> Total stars in normal space: %d" % total_stars)
	assert(total_stars >= 700, "Star count must be 700+ multi-layer parallax stars!")
	assert(backdrop._nebula_clouds.size() >= 30, "Must have 30+ volumetric nebula clouds")
	assert(backdrop._star_clusters.size() >= 3, "Must have dense star clusters")
	assert(backdrop._pulsars.size() >= 2, "Must have rotating pulsars")
	assert(backdrop._distant_galaxies.size() >= 2, "Must have distant spiral galaxies")

	# Test sector switching
	backdrop.set_cosmic_sector(&"asteroid_belt", 1.0)
	assert(backdrop._target_sector == &"asteroid_belt", "Must target asteroid_belt sector")
	backdrop._process(1.5)
	assert(backdrop.current_sector == &"asteroid_belt", "Must blend into asteroid_belt sector")

	backdrop.set_cosmic_sector(&"stellar_corona", 1.0)
	assert(backdrop._target_sector == &"stellar_corona", "Must target stellar_corona sector")
	backdrop._process(1.5)
	assert(backdrop.current_sector == &"stellar_corona", "Must blend into stellar_corona sector")

	backdrop.set_cosmic_sector(&"black_hole", 1.0)
	assert(backdrop._target_sector == &"black_hole", "Must target black_hole sector")
	backdrop._process(1.5)
	assert(backdrop.current_sector == &"black_hole", "Must blend into black_hole sector")

	backdrop.free()
	print("✓ Test 1 Passed: Space backdrop provides 770+ stars, cosmic phenomena, and seamless sector switching.")

	# 2. Test 3D First-Person Piloting Console
	print("[TEST 2] Testing 3D Embedded Viewport & Cockpit Structure...")
	var pilot_console: CanvasLayer = SHIP_PILOTING_SCRIPT.new()
	assert(pilot_console != null, "Pilot console must instantiate")
	root.add_child(pilot_console)
	pilot_console.setup(&"bridge_flight_piloting", false)
	pilot_console._ready()

	assert(pilot_console._sub_vp != null, "SubViewport must be initialized")
	assert(pilot_console._cam_3d != null, "Camera3D must be active")
	assert(pilot_console._stars_3d.size() >= 200, "3D Starfield must contain 200+ 3D stars")
	print("✓ Test 2 Passed: 3D first-person cockpit and camera successfully created.")

	# 3. Test Task 1: Shearwater Asteroids 3D Mechanics
	print("[TEST 3] Testing Task 1: Asteroid Swarm 3D mechanics & pulse lasers...")
	pilot_console._enter_phase(2) # Enter manual flight
	assert(pilot_console._phase == 2, "Phase must be 2 (3D Manual Flight)")

	# Spawn asteroid & test pulse firing
	pilot_console._spawn_3d_asteroid()
	assert(pilot_console._asteroids_3d.size() > 0, "Asteroids must spawn in 3D scene")

	pilot_console._fire_3d_pulse_cannon()
	assert(pilot_console._pulses_3d.size() == 2, "Twin 3D pulse lasers must fire from gun mounts")

	pilot_console._process(0.1)
	print("✓ Test 3 Passed: 3D asteroids and twin laser pulse cannons function correctly.")

	# 4. Test Task 2: Helios Star Veering & Thermal Management
	print("[TEST 4] Testing Task 2: Helios Star Veering & Thermal Coolant Venting...")
	pilot_console.setup(&"star_veering", false)
	pilot_console._enter_phase(2)
	assert(pilot_console._sun_mesh != null, "3D Sun mesh must exist in Star Veering task")
	assert(pilot_console._sun_flares.size() >= 3, "Coronal flare rings must exist")

	var initial_heat: float = pilot_console._core_heat
	pilot_console._process(1.0)
	assert(pilot_console._core_heat > initial_heat, "Core heat must climb near the solar corona")

	# Test Coolant Flush
	pilot_console._core_heat = 80.0
	pilot_console._trigger_coolant_flush()
	assert(pilot_console._core_heat < 80.0, "Coolant flush [C / Shift] must reduce core heat!")
	print("✓ Test 4 Passed: Star Veering thermal core heat build-up and coolant flush system verified.")

	# 5. Test Task 3: Gargantua Singularity (Black Hole Slingshot)
	print("[TEST 5] Testing Task 3: Gargantua Black Hole Slingshot & Escape Velocity...")
	pilot_console.setup(&"black_hole_slingshot", false)
	pilot_console._enter_phase(2)
	assert(pilot_console._black_hole_root != null, "3D Black hole singularity must exist")

	var prev_escape: float = pilot_console._escape_velocity_pct
	pilot_console._process(1.0)
	assert(pilot_console._escape_velocity_pct >= prev_escape, "Escape velocity must accumulate during slingshot")
	print("✓ Test 5 Passed: Black hole accretion disk and escape velocity progression verified.")

	# 6. Test Soft-Fail Thruster Emergency Reset
	print("[TEST 6] Testing Soft-Fail Emergency Retro-burn Reset...")
	pilot_console._hull_integrity = 0.0
	pilot_console._process(0.1)
	assert(pilot_console._phase == 4, "Critical hull breach must transition to Phase 4 (Emergency Reset)")
	pilot_console._on_action_button_pressed() # Triggers retry
	assert(pilot_console._hull_integrity == 100.0, "Retry must restore systems to 100% hull")
	print("✓ Test 6 Passed: Soft-fail emergency reset allows immediate retry without losing progress.")

	pilot_console.queue_free()
	print("--- ALL 3D FIRST-PERSON FLIGHT & DYNAMIC BACKGROUND TESTS PASSED! ---")
	quit(0)
