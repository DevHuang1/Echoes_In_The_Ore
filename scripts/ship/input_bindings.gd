extends Node


func _enter_tree() -> void:
	_define_action(&"move_up", [KEY_W, KEY_UP])
	_define_action(&"move_down", [KEY_S, KEY_DOWN])
	_define_action(&"move_left", [KEY_A, KEY_LEFT])
	_define_action(&"move_right", [KEY_D, KEY_RIGHT])
	_define_action(&"interact", [KEY_E])
	_define_action(&"hide", [KEY_H])
	_define_action(&"toggle_dev_menu", [KEY_F3, KEY_QUOTELEFT, KEY_F1])


func _define_action(action: StringName, key_codes: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var events := InputMap.action_get_events(action)
	for key_code in key_codes:
		var found := false
		for event in events:
			if event is InputEventKey and event.physical_keycode == key_code:
				found = true
				break
		if found:
			continue
		var key_event := InputEventKey.new()
		key_event.physical_keycode = key_code
		InputMap.action_add_event(action, key_event)
