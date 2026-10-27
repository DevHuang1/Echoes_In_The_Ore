extends RefCounted
## Stateless file validation/discovery. No active inventory or progression owner.
const STORY := preload("res://scripts/ship/first_watch_story.gd")
const MODEL := preload("res://scripts/ship/ship_mission_state.gd")
const HUD := preload("res://scripts/ui/walk_hud.gd")
const INDEX := "user://ship_side_missions_story_current.json"
const DEFAULT := "user://ship_side_missions_story_v2.json"
const LEGACY := "user://ship_side_missions_v1.json"

static func allowed(path: String) -> bool:
	return not path.contains("..") and (path.begins_with("user://ship_side_missions") or path.begins_with("res://.godot/mission_validation/"))

static func valid_payload(payload: Dictionary) -> bool:
	if payload.get("format") != "echoes_ship_side" or payload.get("version") not in [1, 2]: return false
	if not payload.get("mission") is Dictionary or not payload.get("inventory") is Dictionary: return false
	var probe = MODEL.new()
	if not probe.restore(payload.mission): return false
	var inventory_probe = HUD.new()
	var inventory_ok: bool = inventory_probe.inventory_valid(payload.inventory)
	inventory_probe.free()
	if not inventory_ok: return false
	for key in ["position", "hide_exit"]:
		if not payload.get(key) is Array or payload[key].size() != 2: return false
		for value in payload[key]:
			if not (value is float or value is int) or not is_finite(float(value)): return false
	for key in ["legacy_completed", "crew_completed"]:
		if not payload.get(key) is Dictionary: return false
		for value in payload[key].values():
			if not value is bool: return false
	if not payload.get("concealed", "") is String: return false
	if payload.version == 2 and payload.has("story"):
		if not payload.story is Dictionary or not STORY.new().restore(payload.story): return false
	return true

static func read(path: String) -> Dictionary:
	if not allowed(path) or not FileAccess.file_exists(path): return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary and valid_payload(value) else {}

static func continue_path() -> String:
	if Engine.has_meta("ship_story_validation_path"):
		var isolated: String = str(Engine.get_meta("ship_story_validation_path"))
		return isolated if isolated.begins_with("res://.godot/mission_validation/") and not read(isolated).is_empty() else ""
	if FileAccess.file_exists(INDEX):
		var pointer: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
		if pointer is Dictionary and pointer.get("path") is String:
			var payload := read(pointer.path)
			if payload.has("story"): return pointer.path
	if read(DEFAULT).has("story"): return DEFAULT
	if not read(LEGACY).is_empty(): return LEGACY
	return ""

static func new_campaign_path() -> String:
	if Engine.has_meta("ship_story_validation_path"):
		var isolated: String = str(Engine.get_meta("ship_story_validation_path"))
		if isolated.begins_with("res://.godot/mission_validation/") and allowed(isolated): return isolated
	if not FileAccess.file_exists(DEFAULT): return DEFAULT
	var stem := "user://ship_side_missions_story_%d" % Time.get_unix_time_from_system()
	var suffix := 0
	while FileAccess.file_exists(stem+"_%d.json" % suffix): suffix += 1
	return stem+"_%d.json" % suffix

static func remember(path: String) -> void:
	if not path.begins_with("user://ship_side_missions_story_"): return
	atomic_write(INDEX, {"path": path})

static func atomic_write(path: String, payload: Dictionary) -> Error:
	if not allowed(path): return ERR_INVALID_PARAMETER
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path+".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t")); file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"), ProjectSettings.globalize_path(path))
