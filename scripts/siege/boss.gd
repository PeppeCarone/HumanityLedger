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
signal frenesia_entrata
signal stagger_cambiato(frac: float, vulnerabile: bool)
signal trasforma_entrata   # prima volta sotto furia_soglia: l'arena fa la cinematica (F4)

var _frenesia: bool = false         # 3ª fase sotto il 25% HP: abilità a raffica

# Tenuta / Stagger (Fase strategica): colpirlo riempie la "tenuta"; piena, il boss va in
# VULNERABILE — vacilla, non usa abilità e subisce danno extra. È la finestra di burst che
# premia il focus-fire e lo Spionaggio (che la riempie più in fretta). Vedi Docs/11 §6.
var stagger_max: float = 180.0
var stagger_gain: float = 1.0       # moltiplicatore d'accumulo (Spionaggio alto = punto debole)
const STAGGER_DUR: float = 3.6      # durata della finestra VULNERABILE
const STAGGER_BONUS: float = 2.0    # danno subìto ×n mentre vulnerabile (premia il burst)
const STAGGER_CD: float = 5.5       # pausa prima che la tenuta torni ad accumularsi
const STAGGER_DECAY: float = 2.5    # la tenuta cala lenta: deve poter ingranare col DPS reale
var _stagger: float = 0.0
var _staggerato: bool = false
var _stagger_fino: float = 0.0
var _stagger_cd: float = 0.0

var nome_boss: String = "Il Colosso"
var legge: int = 30                 # mitigazione del Ruggito (impostata dall'arena)
var furia_soglia: float = 0.5
var era_boss: int = 1               # 1 = Colosso (bruto a terra) · 2 = Drago (caster di fuoco)

const RAGGIO_PESTONE: float = 210.0
const DASH_MULT: float = 2.7

var _stato: String = "entrata"      # entrata | marcia | telegrafo | dash
var _bt: float = 0.0                # tempo locale del boss
var _abil_t: float = 4.0            # countdown alla prossima abilita'
var _tele_fino: float = 0.0
var _tele_dur: float = 0.85
var _dash_fino: float = 0.0
var _in_furia: bool = false
var _abil_idx: int = 0
var _abil_corrente: String = ""
var _tele_pos: Vector2 = Vector2.ZERO
var _ruggito_r: float = 0.0
var _pioggia_pts: Array[Vector2] = []   # punti d'impatto della Pioggia di fuoco (globali)
# Kit di abilità per archetipo (impostato da imposta_era):
#   Era 1 — Il Colosso: bruto a terra (pestone ad area + carica che sfonda).
#   Era 2 — Il Drago: caster di fuoco a distanza (soffio sulla corsia + pioggia sparsa).
var _abilita: Array[String] = ["pestone", "ruggito", "carica"]

# Cambio fase cinematografico (Fase F4, Docs/14 §5): alla PRIMA discesa sotto furia_soglia il
# boss si TRASFORMA (cinematica hitstop/zoom dall'arena), diventa più forte e scatena l'ULTIMATE.
# Poi l'ultimate torna a cadenza CRESCENTE e potenza CALANTE (anti-ripetizione). Per tutto lo
# scontro evoca un esercito di rinforzi (§4).
var _trasformato: bool = false
var _trasf_fino: float = 0.0
var _ult_t: float = 0.0
var _ult_usata: int = 0
var _evoca_t: float = 6.0
const TRASF_DUR: float = 1.4        # durata dell'animazione di trasformazione (tempo locale)
const EVOCA_BOSS_CD: float = 11.0   # ogni quanto il boss chiama rinforzi (meno add = boss focalizzabile)
const ULT_POT_BASE: int = 46        # potenza base dell'ultimate (cala POCO a ogni uso)

# Sistema a FASI (idea utente): il boss attraversa FASI fasi, ognuna con la SUA barra HP piena.
# Svuotata una fase (non l'ultima) NON muore: intermezzo cinematografico (INVULNERABILE, i nemici
# spariscono), poi rientra più grande, con HP pieni e abilità/stat potenziate.
const FASI: int = 3
var _fase: int = 1
var _invulnerabile: bool = false
var _berserk: bool = false           # dopo ~60s: avanza imbloccabile E incassa ×2.5 → conclude sempre
var _spawn_x: float = 1800.0         # lato di spawn: il boss vi RITORNA a ogni cambio fase


