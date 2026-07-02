extends Node2D
class_name SiegeDefender

# Difensore dell'Assedio (Fase B). Quattro ruoli, scalati dalle statistiche della run
# (vedi SiegeArena._crea_unita). Placeholder via _draw; gli archetipi sono costanti,
# le "skin" (nome/colore) cambiano per era. Vedi Docs/11-boss-fight.md §4.
#
#   ranged  — Tiratore: spara un proiettile al nemico più avanzato nel raggio.   (Militare)
#   blocco  — Bloccatore: sbarra la corsia, ha HP, colpisce in mischia chi lo ferma. (Costruzione)
#   slow    — Sciamano: rallenta i nemici in un'aura, non spara.                  (Scienza)
#   aoe     — Totem: proiettile che esplode infliggendo danno ad area.           (Spionaggio)

signal distrutto(slot: int)

var ruolo: String = "ranged"        # ranged | blocco | slow | aoe
var tipo: String = ""               # tiratore | bloccatore | sciamano | totem (per la progressione)
var livello: int = 1                # Lv1→Lv5 del tipo (Docs/14 §3): aspetto + stat salgono
var nome: String = "Difensore"
var corsia: int = 0
var slot: int = -1                  # piazzola occupata (-1 = alleato/non su piazzola)
var costo: int = 4
var colore: Color = Color(0.55, 0.8, 0.95)
var sprite: Texture2D = null        # se presente (…/era<N>/unit_<archetipo>.png) rimpiazza la forma
var alleato: bool = false           # truppa di una civiltà amica (estetica + bandiera)

# Combattimento.
var danno: int = 8
var raggio_tiro: float = 240.0
var cadenza: float = 0.85
var aoe_raggio: float = 0.0
# Solo blocco.
var hp_max: int = 60
var hp: int = 60
# Solo slow.
var slow_fattore: float = 0.5
var slow_durata: float = 0.7

var arena: Node = null              # SiegeArena (API: bersaglio_per/lancia_proiettile/...)

const REACH_BLOCCO: float = 52.0
const ULT_CD: float = 8.0            # cooldown delle ultimate (Lv5), auto-cast periodico
var _cooldown: float = 0.0
var _vita_t: float = 0.0
var _stun_fino: float = -1.0
var _ult_cd: float = randf_range(3.0, 6.5)   # primo cast SCAGLIONATO (niente callout sovrapposti)
var _calore_cd: float = 0.0          # tick del passivo Calore (Totem Lv5)
var _regen_acc: float = 0.0          # accumulo del passivo Roccia (Bloccatore Lv5)
var _regen_show: float = 0.0         # cura accumulata da MOSTRARE (+N verde: il passivo si vede)
var _idle_tw: Tween = null           # tween dell'idle-bob (va fermato durante la camminata)
var _move_tw: Tween = null           # tween della camminata verso il posto in formazione


func _ready() -> void:
	hp = hp_max


