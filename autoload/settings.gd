extends Node
## Manages language selection, audio bus volumes, and user settings persistence.

const CONFIG_PATH: String = "user://settings.cfg"
const SECTION_GENERAL: String = "general"
const SECTION_AUDIO: String = "audio"
const KEY_LANGUAGE: String = "language"
const DEFAULT_LANGUAGE: String = "en"
const SUPPORTED_LANGUAGES: PackedStringArray = ["en", "tr"]
const SILENT_DB: float = -80.0
const MASTER_BASE_ATTENUATION_DB: float = -18.0

var _language: String = DEFAULT_LANGUAGE
var _volumes: Dictionary = {
	&"Master": 1.0,
	&"Music": 1.0,
	&"SFX": 1.0,
	&"Ambience": 1.0,
}
var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	_load_settings()
	for bus_name: StringName in _volumes.keys():
		_apply_bus_volume(bus_name, float(_volumes[bus_name]))


## Sets active locale, persists to user config, and emits language_changed.
func set_language(code: String) -> void:
	var target: String = code if code in SUPPORTED_LANGUAGES else DEFAULT_LANGUAGE
	_language = target
	TranslationServer.set_locale(_language)
	_config.set_value(SECTION_GENERAL, KEY_LANGUAGE, _language)
	_save_settings()
	EventBus.language_changed.emit(_language)


## Returns the current language code.
func get_language() -> String:
	return _language


## Sets linear volume for an audio bus and persists it.
func set_volume(bus: StringName, value: float) -> void:
	var clamped: float = clampf(value, 0.0, 1.0)
	_volumes[bus] = clamped
	_apply_bus_volume(bus, clamped)
	_config.set_value(SECTION_AUDIO, String(bus), clamped)
	_save_settings()


## Returns linear volume for an audio bus.
func get_volume(bus: StringName) -> float:
	return float(_volumes.get(bus, 1.0))


func _load_settings() -> void:
	var err: Error = _config.load(CONFIG_PATH)
	if err == OK:
		var saved_lang: String = str(_config.get_value(SECTION_GENERAL, KEY_LANGUAGE, ""))
		if saved_lang in SUPPORTED_LANGUAGES:
			_language = saved_lang
		elif saved_lang == "":
			var sys_lang: String = OS.get_locale_language()
			_language = sys_lang if sys_lang in SUPPORTED_LANGUAGES else DEFAULT_LANGUAGE
		if _config.has_section(SECTION_AUDIO):
			for key: String in _config.get_section_keys(SECTION_AUDIO):
				var bus_name: StringName = StringName(key)
				var vol: float = clampf(float(_config.get_value(SECTION_AUDIO, key, 1.0)), 0.0, 1.0)
				_volumes[bus_name] = vol
				_apply_bus_volume(bus_name, vol)
	else:
		var sys_lang: String = OS.get_locale_language()
		_language = sys_lang if sys_lang in SUPPORTED_LANGUAGES else DEFAULT_LANGUAGE
	TranslationServer.set_locale(_language)


func _save_settings() -> void:
	var err: Error = _config.save(CONFIG_PATH)
	if err != OK:
		push_warning("Failed to save settings to " + CONFIG_PATH)


func _apply_bus_volume(bus: StringName, linear_value: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	if linear_value <= 0.001:
		AudioServer.set_bus_volume_db(idx, SILENT_DB)
		return
	var curved: float = pow(clampf(linear_value, 0.0, 1.0), 2.0)
	var offset_db: float = MASTER_BASE_ATTENUATION_DB if bus == &"Master" else 0.0
	var db: float = linear_to_db(curved) + offset_db
	AudioServer.set_bus_volume_db(idx, db)