# Sceglie il kit e la messa a punto in base all'era (chiamato dall'arena prima di add_child).
func imposta_era(e: int) -> void:
	era_boss = e
	if e >= 2:
		_abilita = ["soffio", "ruggito", "pioggia"]   # Drago: fuoco a distanza
		furia_soglia = 0.45
	else:
		_abilita = ["pestone", "ruggito", "carica"]   # Colosso: mischia/sfondamento
		furia_soglia = 0.5


func _process(delta: float) -> void:
	if not vivo():
		return
	_bt += delta

	# Anti-stallo: se il fight si trascina (build che murano il boss fuori dal raggio dei ranged),
	# dopo ~60s il boss va BERSERK — imbloccabile, avanza dritto al villaggio → la battaglia
	# conclude SEMPRE (o lo fermi, o arriva). Evita lo stallo "villaggio 100% ma boss vivo".
	if not _berserk and _bt > 60.0:
		_berserk = true
		_frenesia = true
		_in_furia = true

	# Tenuta: cooldown dopo una rottura, oppure decadimento se smetti di colpirlo.
	if _stagger_cd > 0.0:
		_stagger_cd -= delta
	elif not _staggerato and _stagger > 0.0:
		_stagger = maxf(0.0, _stagger - STAGGER_DECAY * delta)
		_notifica_stagger()

	# Respiro: il bestione si solleva e si abbassa di poco (più marcato in furia).
	if not _staggerato:
		var resp: float = sin(_bt * 2.1) * (0.04 if _in_furia else 0.025)
		scale = Vector2(1.0 - resp * 0.5, 1.0 + resp)

	# Le fasi NON scattano più su soglia HP: scattano quando la barra della fase si SVUOTA
	# (in subisci_danno → _cambia_fase). _in_furia/_frenesia li imposta _completa_cambio_fase.

	match _stato:
		"entrata":
			# Ingresso cinematico (shake/banner li fa l'arena): il boss resta fermo.
			if _bt >= 1.3:
				_stato = "marcia"
				_abil_t = _cooldown_abilita()
			queue_redraw()
			return
		"stagger":
			# VULNERABILE: vacilla sul posto, non agisce. Finestra di burst per il giocatore.
			var w: float = sin(_bt * 30.0) * 0.05
			scale = Vector2(1.0 + w, 1.0 - w)
			if _bt >= _stagger_fino:
				_staggerato = false
				_stagger = 0.0
				_stagger_cd = STAGGER_CD
				_stato = "marcia"
				_abil_t = _cooldown_abilita()
				_notifica_stagger()
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
			# Contromossa: un BLOCCATORE sulla sua banda FERMA la Carica (ci si schianta
			# contro). Sfonda il muro ma il villaggio è salvo: leggere il telegrafo e tenere
			# la linea bloccata è la difesa giusta.
			if arena != null:
				var muro: Node = arena.cerca_blocco(global_position)
				if muro != null and position.x > muro.global_position.x and position.x - muro.global_position.x <= 64.0:
					muro.subisci_danno(70)
					arena.scuoti_forte()
					modulate = Color(1.5, 1.2, 1.1)
					var tw: Tween = create_tween()
					tw.tween_property(self, "modulate", Color.WHITE, 0.25)
					_stato = "marcia"
					_abil_t = _cooldown_abilita()
					queue_redraw()
					return
			if position.x <= villaggio_x:
				_arriva()
			if _bt >= _dash_fino:
				_stato = "marcia"
				_abil_t = _cooldown_abilita()
			queue_redraw()
			return
		"trasforma":
			# INTERMEZZO di cambio fase: INVULNERABILE, ribolle e CRESCE sul posto mentre l'arena
			# fa la cinematica e fa sparire i nemici. Poi rientra in fase nuova (HP pieni, più grande).
			var g: float = (1.0 + 0.05 * float(_fase)) + 0.16 * sin(_bt * 14.0)
			scale = Vector2(g, g)
			if _bt >= _trasf_fino:
				_completa_cambio_fase()
			queue_redraw()
			return
		_:  # marcia
			# Evoca rinforzi durante tutto lo scontro (§4).
			_evoca_t -= delta
			if _evoca_t <= 0.0:
				# MOLTI più nemici e più spesso a ogni fase (fase 2-3 = ondate fitte).
				_evoca_t = EVOCA_BOSS_CD * (0.5 if _frenesia else (0.68 if _in_furia else 1.0))
				if arena != null and arena.has_method("evoca_rinforzi_boss"):
					arena.evoca_rinforzi_boss(2 + era_boss + _fase * 2)
			# Ultimate periodica dopo la trasformazione (potenza calante, cadenza crescente).
			if _trasformato:
				_ult_t -= delta
				if _ult_t <= 0.0:
					_cast_ultimate()
					_ult_t = _ult_cooldown()
			_abil_t -= delta
			if _abil_t <= 0.0:
				_inizia_telegrafo()
				queue_redraw()
				return
			# Marcia: normalmente fermata dai bloccatori. In FRENESIA (fase 3) il boss IGNORA i
			# bloccatori e avanza dritto → niente stallo, climax "fermalo prima che arrivi al villaggio".
			if _frenesia:
				position.x -= velocita * delta
				if position.x <= villaggio_x:
					_arriva()
			else:
				super._process(delta)
			queue_redraw()


