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
# Volumi lineari 0..1 (slider del Menu Opzioni); applicati come offset sui dB base.
var _music_vol: float = 0.8
var _sfx_vol: float = 0.85
# Video (Menu Opzioni): persistiti e applicati all'avvio.
var _fullscreen: bool = false
var _win_size: Vector2i = Vector2i.ZERO   # (0,0) = non forzare


func _ready() -> void:
	_load_settings()
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Master"
	add_child(_music_player)
	for i in MAX_CONCURRENT_SFX:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "Sfx_%d" % i
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)
	_applica_volumi()
	_applica_video()
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


# --- Volumi (Menu Opzioni) --------------------------------------------------

func _vol_db(lin: float, base: float) -> float:
	if lin <= 0.001:
		return -60.0
	return base + linear_to_db(lin)


func _applica_volumi() -> void:
	if _music_player != null:
		_music_player.volume_db = _vol_db(_music_vol, MUSIC_VOLUME_DB)
	for p in _sfx_pool:
		p.volume_db = _vol_db(_sfx_vol, SFX_VOLUME_DB)


func set_music_volume(v: float) -> void:
	_music_vol = clampf(v, 0.0, 1.0)
	_applica_volumi()
	_save_settings()


func set_sfx_volume(v: float) -> void:
	_sfx_vol = clampf(v, 0.0, 1.0)
	_applica_volumi()
	_save_settings()


func music_volume() -> float:
	return _music_vol


func sfx_volume() -> float:
	return _sfx_vol


# --- Video (Menu Opzioni) ---------------------------------------------------

func _applica_video() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if _fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if not _fullscreen and _win_size.x > 0:
		DisplayServer.window_set_size(_win_size)
		var screen: Vector2i = DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen - _win_size) / 2)


func set_fullscreen(value: bool) -> void:
	_fullscreen = value
	_applica_video()
	_save_settings()


func is_fullscreen() -> bool:
	return _fullscreen


func set_resolution(size: Vector2i) -> void:
	_win_size = size
	if not _fullscreen:
		_applica_video()
	_save_settings()


func resolution() -> Vector2i:
	return _win_size


# --- Difficoltà (preferenza di gioco, persistita come volume/video) ---------
# 0 = Spirito sereno (perdona) · 1 = Equilibrato (default, è il balance di riferimento
# dei tool) · 2 = Implacabile (duro). Incide sulla minaccia dell'Assedio e sull'HP del
# villaggio; l'Equilibrato lascia tutto a ×1.0 → non tocca il bilanciamento verificato.
var _difficolta: int = 1
const DIFFICOLTA_NOMI: Array[String] = ["Spirito sereno", "Equilibrato", "Implacabile"]
const DIFFICOLTA_DESCR: Array[String] = [
	"Nemici più deboli, villaggio più resistente. Per godersi la storia.",
	"L'equilibrio pensato dagli autori. La sfida giusta.",
	"Nemici più forti, villaggio più fragile. Per chi vuole sudare.",
]


func difficolta() -> int:
	return _difficolta


func difficolta_nome() -> String:
	return DIFFICOLTA_NOMI[clampi(_difficolta, 0, 2)]


func set_difficolta(d: int) -> void:
	_difficolta = clampi(d, 0, 2)
	_save_settings()


# Fattore di minaccia dell'Assedio (scala HP/danno nemici + boss). Equilibrato = 1.0.
func difficolta_minaccia() -> float:
	return [0.82, 1.0, 1.26][clampi(_difficolta, 0, 2)]


# Fattore HP del villaggio nell'Assedio (inverso: facile = più resistente). Equilibrato = 1.0.
func difficolta_villaggio() -> float:
	return [1.18, 1.0, 0.9][clampi(_difficolta, 0, 2)]


# --- Persistenza ------------------------------------------------------------

func _load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	_muted = cfg.get_value("audio", "muted", false)
	_music_vol = float(cfg.get_value("audio", "music_vol", _music_vol))
	_sfx_vol = float(cfg.get_value("audio", "sfx_vol", _sfx_vol))
	_fullscreen = bool(cfg.get_value("video", "fullscreen", false))
	var w: int = int(cfg.get_value("video", "win_w", 0))
	var h: int = int(cfg.get_value("video", "win_h", 0))
	_win_size = Vector2i(w, h)
	_difficolta = clampi(int(cfg.get_value("gameplay", "difficolta", 1)), 0, 2)


func _save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "muted", _muted)
	cfg.set_value("audio", "music_vol", _music_vol)
	cfg.set_value("audio", "sfx_vol", _sfx_vol)
	cfg.set_value("video", "fullscreen", _fullscreen)
	cfg.set_value("video", "win_w", _win_size.x)
	cfg.set_value("video", "win_h", _win_size.y)
	cfg.set_value("gameplay", "difficolta", _difficolta)
	cfg.save(SETTINGS_PATH)
