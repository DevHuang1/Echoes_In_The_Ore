extends Node

const MUSIC_TRACKS: Array[AudioStream] = [
	preload("res://audio/music/a_lament_on_erebos.mp3"),
	preload("res://audio/music/Cold-Wake-01-90s-Loop.wav"),
]
const MUSIC_VOLUME_DB := -10.0

var _music_player: AudioStreamPlayer
var _track_index := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Master"
	_music_player.volume_db = MUSIC_VOLUME_DB
	add_child(_music_player)
	_music_player.finished.connect(_play_next_track)
	_play_next_track()


func _play_next_track() -> void:
	if MUSIC_TRACKS.is_empty():
		return

	_track_index = (_track_index + 1) % MUSIC_TRACKS.size()
	_music_player.stream = MUSIC_TRACKS[_track_index]
	_music_player.play()
