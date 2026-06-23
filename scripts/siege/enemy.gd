extends Node2D
class_name SiegeEnemy

# Nemico dell'Assedio (Fase B, placeholder via _draw): marcia da destra verso il
# villaggio a sinistra lungo una delle 3 corsie. Se trova un BLOCCATORE sulla sua
# corsia si ferma e lo attacca corpo a corpo finché non cade; può essere RALLENTATO
# da uno sciamano. Sostituibile con sprite in Fase G
# (Assets/art/siege/era<N>/enemy_*.png). Vedi Docs/11-boss-fight.md.

signal morto(bounty: int)
signal arrivato(danno: int)

var hp_max: int = 20
var hp: int = 20
var velocita: float = 70.0          # px/s verso sinistra
var danno_villaggio: int = 10
var danno_melee: int = 6            # danno inferto al bloccatore che lo ferma
var bounty: int = 2                 # Risorse d'assedio guadagnate uccidendolo
var villaggio_x: float = 300.0
var corsia: int = 0
var raggio: float = 18.0
var colore: Color = Color(0.82, 0.42, 0.36)
var sprite: Texture2D = null        # se presente (Assets/art/siege/era<N>/enemy.png) rimpiazza il cerchio
var arena: Node = null              # SiegeArena: per interrogare i blocchi sulla corsia
var armatura: int = 0               # riduzione piatta del danno subito (golem)
var risorge: bool = false           # si rialza UNA volta a metà HP quando cadrebbe (scheletro)
# Abilità nemiche (Fase F3, Docs/14 §4): impostate dall'arena dal profilo della creatura.
var caricatore: bool = false        # Caricatore: scatti periodici in avanti (sfonda in fretta)
var scudo_max: int = 0              # Scudato: scudo frontale che assorbe danno, poi si rompe
var scudo: int = 0
var evocatore: bool = false         # Evocatore: chiama minion a cadenza
var risanatore: bool = false        # Risanatore: cura i nemici vicini a cadenza
var mini_boss: bool = false         # Mini-boss (ondata 3): più grosso, banner col nome
var nome: String = ""               # nome (mini-boss) per il banner d'entrata

const REACH_BLOCCO: float = 46.0    # distanza a cui ci si ferma davanti al bloccatore
const ATK_CADENZA: float = 0.75
const CARICA_CD: float = 3.2        # ogni quanto il caricatore scatta
const CARICA_DUR: float = 0.7       # durata dello scatto (lo scatto sfonda la linea)
const CARICA_MULT: float = 2.7      # moltiplicatore velocità durante lo scatto
const EVOCA_CD: float = 4.5         # ogni quanto l'evocatore chiama un minion
const CURA_CD: float = 2.4          # ogni quanto il risanatore cura i vicini

var _vivo: bool = true
var _t: float = 0.0
var _slow_fino: float = -1.0
var _slow_fattore: float = 1.0
var _atk_cd: float = 0.0
var _engaged: Node = null           # bloccatore che ci sbarra la strada
var _risorto: bool = false          # ha già usato la sua risurrezione
var _stun_fino: float = -1.0        # stordito (Grido di guerra, Bloccatore Lv5): fermo
var _carica_cd: float = 2.0         # countdown alla prossima carica
var _carica_fino: float = -1.0      # scatto attivo finché _t < _carica_fino
var _evoca_cd: float = 3.0
var _cura_cd: float = 2.0
var _last_num: float = -1.0         # throttle dei numeri di danno fluttuanti (juice)