# Il boss che raggiunge il villaggio fa un danno grande (oltre la barra HP).
func _arriva() -> void:
	arrivato.emit(danno_villaggio)
	queue_free()


# Override: il danno riempie la tenuta; durante la finestra VULNERABILE il boss incassa ×n.
func subisci_danno(d: int) -> void:
	# INVULNERABILE durante l'intermezzo di cambio fase e l'entrata → niente one-shot.
	if _invulnerabile or _stato == "trasforma" or _stato == "entrata":
		return
	var dmg: int = d
	if _staggerato:
		dmg = int(round(float(d) * STAGGER_BONUS))
	elif _stagger_cd <= 0.0:
		_stagger = minf(stagger_max, _stagger + float(d) * stagger_gain)
		if _stagger >= stagger_max:
			_entra_stagger()
	if _berserk:
		dmg = int(round(float(dmg) * 2.5))   # berserk: incassa molto di più → la battaglia conclude
	_notifica_stagger()
	if arena != null and arena.has_method("fx_numero_danno"):
		arena.fx_numero_danno(global_position, dmg, _staggerato)
	# Se questo colpo SVUOTA la barra della fase corrente e non è l'ultima → CAMBIO FASE (non muore).
	if hp - dmg <= 0 and _fase < FASI:
		hp = 1
		_notifica_stagger()
		_cambia_fase()
		return
	super.subisci_danno(dmg)


func _entra_stagger() -> void:
	_staggerato = true
	_stagger_fino = _bt + STAGGER_DUR
	_stato = "stagger"
	scale = Vector2(1.14, 0.84)
	if arena != null and arena.has_method("segnala_stagger"):
		arena.segnala_stagger(nome_boss)
	if arena != null and arena.has_method("scuoti_forte"):
		arena.scuoti_forte()
	if arena != null and arena.has_method("hitstop"):
		arena.hitstop(0.10, 0.05)   # la rottura della tenuta "schiocca" (juice)
	if arena != null and arena.has_method("fx_esplosione"):
		arena.fx_esplosione(global_position, 150.0)   # onda d'urto: la rottura è "guadagnata"
	AudioManager.play_sfx("stat_down")


func _notifica_stagger() -> void:
	stagger_cambiato.emit(clampf(_stagger / maxf(stagger_max, 1.0), 0.0, 1.0), _staggerato)


