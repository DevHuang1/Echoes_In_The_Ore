extends Node

const TITLE_THEME = preload("res://audio/music/Theme music dubstep.mp3")
const MUSIC_VOLUME_DB := -10.0

var _music_player: AudioStreamPlayer
var _fade_tween: Tween
var _is_title_music_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Master"
	_music_player.volume_db = MUSIC_VOLUME_DB
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)

	get_tree().node_added.connect(_on_node_added)
	call_deferred(&"_check_scene_state")


func play_title_music(fade_in_duration: float = 0.0) -> void:
	if not is_instance_valid(_music_player):
		return

	if TITLE_THEME != null and "loop" in TITLE_THEME:
		TITLE_THEME.set("loop", true)

	if _music_player.stream != TITLE_THEME:
		_music_player.stream = TITLE_THEME

	if is_instance_valid(_fade_tween) and _fade_tween.is_running():
		_fade_tween.kill()

	_is_title_music_active = true

	if fade_in_duration > 0.0:
		_music_player.volume_db = -60.0
		if not _music_player.playing:
			_music_player.play()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_music_player, "volume_db", MUSIC_VOLUME_DB, fade_in_duration)
	else:
		_music_player.volume_db = MUSIC_VOLUME_DB
		if not _music_player.playing:
			_music_player.play()


func stop_music(fade_out_duration: float = 0.0) -> void:
	_is_title_music_active = false
	if not is_instance_valid(_music_player):
		return

	if is_instance_valid(_fade_tween) and _fade_tween.is_running():
		_fade_tween.kill()

	if fade_out_duration > 0.0 and _music_player.playing:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_music_player, "volume_db", -60.0, fade_out_duration)
		_fade_tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()


func is_playing() -> bool:
	return is_instance_valid(_music_player) and _music_player.playing


func _on_music_finished() -> void:
	if _is_title_music_active and is_instance_valid(_music_player):
		_music_player.play()


func _on_node_added(node: Node) -> void:
	if node.get_parent() == get_tree().root:
		call_deferred(&"_check_scene_state")


func _check_scene_state() -> void:
	var cur := get_tree().current_scene
	if cur == null:
		return
	if cur.scene_file_path == "res://scenes/ui/landing_screen.tscn":
		play_title_music()
	else:
		stop_music()
