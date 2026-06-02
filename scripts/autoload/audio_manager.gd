extends Node

const SFX_PATHS: Dictionary = {
	"drag_pickup": "",
	"drag_hover": "",
	"drop_success": "",
	"drop_fail": "",
	"stat_up": "",
	"stat_down": "",
	"quest_complete": "",
	"ledger_unlock": "",
	"era_transition": "",
}

const MUSIC_VOLUME_DB: float = -8.0
const SFX_VOLUME_DB: float = -4.0
const MAX_CONCURRENT_SFX: int = 8

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _cache: Dictionary = {}
var _muted: bool = false


func _ready() -> void:
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


func play_music(path: String) -> void:
	if _muted:
		_music_player.stop()
		return
	if path.is_empty():
		_music_player.stop()
		return
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func set_muted(value: bool) -> void:
	_muted = value
	if _muted:
		_music_player.stop()
