extends Node
## Plays sound effects, wind ambience, and background music tracks.

const SFX_POOL_SIZE: int = 8

const SFX_FILES: Dictionary = {
	&"ui_click": "res://assets/audio/ui_click.wav",
	&"snow_step": "res://assets/audio/snow_step.wav",
	&"step": "res://assets/audio/snow_step.wav",
	&"jump": "res://assets/audio/jump.wav",
	&"land": "res://assets/audio/land.wav",
	&"ice_crack": "res://assets/audio/ice_crack.wav",
	&"pickup": "res://assets/audio/pickup.wav",
	&"sort_ok": "res://assets/audio/sort_ok.wav",
	&"sort_bad": "res://assets/audio/sort_bad.wav",
	&"choice": "res://assets/audio/pickup.wav",
}

const MUSIC_FILES: Dictionary = {
	&"calm": "res://assets/audio/calm_music.wav",
	&"calm_music": "res://assets/audio/calm_music.wav",
	&"music": "res://assets/audio/calm_music.wav",
}

const SFX_VOLUME_OFFSET: Dictionary = {
	&"snow_step": -12.0,
	&"step": -12.0,
}

const AMBIENCE_FILES: Dictionary = {
	&"wind": "res://assets/audio/wind_ambience.wav",
	&"wind_ambience": "res://assets/audio/wind_ambience.wav",
	&"ambience": "res://assets/audio/wind_ambience.wav",
}

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer

var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _ambience_streams: Dictionary = {}


func _ready() -> void:
	_init_players()
	_load_streams()
	if EventBus != null:
		EventBus.chapter_started.connect(_on_chapter_started)
		EventBus.game_ended.connect(_on_game_ended)
	# Start background lo-fi music; background noise/wind removed for clean chill atmosphere
	play_music(&"calm")


func _init_players() -> void:
	var sfx_bus: StringName = &"SFX" if AudioServer.get_bus_index(&"SFX") >= 0 else &"Master"
	var music_bus: StringName = &"Music" if AudioServer.get_bus_index(&"Music") >= 0 else &"Master"
	var amb_bus: StringName = &"Ambience" if AudioServer.get_bus_index(&"Ambience") >= 0 else &"Master"

	for i in range(SFX_POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "SfxPlayer_%d" % i
		p.bus = sfx_bus
		p.volume_db = -8.0
		add_child(p)
		_sfx_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = music_bus
	_music_player.volume_db = -1.0
	add_child(_music_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = amb_bus
	_ambience_player.volume_db = -80.0
	add_child(_ambience_player)


func _load_streams() -> void:
	for key: StringName in SFX_FILES.keys():
		var path: String = SFX_FILES[key]
		if ResourceLoader.exists(path):
			_sfx_streams[key] = ResourceLoader.load(path)

	for key: StringName in MUSIC_FILES.keys():
		var path: String = MUSIC_FILES[key]
		if ResourceLoader.exists(path):
			var stream: AudioStream = ResourceLoader.load(path)
			_configure_loop(stream)
			_music_streams[key] = stream

	for key: StringName in AMBIENCE_FILES.keys():
		var path: String = AMBIENCE_FILES[key]
		if ResourceLoader.exists(path):
			var stream: AudioStream = ResourceLoader.load(path)
			_configure_loop(stream)
			_ambience_streams[key] = stream


func _configure_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav: AudioStreamWAV = stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)


## Plays a sound effect registered under key with optional volume offset.
func play_sfx(key: StringName, volume_offset_db: float = 0.0) -> void:
	if not _sfx_streams.has(key):
		return
	var stream: AudioStream = _sfx_streams[key] as AudioStream
	if stream == null or _sfx_players.is_empty():
		return

	# Find an idle player or cycle round robin
	var player: AudioStreamPlayer = null
	for p: AudioStreamPlayer in _sfx_players:
		if not p.playing:
			player = p
			break
	if player == null:
		player = _sfx_players[_sfx_cursor]
		_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()

	var base_db: float = -8.0
	var offset: float = float(SFX_VOLUME_OFFSET.get(key, 0.0)) + volume_offset_db
	player.volume_db = base_db + offset
	player.stream = stream
	player.play()


## Plays a music stream registered under key.
func play_music(key: StringName = &"calm") -> void:
	if not _music_streams.has(key):
		return
	var stream: AudioStream = _music_streams[key] as AudioStream
	if stream == null:
		return
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.play()


## Stops background music playback.
func stop_music() -> void:
	if _music_player != null and _music_player.playing:
		_music_player.stop()


## Plays ambient background sound registered under key (disabled for clean chill lofi audio).
func play_ambience(_key: StringName = &"wind") -> void:
	return


## Stops ambience playback.
func stop_ambience() -> void:
	if _ambience_player != null and _ambience_player.playing:
		_ambience_player.stop()


func _on_chapter_started(_chapter_id: StringName) -> void:
	play_music(&"calm")


func _on_game_ended(_ending_id: StringName) -> void:
	stop_ambience()
