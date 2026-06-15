extends Node

const SFX_DIR: String = "res://Assets/audio/sfx/"
const MUSIC_DIR: String = "res://Assets/audio/music/"
const SFX_PATHS: Dictionary = {
	"drag_pickup": "res://Assets/audio/sfx/drag_pickup.ogg",
	"drag_hover": "res://Assets/audio/sfx/drag_hover.ogg",
	"drop_success": "res://Assets/audio/sfx/confirmation.wav",
	"drop_fail": "res://Assets/audio/sfx/drop_fail.ogg",
	"stat_up": "res://Assets/audio/sfx/stat_up.ogg",
	"stat_down": "res://Assets/audio/sfx/conseguenze_negative.wav",
	"quest_complete": "res://Assets/audio/sfx/event_reward.wav",
	"ledger_unlock": "res://Assets/audio/sfx/ledger_unlock.ogg",
	"era_transition": "res://Assets/audio/sfx/era_transition.ogg",
	"ui_click": "res://Assets/audio/sfx/ui_click.mp3",
	"ledger_open": "res://Assets/audio/sfx/ledger_open.wav",
}

const MUSIC_PATHS: Dictionary = {
	"era2": "res://Assets/audio/music/void_crown.mp3",
}

const MUSIC_VOLUME_DB: float = -8.0
const SFX_VOLUME_DB: float = -4.0
const MAX_CONCURRENT_SFX: int = 8
const SETTINGS_PATH: String = "user://settings.cfg"

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _cache: Dictionary = {}
var _muted: bool = false
var _current_music_path: String = ""


func _ready() -> void:
	_load_settings()
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.volume_db = MUSIC_VOLUME_DB
	_music_player.bus = "Master"
	add_child(_music_player)
	for i in MAX_CONCURRENT_SFX:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "Sfx_%d" % i
		p.volume_db = SFX_VOLUME_DB
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)
	Ledger.lore_unlocked.connect(func(_id: String) -> void: play_sfx("ledger_unlock"))
	Ledger.evento_unlocked.connect(func(_id: String) -> void: play_sfx("ledger_unlock"))
	Ledger.artefatto_unlocked.connect(func(_id: String) -> void: play_sfx("ledger_unlock"))


func play_sfx(id: String) -> void:
	if _muted:
		return
	if not SFX_PATHS.has(id):
		return
	var path: String = SFX_PATHS[id]
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = _cache.get(id)
	if stream == null:
		stream = load(path) as AudioStream
		if stream == null:
			return
		_cache[id] = stream
	var player: AudioStreamPlayer = _sfx_pool[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_pool.size()
	player.stream = stream
	player.play()


func play_music_id(id: String) -> void:
	play_music(MUSIC_PATHS.get(id, MUSIC_DIR + id + ".ogg"))


func play_music(path: String) -> void:
	if path == _current_music_path and _music_player != null and _music_player.playing:
		return
	_current_music_path = path
	if _muted or path.is_empty():
		_music_player.stop()
		return
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_current_music_path = ""
	_music_player.stop()


func set_muted(value: bool) -> void:
	_muted = value
	if _muted:
		_music_player.stop()
	elif _current_music_path != "":
		play_music(_current_music_path)
	_save_settings()


func is_muted() -> bool:
	return _muted


func toggle_muted() -> bool:
	set_muted(not _muted)
	return _muted


func _load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	_muted = cfg.get_value("audio", "muted", false)


func _save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "muted", _muted)
	cfg.save(SETTINGS_PATH)
