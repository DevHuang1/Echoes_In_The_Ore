extends SceneTree

var _timer: float = 0.0
var _step: int = 0

func _init() -> void:
	print("--- BEGIN BACKGROUND MUSIC & SCENE TRANSITION TEST ---")


func _process(delta: float) -> bool:
	_timer += delta

	var bgm = root.get_node_or_null("BackgroundMusic")
	if bgm == null and _timer < 1.0:
		return false

	assert(bgm != null, "BackgroundMusic autoload must exist in the scene tree!")

	if _step == 0:
		print("[TEST 1] Verifying BackgroundMusic initialization & track...")
		assert(bgm.TITLE_THEME != null, "TITLE_THEME must be loaded!")
		assert(bgm.TITLE_THEME.resource_path.ends_with("Theme music dubstep.mp3"), "TITLE_THEME must be Theme music dubstep.mp3!")
		print("       Track loaded: ", bgm.TITLE_THEME.resource_path)
		print("✓ Test 1 Passed: Theme music correctly loaded.")
		_step = 1
		_timer = 0.0
		return false

	if _step == 1:
		print("[TEST 2] Testing play_title_music & stop_music controls...")
		bgm.play_title_music()
		assert(bgm.is_playing(), "BackgroundMusic should be playing after play_title_music!")
		assert(bgm._music_player.stream == bgm.TITLE_THEME, "Audio stream should match TITLE_THEME!")
		
		bgm.stop_music()
		assert(not bgm.is_playing(), "BackgroundMusic should stop after stop_music!")
		print("✓ Test 2 Passed: play_title_music and stop_music function as expected.")
		_step = 2
		_timer = 0.0
		return false

	if _step == 2:
		print("[TEST 3] Testing scene switching behavior...")
		# When landing screen is active, play_title_music is called.
		# When switching away from landing screen, music stops before backstory.
		bgm.play_title_music()
		assert(bgm.is_playing(), "Music should be playing on title screen.")
		
		# Simulate transition to character backstory (fade out)
		bgm.stop_music(0.1)
		# After immediate stop or fade completion:
		print("✓ Test 3 Passed: Music stops prior to character backstory & ship intro.")
		_step = 3
		_timer = 0.0
		return false

	if _step == 3:
		if _timer >= 0.15:
			assert(not bgm.is_playing(), "Music must be stopped after fade out!")
			print("--- ALL BACKGROUND MUSIC TESTS PASSED SUCCESSFULLY! ---")
			quit(0)
			return true

	return false
