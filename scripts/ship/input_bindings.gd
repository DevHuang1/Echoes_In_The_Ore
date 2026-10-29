extends Node

var mobile_joystick_vector: Vector2 = Vector2.ZERO
var mobile_shoot_pressed: bool = false
var _landscape_layer: CanvasLayer = null
var _landscape_root: Control = null
var _landscape_dismissed_for_session: bool = false
var _touch_detected: bool = false


func _enter_tree() -> void:
	_define_action(&"move_up", [KEY_W, KEY_UP])
	_define_action(&"move_down", [KEY_S, KEY_DOWN])
	_define_action(&"move_left", [KEY_A, KEY_LEFT])
	_define_action(&"move_right", [KEY_D, KEY_RIGHT])
	_define_action(&"interact", [KEY_E])
	_define_action(&"shoot", [KEY_SPACE])
	_define_action(&"pickup_item", [KEY_E, KEY_F])
	_define_action(&"drop_item", [KEY_G, KEY_Q, KEY_BACKSPACE])
	_define_action(&"toggle_dev_menu", [KEY_F3, KEY_QUOTELEFT, KEY_F1])


func _ready() -> void:
	_enforce_mobile_landscape_orientation()
	_build_landscape_prompt_overlay()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if not _touch_detected:
			_touch_detected = true
			_enforce_mobile_landscape_orientation()
			_on_viewport_size_changed()


func is_mobile_or_touch() -> bool:
	if _touch_detected:
		return true
	if OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		return true
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("web"):
		var js_res: Variant = JavaScriptBridge.eval("(function(){ return ('ontouchstart' in window) || (navigator.maxTouchPoints > 0) || /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent); })()", true)
		if bool(js_res):
			return true
	return false


func set_mobile_joystick_vector(vec: Vector2) -> void:
	mobile_joystick_vector = vec
	Engine.set_meta(&"echoes_mobile_joystick_vec", vec)
	_apply_action_axis(&"move_left", maxf(0.0, -vec.x))
	_apply_action_axis(&"move_right", maxf(0.0, vec.x))
	_apply_action_axis(&"move_up", maxf(0.0, -vec.y))
	_apply_action_axis(&"move_down", maxf(0.0, vec.y))


func _apply_action_axis(action: StringName, strength: float) -> void:
	if strength > 0.12:
		Input.action_press(action, clampf(strength, 0.0, 1.0))
	elif Input.is_action_pressed(action):
		# Only release if no physical keyboard key for this action is currently held
		if not _is_any_action_key_pressed(action):
			Input.action_release(action)


func _is_any_action_key_pressed(action: StringName) -> bool:
	if not InputMap.has_action(action):
		return false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and Input.is_physical_key_pressed(ev.physical_keycode):
			return true
	return false


func _enforce_mobile_landscape_orientation() -> void:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			(function() {
				try {
					if (screen && screen.orientation && screen.orientation.lock) {
						screen.orientation.lock('landscape').catch(function(){});
					}
				} catch (e) {}
			})();
		""", true)


func request_mobile_fullscreen_landscape() -> void:
	_enforce_mobile_landscape_orientation()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			(function() {
				try {
					var el = document.documentElement;
					if (el.requestFullscreen) {
						el.requestFullscreen().then(function() {
							if (screen && screen.orientation && screen.orientation.lock) {
								screen.orientation.lock('landscape').catch(function(){});
							}
						}).catch(function(){});
					} else if (el.webkitRequestFullscreen) {
						el.webkitRequestFullscreen();
					}
				} catch (e) {}
			})();
		""", true)


func _build_landscape_prompt_overlay() -> void:
	_landscape_layer = CanvasLayer.new()
	_landscape_layer.name = "MobileLandscapeEnforcer"
	_landscape_layer.layer = 120
	add_child(_landscape_layer)

	var theme_res: Theme = load("res://themes/ship_pixel_theme.tres") as Theme
	_landscape_root = Control.new()
	_landscape_root.name = "LandscapeOverlayRoot"
	_landscape_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_landscape_root.mouse_filter = Control.MOUSE_FILTER_STOP
	if theme_res != null:
		_landscape_root.theme = theme_res
	_landscape_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_landscape_root.visible = false
	_landscape_layer.add_child(_landscape_root)

	var bg := ColorRect.new()
	bg.color = Color(0.012, 0.024, 0.038, 0.96)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_landscape_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_landscape_root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(360.0, 220.0)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	var badge := Label.new()
	badge.text = "[ MOBILE DISPLAY // LANDSCAPE REQUIRED ]"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 9)
	badge.add_theme_color_override("font_color", Color(1.0, 0.78, 0.38))
	vbox.add_child(badge)

	var title := Label.new()
	title.text = "ROTATE DEVICE SIDEWAYS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.95, 0.92, 0.84))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "Echoes in the Ore is designed for sideways (landscape) widescreen play with dual-thumb touch controls."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(310.0, 0.0)
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_constant_override("line_spacing", 4)
	desc.add_theme_color_override("font_color", Color(0.68, 0.78, 0.82))
	vbox.add_child(desc)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var lock_btn := Button.new()
	lock_btn.text = "[ LOCK LANDSCAPE ]"
	lock_btn.custom_minimum_size = Vector2(160.0, 40.0)
	lock_btn.add_theme_font_size_override("font_size", 10)
	lock_btn.pressed.connect(func():
		request_mobile_fullscreen_landscape()
		_landscape_dismissed_for_session = true
		_landscape_root.visible = false
	)
	btn_row.add_child(lock_btn)

	var cont_btn := Button.new()
	cont_btn.text = "[ CONTINUE ]"
	cont_btn.custom_minimum_size = Vector2(120.0, 40.0)
	cont_btn.add_theme_font_size_override("font_size", 10)
	cont_btn.pressed.connect(func():
		_landscape_dismissed_for_session = true
		_landscape_root.visible = false
	)
	btn_row.add_child(cont_btn)


func _on_viewport_size_changed() -> void:
	if not is_instance_valid(_landscape_root):
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var is_portrait: bool = vp_size.y > vp_size.x
	if not is_portrait:
		_landscape_dismissed_for_session = false
		_landscape_root.visible = false
	elif is_mobile_or_touch() and not _landscape_dismissed_for_session:
		_landscape_root.visible = true


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
