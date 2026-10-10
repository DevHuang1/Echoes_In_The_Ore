extends SceneTree

const SOURCE_PATH := "res://art/overview/asteria_space_backdrop_source_hires.png"
const OUTPUT_DIR := "res://art/overview/space_frames"
const FRAME_COUNT := 40
const PIXELS_PER_FRAME := 3


func _initialize() -> void:
	call_deferred("_build_frames")


func _build_frames() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	if source == null or source.is_empty():
		push_error("Could not load space backdrop source: %s" % SOURCE_PATH)
		quit(1)
		return

	source.convert(Image.FORMAT_RGBA8)
	var output_directory := ProjectSettings.globalize_path(OUTPUT_DIR)
	var directory_error := DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_error != OK:
		push_error("Could not create space frame directory: %s" % output_directory)
		quit(1)
		return

	for index in range(FRAME_COUNT):
		var offset := Vector2i(index * PIXELS_PER_FRAME, 0)
		var frame := _shift_wrapped(source, offset)
		var frame_path := "%s/asteria_space_backdrop_%02d.jpg" % [output_directory, index]
		var save_error := frame.save_jpg(frame_path, 0.94)
		if save_error != OK:
			push_error("Could not save space frame: %s" % frame_path)
			quit(1)
			return

	print("Built %d space backdrop frames at %dx%d, drifting right %d px per frame." % [FRAME_COUNT, source.get_width(), source.get_height(), PIXELS_PER_FRAME])
	quit()


func _shift_wrapped(source: Image, requested_offset: Vector2i) -> Image:
	var width := source.get_width()
	var height := source.get_height()
	var offset_x := posmod(requested_offset.x, width)
	var offset_y := posmod(requested_offset.y, height)
	var left_width := width - offset_x
	var top_height := height - offset_y
	var shifted := Image.create(width, height, false, Image.FORMAT_RGBA8)

	_blit_if_nonempty(shifted, source, Rect2i(0, 0, left_width, top_height), Vector2i(offset_x, offset_y))
	_blit_if_nonempty(shifted, source, Rect2i(left_width, 0, offset_x, top_height), Vector2i(0, offset_y))
	_blit_if_nonempty(shifted, source, Rect2i(0, top_height, left_width, offset_y), Vector2i(offset_x, 0))
	_blit_if_nonempty(shifted, source, Rect2i(left_width, top_height, offset_x, offset_y), Vector2i.ZERO)
	return shifted


func _blit_if_nonempty(destination: Image, source: Image, source_rect: Rect2i, target: Vector2i) -> void:
	if source_rect.size.x > 0 and source_rect.size.y > 0:
		destination.blit_rect(source, source_rect, target)
