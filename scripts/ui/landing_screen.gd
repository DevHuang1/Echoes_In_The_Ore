extends Control

const INTRO_SCENE := "res://scenes/ui/earth_years_montage.tscn"
const HERO_IMAGE := preload("res://art/storyboards/thura_earth/07_astronaut_selected.png")
const FADE_SECONDS := 0.85

var _background: TextureRect
var _start_button: Button
var _fade_overlay: ColorRect


func _ready() -> void:
	_build_screen()
	_start_button.grab_focus()
	_play_ambient_zoom()


func _build_screen() -> void:
	_background = TextureRect.new()
	_background.texture = HERO_IMAGE
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	var scene_tint := ColorRect.new()
	scene_tint.color = Color(0.008, 0.014, 0.025, 0.28)
	scene_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scene_tint)

	var title_panel := ColorRect.new()
	title_panel.anchor_left = 0.57
	title_panel.anchor_top = 0.0
	title_panel.anchor_right = 1.0
	title_panel.anchor_bottom = 1.0
	title_panel.color = Color(0.008, 0.018, 0.033, 0.76)
	title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_panel)

	var content := VBoxContainer.new()
	content.anchor_left = 0.63
	content.anchor_top = 0.16
	content.anchor_right = 0.95
	content.anchor_bottom = 0.85
	content.add_theme_constant_override("separation", 18)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(content)

	var eyebrow := Label.new()
	eyebrow.text = "ASTERIA-1  /  A STORY OF HOME AND DISTANCE"
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.add_theme_color_override("font_color", Color(0.88, 0.70, 0.39))
	eyebrow.add_theme_constant_override("outline_size", 3)
	eyebrow.add_theme_color_override("font_outline_color", Color(0.01, 0.018, 0.03, 0.8))
	content.add_child(eyebrow)

	var title := Label.new()
	title.text = "ECHOES\nIN THE ORE"
	title.add_theme_font_size_override("font_size", 62)
	title.add_theme_color_override("font_color", Color(0.97, 0.95, 0.89))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0.015, 0.025, 0.04, 0.95))
	title.add_theme_constant_override("line_spacing", -5)
	content.add_child(title)

	var tagline := Label.new()
	tagline.text = "Some discoveries are worth leaving behind."
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.add_theme_font_size_override("font_size", 20)
	tagline.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9))
	content.add_child(tagline)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	content.add_child(gap)

	_start_button = Button.new()
	_start_button.text = "START"
	_start_button.custom_minimum_size = Vector2(230, 62)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_start_button.focus_mode = Control.FOCUS_ALL
	_start_button.add_theme_font_size_override("font_size", 21)
	_start_button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
	_start_button.add_theme_color_override("font_hover_color", Color(0.08, 0.07, 0.05))
	_start_button.add_theme_stylebox_override("normal", _button_style(Color(0.07, 0.13, 0.19, 0.92), Color(0.78, 0.61, 0.32)))
	_start_button.add_theme_stylebox_override("hover", _button_style(Color(0.84, 0.68, 0.4, 0.98), Color(0.98, 0.83, 0.57)))
	_start_button.add_theme_stylebox_override("pressed", _button_style(Color(0.62, 0.46, 0.22, 1.0), Color(0.98, 0.83, 0.57)))
	_start_button.add_theme_stylebox_override("focus", _button_style(Color(0.07, 0.13, 0.19, 0.92), Color(0.98, 0.83, 0.57)))
	_start_button.pressed.connect(_on_start_pressed)
	content.add_child(_start_button)

	var footer := Label.new()
	footer.text = "A SCI-FI SURVIVAL HORROR"
	footer.anchor_left = 0.04
	footer.anchor_top = 0.94
	footer.anchor_right = 0.42
	footer.anchor_bottom = 0.985
	footer.add_theme_font_size_override("font_size", 13)
	footer.add_theme_color_override("font_color", Color(0.9, 0.91, 0.9, 0.72))
	add_child(footer)

	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_overlay)


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 26.0
	style.content_margin_right = 26.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


func _play_ambient_zoom() -> void:
	_background.pivot_offset = get_viewport_rect().size * 0.5
	_background.scale = Vector2(1.025, 1.025)
	var zoom_tween := create_tween().set_loops()
	zoom_tween.tween_property(_background, "scale", Vector2(1.065, 1.065), 20.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	zoom_tween.tween_property(_background, "scale", Vector2(1.025, 1.025), 20.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_start_pressed() -> void:
	if _start_button.disabled:
		return
	_start_button.disabled = true
	await _fade_to_black()
	var result := get_tree().change_scene_to_file(INTRO_SCENE)
	if result != OK:
		push_error("Could not open the Earth-years montage: %s" % INTRO_SCENE)
		_start_button.disabled = false
		await _fade_from_black()


func _fade_to_black() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color", Color(0.0, 0.0, 0.0, 1.0), FADE_SECONDS)
	await tween.finished


func _fade_from_black() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), FADE_SECONDS)
	await tween.finished
