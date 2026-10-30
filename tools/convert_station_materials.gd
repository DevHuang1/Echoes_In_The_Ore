extends SceneTree
## Rebuilds standalone textures from the Stations 02 graphic and blank-material
## PNGs. ImageTexture resources avoid the compressed-import white-texture issue
## observed in the compatibility renderer; original PNGs remain the source.

const ROOTS := ["res://art/ui/eito/stations02/materials/", "res://art/ui/eito/stations02/graphics/"]

func _initialize() -> void:
	var failed := false
	for root_path in ROOTS:
		for file in DirAccess.get_files_at(root_path):
			if not file.ends_with(".png"): continue
			var image := Image.new()
			var source: String = root_path + file
			var err := image.load(source)
			if err != OK:
				push_error("Image load failed: " + source + ": " + str(err))
				failed = true
				continue
			var texture := ImageTexture.create_from_image(image)
			var target: String = root_path + file.trim_suffix(".png") + ".res"
			err = ResourceSaver.save(texture,target,ResourceSaver.FLAG_COMPRESS)
			if err != OK:
				push_error("Texture save failed: " + target + ": " + str(err))
				failed = true
			else: print(file," ",image.get_size())
	quit(1 if failed else 0)
