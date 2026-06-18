extends SiegeEnemy
class_name SiegeBoss

# Boss dell'Assedio (Fase C). Estende il nemico: HP grande (barra dedicata in alto,
# gestita dall'arena), entrata cinematica, e una macchina a stati con 2-3 abilita'
# telegrafate. A meta' HP entra in FURIA (abilita' piu' frequenti). Vedi Docs/11 §6.
#
#   pestone (AoE) — cerchio rosso a terra, poi danno ai difensori nell'area.
#   ruggito       — onda sonora che stordisce i difensori; mitigata da Legge alta.
#   carica        — il boss arretra, poi scatta a sinistra ignorando i bloccatori.
#
# Niente asset richiesto: corpo via _draw, sprite opzionale (…/era<N>/boss.png).

signal abilita_usata(nome: String)
signal furia_entrata

var nome_boss: String = "Il Colosso"
var legge: int = 30                 # mitigazione del Ruggito (impostata dall'arena)
var furia_soglia: float = 0.5

const RAGGIO_PESTONE: float = 160.0
const DASH_MULT: float = 2.7

var _stato: String = "entrata"      # entrata | marcia | telegrafo | dash
var _bt: float = 0.0                # tempo locale del boss
var _abil_t: float = 4.0            # countdown alla prossima abilita'
var _tele_fino: float = 0.0
var _dash_fino: float = 0.0
var _in_furia: bool = false
var _abil_idx: int = 0
var _abil_corrente: String = ""
var _tele_pos: Vector2 = Vector2.ZERO
var _ruggito_r: float = 0.0
var _abilita: Array[String] = ["pestone", "ruggito", "carica"]


func _process(delta: float) -> void:
	if not vivo():
		return
	_bt += delta

	# Respiro: il bestione si solleva e si abbassa di poco (più marcato in furia).
	var resp: float = sin(_bt * 2.1) * (0.04 if _in_furia else 0.025)
	scale = Vector2(1.0 - resp * 0.5, 1.0 + resp)

	# Furia a meta' HP: abilita' piu' frequenti, corpo che vira al rosso.
	if not _in_furia and float(hp) <= float(hp_max) * furia_soglia:
		_in_furia = true
		_abil_t = minf(_abil_t, 1.2)
		furia_entrata.emit()

	match _stato:
		"entrata":
			# Ingresso cinematico (shake/banner li fa l'arena): il boss resta fermo.
			if _bt >= 1.3:
				_stato = "marcia"
				_abil_t = _cooldown_abilita()
			queue_redraw()
			return
		"telegrafo":
			_ruggito_r += delta * 420.0
			if _bt >= _tele_fino:
				_esegui_abilita()
			queue_redraw()
			return
		"dash":
			position.x -= velocita * DASH_MULT * delta
			if position.x <= villaggio_x:
				_arriva()
			if _bt >= _dash_fino:
				_stato = "marcia"
				_abil_t = _cooldown_abilita()
			queue_redraw()
			return
		_:  # marcia
			_abil_t -= delta
			if _abil_t <= 0.0:
				_inizia_telegrafo()
				queue_redraw()
				return
			# Marcia normale (rallentabile, fermata dai bloccatori) ereditata dal nemico.
			super._process(delta)
			queue_redraw()


# Il boss che raggiunge il villaggio fa un danno grande (oltre la barra HP).
func _arriva() -> void:
	arrivato.emit(danno_villaggio)
	queue_free()


func _cooldown_abilita() -> float:
	var base: float = 3.0 if _in_furia else 5.2
	return base + randf_range(-0.4, 0.6)


func _inizia_telegrafo() -> void:
	_abil_corrente = _abilita[_abil_idx % _abilita.size()]
	_abil_idx += 1
	_stato = "telegrafo"
	_ruggito_r = 0.0
	var dur: float = 0.85
	match _abil_corrente:
		"pestone":
			# Mira al difensore piu' vicino al boss; se non c'è, davanti a sé.
			var bersaglio: Vector2 = _difensore_vicino()
			_tele_pos = bersaglio if bersaglio != Vector2.ZERO else global_position + Vector2(-140.0, 0.0)
			dur = 0.9
		"carica":
			dur = 0.7   # arretra e ringhia
		"ruggito":
			dur = 0.7
	_tele_fino = _bt + dur
	if arena != null and arena.has_method("segnala_abilita_boss"):
		arena.segnala_abilita_boss(_abil_corrente)
	AudioManager.play_sfx("drag_hover")