func _process(delta: float) -> void:
	if not _vivo:
		return
	_t += delta
	if _t >= _slow_fino and _slow_fattore < 1.0:
		_slow_fattore = 1.0
		queue_redraw()

	# Stordito: resta immobile, non marcia né colpisce (finché dura).
	if _t < _stun_fino:
		queue_redraw()
		return

	_tick_abilita_nemico(delta)   # caricatore/evocatore/risanatore (Fase F3)

	# Durante lo SCATTO il caricatore SFONDA: ignora i bloccatori e tira dritto (F5: così
	# qualche nemico può davvero arrivare al villaggio → tensione). Fuori scatto, ingaggia.
	var in_carica: bool = _t < _carica_fino
	if in_carica:
		_engaged = null
	else:
		# Il bloccatore ingaggiato è ancora valido?
		if _engaged != null and (not is_instance_valid(_engaged) or not _engaged.vivo()):
			_engaged = null
		# Cerca un bloccatore davanti nella mia banda verticale (line-battle, per prossimità).
		if _engaged == null and arena != null:
			var b: Node = arena.cerca_blocco(global_position)
			if b != null and global_position.x - b.global_position.x <= REACH_BLOCCO:
				_engaged = b
		if _engaged != null:
			# Fermo: martello il muro a cadenza.
			_atk_cd -= delta
			if _atk_cd <= 0.0:
				_engaged.subisci_danno(danno_melee)
				_atk_cd = ATK_CADENZA
				modulate = Color(1.4, 1.1, 1.0)
				var tw: Tween = create_tween()
				tw.tween_property(self, "modulate", Color.WHITE, 0.2)
			return

	# Marcia (eventualmente rallentata; ×CARICA_MULT durante lo scatto del caricatore).
	var vel_eff: float = velocita * _slow_fattore
	if _t < _carica_fino:
		vel_eff *= CARICA_MULT
	position.x -= vel_eff * delta
	if position.x <= villaggio_x:
		_vivo = false
		arrivato.emit(danno_villaggio)
		queue_free()


# Tick delle abilità nemiche (Fase F3): caricatore (scatto), evocatore (minion), risanatore (cura).
func _tick_abilita_nemico(delta: float) -> void:
	if arena == null:
		return
	# Caricatore: scatta in avanti solo quando è libero di marciare.
	if caricatore and _engaged == null and _t >= _carica_fino:
		_carica_cd -= delta
		if _carica_cd <= 0.0:
			_carica_cd = CARICA_CD
			_carica_fino = _t + CARICA_DUR
			modulate = Color(1.5, 0.9, 0.55)
			var tw: Tween = create_tween()
			tw.tween_property(self, "modulate", Color.WHITE, 0.45)
	if evocatore:
		_evoca_cd -= delta
		if _evoca_cd <= 0.0:
			_evoca_cd = EVOCA_CD
			if mini_boss:
				# Tell del mini-boss: lampo viola d'evocazione (la sua mini-meccanica si VEDE).
				modulate = Color(1.35, 0.8, 1.5)
				var tw: Tween = create_tween()
				tw.tween_property(self, "modulate", Color.WHITE, 0.5)
			if arena.has_method("spawn_minion"):
				arena.spawn_minion(global_position, corsia)
	if risanatore:
		_cura_cd -= delta
		if _cura_cd <= 0.0:
			_cura_cd = CURA_CD
			if arena.has_method("cura_nemici_area"):
				arena.cura_nemici_area(global_position, 170.0, maxi(3, int(float(hp_max) * 0.05)))


func subisci_danno(d: int) -> void:
	if not _vivo:
		return
	# Armatura: assorbe danno piatto (almeno 1 passa sempre). Il golem incassa i colpi.
	var dmg: int = maxi(1, d - armatura) if armatura > 0 else d
	# Scudo frontale (scudato): assorbe i colpi finché non si rompe; poi il danno passa.
	if scudo > 0:
		var assorbito: int = mini(scudo, dmg)
		scudo -= assorbito
		dmg -= assorbito
		queue_redraw()
		if scudo <= 0:
			_rompi_scudo()
		if dmg <= 0:
			modulate = Color(1.2, 1.3, 1.6)
			var ts: Tween = create_tween()
			ts.tween_property(self, "modulate", Color.WHITE, 0.16)
			return
	# Numero di danno fluttuante (juice), con throttle per non intasare lo schermo.
	if _t - _last_num >= 0.28 and arena != null and arena.has_method("fx_numero_danno"):
		arena.fx_numero_danno(global_position, dmg, false)
		_last_num = _t
	hp -= dmg
	if hp <= 0:
		# Risurrezione (scheletro): una volta sola si rialza a metà HP invece di morire.
		if risorge and not _risorto:
			_risorto = true
			hp = maxi(1, int(hp_max * 0.5))
			_fx_risorge()
			queue_redraw()
			return
		_vivo = false
		morto.emit(bounty)
		queue_free()
		return
	queue_redraw()
	modulate = Color(1.6, 1.3, 1.25)
	var t: Tween = create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.18)