# Aura perenne (Sciamano Lv5): aura di gelo pulsante ai piedi — il passivo si VEDE.
# VFX dedicato (fx/aura_gelo.png) in blend ADD, dietro il corpo. Idempotente.
func attiva_aura_gelo(tex: Texture2D) -> void:
	if tex == null or get_node_or_null("AuraGelo") != null:
		return
	var s: Sprite2D = Sprite2D.new()
	s.name = "AuraGelo"
	s.texture = tex
	var sc: float = 150.0 / float(maxi(tex.get_width(), 1))
	s.scale = Vector2(sc, sc)
	s.show_behind_parent = true
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = mat
	s.modulate = Color(0.7, 0.9, 1.0, 0.42)
	s.position = Vector2(0.0, 4.0)
	add_child(s)
	var t: Tween = create_tween()
	t.set_loops()
	t.tween_property(s, "modulate:a", 0.22, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(s, "modulate:a", 0.42, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# Idle-bob: il difensore "respira" oscillando di poco in verticale. Random per
# desincronizzare; non tocca scale (usata dal recoil). Riavviabile (rifà la base sull'attuale y).
func avvia_idle() -> void:
	if _idle_tw != null and _idle_tw.is_valid():
		_idle_tw.kill()
	var base_y: float = position.y
	var amp: float = randf_range(1.5, 3.0)
	var dur: float = randf_range(1.0, 1.6)
	_idle_tw = create_tween()
	_idle_tw.set_loops()
	_idle_tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tw.tween_property(self, "position:y", base_y - amp, dur)
	_idle_tw.tween_property(self, "position:y", base_y, dur)


# Raggiunge il posto in formazione: ferma l'idle, cammina fin lì, poi riprende l'idle.
# ("Esce dal villaggio camminando", Docs/14 §1.) Con cammina=false si teletrasporta.
func vai_a(target: Vector2, cammina: bool = true) -> void:
	if _idle_tw != null and _idle_tw.is_valid():
		_idle_tw.kill()
	if _move_tw != null and _move_tw.is_valid():
		_move_tw.kill()
	if not cammina:
		global_position = target
		avvia_idle()
		return
	var dur: float = clampf(global_position.distance_to(target) / 420.0, 0.12, 0.9)
	_move_tw = create_tween()
	_move_tw.tween_property(self, "global_position", target, dur) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_move_tw.tween_callback(avvia_idle)


func _process(delta: float) -> void:
	if arena == null:
		return
	_vita_t += delta
	if _vita_t < _stun_fino:
		return   # stordito dal Ruggito del boss
	_tick_abilita(delta)   # passivi + ultimate (Lv5): girano anche durante il cooldown d'attacco
	if _cooldown > 0.0:
		_cooldown -= delta
		return
	match ruolo:
		"ranged", "aoe":
			var b: SiegeEnemy = arena.bersaglio_per(global_position, raggio_tiro)
			# FASE II del duello: l'Idolo GIGANTE e immobile si colpisce anche fuori gittata.
			if b == null and arena.has_method("boss_gigante_bersaglio"):
				b = arena.boss_gigante_bersaglio()
			if b != null:
				var dmg: int = danno
				# Mira (Tiratore Lv5): danno critico sui nemici già feriti (< 50% HP).
				var crit: bool = ruolo == "ranged" and livello >= 5 \
					and float(b.hp) < 0.5 * float(maxi(b.hp_max, 1))
				if crit:
					dmg = int(round(float(dmg) * 1.6))
				var pierce: int = 2 if (ruolo == "ranged" and livello >= 3) else 0   # Freccia perforante
				var brace: bool = (ruolo == "aoe" and livello >= 3)                   # Brace
				arena.lancia_proiettile(global_position, b, dmg, aoe_raggio, pierce, brace, crit)
				_cooldown = cadenza
				_recoil()
		"blocco":
			var e: SiegeEnemy = arena.nemico_per_blocco(global_position, REACH_BLOCCO)
			if e != null:
				e.subisci_danno(danno)
				_cooldown = cadenza
				_recoil()
			elif arena.has_method("boss_gigante_bersaglio"):
				# FASE II del duello: nessuno da bloccare (l'Idolo è immobile a destra) —
				# i guerrieri SCAGLIANO le lance contro il colosso, invece di stare a guardare.
				var big: SiegeEnemy = arena.boss_gigante_bersaglio()
				if big != null:
					arena.lancia_proiettile(global_position, big, maxi(3, int(round(float(danno) * 0.7))))
					_cooldown = cadenza * 1.25
					_recoil()
		"slow":
			var lista: Array = arena.nemici_in_area(global_position, raggio_tiro)
			if not lista.is_empty():
				for en in lista:
					en.applica_slow(slow_fattore, slow_durata)
				_pulse()
			_cooldown = 0.35


# Passivi (Lv5) + ultimate (Lv5, auto-cast periodico). Girano ogni frame, a parte lo stun.
func _tick_abilita(delta: float) -> void:
	# Roccia (Bloccatore Lv5): rigenera lentamente i propri HP.
	if ruolo == "blocco" and livello >= 5 and hp < hp_max:
		_regen_acc += 6.0 * delta
		if _regen_acc >= 1.0:
			var add: int = int(_regen_acc)
			_regen_acc -= float(add)
			hp = mini(hp_max, hp + add)
			queue_redraw()
			# Roccia VISIBILE: ogni tot la rigenerazione mostra il suo "+N" verde.
			_regen_show += float(add)
			if _regen_show >= 14.0 and arena != null and arena.has_method("fx_numero_cura"):
				arena.fx_numero_cura(global_position, int(_regen_show))
				_regen_show = 0.0
	# Calore (Totem Lv5): danno continuo ai nemici nell'area attorno al totem.
	if ruolo == "aoe" and livello >= 5:
		_calore_cd -= delta
		if _calore_cd <= 0.0:
			_calore_cd = 0.5
			arena.danno_area_nemici(global_position, maxf(60.0, aoe_raggio * 0.55), maxi(2, int(round(float(danno) * 0.22))))
	# Ultimate (Lv5): a cadenza, se c'è un nemico in gittata (niente sprechi a vuoto).
	# Le unità A TIRO (ranged/aoe) hanno gittata d'ultimate DOPPIA e mirano al nemico
	# più vicino a loro (prima colpivano un punto fisso davanti → spesso "a vuoto").
	if livello >= 5:
		_ult_cd -= delta
		if _ult_cd <= 0.0:
			var gittata: float = raggio_tiro * 2.0 if (ruolo == "ranged" or ruolo == "aoe") else 900.0
			var b_ult: SiegeEnemy = arena.bersaglio_per(global_position, gittata)
			if b_ult == null and arena.has_method("boss_gigante_bersaglio"):
				b_ult = arena.boss_gigante_bersaglio()   # fase II: l'Idolo si ultima da ovunque
			if b_ult != null:
				_ult_cd = ULT_CD
				_cast_ultimate(b_ult)


# Lancia l'ultimate del tipo (forma finale dell'ascensione, Docs/14 §3). Le unità a tiro
# CENTRANO l'ultimate sul nemico più vicino (bersaglio), le altre su di sé.
func _cast_ultimate(bersaglio: SiegeEnemy = null) -> void:
	var mira: Vector2 = global_position + Vector2(230.0, -10.0)
	if bersaglio != null and is_instance_valid(bersaglio):
		mira = bersaglio.global_position
	match tipo:
		"tiratore":
			arena.ultimate_tiratore(global_position, mira, int(round(float(danno) * 1.4)))
		"totem":
			arena.ultimate_totem(global_position, mira, int(round(float(danno) * 1.3)))
		"sciamano":
			arena.ultimate_sciamano(global_position, raggio_tiro * 1.1)
		"bloccatore":
			arena.ultimate_bloccatore(global_position)
	_pulse()


func subisci_danno(d: int) -> void:
	if ruolo != "blocco":
		return
	hp -= d
	queue_redraw()
	modulate = Color(1.5, 1.2, 1.2)
	var t: Tween = create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.18)
	if hp <= 0:
		distrutto.emit(slot)
		queue_free()


# Danno ad area dal boss (Pestone): colpisce QUALSIASI ruolo. Se l'HP cade, l'unità
# è distrutta (libera la piazzola). Distinto da subisci_danno (solo melee sul blocco).
func colpisci(d: int) -> void:
	hp -= d
	queue_redraw()
	modulate = Color(1.6, 0.7, 0.6)
	var t: Tween = create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.22)
	if hp <= 0:
		distrutto.emit(slot)
		queue_free()