func _cooldown_abilita() -> float:
	var base: float = 1.2 if _frenesia else (1.9 if _in_furia else 2.8)
	return base + randf_range(-0.25, 0.45)


# Prima volta sotto furia_soglia: entra nello stato "trasforma" (l'arena fa la cinematica).
func _cambia_fase() -> void:
	_invulnerabile = true
	_stato = "trasforma"
	_trasf_fino = _bt + TRASF_DUR + 0.5
	AudioManager.play_sfx("stat_down")
	if arena != null and arena.has_method("intermezzo_fase"):
		arena.intermezzo_fase(self, _fase + 1)


# Fine dell'intermezzo: NUOVA fase con barra HP PIENA, boss più grande, stat e abilità potenziate.
func _completa_cambio_fase() -> void:
	_fase += 1
	_trasformato = true
	_invulnerabile = false
	hp = hp_max                                   # barra NUOVA, piena
	raggio *= 1.22                                # più grande a ogni fase
	danno_villaggio = int(round(float(danno_villaggio) * 1.3))
	danno_melee = int(round(float(danno_melee) * 1.3))
	velocita *= 1.08
	scale = Vector2.ONE
	# Riparte DALL'INIZIO: torna al lato di spawn e rimarcia (round nuovo per la fase).
	position.x = _spawn_x
	_engaged = null
	_in_furia = _fase >= 2                         # fase 2 = furia (abilità più frequenti)
	_frenesia = _fase >= 3                         # fase 3 = frenesia (a raffica)
	# Sprite della fase, se esiste (es. drago boss_fase2 / boss_fase3).
	if arena != null and arena.has_method("_siege_tex"):
		var tex2: Texture2D = arena._siege_tex("boss_fase%d" % _fase)
		if tex2 != null:
			sprite = tex2
	# Ondata di rinforzi SUBITO all'inizio della nuova fase.
	if arena != null and arena.has_method("evoca_rinforzi_boss"):
		arena.evoca_rinforzi_boss(4 + _fase * 3)
	_stato = "marcia"
	_abil_t = 0.8                                  # casta quasi subito nella fase nuova
	_ult_t = 1.8


# Scatena l'ultimate del boss (devastazione a tutto campo, gestita dall'arena per archetipo).
# Potenza CALANTE a ogni uso: non si può vincere per ripetizione.
func _cast_ultimate() -> void:
	var pot: int = int(round(float(ULT_POT_BASE) * pow(0.88, float(_ult_usata))))
	_ult_usata += 1
	if arena != null and arena.has_method("boss_ultimate"):
		arena.boss_ultimate(era_boss, maxi(18, pot), global_position)


# Cadenza dell'ultimate: cresce a ogni uso (anti-ripetizione).
func _ult_cooldown() -> float:
	return 9.0 + 3.0 * float(_ult_usata)


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
		"soffio":
			dur = 0.95  # il Drago inspira, poi sputa la lingua di fuoco sulla corsia
		"pioggia":
			_pioggia_pts = _scegli_punti_pioggia(3)
			dur = 1.0
	_tele_dur = dur
	_tele_fino = _bt + dur
	if arena != null and arena.has_method("segnala_abilita_boss"):
		arena.segnala_abilita_boss(_abil_corrente)
	AudioManager.play_sfx("drag_hover")


