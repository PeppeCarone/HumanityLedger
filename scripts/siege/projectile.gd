extends Node2D
class_name SiegeProjectile

# Proiettile dell'Assedio (Fase B): vola verso il nemico bersaglio e gli applica il
# danno all'impatto. Se aoe_raggio > 0 (Totem) il danno si propaga ai nemici vicini.
# Placeholder via _draw. Vedi Docs/11-boss-fight.md.

var velocita: float = 640.0
var danno: int = 8
var bersaglio: SiegeEnemy = null
var aoe_raggio: float = 0.0
var arena: Node = null              # SiegeArena: per il danno ad area
var sprite: Texture2D = null        # se presente (Assets/art/siege/fx/proiettile*.png)
var colore: Color = Color(1.0, 0.86, 0.5)
var pierce: int = 0                 # Freccia perforante (Tiratore Lv3): colpisce N nemici extra in fila
var brace: bool = false            # Brace (Totem Lv3): lascia fuoco a terra all'impatto


func _process(delta: float) -> void:
	if bersaglio == null or not is_instance_valid(bersaglio) or not bersaglio.vivo():
		queue_free()
		return
	var dir: Vector2 = bersaglio.global_position - global_position
	var dist: float = dir.length()
	var passo: float = velocita * delta
	if dist <= passo or dist < 1.0:
		_impatto()
		return
	global_position += dir / dist * passo


func _impatto() -> void:
	bersaglio.subisci_danno(danno)
	# Freccia perforante: trafigge anche i nemici vicini in fila (Tiratore Lv3).
	if pierce > 0 and arena != null:
		var colpiti: int = 0
		for e in arena.nemici_in_area(global_position, 80.0):
			if e != bersaglio and colpiti < pierce:
				e.subisci_danno(danno)
				colpiti += 1
	if aoe_raggio > 0.0 and arena != null:
		var danno_aoe: int = int(round(float(danno) * 0.6))
		for e in arena.nemici_in_area(global_position, aoe_raggio):
			if e != bersaglio:
				e.subisci_danno(danno_aoe)
		arena.fx_esplosione(global_position, aoe_raggio)
	# Brace: lascia fuoco a terra che brucia nel tempo (Totem Lv3).
	if brace and arena != null:
		arena.crea_brace(global_position, maxi(2, int(round(float(danno) * 0.35))))
	queue_free()


func _draw() -> void:
	if sprite != null:
		var h: float = 22.0
		var w: float = h * (float(sprite.get_width()) / float(maxi(sprite.get_height(), 1)))
		draw_texture_rect(sprite, Rect2(-w * 0.5, -h * 0.5, w, h), false)
	elif aoe_raggio > 0.0:
		draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.6, 0.3))
		draw_circle(Vector2.ZERO, 3.5, Color(1.0, 0.9, 0.6))
	else:
		draw_circle(Vector2.ZERO, 6.0, colore)
		draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.97, 0.85))