# Stordimento dal Ruggito del boss: l'unità non agisce per `dur` secondi.
func stordisci(dur: float) -> void:
	_stun_fino = _vita_t + dur
	modulate = Color(0.7, 0.7, 0.95)
	var t: Tween = create_tween()
	t.tween_property(self, "modulate", Color.WHITE, minf(dur, 0.6))


# Per il bloccatore: vivo finché ha HP. Gli altri ruoli non vengono mai ingaggiati.
func vivo() -> bool:
	return hp > 0


func _recoil() -> void:
	var t: Tween = create_tween()
	t.tween_property(self, "scale", Vector2(1.15, 0.88), 0.06)
	t.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _pulse() -> void:
	var t: Tween = create_tween()
	t.tween_property(self, "modulate", Color(0.7, 0.92, 1.2), 0.12)
	t.tween_property(self, "modulate", Color.WHITE, 0.22)


func _draw() -> void:
	var scuro: Color = Color(0.1, 0.08, 0.06, 0.9)
	# Tinta per livello: vira verso l'oro col salire del Lv (colpo d'occhio della progressione).
	var lv_col: Color = colore.lerp(Color(1.0, 0.86, 0.42), clampf(0.14 * float(livello - 1), 0.0, 0.58))
	# Raggio d'azione tenue (non per il bloccatore).
	if ruolo != "blocco":
		draw_arc(Vector2.ZERO, raggio_tiro, 0.0, TAU, 48, Color(lv_col.r, lv_col.g, lv_col.b, 0.07), 1.0)
	# Ombra di contatto alla base (àncora l'unità alla piazzola).
	var so: PackedVector2Array = PackedVector2Array()
	for i in range(16):
		var a: float = TAU * float(i) / 16.0
		so.append(Vector2(cos(a) * 24.0, 13.0 + sin(a) * 7.0))
	draw_colored_polygon(so, Color(0.04, 0.03, 0.02, 0.30))
	if sprite != null:
		# Sprite generato (guarda a destra): rimpiazza la forma placeholder. Tinta col livello.
		var h: float = 82.0
		var w: float = h * (float(sprite.get_width()) / float(maxi(sprite.get_height(), 1)))
		var tint: Color = Color.WHITE.lerp(Color(1.25, 1.1, 0.7), clampf(0.18 * float(livello - 1), 0.0, 0.7))
		draw_texture_rect(sprite, Rect2(-w * 0.5, 14.0 - h, w, h), false, tint)
	else:
		match ruolo:
			"ranged":
				# Torre snella con punta verso l'alto.
				draw_rect(Rect2(Vector2(-17, -4), Vector2(34, 15)), Color(0.32, 0.23, 0.15))
				var pts: PackedVector2Array = PackedVector2Array([Vector2(-15, -4), Vector2(15, -4), Vector2(0, -40)])
				draw_colored_polygon(pts, lv_col)
				draw_polyline(PackedVector2Array([Vector2(-15, -4), Vector2(0, -40), Vector2(15, -4), Vector2(-15, -4)]), scuro, 2.0)
			"blocco":
				# Muro di scudi: blocco tozzo.
				draw_rect(Rect2(Vector2(-22, -34), Vector2(44, 46)), lv_col)
				draw_rect(Rect2(Vector2(-22, -34), Vector2(44, 46)), scuro, false, 2.5)
				draw_line(Vector2(0, -34), Vector2(0, 12), scuro, 2.0)
			"slow":
				# Totem/bastone con cristallo: rombo in cima.
				draw_rect(Rect2(Vector2(-6, -36), Vector2(12, 48)), Color(0.3, 0.24, 0.18))
				var rombo: PackedVector2Array = PackedVector2Array([
					Vector2(0, -52), Vector2(13, -38), Vector2(0, -24), Vector2(-13, -38)])
				draw_colored_polygon(rombo, lv_col)
				draw_polyline(PackedVector2Array([
					Vector2(0, -52), Vector2(13, -38), Vector2(0, -24), Vector2(-13, -38), Vector2(0, -52)]), scuro, 2.0)
			"aoe":
				# Piromante/Mago del Fuoco: figura robata con una fiamma in mano (PERSONA, non oggetto).
				draw_rect(Rect2(Vector2(-12, -34), Vector2(24, 46)), lv_col)
				draw_rect(Rect2(Vector2(-12, -34), Vector2(24, 46)), scuro, false, 2.0)
				draw_circle(Vector2(0, -42), 8.0, Color(0.86, 0.72, 0.55))      # testa
				draw_circle(Vector2(-15, -30), 6.0, Color(1.0, 0.6, 0.25))      # fiamma in mano
				draw_circle(Vector2(-15, -30), 3.0, Color(1.0, 0.92, 0.6))
	# Barra HP del muro (sopra lo sprite o la forma).
	if ruolo == "blocco":
		var bw: float = 44.0
		var top: Vector2 = Vector2(-bw * 0.5, -46.0)
		draw_rect(Rect2(top, Vector2(bw, 5.0)), Color(0.12, 0.1, 0.08, 0.85))
		var frac: float = clampf(float(hp) / float(maxi(hp_max, 1)), 0.0, 1.0)
		draw_rect(Rect2(top, Vector2(bw * frac, 5.0)), Color(0.55, 0.78, 0.45))
	if alleato:
		# Stendardo d'alleanza, radicato alla base.
		draw_line(Vector2(13, -6), Vector2(13, -50), scuro, 2.5)
		draw_colored_polygon(PackedVector2Array([
			Vector2(13, -50), Vector2(31, -44), Vector2(13, -38)]), Color(0.6, 0.95, 0.6))
		draw_polyline(PackedVector2Array([
			Vector2(13, -50), Vector2(31, -44), Vector2(13, -38)]), scuro, 1.5)
	_draw_flair_livello()