func _esegui_abilita() -> void:
	match _abil_corrente:
		"pestone":
			if arena != null:
				arena.danno_area_difensori(_tele_pos, RAGGIO_PESTONE, 58 if _in_furia else 44)
				arena.fx_vfx(_tele_pos, RAGGIO_PESTONE * 2.4, "impatto_terra", true)
				arena.fx_esplosione(_tele_pos, RAGGIO_PESTONE)
				arena.scuoti_forte()
				arena.hitstop(0.06, 0.2)
			_stato = "marcia"
			_abil_t = _cooldown_abilita()
		"ruggito":
			# Legge alta riduce la durata dello stun (morale del popolo).
			var dur: float = clampf(2.4 - float(legge) / 42.0, 0.8, 2.4)
			if arena != null:
				arena.stordisci_difensori(dur)
				var cen: Vector2 = global_position + Vector2(-260.0, 0.0)
				arena.danno_area_difensori(cen, 320.0, 26 if _in_furia else 18)
				arena.fx_vfx(global_position + Vector2(-120.0, 0.0), 640.0, "onda_ruggito", false)
				arena.scuoti_forte()
				arena.hitstop(0.05, 0.2)
			AudioManager.play_sfx("stat_down")
			_stato = "marcia"
			_abil_t = _cooldown_abilita()
		"carica":
			_stato = "dash"
			_dash_fino = _bt + 1.0
			AudioManager.play_sfx("drop_success")
		"soffio":
			# Lingua di fuoco lungo la corsia: colpisce i difensori in una banda davanti
			# al Drago (a distanza, senza doverli raggiungere — il contrario del Colosso).
			if arena != null:
				var dmg: int = 52 if _in_furia else 38
				for off in [160.0, 340.0, 520.0, 700.0, 880.0, 1060.0]:
					var p: Vector2 = Vector2(global_position.x - off, global_position.y)
					arena.danno_area_difensori(p, 110.0, dmg)
				arena.fx_vfx(global_position + Vector2(-560.0, 0.0), 1180.0, "fiammata_drago", false)
				arena.scuoti_forte()
				arena.hitstop(0.05, 0.2)
			AudioManager.play_sfx("stat_down")
			_stato = "marcia"
			_abil_t = _cooldown_abilita()
		"pioggia":
			# Pioggia di fuoco: piu' impatti sparsi sul campo (area denial diffuso).
			if arena != null:
				var dmg2: int = 42 if _in_furia else 30
				for p in _pioggia_pts:
					arena.danno_area_difensori(p, 110.0, dmg2)
					arena.fx_vfx(p, 230.0, "fire_burst", true)
				arena.scuoti_forte()
			_pioggia_pts.clear()
			_stato = "marcia"
			_abil_t = _cooldown_abilita()
	abilita_usata.emit(_abil_corrente)