# Si rialza: scatto di scala + bagliore d'ossa, perché il giocatore LO VEDA tornare su.
func _fx_risorge() -> void:
	modulate = Color(0.75, 0.95, 1.0)
	scale = Vector2(0.4, 0.5)
	var t: Tween = create_tween()
	t.tween_property(self, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "modulate", Color.WHITE, 0.45)


func applica_slow(fattore: float, durata: float) -> void:
	if not _vivo:
		return
	_slow_fattore = fattore
	_slow_fino = _t + durata
	queue_redraw()


# Cura (Risanatore nemico): recupera HP fino al massimo, con un lampo verde.
func cura(amount: int) -> void:
	if not _vivo or hp >= hp_max:
		return
	hp = mini(hp_max, hp + amount)
	queue_redraw()
	modulate = Color(0.7, 1.3, 0.7)
	var t: Tween = create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.3)


# Rottura dello scudo frontale (scudato): lampo chiaro; da qui in poi il corpo è esposto.
func _rompi_scudo() -> void:
	modulate = Color(1.7, 1.6, 1.0)
	var t: Tween = create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.32)


# Stordimento (Grido di guerra del Bloccatore Lv5): il nemico resta fermo per `dur` secondi.
func stordisci(dur: float) -> void:
	if not _vivo:
		return
	_stun_fino = _t + dur
	modulate = Color(0.82, 0.82, 1.18)
	var t: Tween = create_tween()
	t.tween_property(self, "modulate", Color.WHITE, minf(dur, 0.6))


func vivo() -> bool:
	return _vivo


