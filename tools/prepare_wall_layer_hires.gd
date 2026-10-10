extends SceneTree

const WALL_MASK_PATH := "res://art/overview/asteria_overview_walls.png"
const DETAIL_PASS_PATH := "res://art/overview/asteria_overview_walls_detail_pass.png"
const OUTPUT_PATH := "res://art/overview/asteria_overview_walls_2x.png"
const SCALE_FACTOR := 2


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	var wall_mask := Image.load_from_file(ProjectSettings.globalize_path(WALL_MASK_PATH))
	var detail_pass := Image.load_from_file(ProjectSettings.globalize_path(DETAIL_PASS_PATH))
	if wall_mask == null or detail_pass == null:
		push_error("Could not load both source wall images.")
		quit(1)
		return
	if wall_mask.get_size() != detail_pass.get_size():
		push_error("The detail pass must match the original wall-mask dimensions.")
		quit(1)
		return

	wall_mask.convert(Image.FORMAT_RGBA8)
	detail_pass.convert(Image.FORMAT_RGBA8)
	var mask_data := wall_mask.get_data()
	var detail_data := detail_pass.get_data()
	for alpha_offset in range(3, detail_data.size(), 4):
		var alpha := mask_data[alpha_offset]
		detail_data[alpha_offset] = alpha
		if alpha == 0:
			detail_data[alpha_offset - 1] = 0
			detail_data[alpha_offset - 2] = 0
			detail_data[alpha_offset - 3] = 0

	var aligned := Image.create_from_data(
		wall_mask.get_width(),
		wall_mask.get_height(),
		false,
		Image.FORMAT_RGBA8,
		detail_data
	)
	aligned.resize(
		wall_mask.get_width() * SCALE_FACTOR,
		wall_mask.get_height() * SCALE_FACTOR,
		Image.INTERPOLATE_LANCZOS
	)
	var output_path := ProjectSettings.globalize_path(OUTPUT_PATH)
	var error := aligned.save_png(output_path)
	if error != OK:
		push_error("Could not save high-resolution wall layer: %s" % error)
		quit(1)
		return

	print("Saved 2x wall layer: %s (%d x %d)" % [OUTPUT_PATH, aligned.get_width(), aligned.get_height()])
	quit()
