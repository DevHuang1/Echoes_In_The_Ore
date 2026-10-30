extends SceneTree
## Regenerates the shared theme from scripts/ui/eito/eito_theme.gd.
## Run twice (assets are imported between the runs):
##   godot --headless --path . --script res://tools/build_eito_theme.gd -- assets
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/build_eito_theme.gd -- theme
const THEME_BUILDER := preload("res://scripts/ui/eito/eito_theme.gd")
const TARGET := "res://themes/ship_pixel_theme.tres"

func _initialize() -> void:
	var phase: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "theme"
	if phase == "assets":
		THEME_BUILDER.knob_image(false).save_png(ProjectSettings.globalize_path(THEME_BUILDER.KNOB))
		THEME_BUILDER.knob_image(true).save_png(ProjectSettings.globalize_path(THEME_BUILDER.KNOB_HI))
		var fonts: Dictionary = THEME_BUILDER.make_fonts()
		print("body font: ", ResourceSaver.save(fonts.body, THEME_BUILDER.BODY_FONT))
		print("label font: ", ResourceSaver.save(fonts.label, THEME_BUILDER.LABEL_FONT))
	else:
		var built: Theme = THEME_BUILDER.build()
		var existing: Theme = load(TARGET)
		existing.clear()
		existing.merge_with(built)
		existing.default_font = built.default_font
		existing.default_font_size = built.default_font_size
		print("theme: ", ResourceSaver.save(existing, TARGET))
		# Keep the theme's original UID so editor references stay stable.
		var text := FileAccess.get_file_as_string(TARGET)
		if not text.begins_with("[gd_resource type=\"Theme\" format=3 uid="):
			text = text.replace("[gd_resource type=\"Theme\" format=3]", "[gd_resource type=\"Theme\" format=3 uid=\"uid://cojsd52dev885\"]")
			var f := FileAccess.open(TARGET, FileAccess.WRITE); f.store_string(text); f.close()
	quit()