# Insegne di livello (Docs/14 §3): gemma dal Lv3 (abilità), coroncina + aura al Lv5 (ascensione).
# Il numero esatto del livello sta sulle carte; qui solo il colpo d'occhio sull'unità.
func _draw_flair_livello() -> void:
	if livello < 3:
		return
	var cima: float = -58.0
	var gem: Color = Color(0.62, 0.95, 1.0) if livello < 5 else Color(1.0, 0.88, 0.4)
	var g: Vector2 = Vector2(0, cima)
	draw_colored_polygon(PackedVector2Array([
		g + Vector2(0, -7), g + Vector2(6, 0), g + Vector2(0, 7), g + Vector2(-6, 0)]), gem)
	draw_polyline(PackedVector2Array([
		g + Vector2(0, -7), g + Vector2(6, 0), g + Vector2(0, 7), g + Vector2(-6, 0), g + Vector2(0, -7)]),
		Color(0.1, 0.08, 0.06, 0.9), 1.5)
	if livello >= 5:
		# Aura + coroncina dorata dell'ascensione.
		draw_arc(Vector2(0, -10), 32.0, PI, TAU, 22, Color(1.0, 0.85, 0.4, 0.5), 3.0)
		var cy: float = cima - 12.0
		var oro: Color = Color(1.0, 0.86, 0.4)
		for k in range(3):
			var bx: float = -10.0 + float(k) * 10.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(bx - 4.0, cy), Vector2(bx + 4.0, cy), Vector2(bx, cy - 9.0)]), oro)