func _esegui_abilita() -> void:
	match _abil_corrente:
		"pestone":
			if arena != null:
				arena.danno_area_difensori(_tele_pos, RAGGIO_PESTONE, 34 if _in_furia else 26)
				arena.fx_esplosione(_tele_pos, RAGGIO_PESTONE)
				arena.scuoti_forte()
			_stato = "marcia"
			_abil_t = _cooldown_abilita()
		"ruggito":
			# Legge alta riduce la durata dello stun (morale del popolo).
			var dur: float = clampf(2.4 - float(legge) / 42.0, 0.7, 2.4)
			if arena != null:
				arena.stordisci_difensori(dur)
				arena.scuoti_forte()
			AudioManager.play_sfx("stat_down")
			_stato = "marcia"
			_abil_t = _cooldown_abilita()
		"carica":
			_stato = "dash"
			_dash_fino = _bt + 1.0
			AudioManager.play_sfx("drop_success")
	abilita_usata.emit(_abil_corrente)


func _difensore_vicino() -> Vector2:
	if arena == null or not arena.has_method("difensori_in_area"):
		return Vector2.ZERO
	var lista: Array = arena.difensori_in_area(global_position, 1300.0)
	var best: Vector2 = Vector2.ZERO
	var best_d: float = INF
	for d in lista:
		if d == null or not is_instance_valid(d):
			continue
		var dist: float = global_position.distance_to(d.global_position)
		if dist < best_d:
			best_d = dist
			best = d.global_position
	return best


func _draw() -> void:
	var r: float = raggio
	# Telegrafo a terra del Pestone (cerchio rosso pulsante nell'area bersaglio).
	if _stato == "telegrafo" and _abil_corrente == "pestone":
		var local: Vector2 = _tele_pos - global_position
		var a: float = 0.40 + 0.28 * sin(_bt * 18.0)
		draw_circle(local, RAGGIO_PESTONE, Color(0.95, 0.22, 0.16, a))
		draw_arc(local, RAGGIO_PESTONE, 0.0, TAU, 48, Color(1.0, 0.5, 0.35, 1.0), 5.0)
		# Mirino interno: rende inequivocabile il punto d'impatto.
		draw_arc(local, RAGGIO_PESTONE * 0.5, 0.0, TAU, 32, Color(1.0, 0.7, 0.4, 0.85), 3.0)
	# Onda del Ruggito.
	if _stato == "telegrafo" and _abil_corrente == "ruggito":
		draw_arc(Vector2.ZERO, _ruggito_r, 0.0, TAU, 48, Color(0.95, 0.85, 0.5, 0.7), 4.0)

	var rear: float = 0.0
	if _stato == "telegrafo" and _abil_corrente == "carica":
		rear = 10.0  # arretra: telegrafo della Carica

	var tinta: Color = Color(1.0, 0.6, 0.55) if _in_furia else Color.WHITE
	if sprite != null:
		var h: float = r * 3.4
		var w: float = h * (float(sprite.get_width()) / float(maxi(sprite.get_height(), 1)))
		draw_texture_rect(sprite, Rect2(-w * 0.5 + rear, -h * 0.82, w, h), false, tinta)
	else:
		# Corpo placeholder: bestia massiccia che guarda a sinistra.
		var body: Color = Color(0.30, 0.16, 0.14).lerp(Color(0.5, 0.12, 0.1), 1.0 if _in_furia else 0.0)
		draw_circle(Vector2(rear, 0.0), r, body)
		draw_arc(Vector2(rear, 0.0), r, 0.0, TAU, 40, Color(0.08, 0.04, 0.04, 0.95), 4.0)
		# Gobba/teschio in alto e zanne verso sinistra.
		draw_circle(Vector2(rear + r * 0.2, -r * 0.55), r * 0.5, body.darkened(0.15))
		draw_line(Vector2(rear - r * 0.7, r * 0.2), Vector2(rear - r * 1.25, -r * 0.1),
			Color(0.92, 0.88, 0.76), 6.0)
		draw_line(Vector2(rear - r * 0.6, r * 0.45), Vector2(rear - r * 1.1, r * 0.35),
			Color(0.92, 0.88, 0.76), 5.0)
		# Occhi che brillano (verso sinistra).
		var eye: Color = Color(1.0, 0.85, 0.3) if not _in_furia else Color(1.0, 0.45, 0.3)
		draw_circle(Vector2(rear - r * 0.45, -r * 0.2), 6.0, eye)
		draw_circle(Vector2(rear - r * 0.2, -r * 0.25), 6.0, eye)
