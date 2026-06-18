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
var _cooldown: float = 0.0
var _vita_t: float = 0.0
var _stun_fino: float = -1.0


func _ready() -> void:
	hp = hp_max


func _process(delta: float) -> void:
	if arena == null:
		return
	_vita_t += delta
	if _vita_t < _stun_fino:
		return   # stordito dal Ruggito del boss
	if _cooldown > 0.0:
		_cooldown -= delta
		return
	match ruolo:
		"ranged", "aoe":
			var b: SiegeEnemy = arena.bersaglio_per(global_position, raggio_tiro)
			if b != null:
				arena.lancia_proiettile(global_position, b, danno, aoe_raggio)
				_cooldown = cadenza
				_recoil()
		"blocco":
			var e: SiegeEnemy = arena.nemico_per_blocco(corsia, global_position.x, REACH_BLOCCO)
			if e != null:
				e.subisci_danno(danno)
				_cooldown = cadenza
				_recoil()
		"slow":
			var lista: Array = arena.nemici_in_area(global_position, raggio_tiro)
			if not lista.is_empty():
				for en in lista:
					en.applica_slow(slow_fattore, slow_durata)
				_pulse()
			_cooldown = 0.35


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
	# Raggio d'azione tenue (non per il bloccatore).
	if ruolo != "blocco":
		draw_arc(Vector2.ZERO, raggio_tiro, 0.0, TAU, 48, Color(colore.r, colore.g, colore.b, 0.07), 1.0)
	if sprite != null:
		# Sprite generato (guarda a destra): rimpiazza la forma placeholder.
		var h: float = 82.0
		var w: float = h * (float(sprite.get_width()) / float(maxi(sprite.get_height(), 1)))
		draw_texture_rect(sprite, Rect2(-w * 0.5, 14.0 - h, w, h), false)
	else:
		match ruolo:
			"ranged":
				# Torre snella con punta verso l'alto.
				draw_rect(Rect2(Vector2(-17, -4), Vector2(34, 15)), Color(0.32, 0.23, 0.15))
				var pts: PackedVector2Array = PackedVector2Array([Vector2(-15, -4), Vector2(15, -4), Vector2(0, -40)])
				draw_colored_polygon(pts, colore)
				draw_polyline(PackedVector2Array([Vector2(-15, -4), Vector2(0, -40), Vector2(15, -4), Vector2(-15, -4)]), scuro, 2.0)
			"blocco":
				# Muro di scudi: blocco tozzo.
				draw_rect(Rect2(Vector2(-22, -34), Vector2(44, 46)), colore)
				draw_rect(Rect2(Vector2(-22, -34), Vector2(44, 46)), scuro, false, 2.5)
				draw_line(Vector2(0, -34), Vector2(0, 12), scuro, 2.0)
			"slow":
				# Totem/bastone con cristallo: rombo in cima.
				draw_rect(Rect2(Vector2(-6, -36), Vector2(12, 48)), Color(0.3, 0.24, 0.18))
				var rombo: PackedVector2Array = PackedVector2Array([
					Vector2(0, -52), Vector2(13, -38), Vector2(0, -24), Vector2(-13, -38)])
				draw_colored_polygon(rombo, colore)
				draw_polyline(PackedVector2Array([
					Vector2(0, -52), Vector2(13, -38), Vector2(0, -24), Vector2(-13, -38), Vector2(0, -52)]), scuro, 2.0)
			"aoe":
				# Catapulta/braciere: base larga + coppa.
				draw_rect(Rect2(Vector2(-20, -6), Vector2(40, 18)), Color(0.32, 0.23, 0.15))
				draw_circle(Vector2(0, -16), 13.0, colore)
				draw_arc(Vector2(0, -16), 13.0, 0.0, TAU, 24, scuro, 2.0)
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
