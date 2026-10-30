class_name ThadingyutMemoryCutscene
extends CanvasLayer

signal finished

const MEMORY_IMAGE := preload("res://art/storyboards/thura_earth/09_thadingyut_star_memory.png")
const MEMORY_IMAGES := [
	MEMORY_IMAGE,
	preload("res://art/storyboards/thura_earth/10_thadingyut_sparkler_closeup.png"),
	preload("res://art/storyboards/thura_earth/11_thadingyut_star_lesson.png"),
]
const TYPEWRITER_SPEED := 38.0
const SHOT_DURATION := 9.75
const DIALOGUE := [
	{"speaker": "THURA", "text": "Ma, why does that star keep shining?"},
	{"speaker": "MOTHER", "text": "Its light has travelled a long way to find us."},
	{"speaker": "THURA", "text": "When I grow up, I want to see where it began."},
]

var _image_motion: Control
var _story_frames: Array[TextureRect] = []
var _subtitle_label: Label
var _speaker_label: Label
var _next_button: Button
var _fade_overlay: ColorRect
var _line_index := 0
var _typed_progress := 0.0
var _shot_remaining := SHOT_DURATION
var _current_frame := 0
var _is_typing := true
var _is_fading := false


func _ready() -> void:
	layer = 30
	_build_ui()
	_show_line(0)
	_start_camera_motion()
	_fade_overlay.color = Color.BLACK
	var fade_in := create_tween()
	fade_in.tween_property(_fade_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), 0.8).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	if _is_fading:
		return
	if _is_typing:
		_type_line(delta)
	_shot_remaining -= delta
	if _shot_remaining <= 0.0:
		if _line_index < DIALOGUE.size() - 1:
			var next_index := _line_index + 1
			_transition_to_frame(next_index)
			_show_line(next_index)
		else:
			_finish()


func _mark_handled() -> void:
	if is_inside_tree() and get_viewport() != null:
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]:
			_advance()
			_mark_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		_mark_handled()
	elif event is InputEventScreenTouch and event.pressed:
		_advance()
		_mark_handled()


func _build_ui() -> void:
	var screen := Control.new()
	screen.name = "MemoryCutscene"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.clip_contents = true
	add_child(screen)

	_image_motion = Control.new()
	_image_motion.name = "SlowZoomAndShake"
	_image_motion.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image_motion.pivot_offset = get_viewport().get_visible_rect().size * 0.5
	_image_motion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(_image_motion)

	for i in MEMORY_IMAGES.size():
		var picture := TextureRect.new()
		picture.name = "ThadingyutMemoryShot%d" % (i + 1)
		picture.texture = MEMORY_IMAGES[i]
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.modulate.a = 1.0 if i == 0 else 0.0
		_image_motion.add_child(picture)
		_story_frames.append(picture)

	var warm_glow := ColorRect.new()
	warm_glow.color = Color(0.16, 0.065, 0.015, 0.13)
	warm_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	warm_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(warm_glow)

	var title := Label.new()
	title.text = "YANGON  /  THADINGYUT FESTIVAL  /  YEARS BEFORE ASTERIA-1"
	title.anchor_left = 0.045
	title.anchor_top = 0.045
	title.anchor_right = 0.82
	title.anchor_bottom = 0.10
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(1.0, 0.79, 0.46))
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color(0.012, 0.022, 0.035, 0.92))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(title)

	var subtitle_panel := PanelContainer.new()
	subtitle_panel.name = "MemoryDialoguePanel"
	subtitle_panel.anchor_left = 0.025
	subtitle_panel.anchor_top = 0.765
	subtitle_panel.anchor_right = 0.975
	subtitle_panel.anchor_bottom = 0.975
	subtitle_panel.add_theme_stylebox_override("panel", _dialogue_panel_style())
	screen.add_child(subtitle_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	subtitle_panel.add_child(content)
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 12)
	_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.4))
	content.add_child(_speaker_label)

	_subtitle_label = Label.new()
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_subtitle_label.add_theme_font_size_override("font_size", 20)
	_subtitle_label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.92))
	content.add_child(_subtitle_label)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	content.add_child(footer)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	_next_button = Button.new()
	_next_button.text = "[ SPACE / ENTER  › ]"
	_next_button.add_theme_font_size_override("font_size", 13)
	_next_button.pressed.connect(_advance)
	footer.add_child(_next_button)

	_fade_overlay = ColorRect.new()
	_fade_overlay.name = "MemoryFade"
	_fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(_fade_overlay)


func _dialogue_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.025, 0.038, 0.93)
	style.border_color = Color(0.47, 0.53, 0.53, 0.9)
	style.set_border_width_all(2)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 10.0
	return style


func _start_camera_motion() -> void:
	_image_motion.scale = Vector2(1.025, 1.025)
	var zoom := create_tween()
	zoom.tween_property(_image_motion, "scale", Vector2(1.13, 1.13), 30.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var shake := create_tween()
	for offset in [Vector2(2.0, -1.0), Vector2(-3.0, 1.0), Vector2(2.0, 2.0), Vector2(-1.0, -2.0), Vector2.ZERO]:
		shake.tween_property(_image_motion, "position", offset, 0.045)
	shake.tween_property(_image_motion, "position", Vector2.ZERO, 0.08)


func _show_line(index: int) -> void:
	_line_index = index
	_typed_progress = 0.0
	_is_typing = true
	_shot_remaining = SHOT_DURATION
	var line: Dictionary = DIALOGUE[index]
	_speaker_label.text = str(line["speaker"])
	_subtitle_label.text = str(line["text"])
	_subtitle_label.visible_characters = 0
	_next_button.text = "[ SPACE / ENTER  › ]"


func _type_line(delta: float) -> void:
	_typed_progress = minf(_typed_progress + TYPEWRITER_SPEED * delta, float(_subtitle_label.get_total_character_count()))
	_subtitle_label.visible_characters = int(_typed_progress)
	if _subtitle_label.visible_characters >= _subtitle_label.get_total_character_count():
		_is_typing = false
		_next_button.text = "[ RETURN TO PRESENT ]" if _line_index == DIALOGUE.size() - 1 else "[ NEXT  › ]"


func _advance() -> void:
	if _is_fading:
		return
	if _is_typing:
		_is_typing = false
		_subtitle_label.visible_characters = -1
		_next_button.text = "[ RETURN TO PRESENT ]" if _line_index == DIALOGUE.size() - 1 else "[ NEXT  › ]"
		return
	if _line_index < DIALOGUE.size() - 1:
		var next_index := _line_index + 1
		_transition_to_frame(next_index)
		_show_line(next_index)
	else:
		_finish()


func _transition_to_frame(index: int) -> void:
	if index == _current_frame or index < 0 or index >= _story_frames.size():
		return
	var crossfade := create_tween()
	crossfade.set_parallel(true)
	crossfade.tween_property(_story_frames[_current_frame], "modulate:a", 0.0, 0.9).set_trans(Tween.TRANS_SINE)
	crossfade.tween_property(_story_frames[index], "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	_current_frame = index


func _finish() -> void:
	if _is_fading:
		return
	_is_fading = true
	var fade_out := create_tween()
	fade_out.tween_property(_fade_overlay, "color", Color.BLACK, 0.7).set_trans(Tween.TRANS_SINE)
	await fade_out.finished
	finished.emit()
	queue_free()
