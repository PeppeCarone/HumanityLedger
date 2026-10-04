class_name StyleBoxDipinto
extends StyleBox

# StyleBox per l'arte "su tela" a capsula del kit (pulsanti §8b): disegna solo il bbox opaco
# della texture in tre fasce orizzontali. I capi ornati si scalano con l'ALTEZZA del
# controllo (proporzioni sempre vere), la fascia centrale si allunga in larghezza.
#
# Perché non StyleBoxTexture: il 9-slice disegna gli angoli a 1:1 e comprime in verticale
# la fascia dei capi; sui pulsanti più bassi della texture (o più larghi) le foglie dei
# capi si deformavano, e il padding trasparente dei PNG finiva dentro gli "angoli".

@export var texture: Texture2D = null
@export var regione: Rect2 = Rect2()   # bbox opaco nella texture (px sorgente)
@export var capo_sx: float = 0.0       # larghezza sorgente del capo sinistro
@export var capo_dx: float = 0.0
@export var modulazione: Color = Color.WHITE


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if texture == null or regione.size.y <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var s: float = rect.size.y / regione.size.y
	var wl: float = capo_sx * s
	var wr: float = capo_dx * s
	if wl + wr > rect.size.x:
		# Pulsante più stretto dei due capi: si stringono i capi (caso limite, mai a 0).
		var k: float = rect.size.x / maxf(wl + wr, 1.0)
		wl *= k
		wr *= k
	var rid: RID = texture.get_rid()
	var rs := RenderingServer
	rs.canvas_item_add_texture_rect_region(to_canvas_item,
		Rect2(rect.position, Vector2(wl, rect.size.y)), rid,
		Rect2(regione.position, Vector2(capo_sx, regione.size.y)), modulazione)
	var mezzo_src: Rect2 = Rect2(regione.position.x + capo_sx, regione.position.y,
		regione.size.x - capo_sx - capo_dx, regione.size.y)
	if mezzo_src.size.x > 0.0 and rect.size.x - wl - wr > 0.0:
		rs.canvas_item_add_texture_rect_region(to_canvas_item,
			Rect2(rect.position.x + wl, rect.position.y, rect.size.x - wl - wr, rect.size.y), rid,
			mezzo_src, modulazione)
	rs.canvas_item_add_texture_rect_region(to_canvas_item,
		Rect2(rect.end.x - wr, rect.position.y, wr, rect.size.y), rid,
		Rect2(regione.end.x - capo_dx, regione.position.y, capo_dx, regione.size.y), modulazione)
