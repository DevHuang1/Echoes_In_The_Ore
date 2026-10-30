extends SceneTree
## Rendered integration checks; run with --path . --script tools/validate_pixel_gui.gd.
## All interactions and screenshots are in memory; no gameplay/room files are saved.
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
var _failures := 0
var _checks := 0
var _cursor := Vector2.ZERO
var _hud: WalkHud
var _level: Node2D

func _initialize() -> void:
	_run.call_deferred()

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

func _mouse(button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = _cursor
	event.global_position = _cursor
	event.button_index = button
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed and button == MOUSE_BUTTON_LEFT else 0
	root.push_input(event, true)
	await _frames(2)

func _click(control: Control) -> void:
	await _move(control.get_global_rect().get_center())
	await _mouse(MOUSE_BUTTON_LEFT, true)
	await _mouse(MOUSE_BUTTON_LEFT, false)

func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event, true)
		await _frames(2)

func _drag(source: Control, target: Control) -> void:
	await _move(source.get_global_rect().get_center())
	await _mouse(MOUSE_BUTTON_LEFT, true)
	await _move(_cursor + Vector2(14, 2), MOUSE_BUTTON_MASK_LEFT)
	await _move(target.get_global_rect().get_center(), MOUSE_BUTTON_MASK_LEFT)
	_check(root.gui_is_dragging(), "Mouse drag did not start")
	await _mouse(MOUSE_BUTTON_LEFT, false)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/gui_validation")
	_level = LEVEL.instantiate()
	root.add_child(_level)
	_hud = _level.get("_walk_hud") as WalkHud
	var player := _level.get_node("Player") as CharacterBody2D
	var master := AudioServer.get_bus_index("Master")
	var previous_db := AudioServer.get_bus_volume_db(master)
	var previous_mute := AudioServer.is_bus_mute(master)
	await _frames(6)
	await _key(KEY_I)
	_check(_hud._active_overlay == &"", "Briefing must gate HUD shortcuts")
	_level.call("_on_arrival_briefing_dismissed")
	for child in _level.get_children():
		if child is CanvasLayer and child != _hud:
			child.hide()
			child.set_process_unhandled_input(false)
			child.set_process_unhandled_key_input(false)
	await _frames(6)
	_check(player.is_physics_processing(), "Walking did not resume after briefing")
	_check(_hud._storage_items.size() == 27 and _hud._hotbar_items.size() == 9 and _hud._equipment_cells.size() == 4, "Inventory capacity changed")
	var initial_storage := _hud._storage_items.duplicate()
	var initial_equipment := _hud._equipment_items.duplicate()
	var menu := _hud._root.get_node("TopRightControls")
	for pair in [["SHIPMAP", &"map"], ["INVENTORY", &"inventory"], ["SETTINGS", &"settings"]]:
		var button := menu.get_node(pair[0]) as Button
		await _move(button.get_global_rect().get_center())
		_check(button.is_hovered() and button.get_theme_stylebox("hover") is StyleBox, "Menu hover missing: " + pair[0])
		await _click(button)
		_check(_hud._active_overlay == pair[1] and not player.is_physics_processing(), "Menu opening/pause failed: " + pair[0])
		var close := _hud._overlay_nodes[pair[1]].find_child("Close", true, false) as Button
		_check(is_equal_approx(close.size.x, close.size.y) and close.theme_type_variation == &"CloseButton", "Close control must be square")
		await _click(close)
		_check(_hud._active_overlay == &"" and player.is_physics_processing(), "Close button/resume failed")
	# The existing input handlers are exercised through viewport events.
	for i in range(9):
		await _key((KEY_1 + i) as Key)
		_check(_hud._selected_hotbar_index == i, "Number shortcut failed: " + str(i + 1))
		await _click(_hud._hotbar_slots[8 - i])
		_check(_hud._selected_hotbar_index == 8 - i, "HUD slot click failed")
	_hud.call("_select_hotbar", 0)
	await _move(Vector2(700, 400))
	await _mouse(MOUSE_BUTTON_WHEEL_UP, true)
	await _mouse(MOUSE_BUTTON_WHEEL_UP, false)
	_check(_hud._selected_hotbar_index == 8, "Wheel-up wrapping failed")
	await _mouse(MOUSE_BUTTON_WHEEL_DOWN, true)
	await _mouse(MOUSE_BUTTON_WHEEL_DOWN, false)
	_check(_hud._selected_hotbar_index == 0, "Wheel-down wrapping failed")
	await _key(KEY_I)
	_check(_hud._active_overlay == &"inventory", "Inventory shortcut failed")
	for i in range(9):
		await _click(_hud._inventory_hotbar_cells[i])
		_check(_hud._selected_hotbar_index == i and _hud._hotbar_slots[i].is_selected, "Inventory quick-slot selection failed")
	_check(not _hud._storage_cells[0].tooltip_text.is_empty() and _hud._storage_cells[26].tooltip_text == "Empty slot", "Inventory tooltips missing")
	await _drag(_hud._storage_cells[0], _hud._inventory_hotbar_cells[0])
	_check(_hud._storage_items[0] == &"" and _hud._hotbar_items[0] == &"captains_revolver", "Cargo-to-hotbar drag failed")
	await _drag(_hud._inventory_hotbar_cells[0], _hud._equipment_cells[0])
	_check(_hud._equipment_items[&"head"] == &"" and _hud._hotbar_items[0] == &"captains_revolver", "Incompatible HEAD transfer was accepted")
	await _drag(_hud._inventory_hotbar_cells[0], _hud._equipment_cells[3])
	_check(_hud._equipment_items[&"tool"] == &"captains_revolver" and _hud._hotbar_items[0] == &"mineral_survey_scanner", "Occupied equipment swap failed")
	await _drag(_hud._equipment_cells[3], _hud._storage_cells[0])
	await _drag(_hud._inventory_hotbar_cells[0], _hud._equipment_cells[3])
	await _drag(_hud._equipment_cells[1], _hud._storage_cells[8])
	_check(_hud._equipment_items[&"suit"] == &"" and _hud._storage_items[8] == &"suit_flashlight", "Unequip-to-cargo drag failed")
	await _drag(_hud._storage_cells[8], _hud._equipment_cells[3])
	_check(_hud._equipment_items[&"tool"] == &"mineral_survey_scanner" and _hud._storage_items[8] == &"suit_flashlight", "Incompatible TOOL transfer was accepted")
	await _drag(_hud._storage_cells[8], _hud._equipment_cells[1])
	await _drag(_hud._storage_cells[0], _hud._storage_cells[8])
	await _drag(_hud._storage_cells[8], _hud._storage_cells[0])
	_check(_hud._storage_items == initial_storage and _hud._equipment_items == initial_equipment and _hud._hotbar_items.count(&"") == 9, "Drag/drop lost, duplicated or changed items")
	var selection_before_modal_key := _hud._selected_hotbar_index
	await _key(KEY_1)
	_check(_hud._selected_hotbar_index == selection_before_modal_key, "Modal window must gate quick-slot keyboard input")
	await _key(KEY_ESCAPE)
	_check(_hud._active_overlay == &"", "Inventory Escape close failed")
	await _key(KEY_M)
	_check(_hud._active_overlay == &"map", "Map shortcut failed")
	_check(_hud._map_surface.find_children("*", "TextureRect", true, false).is_empty(), "Unfinished map illustration is still present")
	_check(not _hud._map_player_marker.is_visible_in_tree(), "Player marker visible on blank map")
	_check(_hud._map_task_markers.size() == _hud._task_entries.size(), "Map/task data was lost")
	for data in _hud._map_task_markers.values():
		_check(not data.marker.is_visible_in_tree() and data.marker.mouse_filter == Control.MOUSE_FILTER_IGNORE and data.marker.focus_mode == Control.FOCUS_NONE, "Hidden map marker can render or receive input")
	await _key(KEY_M)
	_check(_hud._active_overlay == &"", "Map M close failed")
	await _key(KEY_ESCAPE)
	_check(_hud._active_overlay == &"settings", "Settings Escape open failed")
	var slider := _hud._volume_slider
	await _move(slider.get_global_rect().get_center())
	await _mouse(MOUSE_BUTTON_LEFT, true)
	await _move(slider.global_position + Vector2(1, slider.size.y / 2), MOUSE_BUTTON_MASK_LEFT)
	await _mouse(MOUSE_BUTTON_LEFT, false)
	_check(slider.value == 0 and AudioServer.is_bus_mute(master), "Volume zero must mute Master")
	await _move(slider.global_position + Vector2(slider.size.x - 1, slider.size.y / 2))
	await _mouse(MOUSE_BUTTON_LEFT, true)
	await _mouse(MOUSE_BUTTON_LEFT, false)
	_check(slider.value == 100 and not AudioServer.is_bus_mute(master), "Volume maximum failed")
	await _move(slider.get_global_rect().get_center())
	await _mouse(MOUSE_BUTTON_LEFT, true)
	await _move(slider.global_position + Vector2(slider.size.x * 0.37, slider.size.y / 2), MOUSE_BUTTON_MASK_LEFT)
	await _mouse(MOUSE_BUTTON_LEFT, false)
	_check(absf(slider.value - 37) <= 3 and is_equal_approx(AudioServer.get_bus_volume_linear(master), slider.value / 100), "Volume drag/audio value mismatch")
	_check(_hud._volume_label.text == "%d%%" % roundi(slider.value), "Volume percentage is stale")
	var before_arrow := slider.value
	await _key(KEY_RIGHT)
	_check(slider.value == before_arrow + 1, "Focused slider keyboard adjustment failed")
	await _key(KEY_ESCAPE)
	_level.set("_task_console_open", true)
	_level.call("_update_player_walk_state")
	_hud.call("_open_settings")
	_hud.call("_close_overlay")
	_check(not player.is_physics_processing(), "Closing HUD incorrectly resumed movement during another modal")
	_level.set("_task_console_open", false)
	_level.call("_update_player_walk_state")
	_hud.call("_select_hotbar", 0)
	# Capture every requested view and check real layout after OS-window resizing.
	for window_size in [Vector2i(1280, 720), Vector2i(1024, 576)]:
		root.size = window_size
		await _frames(8)
		for overlay in [&"inventory", &"settings", &"map", &""]:
			if overlay == &"":
				_hud.call("_close_overlay")
			else:
				_hud.call("_open_overlay", overlay)
			if overlay == &"settings":
				slider.value = 100
			await _frames(6)
			_check_layout()
			await _move(Vector2(8, 350))
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/gui_validation/%s_%dx%d.png" % [overlay if overlay != &"" else &"hud", window_size.x, window_size.y])
		print("Verified window layout at %s (logical viewport %s)." % [window_size, root.get_visible_rect().size])
	# Repeat pointer/keyboard smoke checks in the smaller physical window.
	for pair in [["SHIPMAP", &"map"], ["INVENTORY", &"inventory"], ["SETTINGS", &"settings"]]:
		await _click(menu.get_node(pair[0]))
		_check(_hud._active_overlay == pair[1], "Small-window menu failed")
		await _click(_hud._overlay_nodes[pair[1]].find_child("Close", true, false))
		_check(_hud._active_overlay == &"" and player.is_physics_processing(), "Small-window close/resume failed")
	for i in range(9):
		await _click(_hud._hotbar_slots[i])
		_check(_hud._selected_hotbar_index == i, "Small-window hotbar click failed")
		await _key((KEY_1 + (8 - i)) as Key)
		_check(_hud._selected_hotbar_index == 8 - i, "Small-window number shortcut failed")
	await _key(KEY_I)
	await _drag(_hud._storage_cells[0], _hud._inventory_hotbar_cells[0])
	_check(_hud._hotbar_items[0] == &"captains_revolver", "Small-window item drag failed")
	await _drag(_hud._inventory_hotbar_cells[0], _hud._storage_cells[0])
	_check(_hud._storage_items == initial_storage, "Small-window return drag failed")
	await _key(KEY_ESCAPE)
	menu.get_node("SETTINGS").grab_focus()
	await _key(KEY_ENTER)
	_check(_hud._active_overlay == &"settings", "Keyboard menu activation failed")
	await _key(KEY_ENTER)
	_check(_hud._active_overlay == &"", "Keyboard close activation failed")
	AudioServer.set_bus_volume_db(master, previous_db)
	AudioServer.set_bus_mute(master, previous_mute)
	print("PIXEL GUI VALIDATION: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)

func _check_layout() -> void:
	var screen := root.get_visible_rect().grow(1)
	for data in _hud._modal_frames.values():
		var frame := data.frame as Control
		if frame.is_visible_in_tree():
			_check(screen.encloses(frame.get_global_rect()), "Window extends beyond viewport")
	for node in _hud._root.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree():
			continue
		if control is Button or control is WalkHud.InventoryCell or control is HSlider:
			_check(screen.encloses(control.get_global_rect()) and control.size.x > 0 and control.size.y > 0, "Interactive control clipped: " + str(control.get_path()))
		if control is Label and not control.text.is_empty() and not control.clip_text and control.autowrap_mode == TextServer.AUTOWRAP_OFF:
			var text_width := control.get_theme_font("font").get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size")).x
			_check(text_width <= control.size.x + 1, "Unreadable clipped text: " + control.text)
