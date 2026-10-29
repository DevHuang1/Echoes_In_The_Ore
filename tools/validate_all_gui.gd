extends SceneTree
## Rendered checks of every remaining UI, including real task inputs and level signals.
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
const SKIN := preload("res://scripts/ui/pixel_ui.gd")
var _failures := 0
var _checks := 0
var _cursor := Vector2.ZERO
var _level: Node2D
var _shot_suffix := ""
var _completed: Array[StringName] = []

func _initialize() -> void:
	_run.call_deferred()
	# A broken step must fail the run rather than hang it.
	create_timer(200.0).timeout.connect(func(): push_error("GUI validation timed out"); quit(2))

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error(message)

func _frames(count := 3) -> void:
	for i in range(count):
		await process_frame

func _move(point: Vector2, buttons := 0) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = point - _cursor
	event.button_mask = buttons
	_cursor = point
	root.push_input(event, true)
	await _frames(2)

func _mouse(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = _cursor
	event.global_position = _cursor
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event, true)
	await _frames(2)

func _click(control: Control) -> void:
	await _move(control.get_global_rect().get_center())
	await _mouse(true)
	await _mouse(false)

func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event, true)
		await _frames(2)

func _slider(slider: HSlider, value: int) -> void:
	# Keyboard input exercises the actual HSlider and its connected signal.
	slider.grab_focus()
	await _key(KEY_HOME)
	for i in range(value):
		await _key(KEY_RIGHT)
	_check(roundi(slider.value) == value, "Slider keyboard value incorrect")

func _layout(ui: Node) -> void:
	var screen := root.get_visible_rect().grow(1)
	for node in ui.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree():
			continue
		if control is PanelContainer or control is Button or control is HSlider or control is Label:
			_check(screen.encloses(control.get_global_rect()), "Clipped control: %s %s" % [control.get_path(), control.get_global_rect()])
		if control is Button:
			var normal := control.get_theme_stylebox("normal")
			_check(normal is StyleBoxTexture, "Button uses old style")
			var font := control.get_theme_font("font")
			var text_size := font.get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size"))
			_check(text_size.x <= control.size.x - normal.get_minimum_size().x + 1, "Button text clipped: " + control.text)
		if control is Label and not control.text.is_empty():
			var font := control.get_theme_font("font")
			_check(font == SKIN.THEME.default_font, "Old font: " + control.text)
			for character in control.text:
				if character != "\n" and character != "\t":
					_check(font.has_char(character.unicode_at(0)), "Missing bitmap glyph: " + character)
			if control.autowrap_mode == TextServer.AUTOWRAP_OFF:
				for line in control.text.split("\n"):
					var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size")).x
					_check(width <= control.size.x + 1, "Label clipped: " + line)
			else:
				_check(control.get_line_count() * font.get_height(control.get_theme_font_size("font_size")) <= control.size.y + 2, "Wrapped text vertically clipped: " + control.text)