func _draw() -> void:
	var rallentato: bool = _t < _slow_fino
	# Ombra di contatto: àncora la figura al terreno (niente "sprite che fluttua").
	var so: PackedVector2Array = PackedVector2Array()
	var sy: float = raggio * 0.78
	var sw: float = raggio * 0.95
	var sh: float = raggio * 0.30
	for i in range(16):
		var a: float = TAU * float(i) / 16.0
		so.append(Vector2(cos(a) * sw, sy + sin(a) * sh))
	draw_colored_polygon(so, Color(0.04, 0.03, 0.02, 0.32))
	if sprite != null:
		# Sprite generato (guarda a sinistra): rimpiazza il cerchio placeholder.
		var tint: Color = Color(0.72, 0.86, 1.1) if rallentato else Color.WHITE
		var h: float = raggio * 3.3
		var w: float = h * (float(sprite.get_width()) / float(maxi(sprite.get_height(), 1)))
		draw_texture_rect(sprite, Rect2(-w * 0.5, -h * 0.78, w, h), false, tint)
	else:
		var c: Color = colore.lerp(Color(0.55, 0.78, 1.0), 0.55) if rallentato else colore
		# Corpo (placeholder): cerchio con contorno scuro.
		draw_circle(Vector2.ZERO, raggio, c)
		draw_arc(Vector2.ZERO, raggio, 0.0, TAU, 28, Color(0.1, 0.06, 0.05, 0.9), 2.0)
		# "occhio" rivolto a sinistra (verso il villaggio) per dare un verso.
		draw_circle(Vector2(-raggio * 0.4, -raggio * 0.2), 3.0, Color(0.1, 0.05, 0.05))
	if rallentato:
		# Fiocco di gelo sopra la testa.
		draw_circle(Vector2(0.0, -raggio - 6.0), 3.0, Color(0.8, 0.95, 1.0, 0.9))
	if _engaged != null:
		# Scintille di scontro verso il muro (a sinistra).
		var sc: Color = Color(1.0, 0.82, 0.4, 0.95)
		draw_line(Vector2(-raggio, -2.0), Vector2(-raggio - 12.0, -8.0), sc, 2.0)
		draw_line(Vector2(-raggio, 2.0), Vector2(-raggio - 13.0, 2.0), sc, 2.0)
		draw_line(Vector2(-raggio, 5.0), Vector2(-raggio - 10.0, 11.0), sc, 2.0)
		draw_circle(Vector2(-raggio - 6.0, 0.0), 2.5, Color(1.0, 0.95, 0.7, 0.9))
	# Glifi delle abilità (Fase F3): leggibilità "nemico con abilità" a colpo d'occhio.
	if scudo > 0:
		# Scudo frontale (verso il villaggio, a sinistra): arco azzurro, intensità = scudo residuo.
		var sa: float = clampf(float(scudo) / float(maxi(scudo_max, 1)), 0.0, 1.0)
		draw_arc(Vector2.ZERO, raggio + 7.0, PI * 0.55, PI * 1.45, 22, Color(0.5, 0.8, 1.0, 0.4 + 0.45 * sa), 3.5)
	if _t < _carica_fino:
		# Scatto: scie di velocità dietro (a destra).
		for k in range(3):
			var yy: float = -6.0 + float(k) * 6.0
			draw_line(Vector2(raggio, yy), Vector2(raggio + 16.0, yy), Color(1.0, 0.7, 0.3, 0.8), 2.0)
	if evocatore:
		# Runa viola sopra la testa.
		draw_circle(Vector2(0.0, -raggio - 21.0), 4.0, Color(0.72, 0.5, 1.0, 0.95))
		draw_arc(Vector2(0.0, -raggio - 21.0), 7.5, 0.0, TAU, 16, Color(0.8, 0.6, 1.0, 0.7), 1.5)
	if risanatore:
		# Croce verde di cura sopra la testa.
		var hg: Vector2 = Vector2(0.0, -raggio - 21.0)
		draw_rect(Rect2(hg + Vector2(-2.0, -6.0), Vector2(4.0, 12.0)), Color(0.5, 1.0, 0.6, 0.92))
		draw_rect(Rect2(hg + Vector2(-6.0, -2.0), Vector2(12.0, 4.0)), Color(0.5, 1.0, 0.6, 0.92))
	# Barra HP sopra la testa.
	var w: float = raggio * 2.4
	var h: float = 5.0
	var top: Vector2 = Vector2(-w * 0.5, -raggio - 13.0)
	draw_rect(Rect2(top, Vector2(w, h)), Color(0.12, 0.08, 0.08, 0.85))
	var frac: float = clampf(float(hp) / float(maxi(hp_max, 1)), 0.0, 1.0)
	draw_rect(Rect2(top, Vector2(w * frac, h)), Color(0.85, 0.35, 0.3))
	# Glifo d'armatura (rombo d'acciaio) a sinistra della barra: segnala "incassa i colpi".
	if armatura > 0:
		var c: Vector2 = top + Vector2(-7.0, 2.5)
		var steel: Color = Color(0.72, 0.78, 0.86)
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(0, -5), c + Vector2(4, 0), c + Vector2(0, 5), c + Vector2(-4, 0)]), steel)
		draw_polyline(PackedVector2Array([
			c + Vector2(0, -5), c + Vector2(4, 0), c + Vector2(0, 5), c + Vector2(-4, 0),
			c + Vector2(0, -5)]), Color(0.2, 0.22, 0.26), 1.0)
