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

const REACH_BLOCCO: float = 46.0    # distanza a cui ci si ferma davanti al bloccatore
const ATK_CADENZA: float = 0.75

var _vivo: bool = true
var _t: float = 0.0
var _slow_fino: float = -1.0
var _slow_fattore: float = 1.0
var _atk_cd: float = 0.0
var _engaged: Node = null           # bloccatore che ci sbarra la strada


func _process(delta: float) -> void:
	if not _vivo:
		return
	_t += delta
	if _t >= _slow_fino and _slow_fattore < 1.0:
		_slow_fattore = 1.0
		queue_redraw()

	# Il bloccatore ingaggiato è ancora valido?
	if _engaged != null and (not is_instance_valid(_engaged) or not _engaged.vivo()):
		_engaged = null
	# Cerca un bloccatore davanti sulla mia corsia.
	if _engaged == null and arena != null:
		var b: Node = arena.cerca_blocco(corsia, position.x)
		if b != null and position.x > b.global_position.x and position.x - b.global_position.x <= REACH_BLOCCO:
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

	# Marcia (eventualmente rallentata).
	position.x -= velocita * _slow_fattore * delta
	if position.x <= villaggio_x:
		_vivo = false
		arrivato.emit(danno_villaggio)
		queue_free()


func subisci_danno(d: int) -> void:
	if not _vivo:
		return
	hp -= d
	if hp <= 0:
		_vivo = false
		morto.emit(bounty)
		queue_free()
		return
	queue_redraw()
	modulate = Color(1.6, 1.3, 1.25)
	var t: Tween = create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.18)


func applica_slow(fattore: float, durata: float) -> void:
	if not _vivo:
		return
	_slow_fattore = fattore
	_slow_fino = _t + durata
	queue_redraw()


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
	# Barra HP sopra la testa.
	var w: float = raggio * 2.4
	var h: float = 5.0
	var top: Vector2 = Vector2(-w * 0.5, -raggio - 13.0)
	draw_rect(Rect2(top, Vector2(w, h)), Color(0.12, 0.08, 0.08, 0.85))
	var frac: float = clampf(float(hp) / float(maxi(hp_max, 1)), 0.0, 1.0)
	draw_rect(Rect2(top, Vector2(w * frac, h)), Color(0.85, 0.35, 0.3))
