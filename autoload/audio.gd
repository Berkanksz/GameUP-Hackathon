extends Node
## Plays sound effects and background music tracks.

var _sfx_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}


func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SfxPlayer"
	add_child(_sfx_player)
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)


## Plays a sound effect registered under key.
func play_sfx(key: StringName) -> void:
	if not _sfx_streams.has(key):
		return
	var stream: AudioStream = _sfx_streams[key] as AudioStream
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.play()


## Plays a music stream registered under key.
func play_music(key: StringName) -> void:
	if not _music_streams.has(key):
		return
	var stream: AudioStream = _music_streams[key] as AudioStream
	if stream == null or _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.play()