# Sceglie n punti d'impatto per la Pioggia: prima sui difensori, poi punti casuali sul
# campo davanti al Drago (verso il villaggio) per riempire.
func _scegli_punti_pioggia(n: int) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	if arena != null and arena.has_method("difensori_in_area"):
		var lista: Array = arena.difensori_in_area(global_position, 1300.0)
		for d in lista:
			if d != null and is_instance_valid(d):
				pts.append(d.global_position)
			if pts.size() >= n:
				break
	while pts.size() < n:
		var x: float = global_position.x - randf_range(150.0, 700.0)
		var y: float = global_position.y + randf_range(-150.0, 150.0)
		pts.append(Vector2(x, y))
	return pts


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
	# Forma trasformata (F4): alone cremisi pulsante dietro il boss (più minaccioso).
	if _trasformato:
		var pa: float = 0.28 + 0.16 * sin(_bt * 5.0)
		draw_circle(Vector2.ZERO, r * 1.28, Color(0.85, 0.12, 0.1, pa))
		draw_arc(Vector2.ZERO, r * 1.34, 0.0, TAU, 44, Color(1.0, 0.4, 0.2, 0.7), 3.0)
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
	# Telegrafo Soffio: lingua di fuoco che cresce verso il villaggio (a sinistra).
	if _stato == "telegrafo" and _abil_corrente == "soffio":
		var prog: float = clampf(1.0 - (_tele_fino - _bt) / maxf(_tele_dur, 0.01), 0.0, 1.0)
		var lung: float = 700.0 * prog
		var a: float = 0.30 + 0.30 * sin(_bt * 20.0)
		var hh: float = 36.0
		draw_rect(Rect2(Vector2(-raggio - lung, -hh), Vector2(lung, hh * 2.0)),
			Color(0.98, 0.42, 0.12, a * 0.6))
		draw_arc(Vector2(-raggio, 0.0), 10.0 + 6.0 * sin(_bt * 24.0), 0.0, TAU, 16,
			Color(1.0, 0.8, 0.35, 0.9), 3.0)
	# Telegrafo Pioggia: cerchi-bersaglio pulsanti sui punti d'impatto.
	if _stato == "telegrafo" and _abil_corrente == "pioggia":
		var ap: float = 0.4 + 0.3 * sin(_bt * 16.0)
		for p in _pioggia_pts:
			var lp: Vector2 = p - global_position
			draw_circle(lp, 90.0, Color(0.95, 0.3, 0.12, ap * 0.5))
			draw_arc(lp, 90.0, 0.0, TAU, 32, Color(1.0, 0.6, 0.3, 0.9), 3.0)

	var rear: float = 0.0
	if _stato == "telegrafo" and _abil_corrente == "carica":
		rear = 10.0  # arretra: telegrafo della Carica
		# Chevron arancioni verso il villaggio: "CARICA su questa corsia — bloccala!".
		var ac: float = 0.5 + 0.4 * sin(_bt * 14.0)
		var col: Color = Color(1.0, 0.55, 0.22, ac)
		for k in range(3):
			var bx: float = -r - 36.0 - float(k) * 34.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(bx, -20.0), Vector2(bx - 24.0, 0.0), Vector2(bx, 20.0)]), col)

	var tinta: Color = Color(1.0, 0.6, 0.55) if _in_furia else Color.WHITE
	if _staggerato:
		tinta = Color(1.3, 1.25, 0.95)   # sbianca: "colpitelo ORA"
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
		# Crepe d'ember sul corpo trasformato: la FASE si legge sul boss, non solo sul titolo.
		if _trasformato:
			var puls: float = 0.55 + 0.4 * sin(_bt * 6.0)
			var ember: Color = Color(1.0, 0.5, 0.16, puls)
			if _frenesia:
				ember = Color(1.0, 0.34, 0.2, 0.7 + 0.3 * sin(_bt * 11.0))
			draw_polyline(PackedVector2Array([
				Vector2(rear - r * 0.1, -r * 0.55), Vector2(rear + r * 0.06, -r * 0.12),
				Vector2(rear - r * 0.06, r * 0.28)]), ember, 3.0)
			draw_polyline(PackedVector2Array([
				Vector2(rear + r * 0.28, -r * 0.22), Vector2(rear + r * 0.46, r * 0.08),
				Vector2(rear + r * 0.3, r * 0.46)]), ember, 3.0)
			draw_polyline(PackedVector2Array([
				Vector2(rear - r * 0.46, -r * 0.04), Vector2(rear - r * 0.24, r * 0.22)]), ember, 3.0)
			draw_circle(Vector2(rear, r * 0.05), r * 0.16, Color(1.0, 0.6, 0.22, puls * 0.5))
	# Stelle che orbitano sopra la testa: il boss è VULNERABILE (stordito).
	if _staggerato:
		var cy: float = -r * 1.05
		for i in range(3):
			var ang: float = _bt * 6.0 + TAU * float(i) / 3.0
			var sp: Vector2 = Vector2(cos(ang) * r * 0.55, cy + sin(ang) * r * 0.18)
			draw_circle(sp, 6.0, Color(1.0, 0.95, 0.5, 0.95))
			draw_circle(sp, 3.0, Color(1.0, 1.0, 0.88, 1.0))
	# Punto debole rivelato dallo Spionaggio alto: bersaglio pulsante (qui la tenuta sale
	# prima). Reso prominente perché si legga anche sul corpo grande del boss.
	elif stagger_gain >= 1.25:
		var wp: Vector2 = Vector2(-r * 0.18, -r * 0.5)
		var pa: float = 0.55 + 0.4 * sin(_bt * 7.0)
		draw_circle(wp, 20.0, Color(0.45, 0.95, 1.0, pa * 0.35))
		draw_arc(wp, 17.0, 0.0, TAU, 24, Color(0.75, 1.0, 1.0, pa), 3.0)
		draw_arc(wp, 9.0, 0.0, TAU, 18, Color(0.9, 1.0, 1.0, pa), 2.0)
		draw_circle(wp, 4.5, Color(1.0, 1.0, 1.0, pa))