func _shot(name: String, ui: Node) -> void:
	await _frames(5)
	_layout(ui)
	await _move(Vector2(4, 350))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/all_gui_validation/%s_%s.png" % [name, _shot_suffix])

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/all_gui_validation")
	for window_size in [Vector2i(1280, 720), Vector2i(1024, 576)]:
		root.size = window_size
		_shot_suffix = "%dx%d" % [window_size.x, window_size.y]
		await _frames(8)
		_level = LEVEL.instantiate()
		root.add_child(_level)
		await create_timer(0.5).timeout
		var briefing: Node
		for child in _level.get_children():
			if child.get_script() == load("res://scripts/ui/arrival_briefing.gd"):
				briefing = child
		_check(is_instance_valid(briefing), "Missing arrival briefing")
		await _shot("arrival", briefing)
		await _key(KEY_ENTER)
		await create_timer(0.3).timeout
		var player := _level.get_node("Player") as ShipPlayer
		_check(not _level.get("_arrival_briefing_open") and player.is_physics_processing(), "Briefing did not release movement")

		# Real first-meeting dialogue and both offer outcomes.
		_level.call("_begin_amara_dialogue")
		var dialogue := _level.get("_crew_dialogue") as CrewDialogue
		await _key(KEY_E)
		_check(dialogue.phase != "typing", "Dialogue reveal failed")
		await _shot("dialogue", dialogue)
		var guard := 0
		while dialogue.phase != "choose" and dialogue._active and guard < 20:
			await _key(KEY_E); guard += 1
		await _shot("dialogue_choices", dialogue)
		await _key(KEY_Q)
		_check(not _level.get("_crew_dialogue_open") and not _level.get("_crew_tasks_unlocked"), "Dialogue decline failed")
		_level.call("_begin_amara_dialogue")
		guard = 0
		while dialogue._active and guard < 20:
			await _key(KEY_E); guard += 1
		_check(_level.get("_crew_tasks_unlocked") and player.is_physics_processing(), "Dialogue accept failed")
		_level.call("_begin_amara_dialogue")
		guard = 0
		while dialogue._active and guard < 20:
			await _key(KEY_E); guard += 1
		_check(player.is_physics_processing(), "Non-offer dialogue close failed")

		for id in [&"auxiliary_power", &"air_filter", &"nutrient_flow"]:
			_level.call("_open_room_task_console", id)
			var console: ServiceTaskConsole
			for child in _level.get_children():
				if child is ServiceTaskConsole:
					console = child
			await create_timer(0.3).timeout
			_check(not player.is_physics_processing(), "Service console did not gate walking")
			console.task_completed.connect(func(task_id: StringName): _completed.append(task_id))
			_check(console._close_button.size == Vector2(48, 48) and console._close_button.theme_type_variation == &"CloseButton", "Service close must be square")
			await _shot(str(id), console)
			if id == &"auxiliary_power":
				_check(console._power_sync_button.disabled, "Power sync initially enabled")
				for i in range(3):
					await _slider(console._power_sliders[i], [67, 43, 77][i])
				_check(not console._power_sync_button.disabled, "Power sync did not unlock")
				await _click(console._power_sync_button)
				_check(not console._power_sliders[0].editable, "Completed power slider remains editable")
			elif id == &"air_filter":
				await _click(console._filter_release_button)
				_check(console._filter_stage == 1, "Release latch failed")
				var row: HBoxContainer = console._filter_stage_controls.get_child(0)
				_check(row.get_child(1).disabled, "Filter seating initially enabled")
				await _shot("filter_align", console)
				await _click(row.get_child(0))
				await _click(row.get_child(0))
				_check(not row.get_child(1).disabled, "Filter notch alignment failed")
				await _click(row.get_child(1))
				_check(console._filter_stage == 2 and console._filter_pressure_button.disabled, "Filter seating failed")
				await _shot("filter_pressure", console)
				await _slider(console._filter_pressure_slider, 67)
				_check(not console._filter_pressure_button.disabled, "Filter target range did not unlock")
				await _click(console._filter_pressure_button)
			else:
				_check(console._nutrient_restore_button.disabled, "Hydro restore initially enabled")
				for i in range(3):
					for turn in range([1, 1, 3][i]):
						await _click(console._nutrient_rotate_buttons[i])
				_check(not console._nutrient_restore_button.disabled, "Hydro alignment failed")
				await _click(console._nutrient_restore_button)
				_check(console._nutrient_rotate_buttons[0].disabled, "Completed valve remains enabled")
			_check(console._task_complete and console._return_button.visible, "Task did not complete: " + str(id))
			_check(_level.get("_completed_room_tasks").has(id), "Level did not receive completion")
			_check(_completed.count(id) == (1 if window_size.x == 1280 else 2), "Completion signal duplicated")
			await _shot(str(id) + "_complete", console)
			await _click(console._return_button)
			await create_timer(0.2).timeout
			_check(not _level.get("_task_console_open") and player.is_physics_processing(), "Return did not close service/resume walking")

		# Both ordinary close routes, without completing a task.
		for use_escape in [false, true]:
			_level.call("_open_room_task_console", &"air_filter")
			var console: ServiceTaskConsole
			for child in _level.get_children():
				if child is ServiceTaskConsole:
					console = child
			await create_timer(0.25).timeout
			if use_escape:
				await _key(KEY_ESCAPE)
			else:
				await _click(console._close_button)
			await create_timer(0.2).timeout
			_check(not _level.get("_task_console_open") and player.is_physics_processing(), "Service close failed")
		_level.queue_free()
		await _frames(4)

		# Inspect every story frame without altering its text or timing constants.
		var montage := load("res://scenes/ui/earth_years_montage.tscn").instantiate() as Control
		root.add_child(montage)
		await create_timer(1.0).timeout
		montage.set_process(false)
		await _click(montage.get("_next_button"))
		_check(not montage.get("_is_subtitle_typing"), "Intro Show Text button failed")
		await _key(KEY_ENTER)
		await create_timer(1.3).timeout
		_check(montage.get("_frame_index") == 1, "Intro Next keyboard activation failed")
		for i in range(montage.STORY_FRAMES.size()):
			montage.call("_show_frame", i)
			montage.call("_finish_subtitle")
			await _frames(3)
			_layout(montage)
			if i == 0:
				await _shot("intro", montage)
		# Exercise end-of-montage controls and final long button label.
		montage.call("_advance")
		await create_timer(1.3).timeout
		montage.call("_finish_subtitle")
		_check(montage.get("_finished"), "Montage final state failed")
		await _shot("intro_boarding", montage)
		if window_size.x == 1280:
			current_scene = montage
			await _click(montage.get("_next_button"))
			await create_timer(1.5).timeout
			_check(current_scene.scene_file_path == "res://scenes/ship/bare_ship_walkthrough.tscn", "Board Asteria transition failed")
			current_scene.queue_free()
		else:
			montage.queue_free()
		await _frames(3)

		var landing := load("res://scenes/ui/landing_screen.tscn").instantiate() as Control
		root.add_child(landing)
		await _shot("landing", landing)
		landing.queue_free()
		await _frames(3)
		print("All remaining UI checked at %s (logical %s)" % [window_size, root.get_visible_rect().size])

	# Full real START -> intro -> Skip -> gameplay scene transition.
	root.size = Vector2i(1280, 720)
	var landing := load("res://scenes/ui/landing_screen.tscn").instantiate() as Control
	root.add_child(landing)
	current_scene = landing
	await _frames(5)
	await _click(landing.get("_start_button"))
	await create_timer(2.0).timeout
	_check(current_scene.scene_file_path == "res://scenes/ui/earth_years_montage.tscn", "START transition failed")
	await _click(current_scene.get("_skip_button"))
	await create_timer(2.0).timeout
	_check(current_scene.scene_file_path == "res://scenes/ship/bare_ship_walkthrough.tscn", "Skip Intro transition failed")
	current_scene.queue_free()
	await _frames(4)
	print("ALL GUI VALIDATION: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)

