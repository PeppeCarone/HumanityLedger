extends Node

# Playtest automatico dell'Assedio: stat realistiche di fine Era 1 + esercito sensato,
# tempo accelerato, registra la timeline e l'esito. Serve a valutare la DIFFICOLTÀ.
# Esegui: godot --headless --path . tools/playtest_assedio.tscn

var _siege: Node = null
var _t: float = 0.0
var _next_log: float = 0.0
var _concluso: String = ""
var _stagger_count: int = 0
var _stagger_prev: bool = false
var _furia: bool = false
var _frenesia: bool = false


func _ready() -> void:
	# QA isolata dallo STATO UTENTE persistente (NG+/difficoltà): solo in memoria, i file
	# in user:// non vengono toccati. Senza questo, un Eone attivo falsa i numeri.
	Ledger.eone = 0
	AudioManager._difficolta = 1
	GameState.reset_run()
	# BUILD MEDIO-FORTE (giocatore bravo): dovrebbe vincere con QUALCHE danno (tensione).
	GameState.militare = 55
	GameState.costruzione = 52
	GameState.scienza = 45
	GameState.spionaggio = 42
	GameState.legge = 45
	GameState.tesoro = 48
	GameState.popolo = 50
	GameState.risorse = 42
	Engine.time_scale = 4.0
	_siege = SiegeArena.new()
	_siege.configura(1)
	add_child(_siege)
	_siege.assedio_concluso.connect(_on_concluso)
	for s in [0, 3, 6]:
		_siege.schiera_unita_test(s, "tiratore")
	for s in [1, 4, 7]:
		_siege.schiera_unita_test(s, "bloccatore")
	_siege.schiera_unita_test(2, "sciamano")
	_siege.schiera_unita_test(5, "totem")
	print("PLAYTEST_START(FORTE) | stat: mil55 cos52 sci45 spi42 leg45 | villaggio_hp_max=", _siege.hp_villaggio_max, " budget=", _siege.risorse)


func _on_concluso(e: String) -> void:
	_concluso = e


func _process(delta: float) -> void:
	_t += delta
	var b: Node = _siege._boss
	var bhp: int = -1
	if b != null and is_instance_valid(b):
		bhp = int(100.0 * float(b.hp) / float(b.hp_max))
		if b._staggerato and not _stagger_prev:
			_stagger_count += 1
			print("  t=%5.1f  >>> STAGGER #%d  (boss %d%%)" % [_t, _stagger_count, bhp])
		_stagger_prev = b._staggerato
		if b._in_furia and not _furia:
			_furia = true
			print("  t=%5.1f  >>> FURIA  (boss %d%%)" % [_t, bhp])
		if b._frenesia and not _frenesia:
			_frenesia = true
			print("  t=%5.1f  >>> FRENESIA  (boss %d%%)" % [_t, bhp])
	if _t >= _next_log:
		_next_log += 4.0
		print("  t=%5.1f  villaggio=%d/%d  boss=%s%%  nemici=%d  risorse=%d" % [
			_t, _siege.hp_villaggio, _siege.hp_villaggio_max, str(bhp), _siege._enemies.size(), _siege.risorse])
	# La schermata d'esito emette `assedio_concluso` solo al clic di "Continua" (assente in
	# headless): se l'arena ha già concluso, deduci l'esito dall'HP del villaggio e riporta.
	if _concluso == "" and _siege._concluso:
		var pct: int = int(100.0 * float(_siege.hp_villaggio) / float(maxi(_siege.hp_villaggio_max, 1)))
		if _siege.hp_villaggio <= 0:
			_concluso = "sopraffatto"
		elif pct >= 100:
			_concluso = "immacolata"
		elif pct >= 40:
			_concluso = "trionfo"
		else:
			_concluso = "fatica"
	if _concluso != "":
		print("PLAYTEST_ESITO=%s | t=%.1f | villaggio_finale=%d/%d (%d%%) | stagger=%d | furia=%s frenesia=%s" % [
			_concluso, _t, _siege.hp_villaggio, _siege.hp_villaggio_max,
			int(100.0 * float(_siege.hp_villaggio) / float(maxi(_siege.hp_villaggio_max, 1))),
			_stagger_count, str(_furia), str(_frenesia)])
		Engine.time_scale = 1.0
		get_tree().quit()
	elif _t > 260.0:   # 6 ondate (F3) richiedono più tempo delle 4 precedenti
		print("PLAYTEST_TIMEOUT | t=%.1f | villaggio=%d | boss=%s%%" % [_t, _siege.hp_villaggio, str(bhp)])
		get_tree().quit()
